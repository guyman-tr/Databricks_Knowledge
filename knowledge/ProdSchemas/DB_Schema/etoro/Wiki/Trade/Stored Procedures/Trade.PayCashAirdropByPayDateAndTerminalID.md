# Trade.PayCashAirdropByPayDateAndTerminalID

> Processes a cash airdrop corporate action payment for a specific payment date and terminal (instrument type), reading Apex EXT869 SOD file activity and queuing balance adjustment commands via the CashPaymentStatus pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentDate + @TerminalID (payment run scope) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Cash airdrops are corporate actions where a company distributes cash to holders of a particular instrument - distinct from regular dividends (EXT922). This procedure is the daily batch runner for EXT869 airdrop processing: it reads the latest Apex SOD (Start-Of-Day) file for the given payment date and terminal, identifies which customers are owed airdrop payments, and queues those payments as balance adjustment commands.

The `@TerminalID` parameter identifies the specific airdrop program/instrument type. The procedure resolves a `CorporateActionID` and description from this terminal via `Trade.GetCorporateActionType`. The resolved `CorporateActionID` is included in the payment record for downstream tracking.

The procedure is idempotent and retry-safe through the `Trade.CashingOperationMonitor` state machine:
- If a prior run completed successfully (StatusID=3): skip entirely (no duplicate payments)
- If a prior run is in progress (StatusID=1): block (prevents concurrent execution)
- If a prior run ended with error (StatusID=-1): retry only the failed records
- If a prior run executed nothing (StatusID=2): retry all records

Data flow: Resolve corporate action type -> check monitor state -> read SOD file BlobUrl -> read EXT869 activity -> insert CashingOperationMonitor record -> insert CashPaymentStatus rows (CMD = Customer.SetBalanceClameFee call string) -> mark monitor as complete.

---

## 2. Business Logic

### 2.1 CashingOperationMonitor State Machine

**What**: Guards against duplicate runs and enables safe retry of failed batches.

**Columns/Parameters Involved**: `Trade.CashingOperationMonitor.StatusID`, `Trade.CashingOperationMonitor.DataSource`, `Trade.CashingOperationMonitor.PaymentDate`

**Rules**:
- SELECT TOP 1 ... ORDER BY ID DESC to get the latest monitor record for DataSource='EXT869' AND PaymentDate=@PaymentDate AND TerminalID=@TerminalID
- StatusID=3 (EndedSuccessfully): RETURN - already processed, skip
- StatusID=1 (InProcess): RAISERROR (another process is running) - block
- StatusID=2 (ExecutedNone): re-insert all records (retry from blank slate)
- StatusID=-1 (EndedWithError): re-insert only the failed records (StatusID=-1 in CashPaymentStatus from the prior run)
- No prior record: full fresh insert

**Diagram**:
```
Monitor state check:
  StatusID=3 -> RETURN (already done)
  StatusID=1 -> RAISERROR (blocked)
  StatusID=2 -> full re-insert
  StatusID=-1 -> partial re-insert (failed only)
  NULL -> fresh insert
```

### 2.2 SOD File Resolution

**What**: Locates the latest Apex EXT869 SOD file blob for the payment date.

**Columns/Parameters Involved**: `Trade.ApexSYN_SodFiles.BlobUrl`, `Trade.ApexSYN_SodFiles.ApexFormat`, `Trade.ApexSYN_SodFiles.ProcessDate`

**Rules**:
- SELECT TOP 1 BlobUrl FROM Trade.ApexSYN_SodFiles
- WHERE ApexFormat=869 AND BlobUrl LIKE '%_ETRO_%' AND ProcessDate <= @PaymentDate
- ORDER BY ProcessDate DESC (get the most recent file up to the payment date)
- The BlobUrl is used to JOIN into Trade.ApexSYN_EXT869_CashActivity to get the actual payment records

### 2.3 Payment Record Construction

**What**: Builds CashPaymentStatus rows from the EXT869 activity for the resolved SOD file.

**Columns/Parameters Involved**: `Trade.ApexSYN_EXT869_CashActivity`, `Trade.CashPaymentStatus.CMD`, `Trade.CashPaymentStatus.ApexID`, `Trade.CashPaymentStatus.InstrumentID`

**Rules**:
- JOIN ApexSYN_EXT869_CashActivity ON BlobUrl (from SOD file resolution)
- Amount comes directly from EXT869_CashActivity (positive for airdrop credits)
- CMD field = formatted string: 'EXEC Customer.SetBalanceClameFee @CID={CID}, @Amount={Amount}, ...'
- DataSource='EXT869', PaymentDate=@PaymentDate, TerminalID=@TerminalID
- CorporateActionID from Trade.GetCorporateActionType result

### 2.4 Duplicate Detection

**What**: Prevents inserting the same payment record twice for the same customer/date/instrument/amount.

