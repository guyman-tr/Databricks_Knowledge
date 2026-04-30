# BackOffice.UpsertIntoAggregationTablesAction

> Core aggregation engine: processes a batch of credit events (by CreditID range) and login activity, computing deltas that are upserted into three customer aggregation tables (AllTime, DayToDay, MonthToDate) and advancing the high-water mark in Dictionary.AggregationLastValue.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LastCreditID / @MaxCreditID - CreditID range window for incremental processing |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpsertIntoAggregationTablesAction` is the core incremental aggregation engine for eToro's customer financial summary system. It is called continuously by a scheduled job (orchestrated via `BackOffice.UpsertIntoAggregationTables`) that passes a CreditID window and a login cutoff timestamp. The SP processes that slice of data and merges the resulting financial deltas into three customer aggregation tables:

- **BackOffice.CustomerAllTimeAggregatedData_1** - lifetime totals per CID
- **BackOffice.CustomerDTDAggregatedData_1** - day-to-day totals per CID per date
- **BackOffice.CustomerMTDAggregatedData_1** - month-to-date totals per CID per year/month

This procedure is the single writer for these three tables. The tables serve as the pre-aggregated financial summary that powers back-office reporting, Salesforce integrations (via LastOccurredTriggerToSF), and customer segmentation for the eToro Club/VIP system.

The design is incremental: rather than recomputing totals from scratch, each call processes only new credit events (CreditID > @LastCreditID) and advances the high-water mark. This allows the job to run continuously with minimal database load.

**Evolution**: The procedure has been extensively modified since 2015 (13+ tracked changes). Key changes include: migration from dbo.STS_Audit_LoginHistory to SYN_STS_Audit_MIMO_GetUsersLogin_V (2022), switch from History.Credit to History.ActiveCredit for performance (2024), switch from History.ActiveCredit to Billing.Deposit for FTD dates (2025), removal of BonusOnlyCustomers handling (2023), and RealizedEquity now sourced from Customer.CustomerMoney (2020).

---

## 2. Business Logic

### 2.1 Part 002 - Build Unified Delta Temp Table

**What**: Builds `#LastMinAggFromAllBaseTables` - a unified view of all financial activity in the given CreditID range plus login activity, with pre-computed delta columns for each metric.

**Source 1 - Credit Events (financial deltas)**:
- Source: `History.ActiveCredit` WHERE `CreditID BETWEEN @LastCreditID AND @MaxCreditID` AND `CreditTypeID IN (1,2,3,4,5,6,7,8,9,13,14,15)`
- Grouped by CID and truncated Date (`DATEADD(dd,0,DATEDIFF(dd,0,Occurred))`)
- Delta columns by CreditTypeID:
  - `CreditTypeID=1` -> `TotalDepositDelta` (from TotalCashChange)
  - `CreditTypeID=2` -> `TotalCashoutDelta` (full withdrawal amount from ProcessedWithdraws subquery)
  - `CreditTypeID=3, 13` -> `TotalInvestmentDelta` (negated - stored as positive outflow)
  - `CreditTypeID=4` -> `TotalProfitDelta`, `TotalCommissionDelta`, `TotalVolumeDelta`, `TotalLotDelta`, `TotalPositionCountDelta` (joined to History.Position + Trade.ProviderToInstrument)
  - `CreditTypeID=5` -> `TotalChampWinDelta`
  - `CreditTypeID=6` -> `TotalCompensationDelta`
  - `CreditTypeID=7` -> `TotalBonusDelta`
  - `CreditTypeID=8, 15 (positive TotalCashChange)` -> `TotalReverseCashoutDelta`
  - `CreditTypeID=9, 15 (negative TotalCashChange)` -> `TotalCashoutRequestDelta`
  - `CreditTypeID=14` -> `TotalEndOfWeekFeeDelta` (negated)
- `RealizedEquityLastChange`: MAX(Occurred) for the CID/Date combination
- `LastRealizedEquity`: Uses MAX/CONCAT trick (`Stuff(Max(Concat(Format(GetDate(),...),RealizedEquity))...`)

**Source 2 - Login Activity**:
- Source: `dbo.SYN_STS_Audit_MIMO_GetUsersLogin_V` WHERE `LastLogin BETWEEN @LastLogin AND @CurrentStart`, TOP 2000
- Joined to `Customer.CustomerStatic` ON GCID to get CID
- Aggregated by CID, Date: `LastLoggedInOn`, `LastClientIp` (via MAX/CONCAT trick)
- All financial deltas set to 0.00 (login rows have no financial impact)

