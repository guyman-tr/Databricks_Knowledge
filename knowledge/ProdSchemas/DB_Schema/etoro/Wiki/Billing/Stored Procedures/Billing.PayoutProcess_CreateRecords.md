# Billing.PayoutProcess_CreateRecords

> Atomically creates PayoutProcess records for approved withdrawals: inserts into Billing.PayoutProcess, transitions WithdrawToFunding status to ReceivedByBilling (12), and writes audit history - guarded against duplicate insertion and invalid source status.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Ids (WithdrawToFundingIDs) + @CorrelationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_CreateRecords` is the entry point for the payout processing pipeline. It converts approved withdrawal records from a "waiting to be processed" state (CashoutStatusID=11 SentToBilling) into active payout process records (CashoutStatusID=12 ReceivedByBilling), simultaneously creating the tracking row in `Billing.PayoutProcess` and the audit entry in `History.WithdrawToFundingAction`.

The procedure is designed for batch execution: a back-office manager (or the billing service with @ManagerID=-1) submits a set of WithdrawToFunding IDs that have been approved for payout. The procedure filters out any that are not in the correct source state (CashoutStatusID != 11, VerificationCode not NULL) or already have a PayoutProcess record (deduplication guard), processes only valid candidates, and atomically commits the 3-table write.

Key business rule: `@PayoutGeneration` determines which payout service will subsequently process these records (0=legacy, 1=new service, introduced August 2020). Called by: back-office approval flow, `Billing.PayoutProcess_GetNewRecordsForInstantPayout` (instant payout path), and external payout service (PayoutUser, SQL_SecurePay, RedeemServiceUser have EXECUTE grant).

Created: Geri Reshef, 16/01/2017. Revisions: transaction handling fix (2019), @IsSendResults added (April 2020), @PayoutGeneration added (August 2020).

---

## 2. Business Logic

### 2.1 Eligibility Filter and Deduplication Guard

**What**: Only WithdrawToFunding records in the correct state and without existing PayoutProcess records are inserted.

**Parameters Involved**: `@Ids`

**Rules**:
- Source filter on Billing.WithdrawToFunding (INNER JOIN to @Ids):
  - `CashoutStatusID = 11` (SentToBilling) - must be in the pre-processing queue
  - `VerificationCode IS NULL` - must be verified (no pending verification code)
- Deduplication: `NOT EXISTS (SELECT * FROM Billing.PayoutProcess WHERE WithdrawToFundingID = i.CID)`
  - Prevents duplicate PayoutProcess rows for the same WithdrawToFunding
  - The UNIQUE NC index on PayoutProcess.WithdrawToFundingID would also block duplicates, but this guard is explicit

### 2.2 Three-Table Atomic Write

**What**: All three DML operations execute within a single transaction.

**Parameters Involved**: `@ManagerID`, `@CorrelationID`, `@PayoutGeneration`

**Rules**:
- **Step 1**: `INSERT INTO Billing.PayoutProcess (WithdrawToFundingID, CashoutStatusID=12, PayoutProcessReasonID=0, ManagerID, BoCorrelationID, PayoutGeneration)`
  - OUTPUT Inserted.WithdrawToFundingID + Inserted.ProcessID -> #Output temp table
  - Only records passing the eligibility filter are inserted
- **Step 2**: `UPDATE Billing.WithdrawToFunding SET CashoutStatusID=12 WHERE ID IN (#Output)`
  - Transitions the WTF record from CashoutStatusID=11 -> 12 (ReceivedByBilling)
  - Atomic with Step 1 - both always committed together
- **Step 3**: `INSERT INTO History.WithdrawToFundingAction` (audit entry)
  - CashoutActionStatusID=2 (processed), Remark='Create New Payout Process record'
  - ManagerID logic: if @ManagerID=-1 (billing service auto-run), uses WTF.ManagerID from source; else uses @ManagerID
- COMMIT: all three writes succeed or none commit

### 2.3 @ManagerID=-1 Convention

**What**: -1 signals that the billing service is auto-running the procedure, not a human manager.

**Rules**:
- When @ManagerID=-1: audit history uses the WTF's existing ManagerID: `CASE WHEN @ManagerID != -1 THEN @ManagerID ELSE ManagerID END`
- When @ManagerID >= 0: audit history uses the supplied manager ID (human back-office user)
- PayoutProcess.ManagerID column receives @ManagerID as-is (including -1)

### 2.4 Optional Result Set

**What**: @IsSendResults controls whether a result set is returned to the caller.

**Rules**:
- `@IsSendResults = 1` (default): Returns ProcessID, WithdrawToFundingID, Amount, WithdrawID, FundingID for all created records
- `@IsSendResults = 0`: No result set returned (used by callers that only need the side-effect writes)
- Result set reads from the join of PayoutProcess + WithdrawToFunding via #Output

### 2.5 @PayoutGeneration Routing

**What**: Determines which payout service pipeline will process the created records.

**Rules**:
- 0 = legacy payout service (default, pre-2020)
- 1 = new payout service (added August 2020 by Elrom)
- Stored in PayoutProcess.PayoutGeneration; payout workers filter by this value to claim only their generation's records

### 2.6 Error Handling

**Rules**:
- TRY/CATCH with nested transaction awareness:
  - `@@TRANCOUNT = 1` -> ROLLBACK (outermost transaction owner)
  - `@@TRANCOUNT > 1` -> COMMIT (nested: inner tran is committed to release savepoint)
- `THROW`: re-raises the original exception to the caller
- `#Output` temp table created before BEGIN TRAN (destroyed automatically on session end or error)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | dbo.IdList (TABLE: CID INT) | ReadOnly | - | CODE-BACKED | Table-valued parameter containing WithdrawToFundingIDs to process. dbo.IdList.CID column is used as generic integer ID container for WTF IDs. |
| 2 | @ManagerID | INT | NO | - | CODE-BACKED | Back-office manager ID initiating the payout batch. -1 = billing service auto-run (does not override WTF.ManagerID in audit history). Stored in PayoutProcess.ManagerID. |
| 3 | @CorrelationID | VARCHAR(36) | NO | - | CODE-BACKED | UUID for this payout approval session. Stored in PayoutProcess.BoCorrelationID (back-office correlation). Used by PayoutProcess_Abort to release claims if needed. |
| 4 | @IsSendResults | INT | YES | 1 | CODE-BACKED | 1=return result set (ProcessID, WTFID, Amount, WithdrawID, FundingID) for created records. 0=no result set. Added April 2020. |
| 5 | @PayoutGeneration | INT | YES | 0 | CODE-BACKED | 0=legacy payout service, 1=new payout service. Stored in PayoutProcess.PayoutGeneration. Payout workers filter by generation to claim their records. Default=0 (legacy). |
| 6 | Result set (when @IsSendResults=1) | TABLE | - | - | CODE-BACKED | Columns: ProcessID, WithdrawToFundingID, Amount, WithdrawID, FundingID. One row per successfully created PayoutProcess record. |
| 7 | RETURN value | - | - | - | CODE-BACKED | No explicit RETURN. THROW re-raises exceptions to caller. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT + OUTPUT | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | WRITER | Creates payout process record (CashoutStatusID=12) |
| UPDATE | Billing.WithdrawToFunding | MODIFIER | Transitions WTF CashoutStatusID 11 -> 12 |
| INSERT | History.WithdrawToFundingAction | WRITER | Audit entry for payout creation |
| INNER JOIN (filter) | Billing.WithdrawToFunding | READ | Source eligibility check (CashoutStatusID=11, VerificationCode IS NULL) |
| NOT EXISTS (dedup) | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | READ | Deduplication guard - prevents double-insertion |
| @Ids | dbo.IdList | TVP Type | Input ID list |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [Billing.PayoutProcess_GetNewRecordsForInstantPayout](Billing.PayoutProcess_GetNewRecordsForInstantPayout.md) | @Ids | EXEC caller | Instant payout path creates records then retrieves them for immediate processing |
| Back-office approval flow (external) | @Ids, @ManagerID | EXEC caller | Human manager approves withdrawals for payout (PayoutUser, SQL_SecurePay grants) |
| RedeemServiceUser (external) | @Ids | EXEC caller | Redeem payout path creates standard payout records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_CreateRecords (procedure)
├── Billing.PayoutProcess (table) - INSERT + dedup check
├── Billing.WithdrawToFunding (table) - filter + UPDATE
└── History.WithdrawToFundingAction (table) - audit INSERT
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Table | INSERT (create payout record) + NOT EXISTS (dedup guard) |
| Billing.WithdrawToFunding | Table | INNER JOIN (eligibility filter) + UPDATE (status transition) |
| History.WithdrawToFundingAction | Table | INSERT (audit trail) |
| dbo.IdList | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayoutProcess_GetNewRecordsForInstantPayout | Procedure | Calls to create PayoutProcess records in the instant payout flow |
| Back-office application (PayoutUser, SQL_SecurePay, RedeemServiceUser) | Application | Called to initiate payout processing for approved withdrawal batches |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Writes to Billing.PayoutProcess (UNIQUE NC on WithdrawToFundingID) and Billing.WithdrawToFunding (NC on ID). Uses #Output temp table (not table variable) to enable the OUTPUT INTO ... SELECT pattern.

### 7.2 Constraints

N/A for stored procedure. TRY/CATCH with ROLLBACK at @@TRANCOUNT=1, COMMIT at @@TRANCOUNT>1, THROW re-raise. Eligibility guards: CashoutStatusID=11, VerificationCode IS NULL, no existing PayoutProcess. @ManagerID=-1 convention for billing service auto-runs. CashoutStatusID hardcoded: 12=ReceivedByBilling, CashoutActionStatusID=2 in history.

---

## 8. Sample Queries

### 8.1 Create payout records for a batch of approved withdrawals

```sql
DECLARE @Ids dbo.IdList;
INSERT INTO @Ids (CID) VALUES (5001), (5002), (5003);  -- WithdrawToFundingIDs

EXEC Billing.PayoutProcess_CreateRecords
    @Ids            = @Ids,
    @ManagerID      = 42,        -- back-office manager user ID
    @CorrelationID  = 'f1e2d3c4-b5a6-7890-abcd-ef0123456789',
    @IsSendResults  = 1,
    @PayoutGeneration = 1;       -- new payout service
```

### 8.2 Preview which withdrawals are eligible for payout creation

```sql
SELECT
    wtf.ID AS WithdrawToFundingID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.CashoutStatusID,
    wtf.Amount,
    wtf.VerificationCode
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.CashoutStatusID = 11       -- SentToBilling
  AND wtf.VerificationCode IS NULL   -- verified
  AND NOT EXISTS (
    SELECT 1 FROM Billing.PayoutProcess pp WITH (NOLOCK)
    WHERE pp.WithdrawToFundingID = wtf.ID
  )
ORDER BY wtf.ID;
```

### 8.3 Check audit history for a payout creation event

```sql
SELECT
    ha.BW2F_ID AS WithdrawToFundingID,
    ha.CashoutStatusID,
    ha.CashoutActionStatusID,
    ha.ModificationDate,
    ha.Remark,
    ha.ManagerID
FROM History.WithdrawToFundingAction ha WITH (NOLOCK)
WHERE ha.BW2F_ID = 5001
  AND ha.Remark = 'Create New Payout Process record'
ORDER BY ha.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 SQL caller (PayoutProcess_GetNewRecordsForInstantPayout) | App Code: PayoutUser/SQL_SecurePay/RedeemServiceUser EXECUTE grants confirmed | Corrections: 0 applied*
*Object: Billing.PayoutProcess_CreateRecords | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_CreateRecords.sql*
