# Trade.GetCopyTradeSettlementRestrictions

> Returns all copy trade settlement restriction rules, defining which settlement types are allowed or restricted when positions are copied through the CopyTrader system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Trade.CopyTradeSettlementRestrictions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete set of rules governing how settlement types interact with the copy trading system. When a trader copies another trader's positions, the settlement type of the copied position may need to differ from the original (e.g., the leader trades real stocks but the copier's regulation only allows CFDs). These restriction rules define the allowed combinations.

Without these rules, the copy trading system would not know how to handle settlement type mismatches between leaders and copiers, potentially creating illegal or unsupported position types.

Data flow: Copy trading pre-execution service calls this procedure -> receives all restriction rules -> applies them when determining the settlement type for a new copied position.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a configuration table reader. The business logic resides in the consuming service that interprets the restriction rules.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (all columns) | * | - | - | NAME-INFERRED | All columns from Trade.CopyTradeSettlementRestrictions. Uses SELECT *, so exact columns depend on the table definition. Likely includes settlement type pairs, restriction type, and applicable conditions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.CopyTradeSettlementRestrictions | Read | Reads all restriction rules |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Copy Trading Service | EXEC | Caller | Loads settlement restriction rules for copy trade execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCopyTradeSettlementRestrictions (procedure)
└── Trade.CopyTradeSettlementRestrictions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CopyTradeSettlementRestrictions | Table | Source of all settlement restriction rules |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Copy Trading Service | External | Loads restrictions for copy trade settlement determination |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses SELECT * - fragile if table schema changes

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Trade.GetCopyTradeSettlementRestrictions;
```

### 8.2 Query the table directly

```sql
SELECT * FROM Trade.CopyTradeSettlementRestrictions WITH (NOLOCK);
```

### 8.3 Check restriction count

```sql
SELECT COUNT(*) AS RestrictionCount
FROM Trade.CopyTradeSettlementRestrictions WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 6.4/10 (Elements: 8.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCopyTradeSettlementRestrictions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCopyTradeSettlementRestrictions.sql*
