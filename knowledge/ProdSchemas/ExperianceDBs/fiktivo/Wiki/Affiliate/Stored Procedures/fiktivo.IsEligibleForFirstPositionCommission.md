# fiktivo.IsEligibleForFirstPositionCommission

> Determines whether an affiliate is eligible to receive first-position commissions based on their affiliate type configuration.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsEligible (OUTPUT - returns eligibility flag) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

IsEligibleForFirstPositionCommission checks whether a given affiliate's type has the first-position commission feature enabled. Not all affiliate types are entitled to earn commission when their referred customers open their first trading position; this procedure resolves that eligibility.

The procedure joins the affiliate record to the affiliate type definition and returns the PerFirstPosition flag. This flag acts as a gate in the commission calculation pipeline: if the affiliate's type does not have PerFirstPosition enabled, no first-position commission is computed regardless of customer activity.

This is a lightweight eligibility check typically called before performing the more expensive first-position commission calculation, avoiding unnecessary processing for ineligible affiliates.

---

## 2. Business Logic

### 2.1 Eligibility Lookup via Affiliate Type

**What**: Resolves first-position commission eligibility from the affiliate's type configuration.

**Columns/Parameters Involved**: `@AffiliateID`, `@IsEligible`

**Rules**:
- JOINs dbo.tblaff_Affiliates to dbo.tblaff_AffiliateTypes on AffiliateTypeID
- Returns the PerFirstPosition column from dbo.tblaff_AffiliateTypes into @IsEligible
- If the affiliate or type does not exist, @IsEligible remains NULL

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The unique identifier of the affiliate whose eligibility is being checked. |
| 2 | @IsEligible | BIT (OUTPUT) | YES | NULL | CODE-BACKED | Returns 1 if the affiliate's type is configured for first-position commissions (PerFirstPosition = 1), 0 otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateID | dbo.tblaff_Affiliates | SELECT | Reads affiliate record to resolve AffiliateTypeID |
| @IsEligible | dbo.tblaff_AffiliateTypes | SELECT | Reads PerFirstPosition flag from the affiliate's type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.IsEligibleForFirstPositionCommission (procedure)
├── dbo.tblaff_Affiliates (table, cross-schema)
└── dbo.tblaff_AffiliateTypes (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table (cross-schema) | SELECT to resolve AffiliateTypeID for the given affiliate |
| dbo.tblaff_AffiliateTypes | Table (cross-schema) | SELECT to retrieve PerFirstPosition eligibility flag |

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

### 8.1 Check eligibility for a specific affiliate
```sql
DECLARE @IsEligible BIT
EXEC fiktivo.IsEligibleForFirstPositionCommission @AffiliateID = 1001, @IsEligible = @IsEligible OUTPUT
SELECT @IsEligible AS IsEligibleForFirstPosition
```

### 8.2 List all affiliate types and their first-position eligibility
```sql
SELECT AffiliateTypeID, AffiliateTypeName, PerFirstPosition
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
ORDER BY PerFirstPosition DESC, AffiliateTypeName
```

### 8.3 Find all affiliates eligible for first-position commissions
```sql
SELECT a.AffiliateID, a.AffiliateTypeID, t.PerFirstPosition
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes t WITH (NOLOCK) ON a.AffiliateTypeID = t.AffiliateTypeID
WHERE t.PerFirstPosition = 1
ORDER BY a.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.IsEligibleForFirstPositionCommission | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.IsEligibleForFirstPositionCommission.sql*
