# Billing.ACHMonitor_NumberOfNewACHAccounts

> Daily ACH and PWMB new account email report that sends an HTML table of new funding accounts created since yesterday, grouped by funding type and verification status, used for daily monitoring of ACH/bank account onboarding volume.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input parameters; sends email via msdb.dbo.sp_send_dbmail |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ACHMonitor_NumberOfNewACHAccounts` produces a daily report of newly linked ACH and PWMB bank accounts (FundingTypeID 29 and 32) created since the previous day. It sends an HTML email to `mimo-rnd-application@etoro.com` titled "NEW ACH AND PWMB ACCOUNTS" with a count of new accounts grouped by funding type name and CustomerFundingStatusID (verification status).

The report answers: "How many new ACH and bank accounts were linked yesterday, and what is their verification status?" The CustomerFundingStatusID column (shown as "Is verified" in the HTML table header) indicates whether the linked account has been verified, pending, or in another onboarding state.

The procedure uses `Billing.CustomerToFunding.Occurred` as the timestamp for new account creation and covers all accounts created since yesterday (`Occurred > CAST(GETDATE()-1 AS DATE)`).

---

## 2. Business Logic

### 2.1 New Account Detection Window

**What**: Counts accounts created since yesterday (not yesterday-only - open-ended from yesterday onwards).

**Columns/Parameters Involved**: `CTF.Occurred`, `BF.FundingTypeID`, `CTF.CustomerFundingStatusID`

**Rules**:
- Window: `CTF.Occurred > CAST(GETDATE()-1 AS DATE)` - all accounts created after midnight yesterday (NOT just yesterday - this is an open-ended window from yesterday going forward).
- Scope: FundingTypeID IN (29, 32).
- Grouping: By CustomerFundingStatusID (verification status) and FundingType name.
- Note: Unlike the deposit/withdrawal reports which use a strict yesterday window, this uses an open-ended start-of-yesterday window.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Window and scope hardcoded. Email recipient hardcoded to mimo-rnd-application@etoro.com. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| New accounts | Billing.CustomerToFunding | READER | Counts new ACH/PWMB account links by Occurred timestamp |
| FundingTypeID filter | Billing.Funding | JOIN | Filters to FundingTypeID IN (29, 32) |
| FundingType name | Dictionary.FundingType | JOIN | Resolves FundingTypeID to display name |

### 5.2 Referenced By (other objects point to this)

No callers found. Called by external daily scheduled job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ACHMonitor_NumberOfNewACHAccounts (procedure)
|- Billing.CustomerToFunding (table) [leaf]
|- Billing.Funding (table) [leaf]
|- Dictionary.FundingType (table) [cross-schema leaf]
|- msdb.dbo.sp_send_dbmail (system proc) [external]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | Primary source for new account links; filtered by Occurred timestamp |
| Billing.Funding | Table | JOINed to filter by FundingTypeID IN (29, 32) |
| Dictionary.FundingType | Table | JOINed to resolve FundingTypeID to Name |
| msdb.dbo.sp_send_dbmail | System Procedure | Sends HTML email report |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Uses temp table (#T3). Window is open-ended start (> yesterday, not = yesterday). CustomerFundingStatusID displayed as raw ID in HTML table (not resolved to name).

---

## 8. Sample Queries

### 8.1 Preview new ACH/PWMB accounts without sending email

```sql
SELECT
    DFT.Name AS FundingName,
    COUNT(*) AS NumOfNewAccount,
    CTF.CustomerFundingStatusID
FROM Billing.CustomerToFunding WITH (NOLOCK) AS CTF
INNER JOIN Billing.Funding WITH (NOLOCK) AS BF ON CTF.FundingID = BF.FundingID
INNER JOIN Dictionary.FundingType WITH (NOLOCK) AS DFT ON DFT.FundingTypeID = BF.FundingTypeID
WHERE CTF.Occurred > CAST(GETDATE()-1 AS DATE)
  AND BF.FundingTypeID IN (29, 32)
GROUP BY CTF.CustomerFundingStatusID, DFT.Name
ORDER BY DFT.Name, CTF.CustomerFundingStatusID
```

### 8.2 Run the report (sends email)

```sql
EXEC Billing.ACHMonitor_NumberOfNewACHAccounts
```

### 8.3 Trend of new ACH accounts per day over past week

```sql
SELECT
    CAST(CTF.Occurred AS DATE) AS Day,
    COUNT(*) AS NewAccounts
FROM Billing.CustomerToFunding WITH (NOLOCK) AS CTF
INNER JOIN Billing.Funding WITH (NOLOCK) AS BF ON CTF.FundingID = BF.FundingID
WHERE CTF.Occurred >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
  AND BF.FundingTypeID IN (29, 32)
GROUP BY CAST(CTF.Occurred AS DATE)
ORDER BY Day
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHMonitor_NumberOfNewACHAccounts | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ACHMonitor_NumberOfNewACHAccounts.sql*
