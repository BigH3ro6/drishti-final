from flask import Blueprint, request, jsonify
from app.services.firebase_core import db
from app.middleware.auth_middleware import require_auth
import random
import string

# Blueprint to hold all the linking/pairing routes
pairing_bp = Blueprint('pairing', __name__)