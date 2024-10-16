from app import db

from datetime import datetime, timedelta
import secrets

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    is_verified = db.Column(db.Boolean, default=False)
    verification_code = db.Column(db.String(6))
    verification_code_expires = db.Column(db.DateTime)

    def set_verification_code(self):
        self.verification_code = secrets.randbelow(1000000)  # Generate a 6-digit code
        self.verification_code_expires = datetime.utcnow() + timedelta(hours=1)  # Code expires in 1 hour

    def __repr__(self):
        return f'<User {self.email}>'
class QRCode(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(64), unique=True, nullable=False)
    is_registered = db.Column(db.Boolean, default=False)
    owner_name = db.Column(db.String(100))
    owner_email = db.Column(db.String(100))

    def __repr__(self):
        return f'<QRCode {self.code}>'
