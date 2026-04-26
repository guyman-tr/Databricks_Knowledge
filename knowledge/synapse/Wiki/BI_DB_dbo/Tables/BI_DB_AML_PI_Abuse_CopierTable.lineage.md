# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable

## Writer SP

`BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]` — parameterized by date, called daily. Writes multiple related tables. Uses DELETE + INSERT for the CopierTable. Written by Lior Ben Dor, created 2023-10-25, last modified 2025-08-18.

## ETL Pattern: DELETE + INSERT (Daily Snapshot, Effective Full Refresh)

```sql
DELETE FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable
WHERE @DateID > @Past6MonthsINT   -- This is always TRUE for current run dates

INSERT INTO BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable (...)
SELECT ... FROM #copiertable
```

The condition `@DateID > @Past6MonthsINT` evaluates to TRUE for any run date within the last 6 months (which is always). Effect: ALL rows are deleted before each run, making this a **daily full-refresh snapshot** (only the most recent run's data is present). As of 2026-04-12: only Date = 2026-04-11 exists in the table.

## Source Objects

| # | Source Object | Type | Role | Columns Contributed |
|---|--------------|------|------|---------------------|
| 1 | general.etoroGeneral_History_GuruCopiers | Hist Table | Active copy relationships snapshot at run timestamp | ParentCID, CID, Timestamp(→Date), AUC components (Cash, Investment, PnL, DetachedPosInvestment, Dit_PnL), StartCopy, ParentUserName |
| 2 | DWH_dbo.Fact_SnapshotCustomer | Fact | PI (Popular Investor) base population; filter: GuruStatusID≥2, IsValidCustomer=1, VerificationLevelID=3, IsDepositor=1 | ParentCID = RealCID; population gate only |
| 3 | DWH_dbo.Dim_Customer | Dim | Copier identity and PII attributes | CID (RealCID), GCID, BirthDate, FirstName, LastName, Address, Email, Phone, UserName, City, Zip, Gender, GuruStatusID |
| 4 | DWH_dbo.Dim_PlayerStatus | Dim | Copier account restriction state label | PlayerStatus = Name |
| 5 | DWH_dbo.Dim_PlayerLevel | Dim | Copier experience tier label | Club = Name |
| 6 | DWH_dbo.Dim_Country | Dim | Copier country name | Country = Name |
| 7 | DWH_dbo.Dim_GuruStatus | Dim | Copier Guru/PI program status label | GuruStatusName |
| 8 | DWH_dbo.V_Liabilities | View | Copier net equity snapshot at run date | TotalEquity = Liabilities + ActualNWA WHERE DateID = @DateID |

## Data Flow

```
PI Population Gate:
  Fact_SnapshotCustomer (GuruStatusID >= 2 [Cadet+], IsValidCustomer=1, VL3, Depositor)
  + Dim_GuruStatus + Dim_Country + Dim_PlayerStatus + Dim_PlayerLevel + Dim_Regulation + Dim_Customer
  → #pis (Popular Investors active on @Date)

Copy Relationships:
  general.etoroGeneral_History_GuruCopiers (Timestamp = @DateTime, ParentCID ∈ #pis)
  JOIN Dim_Customer (copier identity + PII)
  JOIN Dim_PlayerStatus, Dim_PlayerLevel, Dim_Country, Dim_Regulation
  LEFT JOIN Dim_GuruStatus (copier's Guru status)
  LEFT JOIN V_Liabilities (copier equity at @DateID)
  → #copiertable

SP_AML_PI_Abuse
  DELETE FROM BI_DB_AML_PI_Abuse_CopierTable WHERE @DateID > @Past6MonthsINT
  INSERT INTO BI_DB_AML_PI_Abuse_CopierTable (...) FROM #copiertable
       ↓
  BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable
```

## DDL Columns Not Populated

These 4 columns exist in the DDL but are NOT included in the SP INSERT statement — they are always NULL:

| Column | DDL Type | Status |
|--------|---------|--------|
| NumberOfSessionID | int | NEVER POPULATED — orphaned DDL column |
| HasActiveCopy | int | NEVER POPULATED — orphaned DDL column |
| NumOfCountry | int | NEVER POPULATED — orphaned DDL column |
| NumOfCity | int | NEVER POPULATED — orphaned DDL column |

## AUC Calculation

`AUC = ISNULL(Cash,0) + ISNULL(Investment,0) + ISNULL(PnL,0) + ISNULL(DetachedPosInvestment,0) + ISNULL(Dit_PnL,0)`

All components from `general.etoroGeneral_History_GuruCopiers`. Represents total money the copier has allocated to copying this PI (open positions + unrealized PnL + detached positions).

## Popular Investor (Parent) Population Criteria

The SP filters `#pis` (the PI base) from `Fact_SnapshotCustomer` at @DateID:
- `GuruStatusID >= 2` (Cadet and above — enrolled in the Popular Investor program)
- `IsValidCustomer = 1`
- `VerificationLevelID = 3`
- `IsDepositor = 1`

All copiers in the CopierTable are copying a PI who met these criteria on the run date.

## Related Tables Written by Same SP (SP_AML_PI_Abuse)

| Table | Pattern |
|-------|---------|
| BI_DB_dbo.BI_DB_AML_PI_Abuse | TRUNCATE + INSERT (main PI analytics table) |
| BI_DB_dbo.BI_DB_AML_PI_Abuse_SameIP | TRUNCATE + INSERT |
| BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_PI_Side | TRUNCATE + INSERT |
| BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copy_Side | TRUNCATE + INSERT |
| BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_AS_PI | TRUNCATE + INSERT |
| BI_DB_dbo.BI_DB_AML_PI_Abuse_DeviceID_Copiers | TRUNCATE + INSERT |
| BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_PI_Side | TRUNCATE + INSERT |
| BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Copy_Side | TRUNCATE + INSERT |
| BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_as_pi | TRUNCATE + INSERT |
| BI_DB_dbo.BI_DB_AML_PI_Abuse_FID_Same_Copy | TRUNCATE + INSERT |
| **BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable** | **DELETE ALL + INSERT (this table)** |

---
*Generated: 2026-04-22 | Object: BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable | Writer SP: SP_AML_PI_Abuse*
