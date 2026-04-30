# Trade.GetDemoCopiedCids

> Returns the distinct list of parent CIDs (traders being copied) from the Mirror table - only on DEMO environments. Raises an error if executed on REAL.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDemoCopiedCids retrieves all distinct CIDs of traders who are being copied (parent CIDs in copy-trade relationships) from Trade.Mirror, but ONLY on demo/non-production environments. If executed on a REAL environment (detected via Maintenance.Feature FeatureID=22 value=1), it raises an error and stops.

This procedure exists to support demo environment tooling that needs to know which traders are being actively copied. On demo environments, this data can be used for testing, analytics, or UI previews of copy-trade features. The REAL environment guard prevents accidental production execution of a potentially expensive full-table scan.

---

## 2. Business Logic

### 2.1 Environment Guard

**What**: Prevents execution on REAL (production) environments.

**Columns/Parameters Involved**: `Maintenance.Feature`, `FeatureID=22`

**Rules**:
- FeatureID=22 stores whether the environment is REAL (Value=1) or DEMO (Value!=1)
- If REAL: RAISERROR('Trying to execute SP Trade.GetDemoCopiedCids in REAL', 16, 1)
- If DEMO: proceeds with the query
- Severity 16 terminates the batch

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

This procedure has no input parameters.

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParentCID | int | NO | - | CODE-BACKED | CID of a trader being copied by at least one other customer. DISTINCT from Trade.Mirror.ParentCID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=22 | Maintenance.Feature | FROM | Environment detection (REAL vs DEMO) |
| ParentCID | Trade.Mirror | FROM | All copy-trade relationships |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDemoCopiedCids (procedure)
+-- Maintenance.Feature (table)
+-- Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT - environment check (FeatureID=22) |
| Trade.Mirror | Table | SELECT DISTINCT ParentCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Demo environment tooling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Raises error with severity 16 if FeatureID=22 value is 1 (REAL environment).

---

## 8. Sample Queries

### 8.1 Execute on demo environment

```sql
EXEC Trade.GetDemoCopiedCids;
```

### 8.2 Check which environment you are on

```sql
SELECT Value FROM Maintenance.Feature WITH (NOLOCK) WHERE FeatureID = 22;
-- 1 = REAL, other = DEMO
```

### 8.3 Direct equivalent on demo

```sql
SELECT DISTINCT ParentCID
FROM   Trade.Mirror WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDemoCopiedCids | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDemoCopiedCids.sql*
