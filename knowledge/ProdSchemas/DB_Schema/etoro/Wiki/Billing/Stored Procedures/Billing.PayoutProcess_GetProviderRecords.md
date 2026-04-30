# Billing.PayoutProcess_GetProviderRecords

> Claims payout records for a specific protocol and cashout status, with a 30-minute timeout retry - returns ProcessID, WithdrawToFundingID, CashoutStatusID, ManagerID, and ExtReferenceCode for each claimed record.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProtocolID + @CashoutStatusID + @CorrelationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_GetProviderRecords` is the payment gateway worker's claim-and-retrieve procedure for a specific payment protocol (e.g., Adyen, PayPal API) and cashout status stage. Unlike `PayoutProcess_GetNewRecords` (which targets newly received records in status 12), this procedure targets a caller-specified CashoutStatusID and a specific PaymentProtocolID - allowing provider-specific workers to claim records at particular stages of the payout lifecycle.

The 30-minute timeout retry is a key feature: the procedure claims records that are either unclaimed (`InProcess=0`) OR have been stuck in-process for more than 30 minutes (`InProcess=1 AND InProcessDate < GETUTCDATE()-30min`). This prevents payouts from getting permanently stuck if a worker crashed mid-processing.

The result set is delivered directly via the OUTPUT clause of the UPDATE (no INTO - it flows to the caller), returning the minimum fields the gateway worker needs: ProcessID, WithdrawToFundingID, CashoutStatusID, ManagerID, ExtReferenceCode.

Used by `SQL_SecurePay` (payment gateway service with EXECUTE grant). Created by Geri Reshef, 05/01/2017 (ticket 43131), with three subsequent bug-fix revisions (45176, 45427, 49592) including the critical `d.ProtocolID=@ProtocolID` predicate added in November 2017.

---

## 2. Business Logic

### 2.1 Protocol-Filtered Claim with Timeout Retry

**What**: Claims unclaimed OR stuck records for a specific protocol and status.

**Parameters Involved**: `@MaxNumOfItems`, `@CorrelationID`, `@ProtocolID`, `@CashoutStatusID`

**Rules**:
- Filter conditions:
  - `wtf.CashoutStatusID = @CashoutStatusID` - caller specifies the target status stage
  - `d.ProtocolID = @ProtocolID` - targets records for a specific payment protocol/gateway
  - `InProcess=0 OR (InProcess=1 AND InProcessDate < DATEADD(MINUTE,-30,GETUTCDATE()))`
    - `InProcess=0`: fresh unclaimed records
    - `InProcess=1 AND InProcessDate < now-30min`: timed-out claims - allows recovery from crashed workers
- No `PayoutGeneration` filter (unlike GetNewRecords) - processes all generations
- `@MaxNumOfItems` default = 10,000 (much larger than GetNewRecords, which has no default)

### 2.2 Atomic UPDATE+OUTPUT (Result to Caller)

**What**: Claims records and returns their details to the caller in a single atomic operation.

**Rules**:
- UPDATE Billing.PayoutProcess (via subquery alias): SET InProcess=1, InProcessDate=GETUTCDATE(), CorrelationID=@CorrelationID
  - Self-assigns ManagerID and ExtReferenceCode to include them in OUTPUT
- JOIN chain: PayoutProcess -> WithdrawToFunding (on WTF.ID) -> Depot (on WTF.DepotID)
- OUTPUT (no INTO - flows directly to result set):
  - Inserted.ProcessID
  - Inserted.WithdrawToFundingID
  - Inserted.CashoutStatusID
  - Inserted.ManagerID
  - Inserted.ExtReferenceCode

### 2.3 Error Handling

**Rules**:
- TRY/CATCH
- CATCH: Prints full diagnostic message (@@ServerName, DB name, procedure name, error message, line, severity, @@TranCount, timestamp) then THROW
- No @@TRANCOUNT check for ROLLBACK (if tran began and fails, THROW surfaces the error; the caller or connection cleanup handles rollback)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxNumOfItems | INT | YES | 10000 | CODE-BACKED | Maximum records to claim per call. Default 10,000. Controls batch size for the gateway worker. |
| 2 | @CorrelationID | VARCHAR(36) | NO | - | CODE-BACKED | UUID for this worker session. Stamped on claimed records (PayoutProcess.CorrelationID). Enables identification of which records this session owns. |
| 3 | @ProtocolID | INT | NO | - | CODE-BACKED | Payment protocol ID (FK to Billing.Depot.ProtocolID). Routes claim to records for a specific payment gateway/protocol. Added as predicate in November 2017 fix (ticket 49592). |
| 4 | @CashoutStatusID | INT | NO | - | CODE-BACKED | Target cashout status to claim. Caller specifies which stage of the payout lifecycle to work on. Filtered via Billing.WithdrawToFunding.CashoutStatusID. |
| 5 | Result set | TABLE | - | - | CODE-BACKED | Columns from OUTPUT: ProcessID, WithdrawToFundingID, CashoutStatusID, ManagerID, ExtReferenceCode. One row per claimed record. |
| 6 | RETURN value | - | - | - | CODE-BACKED | No explicit RETURN. THROW re-raises exceptions after printing diagnostic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE (claim) | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | MODIFIER | Claims records (InProcess=1, CorrelationID, InProcessDate) |
| JOIN (ProtocolID filter) | Billing.WithdrawToFunding | READ | CashoutStatusID filter; ID for WTF->PayoutProcess join |
| JOIN (ProtocolID filter) | Billing.Depot | READ | ProtocolID filter to route to specific gateway |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay (payment gateway service) | @ProtocolID, @CashoutStatusID | EXEC caller | Called by payment gateway integration to claim records for provider-specific processing stages |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_GetProviderRecords (procedure)
├── Billing.PayoutProcess (table) - claim UPDATE
├── Billing.WithdrawToFunding (table) - CashoutStatusID filter
└── Billing.Depot (table) - ProtocolID filter
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Table | UPDATE (claim) + OUTPUT (result set) |
| Billing.WithdrawToFunding | Table | INNER JOIN - CashoutStatusID filter |
| Billing.Depot | Table | INNER JOIN - ProtocolID filter for gateway routing |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay (payment gateway service) | Application | Claims payout records at specific status stages for provider-specific processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. UPDATE accesses PayoutProcess via join to WithdrawToFunding and Depot. The 30-minute timeout allows recovery without manual intervention.

### 7.2 Constraints

N/A for stored procedure. Critical predicate: `d.ProtocolID=@ProtocolID` (added Nov 2017 - its absence caused a bug where records from other protocols were incorrectly claimed). Timeout retry rule: records in InProcess=1 for >30 minutes are eligible for re-claim. No @@TRANCOUNT guard in CATCH - THROW propagates without explicit ROLLBACK.

---

## 8. Sample Queries

### 8.1 Claim provider records for Adyen protocol in SentToProvider status

```sql
EXEC Billing.PayoutProcess_GetProviderRecords
    @MaxNumOfItems  = 100,
    @CorrelationID  = 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
    @ProtocolID     = 5,   -- Adyen protocol ID (example)
    @CashoutStatusID = 10; -- SentToProvider
```

### 8.2 Check for stuck in-process records (>30 minutes)

```sql
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.CorrelationID,
    pp.InProcessDate,
    DATEDIFF(MINUTE, pp.InProcessDate, GETUTCDATE()) AS MinutesStuck,
    pp.CashoutStatusID
FROM Billing.PayoutProcess pp WITH (NOLOCK)
WHERE pp.InProcess = 1
  AND pp.InProcessDate < DATEADD(MINUTE, -30, GETUTCDATE())
ORDER BY pp.InProcessDate;
```

### 8.3 Find payout records by protocol

```sql
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.CashoutStatusID,
    pp.InProcess,
    d.ProtocolID
FROM Billing.PayoutProcess pp WITH (NOLOCK)
INNER JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.ID = pp.WithdrawToFundingID
INNER JOIN Billing.Depot d WITH (NOLOCK) ON d.DepotID = wtf.DepotID
WHERE d.ProtocolID = 5   -- specific protocol
ORDER BY pp.ProcessID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: SQL_SecurePay EXECUTE grant confirmed | Corrections: 0 applied*
*Object: Billing.PayoutProcess_GetProviderRecords | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_GetProviderRecords.sql*
