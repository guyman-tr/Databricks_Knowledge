# Dictionary.OrderOperationType

> Lookup table defining the two fundamental order operation directions — Open (create a new position) and Close (terminate an existing position).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OrderOperationTypeID (INT IDENTITY, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.OrderOperationType defines the two fundamental trading directions for order operations on the eToro platform: opening a new position and closing an existing one. Every order submitted to the execution engine is classified as either an Open or Close operation.

This table exists because the execution pipeline needs to distinguish between position-creation and position-termination flows. Open operations allocate margin, create new position records, and may trigger CopyTrading replication. Close operations release margin, calculate P&L, and settle the position. The routing, validation, and settlement logic differs entirely between the two.

The OrderOperationTypeID is an IDENTITY column, indicating the values were system-generated. With only 2 rows (1=Open, 2=Close), this is a fundamental binary classification used across the order execution infrastructure.

---

## 2. Business Logic

### 2.1 Binary Order Direction

**What**: Every order operation falls into exactly one of two categories — creating or terminating a position.

**Columns/Parameters Involved**: `OrderOperationTypeID`, `Name`

**Rules**:
- **Open (1)** — The order creates a new position. Triggers margin allocation, risk checks, instrument validation, and potentially CopyTrading mirror replication.
- **Close (2)** — The order terminates an existing position. Triggers P&L calculation, margin release, settlement, and CopyTrading mirror closure.
- These two types are mutually exclusive and collectively exhaustive — every order operation is exactly one type.

**Diagram**:
```
Order Operation Types
├── 1 = Open  → New position created → Margin allocated → Risk checked
└── 2 = Close → Position terminated  → P&L calculated  → Margin released
```

---

## 3. Data Overview

| OrderOperationTypeID | Name | Meaning |
|---|---|---|
| 1 | Open | An order to create a new trading position. The execution engine validates the instrument, checks margin availability, and creates the position record. |
| 2 | Close | An order to terminate an existing trading position. The execution engine calculates P&L, releases margin, and marks the position as closed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderOperationTypeID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key identifying the operation direction. 1=Open (create position), 2=Close (terminate position). IDENTITY NOT FOR REPLICATION — values are not re-seeded during replication. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the operation type. "Open" or "Close". Used in execution reporting and order routing logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK consumers found in the SSDT codebase. Likely consumed at the application layer by the order execution engine.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryOrderOperationType | CLUSTERED PK | OrderOperationTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryOrderOperationType | PRIMARY KEY | Unique order operation type identifier |

---

## 8. Sample Queries

### 8.1 List all order operation types
```sql
SELECT  OrderOperationTypeID,
        Name
FROM    [Dictionary].[OrderOperationType] WITH (NOLOCK)
ORDER BY OrderOperationTypeID;
```

### 8.2 Identify open vs close operations in order tables
```sql
SELECT  oot.Name AS OperationType,
        COUNT(*) AS OrderCount
FROM    [Trade].[OrdersForExecution] o WITH (NOLOCK)
JOIN    [Dictionary].[OrderOperationType] oot WITH (NOLOCK)
        ON o.OrderOperationTypeID = oot.OrderOperationTypeID
GROUP BY oot.Name;
```

### 8.3 Filter only close operations
```sql
SELECT  OrderOperationTypeID,
        Name
FROM    [Dictionary].[OrderOperationType] WITH (NOLOCK)
WHERE   Name = 'Close';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OrderOperationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OrderOperationType.sql*
