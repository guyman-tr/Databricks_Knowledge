---
object: Dealing_EquityFees
schema: Dealing_dbo
type: Table
description: Daily instrument-level equity financing cost comparison across two prime brokers (JP Morgan, Goldman Sachs) vs eToro CBH-hedged client NOP. Enables three-way reconciliation of LP positions and financing charges. Note: "Fianancing" typo in 4 column names is intentional — preserved from LP report column naming.
etl_sp: Dealing_dbo.SP_EquityFees
frequency: Daily
status: Active (last: 2026-03-09)
row_count: 3,835,427
distribution: ROUND_ROBIN
index: CLUSTERED (DateID ASC)
batch: 14
quality: 8.0
---

# Dealing_EquityFees

Daily three-way instrument-level comparison table joining **JP Morgan** and **Goldman Sachs** LP position/financing reports against **eToro's CBH-hedged client NOP**. Enables the Dealing team to reconcile LP financing charges against client positions and monitor equity financing economics across both prime brokers.

> **Column naming note**: Four columns contain the typo `"Fianancing"` (JP_LongFianancingCost, JP_ShortFianancingCost, GS_Long_Fianancing_Fee, GS_Short_Fianancing_Fee). This is **intentional** — the typo is inherited directly from the LP report column naming and is preserved in the DDL to match source. Do not correct.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| JP Morgan positions | `Dealing_staging.LP_JPM_EOD_eToro_Report_ComponentUnderlyings` | JP EOD positions, prices, financing costs, market values |
| JP Morgan rates | `Dealing_staging.LP_JPM_ETORO_AVAILABILITY` | AllInRate, Requested, Approved, ShortFee, Rate_Desc |
| Goldman Sachs | `Dealing_staging.LP_GS_SRPB_PositionValuationSummary` | GS positions, values, financing fees |
| Client NOP | `BI_DB_dbo.BI_DB_PositionPnL` | eToro CBH-hedged client NOP/units (HedgeServerID IN (2,101)) |
| Instrument dim | `DWH_dbo.Dim_Instrument` | InstrumentID resolution from ISIN/SEDOL |
| Writer | `Dealing_dbo.SP_EquityFees` | Daily, OpsDB Priority 0 |

**Author**: Graham Ellinson (2022-04-14).

## 1. Business Purpose

- Reconcile what JP Morgan and Goldman Sachs report holding vs what eToro's clients actually have
- Identify financing cost discrepancies between LP charges and expected costs
- JP-side: `JP_LongFianancingCost` / `JP_ShortFianancingCost` from LP report
- GS-side: `GS_Long_Fianancing_Fee` / `GS_Short_Fianancing_Fee` from GS report
- Client NOP (HedgeServerID IN (2,101)) = CBH-hedged clients only — not all eToro clients
- JOIN uses ISIN + Currency dedup to handle multi-listed stocks

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| CBH hedging | HedgeServerID IN (2,101) — clients hedged via CBH (not all hedge servers) |
| "Fianancing" typo | Intentional: inherited from LP column names; preserved in DDL and queries |
| ISIN dedup | When the same ISIN appears for multiple currencies in LP report, SP takes one per currency to avoid doubles |
| Three-way join | FULL JOIN JP × GS × Client — NULLs on any side are expected and meaningful |
| NULL InstrumentID | Some rows have NULL InstrumentID when ISIN/SEDOL not found in Dim_Instrument |

## 3. Grain

