# Billing.WithdrawService_GetWithdrawsWithoutRedeems

> Returns all withdrawal requests for a customer that have NOT been redeemed - filtering out any withdrawal already linked to a Billing.Redeem record via the WithdrawToFunding bridge.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INTEGER - the customer whose non-redeemed withdrawals are returned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure answers the question: "which of this customer's withdrawals are still available for processing or further action - specifically those that haven't already been converted into a redemption?" It is a filtered variant of `Billing.WithdrawService_GetWithdraws` that excludes any withdrawal that has been redeemed via the `Billing.Redeem` table.

A "redeem" in eToro's context represents a redemption event - typically when a withdrawal request is converted into a different financial instrument or settlement mechanism. By LEFT JOINing to `Billing.WithdrawToFunding` and then to `Billing.Redeem` and filtering `WHERE r.WithdrawToFundingID IS NULL`, the procedure identifies withdrawals where no `Redeem` record exists for any of their funding legs. This allows the calling service to surface only the non-redeemed withdrawals to the user or downstream process.

Added in two stages: initial creation (PAYUS-3416, 14/04/2022) and then a DISTINCT keyword added to prevent duplicates (PAYUA-3689, 07/07/2022 by Denys M.) - indicating that the JOIN to WithdrawToFunding could multiply rows when a withdrawal has multiple funding legs.

---

## 2. Business Logic

### 2.1 Redeem Exclusion via LEFT JOIN Anti-Pattern

**What**: Withdrawals that have been redeemed are excluded by detecting the absence of a Redeem record linked through the WithdrawToFunding bridge.

**Columns/Parameters Involved**: `WithdrawID` (join key), `wtf.ID` -> `r.WithdrawToFundingID`

**Rules**:
- A withdrawal may have multiple `Billing.WithdrawToFunding` rows (one per funding leg)
- Each `WithdrawToFunding` row may or may not have a corresponding `Billing.Redeem` row
- `WHERE r.WithdrawToFundingID IS NULL` keeps only withdrawals where NO funding leg has a redeem record
- `SELECT DISTINCT` prevents duplicate rows when a withdrawal has multiple WithdrawToFunding legs that all lack redeems

**Diagram**:
```
WithdrawService_GetWithdraws(@cid, @startTime)
  --> @TMP_Withdraw (all withdrawals for customer)
        |
        LEFT JOIN Billing.WithdrawToFunding wtf ON t.WithdrawID = wtf.WithdrawID
              |
              LEFT JOIN Billing.Redeem r ON wtf.ID = r.WithdrawToFundingID
                    |
                    WHERE r.WithdrawToFundingID IS NULL
                    (keep withdrawals where no funding leg has a Redeem)
                          |
                          SELECT DISTINCT (deduplicate multi-leg withdrawals)
                                |
                                --> Return: WithdrawID, CashoutStatusID, RequestDate, Amount, Approved, Fee, FundingID
```

### 2.2 Multi-Leg Deduplication

**What**: A single withdrawal may generate multiple WithdrawToFunding rows (one per payment split or retry), requiring DISTINCT to avoid returning duplicate rows.

**Columns/Parameters Involved**: `DISTINCT`, `wtf.ID`

