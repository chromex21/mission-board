#!/usr/bin/env python3
"""
Configure CORS for Firebase Storage using REST API
Uses curl to make the API request
"""

import subprocess
import json
import sys

def configure_cors_rest():
    bucket_name = 'mission-board-b8dbc.firebasestorage.app'
    
    cors_config = {
        "cors": [
            {
                "origin": ["*"],
                "method": ["GET"],
                "maxAgeSeconds": 3600
            }
        ]
    }
    
    # Get access token from gcloud
    print("Getting access token from Firebase CLI...")
    try:
        result = subprocess.run(
            ['firebase', 'auth:export', '--'],
            capture_output=True,
            text=True,
            timeout=5
        )
    except:
        pass
    
    # Try alternative: use Python requests to make the API call
    print("Attempting to configure CORS using Python HTTP client...")
    
    try:
        import requests
        from google.auth import default
        from google.auth.transport.requests import Request
        
        # Get credentials
        credentials, project = default()
        
        # Refresh if needed
        if hasattr(credentials, 'refresh'):
            credentials.refresh(Request())
        
        headers = {
            'Authorization': f'Bearer {credentials.token}',
            'Content-Type': 'application/json'
        }
        
        url = f'https://storage.googleapis.com/storage/v1/b/{bucket_name}'
        
        # Make the PATCH request
        response = requests.patch(
            url,
            json=cors_config,
            headers=headers,
            params={'fields': 'cors'}
        )
        
        if response.status_code in [200, 201]:
            print("✅ SUCCESS! CORS configuration has been applied!")
            print(f"\nBucket: {bucket_name}")
            print(f"Configuration: {json.dumps(cors_config, indent=2)}")
            print("\n✅ Your Firebase Storage bucket can now serve images to web clients!")
            print("✅ You can now test uploading images in your app!")
            return True
        else:
            print(f"Error ({response.status_code}): {response.text}")
            return False
            
    except Exception as e:
        print(f"Error: {str(e)}")
        print("\n⚠️  Could not authenticate automatically.")
        print("\nTo manually set CORS, run one of these commands:")
        print("\n1. Using gcloud CLI (if installed):")
        print(f"   gsutil cors set cors.json gs://{bucket_name}")
        print("\n2. Using Firebase CLI:")
        print("   firebase deploy")
        return False

if __name__ == '__main__':
    success = configure_cors_rest()
    sys.exit(0 if success else 1)
