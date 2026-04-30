# Billing.ACHMonitor_NumAndSumOfWithdraws

> Daily ACH/PWMB withdrawal email report that sends an HTML table of yesterday's withdrawal counts and amounts grouped by funding type and cashout status to the application team, used for daily ACH withdrawal volume monitoring in U.S. operations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input parameters; sends email via msdb.dbo.sp_send_dbmail |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ACHMonitor_NumAndSumOfWithdraws` is the withdrawal counterpart to `Billing.ACHMonitor_NumAndSumOfDeposits`. It aggregates ACH and PWMB (FundingTypeID 29 and 32) withdrawals from the prior day and sends an HTML email to `mimo-rnd-application@etoro.com` titled "WITHDRAWS FROM U.S.A". This daily report gives the application and operations teams visibility into U.S. ACH withdrawal activity grouped by cashout status.

The procedure uses `Billing.WithdrawToFunding.ModificationDate` to determine the reporting window (yesterday) and counts distinct WithdrawIDs (not WithdrawToFunding records) to avoid double-counting where a withdrawal spans multiple funding entries.

---

## 2. Business Logic

### 2.1 Daily Window Aggregation

**What**: Aggregates withdrawals modified on the prior calendar day.

**Columns/Parameters Involved**: `BWTF.ModificationDate`, `BF.FundingTypeID`

**Rules**:
- Window: `BWTF.ModificationDate < CAST(GETDATE() AS DATE) AND BWTF.ModificationDate >= CAST(GETDATE()-1 AS DATE)`.
- Scope: FundingTypeID IN (29, 32) - ACH and PWMB.
- Grouping: By funding type name and cashout status name.
- Aggregation: COUNT(DISTINCT WithdrawID) as NumOfWithdraw, SUM(Amount) as SumOfWithdraw.
- Note: Uses COUNT(DISTINCT WithdrawID) to avoid double-counting withdrawals with multiple WithdrawToFunding entries.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | No input parameters. The reporting window and scope are hardcoded. Email recipient hardcoded to mimo-rnd-application@etoro.com. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Withdrawals | Billing.WithdrawToFunding | READER | Primary source for withdrawal records |
| FundingTypeID filter | Billing.Funding | JOIN | Filters to ACH (29) and PWMB (32) |
| CashoutStatus | Dictionary.CashoutStatus | JOIN | Resolves CashoutStatusID to Name |
| FundingType name | Dictionary.FundingType | JOIN | Resolves FundingTypeID to Name |

### 5.2 Referenced By (other objects point to this)

No callers found. Called by external daily scheduled job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ACHMonitor_NumAndSumOfWithdraws (procedure)
|- Billing.WithdrawToFunding (table) [leaf]
|- Billing.Funding (table) [leaf]
|- Dictionary.CashoutStatus (table) [cross-schema leaf]
|- Dictionary.FundingType (table) [cross-schema leaf]
|- msdb.dbo.sp_send_dbmail (system proc) [external]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Primary data source: withdrawal records filtered by modification date and funding type |
| Billing.Funding | Table | JOINed to filter FundingTypeID IN (29, 32) |
| Dictionary.CashoutStatus | Table | JOINed to resolve CashoutStatusID to status name |
| Dictionary.FundingType | Table | JOINed to get funding type name for report grouping |
| msdb.dbo.sp_send_dbmail | System Procedure | Sends HTML email report |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Uses temp table (#T). COUNT(DISTINCT WithdrawID) prevents double-counting. Hardcoded email recipient.

---

## 8. Sample Queries

### 8.1 Preview yesterday's ACH/PWMB withdrawal summary without sending email

```sql
SELECT
    DFT.Name AS FundingName,
    COUNT(DISTINCT BWTF.WithdrawID) AS NumOfWithdraw,
    SUM(BWTF.Amount) AS SumOfWithdraw,
    DCS.Name AS CashoutStatus
FROM Billing.WithdrawToFunding WITH (NOLOCK) AS BWTF
INNER JOIN Billing.Funding WITH (NOLOCK) AS BF ON BWTF.FundingID = BF.FundingID
INNER JOIN Dictionary.CashoutStatus WITH (NOLOCK) AS DCS ON DCS.CashoutStatusID = BWTF.CashoutStatusID
INNER JOIN Dictionary.FundingType WITH (NOLOCK) AS DFT ON DFT.FundingTypeID = BF.FundingTypeID
WHERE BF.FundingTypeID IN (29, 32)
  AND BWTF.ModificationDate < CAST(GETDATE() AS DATE)
  AND BWTF.ModificationDate >= CAST(GETDATE()-1 AS DATE)
GROUP BY DCS.Name, DFT.Name
ORDER BY DFT.Name, DCS.Name
```

### 8.2 Run the report (sends email)

```sql
EXEC Billing.ACHMonitor_NumAndSumOfWithdraws
```

### 8.3 Compare ACH deposits vs withdrawals for a date

```sql
SELECT 'Deposits' AS Type, COUNT(*) AS Count, SUM(BD.Amount) AS Total
FROM Billing.Deposit WITH (NOLOCK) AS BD
INNER JOIN Billing.Funding WITH (NOLOCK) AS BF ON BD.FundingID = BF.FundingID
WHERE BF.FundingTypeID IN (29, 32)
  AND BD.ModificationDate >= CAST(GETDATE()-1 AS DATE)
  AND BD.ModificationDate < CAST(GETDATE() AS DATE)
UNION ALL
SELECT 'Withdrawals', COUNT(DISTINCT BWTF.WithdrawID), SUM(BWTF.Amount)
FROM Billing.WithdrawToFunding WITH (NOLOCK) AS BWTF
INNER JOIN Billing.Funding WITH (NOLOCK) AS BF ON BWTF.FundingID = BF.FundingID
WHERE BF.FundingTypeID IN (29, 32)
  AND BWTF.ModificationDate >= CAST(GETDATE()-1 AS DATE)
  AND BWTF.ModificationDate < CAST(GETDATE() AS DATE)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHMonitor_NumAndSumOfWithdraws | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ACHMonitor_NumAndSumOfWithdraws.sql*
