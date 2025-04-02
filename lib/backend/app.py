from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import secrets
from bson import ObjectId
import traceback  # Import the traceback module
import base64
import json
from bson import json_util  # Import json_util
import pymongo
import pytz  # To help make timezones.
import os
from flask import send_from_directory

app = Flask(__name__)
CORS(app)


# Configuration
UPLOAD_FOLDER = 'uploads'  # Define the upload folder
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER  # Set the configuration variable
os.makedirs(UPLOAD_FOLDER, exist_ok=True)  # Create folder if it doesn't exist


MONGO_URI = "mongodb://localhost:27017/urban_drive"
DB_NAME = "urban_drive"
USERS_COLLECTION = "users"
CARS_COLLECTION = "cars"
BOOKINGS_COLLECTION = "bookings"
TRIPS_COLLECTION = "trips"  # New collection for trips
REVIEWS_COLLECTION = "reviews"
DASHBOARD_METRICS_COLLECTION = "dashboard_metrics"
BANNER_COLLECTION = 'banner_images'  # Changed Collection name



client = MongoClient(MONGO_URI)
db = client[DB_NAME]
users_collection = db[USERS_COLLECTION]
cars_collection = db[CARS_COLLECTION]
bookings_collection = db[BOOKINGS_COLLECTION]
trips_collection = db[TRIPS_COLLECTION]  # Initialize trips collection
reviews_collection = db[REVIEWS_COLLECTION]
dashboard_metrics_collection = db[DASHBOARD_METRICS_COLLECTION] # define the collection similar to other collections
banners_collection = db[BANNER_COLLECTION]  # Define the uploads collection


def validate_register_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400
    required_fields = ["email", "password", "phone", "dob", "gender"]
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["email"], str) or not data["email"] or '@' not in data["email"]:
        return "Invalid email format", 400
    if not isinstance(data["password"], str) or len(data["password"]) < 8:
        return "Password must be a string and at least 8 characters long", 400
    if not isinstance(data["phone"], str) or not data["phone"].isdigit() or len(data["phone"]) < 10:
        return "Phone must be a string of at least 10 digits", 400
    try:
        datetime.strptime(data["dob"], "%d/%m/%Y")
    except ValueError:
        return "Invalid date format. Please use DD/MM/YYYY", 400
    if data['gender'] not in ['Male', 'Female']:
        return "Invalid gender option", 400
    if users_collection.find_one({'email': data['email']}):
        return 'Email already registered', 409
    return None, 200


@app.route('/register', methods=['POST'])
def register_user():
    data = request.get_json()
    validation_message, status_code = validate_register_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    hashed_password = generate_password_hash(data['password'])
    user_data = {
        'email': data['email'],
        'password': hashed_password,
        'phone': data['phone'],
        'dob': data['dob'],
        'gender': data['gender'],
        'created_at': datetime.now(),
        'role': 'user',
        'profileImage': None
    }
    try:
        user_id = users_collection.insert_one(user_data).inserted_id
        return jsonify({'message': 'User registered successfully', 'user_id': str(user_id)}), 201
    except Exception as e:
        return jsonify({'message': 'Failed to register user', 'error': str(e)}), 500


def validate_login_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400
    required_fields = ["email", "password"]
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["email"], str) or not data["email"] or '@' not in data["email"]:
        return "Invalid email format", 400
    if not isinstance(data["password"], str) or not data["password"]:
        return "Password is required", 400
    return None, 200


@app.route('/login', methods=['POST'])
def login_user():
    data = request.get_json()
    validation_message, status_code = validate_login_data(data)
    if validation_message:
            return jsonify({'message': validation_message}), status_code
    user = users_collection.find_one({'email': data['email']})
    if user and check_password_hash(user['password'], data['password']):
        users_collection.update_one({'email': data['email']}, {'$set': {'role': 'user'}})
        return jsonify({'message': 'Login successful', 'userName': user['email'].split('@')[0], 'email': user['email'],
                            'phone': user['phone'], 'userId': str(user['_id'])}), 200
    else:
        return jsonify({'message': 'Invalid credentials'}), 401


def validate_forgot_password_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400
    if "email" not in data:
        return "Missing email field", 400
    if not isinstance(data["email"], str) or not data["email"] or '@' not in data["email"]:
        return "Invalid email format", 400
    return None, 200


@app.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    validation_message, status_code = validate_forgot_password_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    user = users_collection.find_one({'email': data['email']})
    if not user:
        return jsonify({'message': 'User not found with this email'}), 404
    reset_token = secrets.token_urlsafe(32)
    users_collection.update_one({'email': data['email']}, {'$set': {'reset_token': reset_token}})
    print("Reset token", reset_token)
    return jsonify({'message': 'Reset token generated, check your email', 'reset_token': reset_token}), 200


def validate_reset_password_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400
    required_fields = ["email", "reset_token", "new_password"]
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["email"], str) or not data["email"] or '@' not in data["email"]:
        return "Invalid email format", 400
    if not isinstance(data["reset_token"], str) or not data["reset_token"]:
        return "Invalid reset token", 400
    if not isinstance(data["new_password"], str) or len(data["new_password"]) < 8:
        return "Password must be a string and at least 8 characters long", 400
    return None, 200


@app.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    validation_message, status_code = validate_reset_password_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    user = users_collection.find_one({'email': data['email'], 'reset_token': data['reset_token']})
    if not user:
        return jsonify({'message': 'Invalid reset token or email'}), 400
    new_hashed_password = generate_password_hash(data['new_password'])
    users_collection.update_one({'email': data['email']},
                               {'$set': {'password': new_hashed_password, 'reset_token': None}})
    return jsonify({'message': 'Password reset successfully'}), 200


def validate_switch_role_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400
    required_fields = ["email", "password", "current_email"]
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["email"], str) or not data["email"] or '@' not in data["email"]:
        return "Invalid email format", 400
    if not isinstance(data["password"], str) or not data["password"]:
        return "Password is required", 400
    if not isinstance(data["current_email"], str) or not data["current_email"] or '@' not in data["current_email"]:
        return "Invalid current email format", 400
    return None, 200


@app.route('/switch-role', methods=['POST'])
def switch_role():
    data = request.get_json()
    validation_message, status_code = validate_switch_role_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    user = users_collection.find_one({'email': data['current_email']})
    if not user:
        return jsonify({'message': 'Invalid current email'}), 401
    if user and check_password_hash(user['password'], data['password']) and user['email'] == data['email']:
        current_role = user.get('role', 'user')
        new_role = 'host' if current_role == 'user' else 'user'
        users_collection.update_one({'email': data['current_email']}, {'$set': {'role': new_role}})
        return jsonify({'message': f'Role changed to {new_role}', 'role': new_role}), 200
    else:
        return jsonify({'message': 'Invalid credentials'}), 401


def validate_update_profile_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400

    required_fields = ["current_email", "userName", "phone"]
    missing_fields = [field for field in required_fields if field not in data]

    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400

    if not isinstance(data["current_email"], str) or not data["current_email"] or '@' not in data["current_email"]:
        return "Invalid current email format", 400
    if not isinstance(data["userName"], str):
        return "Username is required", 400
    if not isinstance(data["phone"], str):
        return "Phone must be a string", 400

    return None, 200


@app.route('/update-profile', methods=['POST'])
def update_profile():
    data = request.get_json()

    validation_message, status_code = validate_update_profile_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code

    print("Searching for:", data["current_email"])
    user = users_collection.find_one({'email': data['current_email']})
    print("User found:", user)

    if user:
        update_data = {}
        if "userName" in data and data["userName"]:
            update_data['userName'] = data['userName']
        if "phone" in data and data["phone"]:
            update_data['phone'] = data['phone']

        if update_data:
            users_collection.update_one({'email': data['current_email']}, {'$set': update_data})

        return jsonify({'message': 'Profile Updated Successfully'}), 200
    else:
        return jsonify({'message': 'User not found'}), 404


def validate_update_profile_picture_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400
    required_fields = ["email"]
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["email"], str) or not data["email"] or '@' not in data["email"]:
        return "Invalid email format", 400
    return None, 200


@app.route('/update-profile-picture', methods=['POST'])
def update_profile_picture():
    data = request.get_json()
    validation_message, status_code = validate_update_profile_picture_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    user = users_collection.find_one({'email': data['email']})
    if not user:
        return jsonify({'message': 'User not found'}), 404
    profile_image = data.get('profileImage')
    users_collection.update_one(
        {'email': data['email']},
        {'$set': {'profileImage': profile_image}}
    )
    return jsonify({'message': 'Profile picture updated successfully'}), 200


def validate_get_user_data(data):
    if not isinstance(data, dict):
        return "Invalid data type, data should be a dictionary", 400
    if "email" not in data:
        return "Missing email field", 400
    if not isinstance(data["email"], str) or not data["email"] or '@' not in data["email"]:
        return "Invalid email format", 400
    return None, 200


