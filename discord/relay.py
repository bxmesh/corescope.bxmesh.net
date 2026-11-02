"""Posts new messages from CoreScope's decoded MeshCore channels to Discord webhooks.

Every POLL_SECONDS it reads each channel's latest messages from CoreScope's API
(GET /api/channels/<name>/messages) and posts the ones it hasn't posted yet, oldest first, to that
channel's webhook. A message is one transmission, so the same message heard by several observers
is posted once. Which messages were posted is remembered as the highest packetId per channel, in
STATE_DIR, so a restart neither skips nor repeats; on a channel's first run it starts from the
newest message and posts nothing older.

Configuration (environment):
  CORESCOPE_URL    CoreScope inside the cluster, e.g. http://corescope
  CHANNELS         channel=secret-file pairs, comma-separated, e.g. "#bathurst=bathurst,Public=public"
  SECRETS_DIR      folder of webhook URL files, one per secret-file name (default /srv/secrets)
  STATE_DIR        folder for the state file (default /var/lib/relay)
  POLL_SECONDS     default 15

Standard library only. The webhook URLs are secrets: never logged.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

CORESCOPE_URL = os.environ["CORESCOPE_URL"].rstrip("/")
SECRETS_DIR = os.environ.get("SECRETS_DIR", "/srv/secrets")
STATE_DIR = os.environ.get("STATE_DIR", "/var/lib/relay")
POLL_SECONDS = float(os.environ.get("POLL_SECONDS", "15"))
STATE_FILE = os.path.join(STATE_DIR, "state.json")
PAGE = 50  # messages read per channel per poll; more than arrive in 15 s
DISCORD_MAX = 2000  # Discord's limit on a message's content


def log(msg):
    print(time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), msg, flush=True)


def channels():
    """[(channel name, webhook URL)] from CHANNELS and the secret files."""
    out = []
    for pair in os.environ["CHANNELS"].split(","):
        name, _, secret = pair.strip().rpartition("=")
        with open(os.path.join(SECRETS_DIR, secret)) as f:
            url = f.read().strip()
        if not url.startswith("https://discord.com/api/webhooks/"):
            sys.exit(f"{secret}: not a Discord webhook URL")
        out.append((name, url))
    return out


def load_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def save_state(state):
    tmp = STATE_FILE + ".new"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, STATE_FILE)


USER_AGENT = "bxmesh-discord-relay"


def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def messages(channel):
    """The channel's latest messages, oldest first (CoreScope returns them in that order)."""
    name = urllib.parse.quote(channel, safe="")
    data = get_json(f"{CORESCOPE_URL}/api/channels/{name}/messages?limit={PAGE}")
    return [m for m in data.get("messages", []) if isinstance(m.get("packetId"), int)]


def escape(text):
    """Discord markdown off for mesh text: what was sent is what's shown."""
    for ch in "\\*_~`|>":
        text = text.replace(ch, "\\" + ch)
    return text


def post(url, message):
    """Posts one message; True once Discord has it. Waits out a rate limit and tries again."""
    sender = escape((message.get("sender") or "unknown").strip())
    content = f"**{sender}**: {escape(message['text'].strip())}"[:DISCORD_MAX]
    body = json.dumps({
        "content": content,
        # Never ping anyone: a mesh message can't @everyone or @someone on Discord.
        "allowed_mentions": {"parse": []},
    }).encode()
    req = urllib.request.Request(
        url + "?wait=true", data=body, method="POST",
        headers={"Content-Type": "application/json", "User-Agent": USER_AGENT})
    for _ in range(5):
        try:
            with urllib.request.urlopen(req, timeout=30):
                return True
        except urllib.error.HTTPError as e:
            if e.code == 429:
                retry = float(json.loads(e.read() or b"{}").get("retry_after", 2))
                log(f"rate limited; waiting {retry:.1f} s")
                time.sleep(retry)
                continue
            log(f"Discord refused packet {message['packetId']}: HTTP {e.code}")
            return False
        except (urllib.error.URLError, TimeoutError) as e:
            log(f"Discord unreachable: {e}")
            return False
    return False


def poll(chans, state):
    for channel, url in chans:
        try:
            msgs = messages(channel)
        except (urllib.error.URLError, TimeoutError, ValueError) as e:
            log(f"{channel}: CoreScope unreachable: {e}")
            continue
        newest = max((m["packetId"] for m in msgs), default=0)
        if channel not in state:
            state[channel] = newest
            save_state(state)
            log(f"{channel}: first run, starting after packet {newest}; nothing older is posted")
            continue
        for m in sorted(msgs, key=lambda m: m["packetId"]):
            if m["packetId"] <= state[channel] or not m.get("text"):
                continue
            if not post(url, m):
                break  # try again next poll, from this message
            state[channel] = m["packetId"]
            save_state(state)
            log(f"{channel}: posted packet {m['packetId']}")
            time.sleep(0.5)  # well inside a webhook's 5 requests per 2 seconds


def main():
    chans = channels()
    state = load_state()
    log(f"relaying {', '.join(c for c, _ in chans)} from {CORESCOPE_URL} every {POLL_SECONDS:g} s")
    while True:
        poll(chans, state)
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
