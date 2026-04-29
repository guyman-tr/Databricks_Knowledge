# BI_DB_dbo.BI_DB_ReverseCoReport — Column Lineage

## Source Objects

| Source | Schema | Role |
|--------|--------|------|
| Fact_CustomerAction | DWH_dbo | Cancelled cashout events (ActionTypeID=37) + subsequent cashouts (ActionTypeID=8) |
| External_etoro_Billing_Withdraw | BI_DB_dbo | Original withdraw request details (RequestDate, reason, comment) |
| Dim_ClientWithdrawReason | DWH_dbo | Withdraw reason name lookup |
| BI_DB_CIDFirstDates | BI_DB_dbo | Customer country, region, CountryID |
| Dim_Country | DWH_dbo | Desk assignment (via CountryID) |
| Fact_SnapshotCustomer | DWH_dbo | Account manager assignment (via DateRange) |
| Dim_Manager | DWH_dbo | Manager name (FirstName + LastName) |
| Dim_Range | DWH_dbo | Date range resolution for snapshot join |
| BI_DB_UsageTracking_SF | BI_DB_dbo | Salesforce contact tracking (phone/email before cancel) |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Fact_CustomerAction | RealCID | Rename (RealCID → CID) |
| Desk | DWH_dbo.Dim_Country | Desk | Dim-lookup passthrough (JOIN on CountryID from CIDFirstDates) |
| CoRequestDate | BI_DB_dbo.External_etoro_Billing_Withdraw | RequestDate | Rename |
| Country | BI_DB_dbo.BI_DB_CIDFirstDates | Country | Passthrough |
| Region | BI_DB_dbo.BI_DB_CIDFirstDates | Region | Passthrough |
| Manager | DWH_dbo.Dim_Manager | FirstName + ' ' + LastName | Concatenation |
| AccountManagerID | DWH_dbo.Fact_SnapshotCustomer | AccountManagerID | Passthrough (via DateRange join) |
| CoRequestAmount | DWH_dbo.Fact_CustomerAction | Amount | Rename (Amount → CoRequestAmount) |
| CoCanceledDate | DWH_dbo.Fact_CustomerAction | Occurred | Rename (Occurred → CoCanceledDate) |
| ClientWithdrawReason | DWH_dbo.Dim_ClientWithdrawReason | ClientWithdrawReasonName | Rename |
| ClientWithdrawReasonComment | BI_DB_dbo.External_etoro_Billing_Withdraw | ClientWithdrawReasonComment | Passthrough |
| FirstCoAfterCancelDate | DWH_dbo.Fact_CustomerAction | MIN(Occurred) | First cashout (ActionTypeID=8) after cancel within 30 days (UPDATE pass) |
| Count30DaysCO | DWH_dbo.Fact_CustomerAction | COUNT(DISTINCT WithdrawID) | Number of cashouts within 30 days after cancel (UPDATE pass) |
| Total30DaysCoAmount | DWH_dbo.Fact_CustomerAction | SUM(Amount) | Total cashout amount within 30 days after cancel (UPDATE pass) |
| ContactedBeforCancel | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate_SF | MAX(CASE) — 1 if phone/email contact between request and cancel dates |
| UpdateDate | — | GETDATE() | ETL timestamp |

## ETL Pattern

- **SP**: BI_DB_dbo.SP_ReverseCO_Report
- **Schedule**: Daily (SB_Daily, Priority 0)
- **Load**: Two-phase pattern:
  1. DELETE+INSERT: Find cancelled cashouts (ActionTypeID=37, Amount >= $5,000) for @dd, insert with NULL follow-up fields
  2. UPDATE: For all rows with NULL FirstCoAfterCancelDate (or new data), compute 30-day follow-up metrics from subsequent cashouts (ActionTypeID=8)
- **Minimum amount threshold**: $5,000 (only large cancelled cashouts tracked)