@app.route('/get-user-data', methods=['POST'])
def get_user_data():
    data = request.get_json()
    validation_message, status_code = validate_get_user_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    user = users_collection.find_one({'email': data['email']})
    if user:
        user_data = {
            'userName': user.get('userName', user['email'].split('@')[0]),
            'phone': user.get('phone', '+91 - 9033056422'),
            'email': user['email'],
            'profileImage': user.get('profileImage'),
        }
        return jsonify(user_data), 200
    else:
        return jsonify({'message': 'User not found'}), 404


def validate_add_car_data(data):
    if not isinstance(data, dict):
        return "Invalid data type: Data should be a dictionary", 400


    required_fields = [
        "userId",
        "CarRegistrationNumber",
        "carBrand",
        "carModel",
        "yearOfRegistration",
        "city",
        "kmDriven",
        "chassisNumber",
        "fuelType",
        "transmissionType",
        "pricePerHour",
        "pickupLocation",
        "seatingCapacity",
        "bodyType",
        "startDate",
        "startTime",
        "endDate",
        "endTime",
        "coverImageBytes",
        "exteriorImageBytes",
        "interiorImageBytes"
    ]
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["userId"], str) or not data["userId"]:
        return "Invalid userId format", 400
    return None, 200


@app.route('/add-car', methods=['POST'])
def add_car():
    data = request.get_json()
    validation_message, status_code = validate_add_car_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code


    try:
        car_data = {
            'userId': data['userId'],
            'CarRegistrationNumber': data['CarRegistrationNumber'],
            'carBrand': data['carBrand'],
            'carModel': data['carModel'],
            'yearOfRegistration': data['yearOfRegistration'],
            'city': data['city'],
            'kmDriven': data['kmDriven'],
            'chassisNumber': data['chassisNumber'],
            'fuelType': data['fuelType'],
            'transmissionType': data['transmissionType'],
            'pricePerHour': data['pricePerHour'],
            'pickupLocation': data['pickupLocation'],
            'seatingCapacity': data['seatingCapacity'],
            'bodyType': data['bodyType'],
            'startDate': data['startDate'],
            'startTime': data['startTime'],
            'endDate': data['endDate'],
            'endTime': data['endTime'],
            'coverImageBytes': data['coverImageBytes'],
            'exteriorImageBytes': data['exteriorImageBytes'],
            'interiorImageBytes': data['interiorImageBytes'],
            'created_at': datetime.now(),
            'is_available':True #setting default value true
        }

        car_id = cars_collection.insert_one(car_data).inserted_id
        return jsonify({'message': 'Car details added successfully', 'car_id': str(car_id)}), 201
    except Exception as e:
        return jsonify({'message': 'Failed to add car details', 'error': str(e)}), 500


def validate_get_cars_by_host_data(data):
    if not isinstance(data, dict):
        return "Invalid data type, data should be a dictionary", 400
    if "userId" not in data:
        return "Missing userId field", 400
    if not isinstance(data["userId"], str) or not data["userId"]:
        return "Invalid userId format", 400
    return None, 200


@app.route('/get-cars-by-host', methods=['POST'])
def get_cars_by_host():
    data = request.get_json()
    validation_message, status_code = validate_get_cars_by_host_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code

    try:
        cars = list(cars_collection.find({'userId': data['userId']}))
        for car in cars:
          car['_id'] = str(car['_id'])
        return jsonify(cars), 200
    except Exception as e:
        return jsonify({'message': 'Failed to fetch cars', 'error': str(e)}), 500



def validate_get_all_cars_data(data):
    if not isinstance(data, dict):
        return "Invalid data type, data should be a dictionary", 400
    if "email" not in data:
        return "Missing email field", 400
    if not isinstance(data["email"], str) or not data["email"] or '@' not in data["email"]:
         return "Invalid email format", 400
    if "userId" not in data:  # Check for userId
        return "Missing userId field", 400  # Corrected error message
    if not isinstance(data["userId"], str) or not data["userId"]:  # Validate userId
        return "Invalid userId format", 400 # Corrected error message
    return None, 200


@app.route('/get-all-cars',methods=['POST'])
def get_all_cars():
    data = request.get_json()
    validation_message,status_code = validate_get_all_cars_data(data)
    if validation_message:
      return jsonify({'message':validation_message}), status_code

    user = users_collection.find_one({'email':data['email']})

    if not user:
        return jsonify({'message': 'User not found'}), 404

    if user.get('role') == 'host':
          return jsonify({'message':'Host can not see other cars'}),401
    try:
        now = datetime.now()
        # Convert to string for correct comparison format
        current_date = now.strftime("%Y-%m-%d")
        current_time = now.strftime("%H:%M")


        cars = list(cars_collection.find({
           'userId':{'$ne':data['userId']}, #only hosted by other user not their cars
            'is_available': {'$ne': False}, #exclude is_available false
             '$or':[
                 {
                     'endDate':{'$gt':current_date},
                    },
                {
                    'endDate':current_date,
                    'endTime':{'$gt':current_time}


                 }
                ]
        }))


        for car in cars:
            car['_id'] = str(car['_id'])
        return jsonify(cars),200
    except Exception as e:
        return jsonify({'message':'Failed to fetch cars','error':str(e)}),500


def validate_delete_car_data(data):
    if not isinstance(data,dict):
        return 'Invalid data type: data should be a dictionary', 400
    if 'carId' not in data:
        return 'Missing carId field',400
    if not isinstance(data['carId'],str) or not data['carId']:
         return "Invalid carId format",400
    return None, 200


@app.route('/delete-car', methods=['POST'])
def delete_car():
    data = request.get_json()
    validation_message,status_code = validate_delete_car_data(data)
    if validation_message:
         return jsonify({'message':validation_message}), status_code
    try:
        result = cars_collection.delete_one({'_id':ObjectId(data['carId'])})
        if result.deleted_count == 1:
            return jsonify({'message':'Car deleted successfully'}), 200
        else:
             return jsonify({'message': 'Car not found'}), 404
    except Exception as e:
        return jsonify({'message': 'Failed to delete car', 'error': str(e)}), 500


def validate_update_car_data(data):
    if not isinstance(data, dict):
        return "Invalid data type: Data should be a dictionary", 400
    required_fields = [
        "carId",
        "city",
        "kmDriven",
        "fuelType",
        "pricePerHour",
        "pickupLocation",
        "startDate",
        "startTime",
        "endDate",
        "endTime",
    ]
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
       return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["carId"], str) or not data["carId"]:
     return "Invalid carId format", 400
    return None, 200


@app.route('/update-car', methods=['POST'])
def update_car():
    data = request.get_json()
    validation_message, status_code = validate_update_car_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code


    try:
        car_id = data['carId']
        update_data = {
           'city': data['city'],
            'kmDriven': data['kmDriven'],
            'fuelType': data['fuelType'],
            'pricePerHour': data['pricePerHour'],
            'pickupLocation': data['pickupLocation'],
            'startDate': data['startDate'],
            'startTime': data['startTime'],
            'endDate': data['endDate'],
            'endTime': data['endTime'],
        }
        if 'coverImageBytes' in data:
           update_data['coverImageBytes'] = data['coverImageBytes']
        if 'exteriorImageBytes' in data:
            update_data['exteriorImageBytes'] = data['exteriorImageBytes']
        if 'interiorImageBytes' in data:
           update_data['interiorImageBytes'] = data['interiorImageBytes']


        result = cars_collection.update_one({'_id': ObjectId(car_id)}, {'$set': update_data})


        if result.modified_count > 0:
            return jsonify({'message': 'Car details updated successfully'}), 200
        else:
            return jsonify({'message': 'Car not found or no changes to update'}), 404
    except Exception as e:
        return jsonify({'message': 'Failed to update car details', 'error': str(e)}), 500
   
@app.route('/get-car-by-id', methods=['POST'])
def get_car_by_id():
    data = request.get_json()
    car_id = data.get('carId')


    if not car_id:
        return jsonify({'message': 'Missing carId'}), 400


    try:
        car = cars_collection.find_one({'_id': ObjectId(car_id)})
        if car:
            # Convert ObjectId to string
            car['_id'] = str(car['_id'])
            return jsonify(car), 200
        else:
            return jsonify({'message': 'Car not found'}), 404
    except Exception as e:
        return jsonify({'message': 'Failed to fetch car', 'error': str(e)}), 500
   
