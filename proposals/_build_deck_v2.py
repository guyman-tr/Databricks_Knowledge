"""Build the v2 executive .pptx deck — three-act structure.

Reuses helper functions and reusable slide builders from `_build_deck.py`,
adds new act-divider slides, a methodology slide, a roadmap-overview slide,
a watcher-fleet detail slide, and a smaller-scopes / open-decisions slide.
Reframes everything that previously used "gap" / "wrong" language into
roadmap task families and sub-tasks.

Run from repo root:
    python proposals/_build_deck_v2.py

Produces:
    proposals/exec-deck-anthropic-self-service-analytics-v2-2026-06-08.pptx
"""
from __future__ import annotations

from pathlib import Path

# Reuse helpers + theme constants + reusable slide builders from v1.
from _build_deck import (  # type: ignore
    Presentation,
    RGBColor,
    MSO_SHAPE,
    PP_ALIGN,
    MSO_ANCHOR,
    Inches,
    Pt,
    SLIDE_W,
    SLIDE_H,
    NAVY,
    INK,
    SUBTLE,
    ACCENT,
    GREEN_FILL,
    YELLOW_FILL,
    RED_FILL,
    GREEN_DOT,
    YELLOW_DOT,
    RED_DOT,
    WHITE,
    HEADER_FILL,
    BAND_FILL,
    RULE,
    add_blank_slide,
    add_text,
    add_rich,
    add_rect,
    slide_header,
    add_bullet_list,
    add_scorecard_table,
    build_slide_3_framework,
    build_slide_machine,
    build_slide_8_evals,
    build_slide_9_provenance,
    build_slide_deliberate_non_adoption,
)


# ─────────────────────────── act divider helper ───────────────────────────

def build_act_divider(prs, page, total, *, act_label: str, act_title: str,
                       blurb: str):
    """Full-bleed navy slide announcing the next act."""
    s = add_blank_slide(prs)
    add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, NAVY)
    add_rect(s, Inches(0), Inches(5.5), SLIDE_W, Inches(2.0),
             RGBColor(0x06, 0x1A, 0x2E))

    add_text(s, Inches(1.0), Inches(1.6), Inches(11), Inches(0.5),
             act_label.upper(), size=13, bold=True,
             color=RGBColor(0x6F, 0xB0, 0xD9))
    add_text(s, Inches(1.0), Inches(2.20), Inches(11.3), Inches(1.6),
             act_title, size=48, bold=True, color=WHITE)
    add_text(s, Inches(1.0), Inches(4.05), Inches(11.3), Inches(1.4),
             blurb, size=18, color=RGBColor(0xB7, 0xCF, 0xE6),
             italic=True)
    add_text(s, Inches(11.5), Inches(7.05), Inches(1.5), Inches(0.3),
             f"{page} / {total}", size=10,
             color=RGBColor(0xB7, 0xCF, 0xE6), align=PP_ALIGN.RIGHT)


# ─────────────────────────── new slide builders ───────────────────────────

def build_slide_cover_v2(prs, total):
    s = add_blank_slide(prs)
    add_rect(s, Inches(0), Inches(0), SLIDE_W, SLIDE_H, NAVY)
    add_rect(s, Inches(0), Inches(5.2), SLIDE_W, Inches(2.3),
             RGBColor(0x06, 0x1A, 0x2E))

    add_text(s, Inches(1.0), Inches(0.9), Inches(11), Inches(0.4),
             "EXECUTIVE BRIEFING · 2026-06-08 · v2",
             size=12, bold=True, color=RGBColor(0x6F, 0xB0, 0xD9))
    add_text(s, Inches(1.0), Inches(1.45), Inches(11.3), Inches(1.4),
             "Self-service analytics at eToro",
             size=46, bold=True, color=WHITE)
    add_text(s, Inches(1.0), Inches(2.85), Inches(11.3), Inches(0.7),
             "Three acts: what we learned from Anthropic, what we already built, "
             "and the roadmap we're proposing.",
             size=20, color=RGBColor(0xB7, 0xCF, 0xE6))

    # The three-act mini-map on the cover
    mini_top = Inches(3.75)
    mini_h = Inches(1.30)
    col_w = Inches(3.95)
    gap = Inches(0.15)
    acts = [
        ("ACT I", "Research", "What Anthropic's article taught us about how self-service analytics actually works."),
        ("ACT II", "Comparison", "Where eToro already stands against that framework — including one deliberate non-adoption."),
        ("ACT III", "Action Plan", "The roadmap. Six task families. Everything we plan to do, broken into sub-tasks."),
    ]
    x = Inches(1.0)
    for i, (badge, title, body) in enumerate(acts):
        add_rect(s, x, mini_top, col_w, mini_h,
                 RGBColor(0x14, 0x2D, 0x4F), line_color=RGBColor(0x29, 0x5A, 0x90))
        add_text(s, x + Inches(0.2), mini_top + Inches(0.10),
                 col_w - Inches(0.4), Inches(0.3), badge,
                 size=11, bold=True, color=RGBColor(0x6F, 0xB0, 0xD9))
        add_text(s, x + Inches(0.2), mini_top + Inches(0.35),
                 col_w - Inches(0.4), Inches(0.4), title,
                 size=22, bold=True, color=WHITE)
        add_text(s, x + Inches(0.2), mini_top + Inches(0.75),
                 col_w - Inches(0.4), mini_h - Inches(0.80), body,
                 size=11, color=RGBColor(0xB7, 0xCF, 0xE6))
        x += col_w + gap

    # Audience / source band
    add_text(s, Inches(1.0), Inches(5.45), Inches(11.3), Inches(0.5),
             "Source: How Anthropic enables self-service data analytics with Claude (claude.com/blog, 2026-06-03)",
             size=12, color=RGBColor(0xB7, 0xCF, 0xE6), italic=True)
    add_text(s, Inches(1.0), Inches(6.05), Inches(11.3), Inches(0.5),
             "Audience: Data leadership · Eng leadership · Analyst-team leads   |   Read time: ~10 min",
             size=12, color=RGBColor(0xB7, 0xCF, 0xE6))
    add_text(s, Inches(1.0), Inches(6.55), Inches(11.3), Inches(0.5),
             "No effort numbers — task families and sub-tasks only.",
             size=12, color=RGBColor(0xB7, 0xCF, 0xE6), italic=True)


def build_slide_act1_divider(prs, page, total):
    build_act_divider(
        prs, page, total,
        act_label="Act I",
        act_title="Research",
        blurb="What Anthropic's article taught us about doing self-service analytics with an LLM agent. "
              "Three failure modes, a four-layer stack, and one trade-off they quantified.",
    )


def build_slide_act2_divider(prs, page, total):
    build_act_divider(
        prs, page, total,
        act_label="Act II",
        act_title="Comparison",
        blurb="Where eToro already stands against the Act I framework. "
              "Headline: 5 green, 6 in-motion, 4 roadmap — 1 of which is intentional non-adoption.",
    )


