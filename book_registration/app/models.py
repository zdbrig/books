from app import db

class QRCode(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(64), unique=True, nullable=False)
    is_registered = db.Column(db.Boolean, default=False)
    owner_name = db.Column(db.String(100))
    owner_email = db.Column(db.String(100))

    def __repr__(self):
        return f'<QRCode {self.code}>'
