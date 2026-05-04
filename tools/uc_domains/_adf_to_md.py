#!/usr/bin/env python3
"""
Best-effort ADF → Markdown converter for Confluence pages fetched via
Atlassian MCP (which returns ADF JSON even when format=markdown is requested).

Usage:
  python tools/uc_domains/_adf_to_md.py --in <agent-tools-page.txt> [--out <md path>]

Reads the JSON file (must contain top-level body.content), walks the ADF tree,
emits a flat Markdown document. Does NOT cover every ADF mark — focuses on
headings, paragraphs, lists, tables, code, links, panels.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def _marks_wrap(text: str, marks: list[dict] | None) -> str:
    if not marks or not text:
        return text
    out = text
    for m in marks:
        t = m.get("type")
        if t == "strong":
            out = f"**{out}**"
        elif t == "em":
            out = f"*{out}*"
        elif t == "code":
            out = f"`{out}`"
        elif t == "underline":
            pass  # markdown doesn't have a clean underline
        elif t == "link":
            href = (m.get("attrs") or {}).get("href")
            if href:
                out = f"[{out}]({href})"
        elif t == "strike":
            out = f"~~{out}~~"
    return out


def _node_to_md(node: dict, depth: int = 0) -> str:
    t = node.get("type")
    content = node.get("content") or []
    if t == "text":
        return _marks_wrap(node.get("text", ""), node.get("marks"))
    if t == "hardBreak":
        return "  \n"
    if t == "paragraph":
        inner = "".join(_node_to_md(c, depth) for c in content)
        return inner + "\n\n"
    if t == "heading":
        level = (node.get("attrs") or {}).get("level", 1)
        inner = "".join(_node_to_md(c, depth) for c in content)
        return f"{'#' * level} {inner.strip()}\n\n"
    if t == "bulletList":
        return "".join(_node_to_md(c, depth) for c in content) + "\n"
    if t == "orderedList":
        out = []
        for i, c in enumerate(content, 1):
            li = _node_to_md(c, depth)
            out.append(li.replace("- ", f"{i}. ", 1))
        return "".join(out) + "\n"
    if t == "listItem":
        prefix = "  " * depth + "- "
        children_md = []
        for c in content:
            md = _node_to_md(c, depth + 1)
            children_md.append(md.rstrip())
        body = "\n".join(x for x in children_md if x).strip()
        return prefix + body + "\n"
    if t == "codeBlock":
        lang = (node.get("attrs") or {}).get("language", "")
        text = "".join(c.get("text", "") for c in content)
        return f"```{lang}\n{text}\n```\n\n"
    if t == "blockquote":
        inner = "".join(_node_to_md(c, depth) for c in content).strip().splitlines()
        return "\n".join("> " + l for l in inner) + "\n\n"
    if t == "table":
        rows = []
        for row in content:
            cells = []
            for cell in row.get("content") or []:
                cell_md = "".join(_node_to_md(c, depth) for c in cell.get("content") or []).strip().replace("\n", " ")
                cells.append(cell_md)
            rows.append(cells)
        if not rows:
            return ""
        out = []
        header = rows[0]
        out.append("| " + " | ".join(header) + " |")
        out.append("|" + "|".join(["---"] * len(header)) + "|")
        for r in rows[1:]:
            r = (r + [""] * len(header))[: len(header)]
            out.append("| " + " | ".join(r) + " |")
        return "\n".join(out) + "\n\n"
    if t == "panel":
        kind = (node.get("attrs") or {}).get("panelType", "info")
        inner = "".join(_node_to_md(c, depth) for c in content).strip()
        return f"> **[{kind.upper()}]** " + inner.replace("\n", "\n> ") + "\n\n"
    if t == "rule":
        return "\n---\n\n"
    if t == "extension" or t == "inlineExtension":
        title = (node.get("attrs") or {}).get("parameters", {}).get("macroMetadata", {}).get("title")
        if title:
            return f"<!-- macro: {title} -->\n\n"
        return ""
    if t == "mediaSingle" or t == "media":
        return "<!-- media omitted -->\n"
    if content:
        return "".join(_node_to_md(c, depth) for c in content)
    return ""


def doc_to_md(doc: dict) -> str:
    if not doc:
        return ""
    parts = [_node_to_md(c) for c in doc.get("content") or []]
    md = "".join(parts)
    while "\n\n\n" in md:
        md = md.replace("\n\n\n", "\n\n")
    return md.strip() + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description="ADF→Markdown for cached MCP pages")
    ap.add_argument("--in", dest="inp", required=True, help="JSON file from Atlassian MCP getConfluencePage")
    ap.add_argument("--out", dest="out", default=None, help="Markdown out (default stdout)")
    args = ap.parse_args()

    raw = Path(args.inp).read_text(encoding="utf-8")
    obj = json.loads(raw)
    body = obj.get("body") or {}
    md = doc_to_md(body)

    title = obj.get("title", "")
    page_id = obj.get("id", "")
    web_url = obj.get("webUrl", "")
    space_id = obj.get("spaceId", "")
    out_doc = f"# {title}\n\n_pageId={page_id} spaceId={space_id} url={web_url}_\n\n{md}"

    if args.out:
        Path(args.out).write_text(out_doc, encoding="utf-8")
        print(f"[adf2md] wrote {args.out} ({len(out_doc):,} chars)")
    else:
        sys.stdout.write(out_doc)
    return 0


if __name__ == "__main__":
    sys.exit(main())