def validate_create_booking_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400
    required_fields = [
        "userId",
        "carId",
        "carRegNumber",
        "pickupTime",
        "returnTime",
        "frontImage",
        "backImage",
        "amount",
        "paymentMethod",
        "paymentStatus",
        "numberOfHours"  # ADD THIS: Require numberOfHours from the frontend
    ]
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
      return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["userId"], str) or not data["userId"]:
      return "Invalid userId format", 400
    if not isinstance(data["carId"], str) or not data["carId"]:
      return "Invalid carId format", 400
    if not isinstance(data["carRegNumber"], str) or not data["carRegNumber"]:
      return "Invalid car registration number format", 400
    if not isinstance(data["pickupTime"],str) or not data["pickupTime"]:
        return 'Invalid pickupTime',400
    if not isinstance(data['returnTime'],str) or not data['returnTime']:
        return 'Invalid returnTime',400
    if not isinstance(data["paymentMethod"], str) or not data["paymentMethod"]:
      return "Invalid payment method format", 400
    if not isinstance(data["paymentStatus"], str) or not data["paymentStatus"]:
      return "Invalid payment status format", 400
    if not isinstance(data["amount"], (int, float)):
        return "Invalid amount", 400
    # ADD THIS: Validate numberOfHours
    if not isinstance(data["numberOfHours"], (int, float)):
        return "Invalid numberOfHours", 400
    if data["numberOfHours"] <= 0:  # Or any other reasonable minimum
        return "numberOfHours must be positive", 400

    return None, 200


@app.route('/create-booking', methods=['POST'])
def create_booking():
    data = request.get_json()
    validation_message, status_code = validate_create_booking_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    try:
        car = cars_collection.find_one({'_id':ObjectId(data['carId'])})
        if not car:
            return jsonify({'message':'Car not found'}),404


        # *** FIX: Get user ID from email (assuming data['userId'] is currently the email) ***
        user = users_collection.find_one({'_id': ObjectId(data['userId']) }) #find the user _id
        if not user:
            return jsonify({'message': 'User not found'}), 404


        user_id = user['_id']
        # Convert to string for trip table
        user_id_str = str(user_id)
        print(f"CREATE_BOOKING: User _id from email {data['userId']}: {user_id_str}")  # ADDED LOGGING


        # Calculate total amount:
        base_amount = data['amount']
        number_of_hours = data['numberOfHours']
        total_amount = base_amount * number_of_hours #calculate total amount
        print(f"Calculated total_amount: {total_amount}")


        booking_data = {
            'userId': user_id_str, # Store the ObjectId as a String
            'carId': data['carId'],
            'carRegNumber': data['carRegNumber'],
            'pickupTime':data['pickupTime'],
            'returnTime':data['returnTime'],
          'frontImage':data['frontImage'], # ensure image is being properly formatted as base64 String
          'backImage':data['backImage'], # ensure image is being properly formatted as base64 String
           'amount':base_amount,  # Store base amount too?  Consider.
            'paymentMethod':data['paymentMethod'],
           'paymentStatus':data['paymentStatus'],
           'totalAmount':total_amount, #Store the calculated total amount
           'created_at': datetime.now(),
        }
        booking_id = bookings_collection.insert_one(booking_data).inserted_id


        trip_data = {
            'userId': user_id_str, # Use the String
            'carId': data['carId'],
            'carModel': car['carModel'],
            'pickupLocation': car['pickupLocation'],
            'pickupTime':data['pickupTime'],
            'returnTime': data['returnTime'],
            'amount':base_amount, # add base amount here
            'totalAmount': total_amount, # ADD total amount here
            'paymentStatus': data['paymentStatus'],
            'tripStatus': "Ongoing",  # Set initial trip status
            'created_at': datetime.now(),
        }
        trips_collection.insert_one(trip_data)
        # Set car availability to False
        cars_collection.update_one({'_id': ObjectId(data['carId'])}, {'$set': {'is_available': False}})


        return jsonify({'message':'Booking successful','bookingId':str(booking_id)}),201
    except Exception as e:
          return jsonify({'message':'Failed to create booking','error':str(e)}),500



def validate_get_trips_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400
    if 'userId' not in data:
        return 'Missing userId field', 400
    if not isinstance(data['userId'], str) or not data['userId']:
        return 'Invalid userId format', 400
    return None, 200


@app.route('/get-trips',methods=['POST'])
def get_trips():
    data = request.get_json()
    validation_message, status_code = validate_get_trips_data(data)
    if validation_message:
        return jsonify({'message':validation_message}), status_code
    try:
        # Convert userId to ObjectId if it's a valid ObjectId string
        try:
            user_id = ObjectId(data['userId'])
        except:
            user_id = data['userId']  # Keep as string if not a valid ObjectId


        trips = list(trips_collection.find({'userId': str(user_id)}))
        for trip in trips:
            trip['_id'] = str(trip['_id'])
            trip['carId'] = str(trip['carId'])
        return jsonify(trips), 200
    except Exception as e:
        return jsonify({'message': 'Failed to fetch trips', 'error': str(e)}), 500


def validate_update_trip_status_data(data):
    if not isinstance(data, dict):
       return 'Invalid data type: data should be a dictionary',400
    required_fields = ['tripId','paymentStatus','tripStatus']  # Add 'tripStatus'
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["tripId"], str):
      return "Invalid tripId format", 400
    if not isinstance(data['paymentStatus'],str) or not data['paymentStatus']:
      return 'Invalid payment status', 400
    if not isinstance(data['tripStatus'],str) or not data['tripStatus']:  # Validate tripStatus
      return 'Invalid trip status', 400
    if data['tripStatus'] not in ("Ongoing", "Completed"):
        return "tripStatus can only be Ongoing or Completed", 400
    return None, 200


@app.route('/update-trip-status',methods=['POST'])
def update_trip_status():
    data = request.get_json()
    validation_message, status_code = validate_update_trip_status_data(data)
    if validation_message:
       return jsonify({'message': validation_message}), status_code
    try:
        trip_id = data['tripId'] # Get the trip ID
        print(f"Attempting to update trip status for trip ID: {trip_id}")


        query = {
            '_id': ObjectId(trip_id),  # Use trip ID to find the Trip
        }
        update = {'$set': {'paymentStatus':data['paymentStatus'],'tripStatus': data['tripStatus']}}  # update both
        updated_trip = trips_collection.update_one(query,update)
        print(f"Update Result: {updated_trip.raw_result}") # print out the result


        if updated_trip.modified_count > 0:
            # Set car availability to True when trip is completed
            trip = trips_collection.find_one(query)
            if trip:
                cars_collection.update_one({'_id': ObjectId(trip['carId'])}, {'$set': {'is_available': True}})
            return jsonify({'message': 'trip status updated successfully'}), 200
        else:
            return jsonify({'message': 'trip not found'}), 404
    except Exception as e:
        print(f"Exception in update_trip_status: {e}")
        traceback.print_exc()  # Print the traceback
        return jsonify({'message': 'Failed to update trip status','error': str(e)}), 500


def validate_get_host_bookings_data(data):
    if not isinstance(data, dict):
        return "Invalid data type: data should be a dictionary", 400
    if "userId" not in data:
        return "Missing userId field", 400
    if not isinstance(data["userId"], str):  # Changed this line
        return "Invalid userId format: userId must be a string", 400  # More specific message
    if not data["userId"]: # Added
        return "userId cannot be empty", 400
    return None, 200


@app.route('/get-host-bookings', methods=['POST'])
def get_host_bookings():
    data = request.get_json()
    print(f"Received data: {data}")
    validation_message, status_code = validate_get_host_bookings_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code


    try:
        # Find all cars owned by the host
        host_cars = list(cars_collection.find({'userId': data['userId']}))
        print(f"Found {len(host_cars)} cars for this user.")  # Print car count
        car_ids = [str(car['_id']) for car in host_cars]  # Extract car IDs
        print(f"Car IDs: {car_ids}")


        # Find bookings for those cars
        bookings = list(bookings_collection.find({'carId': {'$in': car_ids}}))  # Use $in operator
        print(f"Found {len(bookings)} bookings for these cars.")  # Print booking count


        # Enhance booking data with renter info
        for booking in bookings:
            print(f"Processing booking ID: {booking.get('_id')}") #Log which booking you're processing


            user_id = booking.get('userId')


            if user_id is None:  # ADD THIS CHECK
                print(f"Booking {booking.get('_id')}: userId is None.")
                booking['renter_email'] = 'N/A (User ID Missing)'  # Or some appropriate message
                booking['renter_mobile'] = 'N/A (User ID Missing)'
            else:
                print(f"Booking {booking.get('_id')}: userId is {user_id}")
                try: # to convert the user ID to an object ID
                    user = users_collection.find_one({'_id': ObjectId(user_id)})
                    if user:
                        booking['renter_email'] = user.get('email')
                        booking['renter_mobile'] = user.get('phone')
                        print(f"Booking {booking.get('_id')}: Renter details found.")
                    else:
                        print(f"Booking {booking.get('_id')}: User not found in users_collection.")
                        booking['renter_email'] = 'N/A (User Not Found)'
                        booking['renter_mobile'] = 'N/A (User Not Found)'
                except Exception as e:
                    print(f"Error finding user for booking {booking.get('_id')}: {e}")
                    booking['renter_email'] = 'N/A (Error Retrieving User)'
                    booking['renter_mobile'] = 'N/A (Error Retrieving User)'


            booking['_id'] = str(booking['_id'])
            #Check if totalAmount exists, else retrieve Amount instead
            if 'totalAmount' not in booking:
                booking['totalAmount'] = booking.get('amount',0) # Retrieve amount as fallback or default to 0


        return jsonify(bookings), 200
    except Exception as e:
        print(f"Error fetching bookings: {str(e)}, {e.__traceback__}")  # Print error message
        return jsonify({'message': 'Failed to fetch bookings', 'error': str(e)}), 500
   
