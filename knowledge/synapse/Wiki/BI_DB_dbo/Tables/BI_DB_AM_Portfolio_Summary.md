# BI_DB_dbo.BI_DB_AM_Portfolio_Summary

| Attribute | Value |
|-----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_AM_Portfolio_Summary |
| **SP Author** | Amir Gurewitz (2018-03-18; updated multiple times through 2024-07-01 by Ofir Chloe Gal) |
| **Refresh Pattern** | DELETE+INSERT days 1–7 of month; daily UPDATE throughout month |
| **Frequency** | Daily |
| **UC Target** | `_Not_Migrated` |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX (StartOfMonth ASC) |
| **Row Count** | 15,914 rows; Oct 2017 – Apr 2026 (103 months); 596 distinct account managers |
| **Columns** | 22 |

---

## Summary

Monthly account manager (AM) performance summary used in Tableau reports for the CopyFund/AM team. Each row = one account manager × one calendar month. Tracks portfolio size, deposits, cashouts, and Salesforce contact activity for each AM's client portfolio.

The SP runs daily. During days 1–7 it deletes and rebuilds the month's skeleton (PortfolioSOM from Fact_SnapshotCustomer). After day 7, INSERT logic stops and the row is updated in-place each day with MTD financial and contact activity data. New managers added after the 7th also get a skeleton row via a secondary INSERT path.

---

## Business Context

Used by the Account Management team and Tableau dashboards for monthly performance reviews. Key use cases:
- Track how much a manager's portfolio deposited vs. cashed out in a month
- Measure contact quality: how many clients were reached, and what proportion made a deposit after contact (`TotalContactDeposit`)
- Monitor manager active working days (`ActiveDays`)

**CopyFund columns are permanently dead**: `TotalMoneyInCF` and `TotalMoneyOutCF` are hardcoded to 0. The CopyFund join section was commented out and these columns carry no data. Do not use them in analysis.

**Contact columns require elevated access**: `Outbound_Email`, `Unique_Outbound_Email`, `Completed_Email`, `Unique_Completed_Email`, `Outbound_Phonecall`, `Unique_Outbound_Phonecall`, `Completed_Phonecall`, and `Unique_Completed_Phonecall` are masked with `MASKED WITH (FUNCTION = 'default()')`. Users without UNMASK permission see NULL for these 8 columns. `UniqueContactAttempts` and `UniqueContactSuccess` (cols 18–19) are **not** masked.

---

## ETL / Refresh

**Phase 1 (days 1–7 only)**: DELETE WHERE StartOfMonth = @startofmonth. INSERT skeleton rows from Fact_SnapshotCustomer at start-of-month snapshot. All financial and contact columns initialized to 0. Population = managers in Dim_Manager WHERE IsActive=1 AND SFManagerID IS NOT NULL.

**Late-manager catch-up**: If a manager appears in Dim_Manager but not yet in the table for this month, the SP inserts a new skeleton row regardless of day (covers managers onboarded after the 7th).

**Phase 2 (daily, all month)**: UPDATE existing rows via LEFT JOINs to:
- `BI_DB_NewBonusReport` → TotalDeposit, TotalCO, TotalContactDeposit (MTD aggregation)
- `BI_DB_UsageTracking_SF` → all 10 contact activity columns (MTD Salesforce actions pivoted by ActionName)
- `Dim_Customer` → CurrentPortfolio (live count updated daily)

---

## Column Catalog

