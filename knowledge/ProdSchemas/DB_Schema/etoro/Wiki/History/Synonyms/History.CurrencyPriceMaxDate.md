# History.CurrencyPriceMaxDate

> Synonym aliasing the remote price database table that stores the maximum date of available currency price data, enabling local code to reference cross-database pricing metadata without hardcoding the remote server name.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.CurrencyPriceMaxDate` is a synonym that maps a local name in the `History` schema to the remote table `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate]` on the `AO-PRICE-LSN-ROR` linked server. The target is the `Price` database on a dedicated pricing server (likely an Azure SQL read-only replica or listener endpoint, as suggested by "LSN-ROR" - possibly "Listener-Read-Only Replica").

The purpose of this synonym is to give local History-schema procedures a stable, server-agnostic name to query currency price availability metadata. If the remote pricing server is renamed or migrated, only the synonym definition needs updating rather than every procedure that references price max-date data.

The target table `CurrencyPriceMaxDate` is expected to store, for each currency pair or instrument, the latest date for which pricing data is available - used by sync and monitoring processes to detect pricing data staleness or gaps.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See the target table documentation in `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate]` for full business logic.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate] | Synonym | Points to currency price max-date table on the AO-PRICE-LSN-ROR pricing server |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CurrencyPriceMaxDate (synonym)
+-- [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate] (external table - pricing server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-PRICE-LSN-ROR].[Price].[History].[CurrencyPriceMaxDate] | External Table | Target of this synonym - all queries routed to this remote table |

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

### 8.1 Query through the synonym

```sql
SELECT TOP 10 *
FROM History.CurrencyPriceMaxDate WITH (NOLOCK)
```

### 8.2 Check the synonym definition

```sql
SELECT
    s.name AS SynonymName,
    s.base_object_name AS TargetObject,
    SCHEMA_NAME(s.schema_id) AS SchemaName
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'CurrencyPriceMaxDate'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.3 Compare with local SYNCurrencyPriceMaxDate synonym

```sql
-- History.CurrencyPriceMaxDate points to AO-PRICE-LSN-ROR (read-only replica)
-- History.SYNCurrencyPriceMaxDate points to Price server (see SYNCurrencyPriceMaxDate doc)
SELECT 'CurrencyPriceMaxDate' AS SynonymName, 'AO-PRICE-LSN-ROR' AS TargetServer
UNION ALL
SELECT 'SYNCurrencyPriceMaxDate', 'Price'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CurrencyPriceMaxDate | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.CurrencyPriceMaxDate.sql*