def validate_submit_review_data(data):
    if not isinstance(data, dict):
        return "Invalid data type: data should be a dictionary", 400
    required_fields = ["carId", "userId", "rating", "comment"]
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["carId"], str) or not data["carId"]:
        return "Invalid carId format", 400
    if not isinstance(data["userId"], str) or not data["userId"]:
        return "Invalid userId format", 400
    if not isinstance(data["rating"], int):
        return "Rating must be an integer", 400
    if data["rating"] < 1 or data["rating"] > 5:
        return "Rating must be between 1 and 5", 400
    if not isinstance(data["comment"], str):
        return "Comment must be a string", 400
    return None, 200


@app.route('/submit-review', methods=['POST'])
def submit_review():
    data = request.get_json()
    validation_message, status_code = validate_submit_review_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code

    try:
        review_data = {
            'carId': data['carId'],
            'userId': data['userId'],
            'rating': data['rating'],
            'comment': data['comment'],
            'createdAt': datetime.now(),
        }
        review_id = reviews_collection.insert_one(review_data).inserted_id
        return jsonify({'message': 'Review submitted successfully', 'review_id': str(review_id)}), 201
    except Exception as e:
        return jsonify({'message': 'Failed to submit review', 'error': str(e)}), 500


#New Route:

@app.route('/get-average-rating', methods=['POST'])
def get_average_rating():
    data = request.get_json()
    validation_message, status_code = validate_get_average_rating_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    car_id = data['carId']
    try:
        # Use aggregation to calculate the average rating
        result = reviews_collection.aggregate([
            {'$match': {'carId': car_id}},
            {'$group': {'_id': '$carId', 'averageRating': {'$avg': '$rating'}}}
        ]).next() # The result will be a dictionary

        average_rating = result['averageRating']
        return jsonify({'carId': car_id, 'averageRating': average_rating}), 200

    except StopIteration:  # Handle the case where there are no reviews
        return jsonify({'carId': car_id, 'averageRating': 0}), 200  # Return 0 if no reviews

    except Exception as e:
        print(f"Error calculating average rating: {e}")
        return jsonify({'message': 'Failed to calculate average rating', 'error': str(e)}), 500


def validate_get_review_count_data(data):
    if not isinstance(data, dict):
        return "Invalid data type: data should be a dictionary", 400
    if "carId" not in data:
        return "Missing carId field", 400
    if not isinstance(data["carId"], str) or not data["carId"]:
        return "Invalid carId format", 400
    return None, 200


@app.route('/get-review-count', methods=['POST'])
def get_review_count():
    data = request.get_json()
    validation_message, status_code = validate_get_review_count_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code

    car_id = data['carId']

    try:
        count = reviews_collection.count_documents({'carId': car_id})
        return jsonify({'carId': car_id, 'reviewCount': count}), 200
    except Exception as e:
        print(f"Error getting review count: {e}")
        return jsonify({'message': 'Failed to get review count', 'error': str(e)}), 500

  
def validate_get_average_rating_data(data):
    if not isinstance(data, dict):
        return "Invalid data type: data should be a dictionary", 400
    if "carId" not in data:
        return "Missing carId field", 400
    if not isinstance(data["carId"], str) or not data["carId"]:
        return "Invalid carId format", 400
    return None, 200

def validate_get_reviews_data(data):
    if not isinstance(data, dict):
        return "Invalid data type: Data should be a dictionary", 400
    if "carId" not in data:
        return "Missing carId field", 400
    if not isinstance(data["carId"], str) or not data["carId"]:
        return "Invalid carId format", 400
    return None, 200


@app.route('/get-reviews', methods=['POST'])
def get_reviews():
    data = request.get_json()
    validation_message, status_code = validate_get_reviews_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    car_id = data['carId']
    try:
        reviews = list(reviews_collection.find({'carId': car_id}))
        for review in reviews:
            review['_id'] = str(review['_id'])  # Convert ObjectId to string
        return jsonify(reviews), 200
    except Exception as e:
        print(f"Error getting reviews: {e}")
        return jsonify({'message': 'Failed to get reviews', 'error': str(e)}), 500

def validate_search_cars_data(data):
    if not isinstance(data, dict):
        return "Invalid data type, data should be a dictionary", 400
    required_fields = ["city", "startTime", "endTime","userId"]  # Included "userId"
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["city"], str) or not data["city"]:
        return "Invalid city format", 400
    if not isinstance(data["startTime"], str) or not data["startTime"]:
        return "Invalid startTime format", 400
    if not isinstance(data["endTime"], str) or not data["endTime"]:
        return "Invalid endTime format", 400
    #basic validation format
    return None, 200


@app.route('/search-cars', methods=['POST'])
def search_cars():
    data = request.get_json()
    print("Received data:", data)
    validation_message, status_code = validate_search_cars_data(data)
    if validation_message:
        print("Validation error:", validation_message)
        return jsonify({'message': validation_message}), status_code

    try:
        city = data['city']
        start_time_str = data['startTime']
        end_time_str = data['endTime']
        user_id = data['userId']

        # Convert time strings to datetime objects for comparison
        try:
            start_time = datetime.strptime(start_time_str, "%Y-%m-%d %H:%M:%S")
            end_time = datetime.strptime(end_time_str, "%Y-%m-%d %H:%M:%S")
        except ValueError as e:
            return jsonify({'message': f"Invalid date/time format: {e}"}), 400

        # Construct the query
        query = {
            'city': city,
            'is_available': True,
            'startDate': {'$lte': start_time.strftime("%Y-%m-%d")}, # Car must start before or on the search start
            'endDate': {'$gte': end_time.strftime("%Y-%m-%d")},     # Car must end after or on the search end

            '$or': [
                {
                    '$and': [
                        {'endDate': {'$gt': start_time.strftime("%Y-%m-%d")}},
                    ]
                },
                {
                    '$and': [
                        {'endDate': start_time.strftime("%Y-%m-%d")},
                        {'endTime': {'$gte': start_time.strftime("%H:%M:%S")}}
                    ]
                }
            ]
        }

        # Query the database for cars matching the criteria
        cars = list(cars_collection.find(query))

        # Convert ObjectIds to strings for JSON serialization
        for car in cars:
            car['_id'] = str(car['_id'])

        return jsonify(cars), 200

    except Exception as e:
        print(f"Error searching cars: {e}")
        return jsonify({'message': 'Failed to search cars', 'error': str(e)}), 500


@app.route('/get-cars-by-brand', methods=['POST'])
def get_cars_by_brand():
    data = request.get_json()
    if not data or 'brandName' not in data:
        return jsonify({'message': 'Missing brandName field'}), 400

    brand_name = data['brandName']
    try:
        # Use a case-insensitive query AND filter by availability
        cars = list(cars_collection.find({
            'carBrand': {'$regex': f'^{brand_name}$', '$options': 'i'},
            'is_available': True  # Only get available cars
        }))
        for car in cars:
            car['_id'] = str(car['_id'])
        return jsonify(cars), 200
    except Exception as e:
        print(traceback.format_exc())  # Print the traceback
        return jsonify({'message': 'Failed to fetch cars', 'error': str(e)}), 500



# Admin Dashboard API's
# New endpoint for getting dashboard data, including booking counts


import pymongo

#Initialize it with Initial Values during app start
def initialize_dashboard_metrics():
  # find if there's a historical data
  last_metrics = dashboard_metrics_collection.find_one(sort=[('_id', pymongo.DESCENDING)])
  if not last_metrics:  # if there no history of the matrix to start from
    initial_metrics = {
        'total_cars': 0, # Start it with the initial value for calculations
        'total_users': 0, # Start it with the initial value for calculations
        'total_trips': 0, # Start it with the initial value for calculations
        'total_bookings': 0, # Start it with the initial value for calculations
        'timestamp': datetime.now()
    }
    dashboard_metrics_collection.insert_one(initial_metrics)
initialize_dashboard_metrics()



