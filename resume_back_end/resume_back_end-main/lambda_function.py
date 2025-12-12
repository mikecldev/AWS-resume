import os
import json
import time
import datetime
import logging
import requests
import uuid
import boto3
from decimal import Decimal

# --- Logging Configuration ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# --- Config ---
CORS_HEADERS = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Accept, X-Requested-With',
    'Access-Control-Max-Age': '86400'
}

# DynamoDB configuration
DYNAMODB_TABLE_NAME = None
dynamodb = None

# reCAPTCHA configuration
RECAPTCHA_SECRET_KEY = None
RECAPTCHA_VERIFY_URL = 'https://www.google.com/recaptcha/api/siteverify'
RECAPTCHA_SCORE_THRESHOLD = 0.5  # Minimum score to consider valid (0.0 to 1.0)

# --- Helpers ---
def get_dynamodb_table():
    global dynamodb, DYNAMODB_TABLE_NAME
    if DYNAMODB_TABLE_NAME is None:
        raise ValueError("DynamoDB table name not initialized")

    if dynamodb is None:
        dynamodb = boto3.resource('dynamodb')

    print(f"Accessing DynamoDB table: {DYNAMODB_TABLE_NAME}")
    logging.info(f"Accessing DynamoDB table: {DYNAMODB_TABLE_NAME}")

    return dynamodb.Table(DYNAMODB_TABLE_NAME)

def get_client_ip(event):
    # Debug: Log the event structure to understand where IP comes from
    print(f"Event headers: {event.get('headers', {})}")
    print(f"Event requestContext: {event.get('requestContext', {})}")
    
    # Try to get the real visitor IP from headers
    headers = event.get('headers', {})
    
    # Check common IP headers
    ip_headers = ['X-Client-Ip', 'X-Forwarded-For', 'X-Real-IP', 'X-Forwarded', 'Forwarded-For', 'Forwarded']
    
    for key in ip_headers:
        # Check both exact case and lowercase
        for header_key in [key, key.lower()]:
            ip = headers.get(header_key, None)
            if ip:
                extracted_ip = ip.split(',')[0].split(':')[0].strip()
                print(f"Found IP '{extracted_ip}' from header '{header_key}': {ip}")
                return extracted_ip
    
    # Try to get IP from requestContext (API Gateway specific)
    request_context = event.get('requestContext', {})
    if 'identity' in request_context:
        source_ip = request_context['identity'].get('sourceIp')
        if source_ip:
            print(f"Found IP '{source_ip}' from requestContext.identity.sourceIp")
            return source_ip
    
    # HTTP API format (API Gateway v2)
    if 'http' in request_context:
        source_ip = request_context['http'].get('sourceIp')
        if source_ip:
            print(f"Found IP '{source_ip}' from requestContext.http.sourceIp")
            return source_ip
    
    print("No IP found in headers or requestContext, using fallback: 127.0.0.1")
    return "127.0.0.1"

def verify_recaptcha(token, action='visit'):
    """
    Verify reCAPTCHA v3 token with Google's API
    Returns: (is_valid: bool, score: float, message: str)
    """
    global RECAPTCHA_SECRET_KEY

    if not RECAPTCHA_SECRET_KEY:
        logger.warning("reCAPTCHA secret key not configured")
        return False, 0.0, "reCAPTCHA not configured"

    if not token:
        logger.warning("No reCAPTCHA token provided")
        return False, 0.0, "No token provided"

    try:
        print(f"Verifying reCAPTCHA token for action: {action}")
        logger.info(f"Verifying reCAPTCHA token for action: {action}")

        # Prepare verification request
        payload = {
            'secret': RECAPTCHA_SECRET_KEY,
            'response': token
        }

        # Make verification request to Google
        response = requests.post(RECAPTCHA_VERIFY_URL, data=payload, timeout=3)

        if not response.ok:
            logger.error(f"reCAPTCHA API request failed: {response.status_code}")
            return False, 0.0, f"Verification request failed: {response.status_code}"

        result = response.json()
        print(f"reCAPTCHA verification result: {result}")
        logger.info(f"reCAPTCHA result: {result}")

        # Check if verification was successful
        success = result.get('success', False)
        score = result.get('score', 0.0)
        result_action = result.get('action', '')
        error_codes = result.get('error-codes', [])

        if not success:
            logger.warning(f"reCAPTCHA verification failed: {error_codes}")
            return False, score, f"Verification failed: {error_codes}"

        # Verify action matches
        if result_action != action:
            logger.warning(f"Action mismatch: expected '{action}', got '{result_action}'")
            return False, score, f"Action mismatch"

        # Check score threshold
        if score < RECAPTCHA_SCORE_THRESHOLD:
            logger.warning(f"reCAPTCHA score too low: {score} < {RECAPTCHA_SCORE_THRESHOLD}")
            return False, score, f"Score too low: {score}"

        logger.info(f"reCAPTCHA verification successful - Score: {score}")
        print(f"reCAPTCHA verified successfully - Score: {score}")
        return True, score, "Success"

    except requests.exceptions.Timeout:
        logger.error("reCAPTCHA verification timeout")
        return False, 0.0, "Verification timeout"
    except Exception as e:
        logger.error(f"reCAPTCHA verification error: {str(e)}")
        return False, 0.0, f"Verification error: {str(e)}"