One row per **DateID × InstrumentID** (or ISINCode when InstrumentID not resolved). JP and GS sides may independently have positions not on the other side.

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| Date | date | Report date | Tier 2 | SP parameter |
| DateID | int | YYYYMMDD date integer | Tier 2 | Clustered index key |
| InstrumentID | int | Instrument ID (resolved from ISIN/SEDOL) | Tier 1 | NULL when ISIN/SEDOL not in Dim_Instrument |
| InstrumentDisplayName | varchar(max) | Instrument display name | Tier 2 | From Dim_Instrument |
| ISINCode | varchar(25) | International Securities Identification Number | Tier 2 | From LP_JPM_EOD_Report |
| RICCode | varchar(25) | Reuters Instrument Code | Tier 2 | From LP_JPM_EOD_Report |
| SedolCode | varchar(max) | SEDOL code | Tier 2 | From LP_JPM_EOD_Report |
| Currency | varchar(25) | Instrument local currency | Tier 2 | From LP_JPM_EOD_Report |
| JP_LongQuantity | int | JP Morgan long position units | Tier 2 | From LP_JPM_EOD_Report |
| JP_ShortQuantity | int | JP Morgan short position units | Tier 2 | From LP_JPM_EOD_Report |
| JP_CurrentPrice | float | JP Morgan EOD price | Tier 2 | From LP_JPM_EOD_Report |
| JP_LongFianancingCost | float | JP Morgan long financing cost (typo intentional) | Tier 1 | From LP_JPM_EOD_Report |
| JP_ShortFianancingCost | float | JP Morgan short financing cost (typo intentional) | Tier 1 | From LP_JPM_EOD_Report |
| JP_FinancingAllInRate | float | JP Morgan all-in financing rate | Tier 2 | From LP_JPM_ETORO_AVAILABILITY.AllInRate |
| JP_LongMarketValue_Local | float | JP Morgan long market value in local currency | Tier 2 | From LP_JPM_EOD_Report |
| JP_ShortMarketValue_Local | float | JP Morgan short market value in local currency | Tier 2 | From LP_JPM_EOD_Report |
| JP_LongMarketValue_USD | float | JP Morgan long market value in USD | Tier 2 | From LP_JPM_EOD_Report |
| JP_ShortMarketValue_USD | float | JP Morgan short market value in USD | Tier 2 | From LP_JPM_EOD_Report |
| JP_FX | float | FX rate used by JP Morgan for USD conversion | Tier 2 | From LP_JPM_EOD_Report |
| JP_Requested | float | JP Morgan requested quantity | Tier 2 | From LP_JPM_ETORO_AVAILABILITY |
| JP_Approved | float | JP Morgan approved quantity | Tier 2 | From LP_JPM_ETORO_AVAILABILITY |
| JP_ShortFee | float | JP Morgan short fee rate | Tier 2 | From LP_JPM_ETORO_AVAILABILITY |
| JP_Rate_Desc | varchar(max) | JP Morgan rate description | Tier 2 | From LP_JPM_ETORO_AVAILABILITY |
| GS_Long_Quantity | float | Goldman Sachs long position quantity | Tier 2 | From LP_GS_SRPB_PositionValuationSummary |
| GS_Short_Quantity | float | Goldman Sachs short position quantity | Tier 2 | From LP_GS_SRPB |
| GS_Long_Value_Local | float | Goldman Sachs long value in local currency | Tier 2 | From LP_GS_SRPB |
| GS_Short_Value_Local | float | Goldman Sachs short value in local currency | Tier 2 | From LP_GS_SRPB |
| GS_Long_Value_USD | float | Goldman Sachs long value in USD | Tier 2 | From LP_GS_SRPB |
| GS_Short_Value_USD | float | Goldman Sachs short value in USD | Tier 2 | From LP_GS_SRPB |
| GS_Price | float | Goldman Sachs EOD price | Tier 2 | From LP_GS_SRPB |
| GS_FX | float | FX rate used by Goldman Sachs | Tier 2 | From LP_GS_SRPB |
| GS_Long_Fianancing_Fee | float | Goldman Sachs long financing fee (typo intentional) | Tier 1 | From LP_GS_SRPB |
| GS_Short_Fianancing_Fee | float | Goldman Sachs short financing fee (typo intentional) | Tier 1 | From LP_GS_SRPB |
| LongClients_NOP | float | eToro client long net open position (CBH-hedged) | Tier 1 | From BI_DB_PositionPnL, HedgeServerID IN (2,101) |
| ShortClients_NOP | float | eToro client short net open position (CBH-hedged) | Tier 1 | From BI_DB_PositionPnL, HedgeServerID IN (2,101) |
| LongClients_Units | float | eToro client long position units (CBH-hedged) | Tier 1 | From BI_DB_PositionPnL |
| ShortClients_Units | float | eToro client short position units (CBH-hedged) | Tier 1 | From BI_DB_PositionPnL |
| UpdateDate | datetime | ETL metadata: row write timestamp | Tier 1 | ETL metadata (blacklist canonical) |

## 5. Common Query Patterns

```sql
-- Financing cost comparison for a specific instrument
SELECT Date, InstrumentDisplayName,
       JP_LongFianancingCost, JP_ShortFianancingCost,
       GS_Long_Fianancing_Fee, GS_Short_Fianancing_Fee,
       LongClients_Units, ShortClients_Units
FROM Dealing_dbo.Dealing_EquityFees
WHERE Date = '2026-03-09' AND InstrumentID = 1234
ORDER BY Date;

-- Daily total financing by LP
SELECT Date,
       SUM(JP_LongFianancingCost + JP_ShortFianancingCost) AS JP_TotalFinancing,
       SUM(GS_Long_Fianancing_Fee + GS_Short_Fianancing_Fee) AS GS_TotalFinancing
FROM Dealing_dbo.Dealing_EquityFees
WHERE Date >= DATEADD(DAY, -30, GETDATE())
  AND InstrumentID IS NOT NULL
GROUP BY Date
ORDER BY Date DESC;
```

> **Performance note**: 3.8M rows, ROUND_ROBIN/CI(DateID). Filter by Date or DateID. InstrumentID may be NULL for unresolved instruments — always check IS NOT NULL for clean analysis.

## 6. Data Quality & Caveats

- **NULL InstrumentID**: Some rows (including recent 2026-03-09 rows) have NULL InstrumentID when ISIN/SEDOL not matched in Dim_Instrument
- **"Fianancing" typo**: Intentional — preserved from LP column names. Do not correct in queries.
- **CBH filter**: Client NOP only covers HedgeServerID IN (2,101) — other hedge-server clients are excluded
- **JP vs GS coverage**: Instruments may appear in one LP report but not the other — NULLs on either side are expected
- **ISIN dedup**: Same ISIN for multiple currencies deduped by SP — currency-specific positions may be aggregated

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_staging.LP_JPM_EOD_eToro_Report_ComponentUnderlyings` | JP Morgan LP EOD feed |
| `Dealing_staging.LP_JPM_ETORO_AVAILABILITY` | JP Morgan availability/rates feed |
| `Dealing_staging.LP_GS_SRPB_PositionValuationSummary` | Goldman Sachs LP feed |
| `BI_DB_dbo.BI_DB_PositionPnL` | Source for client NOP/units |

## 8. Operational Notes

- **ETL**: `SP_EquityFees` runs daily (OpsDB Priority 0). DELETE + INSERT for @DateID
- **Author**: Graham Ellinson (2022-04-14)
- **LP data dependency**: Table populated from LP staging files; late LP file drops will delay or skip the day

---
*Quality score: 8.0/10 — Clear three-way LP vs client NOP comparison. Typo documentation important. NULL InstrumentID is a known data quality issue. CBH-only client NOP scope well-documented.*
