# Trade.GetLeveragesWhiteListUsersDistinctGcidsList

> Returns the distinct list of Global Customer IDs (GCIDs) that have custom leverage white-list entries, enabling the application to pre-load override rules for all affected customers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: GCID (distinct list) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLeveragesWhiteListUsersDistinctGcidsList returns the unique set of GCIDs that have at least one entry in Trade.LeveragesRestrictionsWhiteList. This is a companion procedure to Trade.GetLeveragesRestrictionsWhiteList - while that procedure retrieves the specific leverage entries for a single GCID, this one provides the full list of customers who have ANY custom leverage entries.

This procedure exists so the application (Trading API, Trading Settings API) can efficiently determine which customers need custom leverage treatment. On startup or cache refresh, the service calls this to get all affected GCIDs, then calls Trade.GetLeveragesRestrictionsWhiteList for each to load their specific overrides. This avoids per-request database lookups by enabling pre-caching.

---

## 2. Business Logic

### 2.1 Distinct GCID Extraction

**What**: Returns one row per GCID that has white-list entries, regardless of how many instruments are configured.

**Columns/Parameters Involved**: `Trade.LeveragesRestrictionsWhiteList.GCID`

**Rules**:
- Uses SELECT DISTINCT to deduplicate - a GCID with 50 instrument entries still returns once
- No filters - returns ALL GCIDs with white-list entries
- If the white-list table is empty, returns an empty result set
- Used for cache pre-loading: application fetches the list, then iterates calling Trade.GetLeveragesRestrictionsWhiteList per GCID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

This procedure has no parameters.

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | GCID | int | NO | CODE-BACKED | Global Customer ID of a customer who has at least one custom leverage white-list entry. Used by the application to know which customers need leverage override lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT DISTINCT GCID | Trade.LeveragesRestrictionsWhiteList | SELECT (READER) | Reads all distinct GCIDs from the leverage white-list table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TradingSettingsAPI | GRANT EXECUTE | Application User | Calls on startup/cache refresh to identify white-listed customers |
| TAPIUser | GRANT EXECUTE | Application User | Trading API loads white-list customer list |
| PROD_BIadmins | GRANT EXECUTE | Application User | BI analytics on white-list population |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLeveragesWhiteListUsersDistinctGcidsList (procedure)
+-- Trade.LeveragesRestrictionsWhiteList (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LeveragesRestrictionsWhiteList | Table | SELECT DISTINCT GCID from leverage white-list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TradingSettingsAPI | Application User | Cache pre-load |
| TAPIUser | Application User | Cache pre-load |
| PROD_BIadmins | Application User | Analytics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all white-listed GCIDs

```sql
EXEC Trade.GetLeveragesWhiteListUsersDistinctGcidsList;
```

### 8.2 Count white-listed customers

```sql
SELECT  COUNT(DISTINCT GCID) AS WhiteListedCustomerCount
FROM    Trade.LeveragesRestrictionsWhiteList WITH (NOLOCK);
```

### 8.3 White-listed GCIDs with entry counts

```sql
SELECT  GCID,
        COUNT(*) AS InstrumentOverrides,
        MIN(MinLeverage) AS LowestMin,
        MAX(MaxLeverage) AS HighestMax
FROM    Trade.LeveragesRestrictionsWhiteList WITH (NOLOCK)
GROUP BY GCID
ORDER BY InstrumentOverrides DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetLeveragesWhiteListUsersDistinctGcidsList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetLeveragesWhiteListUsersDistinctGcidsList.sql*
