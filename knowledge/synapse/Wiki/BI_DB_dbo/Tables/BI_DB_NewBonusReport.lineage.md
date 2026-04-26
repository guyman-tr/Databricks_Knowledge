# BI_DB_dbo.BI_DB_NewBonusReport — Column Lineage

**Generated**: 2026-04-23 | **Pipeline**: SP_NewBonusReport (Daily, SB_Daily — SP code not accessible)

## ETL Chain

```
DWH_dbo sources (deposits, cash-out events, customer segments)
  |-- SP_NewBonusReport (Daily, SB_Daily, Priority 0 — logic not accessible) ---|
  |-- Also writes: BI_DB_dbo.BI_DB_Depositors_By_Managers (sibling output)
  v
BI_DB_dbo.BI_DB_NewBonusReport (56.7M rows, per deposit/CO event per customer)
  |-- (downstream consumers not confirmed — likely account manager reporting tools)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | Customer.CustomerStatic | CID | Passthrough — customer identifier | Tier 1 — Customer.CustomerStatic |
| 2 | ManagerID | Account manager assignment | ManagerID | ID of assigned account manager | Tier 3 — inferred from data + naming |
| 3 | Manager | Account manager roster | Manager name | Denormalized name of assigned account manager | Tier 3 — inferred from data + naming |
| 4 | DateID | ETL | derived from event date | YYYYMMDD integer date key | Tier 2 — data evidence (e.g., 20260411) |
| 5 | Date | Deposit/CO event | event date | Calendar date of the deposit or cash-out event | Tier 2 — data evidence |
| 6 | TotalDepositAmount | DWH deposit events | deposit USD amount | USD deposit amount for this event row | Tier 2 — naming + data evidence |
| 7 | TotalCoAmount | DWH cash-out events | CO USD amount | USD cash-out (CO) amount; mutually exclusive with TotalDepositAmount per row | Tier 3 — inferred ("CO" meaning pending confirmation) |
| 8 | IsContacted | Account manager activity | contact flag | 1 = manager has contacted this customer; 0 = not yet contacted | Tier 3 — data evidence (97% = 0) |
| 9 | Country | DWH_dbo.Dim_Customer | CountryName | Customer country name; denormalized from customer dimension | Tier 2 — data evidence + Dim_Customer passthrough |
| 10 | Region | DWH_dbo.Dim_Customer | Region | Sales region segment (UK, French, Eastern Europe, etc.) | Tier 2 — data evidence + Dim_Customer passthrough |
| 11 | Desk | DWH_dbo.Dim_Customer | Desk | Sales desk assignment (UK, French, Other EU, etc.) | Tier 2 — data evidence + Dim_Customer passthrough |
| 12 | Channel | DWH_dbo.Dim_Customer | Channel | Customer acquisition channel (SEM, Affiliate, Direct, etc.) | Tier 2 — data evidence + Dim_Customer passthrough |
| 13 | SubChannel | DWH_dbo.Dim_Customer | SubChannel | Acquisition sub-channel detail (FB, Mobile CPA, Direct Mobile, etc.) | Tier 2 — data evidence + Dim_Customer passthrough |
| 14 | Club | DWH_dbo.Dim_Customer | Club | eToro Club membership tier (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond) | Tier 2 — data evidence + Dim_Customer passthrough |
| 15 | UpdateDate | ETL pipeline | — | ETL write timestamp from SP_NewBonusReport run | Propagation |
| 16 | ContactByManager | Account manager activity | manager name | Name of the manager who last contacted this customer | Tier 3 — inferred from naming + data evidence |
| 17 | DaysSinceContact | ETL | computed | Days elapsed since last manager contact with this customer | Tier 3 — inferred from naming + data evidence |

## Notes

- **SP code unavailable**: `SP_NewBonusReport` exists in OpsDB (Priority 0, Daily, SB_Daily) but sys.sql_modules shows empty definition and no SSDT file. Logic inferred from data evidence.
- **Deposit vs CO rows**: TotalDepositAmount and TotalCoAmount appear mutually exclusive per row — a row represents either a deposit event or a cash-out event, not both.
- **Multiple rows per CID per date**: avg 1.21 rows per CID per date; max 65. Customers with multiple deposits/COs in a day have multiple rows.
- **"CO" meaning**: Likely "Cash Out" (withdrawal). Large values observed ($1.37M, $1.29M) consistent with institutional-scale withdrawals. Pending confirmation.
- **UpdateDate pattern**: All rows updated together in batch ETL (same UpdateDate timestamp across all rows for a given batch run).
