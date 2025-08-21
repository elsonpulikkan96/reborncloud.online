from flask import Flask
import os

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'reborncloud-dev-key-2025')
    app.config['DOMAIN'] = 'reborncloud.online'
    app.config['AUTHOR'] = 'Elson Pulickeel Ealias'
    app.config['TITLE'] = 'RebornCloud - Cloud & DevOps Engineer'
    app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024

    from app.routes import main
    app.register_blueprint(main)

    return app
