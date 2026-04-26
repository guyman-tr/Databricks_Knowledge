# BI_DB_dbo.BI_DB_LimitedAccountsWithReasons — Column Lineage

Generated: 2026-04-22 | Batch: 29 | Writer SP: SP_LimitedAccountsWithReasons

## ETL Pipeline Summary

| Property | Value |
|----------|-------|
| **Writer SP** | `BI_DB_dbo.SP_LimitedAccountsWithReasons` |
| **Author** | Pavlina Masoura (2024-11-05) |
| **Load Pattern** | TRUNCATE TABLE + INSERT (full daily refresh) |
| **Frequency** | Daily (SB_Daily, Priority 20) |
| **Row Count** | ~30,154 (as of 2026-04-13) |
| **UC Target** | Not Migrated |

## Column Lineage

| Column | Source Table | Source Column | Transform | Tier |
|--------|-------------|---------------|-----------|------|
| CID | BI_DB_CIDFirstDates | CID | passthrough | Tier 1 — Customer.CustomerStatic |
| LastLoggeedIn | BI_DB_CIDFirstDates | LastLoggedIn | rename (typo 'ee' added in target col name) | Tier 2 — SP_CIDFirstDates |
| Regulation | Dim_Regulation | Name | lookup via Dim_Customer.RegulationID | Tier 2 — SP_LimitedAccountsWithReasons |
| Balance | V_Liabilities | Credit | passthrough as Balance | Tier 2 — SP_LimitedAccountsWithReasons |
| Equity | V_Liabilities | Liabilities + ActualNWA | SUM of two columns | Tier 2 — SP_LimitedAccountsWithReasons |
| PlayerStatusID | Dim_Customer | PlayerStatusID | passthrough | Tier 1 — Customer.CustomerStatic |
| PlayerStatus | Dim_PlayerStatus | Name | lookup via Dim_Customer.PlayerStatusID | Tier 2 — SP_LimitedAccountsWithReasons |
| PlayerStatusReasoon | Dim_PlayerStatusReasons | Name | lookup via Dim_Customer.PlayerStatusReasonID; typo in target col name | Tier 2 — SP_LimitedAccountsWithReasons |
| PlayerStatusSubReason | Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | lookup via Dim_Customer.PlayerStatusSubReasonID | Tier 2 — SP_LimitedAccountsWithReasons |
| TimeBucket | — | BlockedTime | CASE WHEN DATEDIFF(HOUR/DAY/MONTH, BlockedTime, GETDATE()): Under 24h / Under 48h / 5 days / 10 days / 15 days / 1 month / 2 months / Over 2 Months | Tier 2 — SP_LimitedAccountsWithReasons |
| PendingClosureStatus | Dim_PendingClosureStatus | PendingClosureStatusName | lookup via Dim_Customer.PendingClosureStatusID; ISNULL → 'No' | Tier 2 — SP_LimitedAccountsWithReasons |
| BlockedTime | Fact_SnapshotCustomer + Dim_Range | FromDateID | MAX(CONVERT(DATE, FromDateID)) where LAG(PlayerStatusID) <> current PlayerStatusID (most recent status-change date) | Tier 2 — SP_LimitedAccountsWithReasons |
| Equity_Level | — | Equity (TotalEquity) | CASE: <5='A:0-5', >=5<50='B:5-50', >=50<500='C:50-500', >=500='D:500+' | Tier 2 — SP_LimitedAccountsWithReasons |
| Cashouts | Fact_BillingWithdraw | CID | 'Yes'/'No' flag: wire cashout (FundingTypeID=19) exists after BlockedTime | Tier 2 — SP_LimitedAccountsWithReasons |
| CashoutRequestDate | Fact_BillingWithdraw | RequestDate | MIN(RequestDate) of wire cashout after BlockedTime | Tier 2 — SP_LimitedAccountsWithReasons |
| CashoutStatus | Dim_CashoutStatus | Name | lookup via Fact_BillingWithdraw.CashoutStatusID_Withdraw | Tier 2 — SP_LimitedAccountsWithReasons |
| Tickets | BI_DB_SF_Cases | CID | 'Yes'/'No' flag: SF case exists with CreatedDate >= CashoutRequestDate | Tier 2 — SP_LimitedAccountsWithReasons |
| RiskGroupID | Dim_Country | RiskGroupID | passthrough (country-level risk, not customer risk) | Tier 1 — Dictionary.Country |
| FinalGrouping | — | PlayerStatus + PlayerStatusReasoon + PlayerStatusSubReason | concatenation: AML reason → "Status - AML - SubReason"; Selfie subReason → "Status - Reason - SubReason"; else → "Status - Reason" | Tier 2 — SP_LimitedAccountsWithReasons |
| Region | Dim_Country | Region | passthrough | Tier 2 — SP_Dictionaries_Country_DL_To_Synapse |
| Country | Dim_Country | Name | passthrough (renamed) | Tier 1 — Dictionary.Country |
| AccountType | Dim_AccountType | Name | lookup via Dim_Customer.AccountTypeID | Tier 2 — SP_LimitedAccountsWithReasons |
| UpdateDate | — | — | GETDATE() | Tier 5 — ETL metadata |

## Source Objects

| Object | Schema | Purpose |
|--------|--------|---------|
| BI_DB_CIDFirstDates | BI_DB_dbo | Base population: depositors, last login, IsValidCustomer=1 filter |
| Dim_Customer | DWH_dbo | Player status, regulation ID, account type, risk group, pending closure |
| V_Liabilities | DWH_dbo | Credit (Balance) and Liabilities+ActualNWA (Equity) at @EndDateID |
| Dim_Regulation | DWH_dbo | Regulation name text |
| Fact_SnapshotCustomer | DWH_dbo | Historical player status snapshots for BlockedTime LAG calculation |
| Dim_Range | DWH_dbo | Date range for Fact_SnapshotCustomer (FromDateID → CONVERT to DATE) |
| Fact_BillingWithdraw | DWH_dbo | Wire cashout requests (FundingTypeID=19) after block date |
| Dim_CashoutStatus | DWH_dbo | Cashout status text lookup |
| Dim_PlayerStatus | DWH_dbo | Player status name text |
| Dim_PlayerStatusReasons | DWH_dbo | Player status reason name text |
| Dim_PlayerStatusSubReasons | DWH_dbo | Player status sub-reason name text |
| Dim_PendingClosureStatus | DWH_dbo | Pending closure status name text |
| Dim_Country | DWH_dbo | Country name, marketing region, country risk group |
| Dim_AccountType | DWH_dbo | Account type name text |
| BI_DB_SF_Cases | BI_DB_dbo | Salesforce case presence check for cashout-related tickets |

## UC External Lineage

Not applicable — UC Target: Not Migrated.
