# Customer.SetBalanceClameFee

> Deducts a claim fee from a customer's balance (RealizedEquity and TotalCash always; Credit only for non-mirror positions), updates the mirror's own Amount and RealizedEquity if applicable, and logs CreditTypeID=14 (ClaimFee) - outputs whether the position was mirror-owned and the new CreditID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @PositionID BIGINT, @MirrorID INT, @FeeInDollars MONEY; @IsFromMirror TINYINT OUTPUT, @CreditID BIGINT OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When eToro processes a BSL claim or a position-level fee event, `SetBalanceClameFee` ("Clame" is a historical typo for "Claim" in the original codebase) deducts the fee from the customer's account. This is distinct from `SetBalanceCashOut` and `SetBalanceClosePosition` in that it:

1. Accepts the fee **already in dollars** (no cent conversion required by the caller).
2. Always reduces `RealizedEquity` and `TotalCash`.
3. Only reduces `Credit` if the position is NOT a mirror position - for mirror positions, the credit reduction is applied to `Trade.Mirror.Amount` instead.
4. Optionally updates `Trade.Mirror` (Amount and RealizedEquity) when the position belongs to a live mirror.
5. Returns two OUTPUT parameters: `@IsFromMirror` (whether the fee was deducted from mirror cash) and `@CreditID` (for downstream linking).

There is no MIMO pipeline trigger and no affiliate tracking for claim fees - this is a pure trading fee deduction without BSL recalculation side effects.

---

## 2. Business Logic

### 2.1 Mirror Membership Check

**What**: Before updating balances, determines whether the position being closed belonged to an active mirror.

**Columns/Parameters Involved**: `@MirrorID`, `@ParentPositionID`, `@IsFromMirror`

**Rules**:
- If `@MirrorID > 0 AND @ParentPositionID > 0 AND EXISTS(SELECT * FROM Trade.Mirror WHERE MirrorID = @MirrorID)`: `@IsFromMirror = 1`
- Else: `@IsFromMirror = 0`
- A position with `@ParentPositionID > 0` is a copied (child) position inside a mirror.
- A detached position (mirror since closed) will have `MirrorID > 0` but Trade.Mirror row will not exist -> `@IsFromMirror = 0`.

### 2.2 CustomerMoney Fee Deduction

**What**: Deducts @FeeInDollars from three or two balance fields depending on mirror status.

**Columns/Parameters Involved**: `RealizedEquity`, `TotalCash`, `Credit`

**Rules**:
- `RealizedEquity -= @FeeInDollars` (always)
- `TotalCash -= @FeeInDollars` (always)
- `Credit -= @FeeInDollars` ONLY IF `@IsFromMirror = 0` (non-mirror position)
- For mirror positions: `Credit` is unchanged; fee is absorbed by `Trade.Mirror.Amount` instead.

```
Non-mirror position:             Mirror position:
  Credit         -= fee             Credit         - UNCHANGED
  RealizedEquity -= fee             RealizedEquity -= fee
  TotalCash      -= fee             TotalCash      -= fee
  BSLRealFunds   - UNCHANGED        BSLRealFunds   - UNCHANGED
```

### 2.3 Trade.Mirror Update (Conditional)

**What**: When the position has a positive MirrorID and ParentPositionID, the mirror's own balance is also reduced.

**Columns/Parameters Involved**: `Trade.Mirror.Amount`, `Trade.Mirror.RealizedEquity`

**Rules**:
- If `@MirrorID > 0 AND @ParentPositionID > 0`: `UPDATE Trade.Mirror SET RealizedEquity -= @FeeInDollars, Amount -= @FeeInDollars`
- `@IsFromMirror = @@ROWCOUNT` - if the mirror was already closed (row deleted), @@ROWCOUNT=0 and @IsFromMirror is set back to 0.
- MirrorCash and MirrorEquity at time of fee are captured for the credit record.

### 2.4 Credit Record

**What**: Logs the claim fee as CreditTypeID=14.