**UNION**: Sources 1 and 2 are unioned into `#LastMinAggFromAllBaseTables`. Since one CID may appear in both sources, Part 003 re-aggregates.

### 2.2 Part 003 - Re-Aggregate Into 3 Matching Source Temp Tables

**What**: The UNION temp table may have duplicate CID/Date combinations. Re-aggregate into three tables matching the structure of the target aggregation tables.

- `#LastMinAggSingleTable` (CID + Date): For `CustomerDTDAggregatedData_1` upsert
- `#Source_For_CustomerAllTimeAggregatedData` (CID only): For `CustomerAllTimeAggregatedData_1` upsert. Also has `LastLoggedInOn`, `LastClientIp` (for tracking last login).
- `#Source_For_CustomerMTDAggregatedData` (CID + Year + Month): For `CustomerMTDAggregatedData_1` upsert

### 2.3 Part 004 - UPSERT Into 3 Aggregation Tables (Transaction)

**What**: Within a SET XACT_ABORT ON; BEGIN TRY/BEGIN TRAN block, applies the deltas to all three aggregation tables.

**Target 1 - BackOffice.CustomerAllTimeAggregatedData_1**:
- UPDATE: `TotalX = TotalX + TotalXDelta` for all 14 financial metrics
- `LastRealizedEquity = cc.RealizedEquity` (from Customer.CustomerMoney, not computed delta)
- `RealizedEquityLastChange = ISNULL(source.RealizedEquityLastChange, existing)` - preserves if no new equity event
- `LastOccurredTriggerToSF`: Set to GETUTCDATE() if Deposit/Bonus/Cashout/Compensation delta != 0
- INSERT for new CIDs (LEFT JOIN with WHERE target.CID IS NULL)

**Milestone dates (CustomerAllTimeAggregatedData_1 only)**:
- `FirstTimeDepositAttemptDate`: From Billing.Deposit MIN(PaymentDate) WHERE FirstTimeDepositAttemptDate IS NULL, 7-day lookback
- `FirstTimeDepositSuccessDate`: From Billing.Deposit WHERE PaymentStatusID=2 AND IsFTD=1, 7-day lookback

**Target 2 - BackOffice.CustomerDTDAggregatedData_1**:
- UPSERT keyed on (CID, Date) - day-to-day granularity
- Same delta accumulation as AllTime but without login, LastClientIp, or LastLoggedInOn columns
- `LastRealizedEquity = cc.RealizedEquity` (from Customer.CustomerMoney)

**Target 3 - BackOffice.CustomerMTDAggregatedData_1**:
- UPSERT keyed on (CID, Year, Month) - month-to-date granularity
- Same delta accumulation; no RealizedEquity or login tracking
- Guard: `EXISTS (SELECT * FROM Customer.CustomerStatic WHERE CID=...)` on INSERT to prevent ghost CIDs

**BonusOnlyCustomers cleanup**:
- After upserts, DELETE from `BackOffice.BonusOnlyCustomers` for customers who now have real activity (TotalDeposit != 0 or significant compensation) in the last 7 days from CustomerMIMOAllTimeAggregatedData

### 2.4 Part 005 - Advance High-Water Mark

**What**: Updates Dictionary.AggregationLastValue to record the last processed position.

**Rules**:
- Updates row WHERE TableName='History.Credit' AND IncreasingColumnName='CreditID': sets `LastSampleDateTime=@MaxCreditOccurred, LastSampleID=@MaxCreditID`
- Updates row WHERE TableName='History.Login' AND IncreasingColumnName='LoggedOut': sets `LastSampleDateTime=@MaxLastLogin` (only if @MaxLastLogin IS NOT NULL)
- @MaxLastLogin = MAX(LastLoggedInOn) from `#STS` temp table built in Part 002

### 2.5 Execution Log

