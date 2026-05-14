# Review Sidecar — `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions`

_Encoding: UTF-8 · Generated: 2026-05-14_

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier | Change Summary |
|--------|-------------------|--------------|----------|----------------|
| IsSQF | SpotQuotedFuture flag (smaller-contract RealFutures on CME); `GroupID=59` in `Trade.InstrumentGroups` | Tier 2 — "Sustainable & Quality-Focused instrument flag" | Tier 5 (user expert correction 2026-05-14) | Replaced fabricated business narrative with grounded product semantic (SpotQuotedFuture). |

## Tier 4 — Open Questions for Reviewers

1. **NULL `ActionTypeID` bucket (~2.17M rows on `DateID≥20260101`)** — confirm whether historic loads predating `ISNULL(...,-1)` coercion or a legitimate third sentinel; align cleansing if accidental.
2. **`InstrumentTypeID = 0` slice (~50k rows recent window)** — validate against `Dim_Instrument` hygiene (unexpected asset class zero).
3. **Admin fee branch `IsLeverage` alias** — cosmetic typo vs TVF contract; confirm no consumer depends on column naming inside TVFs.
4. **Options reload window** — `Function_Revenue_OptionsPlatform` spans `20000101` through current — document SLA impact on partition scans when joining without `Metric`/`RevenueMetricID` filters.
5. **`IsSettled` remains Tier 5 Expert Review upstream** (`Fact_CustomerAction`) — escalate if instrument classification policy changes broadly.

## Soft-Fail Tracking (Pipeline)

| Item | Severity | Detail |
|------|----------|--------|
| Phase 10 Atlassian | SOFT skip | MCP search not executed — section 8 states gap explicitly. |
| OpsDB SLA proof | SOFT | Mentioned orchestration verbally; OpsDB MCP not queried here for exact `Priority`/`SB_*` timings. |

## Checker Notes

- **Parity gate:** Wiki element rows = Synapse DDL columns (27 vs 27) — ✅ this session (`INFORMATION_SCHEMA` vs `.lineage.md` summary).