**Rules**:
- `@CreditTypeID = 14` (ClaimFee, hardcoded)
- `@Payment = NewCredit - OldCredit` (the actual Credit change - zero for mirror positions)
- `@TotalCashChange = 0 - @FeeInDollars` (negative - total cash decreased)
- `@MirrorCash = CASE WHEN @IsFromMirror=1 THEN @MirrorCash ELSE 0 END`
- Returns `@CreditID` OUTPUT via `@Identity OUTPUT` from SetBalanceInsertCredit_Native.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position ID being charged the claim fee. Passed to SetBalanceInsertCredit_Native as PositionID for the credit record. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account being charged. |
| 3 | @MirrorID | INT | NO | - | CODE-BACKED | Copy-trading mirror ID for the position. Used to determine mirror membership and to update Trade.Mirror balances. 0 = no mirror. |
| 4 | @FeeInDollars | MONEY | NO | - | CODE-BACKED | Fee amount already in DOLLARS (not cents - unlike most other SetBalance* procedures). Deducted from the customer and/or mirror balances. |
| 5 | @ParentPositionID | BIGINT | NO | - | CODE-BACKED | Parent position ID for copied (mirror child) positions. Used together with @MirrorID to determine if position is actively mirrored. 0 = standalone position. |
| 6 | @Description | VARCHAR(200) | NO | - | CODE-BACKED | Human-readable description of the claim fee event, stored in the credit history. |
| 7 | @IsFromMirror | TINYINT | NO | - (OUTPUT) | CODE-BACKED | OUTPUT: 1 if the fee was deducted from an active mirror (Credit not changed, Trade.Mirror updated); 0 if standalone position. Caller uses this to determine further actions. |
| 8 | @CreditID | BIGINT | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT: The new CreditID created by SetBalanceInsertCredit_Native. Allows caller to reference the credit record (added 2022-02-07). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | UPDATE RealizedEquity, TotalCash (always); Credit (if not mirror) |
| @MirrorID | Trade.Mirror | MODIFIER (conditional) | UPDATE Amount, RealizedEquity if position is mirror-owned |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=14 claim fee credit record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=14 (ClaimFee) events here |
| BSL claim / position fee pipelines | External | Callers | Called when a claim fee is assessed against a position |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceClameFee (procedure)
+-- Customer.CustomerMoney (table) [UPDATE RealizedEquity, TotalCash, Credit(conditional)]
+-- Trade.Mirror (table) [conditional UPDATE Amount, RealizedEquity]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit CreditTypeID=14]
      +-- History.ActiveCreditRecentMemoryBucket (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - deducts fee from RealizedEquity, TotalCash, Credit (conditional) |
| Trade.Mirror | Table | UPDATE (conditional) - deducts fee from Amount and RealizedEquity |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=14 claim fee record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=14 (ClaimFee) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @FeeInDollars (not cents) | Unit convention | This procedure accepts dollars directly; no /100 conversion applied. Callers must pre-convert if their amount is in cents. |
| Mirror vs non-mirror Credit logic | Design | Credit unchanged for mirror positions - fee deducted from Trade.Mirror.Amount instead to maintain mirror balance integrity |
| @IsFromMirror = @@ROWCOUNT | Safety check | If Trade.Mirror row was already deleted (detached), @@ROWCOUNT=0 resets @IsFromMirror to 0 - prevents incorrect credit accounting |
| No MIMO trigger | Design | Claim fees do not trigger BSL recalculation - they are trading costs, not money-in/money-out events |
| @CreditID OUTPUT added 2022-02-07 | Enhancement | Downstream systems can now reference the exact credit record created by this fee event |

---

## 8. Sample Queries

### 8.1 Find claim fees for a customer by position

```sql
SELECT
    acb.CreditID,
    acb.PositionID,
    acb.MirrorID,
    acb.Payment AS FeeImpactOnCredit,
    acb.TotalCashChange AS FeeDeductedFromTotalCash,
    acb.RealizedEquity AS EquityAfterFee,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 14
ORDER BY acb.Occurred DESC
```

### 8.2 Total claim fees paid by a customer this month

```sql
SELECT
    acb.CID,
    SUM(ABS(acb.TotalCashChange)) AS TotalClaimFees,
    COUNT(*) AS ClaimFeeEvents
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CreditTypeID = 14
    AND acb.CID = 12345
    AND acb.Occurred >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETUTCDATE()), 0)
GROUP BY acb.CID
```

### 8.3 Check mirror balance after claim fee deduction

```sql
SELECT
    m.MirrorID,
    m.Amount AS CurrentMirrorCash,
    m.RealizedEquity AS CurrentMirrorEquity,
    acb.MirrorCash AS MirrorCashAtFeeTime,
    acb.TotalCashChange AS FeeDeducted,
    acb.Occurred
FROM Trade.Mirror m WITH (NOLOCK)
JOIN History.ActiveCreditBucket_VW acb WITH (NOLOCK) ON acb.MirrorID = m.MirrorID
WHERE m.MirrorID = 55555
    AND acb.CreditTypeID = 14
ORDER BY acb.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceClameFee | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceClameFee.sql*
