#!/usr/bin/env python3
"""Mock Anthropic Messages API. Scripted tool calls driven by the prompt text. Logs every request body."""
import json, sys, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOG = sys.argv[2]
PORT = int(sys.argv[1])


def text_of(content):
    if isinstance(content, str):
        return content
    out = []
    for b in content:
        if b.get("type") == "text":
            out.append(b["text"])
        elif b.get("type") == "tool_result":
            c = b.get("content")
            out.append("TOOL_RESULT:" + (c if isinstance(c, str) else json.dumps(c)))
    return "\n".join(out)


def plan(body):
    tools = {t["name"] for t in body.get("tools", [])}
    texts = [text_of(m["content"]) for m in body.get("messages", [])]
    allt = "\n".join(texts)
    if "TOOL_RESULT:" in allt:
        return ("text", "done")
    for key, name, inp in [
        ("STEP skill", "Skill", {"skill": "lean-sdd:probe"}),
        ("STEP agent-prefixed", "Agent", {"subagent_type": "lean-sdd:probe-agent", "description": "probe", "prompt": "go"}),
        ("STEP agent-bare", "Agent", {"subagent_type": "probe-agent", "description": "probe", "prompt": "go"}),
    ]:
        if key in allt and name in tools:
            return ("tool", name, inp)
    return ("text", "ok")


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_POST(self):
        n = int(self.headers.get("content-length", 0))
        body = json.loads(self.rfile.read(n) or b"{}")
        with open(LOG, "a") as f:
            f.write(json.dumps({"path": self.path, "body": body}) + "\n")
        if "messages" not in self.path:
            self.send_response(200); self.send_header("content-type", "application/json"); self.end_headers()
            self.wfile.write(b"{}"); return
        p = plan(body)
        mid = "msg_" + uuid.uuid4().hex[:12]
        if p[0] == "text":
            content = [{"type": "text", "text": p[1]}]
            stop = "end_turn"
        else:
            content = [{"type": "tool_use", "id": "toolu_" + uuid.uuid4().hex[:12], "name": p[1], "input": p[2]}]
            stop = "tool_use"
        msg = {"id": mid, "type": "message", "role": "assistant", "model": body.get("model", "m"),
               "content": [], "stop_reason": None, "stop_sequence": None,
               "usage": {"input_tokens": 1, "output_tokens": 1}}
        if not body.get("stream"):
            msg["content"] = content; msg["stop_reason"] = stop
            self.send_response(200); self.send_header("content-type", "application/json"); self.end_headers()
            self.wfile.write(json.dumps(msg).encode()); return
        self.send_response(200); self.send_header("content-type", "text/event-stream"); self.end_headers()

        def ev(name, data):
            self.wfile.write(f"event: {name}\ndata: {json.dumps(data)}\n\n".encode())

        ev("message_start", {"type": "message_start", "message": msg})
        b = content[0]
        if b["type"] == "text":
            ev("content_block_start", {"type": "content_block_start", "index": 0, "content_block": {"type": "text", "text": ""}})
            ev("content_block_delta", {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": b["text"]}})
        else:
            ev("content_block_start", {"type": "content_block_start", "index": 0, "content_block": {"type": "tool_use", "id": b["id"], "name": b["name"], "input": {}}})
            ev("content_block_delta", {"type": "content_block_delta", "index": 0, "delta": {"type": "input_json_delta", "partial_json": json.dumps(b["input"])}})
        ev("content_block_stop", {"type": "content_block_stop", "index": 0})
        ev("message_delta", {"type": "message_delta", "delta": {"stop_reason": stop, "stop_sequence": None}, "usage": {"output_tokens": 1}})
        ev("message_stop", {"type": "message_stop"})


ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
