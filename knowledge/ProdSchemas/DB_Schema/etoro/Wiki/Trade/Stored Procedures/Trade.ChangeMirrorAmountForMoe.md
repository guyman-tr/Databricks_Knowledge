# Trade.ChangeMirrorAmountForMoe

> Adjusts funds in a CopyTrader mirror allocation - moves money between the customer's general balance and a mirror, recalculates mirror stop-loss, and logs the operation via Trade.PostDetachOperation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @MirrorID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChangeMirrorAmountForMoe is a variant of the CopyTrader mirror balance adjustment procedure. It moves funds between a customer's general credit balance and a specific copy-trade mirror allocation. This is called when a copier wants to increase or decrease their investment in a leader they are copying.

This procedure exists because CopyTrader mirrors maintain their own equity pools separate from the customer's general balance. When a copier decides to allocate more or fewer funds to a leader, this procedure handles the fund transfer, recalculates the mirror stop-loss, validates balances, and records the operation for downstream processing.

Key distinguishing feature: Unlike older variants, this procedure uses an atomic UPDATE with OUTPUT...INTO Trade.PostDetachOperation pattern, performing the mirror update and history logging in a single statement. It joins Trade.Mirror with Customer.CustomerMoney (not Customer.Customer) for credit validation, and uses @MirrorCalculatedUnrealized for stop-loss calculation.

---

## 2. Business Logic

### 2.1 Atomic Mirror Update with PostDetachOperation Logging

**What**: Updates mirror financial state and logs to PostDetachOperation in one atomic operation.

**Columns/Parameters Involved**: `Trade.Mirror.Amount`, `Trade.Mirror.RealizedEquity`, `Trade.Mirror.MirrorSL`, `Trade.PostDetachOperation`

**Rules**:
- Single UPDATE statement modifies Amount, RealizedEquity, DepositSummary, WithdrawalSummary, and MirrorSL
- OUTPUT clause inserts a row into Trade.PostDetachOperation with StatusID=0 and H_M_MirrorOprationDB='ChangeMirrorAmount'
- MirrorOperationID=3 (Change mirror balance)
- This replaces the older two-step pattern (UPDATE Mirror then INSERT History.Mirror)

### 2.2 Stop-Loss Recalculation

**What**: Mirror stop-loss is recalculated based on current unrealized PnL.

**Columns/Parameters Involved**: `@MirrorCalculatedUnrealized`, `Trade.Mirror.MirrorSLPercentage`, `@NewSLAmountCents`

**Rules**:
- @NewSLAmountCents = @MirrorCalculatedUnrealized * (MirrorSLPercentage / 100)
- MirrorSL in dollars = @NewSLAmountCents / 100
- Always recalculated (no @EditMirrorSL toggle in this variant)

### 2.3 Balance Validations and Error Codes

**What**: Validates the operation before allowing it.

**Columns/Parameters Involved**: `@ValidateUserBalance`, `@ExpectedMirrorAmountInCents`, `@DeltaAmountInCents`

