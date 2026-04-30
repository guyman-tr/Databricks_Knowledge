# BackOffice.HasPendingCashActivities

> For a batch of customer IDs, returns 1/0 flags indicating whether each customer has any pending withdrawal or redeem - used by the Alert Service to prioritize Back Office alerts for customers with active cash operations.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Cids [BackOffice].[IDs] READONLY (TVP of customer IDs); returns one row per CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`HasPendingCashActivities` answers a simple but critical question per customer: "Does this customer currently have any open (non-terminal) withdrawal or redeem?" The result is a 1/0 flag for each, returned for a batch of customers in one query.

The procedure is called by the Back Office **Alert Service** (`AlertServiceUser_Etoro`) as part of its alert prioritization pipeline. The `PrioritizationManager` class uses it for two scoring rules:
- `HasCashOutPriority`: adds score to alerts for customers with pending withdrawals
- `HasRedeemPriority`: adds score to alerts for customers with pending redeems

A Back Office alert for a customer who also has a pending cash activity is treated as higher priority - a compliance or fraud alert on a customer actively withdrawing money is more urgent than the same alert on an inactive customer. The resulting score determines the alert's priority ranking (1-11 scale) shown to Back Office operators.

Called by `AlertServiceUser_Etoro` at alert read time (GET `/api/v1/AlertService/alert/get`). Prioritization runs dynamically and is not stored - this SP is called on-demand for each alert evaluation.

---

## 2. Business Logic

### 2.1 Pending Withdrawal Detection

**What**: Identifies customers with withdrawals in any non-terminal (open/active) status.

**Columns/Parameters Involved**: `HasPendingWithdraw`, `Billing.Withdraw.CashoutStatusID`

**Rules**:
- Uses `EXISTS` - returns 1 as soon as any matching row is found (efficient for 0/1 check)
- Pending statuses: `CashoutStatusID IN (1,2,5,6,9,10,11,12,14,15)` - all non-terminal withdrawal states
- Excludes CashoutStatusID=3 (Processed/Completed) and 4 (Cancelled) - these are terminal states where cash activity is resolved
- One check per CID from the input batch

**Diagram**:
```
@Cids (each ID) -> EXISTS (Billing.Withdraw WHERE CID=ID AND CashoutStatusID IN (1,2,5,6,9,10,11,12,14,15))
  TRUE  -> HasPendingWithdraw = 1
  FALSE -> HasPendingWithdraw = 0
```

### 2.2 Pending Redeem Detection

**What**: Identifies customers with redeems in any non-terminal (open/active) redeem status.

**Columns/Parameters Involved**: `HasPendingRedeem`, `Billing.Redeem.RedeemStatusID`

**Rules**:
- Uses `EXISTS` - efficient 0/1 check
- Pending statuses: `RedeemStatusID IN (1,4,5,6,7,8,100)` - all open/processing redeem states
- One check per CID from the input batch

### 2.3 Alert Prioritization Integration

**What**: The 1/0 flags from this SP are inputs to the Alert Service scoring engine.

**Business Rules**:
- Each rule (`HasCashOutPriority`, `HasRedeemPriority`) adds a positive score contribution when the flag is 1
- Combined with `AlertTypeSeverityPriority` and `FtdPriority` scores, the total determines the alert priority band (1-11 or MaxPriority for score 0-100)
- Higher priority (lower integer, e.g. 1) = displayed first in the Back Office alert queue
- This SP runs asynchronously alongside other priority rules (FTD check via PaymentSystemService, severity check from Alert DB)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cids | [BackOffice].[IDs] READONLY | NO | - | CODE-BACKED | Table-valued parameter of customer IDs (CIDs) to evaluate. Uses the `BackOffice.IDs` UDT (table of INT IDs). The Alert Service passes a batch of CIDs associated with the current set of alerts being prioritized. |

