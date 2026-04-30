# History.SYNCurrencyPriceMaxDate

> Synonym aliasing the Price database table that stores the maximum date of available currency price data, providing a local History-schema reference to the price server's currency price availability metadata via the SYN (sync) naming convention.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [Price].[History].[CurrencyPriceMaxDate] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.SYNCurrencyPriceMaxDate` is a synonym pointing to `[Price].[History].[CurrencyPriceMaxDate]` on the `Price` linked server. The "SYN" prefix identifies this as a sync-related synonym, distinct from the closely related `History.CurrencyPriceMaxDate` which points to the AO-PRICE-LSN-ROR read-only replica.

Both synonyms target tables named `CurrencyPriceMaxDate` but on different servers:
- `History.CurrencyPriceMaxDate` -> `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate]` (read-only replica)
- `History.SYNCurrencyPriceMaxDate` -> `[Price].[History].[CurrencyPriceMaxDate]` (Price server - likely the primary)

The "SYN" prefix suggests this synonym is used specifically in synchronization processes that need to read the price max-date from the primary `Price` server (e.g., to check what price data has been synchronized, to detect sync lag, or to drive sync operations). Read queries for analytics would use the replica via `History.CurrencyPriceMaxDate`.

---

## 2. Business Logic

### 2.1 Primary vs Replica Price Server Access

**What**: Two synonyms provide access to the same logical table on different servers for different use cases.

**Rules**:
- `History.SYNCurrencyPriceMaxDate` -> `[Price].[History].[CurrencyPriceMaxDate]` (primary Price server - for sync operations)
- `History.CurrencyPriceMaxDate` -> `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate]` (read-only replica - for analytics)
- "SYN" prefix indicates use in synchronization context

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[Price].[History].[CurrencyPriceMaxDate]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table on the Price server.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [Price].[History].[CurrencyPriceMaxDate] | Synonym | Points to the primary Price server's currency price max-date table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SYNCurrencyPriceMaxDate (synonym)
+-- [Price].[History].[CurrencyPriceMaxDate] (external table - Price server primary)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Price].[History].[CurrencyPriceMaxDate] | External Table | Primary Price server target |

### 6.2 Objects That Depend On This

No dependents found in local schema analysis.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query currency price max dates via this synonym

```sql
SELECT TOP 10 *
FROM History.SYNCurrencyPriceMaxDate WITH (NOLOCK)
```

### 8.2 Compare primary vs replica price max dates

```sql
-- Primary (via SYNCurrencyPriceMaxDate):
SELECT TOP 5 * FROM History.SYNCurrencyPriceMaxDate WITH (NOLOCK)
-- Replica (via CurrencyPriceMaxDate):
SELECT TOP 5 * FROM History.CurrencyPriceMaxDate WITH (NOLOCK)
```

### 8.3 Check both synonym definitions

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.name LIKE '%CurrencyPriceMaxDate%'
ORDER BY s.name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SYNCurrencyPriceMaxDate | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.SYNCurrencyPriceMaxDate.sql*
