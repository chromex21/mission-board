#!/usr/bin/env python3
"""Configure CORS for Firebase Storage using REST API"""

import json
import requests
import subprocess
import os

def get_access_token():
    """Get access token from gcloud"""
    try:
        result = subprocess.run(
            ['gcloud', 'auth', 'application-default', 'print-access-token'],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except:
        pass
    return None

def set_cors_via_rest():
    """Set CORS using Cloud Storage JSON API"""
    
    bucket_name = 'mission-board-b8dbc.firebasestorage.app'
    project_id = 'mission-board-b8dbc'
    
    cors_config = [
        {
            "origin": ["*"],
            "method": ["GET"],
            "maxAgeSeconds": 3600
        }
    ]
    
    # Try getting access token from gcloud
    access_token = get_access_token()
    
    if access_token:
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        url = f'https://storage.googleapis.com/storage/v1/b/{bucket_name}?fields=cors'
        
        data = {
            "cors": cors_config
        }
        
        try:
            response = requests.patch(url, json=data, headers=headers)
            
            if response.status_code in [200, 201]:
                print("✅ CORS configuration set successfully!")
                print("Your Firebase Storage bucket can now serve images to web browsers.")
                return True
            else:
                print(f"Error: {response.status_code}")
                print(response.text)
                return False
        except Exception as e:
            print(f"Request error: {e}")
            return False
    else:
        print("Could not get access token from gcloud")
        return False

if __name__ == '__main__':
    if set_cors_via_rest():
        print("\n✅ You can now test uploading images in your app!")
    else:
        print("\n⚠️ CORS setup may need manual configuration in Google Cloud Console")
