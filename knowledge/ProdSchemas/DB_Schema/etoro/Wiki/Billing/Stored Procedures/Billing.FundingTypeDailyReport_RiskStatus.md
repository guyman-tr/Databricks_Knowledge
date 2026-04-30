# Billing.FundingTypeDailyReport_RiskStatus

> Returns yesterday's deposit count grouped by risk management status for a given payment type, as JSON - used to monitor fraud and risk flags on a payment method.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns JSON array of {Count, RiskStatus} sorted by Count DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingTypeDailyReport_RiskStatus` is the risk management dimension slice of the daily funding type monitoring suite. Risk management status (from `Billing.Deposit.RiskManagementStatusID`) captures automated fraud and risk checks performed at deposit time. Operations and fraud teams use this procedure to quickly see how many deposits via a specific payment method were flagged by risk management systems versus cleared.

The BASE function uses a LEFT JOIN for `Dictionary.RiskManagementStatus`, so deposits with no risk flag will show `NULL` as the RiskStatus - typically the largest group (clean deposits).

See `Billing.FundingTypeDailyReport_All` for full suite documentation.

---

## 2. Business Logic

### 2.1 Risk Flag Distribution

**What**: Counts deposits yesterday grouped by their risk management classification.

**Columns/Parameters Involved**: `@fundingTypeID`, `RiskStatus` (from BASE - Dictionary.RiskManagementStatus.Name, LEFT JOINed - NULL for unreviewed/clean deposits)

**Rules**:
- RiskStatus is NULL for deposits with no risk management flag (RiskManagementStatusID is NULL in Billing.Deposit).
- Non-NULL values represent flagged deposits (e.g., "Manual Review Required", "Auto Approved", "Flagged").
- The NULL group is typically the majority - it represents clean, auto-approved deposits.
- Ordered by Count DESC - most common risk status first.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fundingTypeID | INT | NO | 35 | CODE-BACKED | Payment instrument type to report on. Default 35. |

**Return columns** (FOR JSON AUTO):

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | Count | int | CODE-BACKED | Number of deposits with this risk status yesterday. |
| R2 | RiskStatus | nvarchar | CODE-BACKED | Risk management status name (from Dictionary.RiskManagementStatus.Name via Billing.Deposit.RiskManagementStatusID). NULL = no risk flag / auto-cleared. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fundingTypeID | Billing.FundingTypeDailyReport_BASE | Function call | All data retrieval delegated to this inline TVF |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations/fraud dashboards | External | Caller | Risk flag monitoring for payment methods |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDailyReport_RiskStatus (procedure)
└── Billing.FundingTypeDailyReport_BASE (inline TVF)
      ├── Billing.Deposit (table)
      ├── Billing.Funding (table)
      ├── Dictionary.RiskManagementStatus (table, LEFT JOIN)
      └── [other BASE dependencies - see FundingTypeDailyReport_All.md]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDailyReport_BASE | Inline TVF | Provides base dataset; this proc adds GROUP BY RiskStatus + COUNT + FOR JSON AUTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations/fraud dashboards | External | Risk flag distribution monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. FOR JSON AUTO output. RiskStatus will include NULL values in GROUP BY.

---

## 8. Sample Queries

### 8.1 Get risk status breakdown for funding type 35

```sql
EXEC [Billing].[FundingTypeDailyReport_RiskStatus] @fundingTypeID = 35;
-- Returns JSON: [{"Count":400,"RiskStatus":null},{"Count":12,"RiskStatus":"Manual Review"},...]
```

### 8.2 Ad-hoc risk status breakdown without JSON

```sql
SELECT COUNT(*) AS [Count], RiskStatus
FROM [Billing].[FundingTypeDailyReport_BASE](35)
GROUP BY RiskStatus
ORDER BY COUNT(*) DESC;
-- NULL RiskStatus = clean deposits
```

### 8.3 Check flagged deposits percentage for a payment type

```sql
SELECT
    SUM(CASE WHEN RiskStatus IS NOT NULL THEN 1 ELSE 0 END) AS FlaggedCount,
    COUNT(*) AS TotalCount,
    100.0 * SUM(CASE WHEN RiskStatus IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) AS FlaggedPct
FROM [Billing].[FundingTypeDailyReport_BASE](35) WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeDailyReport_RiskStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingTypeDailyReport_RiskStatus.sql*
