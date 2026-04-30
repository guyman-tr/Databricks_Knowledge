# Customer.GetUsersForSeychellesCategorizationCalculationUserSyncApiEnabled

> Retrieves paged GCIDs for Seychelles categorization from live Customer schema tables - used when UserSyncApi feature flag is enabled.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paged GCIDs from Customer schema with OR logic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUsersForSeychellesCategorizationCalculationUserSyncApiEnabled is the feature-flagged replacement for GetUsersForSeychellesCategorizationCalculation. When the UserSyncApi feature flag is enabled, this SP is used instead. It reads from the normalized Customer schema tables (ContactUserInfo + RiskUserInfo) rather than a pre-computed cross-DB table.

Key difference: uses OR logic (CountryID in countries OR DesignatedRegulationID in regulations) vs the original's AND logic. This broader filter catches users who might need recategorization due to either country or regulation changes.

---

## 2. Business Logic

### 2.1 OR-based Filtering (vs AND in legacy)

**What**: Broader user selection using OR instead of AND.

**Rules**:
- WHERE CountryID IN @CountryIDs OR DesignatedRegulationID IN @RegulationIDs
- Legacy version uses AND (narrower filter)
- Joins ContactUserInfo (for CountryID) with RiskUserInfo (for DesignatedRegulationID)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryIDs | dbo.IdList (TVP) | NO | - | CODE-BACKED | Country IDs to filter. |
| 2 | @RegulationIDs | dbo.IdList (TVP) | NO | - | CODE-BACKED | Regulation IDs to filter. |
| 3 | @Offset | int | NO | - | CODE-BACKED | Pagination offset. |
| 4 | @NextRows | int | NO | - | CODE-BACKED | Page size. |
| 5 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Customer.ContactUserInfo | INNER JOIN | Country filter |
| DesignatedRegulationID | Customer.RiskUserInfo | INNER JOIN | Regulation filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Seychelles categorization (feature-flagged) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUsersFor...UserSyncApiEnabled (procedure)
+-- Customer.ContactUserInfo (table)
+-- Customer.RiskUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ContactUserInfo | Table | FROM - CountryID |
| Customer.RiskUserInfo | Table | INNER JOIN - DesignatedRegulationID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Batch processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get users with OR logic
```sql
DECLARE @Countries dbo.IdList, @Regs dbo.IdList
INSERT @Countries VALUES (195)
INSERT @Regs VALUES (4)
EXEC Customer.GetUsersForSeychellesCategorizationCalculationUserSyncApiEnabled
    @CountryIDs=@Countries, @RegulationIDs=@Regs, @Offset=0, @NextRows=100
```

### 8.2 Direct query
```sql
SELECT CUI.GCID
FROM Customer.ContactUserInfo CUI WITH (NOLOCK)
INNER JOIN Customer.RiskUserInfo RUI WITH (NOLOCK) ON CUI.GCID = RUI.GCID
WHERE CUI.CountryID IN (195) OR RUI.DesignatedRegulationID IN (4)
ORDER BY CUI.GCID
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
```

### 8.3 Feature flag comparison
```sql
-- Flag OFF: GetUsersForSeychellesCategorizationCalculation (cross-DB, AND)
-- Flag ON: this SP (Customer schema, OR) - preferred for new development
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetUsersForSeychellesCategorizationCalculationUserSyncApiEnabled | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetUsersForSeychellesCategorizationCalculationUserSyncApiEnabled.sql*
