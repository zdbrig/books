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
