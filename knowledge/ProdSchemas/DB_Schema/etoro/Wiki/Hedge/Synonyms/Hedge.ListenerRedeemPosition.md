# Hedge.ListenerRedeemPosition

> Cross-database synonym providing transparent access to the redeem position listener table in the HedgeRedeemDB database, used by the hedge system to read positions pending redemption.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Synonym |
| **Key Identifier** | N/A (synonym - no own structure) |
| **Partition** | N/A |
| **Indexes** | N/A (target object indexes apply) |

---

## 1. Business Meaning

`Hedge.ListenerRedeemPosition` is a SQL synonym that provides a stable, schema-local reference to `[HedgeRedeem].[HedgeRedeemDB].[Hedge].[ListenerRedeemPosition]` - a table in the `HedgeRedeemDB` database on a linked server named `HedgeRedeem`.

The "Listener" naming indicates this is a queue-like table that the HedgeRedeem service (a dedicated redemption microservice) writes to when positions need to be redeemed. The Hedge schema's stored procedures can query this synonym as if the table were local, while the actual data lives in the HedgeRedeem microservice's own database.

Redemption in the hedge context refers to the process of closing out hedge positions when eToro customers close their trading positions or when risk thresholds are breached. The HedgeRedeemDB service manages this lifecycle asynchronously; the Hedge DB reads from the listener table to discover which positions are queued for redemption.

This synonym is consumed by `Hedge.GetListenerRedeemPosition`, which exposes the redemption queue to the hedge server.

---

## 2. Business Logic

### 2.1 Cross-Database Redemption Queue Access Pattern

**What**: Provides transparent cross-DB access to the redemption position queue.

**Columns/Parameters Involved**: N/A (synonym delegates to target object's schema)

**Rules**:
- All reads go to `HedgeRedeem` linked server. If the linked server is unavailable, queries against this synonym fail.
- The synonym provides a stable name in the Hedge schema - if the target database/table is moved or renamed, only the synonym definition needs updating, not all consuming code.
- Only `Hedge.GetListenerRedeemPosition` is known to consume this synonym in the SSDT project.
- Cross-DB synonyms require the `HedgeRedeem` linked server to be configured and accessible.

**Diagram**:
```
Hedge DB (etoro)
  |
  | SELECT * FROM [Hedge].[ListenerRedeemPosition]
  |
  v
Synonym resolves to:
  [HedgeRedeem] (linked server)
    -> [HedgeRedeemDB] (database)
       -> [Hedge].[ListenerRedeemPosition] (table)
                  |
                  | written by HedgeRedeem service
                  | when positions are queued for redemption
```

---

## 3. Data Overview

N/A for Synonym. The synonym delegates to the target table; no data is stored in the synonym itself.

---

## 4. Elements

N/A for Synonym. The column structure is defined by the target object `[HedgeRedeem].[HedgeRedeemDB].[Hedge].[ListenerRedeemPosition]`. No elements are defined in the synonym itself.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | [HedgeRedeem].[HedgeRedeemDB].[Hedge].[ListenerRedeemPosition] | Synonym target | Cross-database linked server table holding positions queued for redemption by the HedgeRedeem service |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetListenerRedeemPosition | FROM clause | Synonym reference | Queries this synonym to read the current redemption position queue |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ListenerRedeemPosition (synonym)
└── [HedgeRedeem].[HedgeRedeemDB].[Hedge].[ListenerRedeemPosition] (external table - cross-DB)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [HedgeRedeem].[HedgeRedeemDB].[Hedge].[ListenerRedeemPosition] | External Table (linked server) | Target of the synonym; all queries are transparently forwarded |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetListenerRedeemPosition | Stored Procedure | Reads the redemption position queue via this synonym |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym. The target table's indexes apply.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query the redemption position queue via synonym
```sql
SELECT *
FROM [Hedge].[ListenerRedeemPosition] WITH (NOLOCK)
```

### 8.2 Check synonym definition
```sql
SELECT name, base_object_name, type_desc
FROM sys.synonyms WITH (NOLOCK)
WHERE schema_id = SCHEMA_ID('Hedge')
  AND name = 'ListenerRedeemPosition'
```

### 8.3 Execute the consumer SP to read redemption queue
```sql
EXEC [Hedge].[GetListenerRedeemPosition]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 7/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ListenerRedeemPosition | Type: Synonym | Source: etoro/etoro/Hedge/Synonyms/Hedge.ListenerRedeemPosition.sql*
