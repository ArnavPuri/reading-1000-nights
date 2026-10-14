#!/usr/bin/env python3
"""Content pipeline: master sheet -> cleaned, measured content pack.

Steps (PRD "Pipeline"): fetch -> cut -> clean -> measure -> pack.
Review and illustration are manual/separate steps.

Usage:
    python3 content/tools/build_pack.py --pack 1 --nights 1-7 [--version 2]

Card art: a work uses images/<work id>.webp when that file exists at 1x and
2x, and falls back to images/<theme>.webp otherwise. Bump --version when the
art or text changes, or installed apps keep the pack they already imported.

Sources are fetched from the GITenberg mirror of Project Gutenberg texts
(raw.githubusercontent.com) and cached in content/.cache. Rows whose source
is "manual" read from content/manual/<source_file>.

The Gutenberg header and licence never enter the pack: only the text
between the row's start and end markers is kept, and the build fails if a
cut piece mentions Gutenberg.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import math
import re
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "content"
CACHE = CONTENT / ".cache"
MANUAL = CONTENT / "manual"
PACK_OUT = ROOT / "assets" / "packs"
REPORTS = CONTENT / "reports"

WPM = 230
PACK_FORMAT = 1
SIZING = {  # minutes, from the PRD sizing rules
    "story": (8, 15),
    "poem": (1, 4),
    "essay": (5, 10),
}
NIGHT_SIZING = (15, 25)


# --------------------------------------------------------------------------
# Fetch
# --------------------------------------------------------------------------

def fetch(source: str, source_file: str) -> str:
    if source == "manual":
        return (MANUAL / source_file).read_text(encoding="utf-8")
    CACHE.mkdir(parents=True, exist_ok=True)
    cached = CACHE / source_file
    if not cached.exists():
        url = f"https://raw.githubusercontent.com/{source}/master/{source_file}"
        print(f"  fetching {url}", file=sys.stderr)
        with urllib.request.urlopen(url, timeout=60) as resp:
            cached.write_bytes(resp.read())
    raw = cached.read_bytes()
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.decode("latin-1")


# --------------------------------------------------------------------------
# Cut
# --------------------------------------------------------------------------

def _parse_marker(spec: str) -> tuple[str, str, int]:
    kind, _, rest = spec.partition("=")
    text, _, nth = rest.rpartition("#") if "#" in rest else (rest, "", "1")
    return kind, text, int(nth or 1)


def _find(lines: list[str], text: str, nth: int, start: int, exact: bool) -> int:
    seen = 0
    for i in range(start, len(lines)):
        line = lines[i].strip()
        hit = line == text if exact else text in line
        if hit:
            seen += 1
            if seen == nth:
                return i
    raise ValueError(f"marker not found: {text!r} (#{nth})")


def cut(text: str, start_spec: str, end_spec: str) -> list[str]:
    lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    if not start_spec:
        begin = 0
    else:
        kind, marker, nth = _parse_marker(start_spec)
        if kind == "after":  # heading line; piece starts on the next line
            begin = _find(lines, marker, nth, 0, exact=True) + 1
        elif kind == "at":  # first line of the piece itself
            begin = _find(lines, marker, nth, 0, exact=False)
        else:
            raise ValueError(f"bad start marker {start_spec!r}")

    if not end_spec or end_spec == "eof":
        end = len(lines)
    elif end_spec.startswith("blank="):
        need = int(end_spec.split("=", 1)[1])
        end, run, i = len(lines), 0, begin
        # skip leading blanks before counting
        while i < len(lines) and not lines[i].strip():
            i += 1
        for j in range(i, len(lines)):
            run = run + 1 if not lines[j].strip() else 0
            if run >= need:
                end = j - need + 1
                break
    else:
        kind, marker, nth = _parse_marker(end_spec)
        if kind != "before":
            raise ValueError(f"bad end marker {end_spec!r}")
        end = _find(lines, marker, nth, begin, exact=True)
    return lines[begin:end]


# --------------------------------------------------------------------------
# Clean
# --------------------------------------------------------------------------

_NOISE = [
    re.compile(r"\[(Illustration|Picture|Frontispiece)[^\]]*\]", re.I),
    re.compile(r"\{\d+\}"),           # page markers
    re.compile(r"\[\d+\]"),           # footnote references
]


def _blocks(lines: list[str]) -> list[list[str]]:
    blocks, cur = [], []
    for line in lines:
        for pat in _NOISE:
            line = pat.sub("", line)
        if line.strip():
            cur.append(line.rstrip())
        elif cur:
            blocks.append(cur)
            cur = []
    if cur:
        blocks.append(cur)
    # drop footnote blocks and separator lines such as "*****"
    return [
        b for b in blocks
        if not b[0].lstrip().startswith(("[Footnote", "Footnote"))
        and not re.fullmatch(r"[\s*.]+", " ".join(b))
    ]


def _smart_quotes(s: str) -> str:
    s = s.replace("--", "—")
    # old typesetting spaced contractions: "I 've", "it 's" -> "I've", "it's"
    s = re.sub(r"(\w) '(ve|ll|re|s|d|m)\b", r"\1'\2", s)
    out = []
    for i, ch in enumerate(s):
        prev = s[i - 1] if i else " "
        nxt = s[i + 1] if i + 1 < len(s) else " "
        if ch == '"':
            out.append("“" if prev.isspace() or prev in "([—‘" else "”")
        elif ch == "'":
            opening = (prev.isspace() or prev in "([—“") and nxt.isalpha()
            # 't is, 'tis, 'em are elisions, not opening quotes
            if opening and re.match(r"'(t |tis|twas|em\b|neath)", s[i:i + 5]):
                opening = False
            out.append("‘" if opening else "’")
        else:
            out.append(ch)
    return "".join(out)


def _italics(s: str) -> str:
    return re.sub(r"_([^_]+)_", r"*\1*", s)


def _decap_first_word(s: str) -> str:
    # "SHE said" / "IT seems" / "OLENKA, the daughter" -> sentence case
    m = re.match(r"^([“‘\"']?)([A-Z][A-Z]+)\b", s)
    if m and len(m.group(2)) >= 2:
        word = m.group(2)
        s = m.group(1) + word[0] + word[1:].lower() + s[m.end():]
    return s


def clean_prose(lines: list[str]) -> list[str]:
    paras = []
    for block in _blocks(lines):
        para = " ".join(l.strip() for l in block)
        para = re.sub(r"\s+", " ", para).strip()
        paras.append(_italics(_smart_quotes(para)))
    if paras:
        paras[0] = _decap_first_word(paras[0])
    return paras


def clean_poem(lines: list[str]) -> list[str]:
    stanzas = []
    for block in _blocks(lines):
        base = min(len(l) - len(l.lstrip()) for l in block)
        out: list[str] = []
        for line in block:
            indent = len(line) - len(line.lstrip())
            text = re.sub(r"\s+", " ", line.strip())
            if out and indent >= base + 4:  # hard-wrapped continuation line
                out[-1] = f"{out[-1]} {text}"
            else:
                out.append(text)
        stanzas.append("\n".join(_italics(_smart_quotes(l)) for l in out))
    return stanzas


# --------------------------------------------------------------------------
# Measure
# --------------------------------------------------------------------------

def word_count(text: str) -> int:
    return len(re.findall(r"[\w’'—-]+", text.replace("—", " ")))


def truncate(blocks: list[str], max_words: int) -> list[str]:
    out, total = [], 0
    for b in blocks:
        if out and total + word_count(b) > max_words:
            break
        out.append(b)
        total += word_count(b)
    return out


# --------------------------------------------------------------------------
# Pack
# --------------------------------------------------------------------------

@dataclass
class Row:
    night: int
    type: str
    title: str
    author: str
    year: int
    translator: str
    origin: str
    gender: str
    source: str
    source_file: str
    start: str
    end: str
    max_words: str
    label: str
    theme: str
    pull_quote: str


def slug(s: str) -> str:
    s = s.lower().replace("’", "").replace("'", "")
    s = re.sub(r"[éè]", "e", s)
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")


def rights_note(r: Row) -> str:
    note = f"Published {r.year}; public domain in the US (published 1930 or earlier)."
    if r.translator:
        note += f" Translation: {r.translator}."
    note += " Pending legal review."
    return note


def image_for(pack_id: int, wid: str, theme: str) -> tuple[str | None, str]:
    """The work's own engraving if it exists at both sizes, else its theme's."""
    images = PACK_OUT / f"pack-{pack_id:03d}" / "images"
    for name, kind in ((wid, "own"), (theme, "theme")):
        if name and (images / f"{name}.webp").exists() and (images / "2.0x" / f"{name}.webp").exists():
            return f"assets/packs/pack-{pack_id:03d}/images/{name}.webp", kind
    return None, "missing"


def build(pack_id: int, first: int, last: int, version: int = 1) -> int:
    with open(CONTENT / "master_sheet.csv", newline="", encoding="utf-8") as f:
        rows = [Row(**{**r, "night": int(r["night"]), "year": int(r["year"])})
                for r in csv.DictReader(f)]
    rows = [r for r in rows if first <= r.night <= last]

    works, days, report, problems = [], {}, [], 0
    for r in rows:
        if r.translator:
            m = re.search(r"\((\d{4})\)", r.translator)
            if m and int(m.group(1)) > 1930:
                print(f"RIGHTS: {r.title}: translation after 1930", file=sys.stderr)
                problems += 1
        elif r.year > 1930:
            print(f"RIGHTS: {r.title}: published after 1930", file=sys.stderr)
            problems += 1

        raw = fetch(r.source, r.source_file)
        try:
            piece = cut(raw, r.start, r.end)
        except ValueError as e:
            raise SystemExit(f"CUT: night {r.night} {r.title}: {e}")
        blocks = clean_poem(piece) if r.type == "poem" else clean_prose(piece)
        excerpt = False
        if r.max_words:
            trimmed = truncate(blocks, int(r.max_words))
            excerpt = len(trimmed) < len(blocks)
            blocks = trimmed
        text_md = "\n\n".join(blocks).strip() + "\n"
        if "gutenberg" in text_md.lower():
            print(f"CLEAN: {r.title}: Gutenberg text left in piece", file=sys.stderr)
            problems += 1

        words = word_count(text_md)
        minutes = max(1, round(words / WPM))
        lo, hi = SIZING[r.type]
        flag = "" if lo <= minutes <= hi else f"outside {lo}-{hi} min"

        part_label = r.label or ""
        if part_label == "from" and not excerpt:
            part_label = ""

        wid = f"{slug(r.author.split()[-1])}-{slug(r.title)}"
        image_path, art = image_for(pack_id, wid, r.theme)
        if image_path is None:
            print(f"ART: {r.title}: no images/{wid}.webp or images/{r.theme}.webp at 1x and 2x", file=sys.stderr)
            problems += 1
        works.append({
            "id": wid,
            "type": r.type,
            "title": r.title,
            "author": r.author,
            "year": r.year,
            "word_count": words,
            "est_minutes": minutes,
            "part_label": part_label or None,
            "text_md": text_md,
            "image_path": image_path,
            "source_ref": (f"manual:{r.source_file}" if r.source == "manual"
                           else f"github.com/{r.source}/{r.source_file}"),
            "rights_note": rights_note(r),
            "pull_quote": r.pull_quote or None,
        })
        days.setdefault(r.night, {"day_number": r.night})[f"{r.type}_id"] = wid
        report.append((r.night, r.type, r.title, r.author, words, minutes, art, flag))

    for n, d in days.items():
        missing = {"story_id", "poem_id", "essay_id"} - d.keys()
        if missing:
            print(f"NIGHT {n}: missing {sorted(missing)}", file=sys.stderr)
            problems += 1

    pack = {
        "format": PACK_FORMAT,
        "pack_id": pack_id,
        "version": version,
        "first_day": first,
        "last_day": last,
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "days": [days[n] for n in sorted(days)],
        "works": works,
    }
    PACK_OUT.mkdir(parents=True, exist_ok=True)
    out = PACK_OUT / f"pack-{pack_id:03d}.json"
    out.write_text(json.dumps(pack, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")

    REPORTS.mkdir(parents=True, exist_ok=True)
    lines = [f"# Pack {pack_id:03d} measure report", "",
             f"Nights {first}-{last}, {len(works)} pieces, {WPM} wpm.", "",
             "| Night | Type | Title | Author | Words | Min | Art | Flag |",
             "| --- | --- | --- | --- | --- | --- | --- | --- |"]
    for n, t, title, author, w, m, art, flag in report:
        lines.append(f"| {n} | {t} | {title} | {author} | {w} | {m} | {art} | {flag} |")
    lines += ["", "| Night | Total min | Flag |", "| --- | --- | --- |"]
    for n in sorted(days):
        total = sum(m for nn, *_, m, _art, _f in report if nn == n)
        lo, hi = NIGHT_SIZING
        lines.append(f"| {n} | {total} | {'' if lo <= total <= hi else f'outside {lo}-{hi} min'} |")
    (REPORTS / f"pack-{pack_id:03d}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"wrote {out.relative_to(ROOT)} ({len(works)} works, {len(days)} nights)")
    print("\n".join(lines))
    return 1 if problems else 0


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pack", type=int, default=1)
    ap.add_argument("--nights", default="1-7", help="e.g. 1-30")
    ap.add_argument("--version", type=int, default=1, help="bump when art or text changes")
    a = ap.parse_args()
    first, last = (int(x) for x in a.nights.split("-"))
    sys.exit(build(a.pack, first, last, a.version))


if __name__ == "__main__":
    main()
