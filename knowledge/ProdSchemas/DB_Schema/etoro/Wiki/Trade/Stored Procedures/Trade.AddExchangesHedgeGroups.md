# Trade.AddExchangesHedgeGroups

> Upserts exchange-to-hedge-group mappings using MERGE - updates the GroupID when an ExchangeID match exists, inserts new mappings otherwise.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExchangeGroups (Trade.ExchangeHedgeGroupsTbl TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure manages the mapping between **stock exchanges and hedge groups**. Hedge groups determine which hedging strategy or liquidity provider handles orders for instruments listed on a given exchange. When the trading operations team reconfigures exchange routing, they use this procedure to update or create the mappings.

Without these mappings, the hedging system would not know how to route orders for instruments traded on specific exchanges. The MERGE pattern ensures idempotent behavior - calling the procedure multiple times with the same data is safe.

The caller populates a `Trade.ExchangeHedgeGroupsTbl` TVP with ExchangeID/GroupID pairs and passes it in. The MERGE matches on ExchangeID: existing mappings get their GroupID updated, new ExchangeIDs get inserted.

---

## 2. Business Logic

### 2.1 Upsert via MERGE

**What**: The procedure uses MERGE to atomically insert or update exchange-to-group mappings.

**Columns/Parameters Involved**: `ExchangeID`, `GroupID`

**Rules**:
- WHEN MATCHED: Updates the target GroupID to the source GroupID (exchange reassignment)
- WHEN NOT MATCHED: Inserts a new row with ExchangeID and GroupID (new exchange mapping)
- No DELETE clause - existing mappings not in the TVP are left untouched
- The MERGE is matched on ExchangeID, implying ExchangeID is unique in the target table

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExchangeGroups | Trade.ExchangeHedgeGroupsTbl (TVP) | NO | READONLY | CODE-BACKED | Table-valued parameter containing ExchangeID and GroupID pairs. ExchangeID identifies the stock exchange; GroupID identifies the hedge group that should handle orders for that exchange. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.ExchangeGroups | MERGE | Upserts exchange-to-hedge-group mappings |
| @ExchangeGroups | Trade.ExchangeHedgeGroupsTbl | Parameter (TVP) | Input type definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Operations API) | - | Caller | Called to update exchange routing configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AddExchangesHedgeGroups (procedure)
+-- Hedge.ExchangeGroups (table)
+-- Trade.ExchangeHedgeGroupsTbl (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExchangeGroups | Table | MERGE target - receives upserted exchange group mappings |
| Trade.ExchangeHedgeGroupsTbl | User Defined Type | READONLY TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Assign exchanges to hedge groups

```sql
DECLARE @Groups Trade.ExchangeHedgeGroupsTbl;
INSERT INTO @Groups (ExchangeID, GroupID) VALUES (1, 10), (2, 10), (3, 20);

EXEC Trade.AddExchangesHedgeGroups @ExchangeGroups = @Groups;
```

### 8.2 View current exchange-to-hedge-group mappings

```sql
SELECT  eg.ExchangeID, eg.GroupID
FROM    Hedge.ExchangeGroups eg WITH (NOLOCK)
ORDER BY eg.GroupID, eg.ExchangeID;
```

### 8.3 Find which hedge group handles a specific exchange

```sql
SELECT  eg.GroupID
FROM    Hedge.ExchangeGroups eg WITH (NOLOCK)
WHERE   eg.ExchangeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AddExchangesHedgeGroups | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AddExchangesHedgeGroups.sql*
