# Billing.FundingTypeDailyReport_Currency

> Returns yesterday's deposit count grouped by currency for a given payment type, as JSON - used to monitor currency distribution of a payment method.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns JSON array of {Count, Currency} sorted by Count DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingTypeDailyReport_Currency` is the currency-dimension slice of the daily funding type monitoring suite. It queries `Billing.FundingTypeDailyReport_BASE` for yesterday's deposits of a specific payment type and groups by deposit currency abbreviation. Operations teams use this to understand in which currencies a payment method is being used and to identify currency concentration risks.

See `Billing.FundingTypeDailyReport_All` for full suite documentation including BASE function schema and all 8 variants.

---

## 2. Business Logic

### 2.1 Currency Volume Breakdown

**What**: Aggregates deposit counts by transaction currency for the specified payment type.

**Columns/Parameters Involved**: `@fundingTypeID`, `Currency` (from BASE - Dictionary.Currency.Abbreviation via Billing.Deposit.CurrencyID)

**Rules**:
- Currency is the deposit's transaction currency (e.g., USD, EUR, GBP) from Dictionary.Currency.Abbreviation.
- Ordered by Count DESC.
- Time window: GETDATE()-1 to GETDATE().

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
| R1 | Count | int | CODE-BACKED | Number of deposits in this currency yesterday for the specified funding type. |
| R2 | Currency | nvarchar | CODE-BACKED | Currency abbreviation (e.g., "USD", "EUR"). From Dictionary.Currency.Abbreviation via Billing.Deposit.CurrencyID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fundingTypeID | Billing.FundingTypeDailyReport_BASE | Function call | All data retrieval delegated to this inline TVF |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations dashboards | External | Caller | Currency distribution monitoring for a payment method |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDailyReport_Currency (procedure)
└── Billing.FundingTypeDailyReport_BASE (inline TVF)
      ├── Billing.Deposit (table)
      ├── Billing.Funding (table)
      ├── Dictionary.Currency (table)
      └── [other BASE dependencies - see FundingTypeDailyReport_All.md]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDailyReport_BASE | Inline TVF | Provides base dataset; this proc adds GROUP BY Currency + COUNT + FOR JSON AUTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations dashboards | External | Currency distribution monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. FOR JSON AUTO output.

---

## 8. Sample Queries

### 8.1 Get currency breakdown for funding type 35

```sql
EXEC [Billing].[FundingTypeDailyReport_Currency] @fundingTypeID = 35;
-- Returns JSON: [{"Count":200,"Currency":"USD"},{"Count":75,"Currency":"EUR"},...]
```

### 8.2 Ad-hoc currency breakdown without JSON

```sql
SELECT COUNT(*) AS [Count], Currency
FROM [Billing].[FundingTypeDailyReport_BASE](35)
GROUP BY Currency
ORDER BY COUNT(*) DESC;
```

### 8.3 Check all dimension breakdowns for a payment type at once

```sql
EXEC [Billing].[FundingTypeDailyReport_Currency] @fundingTypeID = 35;
EXEC [Billing].[FundingTypeDailyReport_Country] @fundingTypeID = 35;
EXEC [Billing].[FundingTypeDailyReport_Status] @fundingTypeID = 35;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeDailyReport_Currency | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingTypeDailyReport_Currency.sql*
