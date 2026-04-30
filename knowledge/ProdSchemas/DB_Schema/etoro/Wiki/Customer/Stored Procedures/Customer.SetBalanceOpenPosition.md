# Customer.SetBalanceOpenPosition

> Debits a customer's Credit and TotalCash when opening a trading position, with an optional balance check guard; for mirror-copied positions, updates Trade.Mirror.Amount instead of CustomerMoney.Credit; supports nested transaction context; logs CreditTypeID=3 (OpenPosition).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @PositionID BIGINT, @Amount MONEY, @MirrorID INT; @CreditID BIGINT OUTPUT; RAISERROR(60003) if insufficient balance |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetBalanceOpenPosition` is called when a customer opens a trading position. It deducts the position cost from the customer's account. The position cost (passed as `@Amount`) is divided by -100 to produce a negative credit change - the cost is subtracted.

The procedure mirrors the mirror-vs-standalone distinction used in `SetBalanceClosePosition`:
- **Standalone positions** (MirrorID=0): `Credit` and `TotalCash` are both decremented. An optional balance check ensures Credit stays non-negative.
- **Mirror-copied positions** (MirrorID>0): `CustomerMoney.Credit` is NOT changed. Instead, `Trade.Mirror.Amount` is decremented - the position cost comes from the mirror's cash, not the customer's direct balance.

A nested transaction pattern (`@MyTran` flag) allows this procedure to participate in an existing caller transaction - if `@@TranCount > 0` when called, no new transaction is started.

---

## 2. Business Logic

### 2.1 Amount-to-CreditChange Conversion

**What**: @Amount is the position cost in "amount units" (MONEY), divided by -100 to get a negative dollar change.

**Rules**:
- `@CreditChangeInDollar = @Amount / (-100)`
- Always negative (deduction from balance).

### 2.2 Three-Branch CustomerMoney Update

**What**: The balance update takes one of three code paths depending on @ValidateUserBalance and @MirrorID.

**Columns/Parameters Involved**: `Credit`, `TotalCash`, `@ValidateUserBalance`, `@MirrorID`

**Rules**:

| Condition | CustomerMoney Update |
|-----------|---------------------|
| ValidateUserBalance=1 AND MirrorID=0 | UPDATE WHERE `Credit + @CreditChangeInDollar >= 0` (balance guard) |
| ValidateUserBalance=0 AND MirrorID=0 | UPDATE unconditionally (no balance guard) |
| MirrorID>0 | No UPDATE to CustomerMoney; only INSERT snapshot into @Output |

- For non-mirror updates: `TotalCash += @CreditChangeInDollar` AND `Credit += @CreditChangeInDollar`.
- `@rc = @@ROWCOUNT`: if 0, `RAISERROR(60003, 16, 1, 'open')` - either balance check failed or CID not found.

### 2.3 Trade.Mirror Update (Mirror Positions)

**What**: For mirror positions, the position cost comes from the mirror's cash balance.

**Columns/Parameters Involved**: `Trade.Mirror.Amount`

**Rules**:
- `UPDATE Trade.Mirror SET @OldMirrorCredit = Amount, Amount = ROUND(Amount + @CreditChangeInDollar, 2) WHERE MirrorID = @MirrorID`
- If `ROUND(@OldMirrorCredit + @CreditChangeInDollar, 2) < 0 AND @ValidateUserBalance = 1`: RAISERROR(60003) - mirror also checked for sufficient balance.
- `@CustomerCreditChange = 0` for mirror positions (no Customer.CustomerMoney Credit change to report).

### 2.4 Credit Record

**What**: Logs the position open event.

