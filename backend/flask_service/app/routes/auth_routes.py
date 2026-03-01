from flask import Blueprint, request, jsonify
from app.services.firebase_core import db
from app.middleware.auth_middleware import require_auth
from firebase_admin import firestore

#Blueprint to hold all authentication routes
auth_bp = Blueprint('auth', __name__)