@app.route('/dashboard-data', methods=['GET'])
def get_dashboard_data():
    try:
        total_cars = cars_collection.count_documents({})
        total_users = users_collection.count_documents({})
        total_trips = trips_collection.count_documents({})
        total_bookings = bookings_collection.count_documents({})  # Count Bookings
        # Fetch last metrics for calculations
        last_metrics = dashboard_metrics_collection.find_one(sort=[('_id', pymongo.DESCENDING)])
        if not last_metrics:
            # Handle the edge case where there are no metrics yet in DB
            last_metrics = {
                'total_cars': 0,
                'total_users': 0,
                'total_trips': 0,
                'total_bookings': 0
            }

        data = {
            'total_cars': total_cars,
            'total_users': total_users,
            'total_trips': total_trips,
            'total_bookings': total_bookings,  # Include in response
        }

        # Store current metrics for next calculation
        current_metrics = {
            'total_cars': total_cars,
            'total_users': total_users,
            'total_trips': total_trips,
            'total_bookings': total_bookings,
            'timestamp': datetime.now()
        }
        dashboard_metrics_collection.insert_one(current_metrics)

        return jsonify(data), 200

    except Exception as e:
        print(f"Error getting dashboard data: {e}")
        return jsonify({'message': 'Failed to fetch dashboard data', 'error': str(e)}), 500





# Users data
@app.route('/users-data', methods=['GET'])
def get_users_data():
    try:
        users = list(users_collection.find({}))
        for user in users:
            user['_id'] = str(user['_id'])
            # Extract username from email if 'userName' is missing
            if 'userName' not in user:
                user['userName'] = user['email'].split('@')[0]  # Or a default like 'Unknown'
        return jsonify(users), 200
    except Exception as e:
        print(f"Error getting users data: {e}")
        return jsonify({'message': 'Failed to fetch users data', 'error': str(e)}), 500
    

def validate_update_user_data(data):
    if not isinstance(data, dict):
        return "Invalid data type: Data should be a dictionary", 400
    required_fields = ["userName", "email", "phone", "gender", "role"]  # Add role to required fields
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["userName"], str):
        return "userName must be a string", 400
    if not isinstance(data["email"], str) or '@' not in data["email"]:
        return "Invalid email format", 400
    if not isinstance(data["phone"], str):
        return "Phone must be a string", 400
    if not isinstance(data["gender"], str):
        return "Gender must be a string", 400
    if data["gender"] not in ['Male', 'Female', 'Other']:
        return "Invalid gender option", 400
    if data["role"] not in ['user', 'host', 'admin', 'Sub-Admin', 'Vendor', 'Sub-Vendor']:  # Add new roles to validation
        return "Invalid role option", 400
    return None, 200


@app.route('/update-user/<user_id>', methods=['PUT'])
def update_user(user_id):
    data = request.get_json()
    validation_message, status_code = validate_update_user_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code

    try:
        user = users_collection.find_one({'_id': ObjectId(user_id)})
        if not user:
            return jsonify({'message': 'User not found'}), 404

        # Update user data
        update_data = {
            'userName': data['userName'],
            'email': data['email'],
            'phone': data['phone'],
            'gender': data['gender'],
            'role': data['role'],  # Update the role as well
        }
        users_collection.update_one({'_id': ObjectId(user_id)}, {'$set': update_data})
        return jsonify({'message': 'User updated successfully'}), 200
    except Exception as e:
        print(f"Error updating user: {e}")
        return jsonify({'message': 'Failed to update user', 'error': str(e)}), 500


def validate_add_user_data(data):
    if not isinstance(data, dict):
        return "Invalid data type: Data should be a dictionary", 400
    required_fields = ["userName", "email", "phone", "gender", "password",'role']  # Add role to required fields
    missing_fields = [field for field in required_fields if field not in data]
    if missing_fields:
        return f"Missing fields: {', '.join(missing_fields)}", 400
    if not isinstance(data["userName"], str):
        return "userName must be a string", 400
    if not isinstance(data["email"], str) or '@' not in data["email"]:
        return "Invalid email format", 400
    if not isinstance(data["phone"], str):
        return "Phone must be a string", 400
    if not isinstance(data["gender"], str):
        return "Gender must be a string", 400
    if data["gender"] not in ['Male', 'Female', 'Other']:
        return "Invalid gender option", 400
    if data["role"] not in ['user', 'host', 'admin', 'Sub-Admin', 'Vendor', 'Sub-Vendor']:  # Add new roles to validation
        return "Invalid role option", 400
    if not isinstance(data["password"], str):
        return "Password must be a string", 400
    if len(data["password"]) < 8:
        return "Password must be at least 8 characters long", 400
    return None, 200

@app.route('/add-user', methods=['POST'])
def add_user():
    data = request.get_json()
    validation_message, status_code = validate_add_user_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code
    try:
        hashed_password = generate_password_hash(data['password'])
        user_data = {
            'userName': data['userName'],
            'email': data['email'],
            'phone': data['phone'],
            'gender': data['gender'],
            'role': data['role'],  # Add the role
            'password': hashed_password,
            'profileImage': "",
        }
        user_id = users_collection.insert_one(user_data).inserted_id
        return jsonify({'message': 'User added successfully', 'user_id': str(user_id)}), 201
    except Exception as e:
        print(f"Error adding user: {e}")
        return jsonify({'message': 'Failed to add user', 'error': str(e)}), 500


