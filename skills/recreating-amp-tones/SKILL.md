---
name: recreating-amp-tones
description: "Use when recreating a famous or reference guitar/bass tone with whatever amp-sim / amp-modeling plugins the user already has installed (Neural DSP, STL, ML Sound Lab, Helix Native, Amplitube, NAM, Bias FX, Archetype, Quad Cortex plugin, etc.). Covers discovering installed sims, locating where their preset files actually live on disk, researching the target rig on tone forums, and creating/cloning a preset that approximates it. Triggers: 'recreate <artist> tone', 'what amp sims do I have', 'where are my presets', 'make me a preset for X', 'dial in the <album> tone', 'find guitar DI stems to test'."
---

# Recreating Amp Tones

## Overview

Recreate a target guitar/bass tone in four phases: **discover** installed sims → **locate** their preset files → **research** the real rig → **create** a preset that approximates it. This is amp-sim **agnostic** — the vendor names change, the four phases don't.

**Core principle:** Never guess. Preset *locations* and *file formats* are both non-obvious and vary per vendor — inspect, don't assume. A `.xml` or `.preset` file is very often **binary**, not text.

## When to Use

- "Recreate Metallica's *Master of Puppets* rhythm tone with what I have installed"
- "Where does <plugin> store its presets?"
- "Make me a preset for X" / "dial in the <album> tone"
- "Find raw guitar DI stems so I can test a tone"

## Phase 1 — Discover installed sims

Check plugin folders **and** standalone apps. Many modeling plugins also ship a standalone `.app` that holds the same presets.

**macOS** (system `/Library` + user `~/Library`):
```bash
for d in /Library/Audio/Plug-Ins ~/Library/Audio/Plug-Ins; do
  ls "$d"/Components "$d"/VST3 "$d"/VST "$d"/CLAP 2>/dev/null
done
ls /Applications | grep -iE 'neural|archetype|amplitube|bias|helix|STL|tonex|nam|guitar|amp'
```
**Windows:** `C:\Program Files\Common Files\VST3`, `...\Avid\Audio\Plug-Ins` (AAX), vendor folders in `Program Files`.
**Linux:** `~/.vst3`, `/usr/lib/vst3`, `~/.clap`.

**Picking the target sim:** choose the installed sim whose *modeled* amp is closest in circuit/voicing to the real rig (a Marshall-style model for a Marshall tone, a high-gain model for a Randall/5150 tone). If nothing matches the actual amp, pick the closest **gain character** and tell the user up front it's an approximation.

## Phase 2 — Locate preset files (the part everyone gets wrong)

**Presets are almost never next to the plugin binary.** They live in a vendor data dir, and the *right* one is often not the first you find. Search broadly, then confirm:

```bash
# cast a wide net across the usual roots
find /Library/Audio/Presets ~/Library/Audio/Presets \
     ~/Documents ~/Library/Application\ Support \
     -iname '*<vendor>*' -maxdepth 4 2>/dev/null
```

Common macOS homes: `/Library/Audio/Presets/<Vendor>/<Plugin>/User/`, `~/Library/Audio/Presets`, `~/Documents/<Vendor>/<Plugin>/`, `~/Library/Application Support/<Vendor>/`.

**The reliable trick when unsure:** have the user save a preset named `ZZTEST` in the plugin UI, then find the newest file:
```bash
find ~ /Library/Audio/Presets -iname '*ZZTEST*' 2>/dev/null   # exact folder + extension
```
If several candidate folders exist (Documents vs Application Support vs /Library/Audio/Presets), **ask the user which one the plugin reads from** — they often differ, and writing to the wrong one means the preset never appears. **No GUI session?** Fall back to the newest existing preset by mtime (`ls -t <vendor dir>/**/*.{xml,preset}`) and treat the folder holding the user's own saved presets as the write target.

## Phase 3 — Research the target rig

