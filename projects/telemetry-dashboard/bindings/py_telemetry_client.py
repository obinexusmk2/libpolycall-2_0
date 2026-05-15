import json

def observe(payload: dict) -> str:
    return json.dumps({"observer": "python", "payload": payload})
