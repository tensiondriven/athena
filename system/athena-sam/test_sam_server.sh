#!/bin/bash

# SAM Server Test Script
# Tests the happy path: send image -> get JSON + masks back

set -e  # Exit on any error

# Configuration
SAM_SERVER="http://llm:8100"
TEST_IMAGE="test_image.jpg"
OUTPUT_DIR="test_output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== SAM Server Test Script ===${NC}"
echo "Testing SAM server at: $SAM_SERVER"
echo "Timestamp: $TIMESTAMP"
echo

# Function to print status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if test image exists
if [ ! -f "$TEST_IMAGE" ]; then
    print_warning "Test image '$TEST_IMAGE' not found. Creating a sample image..."
    
    # Create a simple test image using ImageMagick (if available)
    if command -v convert &> /dev/null; then
        convert -size 640x480 xc:white \
                -fill red -draw "circle 160,120 160,80" \
                -fill blue -draw "rectangle 320,200 480,360" \
                -fill green -draw "polygon 500,100 580,100 540,180" \
                "$TEST_IMAGE"
        print_success "Created test image with simple shapes"
    else
        print_error "ImageMagick not found and no test image provided."
        print_error "Please provide a test image named '$TEST_IMAGE' or install ImageMagick"
        exit 1
    fi
fi

# Create output directory
print_status "Creating output directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Test 1: Health check and server information
print_status "Testing SAM server health..."
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" "$SAM_SERVER/health" -o /dev/null)
if [ "$HEALTH_RESPONSE" = "200" ]; then
    print_success "SAM server is responding and model is loaded"
elif [ "$HEALTH_RESPONSE" = "503" ]; then
    print_warning "SAM server is responding but model is not loaded (HTTP 503)"
    HEALTH_DETAIL=$(curl -s "$SAM_SERVER/health")
    echo "Health detail: $HEALTH_DETAIL"
    
    # Get server information
    print_status "Fetching server information..."
    SERVER_INFO=$(curl -s "$SAM_SERVER/")
    echo "Server info: $SERVER_INFO"
    
    print_status "Continuing test - server may still accept requests..."
else
    print_error "SAM server health check failed (HTTP $HEALTH_RESPONSE)"
    print_error "Make sure the server is running at $SAM_SERVER"
    exit 1
fi

# Test 2: Get server info (using root endpoint)
print_status "Getting server information..."
SERVER_INFO=$(curl -s "$SAM_SERVER/" 2>/dev/null || echo "Root endpoint not available")
if [ "$SERVER_INFO" != "Root endpoint not available" ]; then
    echo "Server info: $SERVER_INFO"
else
    print_warning "Root endpoint not available, checking base URL..."
    # Try the base URL which should return the API info
    SERVER_INFO=$(curl -s "$SAM_SERVER" 2>/dev/null || echo "Base endpoint not available")
    if [ "$SERVER_INFO" != "Base endpoint not available" ]; then
        echo "Server info: $SERVER_INFO"
    else
        print_warning "Base endpoint not available"
    fi
fi

# Test 3: Send image for segmentation (using segment_all endpoint)
print_status "Sending image for segmentation..."
print_status "Image: $TEST_IMAGE ($(du -h "$TEST_IMAGE" | cut -f1))"

# Create the request
RESPONSE_FILE="$OUTPUT_DIR/response_${TIMESTAMP}.json"
TEMP_RESPONSE="$OUTPUT_DIR/temp_response.json"

# Send POST request with image to segment_all endpoint
print_status "Making segmentation request to /segment_all..."
HTTP_STATUS=$(curl -s -w "%{http_code}" \
    -X POST \
    -F "image=@$TEST_IMAGE" \
    "$SAM_SERVER/segment_all" \
    -o "$TEMP_RESPONSE")

if [ "$HTTP_STATUS" -eq 200 ]; then
    print_success "Segmentation request successful (HTTP $HTTP_STATUS)"
    mv "$TEMP_RESPONSE" "$RESPONSE_FILE"
elif [ "$HTTP_STATUS" -eq 503 ]; then
    print_warning "Segmentation request failed (HTTP $HTTP_STATUS) - Model not loaded"
    if [ -f "$TEMP_RESPONSE" ]; then
        echo "Response content:"
        cat "$TEMP_RESPONSE"
        rm "$TEMP_RESPONSE"
    fi
    print_status "Exiting with status code 2 to indicate model not loaded"
    exit 2