**Rules**:
- DISTINCT added 07/07/2022 (PAYUA-3689) after duplicates were discovered in production
- Without DISTINCT, a withdrawal with 2 non-redeemed WithdrawToFunding legs would appear twice in the result
- DISTINCT collapses duplicates based on the full output column set: (WithdrawID, CashoutStatusID, RequestDate, Amount, Approved, Fee, FundingID)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | integer | NO | - | CODE-BACKED | Input parameter. Customer identifier. Passed directly to Billing.WithdrawService_GetWithdraws to retrieve all withdrawals for this customer. |
| 2 | @startTime | datetime | YES | NULL | CODE-BACKED | Input parameter. Optional date filter. Passed to Billing.WithdrawService_GetWithdraws. If NULL, all historical withdrawals are included; if provided, only withdrawals with RequestDate >= @startTime. |
| 3 | WithdrawID | int | NO | - | VERIFIED | Output column. Primary key of the withdrawal record from Billing.Withdraw. Not redeemed - no Billing.Redeem record exists for any of its WithdrawToFunding legs. |
| 4 | CashoutStatusID | int | YES | - | VERIFIED | Output column. Current withdrawal status. Values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 5/6=other active states. See [Cashout Status](_glossary.md#cashout-status). (Source: Billing.WithdrawService_GetWithdraws) |
| 5 | RequestDate | datetime | NO | - | CODE-BACKED | Output column. Date and time the customer submitted the withdrawal request. (Source: Billing.Withdraw.RequestDate via WithdrawService_GetWithdraws) |
| 6 | Amount | money | YES | - | CODE-BACKED | Output column. Net withdrawal amount in dollars (gross amount minus fee). E.g., $95.00 for a $100 request with $5 fee. (Source: Billing.Withdraw.Amount) |
| 7 | Approved | bit | YES | - | CODE-BACKED | Output column. Approval flag from Billing.Withdraw. Indicates whether the withdrawal has been approved by operations. (Source: Billing.WithdrawService_GetWithdraws) |
| 8 | Fee | money | YES | - | CODE-BACKED | Output column. Cashout fee in dollars charged for this withdrawal. Taken directly from Billing.Withdraw.Fee (added PAYUA-3811 per WithdrawService_GetWithdraws docs). (Source: Billing.Withdraw.Fee) |
| 9 | FundingID | int | YES | - | CODE-BACKED | Output column. FundingID of the payment instrument used. FK to Billing.Funding.FundingID. (Source: Billing.Withdraw.FundingID) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (EXEC) | Billing.WithdrawService_GetWithdraws | Procedure call | Retrieves all customer withdrawals into @TMP_Withdraw temp table |
| (JOIN) | Billing.WithdrawToFunding | LEFT JOIN | Bridges withdrawal to funding legs to enable Redeem lookup |
| (JOIN) | Billing.Redeem | LEFT JOIN (anti-join) | Identifies redeemed funding legs; WHERE IS NULL excludes them |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No SQL callers found in SSDT repo; called from application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetWithdrawsWithoutRedeems (procedure)
├── Billing.WithdrawService_GetWithdraws (procedure)
│     └── Billing.Withdraw (table)
├── Billing.WithdrawToFunding (table)
└── Billing.Redeem (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawService_GetWithdraws | Stored Procedure | Called via INSERT...EXEC to populate @TMP_Withdraw with all customer withdrawals |
| Billing.WithdrawToFunding | Table | LEFT JOINed to bridge WithdrawID to funding legs (ID column) |
| Billing.Redeem | Table | LEFT JOINed on wtf.ID = r.WithdrawToFundingID; WHERE IS NULL excludes redeemed withdrawals |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called from application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute for a specific customer (all history)

```sql
EXEC Billing.WithdrawService_GetWithdrawsWithoutRedeems
    @cid       = 12345,
    @startTime = NULL;  -- all history
```

### 8.2 Execute with date filter (recent only)

```sql
EXEC Billing.WithdrawService_GetWithdrawsWithoutRedeems
    @cid       = 12345,
    @startTime = DATEADD(MONTH, -3, GETUTCDATE());  -- last 3 months
```

### 8.3 Equivalent direct query showing the anti-join pattern

```sql
SELECT DISTINCT
        w.WithdrawID,
        w.CashoutStatusID,
        w.RequestDate,
        w.Amount,
        w.Approved,
        w.Fee,
        w.FundingID
FROM    Billing.Withdraw w WITH (NOLOCK)
LEFT JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK)
        ON w.WithdrawID = wtf.WithdrawID
LEFT JOIN Billing.Redeem r WITH (NOLOCK)
        ON wtf.ID = r.WithdrawToFundingID
WHERE   w.CID = 12345
        AND r.WithdrawToFundingID IS NULL
ORDER BY w.RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetWithdrawsWithoutRedeems | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetWithdrawsWithoutRedeems.sql*
