// PTZ Camera Control - Main JavaScript

// Global configuration
const API_BASE_URL = '/api';

// Utility functions
function showLoading(element) {
    element.classList.add('loading');
    element.disabled = true;
}

function hideLoading(element) {
    element.classList.remove('loading');
    element.disabled = false;
}

function showToast(message, type = 'info') {
    // Create toast element
    const toastId = 'toast-' + Date.now();
    const toastHtml = `
        <div id="${toastId}" class="toast align-items-center text-white bg-${type === 'error' ? 'danger' : 'primary'} border-0" role="alert">
            <div class="d-flex">
                <div class="toast-body">
                    ${message}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        </div>
    `;
    
    // Add to toast container (create if doesn't exist)
    let toastContainer = document.getElementById('toast-container');
    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.id = 'toast-container';
        toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
        document.body.appendChild(toastContainer);
    }
    
    toastContainer.insertAdjacentHTML('beforeend', toastHtml);
    
    // Show toast
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement);
    toast.show();
    
    // Remove from DOM after hiding
    toastElement.addEventListener('hidden.bs.toast', () => {
        toastElement.remove();
    });
}

// API helper functions
async function apiRequest(endpoint, options = {}) {
    const url = API_BASE_URL + endpoint;
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
        },
    };
    
    const finalOptions = { ...defaultOptions, ...options };
    
    try {
        const response = await fetch(url, finalOptions);
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || `HTTP ${response.status}: ${response.statusText}`);
        }
        
        return data;
    } catch (error) {
        console.error('API Request failed:', error);
        throw error;
    }
}

// Camera management functions
async function getCameras() {
    return await apiRequest('/cameras');
}

async function refreshCameras() {
    return await apiRequest('/cameras/refresh', { method: 'POST' });
}

async function controlPanTilt(deviceId, pan, tilt) {
    return await apiRequest(`/cameras/${deviceId}/pan-tilt`, {
        method: 'POST',
        body: JSON.stringify({ pan, tilt })
    });
}

async function controlZoom(deviceId, zoom) {
    return await apiRequest(`/cameras/${deviceId}/zoom`, {
        method: 'POST',
        body: JSON.stringify({ zoom })
    });
}

async function setPreset(deviceId, preset) {
    return await apiRequest(`/cameras/${deviceId}/preset`, {
        method: 'POST',
        body: JSON.stringify({ preset })
    });
}

async function captureScreenshot(deviceId, filename = null) {
    const body = filename ? JSON.stringify({ filename }) : '{}';
    return await apiRequest(`/cameras/${deviceId}/screenshot`, {
        method: 'POST',
        body
    });
}

// Form validation
function validatePanTilt(pan, tilt) {
    const panNum = parseInt(pan);
    const tiltNum = parseInt(tilt);
    
    if (isNaN(panNum) || panNum < -100 || panNum > 100) {
        throw new Error('Pan value must be between -100 and 100');
    }
    
    if (isNaN(tiltNum) || tiltNum < -100 || tiltNum > 100) {
        throw new Error('Tilt value must be between -100 and 100');
    }
    
    return { pan: panNum, tilt: tiltNum };
}

function validateZoom(zoom) {
    const zoomNum = parseInt(zoom);
    
    if (isNaN(zoomNum) || zoomNum < 0 || zoomNum > 100) {
        throw new Error('Zoom value must be between 0 and 100');
    }
    
    return zoomNum;
}

function validatePreset(preset) {
    const presetNum = parseInt(preset);
    
    if (isNaN(presetNum) || presetNum < 1 || presetNum > 8) {
        throw new Error('Preset must be between 1 and 8');
    }
    
    return presetNum;
}

// Camera status monitoring
class CameraStatusMonitor {
    constructor(deviceId, statusCallback) {
        this.deviceId = deviceId;
        this.statusCallback = statusCallback;
        this.isMonitoring = false;
        this.intervalId = null;
    }
    
    start(intervalMs = 30000) {
        if (this.isMonitoring) return;
        
        this.isMonitoring = true;
        this.intervalId = setInterval(async () => {
            try {
                const response = await apiRequest('/status');
                this.statusCallback('online', response);
            } catch (error) {
                this.statusCallback('offline', error);
            }
        }, intervalMs);
    }
    
    stop() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
        this.isMonitoring = false;
    }
}

// Keyboard shortcuts
function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (event) => {
        // Only process shortcuts when not in an input field
        if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') {
            return;
        }
        
        // Preset shortcuts (1-8)
        if (event.key >= '1' && event.key <= '8') {
            const presetId = parseInt(event.key);
            const deviceId = getCurrentDeviceId();
            if (deviceId && typeof setPreset === 'function') {
                setPreset(presetId);
            }
        }
        
        // Arrow key shortcuts for pan/tilt
        const step = 10;
        switch (event.key) {
            case 'ArrowUp':
                event.preventDefault();
                adjustTilt(step);
                break;
            case 'ArrowDown':
                event.preventDefault();
                adjustTilt(-step);
                break;
            case 'ArrowLeft':
                event.preventDefault();
                adjustPan(-step);
                break;
            case 'ArrowRight':
                event.preventDefault();
                adjustPan(step);
                break;
            case 'Home':
                event.preventDefault();
                if (typeof resetPosition === 'function') {
                    resetPosition();
                }
                break;
        }
    });
}

function getCurrentDeviceId() {
    // This would be implemented differently depending on the page
    return window.deviceId || null;
}

function adjustPan(delta) {
    const panSlider = document.getElementById('panSlider');
    if (panSlider) {
        const currentValue = parseInt(panSlider.value);
        const newValue = Math.max(-100, Math.min(100, currentValue + delta));
        panSlider.value = newValue;
        document.getElementById('panValue').textContent = newValue;
        
        // Auto-apply after short delay
        clearTimeout(window.panTiltTimeout);
        window.panTiltTimeout = setTimeout(() => {
            if (typeof setPanTilt === 'function') {
                setPanTilt();
            }
        }, 500);
    }
}

function adjustTilt(delta) {
    const tiltSlider = document.getElementById('tiltSlider');
    if (tiltSlider) {
        const currentValue = parseInt(tiltSlider.value);
        const newValue = Math.max(-100, Math.min(100, currentValue + delta));
        tiltSlider.value = newValue;
        document.getElementById('tiltValue').textContent = newValue;
        
        // Auto-apply after short delay
        clearTimeout(window.panTiltTimeout);
        window.panTiltTimeout = setTimeout(() => {
            if (typeof setPanTilt === 'function') {
                setPanTilt();
            }
        }, 500);
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    setupKeyboardShortcuts();
    
    // Add help tooltip for keyboard shortcuts
    const helpHtml = `
        <div class="position-fixed bottom-0 start-0 p-3">
            <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="collapse" data-bs-target="#keyboardHelp">
                Keyboard Shortcuts
            </button>
            <div class="collapse mt-2" id="keyboardHelp">
                <div class="card card-body">
                    <small>
                        <strong>Keyboard Shortcuts:</strong><br>
                        1-8: Set presets<br>
                        Arrow keys: Pan/Tilt<br>
                        Home: Reset position
                    </small>
                </div>
            </div>
        </div>
    `;
    
    if (document.getElementById('panSlider')) {
        document.body.insertAdjacentHTML('beforeend', helpHtml);
    }
});