@app.route('/delete-user/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    print(f"DELETE route hit for user_id: {user_id}")

    try:
        object_id = ObjectId(user_id)
        print(f"Converted user_id to ObjectId: {object_id}")

        # 1. Find all cars hosted by the user
        cars_hosted = list(cars_collection.find({'userId': user_id}))
        print(f"Found {len(cars_hosted)} cars hosted by user {user_id}: {cars_hosted}")
        car_ids_hosted = [str(car['_id']) for car in cars_hosted]
        print(f"Car IDs hosted by user: {car_ids_hosted}")

        # 2. Delete bookings associated with the cars hosted by the user
        bookings_deletion_result_hosted = bookings_collection.delete_many({'carId': {'$in': car_ids_hosted}})
        print(f"Bookings deletion result (hosted cars): {bookings_deletion_result_hosted.deleted_count}")

        # 3. Delete trips associated with the cars hosted by the user
        trips_deletion_result_hosted = trips_collection.delete_many({'carId': {'$in': car_ids_hosted}})
        print(f"Trips deletion result (hosted cars): {trips_deletion_result_hosted.deleted_count}")

        # 4. Delete the cars hosted by the user
        cars_deletion_result = cars_collection.delete_many({'userId': user_id})
        print(f"Cars deletion result: {cars_deletion_result.deleted_count}")

        # 5. Delete trips *made by* the user (i.e., user booked someone else's car)
        trips_deletion_result_made = trips_collection.delete_many({'userId': user_id})
        print(f"Trips deletion result (made by user): {trips_deletion_result_made.deleted_count}")

         #6 Delete bookings *made by* the user (i.e., user booked someone else's car)
        bookings_deletion_result_made = bookings_collection.delete_many({'userId': user_id})
        print(f"Bookings deletion result (made by user): {bookings_deletion_result_made.deleted_count}")

        # 7. Delete the user
        user_deletion_result = users_collection.delete_one({'_id': object_id})
        print(f"User deletion result: {user_deletion_result.deleted_count}")


        if user_deletion_result.deleted_count == 1:
            return jsonify({
                'message': 'User and related data deleted successfully',
                'bookings_deleted_hosted': bookings_deletion_result_hosted.deleted_count, #Number of bookings
                'trips_deleted_hosted': trips_deletion_result_hosted.deleted_count, #number of trips
                'cars_deleted': cars_deletion_result.deleted_count,  #number of cars,
                'trips_deleted_made': trips_deletion_result_made.deleted_count, #number of trips,
                'bookings_deleted_made': bookings_deletion_result_made.deleted_count, #number of trips,
                'user_deleted': user_deletion_result.deleted_count
            }), 200
        else:
            return jsonify({'message': 'User not found'}), 404

    except Exception as e:
        print(f"Error deleting user: {e}")
        traceback.print_exc()
        return jsonify({'message': 'Failed to delete user and related data', 'error': str(e)}), 500

# Cars data
@app.route('/cars-data', methods=['GET'])
def get_cars_data():
    try:
        cars = list(cars_collection.find({}))
        for car in cars:
            car['_id'] = str(car['_id'])
        return jsonify(cars), 200
    except Exception as e:
        print(f"Error getting cars data: {e}")
        return jsonify({'message': 'Failed to fetch cars data', 'error': str(e)}), 500



# Helper function to get average rating for a car
def get_average_rating(car_id):
    try:
        result = reviews_collection.aggregate([
            {'$match': {'carId': car_id}},
            {'$group': {'_id': '$carId', 'averageRating': {'$avg': '$rating'}}}
        ]).next()
        return result['averageRating'] if result else 0
    except StopIteration: # Handle car without reviews
        return 0


@app.route('/get-average-admin-car-rating', methods=['GET'])
def get_average_admin_car_rating():
    try:
        cars = list(cars_collection.find({}))
        for car in cars:
            car['_id'] = str(car['_id'])
            print(f"Car ID: {car['_id']}, coverImageBytes before get_average_rating: {car.get('coverImageBytes')}")
            car['averageRating'] = get_average_rating(car['_id'])  # Add average rating
            print(f"Car ID: {car['_id']}, coverImageBytes after get_average_rating: {car.get('coverImageBytes')}") # Print again after get_average rating

            # Fetch host details
            host = users_collection.find_one({'_id': ObjectId(car['userId'])})
            if host:
                car['hostName'] = host.get('userName', 'N/A')
                car['hostMobileNumber'] = host.get('phone', 'N/A')
            else:
                car['hostName'] = 'N/A'
                car['hostMobileNumber'] = 'N/A'

        return jsonify(cars), 200
    except Exception as e:
        print(f"Error getting admin cars data: {e}")
        return jsonify({'message': 'Failed to fetch admin cars data', 'error': str(e)}), 500
    

def validate_delete_car_by_admin_data(data):
    if not isinstance(data, dict):
        return 'Invalid data type: data should be a dictionary', 400
    if 'carId' not in data:
        return 'Missing carId field', 400
    if not isinstance(data['carId'], str) or not data['carId']:
        return "Invalid carId format", 400
    return None, 200

@app.route('/delete-car-by-admin', methods=['POST'])
def delete_car_by_admin():
    data = request.get_json()
    validation_message, status_code = validate_delete_car_by_admin_data(data)
    if validation_message:
        return jsonify({'message': validation_message}), status_code

    car_id = data['carId']

    try:
        # 1. Convert car_id to ObjectId
        object_id = ObjectId(car_id)

        # 2. Delete bookings associated with the car ID
        bookings_result = bookings_collection.delete_many({'carId': car_id})  # using same `carId` from client

        # 3. Delete trips associated with the car ID
        trips_result = trips_collection.delete_many({'carId': car_id})  # using same `carId` from client

        # 4. Finally, delete the car itself
        car_result = cars_collection.delete_one({'_id': object_id})

        if car_result.deleted_count == 1:
            return jsonify({
                'message': 'Car and associated bookings/trips deleted successfully by admin',
                'bookings_deleted': bookings_result.deleted_count,  # report back counts of items removed
                'trips_deleted': trips_result.deleted_count,       # report back counts of items removed
                'car_deleted': car_result.deleted_count # this should be 1
            }), 200
        else:
            return jsonify({'message': 'Car not found'}), 404

    except Exception as e:
        print(f"Error deleting car and associated data: {e}")
        return jsonify({'message': 'Failed to delete car and related data', 'error': str(e)}), 500
    



# Trips data
@app.route('/trips-data', methods=['GET'])
def get_trips_data():
    try:
        trips = list(trips_collection.find({}))
        for trip in trips:
            trip['_id'] = str(trip['_id'])
            trip['carId'] = str(trip['carId'])

            # Fetch user data based on userId
            user = users_collection.find_one({'_id': ObjectId(trip['userId'])})
            if user:
                trip['userEmail'] = user.get('email', 'N/A')  # Add user email to trip data
                trip['userPhone'] = user.get('phone', 'N/A') #Add User phone to trip Data
                trip['userName'] = user.get('userName','N/A')#Add User Name too if you want
            else:
                trip['userEmail'] = 'N/A'  # Handle case where user is not found
                trip['userPhone'] = 'N/A' # Handle if User Phone Not Found
                trip['userName'] = 'N/A'

        return jsonify(trips), 200
    except Exception as e:
        print(f"Error getting trips data: {e}")
        return jsonify({'message': 'Failed to fetch trips data', 'error': str(e)}), 500


@app.route('/get-trips-by-admin', methods=['GET'])
def get_trips_by_admin():
    try:
        trips = list(trips_collection.find())

        filtered_trips = []  # Create a new list to hold only valid trips

        for trip in trips:
            try:
                user_id = ObjectId(trip['userId'])

                # Fetch user details, make sure is there are any ObjectId formatting issues
                user = users_collection.find_one({'_id': user_id})

                if user:
                   print (f"User Details Found: {user}")
                   trip['customerName'] = user.get('userName', 'N/A')
                   try:
                        trip['phoneNumber'] = str(user.get('phone', 'N/A')) #retrieve customer phone number to make a string!
                   except:
                       trip['phoneNumber'] = "N/A"  #if it fails just provide N/A

                   trip['email'] = user.get('email', 'N/A')
                else:
                    print (f"USER Details NOT Found: {trip['userId']}") # if no user data is found
                    continue # Skip it, and then do not include it back.


                # Fetch car details
                try:
                    car = cars_collection.find_one({'_id': ObjectId(trip['carId'])})
                    if car:
                        trip['carBrand'] = car.get('carBrand', 'N/A')
                        trip['carModel'] = car.get('carModel', 'N/A')
                        try: #To get user details about who is the car's host.
                            host = users_collection.find_one({'_id': ObjectId(car['userId'])}) #Add host for each car
                            if host:
                                trip['hostName'] = host.get('userName', 'N/A')  # Add host name to trip model
                            else:
                                 trip['hostName'] = "N/A"
                        except Exception as host_err:
                             trip['hostName'] = "N/A"  # if host retrieval fails

                    else:
                         print (f"Car Details NOT Found: {trip['carId']}") # if no car Data is found
                         continue  # skip and DO not include the Car as well.
                         #break # Break so you do not run anything past this error

                except Exception as car_err: # if car retrieval fails
                    trip['carBrand'] = 'N/A'
                    trip['carModel'] = 'N/A'
                    trip['hostName'] = 'N/A'

                # Convert ObjectId to string - after accessing related documents!
                trip['_id'] = str(trip['_id'])
                trip['carId'] = str(trip['carId'])
                filtered_trips.append(trip) #Only appends valid cars/users to list after Validation is good
            except Exception as user_err:
                 print (f"USER Error Fetching Specific Details:  {trip['userId']} - {user_err}") #Show Specific User ID error out for a bug/edge case.
                 #break # do not process if this fails.

        return jsonify(filtered_trips) #Only returns the Validated version
    except Exception as e:
        print(f"Error getting all trips by admin: {e}")
        return jsonify({'message': 'Failed to fetch trips', 'error': str(e)}), 500
    

# Bookings data

@app.route('/get-all-admin-bookings', methods=['GET'])
def get_all_admin_bookings():
    try:
        bookings = list(bookings_collection.find())

        filtered_bookings = [] # List of filtered bookings

        for booking in bookings:
            try:
              # Fetch car details
              car = cars_collection.find_one({'_id': ObjectId(booking['carId'])})
              if car:
                  booking['carBrand'] = car.get('carBrand', 'N/A')
                  booking['carModel'] = car.get('carModel', 'N/A')
                  #Fetch host details from car's userId (car owner)
                  host = users_collection.find_one({'_id': ObjectId(car['userId'])}) #Use the Cars Users ID to find the User details
                  if host:
                      booking['hostName'] = host.get('userName', 'N/A')
                      booking['hostMobileNumber'] = host.get('phone', 'N/A')
                      booking['hostEmail'] = host.get('email', 'N/A')
                  else:
                      booking['hostName'] = 'N/A'
                      booking['hostMobileNumber'] = 'N/A'
                      booking['hostEmail'] = 'N/A'
                      #Dates are already in the booking document, use these to get the Date Range;
                      booking['totalAmount'] = booking.get('totalAmount','N/A') #Retrieve Total Amount
                      booking['_id'] = str(booking['_id']) #Convert ObjectId to string
                      booking['carId'] = str(booking['carId']) #Convert Carid too!
              else:
                  print (f"Car Details NOT Found: {booking['carId']}") # if no car Data is found
                  continue  # skip and DO not include the Car as well.

              booking['_id'] = str(booking['_id']) #Convert ObjectId to string
              booking['carId'] = str(booking['carId']) #Convert Carid too!

              filtered_bookings.append(booking)  #Add back only valid bookings to our list
            except Exception as inner_err:
                print(f"Inner exception getting all admin bookings: {inner_err}")  # print the error, but to not abort.

        return jsonify(filtered_bookings)

    except Exception as e:
        print(f"Error getting all admin bookings: {e}")
        return jsonify({'message': 'Failed to fetch bookings', 'error': str(e)}), 500
        

# Charts data

@app.route('/chart-data-all', methods=['GET'])
def get_chart_data_all():
    year = request.args.get('year')

    if not year:
        return jsonify({'message': 'Year is required'}), 400

    try:
        year = int(year)
        print(f"Chart Data All: Processing data for year: {year}")  # Log
    except ValueError:
        return jsonify({'message': 'Invalid year format'}), 400

    chart_data = []
    months = range(1, 13)

    utc = pytz.utc  # Set timezone to UTC

    for month in months:
        start_date = datetime(year, month, 1, tzinfo=utc)  # add timezone to each comparison to be explicit.
        end_date = datetime(year, month + 1, 1, tzinfo=utc) if month < 12 else datetime(year + 1, 1, 1,
                                                                                          tzinfo=utc)  # add timezone to each comparison to be explicit.
        print(f"Chart Data All: Month {month} - Start Date: {start_date}, End Date: {end_date}")

        # --- Users Pipeline ---
        users_pipeline = [
            {
                '$match': {
                    'created_at': {
                        '$gte': start_date,
                        '$lt': end_date
                    }
                }
            },
            {
                '$group': {
                    '_id': None,
                    'count': {'$sum': 1}
                }
            },
            {
                '$project': {
                    'count': 1,
                    '_id': 0
                }
            }
        ]

        try:
            users_result = list(users_collection.aggregate(users_pipeline))
            user_count = users_result[0]['count'] if users_result else 0
            print(f"Users - Month {month}: Count - {user_count}")
        except Exception as e:
            print(f"Error getting user count for month {month}: {e}")
            user_count = 0

        chart_data.append({'month': month, 'data_type': 'users', 'count': user_count})

        # --- Cars Pipeline ---
        cars_pipeline = [
            {
                '$match': {
                    'created_at': {
                        '$gte': start_date,
                        '$lt': end_date
                    }
                }
            },
            {
                '$group': {
                    '_id': None,
                    'count': {'$sum': 1}
                }
            },
            {
                '$project': {
                    'count': 1,
                    '_id': 0
                }
            }
        ]

        try:
            cars_result = list(cars_collection.aggregate(cars_pipeline))
            car_count = cars_result[0]['count'] if cars_result else 0
            print(f"Cars - Month {month}: Count - {car_count}")
        except Exception as e:
            print(f"Error getting car count for month {month}: {e}")
            car_count = 0

        chart_data.append({'month': month, 'data_type': 'cars', 'count': car_count})

        # --- Trips Pipeline ---
        trips_pipeline = [
            {
                '$match': {
                    'created_at': {
                        '$gte': start_date,
                        '$lt': end_date
                    }
                }
            },
            {
                '$group': {
                    '_id': None,
                    'count': {'$sum': 1}
                }
            },
            {
                '$project': {
                    'count': 1,
                    '_id': 0
                }
            }
        ]

        try:
            trips_result = list(trips_collection.aggregate(trips_pipeline))
            trip_count = trips_result[0]['count'] if trips_result else 0
            print(f"Trips - Month {month}: Count - {trip_count}")
        except Exception as e:
            print(f"Error getting trip count for month {month}: {e}")
            trip_count = 0

        chart_data.append({'month': month, 'data_type': 'trips', 'count': trip_count})

        # --- Bookings Pipeline ---
        bookings_pipeline = [
            {
                '$match': {
                    'created_at': {
                        '$gte': start_date,
                        '$lt': end_date
                    }
                }
            },
            {
                '$group': {
                    '_id': None,
                    'count': {'$sum': 1}
                }
            },
            {
                '$project': {
                    'count': 1,
                    '_id': 0
                }
            }
        ]

        try:
            bookings_result = list(bookings_collection.aggregate(bookings_pipeline))
            booking_count = bookings_result[0]['count'] if bookings_result else 0
            print(f"Bookings - Month {month}: Count - {booking_count}")
        except Exception as e:
            print(f"Error getting booking count for month {month}: {e}")
            booking_count = 0

        chart_data.append({'month': month, 'data_type': 'bookings', 'count': booking_count})

    # Log full results before return
    print(f"Chart Data All: FINAL chart_data: {chart_data}")  # Log full results before return
    return jsonify(chart_data), 200


@app.route('/line-chart-data', methods=['GET'])
def get_line_chart_data():
    data_type = request.args.get('dataType')
    year = request.args.get('year')
    month = request.args.get('month')

    if not all([data_type, year, month]):
        return jsonify({'message': 'Missing parameters'}), 400

    try:
        year = int(year)
        month = int(month)
    except ValueError:
        return jsonify({'message': 'Invalid year or month format'}), 400

    start_date = datetime(year, month, 1)
    next_month = month + 1 if month < 12 else 1
    next_year = year + 1 if month == 12 else year
    end_date = datetime(next_year, next_month, 1)  # First day of next month

    collection = None
    date_field = 'created_at'

    if data_type == 'users':
        collection = users_collection
    elif data_type == 'cars':
        collection = cars_collection
    elif data_type == 'trips':
        collection = trips_collection
    elif data_type == 'bookings':
        collection = bookings_collection
    else:
        return jsonify({'message': 'Invalid data type'}), 400

    pipeline = [
        {
            '$match': {
                date_field: {
                    '$gte': start_date,
                    '$lt': end_date
                }
            }
        },
        {
            '$group': {
                '_id': {'$dayOfMonth': f'${date_field}'},
                'count': {'$sum': 1}
            }
        },
        {
            '$project': {
                'day': '$_id',
                'count': 1,
                '_id': 0
            }
        },
        {
            '$sort': {'day': 1}
        }
    ]

    try:
        data = list(collection.aggregate(pipeline))
        return jsonify(data), 200
    except Exception as e:
        print(f"Error fetching line chart data: {e}")
        return jsonify({'message': 'Failed to fetch data', 'error': str(e)}), 500


@app.route('/car-trip-data', methods=['GET'])
def get_car_trip_data():
    year = request.args.get('year', type=int)
    month = request.args.get('month', type=int)
    if not year or not month:
        return jsonify({'message': 'Year and month are required'}), 400
    try:
        # 1. Retrieve a List of Active Car Models
        existing_cars = list(cars_collection.find({}, {'carModel': 1, '_id': 0}))  # Fetch car models from cars collection
        existing_car_models = [car['carModel'] for car in existing_cars]
        print(f"Existing car models: {existing_car_models}")

        # 2. Modify the Aggregation Pipeline
        pipeline = [
            {
                '$match': {
                    'carModel': {'$in': existing_car_models},  # Only include trips for existing car models
                    # ADD MONTH and YEAR check to prevent the logic from breaking;
                    'created_at': {
                        '$gte': datetime(year,month,1),
                        '$lt': datetime(year,month+1,1) if month < 12 else datetime(year+1,1,1)
                    }
                }
            },
            {
                '$group': {
                    '_id': '$carModel',
                    'totalTrips': {'$sum': 1},
                    'totalAmount': {'$sum': '$totalAmount'}  # Assuming 'totalAmount' field in trips
                }
            },
            {
                '$project': {
                    'carModel': '$_id',
                    'totalTrips': 1,
                    'totalAmount': 1,
                    '_id': 0
                }
            }
        ]

        car_trip_data = list(trips_collection.aggregate(pipeline))

        print(f"Car trip data: {car_trip_data}") # Check Final Output Data
        return jsonify(car_trip_data), 200
    except Exception as e:
        print(f"Error getting car trip data: {e}")
        traceback.print_exc()
        return jsonify({'message': 'Failed to fetch car trip data', 'error': str(e)}), 500


@app.route('/monthly-summary', methods=['GET'])
def get_monthly_summary():
    year = request.args.get('year')
    if not year:
        return jsonify({'message': 'Year is required'}), 400

    try:
        year = int(year)
    except ValueError:
        return jsonify({'message': 'Invalid year format'}), 400

    monthly_data = []
    utc = pytz.utc  # Define the UTC timezone
    for month in range(1, 13):
        # Define the date range with UTC timezone
        start_date = datetime(year, month, 1, tzinfo=utc)
        end_date = datetime(year, month + 1, 1, tzinfo=utc) if month < 12 else datetime(year + 1, 1, 1,
                                                                                          tzinfo=utc)

        # Count users
        users_count = users_collection.count_documents({
            'created_at': {
                '$gte': start_date,
                '$lt': end_date
            }
        })

        # Count cars
        cars_count = cars_collection.count_documents({
            'created_at': {
                '$gte': start_date,
                '$lt': end_date
            }
        })

        # Count trips
        trips_count = trips_collection.count_documents({
            'created_at': {
                '$gte': start_date,
                '$lt': end_date
            }
        })

        # Count bookings
        bookings_count = bookings_collection.count_documents({
            'created_at': {
                '$gte': start_date,
                '$lt': end_date
            }
        })

        monthly_data.append({
            'month': month,
            'users': users_count,
            'cars': cars_count,
            'trips': trips_count,
            'bookings': bookings_count
        })

    return jsonify(monthly_data), 200






@app.route('/monthly-summary-line', methods=['GET'])
def get_monthly_summary_line():
    year = request.args.get('year')
    if not year:
        return jsonify({'message': 'Year is required'}), 400

    try:
        year = int(year)
    except ValueError:
        return jsonify({'message': 'Invalid year format'}), 400

    monthly_data = {}
    utc = pytz.utc  # Define the UTC timezone

    data_types = ['users', 'cars', 'trips', 'bookings']  # List of data types to process

    for data_type in data_types:
        monthly_data[data_type] = []  # Initialize list for each data type

        for month in range(1, 13):
            # Define the date range with UTC timezone
            start_date = datetime(year, month, 1, tzinfo=utc)
            end_date = datetime(year, month + 1, 1, tzinfo=utc) if month < 12 else datetime(year + 1, 1, 1,
                                                                                              tzinfo=utc)

            collection = None  # Determine which collection to query
            if data_type == 'users':
                collection = users_collection
            elif data_type == 'cars':
                collection = cars_collection
            elif data_type == 'trips':
                collection = trips_collection
            elif data_type == 'bookings':
                collection = bookings_collection
            else:
                return jsonify({'message': 'Invalid data type'}), 400  # Should not happen, but good to check

            # Count documents in the collection for the month
            count = collection.count_documents({
                'created_at': {
                    '$gte': start_date,
                    '$lt': end_date
                }
            })

            monthly_data[data_type].append(count)  # Append count to the appropriate data type list

    # Reformat the data to have a list of months, each containing the counts for all data types
    formatted_data = []
    for month in range(1, 13):
        month_data = {'month': month}
        for data_type in data_types:
            month_data[data_type] = monthly_data[data_type][month - 1]  # Add counts for each data type
        formatted_data.append(month_data)

    return jsonify(formatted_data), 200  # Return the formatted data



@app.route('/test-monthly-summary', methods=['GET'])
def test_monthly_summary():
    data = get_monthly_summary()
    print(f"Types in test endpoint: {type(data)}")

    monthly_data = json.loads(data[0].data)  # Access the actual returned JSON data.

    for month in monthly_data: #Loop and test each Key/Value
        for k,v in month.items():
            print (f"Key: {k} Value: {v} ValueType: {type(v)}") # Print each value and type
            print (f"Full Object: {month}")  # Prints full monthly data for inspection purposes
    return data




@app.route('/test-users-chart/<int:year>', methods=['GET'])
def test_users_chart(year):
    chart_data = []
    months = range(1, 13)

    for month in months:
        start_date = datetime(year, month, 1)
        end_date = datetime(year, month + 1, 1) if month < 12 else datetime(year + 1, 1, 1)

        pipeline = [
            {
                '$match': {
                    'created_at': {
                        '$gte': start_date,
                        '$lt': end_date
                    }
                }
            },
            {
                '$group': {
                    '_id': None,
                    'count': {'$sum': 1}
                }
            },
            {
                '$project': {
                    'count': 1,
                    '_id': 0
                }
            }
        ]

        try:
            users_result = list(users_collection.aggregate(pipeline))
            user_count = users_result[0]['count'] if users_result else 0
        except Exception as e:
            print(f"Error getting user count for month {month}: {e}")
            user_count = 0

        chart_data.append({'month': month, 'data_type': 'users', 'count': user_count})

    return jsonify(chart_data), 200


@app.route('/active-cities', methods=['GET'])
def get_active_cities():
    """
    Returns a list of active cities that:
    1. Are returned by the original distinct query on relevant collections (USERS,CARS,BOOKINGS,TRIPS)
    2. Also have at least one car currently associated with them in the cars collection.
    """

    #Step #1 Get distinct cities from all tables(from the user and other collection)
    # Use aggregation to find distinct cities from all relevant collections
    cities_from_users = users_collection.distinct("city")
    cities_from_cars = cars_collection.distinct("city")
    cities_from_bookings = bookings_collection.distinct("pickupLocation")  # Assuming city is in pickupLocation
    cities_from_trips = trips_collection.distinct("pickupLocation") # Assuming city is in pickupLocation

    # Combine and deduplicate the lists of cities
    active_cities = list(set(cities_from_users + cities_from_cars + cities_from_bookings + cities_from_trips))


    # Step #2 now to filter it to the cities with a car
    # Find cities that have at least one car
    cities_with_cars = cars_collection.distinct('city')

    # Step #3 Filter Down the original list based off Car to make sure the data is legitamte
    # Filter the original active_cities list to only include cities with cars
    filtered_active_cities = [city for city in active_cities if city in cities_with_cars]

    return jsonify(filtered_active_cities)


@app.route('/city-details', methods=['POST'])
def get_city_details():
    data = request.get_json()
    if not data or 'city' not in data:
        return jsonify({'message': 'Missing city parameter'}), 400

    city = data['city']

    try:
        # Calculate total cars in the city
        car_count = cars_collection.count_documents({'city': city})

        # Find all car IDs in the given city
        car_ids_cursor = cars_collection.find({'city': city}, {'_id': 1})
        car_ids = [str(car['_id']) for car in car_ids_cursor]

        # Calculate total trips (bookings) for cars in the city
        # OLD: trip_count = bookings_collection.count_documents({'carId': {'$in': car_ids}})

        trip_count = trips_collection.count_documents({'carId': {'$in': car_ids}})  # Count the trip of all cars not Bookings

        # Calculate total income for cars in the city
        pipeline = [
            {
                '$match': {
                    'carId': {'$in': car_ids}
                }
            },
            {
                '$group': {
                    '_id': None,
                    'totalIncome': {'$sum': '$totalAmount'}  # Sum directly from 'totalAmount' field in trips
                }
            }
        ]

        try:
            income_result = list(trips_collection.aggregate(pipeline))  # Changed Cars collection with trips
            total_income = income_result[0]['totalIncome'] if income_result else 0
            formatted_total_income = "₹" + str(total_income)
        except Exception as e:
            formatted_total_income = "₹0"  # if there's no trips in that city return 0 instead of failing.


        city_details = {
            'city': city,
            'Total Cars': car_count,
            'Total Trips': trip_count,
            'Total Income': formatted_total_income, 
        }

        return jsonify(city_details), 200
    except Exception as e:
        traceback.print_exc()
        return jsonify({'message': 'Failed to fetch city details', 'error': str(e)}), 500


# banner
@app.route('/banners', methods=['GET'])
def get_banners():
    """
    Retrieves all banners from the database.
    Returns:
        A JSON response containing a list of banner objects.
    """
    banners = []
    for banner in db.banner_images.find():  # Changed collection name here
        banners.append({
            '_id': str(banner['_id']),
            'imagePath': banner['imagePath'],
            'isActive': banner['isActive']
        })
    return jsonify(banners)


@app.route('/banners', methods=['POST'])
def add_banner():
    """
    Adds a new banner to the database. Expects a JSON request with 'image' and 'isActive' fields.
    'image' should be a base64 encoded string representing the image.
    'isActive' should be a boolean.
    Returns:
        A JSON response containing the ID of the newly created banner.
    """
    try:
        image_data = request.json['image']  # Base64 encoded image data
        isActive = request.json['isActive']
        print("Image data received from Flutter:", len(image_data) if image_data else None)  # Log data
        print("isActive", isActive)

        # Decode the base64 image data
        image_bytes = base64.b64decode(image_data)

        # Generate a unique filename for the image
        filename = secrets.token_hex(16) + ".png"  # Use secrets for security
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)

        # Save the image to the upload folder
        with open(filepath, "wb") as f:
            f.write(image_bytes)

        # Insert the banner data into the database
        banner_id = db.banner_images.insert_one({  # Changed collection name here
            'imagePath': filename,  # Store filename not full path
            'isActive': isActive
        }).inserted_id

        return jsonify({'_id': str(banner_id)}), 201  # 201 Created

    except Exception as e:
        print("Image data error for add banner: ", e)
        traceback.print_exc()
        return jsonify({'error': str(e)}), 400  # 400 Bad Request


