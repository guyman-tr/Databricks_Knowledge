"""Unified notification helper for long-running agent work.

Usage from CLI:
    python tools\notify\notify.py --subject "Audit done" --body "12 changes applied"
    python tools\notify\notify.py --subject "Build failed" --body "see attached log" \
                                  --channel email,teams --status fail

Usage from Python (preferred when wiring into other scripts):
    from tools.notify.notify import notify
    notify(subject="Done", body="...", status="ok")

Channels supported:
    - email  : AgentMail HTTPS API (requires AGENTMAIL_API_KEY + AGENTMAIL_INBOX_ID)
    - teams  : Office365 Connector / Power Automate incoming webhook (requires TEAMS_WEBHOOK_URL)
    - ntfy   : ntfy.sh push notification (requires NTFY_TOPIC; optional NTFY_SERVER)

Status values: ok | warn | fail | info (drives email subject prefix + Teams color stripe).

Credentials are loaded from %USERPROFILE%\.cursor\notify-credentials.env in addition to env vars.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import socket
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Iterable, Optional

CRED_FILE = Path.home() / ".cursor" / "notify-credentials.env"

STATUS_PREFIX = {
    "ok":   "[OK]",
    "warn": "[WARN]",
    "fail": "[FAIL]",
    "info": "[INFO]",
}
STATUS_COLOR = {
    "ok":   "2EB886",  # green
    "warn": "ECB22E",  # yellow
    "fail": "E01E5A",  # red
    "info": "1264A3",  # blue
}
# ntfy priority: 1=min ... 5=max. Maps to phone alert behavior.
NTFY_PRIORITY = {"ok": "3", "info": "3", "warn": "4", "fail": "5"}
NTFY_TAGS = {"ok": "white_check_mark", "warn": "warning", "fail": "rotating_light", "info": "information_source"}


def _load_creds() -> None:
    if not CRED_FILE.exists():
        return
    for line in CRED_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip().strip('"'))


def _http_post_json(url: str, headers: dict, payload: dict, timeout: int = 30) -> tuple[int, str]:
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST")
    for k, v in headers.items():
        req.add_header(k, v)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace")


def _context_footer() -> str:
    return (
        f"\n\n--\n"
        f"host: {socket.gethostname()}  "
        f"cwd: {os.getcwd()}  "
        f"pid: {os.getpid()}  "
        f"ts:  {_dt.datetime.now().isoformat(timespec='seconds')}"
    )


def _send_email(subject: str, body: str, to_addr: str, html: Optional[str] = None) -> tuple[bool, str]:
    api_key   = os.environ.get("AGENTMAIL_API_KEY", "").strip()
    inbox_id  = os.environ.get("AGENTMAIL_INBOX_ID", "").strip()
    if not api_key or not inbox_id:
        return False, "missing AGENTMAIL_API_KEY or AGENTMAIL_INBOX_ID"

    # Path-encode the inbox id (contains '@' and possibly '.')
    inbox_enc = urllib.request.quote(inbox_id, safe="")
    url = f"https://api.agentmail.to/v0/inboxes/{inbox_enc}/messages/send"

    payload: dict = {"to": to_addr, "subject": subject, "text": body}
    if html:
        payload["html"] = html
    status, resp = _http_post_json(
        url,
        headers={"Authorization": f"Bearer {api_key}"},
        payload=payload,
    )
    ok = 200 <= status < 300
    return ok, f"http {status}: {resp[:300]}"


def _send_ntfy(
    subject: str,
    body: str,
    status: str,
    actions: Optional[str] = None,
    click: Optional[str] = None,
) -> tuple[bool, str]:
    topic = os.environ.get("NTFY_TOPIC", "").strip()
    if not topic:
        return False, "missing NTFY_TOPIC"
    server = os.environ.get("NTFY_SERVER", "https://ntfy.sh").rstrip("/")
    url = f"{server}/{urllib.request.quote(topic, safe='')}"

    # ntfy uses simple HTTP POST: body = message, headers = metadata.
    headers_ntfy = {
        "Title":    subject,
        "Priority": NTFY_PRIORITY.get(status, "3"),
        "Tags":     NTFY_TAGS.get(status, "information_source"),
    }
    # Optional: action buttons (semicolon-separated triplets per ntfy spec)
    #   e.g. "view, Open, https://x.com; http, Ack, https://api/, method=POST, body=ok"
    if actions:
        headers_ntfy["Actions"] = actions
    # Optional: tap-to-open URL
    if click:
        headers_ntfy["Click"] = click

    req = urllib.request.Request(url, data=body.encode("utf-8"), method="POST")
    for k, v in headers_ntfy.items():
        # ntfy requires ASCII-safe headers; strip anything funky.
        req.add_header(k, v.encode("ascii", "ignore").decode("ascii"))
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return (200 <= resp.status < 300), f"http {resp.status}"
    except urllib.error.HTTPError as e:
        return False, f"http {e.code}: {e.read().decode('utf-8', errors='replace')[:200]}"
    except Exception as e:  # noqa: BLE001
        return False, f"{type(e).__name__}: {e}"


def _send_teams(subject: str, body: str, status: str) -> tuple[bool, str]:
    url = os.environ.get("TEAMS_WEBHOOK_URL", "").strip()
    if not url:
        return False, "missing TEAMS_WEBHOOK_URL"

    color = STATUS_COLOR.get(status, STATUS_COLOR["info"])
    # MessageCard schema works with both legacy Office365 Connectors and the
    # current Power Automate "Post to Teams channel/chat" webhook templates.
    payload = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "summary": subject,
        "themeColor": color,
        "title": subject,
        "text": body.replace("\n", "  \n"),  # markdown line breaks
    }
    status_code, resp = _http_post_json(url, headers={}, payload=payload)
    ok = 200 <= status_code < 300
    return ok, f"http {status_code}: {resp[:200]}"


def notify(
    subject: str,
    body: str = "",
    *,
    status: str = "ok",
    channels: Iterable[str] = ("email",),
    to_addr: Optional[str] = None,
    include_context: bool = True,
    ntfy_actions: Optional[str] = None,
    ntfy_click: Optional[str] = None,
) -> dict:
    """Send a notification on one or more channels. Returns per-channel status."""
    _load_creds()
    if status not in STATUS_PREFIX:
        status = "info"
    prefixed = f"{STATUS_PREFIX[status]} {subject}"
    full_body = body + (_context_footer() if include_context else "")
    to_addr = to_addr or os.environ.get("NOTIFY_DEFAULT_TO", "").strip()

    results: dict[str, tuple[bool, str]] = {}
    for ch in channels:
        ch = ch.strip().lower()
        if ch == "email":
            if not to_addr:
                results[ch] = (False, "no recipient (set NOTIFY_DEFAULT_TO or pass to_addr)")
                continue
            html = (
                f"<p><strong>{STATUS_PREFIX[status]} {subject}</strong></p>"
                f"<pre style='font-family:Consolas,monospace;font-size:12px;"
                f"background:#f6f8fa;padding:10px;border-radius:4px;'>"
                f"{full_body}</pre>"
            )
            results[ch] = _send_email(prefixed, full_body, to_addr, html=html)
        elif ch == "teams":
            results[ch] = _send_teams(prefixed, full_body, status)
        elif ch == "ntfy":
            results[ch] = _send_ntfy(prefixed, full_body, status,
                                     actions=ntfy_actions, click=ntfy_click)
        else:
            results[ch] = (False, f"unknown channel '{ch}'")
    return {ch: {"ok": ok, "detail": detail} for ch, (ok, detail) in results.items()}


def _read_body(body: str, body_file: Optional[str]) -> str:
    if body_file:
        p = Path(body_file)
        if not p.exists():
            raise SystemExit(f"body-file not found: {body_file}")
        return p.read_text(encoding="utf-8")
    if body == "-" or (not body and not sys.stdin.isatty()):
        return sys.stdin.read()
    return body or ""


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--subject", "-s", required=True, help="Subject line")
    ap.add_argument("--body", "-b", default="", help="Body text (or '-' for stdin)")
    ap.add_argument("--body-file", help="Read body from a file (overrides --body)")
    ap.add_argument("--to", dest="to_addr", default=None,
                    help="Recipient email (default: NOTIFY_DEFAULT_TO)")
    ap.add_argument("--status", choices=list(STATUS_PREFIX), default="ok")
    ap.add_argument("--channel", "--channels", default="email",
                    help="Comma-separated: email,teams (default: email)")
    ap.add_argument("--no-context", action="store_true",
                    help="Suppress the host/cwd/pid/ts footer")
    ap.add_argument("--ntfy-actions", default=None,
                    help="ntfy action buttons (semicolon-separated). "
                         "e.g. 'http, Ack, https://ntfy.sh/topic, method=POST, body=ok'")
    ap.add_argument("--ntfy-click", default=None,
                    help="ntfy tap-to-open URL (Click header)")
    args = ap.parse_args()

    body = _read_body(args.body, args.body_file)
    res = notify(
        subject=args.subject,
        body=body,
        status=args.status,
        channels=[c for c in args.channel.split(",") if c.strip()],
        to_addr=args.to_addr,
        include_context=not args.no_context,
        ntfy_actions=args.ntfy_actions,
        ntfy_click=args.ntfy_click,
    )
    for ch, info in res.items():
        marker = "OK " if info["ok"] else "ERR"
        print(f"[{marker}] {ch}: {info['detail']}", flush=True)
    return 0 if all(v["ok"] for v in res.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
