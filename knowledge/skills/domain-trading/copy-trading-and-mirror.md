---
name: domain-trading
description: "Copy trading mechanics — the mirror relationships, mirror types (manual copy vs Smart Portfolio vs other variants), Popular Investor (PI) economics, copy chain semantics, and the way MirrorID and MirrorTypeID change over a position's lifetime. PLACEHOLDER content — final analytical methodology (PI compensation calc, copy-fund attribution, copier-leader interactions) lands when the dealing-analyst skill set is delivered. Until then, this skill teaches the at-event-time vs current-state rule for MirrorID (fact > dim) and routes deeper questions to the relevant production view family."
triggers:
  - copy trade
  - copy trading
  - mirror
  - mirror relationship
  - MirrorID
  - MirrorTypeID
  - Dim_Mirror
  - Smart Portfolio
  - copy fund
  - CopyFund
  - Popular Investor
  - PI program
  - PI compensation
  - copy chain
  - copier
  - leader
  - copyback
  - stop copy
  - copy to portfolio
required_tables:
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Copy Trading & Mirror Relationships (Placeholder)

eToro's signature differentiator is **social trading**: a customer can copy another trader (a "leader" / Popular Investor) and have positions automatically opened in their account proportional to the leader's. The relationship is mediated by **mirrors** — `Dim_Mirror` is the master registry of every copy / Smart Portfolio relationship, and every position in `Dim_Position` / `fact_customeraction_w_metrics` carries a `MirrorID` and `MirrorTypeID`.

This sub-skill is currently a **placeholder** — full analytical methodology (PI compensation, copy-fund attribution, copier-leader interaction analytics, churn from copy relationships, Smart Portfolio rebalance flow) will be delivered by the dealing-analyst skill set. What this skill DOES own today is the fact-vs-dim rule applied to mirror semantics and the routing into the right production view.

## When to Use

Load when the question is about:

- "How many positions were opened as copies?" — answer comes from the fact (see `position-state-and-grain.md`)
- "Smart Portfolio AUM", "copy-fund equity" — answer comes from the AUM fact (see `portfolio-value-aum-pnl.md`)
- "Popular Investor (PI) commission" — economics lives downstream in `domain-revenue-and-fees`; the customer-identity attribute lives in `domain-customer-and-identity`
- "Who is the leader for position X?", "what mirror was this opened under?"
- "Mirror types" — what does `MirrorTypeID = 4` mean (Smart Portfolio)?

Do **not** load for (today):

- PI compensation calculation — pending dealing-analyst skill
- Copy-fund attribution analytics — pending dealing-analyst skill
- Copier-leader interaction patterns — pending dealing-analyst skill
- Smart Portfolio rebalance forensics — pending dealing-analyst skill

## Scope