Use `WebSearch` to build consensus from multiple results. Capture: **amp/model**, **boost or pedal** (and *how* it's used — e.g. a Boss MT-2 run as a mid/boost into the amp's gain channel, not as standalone distortion), **guitar/pickups**, **tuning**, and the **EQ stance** (mids forward vs scooped).

**Gotcha:** the best tone forums are bot-walled. `WebFetch` returns **403** and `curl` hits a Cloudflare "Just a moment…" challenge on **UltimateMetal (the Andy Sneap community), TheGearPage, Cambridge-MT**. Don't fight it — mine the `WebSearch` result summaries instead, and cite primary sources (engineer/artist interviews) over forum hearsay. Note when a claim is forum consensus vs documented fact.

## Phase 4 — Create the preset

**Translate the research into settings first.** The Phase-3 findings map to knobs, not exact numbers: *mids forward* → raise amp Mid + don't scoop the EQ; *tight/low-gain-feel* → high-pass or pull Low to kill flub; *boost in front* → enable an OD/EQ block (the stand-in for the real pedal). Set **Gain to taste and A/B against the record** — parameter values are starting points to tune by ear, never copied blindly. Clone from a preset on a **similar channel** (don't start from a clean patch for a high-gain tone).

**Inspect the format before touching it.** Extension lies:
```bash
file "preset.xml"                       # often: "data" not "XML text"
python3 -c "d=open('preset.xml','rb').read(); print('NUL' in repr(d[:200]), d[:80])"
```

- **If real text (XML/JSON):** edit values directly.
- **If binary** (NUL / `\x01`-`\x08` control bytes, JUCE ValueTree, length-prefixed strings): **do NOT hand-author.** Clone an existing preset and patch only the *values*, fixing any per-value length byte. Never change the number of fields. **Clone from a preset saved by the SAME plugin version** — the binary layout can drift between versions and invalidate the offsets.

