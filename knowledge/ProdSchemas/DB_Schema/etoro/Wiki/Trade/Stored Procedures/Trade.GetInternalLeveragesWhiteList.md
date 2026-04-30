# Trade.GetInternalLeveragesWhiteList

> Returns two result sets: all available leverage values from Trade.GetLeverages, and the whitelist of GCIDs authorized for internal (non-standard) leverage levels.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Two result sets: leverage values + GCID whitelist |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInternalLeveragesWhiteList provides the data needed by admin/ops tools to manage internal leverage authorization. It returns two result sets:

1. **All available leverage values**: From Trade.GetLeverages (a view/table function), ordered ascending. These are the possible leverage multipliers (e.g., 1x, 2x, 5x, 10x, 25x, etc.) that can be offered.
2. **Whitelisted GCIDs**: From Trade.InternalLeveragesWhiteList, optionally filtered to a specific GCID. These are the global customer IDs authorized to use non-standard (internal) leverage levels that exceed the regulated defaults.

When @GCID is NULL, returns all whitelisted customers. When specified, returns only that customer's whitelist entry (if it exists). This supports both the full-list admin view and single-customer verification.

---

## 2. Business Logic

### 2.1 Dual Result Set Pattern

**What**: Returns two independent result sets in one call.

**Rules**:
- Result Set 1: All leverage values (ascending) — always returns full set regardless of @GCID
- Result Set 2: Whitelisted GCIDs — filtered by @GCID if provided
- Application must handle multiple result sets (NextResult / DataReader pattern)

### 2.2 GCID Filtering

**What**: Optional filter on the whitelist result set.

**Rules**:
- `WHERE @GCID = GCID OR @GCID IS NULL` — catch-all pattern
- NULL returns all distinct GCIDs
- Specific value returns only that GCID (if whitelisted)
- Uses DISTINCT to deduplicate (suggests a GCID can have multiple whitelist entries)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | YES | NULL | CODE-BACKED | Global Customer ID to check. NULL returns all whitelisted GCIDs. |

**Result Set 1 — Leverage Values**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | Leverage | varies | Trade.GetLeverages.Value | CODE-BACKED | Available leverage multiplier value (e.g., 1, 2, 5, 10, 25, 50, 100). |

**Result Set 2 — Whitelisted GCIDs**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R2 | GCID | int | Trade.InternalLeveragesWhiteList.GCID | CODE-BACKED | Global Customer ID authorized for internal leverage levels. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.GetLeverages | Read | All available leverage values |
| SELECT | Trade.InternalLeveragesWhiteList | Read (NOLOCK) | Authorized GCIDs for internal leverage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Admin/Ops tools | - | EXEC | Leverage whitelist management UI |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInternalLeveragesWhiteList (procedure)
+-- Trade.GetLeverages (view/function)
+-- Trade.InternalLeveragesWhiteList (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLeverages | View/Function | SELECT - all leverage values ordered ascending |
| Trade.InternalLeveragesWhiteList | Table | SELECT (NOLOCK) - GCID whitelist filtered by @GCID |

---

## 7. Technical Details

### 7.1 Performance Notes

- SET NOCOUNT ON to suppress row count messages
- NOLOCK on whitelist table for non-blocking reads
- DISTINCT on GCID column suggests possible duplicate entries in source table

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all leverage values and all whitelisted GCIDs

```sql
EXEC Trade.GetInternalLeveragesWhiteList;
```

### 8.2 Check if a specific GCID is whitelisted

```sql
EXEC Trade.GetInternalLeveragesWhiteList @GCID = 12345;
```

### 8.3 Query whitelist table directly

```sql
SELECT  DISTINCT GCID
FROM    Trade.InternalLeveragesWhiteList WITH (NOLOCK)
ORDER BY GCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInternalLeveragesWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInternalLeveragesWhiteList.sql*
