"""VM power scheduler - Scaleway Serverless Function.

Invoked by two crons: one powers the target instances off, the other on.
The action is passed in the invocation body (`{"action": "poweroff"|"poweron"}`).
Uses only the standard library - no external dependencies.
"""

import json
import os
import urllib.error
import urllib.request

API = "https://api.scaleway.com/instance/v1/zones"


def _action(zone: str, server_id: str, action: str, token: str) -> str:
    url = f"{API}/{zone}/servers/{server_id}/action"
    data = json.dumps({"action": action}).encode()
    req = urllib.request.Request(
        url,
        data=data,
        method="POST",
        headers={"X-Auth-Token": token, "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return f"ok ({resp.status})"
    except urllib.error.HTTPError as exc:
        return f"error {exc.code}: {exc.read().decode()}"
    except urllib.error.URLError as exc:
        return f"error: {exc.reason}"


def handle(event, context):
    raw = event.get("body") if isinstance(event, dict) else None
    if isinstance(raw, str):
        body = json.loads(raw or "{}")
    elif isinstance(raw, dict):
        body = raw
    elif isinstance(event, dict):
        body = event
    else:
        body = {}

    action = body.get("action", "poweroff")
    if action not in ("poweroff", "poweron"):
        return {"statusCode": 400, "body": f"invalid action: {action}"}

    token = os.environ["SCW_SECRET_KEY"]
    zone = os.environ["SCW_ZONE"]
    server_ids = [s.strip() for s in os.environ.get("SERVER_IDS", "").split(",") if s.strip()]

    results = {sid: _action(zone, sid, action, token) for sid in server_ids}
    return {"statusCode": 200, "body": json.dumps({"action": action, "results": results})}
