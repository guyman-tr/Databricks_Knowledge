# Billing.GetFirstWithdrawToFunding

> Returns the ID of the earliest successfully processed withdrawal-to-funding record for a given customer, used to determine whether a customer has ever successfully completed a withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Knowing whether a customer has ever successfully completed a withdrawal (cashout) is important for several business decisions: eligibility for certain promotions, KYC milestone tracking, fraud assessment, and VIP status calculations. The "first successful withdrawal" event is a key lifecycle milestone.

This procedure returns the WithdrawToFunding.ID of the earliest successfully processed withdrawal-to-funding record for a customer. "Successfully processed" is defined as CashoutStatusID=3 (the comment in the code confirms this: "Processed withdraw to funding status"). The result is ordered by ModificationDate ASC, returning the single earliest record.

The result is typically used by application services to determine: "Has this customer ever withdrawn successfully?" and "When was their first withdrawal?" The caller can then look up the full record using the returned ID.

---

## 2. Business Logic

### 2.1 First Successful Withdrawal Detection

**What**: Identifies the earliest completion of the withdrawal pipeline for a customer.

**Columns/Parameters Involved**: `CashoutStatusID`, `ModificationDate`

**Rules**:
- `CashoutStatusID = 3` filters to "Processed" withdrawals only (code comment: "Processed withdraw to funding status")
- Other CashoutStatusID values (pending, failed, rejected, etc.) are excluded
- JOIN to Billing.Withdraw ensures only withdrawals belonging to @CID are considered
- `ORDER BY ModificationDate ASC` with `TOP(1)` returns the chronologically first processed record
- Result is a single row with one column (ID); empty result set means no successful withdrawal exists

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Joined to Billing.Withdraw.CID to scope the search to this customer's withdrawals only. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | ID | INT | YES | NULL | CODE-BACKED | Billing.WithdrawToFunding.ID of the first successfully processed withdrawal-to-funding record for this customer (CashoutStatusID=3, earliest ModificationDate). Empty result set if customer has never had a processed withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Withdraw | JOIN | Scopes search to this customer's withdrawals |
| WithdrawID | Billing.WithdrawToFunding | JOIN | CashoutStatusID=3 filter applied here |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services (withdrawal history, promotions, VIP) | @CID | EXEC | Called to check if customer has ever completed a withdrawal |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFirstWithdrawToFunding (procedure)
├── Billing.WithdrawToFunding (table)
└── Billing.Withdraw (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | TOP(1) SELECT where CashoutStatusID=3, ordered by ModificationDate ASC |
| Billing.Withdraw | Table | JOIN on WithdrawID, filter WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application layer for customer lifecycle checks. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if a customer has ever successfully withdrawn

```sql
EXEC Billing.GetFirstWithdrawToFunding @CID = 1234567;
-- Non-empty result: customer has withdrawn. Empty: never withdrawn.
```

### 8.2 Get the full first withdrawal record using the returned ID

```sql
DECLARE @WtfID INT;
EXEC Billing.GetFirstWithdrawToFunding @CID = 1234567;
-- Then use the returned ID to get full record:
SELECT wtf.*, w.CID, w.Amount
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Billing.Withdraw w WITH (NOLOCK) ON wtf.WithdrawID = w.WithdrawID
WHERE wtf.ID = @WtfID;
```

### 8.3 Find all successfully processed withdrawals for a customer

```sql
SELECT wtf.ID, wtf.ModificationDate, wtf.CashoutStatusID, w.Amount
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Billing.Withdraw w WITH (NOLOCK) ON wtf.WithdrawID = w.WithdrawID
WHERE w.CID = 1234567 AND wtf.CashoutStatusID = 3
ORDER BY wtf.ModificationDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFirstWithdrawToFunding | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFirstWithdrawToFunding.sql*
