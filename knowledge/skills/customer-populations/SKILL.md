---
name: customer-populations
description: "TOMBSTONE — superseded on 2026-05-28 / DA-72. This skill's content was absorbed into the Customer & Identity super-domain at sub-skill domain-customer-and-identity/customer-populations-and-lifecycle.md. Population segments (Funded / Active Trader / Portfolio Only / Balance Only), the FTF formula, the SCD population fact (gold_de_user_dim_ddr_customer_dailystatus_scd), the 12 Active Trader sub-flags, and lifecycle milestones now all live in the hub sub-skill — load the hub for any 'how many funded customers?' / 'active traders today?' / 'FTF cohort' / population-breakdown question. This redirect-only file remains for ~30 days to allow the MCP embedding corpus to re-train against the new fingerprint; after that, the folder is hard-deleted."
triggers:
  - funded customers
  - active trader
  - portfolio only
  - balance only
  - population count
  - customer segment
  - first time funded
  - FTF
  - customer lifecycle
  - milestone dates
  - how many funded
required_tables:
  - main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
version: 3
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# customer-populations (TOMBSTONE — superseded)

> **TOMBSTONE — superseded.** Absorbed 2026-05-28 / DA-72 into the Customer & Identity super-domain. Load `domain-customer-and-identity/customer-populations-and-lifecycle.md` (or the hub `domain-customer-and-identity/SKILL.md` and let the routing waypoint take you there). This file is a redirect-only stub kept for ~30 days while the MCP embedding corpus re-trains; after that, the folder is hard-deleted.

## When to Use

**Do not load this skill directly.** It is a tombstone. The loader keeps it temporarily to preserve any embedding similarity that previously routed here, then transparently hand off to the new home.

If the MCP did route here for a query about Funded / Active Trader / Portfolio Only / Balance Only segments, FTF cohorts, lifecycle milestones, or first-trading-action classification — load `domain-customer-and-identity/customer-populations-and-lifecycle.md` instead. It is a faithful absorption: same 8 anchor tables (SCD population fact, periodic-status pre-aggregate, daily-status fact, daily snapshot, milestone first-dates fact, three `v_population_*` builders), same canonical formulas (IsFunded 3-leg equity check, First Time Funded `GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID))`, 12 Active Trader sub-flags), same Tier-ordered warnings (the daily-status fact is multi-billion rows and slow, `FirstDepositDate` carries the `1900-01-01` sentinel, etc.).

## Scope

In scope: redirect-only. The full live scope lives at the new home.
Out of scope: everything substantive — load `domain-customer-and-identity/customer-populations-and-lifecycle.md`.
Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 — Do not write SQL against this skill's content.** It has none. The body above is a redirect. If you find yourself reading SQL from this file, stop and load the new home: `domain-customer-and-identity/customer-populations-and-lifecycle.md`.
2. **Tier 2 — Do not re-derive content here.** Any net-new population segment / lifecycle knowledge must land in `domain-customer-and-identity/customer-populations-and-lifecycle.md`, not in this tombstone. This file is frozen.
3. **Tier 3 — Hard-delete is scheduled.** This folder is slated for `git rm -rf` ~30 days after 2026-05-28 (~2026-06-27) once the MCP embedding corpus has re-trained against the new sub-skill's description and triggers. Track the deletion via DA-72 follow-up.

## Skill provenance

Absorbed 2026-05-28 from this workspace skill (v2, owner dataplatform) into the Customer & Identity super-domain sub-skill `customer-populations-and-lifecycle.md`. Reason: the legacy `customer-populations` skill was always conceptually a sub-slice of the Customer & Identity super-domain (the hub even referenced it as "authoritative" in its Routing waypoint). Co-locating it as a sibling `.md` inside the hub folder removes the inter-skill hop, lets the hub own its full domain, and matches the convention DE applied to `instruments` (absorbed into `domain-trading/instruments-and-asset-classes.md`) and the post-DD-1747 sub-skill structure. Hard-delete deferred ~30 days for embedding re-train.
