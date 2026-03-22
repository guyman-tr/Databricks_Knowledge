# Lineage Map — Dealing_dbo.Dealing_Supposed_LPFees

**Generated**: 2026-03-21
**Writer SP**: None found in SSDT repository
**Pattern**: Unknown — no active ETL code found

## ETL Chain

```
Source unknown — no writer SP found in Dealing_dbo SSDT Stored Procedures
  └── Dealing_dbo.Dealing_Supposed_LPFees
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | Unknown | — | Report date |
| DateID | Unknown | — | Integer date key |
| InstrumentID | Unknown | — | Instrument identifier |
| InstrumentDisplayName | Unknown | — | Instrument name |
| ISINCode | Unknown | — | International Securities Identification Number |
| Currency | Unknown | — | Instrument base currency |
| Units | Unknown | — | Position size in units |
| LocalAmount | Unknown | — | Value in local currency |
| Fee | Unknown | — | Calculated LP fee in local currency |
| LP | Unknown | — | Liquidity provider identifier (e.g., 'IB', 'GS', 'JP') |
| HS | Unknown | — | HedgeServerID — which LP server |
| FeeUSD | Unknown | — | Fee converted to USD |
| TotalCommission | Unknown | — | Total commission charged |
| UpdateDate | Unknown | — | ETL timestamp |

## Governance

- **No writer SP in SSDT**: Pipeline no longer active
- **STALE since 2023-09-11**: Last data from September 2023 — ~30 months stale
- **REPLICATE distribution**: Suggests small reference table expected; 603K rows is larger than typical REPLICATE use case
- **Purpose inference**: Theoretical ("supposed") LP fees for reconciliation or validation against actual LP invoices
