# fiktivo.IsEligibleForFirstPositionCommission

> Checks whether a specific affiliate is eligible to receive first-position commissions based on their affiliate type configuration.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsEligible OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure determines if an affiliate is eligible for first-position commissions by checking the PerFirstPosition flag on their assigned affiliate type. Some affiliate types include first-position commissions (earning when a referred customer closes their first trade) while others do not. This is a gating check called before creating first-position commission records.

Created by Amir Moualem (21/03/2013). Companion to `fiktivo.GetFirstPositionRateForAffiliate` which retrieves the actual rate.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple lookup: Affiliate -> AffiliateType -> PerFirstPosition (BIT).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | Affiliate to check. References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | @IsEligible (OUT) | BIT | YES | - | CODE-BACKED | 1=eligible for first-position commissions, 0=not eligible. Sourced from tblaff_AffiliateTypes.PerFirstPosition. NULL if affiliate not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (JOIN) | dbo.tblaff_Affiliates | Table read | Reads AffiliateTypeID for the given affiliate. |
| (JOIN) | dbo.tblaff_AffiliateTypes | Table read | Reads PerFirstPosition eligibility flag. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.IsEligibleForFirstPositionCommission (procedure)
    ├── dbo.tblaff_Affiliates (table)
    └── dbo.tblaff_AffiliateTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | JOIN to resolve AffiliateTypeID |
| dbo.tblaff_AffiliateTypes | Table | SELECT PerFirstPosition |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check eligibility for an affiliate
```sql
DECLARE @eligible BIT
EXEC fiktivo.IsEligibleForFirstPositionCommission @AffiliateID = 100, @IsEligible = @eligible OUTPUT
SELECT @eligible AS IsEligible
```

### 8.2 List all affiliates with first-position eligibility
```sql
SELECT a.AffiliateID, t.AffiliateTypeName, t.PerFirstPosition, t.PerFirstPositionRate
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes t WITH (NOLOCK) ON a.AffiliateTypeID = t.AffiliateTypeID
WHERE t.PerFirstPosition = 1
```

### 8.3 Combined eligibility and rate check
```sql
DECLARE @eligible BIT, @rate FLOAT
EXEC fiktivo.IsEligibleForFirstPositionCommission @AffiliateID = 100, @IsEligible = @eligible OUTPUT
IF @eligible = 1
    EXEC fiktivo.GetFirstPositionRateForAffiliate @AffiliateID = 100, @FirstPositionRate = @rate OUTPUT
SELECT @eligible AS Eligible, @rate AS Rate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.IsEligibleForFirstPositionCommission | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.IsEligibleForFirstPositionCommission.sql*
