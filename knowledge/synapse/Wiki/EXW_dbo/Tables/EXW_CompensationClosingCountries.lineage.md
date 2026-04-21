---
object: EXW_dbo.EXW_CompensationClosingCountries
type: Table
generated: 2026-04-20
phase: 10B
---

# Column Lineage — EXW_dbo.EXW_CompensationClosingCountries

## ETL Chain

```
BI_DB_dbo.External_Fivetran_google_sheets_aml_reasons_compensated_users (Project='AML')
BI_DB_dbo.External_Fivetran_google_sheets_wallet_aml_us_compensations   (Project='AML_US')
BI_DB_dbo.External_Fivetran_google_sheets_wallet_closureandreimbursementseea_cysec_2025 (Project='AML_EEA')
  |
  | Google Sheets → Fivetran → BI_DB_dbo External Tables
  |
  + EXW_Wallet.EXW_CustomerWalletsView (WalletId + Address by GCID + CryptoId)
    |
    | SP_EXW_CompensationClosingCountries (no @d parameter — full UPSERT)
    | INSERT new rows + UPDATE existing rows (per Project, GCID, CryptoId, USD_FinalBalance uniqueness)
    | Dedup via ROW_NUMBER at end
    v
EXW_dbo.EXW_CompensationClosingCountries
  (15 additional project values loaded by legacy ETL / manual import — not via current SP)
    |
    | consumed by:
    +-- SP_EXW_FinanceReportsBalancesNew → AMLClosureEvent condition 4 (compensated user check)
    +-- SP_EXW_CompensationClosingCountries → EXW_ReimbursementFollowUp (reimbursement tracking)
    +-- SP_EXW_CompensationClosingCountries → EXW_ReimbursementSumTable (summary aggregation)
```

## Column Lineage

| # | DWH Column | Tier | Source Table | Source Column | Transform |
|---|------------|------|-------------|---------------|-----------|
| 1 | CID | T2 | Google Sheets (via Fivetran) | cid | CAST(CAST(REPLACE(cid,CHAR(160),'') AS FLOAT) AS INT) — handles non-breaking space chars in Google Sheets |
| 2 | GCID | T2 | Google Sheets (via Fivetran) | gcid | CAST(CAST(REPLACE(gcid,CHAR(160),'') AS FLOAT) AS INT) — handles NBSP; for AML: direct CAST(INT) |
| 3 | Rate | T2 | Google Sheets (via Fivetran) | exchange_rate | Passthrough from Google Sheet |
| 4 | RateDate | T2 | Google Sheets (via Fivetran) | exchange_date | Passthrough from Google Sheet |
| 5 | CryptoName | T2 | Google Sheets (via Fivetran) | crypto | Passthrough from Google Sheet |
| 6 | CryptoId | T2 | Google Sheets (via Fivetran) | crypto_id | CAST(INT); CASE ISNUMERIC check for AML_US/AML_EEA to handle non-numeric values |
| 7 | FinalBalance | T2 | Google Sheets (via Fivetran) | units | CAST(FLOAT) |
| 8 | USD_FinalBalance | T2 | Google Sheets (via Fivetran) | compensation_amount_usd | CAST(FLOAT) |
| 9 | WalletId | T2 | EXW_Wallet.EXW_CustomerWalletsView | Id | JOIN on GCID + CryptoId; uniqueidentifier |
| 10 | Address | T2 | EXW_Wallet.EXW_CustomerWalletsView | Address | JOIN on GCID + CryptoId; the wallet's blockchain address |
| 11 | Country | T2 | Google Sheets (via Fivetran) | country | Passthrough from Google Sheet |
| 12 | CountryID | T2 | Google Sheets (via Fivetran) | country_id | CAST(INT) |
| 13 | ReportFromDate | T2 | ETL-computed | — | Hardcoded NULL for AML* projects (current SP); may have date values for legacy projects (FrenchTerr, Germany, Russia, etc.) loaded by prior ETL |
| 14 | ReportId | T2 | ETL-computed | — | Hardcoded NULL for AML* projects (current SP); may have int values for legacy projects |
| 15 | Project | T2 | ETL-computed | — | Hardcoded literal: 'AML', 'AML_US', 'AML_EEA' per source; 15 other values from legacy ETL |
| 16 | CompensationDate | T2 | Google Sheets (via Fivetran) | compensation_date | Passthrough from Google Sheet |
| 17 | Regulation | T2 | Google Sheets (via Fivetran) | regulation | Passthrough from Google Sheet |
| 18 | RegulationID | T2 | Google Sheets (via Fivetran) | regulation_id | CAST(INT); ISNUMERIC check for AML_US/AML_EEA |
| 19 | UpdateDate | T2 | ETL-computed | — | GETDATE() at insert time |
| 20 | Reason | T2 | Google Sheets (via Fivetran) | reason (AML/AML_US) or sub_reason (AML_EEA) | Passthrough; field name differs by project type |
| 21 | AMLStatus | T2 | Google Sheets (via Fivetran) | status | Passthrough; relevant values: 'compensated', 'reimbursed', 'completed' (used by downstream SP filter) |
| 22 | DateClosure | T2 | Google Sheets (via Fivetran) | date_of_closure | CAST(DATE) |

## Tier Summary

- **Tier 1**: 0 columns — no upstream DB_Schema wiki exists for Google Sheets / Fivetran sources
- **Tier 2**: 22 columns — all sourced from Fivetran-imported Google Sheets or ETL-computed (GETDATE, hardcoded NULLs, hardcoded literals), with WalletId/Address from EXW_CustomerWalletsView lookup
- **Tier 3**: 0
- **Tier 4**: 0

## UC Target

- **Synapse**: EXW_dbo.EXW_CompensationClosingCountries
- **UC Target**: `_Not_Migrated` (no UC mapping found — regulatory compensation reference, Synapse-only)
