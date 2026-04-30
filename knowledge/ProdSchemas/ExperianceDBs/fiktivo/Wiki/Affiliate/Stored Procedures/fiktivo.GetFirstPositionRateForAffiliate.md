# fiktivo.GetFirstPositionRateForAffiliate

> Retrieves the per-first-position commission rate configured for an affiliate based on their affiliate type classification.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FirstPositionRate (OUTPUT - returns the commission rate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFirstPositionRateForAffiliate returns the monetary rate an affiliate earns for each first position opened by one of their referred customers. This rate is not set per affiliate but rather is inherited from the affiliate's type configuration, making it a tier-based commission structure.

The procedure joins the affiliate record to its type definition to retrieve the PerFirstPositionRate value. This rate is typically used during commission calculation workflows to determine how much to credit an affiliate when one of their referrals opens their very first trading position on the platform.

This is a lightweight lookup procedure designed to be called inline during position-closing or commission-processing pipelines where the first-position rate must be resolved quickly.

---

## 2. Business Logic

### 2.1 Rate Lookup via Affiliate Type

**What**: Resolves the first-position commission rate by joining the affiliate to their type.

**Columns/Parameters Involved**: `@AffiliateID`, `@FirstPositionRate`

**Rules**:
- JOINs dbo.tblaff_Affiliates to dbo.tblaff_AffiliateTypes on AffiliateTypeID
- Returns the PerFirstPositionRate column from dbo.tblaff_AffiliateTypes into @FirstPositionRate
- If the affiliate or type does not exist, @FirstPositionRate remains NULL

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The unique identifier of the affiliate whose first-position rate is being retrieved. |
| 2 | @FirstPositionRate | FLOAT (OUTPUT) | YES | NULL | CODE-BACKED | Returns the per-first-position commission rate from the affiliate's type configuration (tblaff_AffiliateTypes.PerFirstPositionRate). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateID | dbo.tblaff_Affiliates | SELECT | Reads affiliate record to resolve AffiliateTypeID |
| @FirstPositionRate | dbo.tblaff_AffiliateTypes | SELECT | Reads PerFirstPositionRate from the affiliate's type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetFirstPositionRateForAffiliate (procedure)
├── dbo.tblaff_Affiliates (table, cross-schema)
└── dbo.tblaff_AffiliateTypes (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table (cross-schema) | SELECT to resolve AffiliateTypeID for the given affiliate |
| dbo.tblaff_AffiliateTypes | Table (cross-schema) | SELECT to retrieve PerFirstPositionRate |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get first position rate for a specific affiliate
```sql
DECLARE @Rate FLOAT
EXEC fiktivo.GetFirstPositionRateForAffiliate @AffiliateID = 1001, @FirstPositionRate = @Rate OUTPUT
SELECT @Rate AS FirstPositionRate
```

### 8.2 Review all affiliate types and their first-position rates
```sql
SELECT AffiliateTypeID, AffiliateTypeName, PerFirstPositionRate
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE PerFirstPositionRate IS NOT NULL
ORDER BY PerFirstPositionRate DESC
```

### 8.3 List affiliates with their resolved first-position rates
```sql
SELECT a.AffiliateID, a.AffiliateTypeID, t.PerFirstPositionRate
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes t WITH (NOLOCK) ON a.AffiliateTypeID = t.AffiliateTypeID
ORDER BY a.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetFirstPositionRateForAffiliate | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.GetFirstPositionRateForAffiliate.sql*