| # | Column | Type | Tier | Description |
|---|--------|------|------|-------------|
| 1 | StartOfMonth | date NOT NULL | T2 — SP param | First day of the reporting calendar month. Clustered index key. Derived as DATEFROMPARTS(YEAR(@dd), MONTH(@dd), 1). |
| 2 | Manager | varchar(50) NULL | T2 — Dim_Manager | Account manager's full name: Dim_Manager.FirstName + ' ' + LastName. Only active managers with a Salesforce manager ID (SFManagerID IS NOT NULL) are included. |
| 3 | AccountManagerID | int NULL | T2 — Dim_Manager | Account manager's primary key from DWH_dbo.Dim_Manager (= ManagerID). FK to Dim_Manager and Fact_SnapshotCustomer.AccountManagerID. |
| 4 | PortfolioSOM | int NULL | T2 — Fact_SnapshotCustomer | Number of valid customers assigned to this manager at the start of the month. COUNT(DISTINCT Fact_SnapshotCustomer.RealCID WHERE IsValidCustomer=1) at @startofmonth snapshot. Fixed after day 7. |
| 5 | TotalDeposit | money NULL | T2 — BI_DB_NewBonusReport | Month-to-date total deposit amount (USD) for all clients in this manager's portfolio. SUM(BI_DB_NewBonusReport.TotalDepositAmount) where ManagerID matches and DateID in current month range. |
| 6 | TotalContactDeposit | money NULL | T2 — BI_DB_NewBonusReport | Month-to-date deposits from clients the manager has contacted (IsContacted=1 in NewBonusReport). Subset of TotalDeposit — measures contact-driven deposit conversion. |
| 7 | TotalCO | money NULL | T2 — BI_DB_NewBonusReport | Month-to-date total cashout amount (USD) for manager's portfolio. SUM(BI_DB_NewBonusReport.TotalCoAmount). |
| 8 | TotalMoneyInCF | money NULL | Propagation — dead column | Always 0. CopyFund money-in metric — the integration was commented out. Do not use. |
| 9 | TotalMoneyOutCF | money NULL | Propagation — dead column | Always 0. CopyFund money-out metric — same as TotalMoneyInCF. Do not use. |
| 10 | Outbound_Email | int MASKED NULL | T2 — BI_DB_UsageTracking_SF | **MASKED**. Total count of outbound email actions logged in Salesforce by this manager MTD (ActionName='Outbound_Email__c'). Requires UNMASK permission to view. |
| 11 | Unique_Outbound_Email | int MASKED NULL | T2 — BI_DB_UsageTracking_SF | **MASKED**. Count of distinct client CIDs contacted via outbound email by this manager MTD. |
| 12 | Completed_Email | int MASKED NULL | T2 — BI_DB_UsageTracking_SF | **MASKED**. Total count of completed email contacts (ActionName='Completed_Contact_Email__c') by this manager MTD. |
| 13 | Unique_Completed_Email | int MASKED NULL | T2 — BI_DB_UsageTracking_SF | **MASKED**. Count of distinct client CIDs with a completed email contact with this manager MTD. |
| 14 | Outbound_Phonecall | int MASKED NULL | T2 — BI_DB_UsageTracking_SF | **MASKED**. Total count of outbound phone contact attempts (ActionName='Contacted__c') by this manager MTD. |
| 15 | Unique_Outbound_Phonecall | int MASKED NULL | T2 — BI_DB_UsageTracking_SF | **MASKED**. Count of distinct client CIDs who received a phone contact attempt from this manager MTD. |
| 16 | Completed_Phonecall | int MASKED NULL | T2 — BI_DB_UsageTracking_SF | **MASKED**. Total count of successful phone calls (ActionName='Phone_Call_Succeed__c') by this manager MTD. |
| 17 | Unique_Completed_Phonecall | int MASKED NULL | T2 — BI_DB_UsageTracking_SF | **MASKED**. Count of distinct client CIDs with a successful phone call with this manager MTD. |
| 18 | UniqueContactAttempts | int NULL | T2 — BI_DB_UsageTracking_SF | Total distinct client CIDs that this manager contacted via any Salesforce action type MTD. Not masked — aggregate across all action types. |
| 19 | UniqueContactSuccess | int NULL | T2 — BI_DB_UsageTracking_SF | Distinct client CIDs with a completed contact (email replied or call succeeded): ActionName IN ('Completed_Contact_Email__c', 'Phone_Call_Succeed__c'). Not masked. |
| 20 | ActiveDays | int NULL | T2 — BI_DB_UsageTracking_SF | Number of distinct calendar days in the month where the manager logged at least one phone contact action (ActionName IN ('Contacted__c', 'Phone_Call_Succeed__c')) for a non-NULL client CID. Proxy for AM working engagement. |
| 21 | CurrentPortfolio | int NULL | T2 — Dim_Customer | Live count of valid customers assigned to this manager. COUNT(Dim_Customer.RealCID WHERE IsValidCustomer=1 AND AccountManagerID matches). Refreshed every day — represents today's portfolio size, not start-of-month. |
| 22 | UpdateDate | datetime NOT NULL | Propagation | ETL metadata: timestamp of the most recent UPDATE run (GETDATE()). |

---

## Data Quality / Known Issues

### TotalMoneyInCF / TotalMoneyOutCF Are Always 0

Both columns are hardcoded to 0 in the UPDATE statement:
```sql
SET TotalMoneyInCF = 0, TotalMoneyOutCF = 0
```
The `--LEFT JOIN #copyfund cf` section is commented out. These columns exist in the DDL but carry no data. Do not include them in analysis or dashboards.

### Eight Contact Columns Are Masked

Columns 10–17 (`Outbound_Email` through `Unique_Completed_Phonecall`) use `MASKED WITH (FUNCTION = 'default()')`. Only users with UNMASK permission see real values. BI tools and users without elevated access see NULL for all 8. `UniqueContactAttempts` and `UniqueContactSuccess` (cols 18–19) are NOT masked and are safe to query without special permissions.

### PortfolioSOM vs CurrentPortfolio Semantics

`PortfolioSOM` is a point-in-time snapshot at start of month (locked after day 7). `CurrentPortfolio` is live (updated daily from Dim_Customer). When month-end reporting uses both, ensure the correct metric is selected for the analytical question.

### Manager Name Cardinality (596 IDs vs 632 Names)

Live data shows 596 distinct `AccountManagerID` values but 632 distinct `Manager` name strings across 103 months. The 36 additional name variants reflect managers whose names were updated in Dim_Manager over time — each update propagates to new monthly rows only, leaving old rows with the prior name.

---

## Lineage

Full column-level lineage: [BI_DB_AM_Portfolio_Summary.lineage.md](./BI_DB_AM_Portfolio_Summary.lineage.md)

**Tier Summary**: 20 Tier 2, 2 Propagation (dead) + 1 Propagation (UpdateDate) = 3 Propagation total

**Upstream sources**:
- `DWH_dbo.Dim_Manager` → Manager name, AccountManagerID (active AMs with SFManagerID only)
- `DWH_dbo.Fact_SnapshotCustomer` → PortfolioSOM
- `DWH_dbo.Dim_Range` → date range filter for snapshot join
- `BI_DB_dbo.BI_DB_NewBonusReport` → TotalDeposit, TotalCO, TotalContactDeposit
- `BI_DB_dbo.BI_DB_UsageTracking_SF` → all 10 contact activity columns
- `DWH_dbo.Dim_Customer` → CurrentPortfolio
