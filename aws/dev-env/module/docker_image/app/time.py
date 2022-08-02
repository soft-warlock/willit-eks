import json
from flask import Flask, render_template
import logging

logger = logging.getLogger('waitress')
logger.setLevel(logging.INFO)
app = Flask(__name__, template_folder='templates')

@app.route('/health', methods=['GET'])
def health():
    response = app.response_class(
        response=json.dumps({"health": "ok"}),
        status=200,
        mimetype='application/json'
    )
    return response

@app.route('/', methods=['GET'])
def get():
    return render_template("time.html")

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
