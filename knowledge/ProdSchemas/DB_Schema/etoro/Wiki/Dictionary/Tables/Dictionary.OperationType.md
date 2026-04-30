# Dictionary.OperationType

> Lookup table defining the 26 types of trading operations (open, close, cancel, admin actions) with fee classification linkage.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Row Count** | 26 rows |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.OperationType classifies every type of trading operation the eToro execution engine can perform. Each operation type represents a distinct action in the position lifecycle — from opening and closing positions to canceling pending orders, handling mirror (copy-trading) operations, and administrative interventions.

The FeeOperationTypeID column links each operation to its fee category via Dictionary.FeeOperationTypes. Operations that result in opening a position are classified as "Open" fee operations (FeeOperationTypeID=1), and operations that close positions are classified as "Close" fee operations (FeeOperationTypeID=2). Cancel and status-update operations have NULL fee classification since they don't trigger fee charges.

This table is central to the trading engine's operation routing. The OperationTypeID stored in order and execution records determines which code path processes the operation, which fees apply, and how the operation is logged.

---

## 2. Business Logic

### 2.1 Operation Categories

**What**: Operations group into functional categories: regular trading, mirror (copy-trading), cancellations, status updates, admin, and special actions.

**Columns/Parameters Involved**: `ID`, `OperationTypeName`, `FeeOperationTypeID`

**Rules**:

| Category | IDs | Fee Type | Description |
|----------|-----|----------|-------------|
| **Regular Open** | 0, 14 | Open (1) | Standard position opening — user clicks "Buy" or "Sell" |
| **Mirror Open** | 1 | Open (1) | Position opened as part of CopyTrading replication |
| **Regular Close** | 2, 12, 13 | Close (2) | Standard position closure — user-initiated, SL/TP trigger, or limit |
| **Mirror Close** | 3 | Close (2) | Position closed because the copied trader closed theirs |
| **Cancellations** | 4, 5, 6, 7 | None | Canceling pending or delayed orders — no fees |
| **Status Updates** | 8, 9, 10, 11 | Open/Close/None | Order filled or rejected — fees only on successful fill |
| **Operational** | 15, 16, 17 | Open/Close/None | Operations team manual open/close/adjustment |
| **Direct** | 18, 19 | Open/Close | Direct market operations bypassing standard flow |
| **Admin** | 22, 23, 24 | Open | Admin-initiated position opening (with/without hedge) |
| **Reopen** | 25 | Open | Position reopened after previous closure (error correction) |

### 2.2 Fee Classification

**What**: Every fee-generating operation maps to exactly one fee category.

**Columns/Parameters Involved**: `FeeOperationTypeID`

**Rules**:
- FeeOperationTypeID=1 (Open): Spread fee charged when position is created
- FeeOperationTypeID=2 (Close): No additional spread on close (already baked into open spread), but overnight fees apply during position lifetime
- FeeOperationTypeID=NULL: No fee — cancellations, rejections, and non-trade operations

---

## 3. Data Overview

| ID | OperationTypeName | FeeOpType | Meaning |
|---|---|---|---|
| 0 | OrderForOpen | Open | Standard market order to open a new position. The primary entry point for manual trades. |
| 1 | OrderForOpenInMirror | Open | Order to open a position as part of CopyTrading. Triggered when the copied leader opens a trade. |
| 2 | OrderForClose | Close | Standard order to close an existing position. Triggered by user clicking "Close" or by SL/TP. |
| 3 | OrderForCloseInMirror | Close | Close triggered by CopyTrading — the leader closed their position, so all copiers' mirrored positions close. |
| 4 | CancelDelayedOrderForOpen | None | Cancel a pending entry order (limit/stop) before it fills. No fees. |
| 12 | PositionClose | Close | Direct position closure (bypasses order flow). Used for system-initiated closes (margin call, overnight expiry). |
| 14 | PositionOpen | Open | Direct position creation (bypasses order flow). Used for system-initiated opens (corporate actions, splits). |
| 22 | AdminOrderForOpenWithHedge | Open | Admin opens a position AND creates a corresponding hedge position. For error correction with full risk management. |
| 25 | Reopen | Open | Position reopened after erroneous closure. Reverses a close by creating a new open with original parameters. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the operation type. 0-25. Referenced by order and execution tables to classify each trading action. See [Operation Type](_glossary.md#operation-type). (Dictionary.OperationType) |
| 2 | OperationTypeName | varchar(50) | NO | - | VERIFIED | PascalCase operation name used in code routing and API classification. Descriptive enough to identify the action without looking up the ID. |
| 3 | FeeOperationTypeID | tinyint | YES | - | VERIFIED | FK to Dictionary.FeeOperationTypes. 1=Open (spread charged), 2=Close (no additional spread), NULL=no fee applies. Determines which fee calculation logic runs for this operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Verified |
|---------|---------------|-------------------|----------|
| FeeOperationTypeID | Dictionary.FeeOperationTypes | FK (explicit) | Yes — FK_OperationType_FeeOperationType |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade order/execution tables | OperationTypeID | Implicit Lookup | Classifies every trading operation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.OperationType
 └── Dictionary.FeeOperationTypes (FK: FeeOperationTypeID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FeeOperationTypes | Table | FK: Fee classification for operations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_OperationType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_OperationType | PRIMARY KEY | Unique operation type identifier |
| FK_OperationType_FeeOperationType | FOREIGN KEY | FeeOperationTypeID → Dictionary.FeeOperationTypes |

---

## 8. Sample Queries

### 8.1 List all operations with fee classification
```sql
SELECT  o.ID, o.OperationTypeName, o.FeeOperationTypeID,
        ISNULL(f.Name, 'No Fee') AS FeeCategory
FROM    [Dictionary].[OperationType] o WITH (NOLOCK)
LEFT JOIN [Dictionary].[FeeOperationTypes] f WITH (NOLOCK) ON o.FeeOperationTypeID = f.FeeOperationTypeID
ORDER BY o.ID;
```

### 8.2 Find all fee-generating operations
```sql
SELECT  o.ID, o.OperationTypeName, f.Name AS FeeType
FROM    [Dictionary].[OperationType] o WITH (NOLOCK)
JOIN    [Dictionary].[FeeOperationTypes] f WITH (NOLOCK) ON o.FeeOperationTypeID = f.FeeOperationTypeID
ORDER BY f.Name, o.ID;
```

---

*Generated: 2026-03-13 | Enriched: MCP live data | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OperationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OperationType.sql*
