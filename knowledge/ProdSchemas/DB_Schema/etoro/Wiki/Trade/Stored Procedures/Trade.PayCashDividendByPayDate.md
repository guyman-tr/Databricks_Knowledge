# Trade.PayCashDividendByPayDate

> Processes cash dividend corporate action payments for a specific payment date, reading Apex EXT922 dividend report activity and queuing balance adjustment commands via the CashPaymentStatus pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentDate (payment run scope) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Cash dividends are corporate actions where companies distribute dividend payments to holders of their instruments. This procedure is the daily batch runner for EXT922 dividend processing: it reads the latest Apex SOD (Start-Of-Day) file for the given payment date, identifies which customers are owed dividend payments, and queues those payments as balance adjustment commands.

Unlike `Trade.PayCashAirdropByPayDateAndTerminalID` (EXT869, TerminalID-scoped), this procedure processes ALL dividend records across all instruments for the payment date in a single run - there is no `@TerminalID` filter. The `CorporateActionTypeID` is hard-coded to 3 (Cash Dividend). The amount sign is inverted: `DividendInterest * -1` because dividend amounts in the EXT922 report are stored as debits but must be applied as credits to customer balances.

The procedure uses the same `Trade.CashingOperationMonitor` idempotency state machine as the airdrop procedure, enabling safe retries: successful runs are skipped, in-progress runs are blocked, failed runs retry only the failed records.

Data flow: Check monitor state -> read EXT922 SOD file -> read dividend activity -> insert CashingOperationMonitor record -> insert CashPaymentStatus rows (CMD = Customer.SetBalanceClameFee call string) -> mark monitor as complete.

---

## 2. Business Logic

### 2.1 CashingOperationMonitor State Machine

**What**: Guards against duplicate runs and enables safe retry of failed batches.

**Columns/Parameters Involved**: `Trade.CashingOperationMonitor.StatusID`, `Trade.CashingOperationMonitor.DataSource`, `Trade.CashingOperationMonitor.PaymentDate`

**Rules**:
- SELECT TOP 1 ... ORDER BY ID DESC to get the latest monitor record for DataSource='EXT922' AND PaymentDate=@PaymentDate
- No TerminalID filter (TerminalID IS NULL for dividend runs)
- StatusID=3 (EndedSuccessfully): RETURN - already processed, skip
- StatusID=1 (InProcess): RAISERROR - block concurrent execution
- StatusID=2 (ExecutedNone): full re-insert
- StatusID=-1 (EndedWithError): re-insert only the previously-failed records (StatusID=-1 in CashPaymentStatus)
- No prior record: full fresh insert

**Diagram**:
```
Monitor state check (DataSource='EXT922', no TerminalID):
  StatusID=3 -> RETURN (already done)
  StatusID=1 -> RAISERROR (blocked)
  StatusID=2 -> full re-insert
  StatusID=-1 -> partial re-insert (failed only)
  NULL -> fresh insert
```

### 2.2 SOD File and EXT922 Activity Resolution

**What**: Locates the latest Apex EXT922 SOD file and reads dividend records from it.

**Columns/Parameters Involved**: `Trade.ApexSYN_SodFiles.BlobUrl`, `Trade.ApexSYN_EXT922_DividendReport.DividendInterest`

**Rules**:
- SELECT TOP 1 BlobUrl FROM Trade.ApexSYN_SodFiles WHERE ApexFormat=922 AND BlobUrl LIKE '%_ETRO_%' AND ProcessDate <= @PaymentDate ORDER BY ProcessDate DESC
- JOIN Trade.ApexSYN_EXT922_DividendReport ON BlobUrl to get dividend records
- Amount = DividendInterest * -1 (sign inversion: EXT922 stores debits, payments are credits)

### 2.3 Hard-coded CorporateActionTypeID

**What**: Dividend payments are always categorized as Cash Dividend (type 3).

**Columns/Parameters Involved**: `Trade.CashPaymentStatus.CorporateActionTypeID`

**Rules**:
- CorporateActionTypeID = 3 hard-coded (Cash Dividend)
- Unlike airdrop procedure, no call to Trade.GetCorporateActionType - the type is fixed
- DataSource = 'EXT922' (distinguishes from 'EXT869' airdrop and 'MANUAL' paths)

### 2.4 Payment Command Construction and Duplicate Detection

**What**: Builds CashPaymentStatus rows; skips records already present for this run scope.

**Columns/Parameters Involved**: `Trade.CashPaymentStatus.CMD`, `Trade.CashPaymentStatus.ApexID`, `Trade.CashPaymentStatus.PaymentDate`

