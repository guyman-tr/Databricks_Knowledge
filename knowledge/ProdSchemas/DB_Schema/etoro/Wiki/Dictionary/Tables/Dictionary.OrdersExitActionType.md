# Dictionary.OrdersExitActionType

> Lookup table defining exit order action types — currently empty in production, reserved for future classification of exit order resolution outcomes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ActionTypeID (INT, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.OrdersExitActionType is designed to classify the resolution outcomes of exit orders (orders that close or partially close existing positions). Exit orders include stop-loss triggers, take-profit triggers, and manual close orders submitted against open positions.

This table exists as a structural counterpart to Dictionary.OrdersEntryActionType, following the pattern of separate action-type dictionaries for entry vs exit order flows. However, the table is currently empty in production — exit order outcomes are likely tracked through other mechanisms (e.g., ClosePositionActionType or the execution engine's application-layer classification).

The DDL defines the structure and the PK constraint, indicating the table is ready for use if the exit order tracking system is expanded to use a dictionary-based classification.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is currently empty. When populated, it would follow the same pattern as OrdersEntryActionType — classifying how exit orders are resolved (executed, failed, cancelled, etc.).

---

## 3. Data Overview

This table is empty in production (0 rows). No data to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionTypeID | int | NO | - | CODE-BACKED | Primary key identifying the exit order action type. Currently no values populated. When used, would classify exit order outcomes (execution, failure, cancellation). |
| 2 | ActionName | varchar(35) | NO | - | CODE-BACKED | Human-readable label for the exit order action type. NOT NULL constraint ensures all action types have a descriptive name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No consumers found in the SSDT codebase. Table is empty and not actively referenced.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryOrdersExitActionType | CLUSTERED PK | ActionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryOrdersExitActionType | PRIMARY KEY | Unique exit order action type identifier |

---

## 8. Sample Queries

### 8.1 List all exit order action types
```sql
SELECT  ActionTypeID,
        ActionName
FROM    [Dictionary].[OrdersExitActionType] WITH (NOLOCK)
ORDER BY ActionTypeID;
```

### 8.2 Check if table has been populated
```sql
SELECT  COUNT(*) AS RowCount
FROM    [Dictionary].[OrdersExitActionType] WITH (NOLOCK);
```

### 8.3 Compare with entry action types
```sql
SELECT  'Entry' AS OrderDirection, ActionTypeID, ActionName
FROM    [Dictionary].[OrdersEntryActionType] WITH (NOLOCK)
UNION ALL
SELECT  'Exit' AS OrderDirection, ActionTypeID, ActionName
FROM    [Dictionary].[OrdersExitActionType] WITH (NOLOCK)
ORDER BY OrderDirection, ActionTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrdersExitActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrdersExitActionType.sql*
