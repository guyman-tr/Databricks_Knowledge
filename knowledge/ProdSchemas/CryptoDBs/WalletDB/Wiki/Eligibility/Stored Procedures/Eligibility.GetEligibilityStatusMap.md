# Eligibility.GetEligibilityStatusMap

> Returns the complete status resolution matrix from Eligibility.StatusMap for application-level caching by the Eligibility Service.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Eligibility.StatusMap |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the entire `Eligibility.StatusMap` table - all 20 rows of the group-vs-customer status resolution matrix. The Eligibility Service calls this at startup or periodically to cache the resolution matrix in memory, avoiding database round-trips for every status resolution request. Since the StatusMap is static configuration data, caching it is safe and highly effective.

---

## 2. Business Logic

### 2.1 Full Table Dump for Caching

**What**: Simple SELECT of all columns from StatusMap with NOLOCK.

**Columns/Parameters Involved**: GroupValue, CustomerValue, Status

**Rules**:
- No parameters - returns all 20 rows
- Uses NOLOCK for performance since this is read-only config data
- The application caches the result and uses it to resolve statuses without further DB calls

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupValue | tinyint | NO | - | CODE-BACKED | Group-level eligibility status (0-3). FK to Dictionary.EligibilityStatuses. |
| 2 | CustomerValue | tinyint | YES | - | CODE-BACKED | Customer-level override status (0-3 or NULL). FK to Dictionary.EligibilityStatuses. |
| 3 | Status | tinyint | NO | - | CODE-BACKED | Resolved effective eligibility status after conflict resolution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT FROM | Eligibility.StatusMap | READER | Reads all rows from the resolution matrix |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT project. Called by the Eligibility Service for cache loading.

---

## 6. Dependencies

```
Eligibility.GetEligibilityStatusMap (procedure)
+-- Eligibility.StatusMap (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.StatusMap | Table | Full table read for caching |

### 6.2 Objects That Depend On This

No callers found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute to load the full matrix
```sql
EXEC Eligibility.GetEligibilityStatusMap
```

### 8.2 Direct equivalent query
```sql
SELECT GroupValue, CustomerValue, Status FROM Eligibility.StatusMap WITH (NOLOCK)
```

### 8.3 Verify matrix completeness
```sql
SELECT COUNT(*) AS TotalRows FROM Eligibility.StatusMap WITH (NOLOCK)
-- Should return 20 (4 group values x 5 customer values including NULL)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [User Eligibility Status Update HLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12488704146) | Confluence | Confirms this procedure provides the resolution matrix data that the Eligibility Service caches. The HLD describes the Eligibility Service as the "single point of truth" for status determination. |

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.GetEligibilityStatusMap | Type: Stored Procedure | Source: WalletDB/Eligibility/Stored Procedures/Eligibility.GetEligibilityStatusMap.sql*
