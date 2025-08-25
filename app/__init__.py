from flask import Flask
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import os

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["1000 per day", "200 per hour", "50 per minute"],
    storage_uri=os.environ.get('RATELIMIT_STORAGE_URL', 'memory://')
)

def create_app():
    app = Flask(__name__)
    
    app.config.update({
        'SECRET_KEY': os.environ.get('SECRET_KEY', 'reborncloud-prod-2025'),
        'DOMAIN': 'reborncloud.online',
        'AUTHOR': 'Elson Pulickeel Ealias',
        'TITLE': 'RebornCloud - Cloud & DevOps Engineer',
        'RECAPTCHA_SITE_KEY': os.environ.get('RECAPTCHA_SITE_KEY'),
        'RECAPTCHA_SECRET_KEY': os.environ.get('RECAPTCHA_SECRET_KEY'),
        'MAX_CONTENT_LENGTH': 16 * 1024 * 1024,
        'RESUME_DOWNLOAD_LIMIT': int(os.environ.get('RESUME_DOWNLOAD_LIMIT', 5)),
        'SEND_FILE_MAX_AGE_DEFAULT': 31536000
    })
    
    @app.after_request
    def security_headers(response):
        response.headers.update({
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'X-XSS-Protection': '1; mode=block',
            'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
            'Referrer-Policy': 'strict-origin-when-cross-origin',
            'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.google.com https://www.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self';"
        })
        return response
    
    limiter.init_app(app)
    
    from app.routes import main
    app.register_blueprint(main)

    return app
