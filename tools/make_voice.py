#!/usr/bin/env python3
"""Generates game audio with OpenRouter audio models (stdlib only + ffmpeg to transcode).

Speech: openai/gpt-audio-mini via /chat/completions audio modality, streamed SSE base64 pcm16.
Music:  google/lyria-3-clip-preview 30s loops via the same endpoint.
Key comes from OPENROUTER_API_KEY (env only, never written anywhere).
"""
import base64
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
import wave

API = "https://openrouter.ai/api/v1/chat/completions"
OUT = os.path.join(os.path.dirname(__file__), "..", "assets")
VOICE_DIR = os.path.join(OUT, "voice")
MUSIC_DIR = os.path.join(OUT, "music")

LINES = [
    # id, voice, direction, text
    ("heat1", "onyx", "Flat police-dispatcher radio cadence, authoritative, no emotion.",
     "Harbor dispatch, all units: suspect vehicle seen near Pier 7."),
    ("heat2", "onyx", "Flat police-dispatcher radio cadence, urgent but controlled.",
     "Suspect is running. All units converge on the quay."),
    ("heat3", "onyx", "Flat police-dispatcher radio cadence, sharp.",
     "All available units to the waterfront. Box that car in."),
    ("lost", "onyx", "Flat police-dispatcher radio cadence, irritated.",
     "Visual lost. Suspect in the wind. Resume patrol."),
    ("busted", "onyx", "Flat police-dispatcher radio cadence, satisfied.",
     "Suspect in custody. The case is secured."),
    ("odessa", "shimmer", "Smoky late-night female voice, slow, dangerous, a little amused.",
     "My courier froze at Pier 7. My buyer sails on the tide. Bring the case home, Rue, and we'll talk about your cut."),
    ("take", "shimmer", "Smoky late-night female voice, brief and businesslike.",
     "Good. Now drive like the tide depends on it."),
]

CLIPS = [
    # id, description (30s seamless loop)
    ("radio_bed", "Rain-soaked slow noir jazz loop: upright bass, brushed drums, muted trumpet phrases, wet street at night, no vocals, no drum fills, constant mid-tempo groove that loops seamlessly."),
    ("title_theme", "Brooding cinematic noir theme: low piano motif, slow strings, distant harbor horn, vinyl rain texture, coherent 30 second arc, gentle ending."),
]


def chat_audio(model, prompt, voice, fmt):
    payload = {
        "model": model,
        "modalities": ["text", "audio"],
        "audio": {"voice": voice, "format": fmt},
        "stream": True,
        "messages": [{"role": "user", "content": prompt}],
    }
    key = os.environ["OPENROUTER_API_KEY"]
    req = urllib.request.Request(
        API, data=json.dumps(payload).encode(),
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json",
                 "HTTP-Referer": "https://omarchy.local/backstreets", "X-Title": "Backstreets"})
    chunks = []
    transcript = ""
    try:
        r = urllib.request.urlopen(req, timeout=300)
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"HTTP {e.code}: {e.read().decode()[:500]}")
    with r:
        buf = b""
        while True:
            part = r.read(65536)
            if not part:
                break
            buf += part
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                line = line.strip()
                if not line.startswith(b"data:"):
                    continue
                body = line[5:].strip()
                if body == b"[DONE]":
                    continue
                try:
                    ev = json.loads(body)
                except json.JSONDecodeError:
                    continue
                for ch in ev.get("choices", []):
                    audio = (ch.get("delta", {}) or {}).get("audio") or {}
                    if isinstance(audio, dict) and audio.get("data"):
                        chunks.append(audio["data"])
                    if isinstance(audio, dict) and audio.get("transcript"):
                        transcript = str(audio["transcript"])
    if not chunks:
        raise RuntimeError("no audio data returned")
    return base64.b64decode("".join(chunks)), transcript


def write_wav(path, pcm16, rate, channels):
    with wave.open(path, "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm16)


def main() -> None:
    os.makedirs(VOICE_DIR, exist_ok=True)
    os.makedirs(MUSIC_DIR, exist_ok=True)
    only = sys.argv[1:] or None

    def want(i):
        return only is None or i in only

    for lid, voice, style, text in LINES:
        if not want(lid):
            continue
        print(f"voice {lid} ...", flush=True)
        raw, tr = chat_audio("openai/gpt-audio-mini",
                             f"Voice direction: {style}\nLine: {text}", voice, "pcm16")
        # gpt-audio speech stream is 24kHz mono pcm16
        tmp = os.path.join(VOICE_DIR, f"{lid}.raw")
        open(tmp, "wb").write(raw)
        wav = os.path.join(VOICE_DIR, f"{lid}.wav")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", "24000", "-ac", "1",
                        "-i", tmp, "-ar", "22050", wav], check=True)
        os.remove(tmp)
        print(f"  saved {wav} ({len(raw)} bytes) transcript={tr[:60]!r}")

    for cid, desc in CLIPS:
        if not want(cid):
            continue
        print(f"music {cid} ... (Lyria, may take a minute)", flush=True)
        raw, _tr = chat_audio("google/lyria-3-clip-preview", f"Generate a 30 second music clip: {desc}", "alloy", "mp3")
        tmp = os.path.join(MUSIC_DIR, f"{cid}.mp3")
        open(tmp, "wb").write(raw)
        wav = os.path.join(MUSIC_DIR, f"{cid}.wav")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-ar", "44100", "-ac", "2", wav], check=True)
        os.remove(tmp)
        print(f"  saved {wav} ({len(raw)} bytes)")


if __name__ == "__main__":
    main()