At the beginning of each call, inserts a row into `Dictionary.AggregationLastValue_History` with execution time and batch parameters. Used for troubleshooting/auditing aggregation runs.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LastCreditID | bigint | NO | - | CODE-BACKED | The last CreditID processed in the previous batch (exclusive lower bound). Credits with CreditID > @LastCreditID are included in this batch. Sourced from Dictionary.AggregationLastValue WHERE TableName='History.Credit'. |
| 2 | @MaxCreditID | bigint | NO | - | CODE-BACKED | The upper bound of the CreditID range for this batch (inclusive). Credits with CreditID <= @MaxCreditID are included. Set by the caller to limit batch size. After processing, @MaxCreditID is written back as LastSampleID in Dictionary.AggregationLastValue. |
| 3 | @MaxCreditOccurred | datetime | NO | - | CODE-BACKED | The Occurred timestamp of the credit with CreditID = @MaxCreditID. Used to update the LastSampleDateTime high-water mark in Dictionary.AggregationLastValue and logged to Dictionary.AggregationLastValue_History. |
| 4 | @LastLogin | datetime | NO | - | CODE-BACKED | The last login timestamp processed in the previous batch. Logins with LastLogin > @LastLogin AND <= GETUTCDATE() at execution time are included. Sources from dbo.SYN_STS_Audit_MIMO_GetUsersLogin_V, max 2000 rows per call. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LastCreditID / @MaxCreditID | History.ActiveCredit | SELECT source | Core credit event stream - financial deltas |
| CreditTypeID=4 | History.Position | LEFT JOIN | Profit, commission, volume per closed position |
| CreditTypeID=4 | Trade.ProviderToInstrument | LEFT JOIN | UnitMargin for volume computation |
| CreditTypeID=2 | History.Credit | LEFT JOIN (subquery) | Cashout full amount from paired credit rows |
| @LastLogin | dbo.SYN_STS_Audit_MIMO_GetUsersLogin_V | SELECT source | Login activity for LastLoggedInOn/LastClientIp |
| GCID | Customer.CustomerStatic | JOIN | Maps GCID from login data to CID |
| CID | Customer.CustomerMoney | JOIN | LastRealizedEquity source (AllTime and DayToDay) |
| FTD dates | Billing.Deposit | SELECT subquery | FirstTimeDepositAttemptDate and FirstTimeDepositSuccessDate milestones |
| CID | [BackOffice.CustomerAllTimeAggregatedData_1](../Tables/BackOffice.CustomerAllTimeAggregatedData_1.md) | UPDATE + INSERT (upsert) | Lifetime financial totals per CID |
| CID + Date | BackOffice.CustomerDTDAggregatedData_1 | UPDATE + INSERT (upsert) | Day-to-day financial totals per CID/Date |
| CID + Year + Month | BackOffice.CustomerMTDAggregatedData_1 | UPDATE + INSERT (upsert) | Month-to-date financial totals per CID/Year/Month |
| CID | BackOffice.BonusOnlyCustomers | DELETE | Removes customers who now have real financial activity |
| Batch params | Dictionary.AggregationLastValue | UPDATE | Advances high-water marks (CreditID, Login timestamp) |
| Execution log | Dictionary.AggregationLastValue_History | INSERT | Troubleshooting log of each batch execution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpsertIntoAggregationTables | - | EXEC callee | Production orchestrator: reads high-water mark from Dictionary.AggregationLastValue, batches CreditID ranges, calls this SP in a loop |
| BackOffice.UpsertIntoAggregationTables_Test | - | EXEC callee (test) | Test orchestrator: calls the `_Test` variant but uses the same batching logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpsertIntoAggregationTablesAction (procedure)
+-- History.ActiveCredit (table) [SELECT: CreditID range batch]
+-- History.Credit (table) [SELECT: cashout full amount subquery]
+-- History.Position (table) [LEFT JOIN: NetProfit/Commission/Volume for CreditTypeID=4]
+-- Trade.ProviderToInstrument (table) [LEFT JOIN: UnitMargin for volume]
+-- dbo.SYN_STS_Audit_MIMO_GetUsersLogin_V (view/synonym) [SELECT: login events]
+-- Customer.CustomerStatic (table) [JOIN: GCID -> CID for login data]
+-- Customer.CustomerMoney (table) [JOIN: RealizedEquity source]
+-- Billing.Deposit (table) [SELECT: FTD milestone dates]
+-- BackOffice.CustomerAllTimeAggregatedData_1 (table) [UPSERT: lifetime totals]
+-- BackOffice.CustomerDTDAggregatedData_1 (table) [UPSERT: day-to-day totals]
+-- BackOffice.CustomerMTDAggregatedData_1 (table) [UPSERT: month-to-date totals]
+-- BackOffice.BonusOnlyCustomers (table) [DELETE: cleanup]
+-- Dictionary.AggregationLastValue (table) [UPDATE: high-water mark]
+-- Dictionary.AggregationLastValue_History (table) [INSERT: execution log]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table | SELECT financial events for CreditID range |
| History.Credit | Table | Subquery for cashout full amount (paired credits) |
| History.Position | Table | LEFT JOIN on PositionID for profit/volume/commission |
| Trade.ProviderToInstrument | Table | LEFT JOIN for UnitMargin in volume calculation |
| dbo.SYN_STS_Audit_MIMO_GetUsersLogin_V | View/Synonym | SELECT TOP 2000 login events since @LastLogin |
| Customer.CustomerStatic | Table | JOIN on GCID to resolve CID for login data |
| Customer.CustomerMoney | Table | JOIN for current RealizedEquity (AllTime + DayToDay) |
| Billing.Deposit | Table | Subquery for FirstTimeDepositAttemptDate/SuccessDate milestones |
| [BackOffice.CustomerAllTimeAggregatedData_1](../Tables/BackOffice.CustomerAllTimeAggregatedData_1.md) | Table | UPSERT target: lifetime customer financial totals |
| BackOffice.CustomerDTDAggregatedData_1 | Table | UPSERT target: day-to-date customer financial totals |
| BackOffice.CustomerMTDAggregatedData_1 | Table | UPSERT target: month-to-date customer financial totals |
| BackOffice.BonusOnlyCustomers | Table | DELETE: remove customers with real deposit/cashout activity |
| Dictionary.AggregationLastValue | Table | UPDATE: advance CreditID and Login high-water marks |
| Dictionary.AggregationLastValue_History | Table | INSERT: execution log for troubleshooting |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertIntoAggregationTables | Procedure | Production orchestrator that calls this SP in batches |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Internal temp tables use clustered indexes for JOIN performance:
- `#LastMinAggFromAllBaseTables2_1([Date],CID)` - clustered, page-compressed
- `#Source_For_CustomerAllTimeAggregatedData(CID)` - unique clustered
- `IX_STS` on `#STS(Gcid)` - for GCID join to CustomerStatic

