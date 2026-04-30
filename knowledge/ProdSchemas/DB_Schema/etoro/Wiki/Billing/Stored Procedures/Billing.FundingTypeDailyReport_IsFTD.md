# Billing.FundingTypeDailyReport_IsFTD

> Returns yesterday's deposit count split by first-time vs returning depositors for a given payment type, as JSON.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns JSON array of {Count, IsFTD} - two rows maximum |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingTypeDailyReport_IsFTD` is the FTD (First Time Depositor) dimension slice of the daily funding type monitoring suite. It tells operations whether yesterday's deposits via a specific payment method were predominantly from new customers making their first deposit, or from returning depositors. This is a key business KPI: FTD rate indicates how well the payment method is performing for customer acquisition vs. retention.

See `Billing.FundingTypeDailyReport_All` for full suite documentation.

---

## 2. Business Logic

### 2.1 First-Time vs Returning Depositor Split

**What**: Counts deposits yesterday grouped by the IsFTD flag.

**Columns/Parameters Involved**: `@fundingTypeID`, `IsFTD` (from BASE - Billing.Deposit.IsFTD)

**Rules**:
- `IsFTD = 1`: customer's first deposit ever on eToro. This deposit was their entry point.
- `IsFTD = 0`: returning customer who has deposited before.
- Results: usually two rows maximum (IsFTD=0 and IsFTD=1). Ordered by Count DESC.
- IsFTD is set at deposit time based on prior deposit history; it does not change after the deposit.

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
| R1 | Count | int | CODE-BACKED | Number of deposits with this IsFTD value yesterday. |
| R2 | IsFTD | bit | CODE-BACKED | 1 = first-time depositor; 0 = returning depositor. From Billing.Deposit.IsFTD. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fundingTypeID | Billing.FundingTypeDailyReport_BASE | Function call | All data retrieval delegated to this inline TVF |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations dashboards | External | Caller | FTD vs returning depositor split monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDailyReport_IsFTD (procedure)
└── Billing.FundingTypeDailyReport_BASE (inline TVF)
      ├── Billing.Deposit (table)
      ├── Billing.Funding (table)
      └── [other BASE dependencies - see FundingTypeDailyReport_All.md]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDailyReport_BASE | Inline TVF | Provides base dataset; this proc adds GROUP BY IsFTD + COUNT + FOR JSON AUTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations dashboards | External | FTD rate monitoring for payment methods |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. FOR JSON AUTO output. Returns at most 2 rows (IsFTD 0 and 1).

---

## 8. Sample Queries

### 8.1 Get FTD split for funding type 35

```sql
EXEC [Billing].[FundingTypeDailyReport_IsFTD] @fundingTypeID = 35;
-- Returns JSON: [{"Count":180,"IsFTD":0},{"Count":45,"IsFTD":1}]
```

### 8.2 Ad-hoc FTD split without JSON

```sql
SELECT COUNT(*) AS [Count], IsFTD
FROM [Billing].[FundingTypeDailyReport_BASE](35)
GROUP BY IsFTD
ORDER BY COUNT(*) DESC;
```

### 8.3 Calculate FTD percentage

```sql
SELECT
    SUM(CASE WHEN IsFTD = 1 THEN 1 ELSE 0 END) AS FTDCount,
    COUNT(*) AS TotalCount,
    100.0 * SUM(CASE WHEN IsFTD = 1 THEN 1 ELSE 0 END) / COUNT(*) AS FTDPct
FROM [Billing].[FundingTypeDailyReport_BASE](35) WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeDailyReport_IsFTD | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingTypeDailyReport_IsFTD.sql*