def build_slide_act3_divider(prs, page, total):
    build_act_divider(
        prs, page, total,
        act_label="Act III",
        act_title="Action Plan",
        blurb="The roadmap. Six task families. Every yellow on Act II's scorecard is a planned task family here. "
              "Roadmap language — no gaps, no failures, just work breakdown.",
    )


def build_slide_research_methodology(prs, page, total):
    """Act I, Slide R2 — Anthropic's methodology + observed trade-offs."""
    s = add_blank_slide(prs)
    slide_header(s, "Anthropic's methodology and the trade-offs they observed",
                 eyebrow="Act I — Research finding 3",
                 page_num=page, total=total)

    # Methodology bullets
    add_text(s, Inches(0.6), Inches(1.30), Inches(12), Inches(0.4),
             "Methodology — what they do for every domain",
             size=13, bold=True, color=NAVY)

    method = [
        ("Pin every eval to a snapshot date.",
         " Write it against a stable fact table, or have the grader judge the agent's "
         "query shape — not its number — so refreshes don't break evals."),
        ("Ship a provenance footer on every answer.",
         " Source tier (semantic layer › curated view › raw exploration), freshness, "
         "owner, skill+sha. Silent wrong answers are the highest-risk failure mode "
         "and the footer is what makes the silent default safe."),
        ("Active correction harvesting.",
         " A scheduled agent reads Slack / feedback channels every few hours for "
         "correction language, drafts one-line markdown fixes, opens PRs tagged to "
         "the domain owner."),
        ("90% per-domain accuracy floor before announcement.",
         " A domain owner cannot announce the agent to their stakeholders until "
         "their slice of the eval set clears the threshold."),
        ("Skill-touch CI hook.",
         " 90% of their data-model PRs include a skill-file change in the same diff, "
         "enforced by CI."),
    ]
    y = Inches(1.70)
    for lead, body in method:
        circ = s.shapes.add_shape(MSO_SHAPE.OVAL, Inches(0.6), y + Inches(0.04),
                                  Inches(0.18), Inches(0.18))
        circ.fill.solid(); circ.fill.fore_color.rgb = ACCENT
        circ.line.fill.background(); circ.shadow.inherit = False
        add_rich(s, Inches(0.95), y, Inches(12), Inches(0.35), [
            {"runs": [
                {"text": lead, "size": 12, "bold": True, "color": INK},
                {"text": body, "size": 12, "color": INK},
            ]},
        ])
        y += Inches(0.55)

    # The trade-off they quantified
    trade_top = Inches(4.55)
    add_text(s, Inches(0.6), trade_top, Inches(12), Inches(0.4),
             "One trade-off they took and quantified",
             size=13, bold=True, color=NAVY)
    add_text(s, Inches(0.6), trade_top + Inches(0.40), Inches(12), Inches(0.35),
             "Mandatory adversarial review (\"Challenge the Solution\") on every answer:",
             size=12, color=INK)

    metrics = [
        ("Accuracy lift", "+6%", GREEN_DOT),
        ("Token cost", "+32%", YELLOW_DOT),
        ("Latency cost", "+72%", RED_DOT),
    ]
    metric_top = trade_top + Inches(0.85)
    for i, (k, v, col) in enumerate(metrics):
        left = Inches(0.6 + i * 4.1)
        add_rect(s, left, metric_top, Inches(3.9), Inches(0.9), BAND_FILL,
                 line_color=RULE)
        add_text(s, left + Inches(0.2), metric_top + Inches(0.05),
                 Inches(2.0), Inches(0.35), k, size=11, color=SUBTLE)
        add_text(s, left + Inches(0.2), metric_top + Inches(0.32),
                 Inches(3.5), Inches(0.5), v, size=22, bold=True, color=col)

    add_text(s, Inches(0.6), Inches(6.65), Inches(12.2), Inches(0.4),
             "We carry this number into Act II — it's the basis for our one "
             "deliberate non-adoption.",
             size=11, italic=True, color=SUBTLE)


def build_slide_scorecard_v2(prs, page, total):
    """Act II — Slide C1. Same data as v1 scorecard, Priority column relabeled
    to 'Roadmap home' so the framing is forward-looking."""
    s = add_blank_slide(prs)
    slide_header(s, "How our stack maps to Anthropic's framework",
                 eyebrow="Act II — Comparison",
                 page_num=page, total=total)

    rows = [
        ("g", "Canonical datasets",
         "etoro_kpi views own MIMO / AUM / PFOF; other domains route through canonical prep views + DDR",
         "—"),
        ("y", "Skills + models colocation",
         "Both live in DataPlatform; CI-enforcement hook is task family 2",
         "Task family 2"),
        ("g", "UC metadata as product",
         "Column-level descriptions deployed across 6 domains",
         "—"),
        ("y", "Semantic layer (declarative)",
         "Not declarative yet — skills route to etoro_kpi canonical views, so ambiguity-collapse partially realized",
         "Task family 6"),
        ("g", "Lineage + table ranking",
         "Genie Code has UC lineage access",
         "—"),
        ("y", "Query corpus",
         "Captured (MCP + Genie gateway); distillation manual today",
         "Task family 4"),
        ("y", "Business context",
         "SME / TVF docs in Synapse Wiki + Confluence; not piped to agents yet",
         "Task family 4"),
        ("g", "Skills (knowledge router)",
         "Hub-and-spoke; ~13 entry + 45 sub-skills; MCP-served, CI-validated",
         "—"),
        ("y", "Skills (unbook / process)",
         "Substance authored (3-skill triple in prod) — analyst-triggered today; auto-fire promotion is task family 6",
         "Task family 6"),
        ("r", "Offline evals",
         "Not yet — /feedback app already captures graded Q&A in production",
         "Task family 1"),
        ("r", "Ablation methodology",
         "Not yet — task family 1 + 5",
         "Task family 1+5"),
        ("r", "Provenance footer",
         "Not yet on Genie / MCP responses — task family 3 (final-answer-assembly enforced)",
         "Task family 3"),
        ("r", "Adversarial review on every answer",
         "DELIBERATE non-adoption (see Act II Slide C3) — semi-annual revisit only",
         "Reject"),
        ("g", "Passive monitoring",
         "genie_audit_events + MCP gateway logs live",
         "—"),
        ("y", "Active correction harvesting",
         "Substrate ready (/feedback + MCP user-message logs); scheduled classifier + PR-draft agent is task family 4",
         "Task family 4"),
    ]
    add_scorecard_table_v2(s, rows, Inches(0.5), Inches(1.35),
                            Inches(12.3), Inches(5.55))
    add_text(s, Inches(0.5), Inches(6.95), Inches(12), Inches(0.4),
             "Score: 5 green · 6 in-motion · 4 roadmap.   "
             "Every yellow and red is a planned task family in Act III. The one Reject "
             "is the deliberate non-adoption.",
             size=11, italic=True, color=SUBTLE)


def add_scorecard_table_v2(slide, rows, left, top, total_w, total_h):
    """Like v1's add_scorecard_table but renames the Priority header to
    'Roadmap home' and supports 'Task family N' / 'Reject' / '—' pill values."""
    col_widths = [Inches(0.5), Inches(3.3), Inches(6.5), Inches(2.0)]
    header_h = Inches(0.36)
    body_top = top + header_h
    available_h = total_h - header_h
    row_h = available_h / len(rows) if rows else Inches(0.3)

    # Header band
    add_rect(slide, left, top, total_w, header_h, NAVY)
    x = left
    headers = ["", "Anthropic layer", "eToro today", "Roadmap home"]
    for w, h in zip(col_widths, headers):
        add_text(slide, x + Inches(0.1), top + Inches(0.05), w - Inches(0.2),
                 header_h - Inches(0.1), h, size=11, bold=True, color=WHITE)
        x += w

    dot_color_map = {"g": GREEN_DOT, "y": YELLOW_DOT, "r": RED_DOT}

    for i, (dot, layer, status, prio) in enumerate(rows):
        row_top = body_top + int(row_h * i)
        add_rect(slide, left, row_top, total_w, row_h,
                 BAND_FILL if i % 2 == 0 else WHITE, line_color=RULE)
        # Status dot
        pill_left = left + Inches(0.10)
        pill_top = row_top + Inches(0.05)
        pill_w = Inches(0.3)
        pill_h = row_h - Inches(0.10)
        circ = slide.shapes.add_shape(MSO_SHAPE.OVAL, pill_left, pill_top,
                                      pill_w, pill_h)
        circ.fill.solid()
        circ.fill.fore_color.rgb = dot_color_map[dot]
        circ.line.fill.background()
        circ.shadow.inherit = False
        # Layer name
        add_text(slide, left + col_widths[0] + Inches(0.05),
                 row_top + Inches(0.02),
                 col_widths[1] - Inches(0.1), row_h - Inches(0.04),
                 layer, size=10, bold=True, color=INK,
                 anchor=MSO_ANCHOR.MIDDLE)
        # Status text
        add_text(slide, left + col_widths[0] + col_widths[1] + Inches(0.05),
                 row_top + Inches(0.02),
                 col_widths[2] - Inches(0.1), row_h - Inches(0.04),
                 status, size=9, color=INK, anchor=MSO_ANCHOR.MIDDLE)
        # Roadmap home pill
        prio_left = left + col_widths[0] + col_widths[1] + col_widths[2] + Inches(0.1)
        prio_w = col_widths[3] - Inches(0.2)
        if prio == "—":
            prio_fill = GREEN_FILL
            prio_text_color = GREEN_DOT
        elif prio == "Reject":
            prio_fill = RED_FILL
            prio_text_color = RED_DOT
        else:
            prio_fill = HEADER_FILL
            prio_text_color = ACCENT
        add_rect(slide, prio_left, row_top + Inches(0.07), prio_w,
                 row_h - Inches(0.14), prio_fill, line_color=RULE)
        add_text(slide, prio_left, row_top + Inches(0.05), prio_w,
                 row_h - Inches(0.1), prio, size=9, bold=True,
                 color=prio_text_color, align=PP_ALIGN.CENTER,
                 anchor=MSO_ANCHOR.MIDDLE)


def build_slide_strengths_v2(prs, page, total):
    """Act II — Slide C2. Seven assets we already have (consolidated v2 list)."""
    s = add_blank_slide(prs)
    slide_header(s, "What we already built that maps cleanly to Anthropic's framework",
                 eyebrow="Act II — Comparison",
                 page_num=page, total=total)
    items = [
        ("Knowledge skill corpus.",
         " Hub-and-spoke routing, CI-enforced frontmatter, kebab-case names, required body sections. "
         "Identical shape to Anthropic's appendix skeleton."),
        ("🚀 Unbook SUBSTANCE — decomposed better than Anthropic's.",
         " Three-skill triple on Databricks Assistant (data-analysis-playbook + patterns + pattern-library) "
         "splits process from routing from detail. Analyst-triggered today; auto-fire promotion is task family 6."),
        ("Skills + models in the same repo (DataPlatform).",
         " CI-deployed. Same colocation Anthropic endorses — enforcement hook is task family 2."),
        ("Cross-surface portability.",
         " Same skill served via MCP gateway → Cursor IDE, Genie Code, standalone agents."),
        ("Telemetry foundations live.",
         " genie_audit_events + monitoring_mcp_logs_mcp_gateway capture skill loads, NL prompts, generated SQL."),
        ("🚀 /feedback Databricks app — strategic asset.",
         " Every Genie answer one-click graded; landed in de_output_genie_code_skill_feedback. "
         "Fastest path to a labeled eval set in the industry — Anthropic builds evals by hand; we harvest them in production."),
        ("UC as a documented warehouse + workspace-level assistant defaults.",
         " ~10k+ column comments deployed across 6 domains; .assistant_workspace_instructions.md anchors cross-Genie-Code behavior."),
    ]
    add_bullet_list(s, Inches(0.6), Inches(1.35), Inches(12.2), Inches(5.5),
                    items, size=13, spacing=12)


