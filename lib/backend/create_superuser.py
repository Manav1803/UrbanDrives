# create_superuser.py
import os
from flask import Flask
from werkzeug.security import generate_password_hash
from pymongo import MongoClient

# Configuration (Ensure these match your app.py)
MONGO_URI = "mongodb://localhost:27017/urban_drive"
DB_NAME = "urban_drive"
USERS_COLLECTION = "users"

# Initialize Flask (needed for app context)
app = Flask(__name__)

# Get MongoDB connection
client = MongoClient(MONGO_URI)
db = client[DB_NAME]
users_collection = db[USERS_COLLECTION]

def create_superuser(email, password):
    """Creates a superuser in the MongoDB database."""
    if users_collection.find_one({'email': email}):
        print(f"Error: User with email '{email}' already exists.")
        return

    hashed_password = generate_password_hash(password)
    user_data = {
        'email': email,
        'password': hashed_password,
        'userName': 'Administrator', #Or any superuser name
        'phone': '1234567890',  #Example Phone number
        'dob': '01/01/1970',      #Example Date of Birth
        'gender': 'Other',
        'created_at': None, # Removed datetime.now() for direct value
        'role': 'admin',  # Set the role to 'admin'
        'profileImage': None
    }

    try:
        user_id = users_collection.insert_one(user_data).inserted_id
        print(f"Superuser created successfully with ID: {user_id}")
    except Exception as e:
        print(f"Error creating superuser: {e}")


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description="Create a superuser in the Urban Drive application.")
    parser.add_argument("--email", default="admin@gmail.com", help="Email address for the superuser. Defaults to admin@gmail.com")
    parser.add_argument("--password", default="password", help="Password for the superuser. Defaults to password")

    args = parser.parse_args()

    with app.app_context(): # Use app context to access the database
        create_superuser(args.email, args.password)