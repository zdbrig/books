#!/bin/bash

# Create project directory
mkdir book_registration
cd book_registration

# Create project structure
mkdir -p app/static app/templates
touch app/__init__.py app/models.py app/routes.py app/static/style.css
touch app/templates/admin.html app/templates/base.html app/templates/index.html app/templates/register.html
touch config.py run.py Dockerfile requirements.txt

# Write content to files
cat > app/__init__.py << EOL
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config.from_object('config')
db = SQLAlchemy(app)

from app import routes, models
EOL

cat > app/models.py << EOL
from app import db

class QRCode(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(64), unique=True, nullable=False)
    is_registered = db.Column(db.Boolean, default=False)
    owner_name = db.Column(db.String(100))
    owner_email = db.Column(db.String(100))

    def __repr__(self):
        return f'<QRCode {self.code}>'
EOL

cat > app/routes.py << EOL
from flask import render_template, request, redirect, url_for, flash
from app import app, db
from app.models import QRCode

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/register/<qr_code>', methods=['GET', 'POST'])
def register(qr_code):
    qr = QRCode.query.filter_by(code=qr_code).first()
    if not qr:
        flash('Invalid QR code')
        return redirect(url_for('index'))
    
    if qr.is_registered:
        flash('This QR code has already been registered')
        return redirect(url_for('index'))

    if request.method == 'POST':
        qr.owner_name = request.form['name']
        qr.owner_email = request.form['email']
        qr.is_registered = True
        db.session.commit()
        flash('Registration successful')
        return redirect(url_for('index'))

    return render_template('register.html', qr_code=qr_code)

@app.route('/admin', methods=['GET', 'POST'])
def admin():
    if request.method == 'POST':
        new_qr = QRCode(code=request.form['qr_code'])
        db.session.add(new_qr)
        db.session.commit()
        flash('New QR code added')

    qr_codes = QRCode.query.all()
    return render_template('admin.html', qr_codes=qr_codes)
EOL

cat > app/static/style.css << EOL
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    background-color: #f4f4f4;
}

.container {
    width: 80%;
    margin: auto;
    overflow: hidden;
    background: #fff;
    padding: 20px;
    border-radius: 5px;
    box-shadow: 0 0 10px rgba(0,0,0,0.1);
}

h1 {
    color: #333;
}

form {
    margin-top: 20px;
}

input[type="text"], input[type="email"] {
    width: 100%;
    padding: 10px;
    margin: 10px 0;
}

input[type="submit"] {
    display: inline-block;
    background: #333;
    color: #fff;
    padding: 10px 20px;
    border: none;
    cursor: pointer;
}

input[type="submit"]:hover {
    background: #555;
}

.flash {
    padding: 10px;
    margin: 10px 0;
    background: #f4f4f4;
    border: 1px solid #ccc;
    color: #333;
}
EOL

cat > app/templates/base.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Book Registration</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
</head>
<body>
    <div class="container">
        {% with messages = get_flashed_messages() %}
            {% if messages %}
                {% for message in messages %}
                    <div class="flash">{{ message }}</div>
                {% endfor %}
            {% endif %}
        {% endwith %}
        
        {% block content %}{% endblock %}
    </div>
</body>
</html>
EOL

cat > app/templates/index.html << EOL
{% extends "base.html" %}

{% block content %}
    <h1>Welcome to Book Registration</h1>
    <p>Scan your QR code to register your book.</p>
{% endblock %}
EOL

cat > app/templates/register.html << EOL
{% extends "base.html" %}

{% block content %}
    <h1>Register Your Book</h1>
    <form method="POST">
        <input type="text" name="name" placeholder="Your Name" required>
        <input type="email" name="email" placeholder="Your Email" required>
        <input type="submit" value="Register">
    </form>
{% endblock %}
EOL

cat > app/templates/admin.html << EOL
{% extends "base.html" %}

{% block content %}
    <h1>Admin Panel</h1>
    <h2>Add New QR Code</h2>
    <form method="POST">
        <input type="text" name="qr_code" placeholder="New QR Code" required>
        <input type="submit" value="Add QR Code">
    </form>

    <h2>Existing QR Codes</h2>
    <ul>
    {% for qr in qr_codes %}
        <li>{{ qr.code }} - {% if qr.is_registered %}Registered to {{ qr.owner_name }}{% else %}Not Registered{% endif %}</li>
    {% endfor %}
    </ul>
{% endblock %}
EOL

cat > config.py << EOL
import os

basedir = os.path.abspath(os.path.dirname(__file__))

SQLALCHEMY_DATABASE_URI = 'sqlite:///' + os.path.join(basedir, 'app.db')
SQLALCHEMY_TRACK_MODIFICATIONS = False
SECRET_KEY = 'your-secret-key'  # Change this to a random secret key
EOL

cat > run.py << EOL
from app import app, db

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True)
EOL

cat > Dockerfile << EOL
FROM python:3.9

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["python", "run.py"]
EOL

cat > requirements.txt << EOL
Flask==2.0.1
Flask-SQLAlchemy==2.5.1
EOL

# Build Docker image
docker build -t book-registration .

# Run Docker container
docker run -p 5000:5000 book-registration