**Deriving the length-prefix rule (don't assume `+2`):** the `+2` below is specific to one vendor's format — *measure your own*. Dump several real entries and compare each length byte to its value length:
```python
import re
d = open(SRC,"rb").read()
for m in re.finditer(rb'([A-Za-z]+)\x00\x01(.)\x05([ -~]+)\x00', d):
    key,Lbyte,val = m.group(1).decode(), m.group(2)[0], m.group(3).decode()
    print(f"{key:18} Lbyte={Lbyte:3} len={len(val):3} delta={Lbyte-len(val)}")  # delta is your N
```
If `delta` is constant → that's `N`. If it isn't constant, or values exceed ~253 chars (length needs >1 byte / varint), or keys aren't plain ASCII, the format is more complex than this pattern — **stop and study it further or have the user save in-app instead.**

Clone-and-patch pattern (binary, length-prefixed):
```python
# Each value framed as: <key>\x00 \x01 <Lbyte> \x05 <ascii value> \x00   where Lbyte == len(value)+2
import os
data = bytearray(open(SRC, "rb").read())          # SRC = an existing preset, kept READ-ONLY
def patch(key, newval):
    i = data.find(key.encode()+b"\x00\x01"); assert i!=-1, key
    j = i+len(key)+2; assert data[j+1]==0x05        # j = length byte
    end = data.index(b"\x00", j+2)
    data[j:end] = bytes([len(newval)+2]) + b"\x05" + newval.encode()
for k,v in {"name":"My Tone","ampGain":"0.74","ampMid":"0.66"}.items(): patch(k,v)
assert open(SRC,"rb").read().count(b"\x00") == bytes(data).count(b"\x00")  # field count unchanged
open(DST,"wb").write(bytes(data))                 # DST = NEW file in the Phase-2 folder
```
**Verify (two levels):** (1) *structural* — re-read the new file, confirm each value round-trips and every length byte satisfies the measured rule, and the field/NUL count matches the source. (2) *auditory* — a structurally valid preset can still be silent or musically wrong; have the user (or the standalone app) **load it and confirm it makes sound and sounds in the ballpark**, ideally by running a DI stem through it (see Bonus). Then place it in the folder confirmed in Phase 2 (mirror to other candidate folders only if the plugin reads them).

## Bonus — DI stems for testing (no playing required)

Dry direct-input guitar to run through the new preset:
**Trust your ears — many "DIs" are programmed, not played.** A lot of catalog "DIs" (especially note-for-note covers of famous albums) are **MIDI run through a sampled-guitar VSTi** (Shreddage/Ample-type), not a human recording. They're often dressed up with humanized timing, mains hum, and round-robin samples specifically to *look* real — which defeats automated forensics (onset-jitter, repeat-correlation, hum, DC-offset tests all come back ambiguous). **The only reliable test is listening:** programmed guitar lacks organic feel (pick attack variation, fret/finger noise, micro-dynamics). Audition before trusting any DI.

- **Verified-organic, curl-able (preferred):** amp-modeling/reamp repos store *real recorded* `*-input.wav` (dry DI) vs `*-target.wav` (amped) — these are genuine playing used to train captures. e.g. `GuitarML/Automated-GuitarAmpModelling` `Data/train/*-input.wav`, `GuitarML/PedalNetRT/data/ts9_test1_in_FP32.wav`. Find via the GitHub trees API, download with `curl -sL <raw url>`. Real studio multitracks (Cambridge-MT *actual band* recordings, not covers) are also organic.
- **Omega Station "Multitracks & DIs List" (large catalog, audition first):** a ~520-row spreadsheet (find the CSV export) with `GTR DI` / `BASS DI` Y/N flags, genre, and a per-entry download link. Convenient and broad, but its classic-album entries are **cover re-creations and frequently programmed/sampled, not organic** — useful only after you've listened and confirmed. Parse with Python `csv`, filter `GTR DI == 'Y'` + a download link, match on genre.
- **Getting past the blogspot redirect:** most Omega Station download links point at an `omegastationmusic.blogspot.com` landing page, not a file. `curl` the page, grep for the embedded `drive.google.com/file/d/<ID>` link, then download the actual file from the direct endpoint `https://drive.usercontent.google.com/download?id=<ID>&export=download&confirm=t` (a `HEAD` first reveals the real filename + size via `content-disposition`/`content-length`). Unpack `.7z` with `bsdtar -xf` (built into macOS).
- **Browser only (bot-walled):** Cambridge-MT "Mixing Secrets" library (filter Genre → Hard Rock & Metal, look for a "Gtr DI" track), UltimateMetal "Free Multitracks & DIs" list.
- DIs are usually mono and quiet — nudge input gain; real album DIs often come **double-tracked** (`Guitar 1` / `Guitar 2`) — hard-pan them L/R for the wall.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Assuming presets sit next to the plugin | They're in a vendor data dir; search broadly + save-a-test-preset trick |
| Trusting the `.xml`/`.preset` extension | `file` it / read the bytes — it's often binary |
| Hand-authoring a binary preset | Clone an existing one, patch values, fix length prefixes |
| Writing to the wrong preset folder | Confirm which folder the plugin actually reads; ask the user |
| Editing the source preset in place | Keep the source read-only; always write a NEW file |
| Cloning from a different plugin version | Binary layout drifts between versions — clone from a same-version preset |
| Declaring done after a byte-level round-trip | Also load it and confirm it makes sound (auditory check) |
| Copying knob values from a forum verbatim | Values are starting points; A/B against the record and tune by ear |
| Trusting a downloaded "DI" without listening | Many catalog DIs are MIDI→sampled-guitar VSTi dressed to look real; only your ears catch it — audition first |
| `WebFetch`-ing forums and giving up on 403 | Use `WebSearch` summaries; cite interviews over forum claims |
| Expecting an exact match | Sims model different amps than the original rig — set expectations: it's an approximation |
