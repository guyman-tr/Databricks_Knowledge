# BackOffice.GetWithdrawHeader

> Returns the header-level summary for a single withdrawal: comments, current status, and how much has already been paid out - a minimal view used to render the withdrawal processing header.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID (required); returns 5-column header summary from Billing.Withdraw with AlreadyPaid aggregate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawHeader` retrieves the minimal header data needed to display the top section of a withdrawal processing screen: what the customer said (UserComment/Remark), what the BO manager noted (ManagerComment/Comment), the current status, and how much has already been disbursed (AlreadyPaid).

It uses the same `AlreadyPaid` CTE calculation as `BackOffice.GetWithdraw` - summing completed funding transfers excluding zero-money-movement completions. The difference from `GetWithdraw` is that this procedure returns only 5 columns (no financial amounts, no currencies) rather than the full financial picture.

Added in MIMOPS-358 which added `CashoutStatusID` to the output.

---

## 2. Business Logic

### 2.1 AlreadyPaid Calculation

**What**: Computes how much of the withdrawal amount has been successfully paid out.

**Columns/Parameters Involved**: `AlreadyPaid`, `Billing.WithdrawToFunding.Amount`, `Dictionary.CashoutStatus.IsFinishedWithoutMoneyTransfer`

**Rules**:
- CTE FundingAmount: SUM(BWTF.Amount) WHERE WithdrawID = @WithdrawID AND IsFinishedWithoutMoneyTransfer = 0
- `IsFinishedWithoutMoneyTransfer = 0` excludes funding records where the process completed without actual money movement (cancellations, zero-amount settlements)
- ISNULL(AlreadyPaid, 0) in outer SELECT - 0 if no qualifying funding records exist
- Identical pattern to BackOffice.GetWithdraw (see that procedure for more detail)

### 2.2 Comment Fields

**What**: Returns two distinct comment fields from the withdrawal record.

**Columns/Parameters Involved**: `UserComment`, `ManagerComment`

**Rules**:
- BW.Remark AS UserComment - text the customer entered when submitting the withdrawal request
- BW.Comment AS ManagerComment - internal BO note added by the manager processing the withdrawal
- Both may be NULL or empty

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal to retrieve header data for. Required. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal (Billing.Withdraw.WithdrawID). |
| 2 | UserComment | NVARCHAR | YES | - | CODE-BACKED | Customer's remark/comment submitted with the withdrawal request (Billing.Withdraw.Remark). |
| 3 | ManagerComment | NVARCHAR | YES | - | CODE-BACKED | Internal Back Office comment added by the manager (Billing.Withdraw.Comment). |
| 4 | AlreadyPaid | MONEY | NO | - | VERIFIED | Sum of amounts already transferred via Billing.WithdrawToFunding WHERE IsFinishedWithoutMoneyTransfer=0. 0 if nothing paid yet. Same calculation as BackOffice.GetWithdraw. |
| 5 | CashoutStatusID | INT | NO | - | CODE-BACKED | Current withdrawal status (Billing.Withdraw.CashoutStatusID). Added in MIMOPS-358. Raw ID - join Dictionary.CashoutStatus for name. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BW.WithdrawID = @WithdrawID | Billing.Withdraw | Read (primary) | Withdrawal record |
| BWTF.WithdrawID + CashoutStatus | Billing.WithdrawToFunding | CTE (LEFT JOIN) | AlreadyPaid calculation |
| DCS.CashoutStatusID | Dictionary.CashoutStatus | INNER JOIN (in CTE) | IsFinishedWithoutMoneyTransfer flag |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO withdrawal processing header) | @WithdrawID | Application | Header rendering for withdrawal processing screen |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawHeader (procedure)
├── Billing.Withdraw (table)
├── Billing.WithdrawToFunding (table) - AlreadyPaid CTE
└── Dictionary.CashoutStatus (table) - IsFinishedWithoutMoneyTransfer flag
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Primary - Remark, Comment, CashoutStatusID |
| Billing.WithdrawToFunding | Table | CTE SUM for AlreadyPaid |
| Dictionary.CashoutStatus | Table | CTE JOIN for IsFinishedWithoutMoneyTransfer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO withdrawal processing screens for header data. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsFinishedWithoutMoneyTransfer=0 | Logic | Excludes zero-money-movement funding records from AlreadyPaid sum (same as GetWithdraw). |
| Relationship to GetWithdraw | Design | GetWithdrawHeader returns 5 header-only columns; BackOffice.GetWithdraw returns 6 financial columns. Use GetWithdrawHeader when only comments/status/AlreadyPaid are needed; use GetWithdraw for full financial details. |
| CashoutStatusID added by MIMOPS-358 | History | Originally this procedure returned only WithdrawID, UserComment, ManagerComment, AlreadyPaid. Status was added to avoid a separate status lookup call. |

---

## 8. Sample Queries

### 8.1 Get withdrawal header
```sql
EXEC [BackOffice].[GetWithdrawHeader] @WithdrawID = 123456
```

### 8.2 Direct equivalent query
```sql
;WITH FundingAmount AS (
    SELECT BWTF.WithdrawID, SUM(BWTF.Amount) AS AlreadyPaid
    FROM Billing.WithdrawToFunding BWTF WITH (NOLOCK)
    INNER JOIN Dictionary.CashoutStatus DCS WITH (NOLOCK) ON DCS.CashoutStatusID = BWTF.CashoutStatusID
    WHERE BWTF.WithdrawID = 123456
    AND DCS.IsFinishedWithoutMoneyTransfer = 0
    GROUP BY BWTF.WithdrawID
)
SELECT BW.WithdrawID,
       BW.Remark AS UserComment,
       BW.Comment AS ManagerComment,
       ISNULL(FA.AlreadyPaid, 0) AS AlreadyPaid,
       BW.CashoutStatusID
FROM Billing.Withdraw BW WITH (NOLOCK)
LEFT JOIN FundingAmount FA ON FA.WithdrawID = BW.WithdrawID
WHERE BW.WithdrawID = 123456
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-358 | Jira (DDL comment) | Added CashoutStatusID to output |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira (MIMOPS-358 from DDL comment) | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawHeader | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawHeader.sql*
