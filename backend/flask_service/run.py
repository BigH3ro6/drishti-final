from flask import Flask
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

@app.route('/')
def home():
    return {"status": "Drishti Backend Online", "version": "1.0"}

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)