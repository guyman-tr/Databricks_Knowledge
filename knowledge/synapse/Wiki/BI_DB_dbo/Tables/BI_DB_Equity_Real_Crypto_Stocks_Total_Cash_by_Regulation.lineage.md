---
object: BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation
schema: BI_DB_dbo
type: table
lineage_tier: Tier 2 — SP-derived aggregation from BI_DB_Client_Balance_Aggregate_Level_New
generated: 2026-04-23
---

# Lineage — BI_DB_dbo.BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation

## Writer

| Property | Value |
|---|---|
| Writer SP | `SP_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation` |
| Author | Unknown (no SP header) |
| OpsDB Priority | 20 (third wave — depends on P0/P15 BI_DB_Client_Balance_Aggregate_Level_New output) |
| Schedule | SB_Daily / Daily |
| Pattern | DELETE WHERE DateID = @DateID + INSERT (idempotent per date) |

## Source Tables

| Source | Schema | Purpose |
|---|---|---|
| `BI_DB_Client_Balance_Aggregate_Level_New` | BI_DB_dbo | Aggregated customer balance snapshot — provides all financial metrics and dimensional attributes. Filtered to UK/CySEC+BVI+NFA/TransferDirection=1 |

## Column Lineage

| Column | Source Table | Source Column | Transform | Confidence |
|---|---|---|---|---|
| DateID | ETL parameter | @DateID = CONVERT(CHAR(8), @Date, 112) | YYYYMMDD int derived from run date | Tier 2 — ETL parameter |
| Country | BI_DB_Client_Balance_Aggregate_Level_New | Country | Passthrough; hardcoded to 'United Kingdom' by SP WHERE filter | Tier 2 — SP-derived |
| Regulation | BI_DB_Client_Balance_Aggregate_Level_New | Regulation | Passthrough; restricted to CySEC, BVI, NFA by SP WHERE filter | Tier 2 — SP-derived |
| IsGermanBaFin | BI_DB_Client_Balance_Aggregate_Level_New | IsGermanBaFin | Passthrough; always 0 in this extract (UK customers, not BaFin) | Tier 2 — SP-derived |
| PlayerStatus | BI_DB_Client_Balance_Aggregate_Level_New | PlayerStatus | Passthrough GROUP BY dimension | Tier 2 — SP-derived |
| IsCreditReportValidCB | BI_DB_Client_Balance_Aggregate_Level_New | IsCreditReportValidCB | Passthrough GROUP BY dimension | Tier 2 — SP-derived |
| AccountType | BI_DB_Client_Balance_Aggregate_Level_New | AccountType | Passthrough GROUP BY dimension | Tier 2 — SP-derived |
| Club | BI_DB_Client_Balance_Aggregate_Level_New | Club | Passthrough GROUP BY dimension | Tier 2 — SP-derived |
| MifidCategory | BI_DB_Client_Balance_Aggregate_Level_New | MifidCategory | Passthrough GROUP BY dimension | Tier 2 — SP-derived |
| AvailableCash | BI_DB_Client_Balance_Aggregate_Level_New | AvailableCash | SUM(ISNULL(a.AvailableCash, 0)) | Tier 2 — SP-derived |
| CashInCopy | BI_DB_Client_Balance_Aggregate_Level_New | CashInCopy | SUM(ISNULL(a.CashInCopy, 0)) | Tier 2 — SP-derived |
| TotalNegativeLiability | BI_DB_Client_Balance_Aggregate_Level_New | TotalNegativeLiability | SUM(ISNULL(a.TotalNegativeLiability, 0)) | Tier 2 — SP-derived |
| InProcessCashout | BI_DB_Client_Balance_Aggregate_Level_New | InProcessCashout | SUM(ISNULL(a.InProcessCashout, 0)) | Tier 2 — SP-derived |
| ActualNWA | BI_DB_Client_Balance_Aggregate_Level_New | actualNWA | SUM(ISNULL(a.actualNWA, 0)); note source column is lowercase 'actualNWA' | Tier 2 — SP-derived |
| EquityRealCrypto | BI_DB_Client_Balance_Aggregate_Level_New | TotalRealCrypto + PositionPNLCryptoReal | SUM(TotalRealCrypto + PositionPNLCryptoReal) | Tier 2 — SP-derived |
| EquityRealStocks | BI_DB_Client_Balance_Aggregate_Level_New | TotalRealStocks + PositionPNLStocksReal | SUM(TotalRealStocks + PositionPNLStocksReal) | Tier 2 — SP-derived |
| EquityCFD | BI_DB_Client_Balance_Aggregate_Level_New | PositionAmount + PositionPNL - real components | SUM((PositionAmount + PositionPNL) - (TotalRealCrypto + PositionPNLCryptoReal + TotalRealStocks + PositionPNLStocksReal)) | Tier 2 — SP-derived |
| TotalCash_Calc | BI_DB_Client_Balance_Aggregate_Level_New | Multiple | SUM(AvailableCash + CashInCopy + InProcessCashout + EquityCFD - TotalNegativeLiability - ActualNWA) | Tier 2 — SP-derived |
| UpdateDate | — | — | GETDATE() at INSERT time | Propagation — ETL metadata |

## Notes

- **UK-only extract**: SP hardcodes `Country = 'United Kingdom'` and `Regulation IN ('CySEC', 'BVI', 'NFA')` — only UK-domiciled customers under these three regulations appear. All other countries/regulations are excluded.
- **IsGermanBaFin always 0**: BaFin is a German regulator; the UK filter means this column is always 0 and provides no analytical value in this table.
- **TransferDirection = 1 filter**: Only one direction of balance transfer is included; the source aggregate table tracks both directions.
- **EquityRealCrypto/Stocks**: These are position NOP + unrealized PnL (not settled value). Both components may be negative.
- **TotalCash_Calc**: A derived regulatory cash calculation, not a raw balance. EquityCFD (CFD equity) is included; ActualNWA is subtracted as a liability offset.
- **P20 dependency**: This SP depends on BI_DB_Client_Balance_Aggregate_Level_New (a P15 table) being populated first.
