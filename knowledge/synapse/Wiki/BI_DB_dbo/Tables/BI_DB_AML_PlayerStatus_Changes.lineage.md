# BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes — Column Lineage

*Generated: 2026-04-21 | Phase 10B output — written BEFORE wiki*

## Source Objects

| Source | Type | Description |
|--------|------|-------------|
| DWH_dbo.Fact_SnapshotCustomer | DWH Fact | Daily customer snapshot — provides PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID, IsDepositor, RealCID; filtered to IsValidCustomer=1, VerificationLevelID>=2 |
| DWH_dbo.Dim_Range | DWH Dimension | Date range dimension — provides FromDateID (converted to Change_Date via CONVERT(DATE,CHAR(8),FromDateID)) |
| DWH_dbo.Dim_Customer | DWH Dimension | Customer master — provides PII (FirstName, LastName, MiddleName, Email, BirthDate, Phone, IP, UserName), RegisteredReal, FirstDepositDate, CountryID, RegulationID, PlayerLevelID |
| DWH_dbo.Dim_PlayerStatus | DWH Dimension | Player status master — provides Name for both Current and Previous status (joined twice via INNER JOIN) |
| DWH_dbo.Dim_PlayerStatusReasons | DWH Dimension | Status change reason master — provides Name for both current and previous reason (joined twice via LEFT JOIN) |
| DWH_dbo.Dim_PlayerStatusSubReasons | DWH Dimension | Sub-reason master — provides PlayerStatusSubReasonName for both current and previous sub-reason (joined twice via LEFT JOIN) |
| DWH_dbo.Dim_Country | DWH Dimension | Country master — provides Name (Country) via JOIN on CountryID |
| DWH_dbo.Dim_Regulation | DWH Dimension | Regulation master — provides Name (Regulation) via JOIN on DWHRegulationID=RegulationID |
| DWH_dbo.Dim_PlayerLevel | DWH Dimension | Player level master — provides Name (Club) via JOIN on PlayerLevelID |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|------------|---------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough: Fact_SnapshotCustomer.RealCID, confirmed via INNER JOIN ON dc.RealCID = dd.CID | Tier 1 — Customer.CustomerStatic |
| 2 | FirstName | DWH_dbo.Dim_Customer | FirstName | Passthrough — current-state PII from Dim_Customer at time of ETL run | Tier 1 — Customer.CustomerStatic |
| 3 | LastName | DWH_dbo.Dim_Customer | LastName | Passthrough | Tier 1 — Customer.CustomerStatic |
| 4 | MiddleName | DWH_dbo.Dim_Customer | MiddleName | Passthrough | Tier 1 — Customer.CustomerStatic |
| 5 | Email | DWH_dbo.Dim_Customer | Email | Passthrough | Tier 1 — Customer.CustomerStatic |
| 6 | BirthDate | DWH_dbo.Dim_Customer | BirthDate | Passthrough (datetime) | Tier 1 — Customer.CustomerStatic |
| 7 | Phone | DWH_dbo.Dim_Customer | Phone | Passthrough | Tier 1 — Customer.CustomerStatic |
| 8 | IP | DWH_dbo.Dim_Customer | IP | Passthrough | Tier 1 — Customer.CustomerStatic |
| 9 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN: Dim_Customer.RegulationID → Dim_Regulation.DWHRegulationID → Dim_Regulation.Name | Tier 1 — Dictionary.Regulation |
| 10 | Country | DWH_dbo.Dim_Country | Name | JOIN: Dim_Customer.CountryID → Dim_Country.DWHCountryID → Dim_Country.Name | Tier 1 — Dictionary.Country |
| 11 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN: Dim_Customer.PlayerLevelID → Dim_PlayerLevel.Name | Tier 1 — Dictionary.PlayerLevel |
| 12 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | CAST(dc.RegisteredReal AS DATE) — date portion only | Tier 1 — Customer.CustomerStatic |
| 13 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | CAST(dc.FirstDepositDate AS DATE). Default='1900-01-01' for non-depositors | Tier 2 — SP_Dim_Customer |
| 14 | Previous_ID | DWH_dbo.Dim_PlayerStatus | PlayerStatusID | LAG(fsc.PlayerStatusID, 1, 0) OVER(PARTITION BY RealCID ORDER BY FromDateID) — default=0 for first row per customer | Tier 2 — SP_AML_PlayerStatus_Changes |
| 15 | Previous_PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on Previous_ID → Dim_PlayerStatus.Name. Value='N/A' (ID=0) for first-ever status rows (LAG default=0) | Tier 1 — Dictionary.PlayerStatus |
| 16 | Current_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | Passthrough from Fact_SnapshotCustomer.PlayerStatusID | Tier 2 — SP_AML_PlayerStatus_Changes |
| 17 | Current_PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN on Current_ID → Dim_PlayerStatus.Name | Tier 1 — Dictionary.PlayerStatus |
| 18 | Change_Date | DWH_dbo.Dim_Range | FromDateID | CONVERT(DATE, CONVERT(CHAR(8), dr.FromDateID)) — status change date from snapshot range start | Tier 2 — SP_AML_PlayerStatus_Changes |
| 19 | Previous_ChangeDate | Computed | N/A | LAG(Change_Date, 1, NULL) OVER(PARTITION BY CID ORDER BY Change_Date) — NULL for first change per customer | Tier 2 — SP_AML_PlayerStatus_Changes |
| 20 | DaysBetweenChanges | Computed | N/A | DATEDIFF(DAY, Previous_ChangeDate, Change_Date). NULL when Previous_ChangeDate IS NULL | Tier 2 — SP_AML_PlayerStatus_Changes |
| 21 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | LEFT JOIN: Fact_SnapshotCustomer.PlayerStatusReasonID → Dim_PlayerStatusReasons.Name. NULL when no reason recorded | Tier 1 — Dictionary.PlayerStatusReasons |
| 22 | PlayerStatusSubReasonName | N/A | N/A | ALWAYS NULL — column exists in DDL but is never populated by SP_AML_PlayerStatus_Changes. SP inserts 31 columns; this DDL column is omitted. | Tier 2 — SP_AML_PlayerStatus_Changes |
| 23 | Is_FTD | DWH_dbo.Fact_SnapshotCustomer | IsDepositor | COMPUTED: `CASE WHEN fsc.IsDepositor=1 THEN 1 ELSE 0 END`. Snapshot-time depositor flag (not FTD event itself) | Tier 2 — SP_AML_PlayerStatus_Changes |
| 24 | Current_Reason_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusReasonID | Passthrough — the reason ID that drove the current status | Tier 2 — SP_AML_PlayerStatus_Changes |
| 25 | Previous_PlayerStatus_Reason_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusReasonID | LAG(PlayerStatusReasonID, 1, 0) OVER(PARTITION BY RealCID ORDER BY FromDateID) | Tier 2 — SP_AML_PlayerStatus_Changes |
| 26 | Previous_PlayerStatus_Reason | DWH_dbo.Dim_PlayerStatusReasons | Name | LEFT JOIN on Previous_PlayerStatus_Reason_ID → Dim_PlayerStatusReasons.Name | Tier 1 — Dictionary.PlayerStatusReasons |
| 27 | Current_Sub_Reason_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusSubReasonID | Passthrough — granular sub-reason ID for current status | Tier 2 — SP_AML_PlayerStatus_Changes |
| 28 | PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | LEFT JOIN: Fact_SnapshotCustomer.PlayerStatusSubReasonID → Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName | Tier 1 — Dictionary.PlayerStatusSubReasons |
| 29 | Previous_PlayerStatus_SubReason_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusSubReasonID | LAG(PlayerStatusSubReasonID, 1, 0) OVER(PARTITION BY RealCID ORDER BY FromDateID) | Tier 2 — SP_AML_PlayerStatus_Changes |
| 30 | Previous_PlayerStatus_Sub_Reason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | LEFT JOIN on Previous_PlayerStatus_SubReason_ID → Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName | Tier 1 — Dictionary.PlayerStatusSubReasons |
| 31 | UserName | DWH_dbo.Dim_Customer | UserName | Passthrough | Tier 1 — Customer.CustomerStatic |
| 32 | UpdateDate | ETL | N/A | GETDATE() at SP execution time | Tier 2 — SP_AML_PlayerStatus_Changes |

