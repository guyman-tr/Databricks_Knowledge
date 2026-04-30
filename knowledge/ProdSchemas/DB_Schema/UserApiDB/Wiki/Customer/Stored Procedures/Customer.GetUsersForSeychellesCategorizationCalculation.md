# Customer.GetUsersForSeychellesCategorizationCalculation

> Retrieves paged GCIDs for Seychelles regulatory categorization calculation from a pre-computed cross-DB table - used when UserSyncApi feature flag is disabled.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paged GCIDs filtered by country and regulation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUsersForSeychellesCategorizationCalculation retrieves GCIDs for users who need Seychelles regulatory categorization recalculation. It reads from DBA.dbo.Yulia_UsersForCalculation (a cross-database pre-computed table in the DBA database) and supports pagination via OFFSET/FETCH. This version is used when the UserSyncApi feature flag is disabled (the legacy path). When the flag is enabled, GetUsersForSeychellesCategorizationCalculationUserSyncApiEnabled is used instead.

---

## 2. Business Logic

### 2.1 Feature Flag Toggle

**What**: Two versions of this SP exist based on the UserSyncApi feature flag.

**Rules**:
- This SP (flag=false): reads from DBA.dbo.Yulia_UsersForCalculation (pre-computed, cross-DB)
- UserSyncApiEnabled version (flag=true): reads from Customer.ContactUserInfo + RiskUserInfo (live data)
- Uses AND logic: CountryID IN @CountryIDs AND DesignatedRegulationID IN @RegulationIDs

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryIDs | dbo.IdList (TVP) | NO | - | CODE-BACKED | Country IDs to filter (Seychelles-regulated countries). |
| 2 | @RegulationIDs | dbo.IdList (TVP) | NO | - | CODE-BACKED | Regulation IDs to filter (Seychelles regulation). |
| 3 | @Offset | int | NO | - | CODE-BACKED | Pagination offset (skip N rows). |
| 4 | @NextRows | int | NO | - | CODE-BACKED | Page size (fetch N rows). |
| 5 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID needing recategorization. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | DBA.dbo.Yulia_UsersForCalculation | FROM | Cross-DB pre-computed table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Seychelles categorization batch job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUsersForSeychellesCategorizationCalculation (procedure)
+-- DBA.dbo.Yulia_UsersForCalculation (cross-DB table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DBA.dbo.Yulia_UsersForCalculation | Table (cross-DB) | FROM - pre-computed user list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Batch processing job |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get first page of users
```sql
DECLARE @Countries dbo.IdList, @Regs dbo.IdList
INSERT @Countries VALUES (195) -- Seychelles
INSERT @Regs VALUES (4) -- Seychelles regulation
EXEC Customer.GetUsersForSeychellesCategorizationCalculation
    @CountryIDs=@Countries, @RegulationIDs=@Regs, @Offset=0, @NextRows=100
```

### 8.2 Compare with enabled version
```sql
-- GetUsersForSeychellesCategorizationCalculation: cross-DB, AND logic, feature flag OFF
-- GetUsersFor...UserSyncApiEnabled: Customer schema tables, OR logic, feature flag ON
```

### 8.3 Get second page
```sql
EXEC Customer.GetUsersForSeychellesCategorizationCalculation
    @CountryIDs=@Countries, @RegulationIDs=@Regs, @Offset=100, @NextRows=100
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetUsersForSeychellesCategorizationCalculation | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetUsersForSeychellesCategorizationCalculation.sql*
