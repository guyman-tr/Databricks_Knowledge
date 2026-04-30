# fiktivo.GetFirstPositionRateForAffiliate

> Returns the first-position commission rate for a specific affiliate, determined by their affiliate type's PerFirstPositionRate setting.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FirstPositionRate OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure looks up the commission rate that an affiliate earns when one of their referred customers closes their first trading position. The rate is determined by the affiliate's type (tblaff_AffiliateTypes.PerFirstPositionRate). This is part of the CPA (Cost Per Acquisition) commission model where affiliates earn a flat or percentage-based commission on first-position events.

Created by Amir Moualem (21/03/2013). JOINs tblaff_Affiliates to tblaff_AffiliateTypes to resolve the rate from the affiliate's assigned type.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple lookup: Affiliate -> AffiliateType -> PerFirstPositionRate.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | Affiliate to look up. References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | @FirstPositionRate (OUT) | FLOAT | YES | - | CODE-BACKED | Commission rate for first-position events. Sourced from tblaff_AffiliateTypes.PerFirstPositionRate via the affiliate's AffiliateTypeID. NULL if affiliate not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (JOIN) | dbo.tblaff_Affiliates | Table read | Reads AffiliateTypeID for the given affiliate. |
| (JOIN) | dbo.tblaff_AffiliateTypes | Table read | Reads PerFirstPositionRate for the affiliate's type. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetFirstPositionRateForAffiliate (procedure)
    ├── dbo.tblaff_Affiliates (table)
    └── dbo.tblaff_AffiliateTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | JOIN to resolve AffiliateTypeID |
| dbo.tblaff_AffiliateTypes | Table | SELECT PerFirstPositionRate |

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

### 8.1 Get first position rate for an affiliate
```sql
DECLARE @rate FLOAT
EXEC fiktivo.GetFirstPositionRateForAffiliate @AffiliateID = 100, @FirstPositionRate = @rate OUTPUT
SELECT @rate AS FirstPositionRate
```

### 8.2 Check rates for multiple affiliates
```sql
SELECT a.AffiliateID, t.AffiliateTypeName, t.PerFirstPositionRate
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes t WITH (NOLOCK) ON a.AffiliateTypeID = t.AffiliateTypeID
WHERE a.AffiliateID IN (100, 200, 300)
```

### 8.3 Find affiliate types with first-position commissions enabled
```sql
SELECT AffiliateTypeID, AffiliateTypeName, PerFirstPositionRate, PerFirstPosition
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE PerFirstPosition = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetFirstPositionRateForAffiliate | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.GetFirstPositionRateForAffiliate.sql*