def build_slide_roadmap_overview(prs, page, total):
    """Act III — Slide A2. Six task families table (roadmap overview)."""
    s = add_blank_slide(prs)
    slide_header(s, "Roadmap overview — six task families",
                 eyebrow="Act III — Action Plan",
                 page_num=page, total=total)

    add_text(s, Inches(0.5), Inches(1.30), Inches(12.3), Inches(0.4),
             "Every yellow on the Act II scorecard is a planned task family here. "
             "Detail follows for the three with the most sub-task depth.",
             size=12, italic=True, color=SUBTLE)

    headers = ["#", "Task family", "What it produces", "First sub-task we'd ship"]
    col_widths = [Inches(0.55), Inches(3.0), Inches(5.55), Inches(3.20)]
    top = Inches(1.85)
    header_h = Inches(0.40)
    total_w = sum(col_widths, Inches(0))

    add_rect(s, Inches(0.5), top, total_w, header_h, NAVY)
    x = Inches(0.5)
    for w, h in zip(col_widths, headers):
        align = PP_ALIGN.CENTER if h == "#" else PP_ALIGN.LEFT
        add_text(s, x + Inches(0.08), top + Inches(0.05),
                 w - Inches(0.16), header_h - Inches(0.1), h,
                 size=11, bold=True, color=WHITE, align=align)
        x += w

    rows = [
        ("1", ACCENT,
         "Truth Sensor",
         "eval substrate",
         "Pinned canonical Q&A set + per-domain accuracy dashboard",
         "Synthesize the first eval slice from /feedback 4★+5★ submissions"),
        ("2", ACCENT,
         "Model-Change Watcher",
         "skill-touch CI hook",
         "Blocks canonical-view PRs that don't touch a skill",
         "Single PR adding the CI rule on DataPlatform"),
        ("3", ACCENT,
         "Output Contract",
         "provenance footer enforced",
         "Every MCP and Genie Code answer carries source tier + freshness + owner + skill@sha + confidence",
         "MCP gateway middleware injection"),
        ("4", RED_DOT,
         "Multi-Source Watcher Fleet",
         "the heart of the machine",
         "Confluence / SharePoint / UC schema / UC lineage / MCP-correction watchers → draft skill PRs",
         "MCP correction harvester (logs are live; lowest friction)"),
        ("5", ACCENT,
         "Ablation-grade telemetry",
         "per-skill / per-model observability",
         "Makes \"did skill X help?\" a SQL query, not an A/B study",
         "Enrich monitoring_mcp_logs_mcp_gateway schema"),
        ("6", YELLOW_DOT,
         "Open design decisions",
         "parked, not stuck",
         "Resolved when the data justifies the choice (unbook auto-fire / 10-KPI metric-view pilot / adversarial-review revisit)",
         "Promote final-answer-assembly to default output on domain-* hub queries"),
    ]
    row_top = top + header_h
    row_h = Inches(0.78)
    for i, (n, dot_col, label, subtitle, what, first) in enumerate(rows):
        is_big = (i == 3)
        rh = Inches(0.95) if is_big else row_h
        fill = BAND_FILL if i % 2 == 0 else WHITE
        if is_big:
            fill = RGBColor(0xFF, 0xEC, 0xEF)
        add_rect(s, Inches(0.5), row_top, total_w, rh, fill, line_color=RULE)
        # Number circle
        circ_x = Inches(0.5) + Inches(0.10)
        circ_y = row_top + (rh - Inches(0.40)) / 2
        circ = s.shapes.add_shape(MSO_SHAPE.OVAL, circ_x, circ_y,
                                  Inches(0.40), Inches(0.40))
        circ.fill.solid(); circ.fill.fore_color.rgb = dot_col
        circ.line.fill.background(); circ.shadow.inherit = False
        add_text(s, circ_x, circ_y, Inches(0.40), Inches(0.40), n,
                 size=14, bold=True, color=WHITE,
                 align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
        # Task family label + subtitle
        comp_x = Inches(0.5) + col_widths[0] + Inches(0.05)
        add_text(s, comp_x, row_top + Inches(0.06),
                 col_widths[1] - Inches(0.1), Inches(0.30), label,
                 size=12, bold=True, color=dot_col)
        add_text(s, comp_x, row_top + Inches(0.32),
                 col_widths[1] - Inches(0.1), rh - Inches(0.34),
                 subtitle, size=10, italic=True, color=SUBTLE)
        # What it does
        what_x = comp_x + col_widths[1]
        add_text(s, what_x, row_top + Inches(0.06),
                 col_widths[2] - Inches(0.10), rh - Inches(0.12),
                 what, size=10, color=INK, anchor=MSO_ANCHOR.MIDDLE)
        # First sub-task
        first_x = what_x + col_widths[2]
        add_text(s, first_x, row_top + Inches(0.06),
                 col_widths[3] - Inches(0.10), rh - Inches(0.12),
                 first, size=10, italic=True, color=ACCENT,
                 anchor=MSO_ANCHOR.MIDDLE)
        row_top += rh


def build_slide_truth_sensor(prs, page, total):
    """Act III — Slide A3. Task family 1: Truth Sensor (eval substrate).
    Same content as v1's slide_8_evals but reframed as task family 1."""
    s = add_blank_slide(prs)
    slide_header(s, "Task family 1: Truth Sensor (the eval substrate)",
                 eyebrow="Act III — Action Plan",
                 page_num=page, total=total)

    add_rect(s, Inches(0.6), Inches(1.25), Inches(12.2), Inches(0.55),
             HEADER_FILL)
    add_text(s, Inches(0.85), Inches(1.30), Inches(11.7), Inches(0.45),
             "\"Data teams set up elaborate analytic environments without any process to "
             "understand the accuracy of their analytics agents.\"  — Anthropic",
             size=12, italic=True, color=INK, anchor=MSO_ANCHOR.MIDDLE)

    add_text(s, Inches(0.6), Inches(1.95), Inches(12), Inches(0.4),
             "What it produces",
             size=12, bold=True, color=ACCENT)
    add_text(s, Inches(0.6), Inches(2.25), Inches(12.2), Inches(0.5),
             "Pinned canonical Q&A eval set, run on every skill PR, gated at 90% per "
             "domain before an agent is announced to that domain.",
             size=11, color=INK)

    add_text(s, Inches(0.6), Inches(2.85), Inches(12), Inches(0.4),
             "Why this task family ships first",
             size=12, bold=True, color=ACCENT)
    add_text(s, Inches(0.6), Inches(3.15), Inches(12.2), Inches(0.5),
             "The /feedback app is already harvesting graded Q&A in production. "
             "The labeled data arrives every day. Anthropic's hardest problem becomes our easiest.",
             size=11, color=INK)

    add_text(s, Inches(0.6), Inches(3.80), Inches(12), Inches(0.4),
             "Sub-tasks (in build order)",
             size=12, bold=True, color=NAVY)

    steps = [
        ("Harvest 4★ + 5★ submissions → graded-correct canonical Q&A pairs.",
         "  Pin to created_at snapshot. Grader checks SQL shape, not number."),
        ("Harvest 1★ + 2★ submissions with free-text corrections → active-correction stream.",
         "  Each is a candidate skill-file edit (feeds task family 4)."),
        ("LLM-cluster NL questions per domain — frequency-weighted Pareto.",
         "  Top 30 question clusters per domain cover the long tail."),
        ("Land eval runs as telemetry in a Delta table.",
         "  eval_id, skill_version_sha, model_id, run_ts, passed_bool, per_assertion_json, tokens, latency."),
        ("Wire into CI on every skill PR.",
         "  Run only the eval slice affected by the diff."),
        ("Gate at 90% per domain before announcement.",
         "  Anthropic's threshold. Non-negotiable."),
    ]
    y = Inches(4.20)
    for i, (lead, body) in enumerate(steps):
        circ = s.shapes.add_shape(MSO_SHAPE.OVAL, Inches(0.6), y, Inches(0.36),
                                  Inches(0.36))
        circ.fill.solid(); circ.fill.fore_color.rgb = ACCENT
        circ.line.fill.background(); circ.shadow.inherit = False
        add_text(s, Inches(0.6), y, Inches(0.36), Inches(0.36), str(i + 1),
                 size=12, bold=True, color=WHITE, align=PP_ALIGN.CENTER,
                 anchor=MSO_ANCHOR.MIDDLE)
        add_rich(s, Inches(1.10), y + Inches(0.04), Inches(11.5), Inches(0.36), [
            {"runs": [
                {"text": lead, "size": 11, "bold": True, "color": INK},
                {"text": body, "size": 11, "color": INK},
            ]},
        ])
        y += Inches(0.40)


def build_slide_output_contract(prs, page, total):
    """Act III — Slide A4. Task family 3: Output Contract (provenance footer).
    Similar to v1's slide_9_provenance, renamed and slightly reframed."""
    s = add_blank_slide(prs)
    slide_header(s, "Task family 3: Output Contract (provenance footer)",
                 eyebrow="Act III — Action Plan",
                 page_num=page, total=total)

    # Footer template box
    add_rect(s, Inches(0.6), Inches(1.25), Inches(12.2), Inches(1.55),
             RGBColor(0x14, 0x1F, 0x33))
    add_text(s, Inches(0.85), Inches(1.32), Inches(11.7), Inches(0.32),
             "Every user-facing answer carries this footer:",
             size=11, color=RGBColor(0xB7, 0xCF, 0xE6))
    add_text(s, Inches(0.85), Inches(1.62), Inches(11.7), Inches(1.15),
             "Source: semantic layer / curated view / raw exploration\n"
             "Freshness: data through YYYY-MM-DD\n"
             "Owner: <team>     |     Skill: <skill_id>@<commit_sha>\n"
             "Confidence: H / M / L",
             size=12, color=WHITE)

    add_text(s, Inches(0.6), Inches(2.95), Inches(12), Inches(0.4),
             "Why this task family ships in parallel with the eval substrate",
             size=11, bold=True, color=ACCENT)
    add_text(s, Inches(0.6), Inches(3.25), Inches(12.2), Inches(0.45),
             "Silent wrong answers are the highest-risk failure mode. The footer is "
             "the online safety net while the eval gate is being built.",
             size=11, color=INK)

    add_text(s, Inches(0.6), Inches(3.85), Inches(12), Inches(0.4),
             "Sub-tasks, by surface",
             size=13, bold=True, color=NAVY)

    headers = ["Surface", "How", "Status"]
    col_widths = [Inches(3.7), Inches(6.6), Inches(2.0)]
    rows = [
        ("MCP gateway responses",
         "Append footer in the gateway middleware. We own the layer end-to-end.",
         "One PR"),
        ("Genie Code (Databricks Assistant in notebooks)",
         "Two paths: (a) add the mandate to .assistant_workspace_instructions.md "
         "at workspace root — applies globally; or (b) push a dedicated "
         "final-answer-assembly skill into /.assistant/skills/.",
         "Choose (a)/(b)"),
        ("Cursor IDE",
         "Covered — only our custom MCP sees skill-load context. No separate action.",
         "Covered by MCP"),
        ("Classic Genie Space",
         "Out of scope — no skill / instruction injection point yet. "
         "Databricks-controlled. Wait for product.",
         "Wait for Databricks"),
    ]
    x = Inches(0.6)
    top = Inches(4.30)
    header_h = Inches(0.36)
    add_rect(s, x, top, sum(col_widths, Inches(0)), header_h, NAVY)
    for w, h in zip(col_widths, headers):
        add_text(s, x + Inches(0.1), top + Inches(0.05), w - Inches(0.2),
                 header_h - Inches(0.1), h, size=11, bold=True, color=WHITE)
        x += w
    for i, (surface, how, status) in enumerate(rows):
        row_top = top + header_h + Inches(0.55 * i)
        row_h = Inches(0.55)
        skipped = "Out of scope" in status or "Covered" in status
        fill = BAND_FILL if i % 2 == 0 else WHITE
        add_rect(s, Inches(0.6), row_top, sum(col_widths, Inches(0)), row_h,
                 fill, line_color=RULE)
        add_text(s, Inches(0.7), row_top + Inches(0.04),
                 col_widths[0] - Inches(0.1), row_h - Inches(0.08),
                 surface, size=11, bold=True,
                 color=SUBTLE if skipped else INK,
                 anchor=MSO_ANCHOR.MIDDLE, italic=skipped)
        add_text(s, Inches(0.7) + col_widths[0], row_top + Inches(0.04),
                 col_widths[1] - Inches(0.2), row_h - Inches(0.08),
                 how, size=10, color=SUBTLE if skipped else INK,
                 anchor=MSO_ANCHOR.MIDDLE, italic=skipped)
        pill_left = Inches(0.7) + col_widths[0] + col_widths[1]
        pill_w = col_widths[2] - Inches(0.2)
        pill_fill = HEADER_FILL if skipped else GREEN_FILL if "One PR" in status else YELLOW_FILL
        add_rect(s, pill_left, row_top + Inches(0.12), pill_w,
                 row_h - Inches(0.24), pill_fill, line_color=RULE)
        add_text(s, pill_left, row_top + Inches(0.10), pill_w,
                 row_h - Inches(0.20), status, size=10, bold=True,
                 color=SUBTLE if skipped else INK,
                 align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)

    # Adjacent open decision
    add_text(s, Inches(0.6), Inches(6.65), Inches(12.2), Inches(0.7),
             "Adjacent open decision (task family 6): promote final-answer-assembly to the default "
             "output mode for domain-* hub queries — the cheapest minimal-unbook auto-fire candidate. "
             "Start at (a), let the eval gate justify (b) metric-definition-check or (c) question-framing.",
             size=10, italic=True, color=SUBTLE)


def build_slide_watcher_fleet(prs, page, total):
    """Act III — Slide A5. Task family 4: Multi-Source Watcher Fleet."""
    s = add_blank_slide(prs)
    slide_header(s, "Task family 4 (the heart of the machine): Multi-Source Watcher Fleet",
                 eyebrow="Act III — Action Plan",
                 page_num=page, total=total)

    add_rect(s, Inches(0.6), Inches(1.25), Inches(12.2), Inches(0.55),
             RGBColor(0xFF, 0xEC, 0xEF), line_color=RED_DOT)
    add_text(s, Inches(0.85), Inches(1.30), Inches(11.7), Inches(0.45),
             "The difference between a corpus authored once and forgotten, and a corpus "
             "that continuously re-validates itself against every knowledge source in the company.",
             size=12, italic=True, color=NAVY, anchor=MSO_ANCHOR.MIDDLE)

    add_text(s, Inches(0.6), Inches(1.95), Inches(12), Inches(0.4),
             "Sub-tasks — one strand per knowledge source",
             size=13, bold=True, color=NAVY)

    # Watcher table
    headers = ["Watcher", "Trigger", "Action"]
    col_widths = [Inches(2.8), Inches(5.0), Inches(4.5)]
    top = Inches(2.4)
    header_h = Inches(0.36)
    total_w = sum(col_widths, Inches(0))

    add_rect(s, Inches(0.6), top, total_w, header_h, NAVY)
    x = Inches(0.6)
    for w, h in zip(col_widths, headers):
        add_text(s, x + Inches(0.1), top + Inches(0.05),
                 w - Inches(0.2), header_h - Inches(0.1), h,
                 size=11, bold=True, color=WHITE)
        x += w

    watchers = [
        ("MCP correction harvester",
         "Scheduled scan of monitoring_mcp_logs_mcp_gateway user messages for correction language "
         "(\"that's wrong\", \"you forgot\", \"the right table is\") + /feedback 1★/2★ comments",
         "LLM classifier → domain-tagged draft PR with proposed skill-file edit"),
        ("Confluence new-page watcher",
         "Confluence webhook / scheduled diff on tagged spaces",
         "LLM classifier: \"does this change the routing for domain-X?\" → draft PR if yes"),
        ("SharePoint new-doc watcher",
         "Scheduled scan of mapped SharePoint folders (the post-Fivetran source of truth for ops-authored data)",
         "Same pattern as Confluence"),
        ("UC schema-delta watcher",
         "Daily diff on system.information_schema.tables + .columns",
         "Renamed / dropped / added column → flag the skill(s) whose required_tables include that table"),
        ("UC lineage-delta watcher",
         "Daily diff on system.access.column_lineage",
         "Upstream change → flag downstream skills' required_tables for review"),
    ]
    row_top = top + header_h
    row_h = Inches(0.58)
    for i, (w_name, trigger, action) in enumerate(watchers):
        fill = BAND_FILL if i % 2 == 0 else WHITE
        if i == 0:
            fill = GREEN_FILL  # MCP correction harvester is "start here"
        add_rect(s, Inches(0.6), row_top, total_w, row_h, fill, line_color=RULE)
        add_text(s, Inches(0.70), row_top + Inches(0.05),
                 col_widths[0] - Inches(0.10), row_h - Inches(0.10),
                 w_name, size=10, bold=True, color=INK,
                 anchor=MSO_ANCHOR.MIDDLE)
        add_text(s, Inches(0.70) + col_widths[0], row_top + Inches(0.05),
                 col_widths[1] - Inches(0.10), row_h - Inches(0.10),
                 trigger, size=9, color=INK, anchor=MSO_ANCHOR.MIDDLE)
        add_text(s, Inches(0.70) + col_widths[0] + col_widths[1],
                 row_top + Inches(0.05),
                 col_widths[2] - Inches(0.10), row_h - Inches(0.10),
                 action, size=9, color=INK, anchor=MSO_ANCHOR.MIDDLE)
        row_top += row_h

    # Shared infrastructure callout + build order
    callout_top = Inches(5.55)
    add_rect(s, Inches(0.6), callout_top, Inches(5.95), Inches(1.55),
             BAND_FILL, line_color=RULE)
    add_text(s, Inches(0.80), callout_top + Inches(0.08), Inches(5.55),
             Inches(0.30), "Shared infrastructure (one build, five reuses)",
             size=11, bold=True, color=ACCENT)
    add_text(s, Inches(0.80), callout_top + Inches(0.38), Inches(5.55),
             Inches(1.20),
             "• LLM classifier with per-watcher prompts\n"
             "• PR-draft framework (writes edit, opens PR, applies label)\n"
             "• Domain-owner routing table (signal → owner)\n"
             "• Suppression rules to avoid PR storms on bulk events",
             size=10, color=INK)

    add_rect(s, Inches(6.85), callout_top, Inches(5.95), Inches(1.55),
             HEADER_FILL, line_color=RULE)
    add_text(s, Inches(7.05), callout_top + Inches(0.08), Inches(5.55),
             Inches(0.30), "Build order — easiest signal first",
             size=11, bold=True, color=ACCENT)
    add_text(s, Inches(7.05), callout_top + Inches(0.38), Inches(5.55),
             Inches(1.20),
             "1. MCP correction harvester — logs live, lowest friction, immediate ROI\n"
             "2. UC schema-delta watcher — information_schema diff is a 3-line query\n"
             "3. Confluence / SharePoint watchers — API wiring, same template\n"
             "4. UC lineage-delta watcher — most complex; ship last",
             size=10, color=INK)


def build_slide_smaller_scopes(prs, page, total):
    """Act III — Slide A6. Task families 2, 5, 6: smaller scopes + open
    design decisions."""
    s = add_blank_slide(prs)
    slide_header(s, "Task families 2, 5, 6: smaller scopes + open design decisions",
                 eyebrow="Act III — Action Plan",
                 page_num=page, total=total)

    # Top row: TF2 + TF5 (side by side)
    col_w = Inches(6.05)
    top = Inches(1.35)
    h = Inches(2.45)

    add_rect(s, Inches(0.6), top, col_w, h, BAND_FILL, line_color=RULE)
    add_text(s, Inches(0.80), top + Inches(0.10), col_w - Inches(0.4),
             Inches(0.32), "TASK FAMILY 2",
             size=11, bold=True, color=ACCENT)
    add_text(s, Inches(0.80), top + Inches(0.40), col_w - Inches(0.4),
             Inches(0.40), "Model-Change Watcher",
             size=16, bold=True, color=NAVY)
    add_text(s, Inches(0.80), top + Inches(0.80), col_w - Inches(0.4),
             h - Inches(0.85),
             "One PR. Detects PRs that modify canonical tables (etoro_kpi.*, DDR family, "
             "bi_db_* gold tables) and requires the diff to also touch the matching skill file. "
             "Auto-tags the domain owner if it doesn't.\n\n"
             "Anthropic's number: 90% of model PRs include a skill diff. "
             "Stops silent skill rot the day it ships.",
             size=11, color=INK)

    add_rect(s, Inches(6.85), top, col_w, h, BAND_FILL, line_color=RULE)
    add_text(s, Inches(7.05), top + Inches(0.10), col_w - Inches(0.4),
             Inches(0.32), "TASK FAMILY 5",
             size=11, bold=True, color=ACCENT)
    add_text(s, Inches(7.05), top + Inches(0.40), col_w - Inches(0.4),
             Inches(0.40), "Ablation-grade telemetry",
             size=16, bold=True, color=NAVY)
    add_text(s, Inches(7.05), top + Inches(0.80), col_w - Inches(0.4),
             h - Inches(0.85),
             "Enrich monitoring_mcp_logs_mcp_gateway + Genie sibling table with:\n"
             "  • skill_version_sha · model_id · token_in/out · latency_ms · correction_flag\n"
             "  • metric_flow_id tying eval run, production answer, and correction together.\n\n"
             "Makes \"is the new skill version better?\" a SQL query, not an A/B study.",
             size=11, color=INK)

    # Bottom row: TF6 open decisions table (full width)
    bottom_top = Inches(3.95)
    add_text(s, Inches(0.6), bottom_top, Inches(12), Inches(0.4),
             "Task family 6 — Open design decisions in the roadmap (parked, not stuck)",
             size=13, bold=True, color=NAVY)

    headers = ["Decision", "Recommendation", "Resolution path"]
    col_widths = [Inches(4.0), Inches(5.5), Inches(2.8)]
    top2 = Inches(4.40)
    header_h = Inches(0.36)
    total_w2 = sum(col_widths, Inches(0))

    add_rect(s, Inches(0.6), top2, total_w2, header_h, NAVY)
    x = Inches(0.6)
    for w, h2 in zip(col_widths, headers):
        add_text(s, x + Inches(0.1), top2 + Inches(0.05),
                 w - Inches(0.2), header_h - Inches(0.1), h2,
                 size=11, bold=True, color=WHITE)
        x += w

    rows = [
        ("Unbook auto-fire — promote which minimal subset?",
         "Start with final-answer-assembly (candidate (a)). Promote to metric-definition-check or question-framing only if the eval gate data justifies.",
         "Resolved by Truth Sensor data"),
        ("10-KPI UC-metric-view pilot — declarative semantic layer on top of etoro_kpi?",
         "Pilot 10 KPIs (FTD, MIMO net, AUM, NOP, daily volumes, registration funnel, RAF, options PFOF, fee revenue, refund chain).",
         "H2 planning decision"),
        ("Adversarial review on every answer — does the trade-off math change?",
         "Hold the deliberate non-adoption. Revisit semi-annually.",
         "Model cost / latency curves"),
    ]
    row_top = top2 + header_h
    row_h = Inches(0.78)
    for i, (decision, rec, path) in enumerate(rows):
        fill = BAND_FILL if i % 2 == 0 else WHITE
        add_rect(s, Inches(0.6), row_top, total_w2, row_h, fill, line_color=RULE)
        add_text(s, Inches(0.70), row_top + Inches(0.06),
                 col_widths[0] - Inches(0.10), row_h - Inches(0.12),
                 decision, size=10, bold=True, color=INK,
                 anchor=MSO_ANCHOR.MIDDLE)
        add_text(s, Inches(0.70) + col_widths[0], row_top + Inches(0.06),
                 col_widths[1] - Inches(0.10), row_h - Inches(0.12),
                 rec, size=10, color=INK, anchor=MSO_ANCHOR.MIDDLE)
        add_text(s, Inches(0.70) + col_widths[0] + col_widths[1],
                 row_top + Inches(0.06),
                 col_widths[2] - Inches(0.10), row_h - Inches(0.12),
                 path, size=10, italic=True, color=ACCENT,
                 anchor=MSO_ANCHOR.MIDDLE)
        row_top += row_h


def build_slide_asks_v2(prs, page, total):
    """Act III — Slide A7. Asks of executive (same content as v1, light tweaks)."""
    s = add_blank_slide(prs)
    slide_header(s, "Asks of executive", eyebrow="Act III — Action Plan",
                 page_num=page, total=total)

    # Primary ask — boxed
    add_rect(s, Inches(0.6), Inches(1.3), Inches(12.2), Inches(2.6),
             RED_FILL, line_color=RED_DOT, line_width=Pt(1.5))
    add_text(s, Inches(0.85), Inches(1.4), Inches(11.7), Inches(0.4),
             "PRIMARY ASK", size=11, bold=True, color=RED_DOT)
    add_text(s, Inches(0.85), Inches(1.78), Inches(11.7), Inches(0.5),
             "Assign domain owners and commit them to the eval gate",
             size=18, bold=True, color=NAVY)
    add_text(s, Inches(0.85), Inches(2.35), Inches(11.7), Inches(0.4),
             "The machine has one human-in-the-loop role that cannot be automated: the domain owner who "
             "adjudicates ground truth for their slice. Per Anthropic — non-negotiable.",
             size=11, italic=True, color=INK)
    add_rich(s, Inches(0.85), Inches(2.85), Inches(11.7), Inches(1.0), [
        {"runs": [
            {"text": "• Internal teams ", "size": 11, "bold": True, "color": INK},
            {"text": "(Data Analytics, Product Analytics — inside our org): ",
             "size": 11, "color": INK},
            {"text": "can be mandated. ", "size": 11, "bold": True, "color": RED_DOT},
            {"text": "Domain ownership assigned; team signs off on the eval slice.",
             "size": 11, "color": INK},
        ]},
        {"runs": [
            {"text": "• Cross-functional business domains ",
             "size": 11, "bold": True, "color": INK},
            {"text": "(Marketing, Trading Ops, Payments, US Ops, Compliance…): ",
             "size": 11, "color": INK},
            {"text": "needs leadership-level comms. ",
             "size": 11, "bold": True, "color": RED_DOT},
            {"text": "Message: \"the agent will give your users wrong answers unless your team owns the eval slice. "
             "We build the substrate; you adjudicate ground truth.\" Without this we stall at ~75%.",
             "size": 11, "color": INK},
        ], "space_before": 4},
    ])

    add_text(s, Inches(0.6), Inches(4.10), Inches(12), Inches(0.4),
             "And three smaller asks", size=13, bold=True, color=NAVY)
    other_asks = [
        ("2.", "Greenlight the machine's first watchers",
         "Skill-touch CI hook on DataPlatform (one PR, no product impact) + MCP correction harvester "
         "(scheduled job on logs that already exist — ready to start now)."),
        ("3.", "Commit a baseline accuracy number for H2",
         "Suggested floor: 75% on top 4 domains by Q3, 90% by Q4. The machine without a target is just plumbing."),
        ("4.", "Decision on the 10-KPI UC-metric-view pilot",
         "Yes / no on a thin semantic-layer pilot in H2. We have the canonical views; this is the declarative wrapper."),
    ]
    y = Inches(4.55)
    for n, lead, body in other_asks:
        add_text(s, Inches(0.7), y, Inches(0.5), Inches(0.4), n,
                 size=15, bold=True, color=ACCENT)
        add_text(s, Inches(1.2), y, Inches(11.5), Inches(0.35), lead,
                 size=12, bold=True, color=NAVY)
        add_text(s, Inches(1.2), y + Inches(0.32), Inches(11.5),
                 Inches(0.5), body, size=11, color=INK)
        y += Inches(0.78)


def build_slide_summary_v2(prs, page, total):
    """Three-act summary."""
    s = add_blank_slide(prs)
    slide_header(s, "One-page summary",
                 eyebrow="Take this back to the room",
                 page_num=page, total=total)

    acts = [
        ("ACT I — Research",
         "Self-service analytics accuracy is a context + verification problem, not a code-generation problem. "
         "Three failure modes (ambiguity, staleness, retrieval) and a four-layer stack that attacks them. "
         "Methodology: pinned evals, provenance footer, active correction harvesting, 90% per-domain gate, "
         "skill-touch CI hook. One heavy trade-off they quantified: adversarial review on every answer costs "
         "+32% tokens / +72% latency for +6% accuracy."),
        ("ACT II — Comparison",
         "We've already built most of it. Score: 5 green / 6 in-motion / 4 roadmap. Two strategic assets most "
         "teams don't have: /feedback Databricks app (turns Anthropic's hardest problem — building evals — into "
         "our easiest) + the three-skill analysis triple (substance of an unbook, decomposed better than theirs). "
         "One deliberate non-adoption: mandatory adversarial review on every answer — economics don't pencil."),
        ("ACT III — Action Plan",
         "Build the machine. Six task families: (1) Truth Sensor — eval substrate from /feedback. "
         "(2) Model-Change Watcher — skill-touch CI hook. (3) Output Contract — provenance footer enforced. "
         "(4) MULTI-SOURCE WATCHER FLEET — MCP corrections + Confluence + SharePoint + UC schema + UC lineage → draft PRs. "
         "(5) Ablation-grade telemetry. (6) Open design decisions (unbook auto-fire / 10-KPI pilot / adversarial-review revisit)."),
    ]

    y = Inches(1.25)
    band_colors = [
        (RGBColor(0xE3, 0xEE, 0xF7), ACCENT),
        (RGBColor(0xE8, 0xF5, 0xE9), GREEN_DOT),
        (RGBColor(0xFF, 0xF8, 0xE1), RGBColor(0x8B, 0x5A, 0x00)),
    ]
    for (h, body), (fill, accent_col) in zip(acts, band_colors):
        add_rect(s, Inches(0.6), y, Inches(12.2), Inches(1.40), fill,
                 line_color=RULE)
        add_text(s, Inches(0.85), y + Inches(0.10), Inches(11.7),
                 Inches(0.32), h, size=13, bold=True, color=accent_col)
        add_text(s, Inches(0.85), y + Inches(0.45), Inches(11.7),
                 Inches(0.90), body, size=11, color=INK)
        y += Inches(1.50)

    # Money line
    money_top = y + Inches(0.05)
    add_rect(s, Inches(0.6), money_top, Inches(12.2), Inches(0.85), NAVY)
    add_text(s, Inches(0.85), money_top + Inches(0.08), Inches(11.7),
             Inches(0.30),
             "Everything in this roadmap is something we plan to do. "
             "The only item we chose not to do is adversarial review on every answer — "
             "and that's revisited semi-annually.",
             size=10, italic=True, color=RGBColor(0xB7, 0xCF, 0xE6))
    add_text(s, Inches(0.85), money_top + Inches(0.42), Inches(11.7),
             Inches(0.40),
             "\"We're not asking for budget to write more skills. "
             "We're asking for the green light to build the system that writes them — "
             "and the domain owners to staff its accuracy gate.\"",
             size=13, bold=True, italic=True, color=WHITE,
             anchor=MSO_ANCHOR.MIDDLE)


def build_slide_appendix_v2(prs, page, total):
    s = add_blank_slide(prs)
    slide_header(s, "Appendix — sources & artefacts",
                 eyebrow="Backup",
                 page_num=page, total=total)
    sources = [
        ("Article (source of comparison)",
         "How Anthropic enables self-service data analytics with Claude — claude.com/blog, 2026-06-03"),
        ("v1 deck (pre-restructure)",
         "proposals/exec-deck-anthropic-self-service-analytics-2026-06-04.md + .pptx"),
        ("Internal briefs",
         "proposals/skill-curation-from-nl-and-queries-2026-05-31.md · proposals/skills-mcp-protocol-parity-implementation-2026-06-03.md · dab/monitoring-genie-logs/"),
        ("Skill corpus (knowledge router)",
         "databricks/data-skills/skills/domain-*/ on DataPlatform (CI-deployed)"),
        ("Skill corpus (unbook triple)",
         "/.assistant/skills/data-analysis-playbook · /.assistant/skills/data-analysis-patterns · /.assistant/skills/data-analysis-pattern-library on Databricks Assistant"),
        ("Workspace assistant defaults",
         "/.assistant_workspace_instructions.md at Databricks workspace root"),
        ("Telemetry tables",
         "main.config.monitoring_mcp_logs_mcp_gateway · main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway · main.monitoring.genie_audit_events · main.de_output.de_output_genie_code_skill_feedback"),
        ("Feedback skill (DA-80 PR)",
         "knowledge/skills/feedback-command/SKILL.md"),
    ]
    y = Inches(1.4)
    for h, body in sources:
        add_text(s, Inches(0.6), y, Inches(3.6), Inches(0.4), h, size=11,
                 bold=True, color=NAVY)
        add_text(s, Inches(4.3), y, Inches(8.5), Inches(0.65), body, size=11,
                 color=INK)
        y += Inches(0.55)


# ─────────────────────────── main ───────────────────────────

def main():
    prs = Presentation()
    prs.slide_width = SLIDE_W
    prs.slide_height = SLIDE_H

    # Three-act structure
    builders = [
        build_slide_cover_v2,                  # 1  Cover
        build_slide_act1_divider,              # 2  ACT I divider
        build_slide_3_framework,               # 3  R1 — Framework (reused)
        build_slide_research_methodology,      # 4  R2 — Methodology + trade-off
        build_slide_act2_divider,              # 5  ACT II divider
        build_slide_scorecard_v2,              # 6  C1 — Scorecard (reframed)
        build_slide_strengths_v2,              # 7  C2 — Strengths
        build_slide_deliberate_non_adoption,   # 8  C3 — Deliberate non-adoption (reused)
        build_slide_act3_divider,              # 9  ACT III divider
        build_slide_machine,                   # 10 A1 — The machine vision (reused)
        build_slide_roadmap_overview,          # 11 A2 — Roadmap task families
        build_slide_truth_sensor,              # 12 A3 — Task family 1 detail
        build_slide_output_contract,           # 13 A4 — Task family 3 detail
        build_slide_watcher_fleet,             # 14 A5 — Task family 4 detail
        build_slide_smaller_scopes,            # 15 A6 — Task families 2/5/6
        build_slide_asks_v2,                   # 16 A7 — Asks of executive
        build_slide_summary_v2,                # 17 Summary
        build_slide_appendix_v2,               # 18 Appendix
    ]
    total = len(builders)
    for i, build in enumerate(builders, start=1):
        if i == 1:
            build(prs, total)
        else:
            build(prs, i, total)

    out = Path(__file__).parent / "exec-deck-anthropic-self-service-analytics-v2-2026-06-08.pptx"
    try:
        prs.save(out)
    except PermissionError:
        out = out.with_name(out.stem + "_alt" + out.suffix)
        prs.save(out)
    print(f"Wrote {out} ({out.stat().st_size:,} bytes, {total} slides)")


if __name__ == "__main__":
    main()