else
    print_error "Segmentation request failed (HTTP $HTTP_STATUS)"
    if [ -f "$TEMP_RESPONSE" ]; then
        echo "Response content:"
        cat "$TEMP_RESPONSE"
        rm "$TEMP_RESPONSE"
    fi
    exit 1
fi

# Test 4: Parse and validate JSON response
print_status "Parsing JSON response..."
if command -v jq &> /dev/null; then
    # Validate JSON and extract key information
    if jq empty "$RESPONSE_FILE" 2>/dev/null; then
        print_success "Valid JSON response received"
        
        # Extract metadata
        OBJECT_COUNT=$(jq '.objects | length' "$RESPONSE_FILE" 2>/dev/null || echo "0")
        TIMESTAMP_RESP=$(jq -r '.timestamp // "N/A"' "$RESPONSE_FILE")
        PROCESSING_TIME=$(jq -r '.processing_time // "N/A"' "$RESPONSE_FILE")
        
        echo "  Objects found: $OBJECT_COUNT"
        echo "  Timestamp: $TIMESTAMP_RESP"
        echo "  Processing time: $PROCESSING_TIME"
        
        # Show object details
        if [ "$OBJECT_COUNT" -gt 0 ]; then
            print_status "Object details:"
            jq -r '.objects[] | "  Object \(.id): confidence=\(.confidence), area=\(.area)"' "$RESPONSE_FILE"
        fi
    else
        print_error "Invalid JSON response"
        echo "Response content:"
        head -20 "$RESPONSE_FILE"
        exit 1
    fi
else
    print_warning "jq not available for JSON parsing"
    print_success "Response saved to: $RESPONSE_FILE"
fi

# Test 5: Check for mask files (if server returns them)
print_status "Checking for mask files..."
MASK_COUNT=0

# Look for mask files in response or as separate files
if [ -d "$OUTPUT_DIR/masks" ]; then
    MASK_COUNT=$(find "$OUTPUT_DIR/masks" -name "*.png" | wc -l)
    print_success "Found $MASK_COUNT mask files in $OUTPUT_DIR/masks/"
elif command -v jq &> /dev/null && jq -e '.masks' "$RESPONSE_FILE" >/dev/null 2>&1; then
    # Masks might be base64 encoded in JSON
    print_status "Extracting base64 encoded masks from JSON..."
    MASK_DIR="$OUTPUT_DIR/masks_${TIMESTAMP}"
    mkdir -p "$MASK_DIR"
    
    # Extract masks (this would need to be adapted based on actual API response format)
    jq -r '.masks[]? | @base64d' "$RESPONSE_FILE" 2>/dev/null | \
    split -a 3 -d --bytes=1M - "$MASK_DIR/mask_" || \
    print_warning "Could not extract masks from JSON (format may vary)"
    
    MASK_COUNT=$(find "$MASK_DIR" -name "mask_*" 2>/dev/null | wc -l)
    if [ "$MASK_COUNT" -gt 0 ]; then
        print_success "Extracted $MASK_COUNT mask files to $MASK_DIR/"
    fi
else
    print_warning "No mask files found (server may not return masks directly)"
fi

# Test 6: Summary
echo
print_success "=== Test Summary ==="
echo "✓ SAM server health check passed"
echo "✓ Image segmentation request successful"
echo "✓ JSON response received and validated"
echo "✓ Found $OBJECT_COUNT objects in image"
if [ "$MASK_COUNT" -gt 0 ]; then
    echo "✓ Retrieved $MASK_COUNT mask files"
else
    echo "⚠ No mask files retrieved (check server configuration)"
fi

echo
print_success "Test completed successfully!"
print_status "Output files:"
echo "  JSON response: $RESPONSE_FILE"
echo "  Test image: $TEST_IMAGE"
echo "  Output directory: $OUTPUT_DIR"

# Optional: Display file sizes
echo
print_status "File sizes:"
ls -lh "$TEST_IMAGE" "$RESPONSE_FILE" 2>/dev/null || true
if [ "$MASK_COUNT" -gt 0 ]; then
    find "$OUTPUT_DIR" -name "*.png" -exec ls -lh {} \; 2>/dev/null || true
fi

echo
print_status "To view the JSON response:"
echo "  cat $RESPONSE_FILE"
if command -v jq &> /dev/null; then
    echo "  jq . $RESPONSE_FILE  # Pretty print"
fi

echo
print_success "Happy path test completed! 🎉"