**Columns/Parameters Involved**: `Trade.CashPaymentStatus.ApexID`, `Trade.CashPaymentStatus.PaymentDate`, `Trade.CashPaymentStatus.InstrumentID`, `Trade.CashPaymentStatus.Amount`

**Rules**:
- LEFT JOIN on existing CashPaymentStatus rows (same ApexID + PaymentDate + InstrumentID + ABS(Amount))
- WHERE existing.ID IS NULL (only insert rows not already present)
- This protects against re-inserting already-successful records during partial retries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentDate | DATE | NO | - | CODE-BACKED | The date for which to process airdrop payments. Used to filter CashingOperationMonitor (existing run check), ApexSYN_SodFiles (ProcessDate<=@PaymentDate), and as PaymentDate in CashPaymentStatus records. |
| 2 | @TerminalID | VARCHAR(30) | NO | - | CODE-BACKED | Identifies the airdrop program/instrument type. Passed to Trade.GetCorporateActionType to resolve CorporateActionID and Description. Also used as the TerminalID filter on CashingOperationMonitor and CashPaymentStatus. |
| 3 | @UserName | VARCHAR(255) | NO | - | CODE-BACKED | The operator username initiating this payment run. Stored in CashingOperationMonitor and CashPaymentStatus records for audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TerminalID | Trade.GetCorporateActionType | EXEC (CALL) | Resolves CorporateActionID and Description from the terminal identifier |
| @PaymentDate/@TerminalID | Trade.CashingOperationMonitor | READ + INSERT + UPDATE | State machine: checks prior run status; inserts new monitor record; marks complete at end |
| @PaymentDate | Trade.ApexSYN_SodFiles | READ | Finds the latest EXT869 SOD file BlobUrl for the payment date |
| BlobUrl | Trade.ApexSYN_EXT869_CashActivity | READ | Reads cash airdrop activity records from the resolved SOD file |
| Internal | Trade.CashPaymentStatus | INSERT (WRITE) | Writes payment commands (CMD=Customer.SetBalanceClameFee) for downstream execution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PayCashAirdropByPayDateAndTerminalID (procedure)
+-- Trade.GetCorporateActionType (procedure) [EXEC - resolve CorporateActionID from TerminalID]
+-- Trade.CashingOperationMonitor (table) [READ + INSERT + UPDATE - idempotency state machine]
+-- Trade.ApexSYN_SodFiles (table) [READ - find latest EXT869 blob for payment date]
+-- Trade.ApexSYN_EXT869_CashActivity (table) [READ - airdrop payment records from SOD file]
+-- Trade.CashPaymentStatus (table) [WRITE - queued payment commands]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCorporateActionType | Stored Procedure | Resolves CorporateActionID and description from @TerminalID input |
| Trade.CashingOperationMonitor | Table | Idempotency guard: reads prior run state; inserts new InProcess record; updates to Ended* at completion |
| Trade.ApexSYN_SodFiles | Table | Finds the latest EXT869 SOD file blob URL for the given payment date |
| Trade.ApexSYN_EXT869_CashActivity | Table | Source of cash airdrop records associated with the resolved SOD file |
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
| DataSource='EXT869' | Design constant | Hard-coded data source tag distinguishes airdrop (869) from dividend (EXT922) payments |
| BlobUrl LIKE '%_ETRO_%' | Filter | Only processes eToro-tagged SOD files (excludes non-eToro Apex files in the sync table) |
| Idempotency via CashingOperationMonitor | Design | StatusID=3 -> skip; StatusID=1 -> block; StatusID=-1 -> retry failed only |
| ABS(Amount) in duplicate check | Design | Amount sign may vary; absolute value used for deduplication to handle sign normalization |
| CMD = Customer.SetBalanceClameFee string | Design | Payment execution is decoupled: this SP queues strings; a separate process executes them |

---

## 8. Sample Queries

### 8.1 Process airdrop payments for a specific date and terminal
```sql
EXEC Trade.PayCashAirdropByPayDateAndTerminalID
    @PaymentDate = '2026-03-15',
    @TerminalID  = 'AIRDROP_ETH',
    @UserName    = 'ops.team';
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
WHERE DataSource = 'EXT869'
  AND PaymentDate = '2026-03-15'
ORDER BY ID DESC;
```

### 8.3 Check queued payments from this run
```sql
SELECT TOP 20
    ID,
    ApexID,
    InstrumentID,
    Amount,
    PaymentDate,
    TerminalID,
    StatusID,
    CMD
FROM Trade.CashPaymentStatus WITH (NOLOCK)
WHERE DataSource = 'EXT869'
  AND PaymentDate = '2026-03-15'
ORDER BY ID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (GetCorporateActionType) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PayCashAirdropByPayDateAndTerminalID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PayCashAirdropByPayDateAndTerminalID.sql*
