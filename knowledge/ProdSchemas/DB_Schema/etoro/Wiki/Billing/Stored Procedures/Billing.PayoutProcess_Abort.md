# Billing.PayoutProcess_Abort

> Releases the InProcess claim on a batch of payout records, resetting InProcess=0 so the records become eligible for re-processing by another worker in the same CorrelationID session.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Ids (WithdrawToFundingIDs) + @CorrelationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_Abort` is the abort/release mechanism for the payout processing pipeline. When the payout service worker claims a set of `Billing.PayoutProcess` records (by setting `InProcess=1` and stamping `CorrelationID`), it takes exclusive ownership of those records. If the worker encounters an error or the payout batch must be cancelled mid-flight, this procedure releases the claim by resetting `InProcess=0`.

After abort, the affected records revert to the "available for processing" state and can be picked up by the next payout worker query (which uses a filtered index on `InProcess=0 AND CashoutStatusID IN (0,12)`).

The CorrelationID guard is critical for safety: only records belonging to the specific worker session that claimed them can be released. This prevents one worker from accidentally releasing records claimed by another concurrent worker.

Created by Geri Reshef, 05/01/2017 (ticket 43131, "DB - Cashout new SP"). Executed by `PayoutUser` (EXECUTE grant confirmed).

---

## 2. Business Logic

### 2.1 Batch InProcess Release

**What**: Resets InProcess=0 on all payout records in the given ID set that match the CorrelationID.

**Parameters Involved**: `@Ids`, `@CorrelationID`

**Rules**:
- `UPDATE Billing.PayoutProcess SET InProcess=0 WHERE WithdrawToFundingID IN (SELECT CID FROM @Ids) AND CorrelationID=@CorrelationID`
- Targets records by `WithdrawToFundingID` (matched via the `CID` column of the `dbo.IdList` TVP - generic ID container, misnamed)
- Double guard: WithdrawToFundingID must be in @Ids AND CorrelationID must match
- After update: records are eligible for re-pick-up by the filtered index on `InProcess=0 AND CashoutStatusID IN (0,12)`
- No return value, no error handling, no transaction wrapper
- If no matching records found: silent no-op (0 rows affected)

### 2.2 CorrelationID as Worker Session Identifier

**What**: The CorrelationID ensures only the owning worker session can abort its own records.

**Rules**:
- CorrelationID (VARCHAR(36)): a UUID assigned by the payout worker when it claims records via `PayoutProcess_GetNewRecords`
- Matching on CorrelationID prevents cross-worker interference: worker A cannot release records claimed by worker B
- Distinct from BoCorrelationID (back-office approval session) - this is the worker-level processing session ID

### 2.3 dbo.IdList TVP Naming Quirk

**What**: The `dbo.IdList` type has a single column named `CID` (integer), used as a generic integer ID list.

**Rules**:
- `dbo.IdList`: `CREATE TYPE [dbo].[IdList] AS TABLE ([CID] [int] NULL)`
- Despite the column being named `CID` (Customer ID by convention), it holds `WithdrawToFundingID` values in this context
- The TVP is a reusable generic integer list type used across multiple procedures; the CID column name is a generic artifact

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | dbo.IdList (TABLE: CID INT) | ReadOnly | - | CODE-BACKED | Table-valued parameter containing WithdrawToFundingIDs to abort. dbo.IdList is a generic integer list type; the CID column holds WTF IDs despite the misleading name. |
| 2 | @CorrelationID | VARCHAR(36) | NO | - | CODE-BACKED | UUID identifying the payout worker session that originally claimed these records. Only records with this exact CorrelationID are released - prevents cross-worker interference. |
| 3 | RETURN value | - | - | - | CODE-BACKED | No explicit RETURN statement. No error handling. UPDATE errors surface as unhandled exceptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | MODIFIER | Resets InProcess=0 on aborted payout records |
| @Ids | dbo.IdList | TVP Type | Generic integer list container for WithdrawToFundingIDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout service (PayoutUser) | @Ids, @CorrelationID | EXEC caller | Called when a payout worker batch encounters an error and must release claimed records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_Abort (procedure)
└── Billing.PayoutProcess (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Table | UPDATE InProcess=0 on matching records |
| dbo.IdList | User Defined Type | TVP parameter type - integer list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout service (PayoutUser) | Application | Aborts payout worker session claims on error |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. The UPDATE will use the UNIQUE NC index on Billing.PayoutProcess.WithdrawToFundingID to locate rows efficiently.

### 7.2 Constraints

N/A for stored procedure. No transaction wrapper. No error handling. No return value. Double filter (WithdrawToFundingID IN @Ids AND CorrelationID match) ensures only the owning worker session can release its records. Safe for concurrent payout workers.

---

## 8. Sample Queries

### 8.1 Abort payout processing for a set of withdrawals

```sql
DECLARE @Ids dbo.IdList;
INSERT INTO @Ids (CID) VALUES (1000001), (1000002), (1000003);  -- WTF IDs

EXEC Billing.PayoutProcess_Abort
    @Ids           = @Ids,
    @CorrelationID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
```

### 8.2 Check which payout records are currently claimed (InProcess=1)

```sql
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.CorrelationID,
    pp.InProcessDate,
    pp.CashoutStatusID
FROM Billing.PayoutProcess pp WITH (NOLOCK)
WHERE pp.InProcess = 1
ORDER BY pp.InProcessDate DESC;
```

### 8.3 Find payout records available for processing (filtered index candidates)

```sql
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.CashoutStatusID,
    pp.BoCorrelationID,
    pp.PayoutGeneration
FROM Billing.PayoutProcess pp WITH (NOLOCK)
WHERE pp.InProcess = 0
  AND pp.CashoutStatusID IN (0, 12)  -- ReceivedByBilling or reset state
ORDER BY pp.ProcessID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: PayoutUser EXECUTE grant confirmed | Corrections: 0 applied*
*Object: Billing.PayoutProcess_Abort | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_Abort.sql*