### 7.2 Constraints

- `SET XACT_ABORT ON` before the main upsert transaction
- `BEGIN TRY / BEGIN TRAN ... COMMIT TRAN` / `BEGIN CATCH ROLLBACK / RAISERROR`
- `OPTION (MAXDOP 1)` and `OPTION (RECOMPILE)` hints on key queries to prevent bad plan selection
- Login batch cap: TOP 2000 from SYN_STS_Audit_MIMO_GetUsersLogin_V per call

**Performance architecture**: The incremental window-based approach (CreditID range + datetime login cutoff) ensures each call processes only new events. The orchestrator batches these in increments of ~6000 credits, making the system near-real-time.

---

## 8. Sample Queries

### 8.1 Check the current high-water mark

```sql
SELECT TableName, IncreasingColumnName, LastSampleID, LastSampleDateTime
FROM Dictionary.AggregationLastValue WITH (NOLOCK)
WHERE TableName IN ('History.Credit', 'History.Login');
```

### 8.2 Manually run a batch with specific parameters (DBA/debug use only)

```sql
DECLARE @LastCreditID BIGINT = 1533630475,
        @MaxCreditID  BIGINT = 1533630499,
        @MaxCreditOccurred DATETIME = '20181105 09:10',
        @LastLogin DATETIME = '20181105 09:00';

EXEC BackOffice.UpsertIntoAggregationTablesAction
    @LastCreditID,
    @MaxCreditID,
    @MaxCreditOccurred,
    @LastLogin;
```

### 8.3 Check execution history

```sql
SELECT TOP 20 EXECUTION_TIME, LastCreditID, LastLoggedOut, MaxCreditID, MaxCreditOccurred
FROM Dictionary.AggregationLastValue_History WITH (NOLOCK)
ORDER BY EXECUTION_TIME DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| FB-28653 | Internal | Initial version (2015) |
| FB-50280 | Internal | Moved job to secondary DB, synonyms for primary DB cross-references (2018) |
| FB-50710 | Internal | Added LastLoggedInOn, LastClientIp to CustomerAllTimeAggregatedData (2018) |
| RD-2795/2796 | Jira | Added GatewayAppId=1 filter to STS login source (2019) |
| RD-4162/4877 | Jira | Club Manager status management - added realized equity to end-of-day aggregation (2019) |
| DBA-1357 | Jira | Fixed LastOccurredTriggerToSF to use GETUTCDATE() (2022) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 6 Internal/Jira (from DDL comments) | Procedures: 1 caller analyzed (UpsertIntoAggregationTables) | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpsertIntoAggregationTablesAction | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpsertIntoAggregationTablesAction.sql*
