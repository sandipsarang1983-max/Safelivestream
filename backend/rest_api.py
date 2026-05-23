from flask import Flask, jsonify, request
from flask_cors import CORS
import json
import logging
import threading
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# Configure Logging for Production
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ModerationService:
    def __init__(self, config_path='../assets/global_moderation_config.json'):
        self.lock = threading.Lock() # Prevents data race conditions
        self.config_path = config_path
        self._load_config()
        self.processed_messages = []
    
    def _load_config(self):
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                self.config = json.load(f)
            self.blacklists = self.config.get('blacklists', {})
        except Exception as e:
            logger.error(f"Failed to load config: {e}")
            self.blacklists = {}
    
    def moderate_message(self, message):
        clean_msg = message.lower()
        for lang, words in self.blacklists.items():
            if any(word.lower() in clean_msg for word in words):
                return {"blocked": True, "language": lang, "message": message}
        return {"blocked": False, "language": "clean", "message": message}
    
    def process_stream(self, live_chat_id, messages):
        results = []
        with self.lock: # Thread-safe access to logs
            for msg in messages:
                result = self.moderate_message(msg)
                result.update({'live_chat_id': live_chat_id, 'timestamp': datetime.now().isoformat()})
                results.append(result)
                self.processed_messages.append(result)
        return results

# Initialize service
moderator = ModerationService()

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "SafeStream AI Backend"}), 200

@app.route('/api/moderate', methods=['POST'])
def moderate_message():
    data = request.json or {}
    message = data.get('message', '')
    if not message:
        return jsonify({"error": "Message required"}), 400
    
    result = moderator.moderate_message(message)
    result['timestamp'] = datetime.now().isoformat()
    return jsonify(result), 200

@app.route('/api/stream/start', methods=['POST'])
def start_stream():
    data = request.json or {}
    live_chat_id = data.get('live_chat_id')
    messages = data.get('messages', [])
    
    if not live_chat_id:
        return jsonify({"error": "live_chat_id required"}), 400
    
    results = moderator.process_stream(live_chat_id, messages)
    return jsonify({"live_chat_id": live_chat_id, "processed_count": len(results), "results": results}), 200

@app.route('/api/logs', methods=['GET'])
def get_logs():
    limit = request.args.get('limit', 100, type=int)
    with moderator.lock:
        return jsonify({"total": len(moderator.processed_messages), "logs": moderator.processed_messages[-limit:]})

@app.route('/api/logs/clear', methods=['POST'])
def clear_logs():
    with moderator.lock:
        count = len(moderator.processed_messages)
        moderator.processed_messages = []
    return jsonify({"message": f"Cleared {count} log entries"})

if __name__ == '__main__':
    # REMOVED debug=True for security
    logger.info("Starting SafeStream AI REST API Server...")
    app.run(host='0.0.0.0', port=5000, debug=False)