## ETL Pipeline Summary

```
DWH_dbo.Fact_SnapshotCustomer
  [IsValidCustomer=1, VerificationLevelID>=2]
  LAG(PlayerStatusID) OVER(PARTITION BY RealCID ORDER BY FromDateID)  → Previous_ID
  LAG(PlayerStatusReasonID) OVER(...)                                  → Previous_Reason_ID
  LAG(PlayerStatusSubReasonID) OVER(...)                               → Previous_SubReason_ID
  WHERE PlayerStatusID <> Previous_PlayerStatusID  [change detection]
    → #pop  (status changes + first-time assignments where LAG default=0)

DWH_dbo.Dim_PlayerStatus      → Current_PlayerStatus, Previous_PlayerStatus (joined twice)
DWH_dbo.Dim_PlayerStatusReasons  → PlayerStatusReason, Previous_PlayerStatus_Reason (LEFT JOIN x2)
DWH_dbo.Dim_PlayerStatusSubReasons → PlayerStatusSubReason, Previous_PlayerStatus_Sub_Reason (LEFT JOIN x2)
DWH_dbo.Dim_Range             → Change_Date (FromDateID → DATE)
    → #pop

LAG(Change_Date) OVER(PARTITION BY CID ORDER BY Change_Date) → Previous_ChangeDate
DATEDIFF(DAY, Previous_ChangeDate, Change_Date)              → DaysBetweenChanges
    → #days

DWH_dbo.Dim_Customer [IsValidCustomer=1, VerificationLevelID>=2] → PII + Regulation + Country + Club + dates
    → #client → #final

  |-- SP_AML_PlayerStatus_Changes (no @Date param, TRUNCATE+INSERT, daily) ---|
  |   Full rebuild: all customers, all dates, all status changes              |
  v
BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes
  27.2M rows | 19.6M distinct CIDs | Change dates 2011-06-07 to 2026-04-12
  72.1% rows: Previous='N/A' (first-ever status, LAG default=0)
  Current status: Normal 75.8%, Blocked 8.0%, Block Deposit & Trading 5.0%
  PlayerStatusSubReasonName: always NULL (DDL ghost column, never populated by SP)
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 19 | CID, FirstName, LastName, MiddleName, Email, BirthDate, Phone, IP, Regulation, Country, Club, RegisteredReal, Previous_PlayerStatus, Current_PlayerStatus, PlayerStatusReason, Previous_PlayerStatus_Reason, PlayerStatusSubReason, Previous_PlayerStatus_Sub_Reason, UserName |
| Tier 2 | 13 | FirstDepositDate, Previous_ID, Current_ID, Change_Date, Previous_ChangeDate, DaysBetweenChanges, PlayerStatusSubReasonName (always NULL), Is_FTD, Current_Reason_ID, Previous_PlayerStatus_Reason_ID, Current_Sub_Reason_ID, Previous_PlayerStatus_SubReason_ID, UpdateDate |