**Rules**:
- Default `@CreditTypeID = 3` (OpenPosition), overridable by caller.
- `@Payment = @CustomerCreditChange` (= @CreditChangeInDollar for standalone; = 0 for mirror).
- `@TotalCashChange = @CreditChangeInDollar` (TotalCash always changes by the full amount).
- `@MirrorCash = ROUND(@OldMirrorCredit + @CreditChangeInDollar, 2)` for mirror; NULL for standalone.
- `@Credit = OldCredit` for mirror (Credit didn't change); `@Credit = NewCredit` for standalone.
- Returns `@CreditID OUTPUT`.

### 2.5 Nested Transaction Handling

**What**: Supports being called from within an existing transaction.

**Rules**:
- If `@@TranCount > 0` when called: `@MyTran = 0`, no BEGIN TRAN issued.
- If `@@TranCount = 0`: `@MyTran = 1`, BEGIN TRAN started and COMMIT at end.
- CATCH: only ROLLBACK if `@MyTran = 1 AND @@TranCount = 1` (this procedure's transaction).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID opening the position. |
| 2 | @Amount | MONEY | NO | - | VERIFIED | Position cost in "amount units" (MONEY type). Divided by -100 to get negative credit change in dollars. |
| 3 | @CreditTypeID | INT | YES | 3 | CODE-BACKED | Credit event type. Default 3=OpenPosition. Overridable for special open types. |
| 4 | @Description | VARCHAR(100) | NO | - | CODE-BACKED | Human-readable description stored in credit history. |
| 5 | @ManagerID | INT | YES | 0 | CODE-BACKED | Admin/manager ID for admin-initiated opens. 0 = customer-initiated. |
| 6 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position being opened. Stored in the credit record. |
| 7 | @MirrorID | INT | NO | - | CODE-BACKED | Copy-trading mirror ID. 0 = standalone position. Determines whether CustomerMoney or Trade.Mirror is debited. |
| 8 | @ValidateUserBalance | TINYINT | YES | 1 | CODE-BACKED | 1=enforce Credit >= 0 guard before update (default); 0=skip balance check. Used for system reopens where balance check is bypassed. |
| 9 | @CreditID | BIGINT | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT: CreditID of the open position credit record. |
| 10 | @CompensationReasonID | INTEGER | YES | NULL | CODE-BACKED | Optional compensation reason reference. Passed to SetBalanceInsertCredit_Native for special open event classification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER (conditional) | UPDATE TotalCash, Credit for standalone positions; snapshot READ for mirror positions |
| @MirrorID | Trade.Mirror | MODIFIER (conditional) | UPDATE Amount -= position cost for mirror positions |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs position open credit record |
| - | Trade.SetBalanceOpenPosition_MOT | TABLE TYPE | @Output variable type - table-valued UDT capturing balance snapshot |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=3 (OpenPosition) events here |
| Trade position open pipelines | External | Callers | Called when a new trading position is opened |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceOpenPosition (procedure)
+-- Customer.CustomerMoney (table) [conditional UPDATE TotalCash, Credit]
+-- Trade.Mirror (table) [conditional UPDATE Amount]
+-- Trade.SetBalanceOpenPosition_MOT (user defined type) [@Output table variable type]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit record CreditTypeID=3]
      +-- History.ActiveCreditRecentMemoryBucket (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE (conditional) - TotalCash, Credit for standalone positions |
| Trade.Mirror | Table | UPDATE (conditional) - Amount for mirror positions |
| Trade.SetBalanceOpenPosition_MOT | User Defined Type | @Output table variable declaration |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts open position credit record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=3 (OpenPosition) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @Amount / -100 | Unit convention | Position cost is positive amount; negated and divided by 100 to produce dollar deduction |
| Credit balance check | Guard | WHERE Credit + CreditChangeInDollar >= 0 prevents overdraft for standard opens |
| RAISERROR(60003) | Error code | 60003 = "Insufficient funds to open/close position" in the Customer schema error convention |
| Mirror bypass of CustomerMoney | Design | Mirror positions cost from mirror cash (Trade.Mirror.Amount), not customer credit directly - ensures mirror accounting is separate |
| RealizedEquity not changed | Design | Opening a position does not change RealizedEquity (unlike closing) - position value is not "realized" until close |
| Nested transaction support | Design | @MyTran flag allows participation in caller's transaction scope |

---

## 8. Sample Queries

### 8.1 Find position opens for a customer

```sql
SELECT
    acb.CreditID,
    acb.PositionID,
    acb.MirrorID,
    acb.Payment AS CreditDeductedForStandalone,
    acb.TotalCashChange AS TotalCashDeducted,
    acb.Credit AS CreditAfterOpen,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 3
ORDER BY acb.Occurred DESC
```

### 8.2 Check mirror cash after position opens

```sql
SELECT
    m.MirrorID,
    m.Amount AS CurrentMirrorCash,
    acb.MirrorCash AS MirrorCashAtOpen,
    acb.TotalCashChange AS PositionCostDeducted,
    acb.Occurred
FROM Trade.Mirror m WITH (NOLOCK)
JOIN History.ActiveCreditBucket_VW acb WITH (NOLOCK) ON acb.MirrorID = m.MirrorID
WHERE m.MirrorID = 55555
    AND acb.CreditTypeID = 3
ORDER BY acb.Occurred DESC
```

### 8.3 Standalone vs mirror open volume

```sql
SELECT
    CASE WHEN acb.MirrorID > 0 THEN 'Mirror' ELSE 'Standalone' END AS PositionType,
    COUNT(*) AS OpenCount,
    SUM(ABS(acb.TotalCashChange)) AS TotalCashDeducted
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 3
GROUP BY CASE WHEN acb.MirrorID > 0 THEN 'Mirror' ELSE 'Standalone' END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceOpenPosition | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceOpenPosition.sql*