def geolocate_ip(ip):
    print(f"Geolocating IP: '{ip}' (type: {type(ip)}, length: {len(str(ip))})")
    logging.info(f"Geolocating IP: {ip}")

    # Check for local/private IPs with proper ranges
    ip_str = str(ip).strip()

    # Check for obvious local IPs
    if ip_str.startswith(('127.', '192.168.', '10.', '::1')) or ip_str == 'localhost':
        print(f"IP '{ip_str}' is local/private - using Local Network")
        return 0.0, 0.0, "Local Network"

    # Check for 172.16.0.0 to 172.31.255.255 range (actual private range)
    if ip_str.startswith('172.'):
        try:
            parts = ip_str.split('.')
            if len(parts) >= 2:
                second_octet = int(parts[1])
                if 16 <= second_octet <= 31:
                    print(f"IP '{ip_str}' is in private 172.16-31.x.x range - using Local Network")
                    return 0.0, 0.0, "Local Network"
        except (ValueError, IndexError):
            pass

    print(f"IP '{ip_str}' is public - proceeding with geolocation API")

    # Use ipinfo.io for geolocation
    try:
        url = f'https://ipinfo.io/{ip}/json'
        print(f"Making geolocation API call to ipinfo.io for IP: {ip}")
        print(f"URL: {url}")
        logging.info(f"Trying geolocation service: ipinfo.io")

        resp = requests.get(url, timeout=3)

        if resp.ok:
            data = resp.json()
            print(f"ipinfo.io API response: {data}")

            # Parse ipinfo.io response format
            lat = lon = None
            if 'loc' in data:
                loc_parts = data['loc'].split(',')
                if len(loc_parts) == 2:
                    lat = float(loc_parts[0])
                    lon = float(loc_parts[1])

            city = data.get('city')
            country = data.get('country')

            if lat and lon:
                info = ', '.join(filter(None, [city, country]))
                result = (float(lat), float(lon), info or 'Unknown Location')
                print(f"Geolocation successful via ipinfo.io: {result}")
                return result
            else:
                print(f"ipinfo.io returned incomplete data")
        else:
            print(f"ipinfo.io returned status: {resp.status_code}")

    except Exception as e:
        print(f"ipinfo.io API error: {str(e)}")
        logging.warning(f"ipinfo.io error: {str(e)}")

    print("Geolocation service failed - using fallback: Unknown")
    return 0.0, 0.0, "Unknown"

