from flask import Blueprint, jsonify, current_app
from datetime import datetime

main_bp = Blueprint('main', __name__)

@main_bp.route('/api/handshake', methods=['GET'])
def handshake():
    # 1. Get the Firestore DB reference
    db = current_app.db
    
    # 2. Write a test log to Firebase
    timestamp = datetime.now().isoformat()
    doc_ref = db.collection('system_logs').add({
        'message': 'Walking Skeleton Connection Successful',
        'timestamp': timestamp,
        'source': 'Flutter App'
    })

    # 3. Return success to the mobile app
    return jsonify({
        "status": "success",
        "message": "Backend & Database are Online",
        "timestamp": timestamp,
        "log_id": str(doc_ref[1].id)
    }), 200