**Rules**:
- CMD = formatted string: 'EXEC Customer.SetBalanceClameFee @CID={CID}, @Amount={Amount}, ...'
- LEFT JOIN on existing CashPaymentStatus (same ApexID + PaymentDate + InstrumentID + ABS(Amount)) WHERE existing.ID IS NULL
- Prevents re-inserting already-successful records during partial retries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentDate | DATE | NO | - | CODE-BACKED | The date for which to process cash dividend payments. Used to filter CashingOperationMonitor (existing run check), ApexSYN_SodFiles (ProcessDate<=@PaymentDate), and as PaymentDate in CashPaymentStatus records. All dividend records across all instruments for this date are processed in a single run. |
| 2 | @UserName | VARCHAR(255) | NO | - | CODE-BACKED | The operator username initiating this payment run. Stored in CashingOperationMonitor and CashPaymentStatus records for audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentDate | Trade.CashingOperationMonitor | READ + INSERT + UPDATE | State machine: checks prior run status; inserts InProcess record; marks complete at end |
| @PaymentDate | Trade.ApexSYN_SodFiles | READ | Finds the latest EXT922 SOD file BlobUrl for the payment date |
| BlobUrl | Trade.ApexSYN_EXT922_DividendReport | READ | Reads dividend records (DividendInterest) from the resolved SOD file |
| Internal | Trade.CashPaymentStatus | INSERT (WRITE) | Writes dividend payment commands (CMD=Customer.SetBalanceClameFee) for downstream execution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PayCashDividendByPayDate (procedure)
+-- Trade.CashingOperationMonitor (table) [READ + INSERT + UPDATE - idempotency state machine]
+-- Trade.ApexSYN_SodFiles (table) [READ - find latest EXT922 blob for payment date]
+-- Trade.ApexSYN_EXT922_DividendReport (table) [READ - dividend payment records from SOD file]
+-- Trade.CashPaymentStatus (table) [WRITE - queued payment commands]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CashingOperationMonitor | Table | Idempotency guard: reads prior run state; inserts new InProcess record; updates to Ended* at completion |
| Trade.ApexSYN_SodFiles | Table | Finds the latest EXT922 SOD file blob URL for the given payment date |
| Trade.ApexSYN_EXT922_DividendReport | Table | Source of dividend records (DividendInterest amounts) associated with the resolved SOD file |
| Trade.CashPaymentStatus | Table | Output: payment commands queued for downstream balance adjustment execution |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DataSource='EXT922' | Design constant | Hard-coded data source tag distinguishes dividends (EXT922) from airdrops (EXT869) and manual payments |
| CorporateActionTypeID=3 | Design constant | Cash Dividend type is hard-coded - no dynamic type resolution (unlike airdrop which calls GetCorporateActionType) |
| Amount = DividendInterest * -1 | Sign convention | EXT922 stores dividend amounts as debits; sign is inverted to credit customer balances |
| No TerminalID filter | Design | Dividend runs process all instruments for the date; no per-terminal scoping (unlike EXT869 airdrop) |
| BlobUrl LIKE '%_ETRO_%' | Filter | Only processes eToro-tagged SOD files (excludes non-eToro Apex files in the sync table) |

---

## 8. Sample Queries

### 8.1 Process cash dividend payments for a payment date
```sql
EXEC Trade.PayCashDividendByPayDate
    @PaymentDate = '2026-03-15',
    @UserName    = 'ops.dividends';
```

### 8.2 Check run status in the monitor
```sql
SELECT TOP 5
    ID,
    DataSource,
    PaymentDate,
    TerminalID,
    StatusID,
    CreatedAt,
    UpdatedAt
FROM Trade.CashingOperationMonitor WITH (NOLOCK)
WHERE DataSource = 'EXT922'
  AND PaymentDate = '2026-03-15'
ORDER BY ID DESC;
```

### 8.3 Check queued dividend payments
```sql
SELECT TOP 20
    ID,
    ApexID,
    InstrumentID,
    Amount,
    PaymentDate,
    CorporateActionTypeID,
    StatusID,
    CMD
FROM Trade.CashPaymentStatus WITH (NOLOCK)
WHERE DataSource = 'EXT922'
  AND PaymentDate = '2026-03-15'
ORDER BY ID DESC;
```

### 8.4 Compare EXT922 source amounts vs queued (sign check)
```sql
-- Source amounts in EXT922 report (should be opposite sign from CashPaymentStatus)
SELECT TOP 10
    dr.ApexID,
    dr.DividendInterest AS SourceAmount,  -- stored as debit
    cs.Amount           AS QueuedAmount   -- stored as credit (DividendInterest * -1)
FROM Trade.ApexSYN_EXT922_DividendReport dr WITH (NOLOCK)
JOIN Trade.CashPaymentStatus cs WITH (NOLOCK)
    ON cs.ApexID = dr.ApexID
    AND cs.DataSource = 'EXT922'
    AND cs.PaymentDate = '2026-03-15';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 additional analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PayCashDividendByPayDate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PayCashDividendByPayDate.sql*
