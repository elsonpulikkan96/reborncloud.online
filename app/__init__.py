from flask import Flask
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import os

# Initialize rate limiter
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"],
    storage_uri=os.environ.get('RATELIMIT_STORAGE_URL', 'memory://')
)

def create_app():
    app = Flask(__name__)
    
    # Basic Flask Configuration
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'reborncloud-dev-key-2025')
    app.config['DOMAIN'] = 'reborncloud.online'
    app.config['AUTHOR'] = 'Elson Pulickeel Ealias'
    app.config['TITLE'] = 'RebornCloud - Cloud & DevOps Engineer'
    
    # reCAPTCHA Configuration
    app.config['RECAPTCHA_SITE_KEY'] = os.environ.get('RECAPTCHA_SITE_KEY')
    app.config['RECAPTCHA_SECRET_KEY'] = os.environ.get('RECAPTCHA_SECRET_KEY')
    app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024
    
    # Security Configuration
    app.config['RECAPTCHA_SITE_KEY'] = os.environ.get('RECAPTCHA_SITE_KEY', '')
    app.config['RECAPTCHA_SECRET_KEY'] = os.environ.get('RECAPTCHA_SECRET_KEY', '')
    app.config['RESUME_DOWNLOAD_LIMIT'] = int(os.environ.get('RESUME_DOWNLOAD_LIMIT', 5))
    
    # Security Headers
    @app.after_request
    def security_headers(response):
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
        return response
    
    # Initialize rate limiter
    limiter.init_app(app)
    
    from app.routes import main
    app.register_blueprint(main)

    return app
