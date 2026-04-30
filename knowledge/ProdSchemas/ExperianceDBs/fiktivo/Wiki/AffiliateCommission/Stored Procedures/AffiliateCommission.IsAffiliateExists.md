# AffiliateCommission.IsAffiliateExists

> Simple existence check that returns 1 if an affiliate ID exists in the system, used as a guard in the commission pipeline before processing events.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1 if affiliate exists, empty if not |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

IsAffiliateExists is a lightweight guard procedure that verifies whether an affiliate ID is valid before the commission pipeline processes events attributed to it. If the affiliate doesn't exist (e.g., deleted, never created, or data corruption), the pipeline can skip processing rather than failing downstream.

This procedure queries dbo.tblaff_Affiliates (the core affiliate registry) and returns 1 if found. Unlike a typical "SELECT COUNT(*)" pattern, it uses "SELECT 1 ... WHERE" which returns either a single row with value 1 or an empty result set, leaving the interpretation to the caller.

---

## 2. Business Logic

### 2.1 Affiliate Existence Guard

**What**: Binary check for affiliate existence.

**Columns/Parameters Involved**: `@AffiliateId`

**Rules**:
- SELECT 1 FROM tblaff_Affiliates WHERE AffiliateID = @AffiliateId
- Returns single row with value 1 if affiliate exists
- Returns empty result set if affiliate does not exist
- The caller must handle the empty result set case (no row = affiliate not found)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateId | int (IN) | NO | - | CODE-BACKED | The affiliate ID to validate. Matched against dbo.tblaff_Affiliates.AffiliateID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateId | dbo.tblaff_Affiliates | READ (SELECT) | Checks affiliate existence by AffiliateID |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission pipeline as a validation guard.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.IsAffiliateExists (procedure)
+-- dbo.tblaff_Affiliates (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table (external) | SELECT 1 WHERE AffiliateID = @AffiliateId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Validates affiliate before processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if affiliate 3 exists
```sql
EXEC [AffiliateCommission].[IsAffiliateExists] @AffiliateId = 3
```

### 8.2 List all active affiliates
```sql
SELECT AffiliateID, AffiliateTypeID, AccountTypeID
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
ORDER BY AffiliateID
```

### 8.3 Count total affiliates in system
```sql
SELECT COUNT(*) AS TotalAffiliates
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.IsAffiliateExists | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.IsAffiliateExists.sql*