# --- Lambda Handler ---
def lambda_handler(event, context):
    global DYNAMODB_TABLE_NAME, RECAPTCHA_SECRET_KEY

    try:
        # Initialize logging first
        print("Lambda function started")  # This always shows in CloudWatch
        logging.info("Lambda function started - initializing...")

        # Initialize DynamoDB table name
        if DYNAMODB_TABLE_NAME is None:
            logging.info("Initializing DynamoDB configuration...")

            # Read DynamoDB table name from environment variable
            table_name = os.environ.get('DYNAMODB_TABLE_NAME')

            # Log environment variable status
            logging.info(f"Environment variable - DYNAMODB_TABLE_NAME: {'SET' if table_name else 'NOT SET'}")

            # Validate required environment variable
            if not table_name:
                error_msg = "Missing required environment variable: DYNAMODB_TABLE_NAME"
                logging.error(error_msg)
                return {
                    'statusCode': 500,
                    'headers': CORS_HEADERS,
                    'body': json.dumps({'error': error_msg})
                }

            DYNAMODB_TABLE_NAME = table_name
            logging.info(f"DynamoDB table name initialized successfully: {DYNAMODB_TABLE_NAME}")

        # Initialize reCAPTCHA secret key
        if RECAPTCHA_SECRET_KEY is None:
            logging.info("Initializing reCAPTCHA configuration...")

            # Read reCAPTCHA secret key from environment variable
            secret_key = os.environ.get('RECAPTCHA_SECRET_KEY')

            # Log environment variable status
            logging.info(f"Environment variable - RECAPTCHA_SECRET_KEY: {'SET' if secret_key else 'NOT SET'}")

            if secret_key:
                RECAPTCHA_SECRET_KEY = secret_key
                logging.info("reCAPTCHA secret key initialized successfully")
            else:
                logging.warning("reCAPTCHA secret key not configured - bot protection disabled")
        
        # Log the incoming event
        logging.info(f"Received event: {json.dumps(event)}")
        
        path = event.get('path') or event.get('rawPath', '')
        method = event.get('httpMethod') or event.get('requestContext', {}).get('http', {}).get('method', '')
        
        logging.info(f"Path: {path}, Method: {method}")

        # Handle OPTIONS request for CORS preflight
        if method == 'OPTIONS':
            logging.info("Handling OPTIONS request for CORS preflight")
            return {
                'statusCode': 200,
                'headers': CORS_HEADERS,
                'body': json.dumps({'message': 'CORS preflight successful'})
            }

        if path == '/visit' and method == 'POST':
            return store_visit_and_get_data(event)
        else:
            logging.warning(f"Unknown endpoint requested: {method} {path}")
            return {
                'statusCode': 404,
                'headers': CORS_HEADERS,
                'body': json.dumps({'error': 'Endpoint not found. Only POST /visit is available.'})
            }
            
    except Exception as e:
        error_msg = f"Lambda handler error: {str(e)}"
        print(f"ERROR: {error_msg}")  # This always shows in CloudWatch
        logging.error(error_msg, exc_info=True)
        return {
            'statusCode': 500,
            'headers': CORS_HEADERS,
            'body': json.dumps({'error': error_msg})
        }