**Output columns (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer identifier (the ID column from @Cids). One row per input CID. |
| 2 | HasPendingWithdraw | BIT/INT | NO | - | VERIFIED | 1 if the customer has at least one withdrawal in a pending/active status (CashoutStatusID IN (1,2,5,6,9,10,11,12,14,15)); 0 otherwise. Per Confluence (Alert prioritization page, 2023): drives the HasCashOutPriority scoring rule in the Alert Service. |
| 3 | HasPendingRedeem | BIT/INT | NO | - | VERIFIED | 1 if the customer has at least one redeem in a pending/active status (RedeemStatusID IN (1,4,5,6,7,8,100)); 0 otherwise. Per Confluence (Alert prioritization page, 2023): drives the HasRedeemPriority scoring rule in the Alert Service. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Cids | BackOffice.IDs | UDT | TVP type for passing the batch of customer IDs |
| CID | Billing.Withdraw | EXISTS check | Checks for non-terminal withdrawal records per customer |
| CID | Billing.Redeem | EXISTS check | Checks for non-terminal redeem records per customer |
| CashoutStatusID | (inline set) | Hardcoded list | (1,2,5,6,9,10,11,12,14,15) defines "pending" withdrawal statuses |
| RedeemStatusID | (inline set) | Hardcoded list | (1,4,5,6,7,8,100) defines "pending" redeem statuses |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AlertService PrioritizationManager | @Cids (batch CIDs) | Caller | HasCashOutPriority and HasRedeemPriority scoring rules call this SP at alert read time (GET /api/v1/AlertService/alert/get) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.HasPendingCashActivities (procedure)
├── BackOffice.IDs (user defined type) [TVP]
├── Billing.Withdraw (table) [EXISTS subquery]
└── Billing.Redeem (table) [EXISTS subquery]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.IDs | User Defined Type | TVP type for @Cids parameter |
| Billing.Withdraw | Table | EXISTS subquery checking non-terminal CashoutStatusID per CID |
| Billing.Redeem | Table | EXISTS subquery checking non-terminal RedeemStatusID per CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AlertService PrioritizationManager | External service | HasCashOutPriority and HasRedeemPriority rules call this to compute alert priority scores |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Query hint | Both Billing.Withdraw and Billing.Redeem use NOLOCK - prioritization reads are non-critical for consistency |
| EXISTS pattern | Optimization | Stops scanning as soon as one matching row is found per CID - efficient for 0/1 flag computation |
| TVP READONLY | Parameter constraint | @Cids cannot be modified within the procedure |

---

## 8. Sample Queries

### 8.1 Check pending cash activity for a batch of customers

```sql
DECLARE @Cids [BackOffice].[IDs];
INSERT INTO @Cids VALUES (123456), (234567), (345678);
EXEC [BackOffice].[HasPendingCashActivities] @Cids = @Cids;
```

### 8.2 Find customers in the batch who have BOTH pending withdraw and redeem

```sql
-- Run the SP and filter results with both flags set
DECLARE @Cids [BackOffice].[IDs];
INSERT INTO @Cids VALUES (123456), (234567), (345678);

EXEC [BackOffice].[HasPendingCashActivities] @Cids = @Cids;
-- In application: filter WHERE HasPendingWithdraw = 1 AND HasPendingRedeem = 1
```

### 8.3 Manually check pending withdrawals for a single customer

```sql
SELECT
    w.CID,
    w.WithdrawID,
    w.CashoutStatusID,
    cs.Name AS StatusName,
    w.Amount,
    w.RequestDate
FROM Billing.Withdraw WITH (NOLOCK) w
JOIN Dictionary.CashoutStatus WITH (NOLOCK) cs ON cs.CashoutStatusID = w.CashoutStatusID
WHERE w.CID = 123456
  AND w.CashoutStatusID IN (1,2,5,6,9,10,11,12,14,15)
ORDER BY w.RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Alert prioritization](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11933614145) | Confluence | Procedure is called by AlertService PrioritizationManager for HasCashOutPriority and HasRedeemPriority scoring rules; results drive alert priority scores for Back Office alert queue; called at GET /api/v1/AlertService/alert/get |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: AlertService caller (permissions grant + Confluence confirmed) | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.HasPendingCashActivities | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.HasPendingCashActivities.sql*
