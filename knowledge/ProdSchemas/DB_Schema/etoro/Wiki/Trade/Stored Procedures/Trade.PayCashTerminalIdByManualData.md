# Trade.PayCashTerminalIdByManualData

> Processes cash corporate action payments from manually-provided data (no Apex SOD file), validating each record and queuing balance adjustment commands via the CashPaymentStatus pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentDate + @TerminalID + @CashPaymentsTbl (payment run scope) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When Apex SOD files are unavailable, delayed, or when operations need to make manual corporate action adjustments, this procedure handles the payment processing using a caller-supplied table of records. Unlike `Trade.PayCashAirdropByPayDateAndTerminalID` (EXT869) and `Trade.PayCashDividendByPayDate` (EXT922), which read from synchronized Apex data, this procedure accepts a TVP (`@CashPaymentsTbl`) containing the manual payment data.

The procedure applies comprehensive validation on each input row before queuing:
- Customer resolution: CID and ApexID are mutually exclusive identifiers - the caller must provide exactly one
- ApexID validation: if provided, must exist in the system (resolved to CID internally)
- Instrument validation: InstrumentID and CUSIP are mutually exclusive - exactly one must be provided; CUSIP is resolved to InstrumentID
- Amount validation: must be non-zero (>= 0.01 or <= -0.01)

Notably, this procedure does NOT use the `Trade.CashingOperationMonitor` state machine. Each call creates a fresh InProcess record and inserts new CashPaymentStatus rows without checking for prior runs - the caller is responsible for ensuring the operation is not duplicated.

The `@ErrorMsg OUTPUT` parameter returns validation errors without raising exceptions, allowing the caller to handle failures gracefully.

Data flow: Validate input rows -> INSERT CashingOperationMonitor (InProcess) -> INSERT CashPaymentStatus rows (CMD=Customer.SetBalanceClameFee) for valid records -> return errors via @ErrorMsg for invalid records.

---

## 2. Business Logic

### 2.1 Customer Identification Validation

**What**: Each payment row must identify the customer using exactly one of CID or ApexID.

**Columns/Parameters Involved**: `Trade.CashPaymentsTbl.CID`, `Trade.CashPaymentsTbl.ApexID`

**Rules**:
- IF CID IS NOT NULL AND ApexID IS NOT NULL: error - cannot specify both
- IF CID IS NULL AND ApexID IS NULL: error - must specify one
- IF ApexID provided: resolve to CID internally (lookup against customer ApexID registry)
- IF resolved CID not found: error - ApexID does not exist in system
- Errors are accumulated into @ErrorMsg OUTPUT (not RAISERROR)

### 2.2 Instrument Identification Validation

**What**: Each payment row must identify the instrument using exactly one of InstrumentID or CUSIP.

**Columns/Parameters Involved**: `Trade.CashPaymentsTbl.InstrumentID`, `Trade.CashPaymentsTbl.CUSIP`

**Rules**:
- IF InstrumentID IS NOT NULL AND CUSIP IS NOT NULL: error - cannot specify both
- IF InstrumentID IS NULL AND CUSIP IS NULL: error - must specify one
- IF CUSIP provided: resolve to InstrumentID internally (lookup against instrument CUSIP registry)
- IF resolved InstrumentID not found: error - CUSIP does not match any active instrument
- IF InstrumentID provided: validated against existing instruments

### 2.3 Amount Validation

**What**: Payment amounts must be non-zero (positive or negative).

**Columns/Parameters Involved**: `Trade.CashPaymentsTbl.Amount`

**Rules**:
- IF Amount BETWEEN -0.01 AND 0.01 (exclusive): error - amount too small / zero
- Valid range: Amount >= 0.01 (credit) or Amount <= -0.01 (debit/clawback)
- Note: negative amounts are valid for clawbacks or corrections

### 2.4 No CashingOperationMonitor Retry Logic

**What**: Unlike Apex-based procedures, manual data runs do not check for prior executions.

**Columns/Parameters Involved**: `Trade.CashingOperationMonitor.StatusID`

**Rules**:
- Always inserts a fresh CashingOperationMonitor record with StatusID=1 (InProcess)
- Does NOT check for existing records at DataSource='MANUAL' + @PaymentDate + @TerminalID
- Caller is responsible for preventing duplicate manual payment runs
- Temporal table optimization comment (13/02/2022): internal implementation uses a temp table for batch processing

### 2.5 Payment Command Construction

**What**: Builds CashPaymentStatus rows with CMD strings for each validated payment.

**Columns/Parameters Involved**: `Trade.CashPaymentStatus.CMD`, `Trade.CashPaymentStatus.DataSource`

