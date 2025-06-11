#!/usr/bin/env python3
"""
MCP server for time operations including sunset calculations
"""

import json
import sys
from datetime import datetime, timedelta
import math
from zoneinfo import ZoneInfo

def calculate_sunset(date, latitude=43.0731, longitude=-89.4012):
    """
    Calculate approximate sunset time for given date and location.
    Default location is Madison, WI.
    Uses simplified astronomical calculations.
    """
    # Day of year
    n = date.timetuple().tm_yday
    
    # Solar declination angle
    P = math.asin(0.39795 * math.cos(math.radians(0.98563 * (n - 173) + 1.914 * math.sin(math.radians(0.98563 * (n - 2))))))
    
    # Sunrise/sunset hour angle
    sunrise_angle = math.degrees(math.acos(-math.tan(math.radians(latitude)) * math.tan(P)))
    
    # Time correction for longitude
    time_correction = 4 * (longitude - 0) / 60  # 0 is reference meridian for CST/CDT
    
    # Equation of time (approximation)
    B = 2 * math.pi * (n - 81) / 365
    E = 9.87 * math.sin(2 * B) - 7.53 * math.cos(B) - 1.5 * math.sin(B)
    
    # Solar noon and sunset time (in decimal hours)
    solar_noon = 12 - time_correction - E / 60
    sunset_decimal = solar_noon + sunrise_angle / 15
    
    # Convert to hours and minutes, clamping to valid range
    sunset_hour = int(sunset_decimal) % 24
    sunset_minute = int((sunset_decimal - int(sunset_decimal)) * 60) % 60
    
    # Ensure sunset is in reasonable range (typically between 4 PM and 9 PM)
    if sunset_hour < 16:
        sunset_hour = 16  # 4 PM minimum
    elif sunset_hour > 21:
        sunset_hour = 21  # 9 PM maximum
    
    return sunset_hour, sunset_minute

def get_timezone_for_location(location_name):
    """Get timezone for common US locations"""
    timezones = {
        "madison": "America/Chicago",
        "chicago": "America/Chicago",
        "milwaukee": "America/Chicago",
        "new york": "America/New_York",
        "los angeles": "America/Los_Angeles",
        "denver": "America/Denver",
        "phoenix": "America/Phoenix",
        "seattle": "America/Los_Angeles",
        "miami": "America/New_York",
        "atlanta": "America/New_York",
        "boston": "America/New_York",
        "dallas": "America/Chicago",
        "houston": "America/Chicago"
    }
    return timezones.get(location_name.lower(), "America/Chicago")

def handle_request(request):
    """Handle JSON-RPC request"""
    method = request.get("method")
    params = request.get("params", {})
    request_id = request.get("id")
    
    if method == "get_current_time":
        # Get location from params or default to Madison
        location = params.get("location", "madison")
        timezone_str = get_timezone_for_location(location)
        
        try:
            tz = ZoneInfo(timezone_str)
            now = datetime.now(tz)
            
            # Format date and time
            date_str = now.strftime("%A, %B %d, %Y")
            time_str = now.strftime("%I:%M %p").lstrip('0')
            
            # Determine if afternoon
            is_afternoon = now.hour >= 12
            
            # Calculate sunset and time until sunset if afternoon
            sunset_info = None
            if is_afternoon:
                sunset_hour, sunset_minute = calculate_sunset(now)
                sunset_time = now.replace(hour=sunset_hour, minute=sunset_minute, second=0, microsecond=0)
                
                if now < sunset_time:
                    time_until_sunset = sunset_time - now
                    hours_until = int(time_until_sunset.total_seconds() // 3600)
                    minutes_until = int((time_until_sunset.total_seconds() % 3600) // 60)
                    
                    sunset_info = {
                        "sunset_time": sunset_time.strftime("%I:%M %p").lstrip('0'),
                        "hours_until_sunset": hours_until,
                        "minutes_until_sunset": minutes_until,
                        "time_until_sunset": f"{hours_until}h {minutes_until}m" if hours_until > 0 else f"{minutes_until}m"
                    }
                else:
                    sunset_info = {
                        "sunset_time": sunset_time.strftime("%I:%M %p").lstrip('0'),
                        "sunset_passed": True,
                        "message": "The sun has already set today"
                    }
            
            result = {
                "success": True,
                "date": date_str,
                "time": time_str,
                "timezone": timezone_str,
                "location": location.title(),
                "is_afternoon": is_afternoon,
                "unix_timestamp": int(now.timestamp()),
                "iso_timestamp": now.isoformat()
            }
            
            if sunset_info:
                result["sunset_info"] = sunset_info
            
            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": result
            }
            
        except Exception as e:
            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "error": {
                    "code": -32603,
                    "message": f"Error getting time: {str(e)}"
                }
            }
    
    elif method == "list_timezones":
        # List supported locations
        locations = [
            "Madison", "Chicago", "Milwaukee", "New York", "Los Angeles",
            "Denver", "Phoenix", "Seattle", "Miami", "Atlanta", "Boston",
            "Dallas", "Houston"
        ]
        
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "success": True,
                "supported_locations": locations,
                "default": "Madison"
            }
        }
    
    else:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {
                "code": -32601,
                "message": f"Method not found: {method}"
            }
        }

def main():
    # Read JSON-RPC request from stdin
    try:
        request_str = sys.stdin.read()
        request = json.loads(request_str)
        
        # Handle the request
        response = handle_request(request)
        
        # Write response to stdout
        print(json.dumps(response))
        
    except json.JSONDecodeError as e:
        error_response = {
            "jsonrpc": "2.0",
            "id": None,
            "error": {
                "code": -32700,
                "message": f"Parse error: {str(e)}"
            }
        }
        print(json.dumps(error_response))
    except Exception as e:
        error_response = {
            "jsonrpc": "2.0",
            "id": None,
            "error": {
                "code": -32603,
                "message": f"Internal error: {str(e)}"
            }
        }
        print(json.dumps(error_response))

if __name__ == "__main__":
    main()