# --- /visit (POST): Store visit and return locations + counter
def store_visit_and_get_data(event):
    print("Starting store_visit_and_get_data request")  # Always visible
    logging.info("Starting store_visit_and_get_data request")

    try:
        # Parse request body
        body = event.get('body', '{}')
        if isinstance(body, str):
            body_data = json.loads(body)
        else:
            body_data = body

        # Verify reCAPTCHA token if provided
        recaptcha_token = body_data.get('recaptchaToken')
        if recaptcha_token:
            is_valid, score, message = verify_recaptcha(recaptcha_token, action='visit')

            if not is_valid:
                logger.warning(f"Bot detected - reCAPTCHA verification failed: {message} (score: {score})")
                print(f"Bot detected - Request rejected: {message}")

                # Return error response for bot traffic
                return {
                    'statusCode': 403,
                    'headers': CORS_HEADERS,
                    'body': json.dumps({
                        'error': 'Bot detection: Request failed verification',
                        'message': 'This request appears to be from a bot',
                        'score': score
                    })
                }
            else:
                logger.info(f"reCAPTCHA verification passed - Score: {score}")
                print(f"Valid visitor verified - Score: {score}")
        else:
            logger.warning("No reCAPTCHA token provided in request")
            print("No reCAPTCHA token provided - proceeding without verification")

        # Get client IP and geolocation
        ip = get_client_ip(event)

        # Also check if IP is provided in the request body (from frontend)
        try:
            frontend_ip = body_data.get('ip')
            if frontend_ip and frontend_ip != ip:
                print(f"Frontend provided IP: {frontend_ip}, API Gateway IP: {ip}")
                logging.info(f"Using frontend-provided IP: {frontend_ip} instead of API Gateway IP: {ip}")
                ip = frontend_ip
        except (json.JSONDecodeError, Exception) as e:
            print(f"Could not parse request body for IP: {e}")
        
        print(f"Final Client IP: {ip}")
        logging.info(f"Client IP: {ip}")
        
        print(f"About to geolocate IP: '{ip}' (raw)")
        lat, lon, info = geolocate_ip(ip)
        print(f"Geolocation result: '{info}' at coordinates ({lat}, {lon})")
        logging.info(f"Geolocation: {info} at ({lat}, {lon})")
        
        now = datetime.datetime.utcnow()
        
    except Exception as e:
        print(f"Error in initial processing: {str(e)}")
        logging.error(f"Error in initial processing: {str(e)}")
        # Use fallback values
        ip = "127.0.0.1"
        lat, lon, info = 0.0, 0.0, "Unknown"
        now = datetime.datetime.utcnow()
    
    try:
        # Get DynamoDB table
        print("Accessing DynamoDB table")
        logging.info("Accessing DynamoDB table")

        table = get_dynamodb_table()
        print("DynamoDB table accessed successfully")
        logging.info("DynamoDB table accessed successfully")

        # Store the visit location
        print("Storing visit location in DynamoDB")
        logging.info("Storing visit location")

        # Generate unique visit ID using timestamp and UUID
        visit_id = f"{int(now.timestamp() * 1000000)}_{uuid.uuid4().hex[:8]}"

        # DynamoDB requires Decimal for float values
        item = {
            'visit_id': visit_id,
            'latitude': Decimal(str(lat)),
            'longitude': Decimal(str(lon)),
            'timestamp': now.isoformat(),
            'info': info
        }

        table.put_item(Item=item)
        print("Visit location stored successfully")
        logging.info(f"Visit stored with ID: {visit_id}")

        # Get all visits from DynamoDB
        print("Scanning DynamoDB for all visits")
        logging.info("Scanning DynamoDB for all visits")

        response = table.scan()
        items = response.get('Items', [])

        # Handle pagination if there are more items
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            items.extend(response.get('Items', []))

        total_visits = len(items)
        print(f"Total visits: {total_visits}")
        logging.info(f"Total visits: {total_visits}")

        # Aggregate locations by info, latitude, longitude
        print("Aggregating locations data")
        logging.info("Aggregating locations data")

        location_groups = {}
        for item in items:
            # Create a key from info, lat, lon
            location_info = item.get('info', 'Unknown')
            location_lat = float(item.get('latitude', 0))
            location_lon = float(item.get('longitude', 0))

            key = (location_info, location_lat, location_lon)

            if key not in location_groups:
                location_groups[key] = 0
            location_groups[key] += 1

        # Convert to list format
        locations = []
        for (location_info, location_lat, location_lon), views in location_groups.items():
            location_data = {
                'info': location_info,
                'lat': location_lat,
                'lng': location_lon,
                'views': views
            }
            locations.append(location_data)

        # Sort by views descending
        locations.sort(key=lambda x: x['views'], reverse=True)

        print(f"Aggregated {len(locations)} unique locations")
        logging.info(f"Aggregated {len(locations)} unique locations")
        print("DynamoDB operations completed successfully")
        
        logging.info(f"Successfully processed {len(locations)} locations with total visits: {total_visits}")
        
        # Return combined response
        response_data = {
            'count': total_visits,
            'current_visit': {
                'location': info,
                'coordinates': {'lat': lat, 'lon': lon}
            },
            'locations': locations
        }
        
        print("Returning successful response")
        return {
            'statusCode': 200,
            'headers': CORS_HEADERS,
            'body': json.dumps(response_data)
        }
        
    except Exception as e:
        error_msg = f"Error in store_visit_and_get_data: {str(e)}"
        logging.error(error_msg, exc_info=True)
        return {
            'statusCode': 500, 
            'headers': CORS_HEADERS, 
            'body': json.dumps({
                'error': str(e),
                'count': 0,
                'current_visit': None,
                'locations': []
            })
        }
