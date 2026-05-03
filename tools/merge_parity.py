#!/usr/bin/env python3
"""Merge synapse-MCP markdown output and UC TSV output into a parity comparison."""
from __future__ import annotations

import re
import sys
from decimal import Decimal

SYN_FILE = sys.argv[1]
UC_FILE = sys.argv[2]
START_DATEID = int(sys.argv[3]) if len(sys.argv) > 3 else 20250101

DECIMAL_TOL = Decimal("0.01")
METRICS = ["deposits", "tp_equity", "sdrt", "upnl", "funded"]


def to_dec(s):
    s = (s or "").strip()
    if not s:
        return None
    return Decimal(s)


def to_int(s):
    s = (s or "").strip()
    if not s:
        return None
    return int(float(s))


def parse_markdown(path):
    out = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            if not line.startswith("|"):
                continue
            cells = [c.strip() for c in line.strip("\n").strip("|").split("|")]
            if len(cells) < 6:
                continue
            if cells[0] in ("DateID", "---") or set(cells[0]) <= {"-"}:
                continue
            try:
                d = int(cells[0])
            except ValueError:
                continue
            if d < START_DATEID:
                continue
            out[d] = {
                "deposits":  to_dec(cells[1]),
                "tp_equity": to_dec(cells[2]),
                "sdrt":      to_dec(cells[3]),
                "upnl":      to_dec(cells[4]),
                "funded":    to_int(cells[5]),
            }
    return out


def parse_tsv(path):
    out = {}
    header_seen = False
    # PowerShell `>` redirect writes UTF-16 LE with BOM by default
    with open(path, "rb") as fb:
        raw = fb.read()
    for enc in ("utf-16", "utf-16-le", "utf-8-sig", "utf-8"):
        try:
            text = raw.decode(enc)
            break
        except UnicodeDecodeError:
            continue
    else:
        raise RuntimeError(f"Could not decode {path}")
    for line in text.splitlines():
        if True:
            line = line.rstrip("\n")
            if not line or "\t" not in line:
                continue
            cells = line.split("\t")
            if cells[0] == "DateID":
                header_seen = True
                continue
            if not header_seen:
                continue
            if len(cells) < 6:
                continue
            try:
                d = int(cells[0])
            except ValueError:
                continue
            if d < START_DATEID:
                continue
            out[d] = {
                "deposits":  to_dec(cells[1]),
                "tp_equity": to_dec(cells[2]),
                "sdrt":      to_dec(cells[3]),
                "upnl":      to_dec(cells[4]),
                "funded":    to_int(cells[5]),
            }
    return out


def vals_match(metric, a, b):
    if a is None and b is None:
        return True
    if a is None or b is None:
        return False
    if metric == "funded":
        return int(a) == int(b)
    return abs(Decimal(a) - Decimal(b)) <= DECIMAL_TOL


def fmt(v):
    return "" if v is None else str(v)


def main():
    syn = parse_markdown(SYN_FILE)
    uc = parse_tsv(UC_FILE)
    all_d = sorted(set(syn) | set(uc))

    headers = ["DateID"]
    for m in METRICS:
        headers += [f"syn_{m}", f"uc_{m}", f"diff_{m}"]
    headers.append("mismatch")

    rows = []
    for d in all_d:
        s = syn.get(d) or {m: None for m in METRICS}
        u = uc.get(d) or {m: None for m in METRICS}
        bad = [m for m in METRICS if not vals_match(m, s[m], u[m])]
        if not bad and d in syn and d in uc:
            continue
        if d not in syn:
            bad.insert(0, "MISSING_IN_SYN")
        if d not in uc:
            bad.insert(0, "MISSING_IN_UC")
        row = [str(d)]
        for m in METRICS:
            sv, uv = s[m], u[m]
            if sv is None or uv is None:
                diff = ""
            elif m == "funded":
                diff = str(int(sv) - int(uv))
            else:
                diff = str(Decimal(sv) - Decimal(uv))
            row += [fmt(sv), fmt(uv), diff]
        row.append("|".join(bad))
        rows.append(row)

    print(",".join(headers))
    for r in rows:
        print(",".join(r))

    print(
        f"\n[summary] syn={len(syn)} uc={len(uc)} mismatches={len(rows)}",
        file=sys.stderr,
    )


if __name__ == "__main__":
    sys.stdout.reconfigure(line_buffering=True)
    main()
