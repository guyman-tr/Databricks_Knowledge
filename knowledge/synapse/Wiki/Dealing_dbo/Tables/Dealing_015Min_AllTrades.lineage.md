---
object: Dealing_015Min_AllTrades
schema: Dealing_dbo
lineage_type: stale-unknown-writer
generated: 2026-03-21
---

# Lineage — Dealing_015Min_AllTrades

## Pipeline Status

**STALE** — No active writer SP found. Last data 2024-04-02.

## ETL Chain

```
[Unknown LP/exchange feed]
    → [Unknown writer SP or external loader]
        → Dealing_015Min_AllTrades   (STALE Apr 2024)
```

## Production Source

| Attribute | Value |
|-----------|-------|
| Generic Pipeline mapping | Not found |
| Source system | External LP / exchange (inferred from exchange, source_name columns) |
| Upstream wiki | None |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | External feed | trade date | passthrough |
| Last15Min | External feed | window boundary | ETL-computed (15-min truncation) |
| id | External feed | trade id | passthrough |
| execution_time | External feed | execution timestamp | passthrough |
| Instrument_Name | External feed | symbol/instrument | passthrough |
| Side | External feed | side | passthrough |
| price | External feed | price | passthrough |
| quantity | External feed | quantity | passthrough |
| Funds | External feed | notional / funds | passthrough |
| Fee | External feed | fee | passthrough |
| exchange | External feed | exchange | passthrough |
| source_name | External feed | source | passthrough |
| order_id | External feed | order id | passthrough |
| UpdateDate | ETL | GETDATE() | ETL metadata |

## Notes

- No writer SP found in SSDT Dealing_dbo stored procedures
- May have been loaded via an external SSIS/ADF pipeline not tracked in the SSDT repo
