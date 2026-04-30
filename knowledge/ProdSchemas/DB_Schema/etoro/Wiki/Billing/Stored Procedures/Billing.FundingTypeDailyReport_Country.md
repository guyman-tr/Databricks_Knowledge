# Billing.FundingTypeDailyReport_Country

> Returns yesterday's deposit count grouped by customer country for a given payment type, as JSON - used to monitor geographic distribution of a payment method.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns JSON array of {Count, Country} sorted by Count DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingTypeDailyReport_Country` is the country-dimension slice of the daily funding type monitoring suite. It queries `Billing.FundingTypeDailyReport_BASE` for yesterday's deposits of a specific payment type and groups them by the customer's registered country, returning a JSON array ranked by deposit count. Operations teams use this to identify which countries are driving volume for a specific payment method and to spot geographic anomalies.

See `Billing.FundingTypeDailyReport_All` for full suite documentation including the BASE function schema and all 8 variants.

---

## 2. Business Logic

### 2.1 Country Volume Breakdown

**What**: Aggregates deposit counts by customer country for the specified payment type.

**Columns/Parameters Involved**: `@fundingTypeID`, `Country` (from BASE - Dictionary.Country.Name via Customer.Customer.CountryID)

**Rules**:
- Country is the customer's registered country at the time of the deposit (not the card issuer's country).
- Ordered by Count DESC - highest-volume country appears first in the JSON array.
- Time window: GETDATE()-1 to GETDATE() (24h sliding window - results change continuously).
- NULL Country is possible if Customer.Customer.CountryID is not in Dictionary.Country (data quality issue).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fundingTypeID | INT | NO | 35 | CODE-BACKED | Payment instrument type to report on. Default 35. Filters Billing.Funding records by type before aggregation. |

**Return columns** (FOR JSON AUTO):

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | Count | int | CODE-BACKED | Number of deposits from this country yesterday for the specified funding type. |
| R2 | Country | nvarchar | CODE-BACKED | Customer's registered country name. Sourced from Dictionary.Country via Customer.Customer.CountryID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fundingTypeID | Billing.FundingTypeDailyReport_BASE | Function call | All data retrieval delegated to this inline TVF |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations dashboards | External | Caller | Geographic distribution monitoring for a payment method |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDailyReport_Country (procedure)
└── Billing.FundingTypeDailyReport_BASE (inline TVF)
      ├── Billing.Deposit (table)
      ├── Billing.Funding (table)
      ├── Customer.Customer (table)
      ├── Dictionary.Country (table)
      └── [other BASE dependencies - see FundingTypeDailyReport_All.md]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDailyReport_BASE | Inline TVF | Provides base dataset; this proc adds GROUP BY Country + COUNT + FOR JSON AUTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations dashboards | External | Calls for country-level deposit volume monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. No SET NOCOUNT ON. FOR JSON AUTO output. No explicit NOLOCK.

---

## 8. Sample Queries

### 8.1 Get country breakdown for funding type 35

```sql
EXEC [Billing].[FundingTypeDailyReport_Country] @fundingTypeID = 35;
-- Returns JSON: [{"Count":150,"Country":"United States"},{"Count":80,"Country":"Germany"},...]
```

### 8.2 Ad-hoc country breakdown without JSON

```sql
SELECT COUNT(*) AS [Count], Country
FROM [Billing].[FundingTypeDailyReport_BASE](35)
GROUP BY Country
ORDER BY COUNT(*) DESC;
```

### 8.3 Compare country distributions across two funding types

```sql
-- Run for each type and compare JSON output
EXEC [Billing].[FundingTypeDailyReport_Country] @fundingTypeID = 35;
EXEC [Billing].[FundingTypeDailyReport_Country] @fundingTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeDailyReport_Country | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingTypeDailyReport_Country.sql*