@app.route('/banners/<id>', methods=['PUT'])
def update_banner(id):
    """
    Updates an existing banner in the database.  Expects a JSON request
    with 'isActive' field (boolean).
    Returns:
        A JSON response indicating success or failure.
    """
    try:
        isActive = request.json['isActive']

        result = db.banner_images.update_one(  # Changed collection name here
            {'_id': ObjectId(id)},
            {'$set': {'isActive': isActive}}
        )

        if result.modified_count > 0:
            return jsonify({'message': 'Banner updated successfully'})
        else:
            return jsonify({'message': 'Banner not found or no changes made'}), 404

    except Exception as e:
        return jsonify({'error': str(e)}), 400


@app.route('/banners/<id>', methods=['DELETE'])
def delete_banner(id):
    """
    Deletes a banner from the database and its associated image file.
    Returns:
        A JSON response indicating success or failure.
    """
    try:
        banner = db.banner_images.find_one({'_id': ObjectId(id)})  # Changed collection name here
        if banner:
            # Delete the image file
            image_path = os.path.join(app.config['UPLOAD_FOLDER'], banner['imagePath'])
            if os.path.exists(image_path):
                os.remove(image_path)

            # Delete the banner from the database
            db.banner_images.delete_one({'_id': ObjectId(id)})  # Changed collection name here
            return jsonify({'message': 'Banner deleted successfully'})
        else:
            return jsonify({'message': 'Banner not found'}), 404

    except Exception as e:
        return jsonify({'error': str(e)}), 400


@app.route('/uploads/<filename>')
def send_image(filename):
    try:
        return send_from_directory(app.config["UPLOAD_FOLDER"], filename)
    except FileNotFoundError:
        return jsonify({'message': 'Image not found'}), 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')