In scope: the `Dim_Mirror` master registry, `MirrorTypeID` known values (4 = Smart Portfolio / Copy Fund; other values = manual copy variations), the fact-vs-dim rule applied to `MirrorID` (Critical Warning #1 in [`position-state-and-grain.md`](position-state-and-grain.md)), the `IsCopy` / `IsCopyFund` flag derivation, copy-trade volume aggregates (covered in `trading-volumes.md`), copy-equity snapshot (covered in `portfolio-value-aum-pnl.md`), routing into PI customer-attribute lookup (`domain-customer-and-identity`), routing into PI revenue/compensation (`domain-revenue-and-fees`).
Out of scope: PI compensation calculation, copy-fund attribution analytics, copier-leader interaction analytics, Smart Portfolio rebalance flow forensics — ALL pending the dealing-analyst skill set.
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — Apply the fact-vs-dim rule from `position-state-and-grain.md` rigorously here.** A position's `MirrorID` on the dim is *current state* (overwritten on update). To ask "was this position OPENED as a copy?", filter `fact_customeraction_w_metrics` to the opening `ActionTypeID` (1, 2, 3, or 39) and read `MirrorID` from that event. A common bug: query `Dim_Position WHERE MirrorID > 0` to count "copy positions" — that **misses every position that has since been detached from its mirror** (Smart Portfolio stopped, customer kept the position). The fact preserves the open-time value.
2. **Tier 1 — `MirrorTypeID = 4` is Smart Portfolio (Copy Fund); other positive values are manual copy variations.** The Smart Portfolio (managed-product) flow is materially different from manual copy in compensation and economics. When the question is about "copy" generically, confirm whether the user means manual copy (MirrorTypeID ≠ 4) or Smart Portfolio (MirrorTypeID = 4) or both.
3. **Tier 2 — Popular Investor (PI) status is a CUSTOMER attribute, owned by `domain-customer-and-identity`.** A leader's PI status (eligible, suspended, tier) lives on `Dim_Customer` and is current-state. For point-in-time PI status, walk `Fact_SnapshotCustomer` via the customer-and-identity hub. PI compensation amounts are revenue (paid TO the PI from copier fees) and live in `domain-revenue-and-fees`.
4. **Tier 3 — `IsC2P` (Copy-to-Portfolio) flag** in the volumes fact identifies positions that were originally copies but the customer kept after stopping the copy relationship. These are no longer auto-managed but the open-time event will still show the original `MirrorID`. The flag is the cleanest way to separate "active copies" from "former copies still open in the portfolio".

## Tables (placeholder coverage)

| Table | Use For |
|---|---|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | Mirror master registry — registry of every copy / Smart Portfolio relationship ever created. |
| `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | Per-event MirrorID (at open / at modify / at close). The authoritative source for at-event-time copy detection. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` | Current MirrorID — useful for "is this position CURRENTLY linked to a mirror?", NOT for "was it ever a copy?" |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | Aggregated copy / Smart Portfolio volumes via `IsCopy` / `IsCopyFund` flags. |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | Aggregated copy equity via `EquityCopy` snapshot. |

---

## Query Patterns (placeholder)

### Pattern 1 — Was position X opened as a copy? (the fact-vs-dim correct way)
See [`position-state-and-grain.md`](position-state-and-grain.md) Pattern 7 — the canonical answer.

### Pattern 2 — Smart Portfolio vs manual-copy volume split
```sql
SELECT IsCopyFund,
       SUM(TotalVolume) AS volume,
       SUM(CountTotalTransactions) AS trades
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
WHERE IsCopy = 1
  AND etr_ymd BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY IsCopyFund;
```
**Use when:** "Smart Portfolio vs manual-copy volume", "managed-product trading share"

### Pattern 3 — Copy equity share
```sql
SELECT DateID,
       SUM(EquityCopy) AS copy_equity,
       SUM(TotalEquityTP) AS total_equity,
       SUM(EquityCopy) * 1.0 / SUM(TotalEquityTP) AS copy_share
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID BETWEEN 20260101 AND 20260131
GROUP BY DateID
ORDER BY DateID;
```
**Use when:** "what's the copy-equity share of total AUM?"

### Pattern 4 — Mirror registry lookup
```sql
SELECT MirrorID, MirrorTypeID, OwnerCID, MirrorName, IsActive
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
WHERE OwnerCID = 12345;
```
**Use when:** "what mirrors does leader X have?", master-registry lookup. Column names approximate — verify against current schema.

---

## Cross-references

- The at-event-time copy-detection rule (the canonical fact-vs-dim case) → [`position-state-and-grain.md`](position-state-and-grain.md)
- Copy/Smart Portfolio volume aggregates → [`trading-volumes.md`](trading-volumes.md)
- Copy equity snapshot → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- PI customer attribute (current + point-in-time) → [`../domain-customer-and-identity/SKILL.md`](../domain-customer-and-identity/SKILL.md)
- PI compensation / commission revenue → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)

## Provenance

Placeholder skill authored 2026-05-11 to encode the fact-vs-dim mirror rule and route into the broader domain-trading and cross-domain references. Deeper methodology — PI compensation, copy-fund attribution, copier-leader interactions, Smart Portfolio rebalancing — pending the dealing-analyst skill set commissioned by the data team. When that skill lands, this placeholder will be expanded into authoritative content.
