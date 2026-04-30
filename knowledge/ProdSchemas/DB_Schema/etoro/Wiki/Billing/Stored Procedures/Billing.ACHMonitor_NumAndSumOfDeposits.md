# Billing.ACHMonitor_NumAndSumOfDeposits

> Daily ACH/PWMB deposit email report that sends an HTML table of yesterday's deposit counts and amounts grouped by funding type and payment status to the application team, used for daily ACH volume monitoring in U.S. operations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input parameters; sends email via msdb.dbo.sp_send_dbmail |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ACHMonitor_NumAndSumOfDeposits` is a daily operational report procedure that aggregates ACH and PWMB (bank transfer) deposits from the prior day and sends an HTML-formatted email to `mimo-rnd-application@etoro.com` with the results. The report is titled "DEPOSITS FROM U.S.A" and describes "deposits done by customers from U.S.A", indicating it is scoped to U.S.-based customers using ACH/bank transfer methods.

The procedure covers two funding types: FundingTypeID=29 (ACH) and FundingTypeID=32 (PWMB - Private Wealth Management Banking or similar bank product). The email is sent via the SQL Server Database Mail system (msdb.dbo.sp_send_dbmail) with an HTML table showing funding name, count, total amount, and status.

The procedure has no parameters and is designed to be called by a daily scheduled job.

---

## 2. Business Logic

### 2.1 Daily Window Aggregation

**What**: Aggregates deposits modified on the prior calendar day.

**Columns/Parameters Involved**: `BD.ModificationDate`

**Rules**:
- Window: `ModificationDate < CAST(GETDATE() AS DATE) AND ModificationDate >= CAST(GETDATE()-1 AS DATE)` - yesterday's calendar day.
- Scope: FundingTypeID IN (29, 32) - ACH and PWMB/bank transfer funding types.
- Grouping: By funding type name and payment status name.
- Aggregation: COUNT(*) as NumOfDeposits, SUM(BD.Amount) as SumOfDeposits.

### 2.2 Email Report Format

**What**: Produces an HTML email with formatted deposit statistics.

**Columns/Parameters Involved**: `@tableHTML`, `@EmailRecipients`

**Rules**:
- Hard-coded recipient: `mimo-rnd-application@etoro.com` (commented fallback: `adico@etoro.com`).
- Subject: `'ACH Reports for {yesterday's date}'` (formatted via `convert(varchar, getutcdate()-1, 103)`).
- HTML table with columns: Funding name, Number of deposits (formatted), Amount of deposits (formatted), Deposit status.
- Numbers formatted with `FORMAT(..., '##,##')` for readability; zero values shown as '0'.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | This procedure has no input parameters. The reporting window (yesterday) and scope (FundingTypeID 29 and 32) are hardcoded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposits | Billing.Deposit | READER | Reads yesterday's deposits filtered by FundingTypeID 29/32 |
| FundingTypeID filter | Dictionary.PaymentStatus | JOIN | Resolves PaymentStatusID to Name for status grouping |
| FundingType name | Billing.Funding | JOIN | JOINed to get FundingTypeID |
| FundingType name | Dictionary.FundingType | JOIN | Resolves FundingTypeID to Name for report display |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT. Called by an external daily scheduled job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ACHMonitor_NumAndSumOfDeposits (procedure)
|- Billing.Deposit (table) [leaf]
|- Dictionary.PaymentStatus (table) [cross-schema leaf]
|- Billing.Funding (table) [leaf]
|- Dictionary.FundingType (table) [cross-schema leaf]
|- msdb.dbo.sp_send_dbmail (system proc) [external]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source: counts and sums deposits by status |
| Dictionary.PaymentStatus | Table | JOINed to resolve PaymentStatusID to status name |
| Billing.Funding | Table | JOINed to get FundingTypeID for filtering |
| Dictionary.FundingType | Table | JOINed to get funding type name for report grouping |
| msdb.dbo.sp_send_dbmail | System Procedure | Sends HTML email report |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. Uses temp table (#T). Hardcoded email recipient and funding type filter. Uses ModificationDate (not PaymentDate) for the daily window.

---

## 8. Sample Queries

### 8.1 Preview yesterday's ACH/PWMB deposit summary without sending email

```sql
SELECT
    DFT.Name AS FundingName,
    COUNT(*) AS NumOfDeposits,
    SUM(BD.Amount) AS SumOfDeposits,
    DPS.Name AS StatusName
FROM Billing.Deposit WITH (NOLOCK) AS BD
INNER JOIN Dictionary.PaymentStatus WITH (NOLOCK) AS DPS ON BD.PaymentStatusID = DPS.PaymentStatusID
INNER JOIN Billing.Funding WITH (NOLOCK) AS BF ON BD.FundingID = BF.FundingID
INNER JOIN Dictionary.FundingType WITH (NOLOCK) AS DFT ON DFT.FundingTypeID = BF.FundingTypeID
WHERE BD.ModificationDate < CAST(GETDATE() AS DATE)
  AND BD.ModificationDate >= CAST(GETDATE()-1 AS DATE)
  AND BF.FundingTypeID IN (29, 32)
GROUP BY DPS.Name, DFT.Name
ORDER BY DFT.Name, DPS.Name
```

### 8.2 Run the report (sends email)

```sql
EXEC Billing.ACHMonitor_NumAndSumOfDeposits
```

### 8.3 Weekly trend of ACH deposit volumes

```sql
SELECT
    CAST(BD.ModificationDate AS DATE) AS ReportDate,
    COUNT(*) AS NumDeposits,
    SUM(BD.Amount) AS TotalAmount
FROM Billing.Deposit WITH (NOLOCK) AS BD
INNER JOIN Billing.Funding WITH (NOLOCK) AS BF ON BD.FundingID = BF.FundingID
WHERE BF.FundingTypeID IN (29, 32)
  AND BD.ModificationDate >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
GROUP BY CAST(BD.ModificationDate AS DATE)
ORDER BY ReportDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHMonitor_NumAndSumOfDeposits | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ACHMonitor_NumAndSumOfDeposits.sql*
