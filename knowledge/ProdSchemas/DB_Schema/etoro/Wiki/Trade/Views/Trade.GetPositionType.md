# Trade.GetPositionType

> Read-only view exposing position type dictionary values (CFD, REAL) excluding the system placeholder ID 255.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ID (from Dictionary.PositionType) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetPositionType exposes the position type taxonomy used across the platform to classify positions as CFD (contract for difference) or REAL (real stock ownership). Each row is a dictionary entry from Dictionary.PositionType, with the system placeholder (ID 255) excluded so callers receive only valid trading position types.

The view exists to provide a single, filtered source for position type lookups. Without it, callers would need to remember to exclude ID 255 or replicate the filter. Used wherever the platform needs to resolve or display position type labels.

---

## 2. Business Logic

### 2.1 Exclusion of System Placeholder (ID 255)

**What**: ID 255 is a reserved/system value and is filtered out from the view.

**Columns/Parameters Involved**: `ID`

**Rules**:
- WHERE ID != 255
- Ensures only valid, user-facing position types appear
- Callers receive CFD (0), REAL (1), and any other non-255 types

---

## 3. Data Overview

| ID | Value | Meaning |
|---|-------|---------|
| 0 | CFD | Contract for difference - leveraged derivative position |
| 1 | REAL | Real stock ownership - customer holds actual shares |

**Selection criteria**: Live MCP sample. Dictionary.PositionType contains at least 0 (CFD) and 1 (REAL). ID 255 excluded per view definition.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Position type identifier from Dictionary.PositionType. Primary key of source table. |
| 2 | Value | varchar | NO | - | CODE-BACKED | Human-readable label: CFD, REAL, or other non-255 types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| ID, Value | Dictionary.PositionType | Base table | Single-table view; all columns from dictionary |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No direct procedure/view references found in etoro/etoro/**/*.sql |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionType (view)
└── Dictionary.PositionType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PositionType | Table | FROM - single source; WHERE ID != 255 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None) | - | No references found; view may be used by external apps or BI tools |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all position types
```sql
SELECT ID, Value
  FROM Trade.GetPositionType WITH (NOLOCK)
 ORDER BY ID;
```

### 8.2 Resolve position type label by ID
```sql
SELECT Value
  FROM Trade.GetPositionType WITH (NOLOCK)
 WHERE ID = 1;
```

### 8.3 Join position data to position type names
```sql
SELECT p.PositionID, p.CID, GPT.Value AS PositionTypeName
  FROM Trade.PositionTbl p WITH (NOLOCK)
  LEFT JOIN Trade.GetPositionType GPT WITH (NOLOCK)
    ON p.PositionTypeID = GPT.ID
 WHERE p.CID = @CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionType | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPositionType.sql*
