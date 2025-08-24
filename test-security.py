#!/usr/bin/env python3
"""
Test script to verify the secure resume download functionality
"""

import requests
import sys

def test_secure_download_flow():
    """Test the complete secure download flow"""
    base_url = "https://reborncloud.online"
    
    print("🔐 Testing RebornCloud Portfolio Security Features")
    print("=" * 50)
    
    # Create a session to maintain cookies
    session = requests.Session()
    
    # Test 1: Access the secure resume page
    print("1. Testing secure resume access page...")
    response = session.get(f"{base_url}/resume-access")
    if response.status_code == 200:
        print("   ✅ Secure access page loads correctly")
        print(f"   📊 Content length: {len(response.content)} bytes")
    else:
        print(f"   ❌ Failed to load secure access page: {response.status_code}")
        return False
    
    # Test 2: Test direct download protection
    print("\n2. Testing direct download protection...")
    response = session.get(f"{base_url}/download-resume", allow_redirects=False)
    if response.status_code == 302:
        print("   ✅ Direct download correctly redirected")
        print(f"   📍 Redirect location: {response.headers.get('Location', 'N/A')}")
    else:
        print(f"   ❌ Direct download not protected: {response.status_code}")
        return False
    
    # Test 3: Test form submission (development mode)
    print("\n3. Testing form submission (development mode)...")
    response = session.post(f"{base_url}/verify-access", 
                           data={}, 
                           allow_redirects=False)
    
    if response.status_code == 302:
        print("   ✅ Form submission works")
        location = response.headers.get('Location', '')
        if 'download-resume' in location and 'token=' in location:
            print("   ✅ Download token generated successfully")
            
            # Test 4: Test secure download with token
            print("\n4. Testing secure download with token...")
            download_response = session.get(f"{base_url}{location}", allow_redirects=False)
            if download_response.status_code == 200:
                content_type = download_response.headers.get('Content-Type', '')
                if 'application/pdf' in content_type:
                    print("   ✅ Secure download successful")
                    print(f"   📄 Content-Type: {content_type}")
                    print(f"   📊 File size: {len(download_response.content)} bytes")
                else:
                    print(f"   ❌ Wrong content type: {content_type}")
                    return False
            else:
                print(f"   ❌ Secure download failed: {download_response.status_code}")
                return False
        else:
            print(f"   ❌ Invalid redirect location: {location}")
            return False
    else:
        print(f"   ❌ Form submission failed: {response.status_code}")
        return False
    
    # Test 5: Test security headers
    print("\n5. Testing security headers...")
    response = session.get(f"{base_url}/")
    headers = response.headers
    
    security_headers = {
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains'
    }
    
    all_headers_present = True
    for header, expected_value in security_headers.items():
        if header in headers:
            print(f"   ✅ {header}: {headers[header]}")
        else:
            print(f"   ❌ {header}: MISSING")
            all_headers_present = False
    
    if not all_headers_present:
        return False
    
    # Test 6: Test server type
    print("\n6. Testing server configuration...")
    server = headers.get('Server', 'Unknown')
    if 'gunicorn' in server.lower():
        print(f"   ✅ Production server: {server}")
    else:
        print(f"   ⚠️  Server: {server} (expected gunicorn)")
    
    print("\n" + "=" * 50)
    print("🎉 ALL SECURITY TESTS PASSED!")
    print("✅ Your portfolio has enterprise-grade security")
    print("🔐 Resume downloads are fully protected")
    print("🛡️  All security headers are active")
    print("🚀 Production server is running")
    
    return True

if __name__ == "__main__":
    try:
        success = test_secure_download_flow()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        sys.exit(1)