**Rules**:
- 60050: MirrorID does not exist (@@ROWCOUNT = 0 after UPDATE)
- 60051: Mirror is not active AND trying to deposit (IsActive=0 AND @DeltaAmountInCents > 0) - withdrawals from inactive mirrors are allowed
- 60052: Only for @IsRealizedFlow=1: withdrawal exceeds mirror amount
- 60054: Deposit exceeds customer credit
- 60064: @CID mismatch
- 60097: New amount would trigger mirror stop-loss closure (and mirror is active)
- 60201: Customer.SetBalanceChangeMirrorAmount failed
- @ExpectedMirrorAmountInCents: Optimistic concurrency - current + delta must equal expected

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Must match Trade.Mirror.CID for the given mirror. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | CopyTrader mirror to adjust. Identifies the copy-trade relationship in Trade.Mirror. |
| 3 | @DeltaAmountInCents | MONEY | NO | - | CODE-BACKED | Amount to add/remove in cents. Positive = deposit into mirror, negative = withdraw. |
| 4 | @ExpectedMirrorAmountInCents | MONEY | YES | NULL | CODE-BACKED | Optimistic concurrency: if provided, current amount + delta must equal this. |
| 5 | @MirrorCalculatedUnrealized | MONEY | NO | - | CODE-BACKED | Current unrealized PnL of the mirror in cents. Used for SL recalculation and SL-trigger validation. |
| 6 | @NewSLAmountCents | MONEY | NO (OUT) | - | CODE-BACKED | OUTPUT: New mirror stop-loss amount in cents after recalculation. |
| 7 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Trading session ID for audit. Written to PostDetachOperation. |
| 8 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation GUID from client request for tracing. |
| 9 | @ValidateUserBalance | TINYINT | YES | 1 | CODE-BACKED | 1=enforce balance validations (default), 0=skip (Reopen Trade feature). |
| 10 | @ReferenceID | VARCHAR(36) | YES | NULL | CODE-BACKED | External reference ID. Written to PostDetachOperation.H_M_ReferenceID. |
| 11 | @ExternalOperationType | INT | YES | NULL | CODE-BACKED | External operation type identifier. Written to PostDetachOperation.H_M_ExternalOperationType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | UPDATE + SELECT | Reads and updates mirror financial state |
| @CID | Customer.CustomerMoney | JOIN | Reads Credit for balance validation |
| (writes) | Trade.PostDetachOperation | INSERT via OUTPUT | Logs the operation for async downstream processing |
| (calls) | Customer.SetBalanceChangeMirrorAmount | EXEC | Adjusts customer's general credit balance |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | (external) | EXEC | Called from CopyTrader mirror management flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChangeMirrorAmountForMoe (procedure)
+-- Trade.Mirror (table)
+-- Customer.CustomerMoney (table)
+-- Trade.PostDetachOperation (table)
+-- Customer.SetBalanceChangeMirrorAmount (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | UPDATE + SELECT (atomic with OUTPUT) |
| Customer.CustomerMoney | Table | JOIN for Credit validation |
| Trade.PostDetachOperation | Table | INSERT via OUTPUT clause |
| Customer.SetBalanceChangeMirrorAmount | Stored Procedure | EXEC to adjust general balance |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application services | External | Called for mirror fund adjustments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | BEGIN TRAN / COMMIT / ROLLBACK | Full transactional consistency for mirror + credit adjustment |
| TRY/CATCH with THROW | Error Handling | Rolls back on error and re-throws |

---

## 8. Sample Queries

### 8.1 Check mirror state before adjustment

```sql
SELECT M.MirrorID, M.CID, M.Amount, M.RealizedEquity,
       M.MirrorSL, M.MirrorSLPercentage, M.IsActive,
       CM.Credit
FROM   Trade.Mirror M WITH (NOLOCK)
       JOIN Customer.CustomerMoney CM WITH (NOLOCK) ON M.CID = CM.CID
WHERE  M.MirrorID = @MirrorID;
```

### 8.2 View recent PostDetachOperation entries for a mirror

```sql
SELECT TOP 10 *
FROM   Trade.PostDetachOperation WITH (NOLOCK)
WHERE  H_M_MirrorID = @MirrorID
ORDER BY ID DESC;
```

### 8.3 Audit mirror balance changes

```sql
SELECT H_M_MirrorID, H_M_Amount, H_M_MirrorOprationDB,
       H_M_RealizedEquity, H_M_MirrorSL
FROM   Trade.PostDetachOperation WITH (NOLOCK)
WHERE  H_M_CID = @CID
       AND H_M_MirrorOprationDB = 'ChangeMirrorAmount'
ORDER BY ID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. The header references TRADNA-1459 and multiple FogBugz tickets (23569, 31696, 35218, 35806, 51445, 52839) documenting the evolution of mirror amount change logic.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ChangeMirrorAmountForMoe | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ChangeMirrorAmountForMoe.sql*
