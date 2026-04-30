# AffiliateCommission.GetRegistrationRate

> Retrieves the per-registration commission rate and country-specific registration rate overrides for an affiliate type, used to calculate registration commissions.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: base rate + country overrides |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetRegistrationRate retrieves the commission rate an affiliate earns per customer registration. Some affiliates are compensated simply for driving new registrations, regardless of whether those customers trade or deposit. This procedure returns the base per-registration rate and any country-specific overrides.

This procedure was created (February 2022, PART-1195) to support the registration commission model. The commission engine calls this when processing registration events to determine the payout amount. Country-specific rates allow different markets to have different registration commission values, reflecting varying customer acquisition costs across geographies.

---

## 2. Business Logic

### 2.1 Two-Level Rate Resolution

**What**: Registration commission uses a base rate with optional country overrides.

**Columns/Parameters Involved**: `@AffiliateTypeId`, `PerRegistrationRate`, `CountryID`, `Rate`

**Rules**:
- Result Set 1: Base PerRegistrationRate from tblaff_AffiliateTypes (defaults to 0 if NULL)
- Result Set 2: Country-specific overrides from tblaff_Registration2Country
- If a country override exists, it takes precedence over the base rate
- If no country override, the base PerRegistrationRate applies
- The engine uses the variable declaration with default 0 to ensure a non-NULL result even if the affiliate type doesn't exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateTypeId | int (IN) | NO | - | CODE-BACKED | The affiliate type whose registration rates are being queried. |

**Result Set 1:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PerRegistrationRate | float | NO | 0 | CODE-BACKED | Base per-registration commission rate for this affiliate type. Defaults to 0 if not configured. |

**Result Set 2:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | AffiliateTypeID | int | - | - | CODE-BACKED | Affiliate type (echo for join context). |
| 4 | CountryID | int | - | - | CODE-BACKED | Country for which this override rate applies. |
| 5 | Rate | float | - | - | CODE-BACKED | Country-specific registration commission rate. Overrides the base PerRegistrationRate for registrations from this country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateTypeId | dbo.tblaff_AffiliateTypes | READ (SELECT) | Gets base PerRegistrationRate |
| @AffiliateTypeId | dbo.tblaff_Registration2Country | READ (SELECT) | Gets country-specific rate overrides |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the registration commission engine.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetRegistrationRate (procedure)
+-- dbo.tblaff_AffiliateTypes (table, external)
+-- dbo.tblaff_Registration2Country (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table (external) | SELECT PerRegistrationRate by AffiliateTypeID |
| dbo.tblaff_Registration2Country | Table (external) | SELECT country-specific rates by AffiliateTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Registration commission engine) | External | Loads rates for registration commission calculation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get registration rates for affiliate type 1
```sql
EXEC [AffiliateCommission].[GetRegistrationRate] @AffiliateTypeId = 1
```

### 8.2 View all affiliate types with registration rates
```sql
SELECT AffiliateTypeID, PerRegistrationRate
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE PerRegistrationRate > 0
```

### 8.3 View country-specific registration rate overrides
```sql
SELECT AffiliateTypeID, CountryID, Rate
FROM dbo.tblaff_Registration2Country WITH (NOLOCK)
ORDER BY AffiliateTypeID, CountryID
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-1195: New SP for Registration Commission support (2022-02-22, Gil Hava)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetRegistrationRate | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetRegistrationRate.sql*
