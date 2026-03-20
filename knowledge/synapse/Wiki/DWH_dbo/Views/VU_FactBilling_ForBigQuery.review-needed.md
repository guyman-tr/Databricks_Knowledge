# Review Sidecar — DWH_dbo.VU_FactBilling_ForBigQuery

## Confidence Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 2 | ~125 | All columns — from view DDL, most wrapped in RemoveSpecialChars |

## Unverified Claims

| # | Claim | Source | Confidence |
|---|-------|--------|------------|
| 1 | RemoveSpecialChars strips export-breaking characters | Function name inference — not inspected | Medium |
| 2 | Column `v` is a legitimate billing detail field | View DDL — single-letter name is suspicious | Low |
| 3 | View targets Google BigQuery specifically | View name suffix "ForBigQuery" | High |

## Reviewer Corrections

*(None yet — pending reviewer pass)*

## Quality Breakdown

| Dimension | Score | Notes |
|-----------|-------|-------|
| **Overall** | **7.5/10** | Large export view — individual column docs inherited from base table |