**Rules**:
- CMD = formatted string: 'EXEC Customer.SetBalanceClameFee @CID={CID}, @Amount={Amount}, ...'
- DataSource = 'MANUAL' (distinguishes from Apex-sourced payments)
- Only valid records are inserted; invalid rows are returned via @ErrorMsg
- @TerminalID is stored as TerminalID in CashPaymentStatus for correlation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentDate | DATE | NO | - | CODE-BACKED | The date for which to process manual payments. Stored as PaymentDate in CashingOperationMonitor and CashPaymentStatus records. |
| 2 | @TerminalID | VARCHAR(30) | NO | - | CODE-BACKED | Identifies the airdrop/corporate action program. Stored as TerminalID in CashPaymentStatus for downstream correlation. Unlike Apex procedures, does not call GetCorporateActionType - used as-is for labeling. |
| 3 | @UserName | VARCHAR(255) | NO | - | CODE-BACKED | The operator username initiating this manual payment run. Stored in CashingOperationMonitor and CashPaymentStatus records for audit trail. |
| 4 | @CashPaymentsTbl | Trade.CashPaymentsTbl READONLY | NO | - | CODE-BACKED | TVP containing the manual payment records. Each row must have: CID or ApexID (not both, not neither); InstrumentID or CUSIP (not both, not neither); Amount (>= 0.01 or <= -0.01). Invalid rows are reported via @ErrorMsg. |
| 5 | @ErrorMsg | VARCHAR(4000) OUTPUT | YES | NULL | CODE-BACKED | OUTPUT: accumulated validation error messages for records that failed validation. Returns NULL if all records passed. Caller checks this to detect partial failures. Errors do NOT raise exceptions - valid records are still processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CashPaymentsTbl.ApexID | Customer registry | READ | Resolves ApexID to CID for rows where ApexID is provided |
| @CashPaymentsTbl.CUSIP | Instrument registry | READ | Resolves CUSIP to InstrumentID for rows where CUSIP is provided |
| @PaymentDate/@TerminalID | Trade.CashingOperationMonitor | INSERT + UPDATE | Always inserts fresh InProcess record; updates to Ended* on completion. No prior-run check. |
| Internal | Trade.CashPaymentStatus | INSERT (WRITE) | Writes manual payment commands (CMD=Customer.SetBalanceClameFee) for valid input rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PayCashTerminalIdByManualData (procedure)
+-- Trade.CashingOperationMonitor (table) [INSERT + UPDATE - new run record, no prior-run check]
+-- Trade.CashPaymentStatus (table) [WRITE - queued payment commands for valid rows]
+-- Customer registry (implicit) [READ - ApexID to CID resolution]
+-- Instrument registry (implicit) [READ - CUSIP to InstrumentID resolution]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CashPaymentsTbl | User-Defined Table Type (TVP) | Input: caller-supplied table of payment records to process |
| Trade.CashingOperationMonitor | Table | Inserts a new InProcess run record; updates to EndedSuccessfully/EndedWithError on completion |
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
| DataSource='MANUAL' | Design constant | Hard-coded data source tag distinguishes manual payments from Apex-sourced (EXT869/EXT922) |
| CID XOR ApexID | Input validation | Exactly one customer identifier must be provided per row |
| InstrumentID XOR CUSIP | Input validation | Exactly one instrument identifier must be provided per row |
| Amount >= 0.01 or <= -0.01 | Input validation | Zero or near-zero amounts are rejected |
| @ErrorMsg OUTPUT (not RAISERROR) | Error handling | Validation errors accumulated and returned without raising exceptions |
| No CashingOperationMonitor check | Design difference | Manual runs do not retry from prior state - no state machine; caller owns idempotency |
| Temp table optimization (13/02/2022) | Performance | Internal implementation uses a temp table for batch processing efficiency |

---

## 8. Sample Queries

### 8.1 Process manual payments by CID and InstrumentID
```sql
DECLARE @Payments Trade.CashPaymentsTbl;
INSERT INTO @Payments (CID, InstrumentID, Amount)
VALUES (111222, 7, 50.00),   -- credit $50 for instrument 7
       (333444, 12, -25.00); -- debit $25 for instrument 12

DECLARE @ErrorMsg VARCHAR(4000);

EXEC Trade.PayCashTerminalIdByManualData
    @PaymentDate    = '2026-03-15',
    @TerminalID     = 'MANUAL_CORRECTION_Q1',
    @UserName       = 'ops.admin',
    @CashPaymentsTbl = @Payments,
    @ErrorMsg        = @ErrorMsg OUTPUT;

SELECT @ErrorMsg AS ValidationErrors;
```

### 8.2 Process manual payments by ApexID and CUSIP
```sql
DECLARE @Payments Trade.CashPaymentsTbl;
INSERT INTO @Payments (ApexID, CUSIP, Amount)
VALUES ('APEX_12345', 'US0378331005', 10.50);

DECLARE @ErrorMsg VARCHAR(4000);

EXEC Trade.PayCashTerminalIdByManualData
    @PaymentDate    = '2026-03-15',
    @TerminalID     = 'AIRDROP_CORP',
    @UserName       = 'ops.dividends',
    @CashPaymentsTbl = @Payments,
    @ErrorMsg        = @ErrorMsg OUTPUT;

IF @ErrorMsg IS NOT NULL
    PRINT 'Validation errors: ' + @ErrorMsg;
```

### 8.3 Check queued manual payments
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
WHERE DataSource = 'MANUAL'
  AND PaymentDate = '2026-03-15'
ORDER BY ID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 additional analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PayCashTerminalIdByManualData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PayCashTerminalIdByManualData.sql*
