# Dictionary.AtomicOperationsForBlocking

> Lookup table defining the 20 atomic (leaf-level) trading operations that can be individually blocked for a customer. These operations are the finest granularity in the blocking hierarchy; higher-level OperationTypesForBlocking decompose into these via a bridge table.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OperationID (int, PK CLUSTERED) |
| **Filegroup** | PRIMARY |
| **Row Count** | 20 (MCP verified) |
| **Indexes** | 1 active (PK only) |
| **FILLFACTOR** | 95 |

---

## 1. Business Meaning

Dictionary.AtomicOperationsForBlocking defines the most granular (atomic) trading operations that can be individually blocked for a customer. These are the leaf-level operations that higher-level "operation types for blocking" decompose into. Instead of blocking an entire category like "Trading," the system can block specific actions such as Position Open, Manual Edit SL, Order Close, or Manual Pause Copy. This enables fine-grained risk and compliance controls — for example, allowing a customer to close existing positions while blocking new trades.

The table is the target of the bridge table Trade.OperationTypeForBlockingToAtomic, which maps each OperationTypeForBlocking (parent) to one or more AtomicOperationsForBlocking (child). When Customer.BlockedCustomerOperations records a block at the OperationType level, the actual enforcement happens by resolving to atomic operations via this mapping. Procedures such as Trade.GetOrderForOpenContextData, Trade.GetOrderForCloseContextData, and Trade.GetUserWithRestirctions join BlockedCustomerOperations to OperationTypeForBlockingToAtomic and AtomicOperationsForBlocking to determine which specific actions are blocked.

**OperationID values 1–20** cover the full spectrum of copy-trading and manual operations: copy lifecycle (Copy User, Copied, Public Portfolio Visible), core trading (Trading, Position Open, Manual Position Close), orders (Open Entry Order, Open Order, Manual Close Entry Order, Order Close), and mirror-specific edits (Manual Edit SL, Manual Edit TP, Manual Edit TSL, Manual Edit Mirror SL, Manual Edit Mirror SL Percentage, Manual Pause Copy, Manual Unregister Mirror). Each atomic operation corresponds to a distinct user action that BackOffice or compliance may need to restrict.

---

## 2. Business Logic

### 2.1 Atomic Operation Hierarchy

**What**: How atomic operations relate to operation types for blocking.

**Columns/Parameters Involved**: `OperationID`, `Description`

**Rules**:
- **Atomic = Leaf**: Each row in AtomicOperationsForBlocking is a single, indivisible action (e.g., "Manual Edit SL" or "Order Close"). No further decomposition.
- **Bridge mapping**: Trade.OperationTypeForBlockingToAtomic links OperationTypeID → AtomicOperationID. One operation type may map to multiple atomic operations.
- **Block resolution**: When a customer has blocked operations, the system joins Customer.BlockedCustomerOperations → Trade.OperationTypeForBlockingToAtomic → Dictionary.AtomicOperationsForBlocking to get the list of blocked atomic OperationIDs.
- **Enforcement**: Trade.GetOrderForOpenContextData and Trade.GetOrderForCloseContextData use this chain to determine if a specific order/position action is blocked for the customer.

**Diagram**:
```
Operation Type (e.g., "Trading")     Atomic Operations (leaf)
Dictionary.OperationTypesForBlocking   Dictionary.AtomicOperationsForBlocking
         │                                        │
         │    Trade.OperationTypeForBlockingToAtomic (bridge)
         │         OperationTypeID  →  AtomicOperationID
         │                                        │
         └──► Blocked for CID  ──────────────────►  Position Open (5)
                                                   Order Close (17)
                                                   Open Entry Order (8)
                                                   ...
```

### 2.2 Common Filtering Patterns

**What**: How atomic operations are used in blocking logic.

**Columns/Parameters Involved**: `OperationID` (referenced as AtomicOperationID in bridge)

**Rules**:
- Blocking is applied at the OperationType level in Customer.BlockedCustomerOperations; atomic IDs are resolved via the bridge.
- Procedures join BCO.OperationTypeID = OTFBA.OperationTypeID and OTFBA.AtomicOperationID = aob.OperationID to get the Description for display or to check against the current action.

---

## 3. Data Overview

| OperationID | Description | Meaning |
|---|---|---|
| 1 | Copy User | Copy-trading: register/copy another user (trader). Blocked when CopyTrading is restricted. |
| 4 | Trading | General trading activity. High-level block affecting multiple atomic ops. |
| 5 | Position Open | Opening a new position. Blocked when new trades are restricted. |
| 12 | Manual Edit SL | Editing Stop-Loss on a position. Risk control for limiting loss adjustments. |
| 20 | Manual Pause Copy | Pausing a CopyTrading relationship. Operational control. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationID | int | NO | - | VERIFIED | Primary key; unique identifier for the atomic operation. Range 1–20. Referenced by Trade.OperationTypeForBlockingToAtomic.AtomicOperationID (FK). MCP-verified 20 rows. |
| 2 | Description | varchar(50) | NO | - | VERIFIED | Human-readable label for the operation (e.g., "Position Open", "Manual Edit SL"). Used in joins for display and logging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OperationTypeForBlockingToAtomic | AtomicOperationID | Explicit FK | Bridge table maps operation types to atomic operations |
| Trade.GetOrderForOpenContextData | OTFBA.AtomicOperationID | JOIN | Resolves blocked atomic ops for order open context |
| Trade.GetOrderForCloseContextData | OTFBA.AtomicOperationID | JOIN | Resolves blocked atomic ops for order close context |
| Trade.GetUserWithRestirctions | OTFBA.AtomicOperationID | JOIN | Returns user restrictions including atomic operation IDs |
| Trade.CustomerRestrictionCIDs_Wrapper | (via BCO→OTFBA) | Indirect | Block resolution chain |
| Trade.GetRestrictionsByTradingOperationTypes | (via BCO→OTFBA) | Indirect | Restriction lookup |
| Trade.GetCustomersRestrictionsByTypesForAPI | (via BCO→OTFBA) | Indirect | API restriction exposure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.AtomicOperationsForBlocking (table)
  └── referenced by Trade.OperationTypeForBlockingToAtomic (FK)
  └── consumed via bridge by Customer.BlockedCustomerOperations (indirect)
  └── used by Trade.GetOrderForOpenContextData, GetOrderForCloseContextData, GetUserWithRestirctions
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OperationTypeForBlockingToAtomic | Table | FK AtomicOperationID → OperationID |
| Trade.GetOrderForOpenContextData | Stored Procedure | JOIN via bridge for blocking check |
| Trade.GetOrderForCloseContextData | Stored Procedure | JOIN via bridge for blocking check |
| Trade.GetUserWithRestirctions | Stored Procedure | JOIN via bridge for restriction list |
| Trade.CustomerRestrictionCIDs_Wrapper | Stored Procedure | Indirect via BCO + bridge |
| Trade.GetRestrictionsByTradingOperationTypes | Stored Procedure | Indirect via BCO + bridge |
| Trade.GetCustomersRestrictionsByTypesForAPI | Stored Procedure | Indirect via BCO + bridge |
| tradonomi.Trade.GetOrderForOpenContextData | Stored Procedure | Same pattern as etoro |
| tradonomi.Trade.GetOrderForCloseContextData | Stored Procedure | Same pattern as etoro |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AtomicOperationsForBlocking | CLUSTERED PK | OperationID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|------------------------|
| PK_AtomicOperationsForBlocking | PRIMARY KEY | Unique operation identifier, PRIMARY filegroup, FILLFACTOR 95 |

---

## 8. Sample Queries

### 8.1 List all atomic operations
```sql
SELECT  OperationID,
        Description
FROM    Dictionary.AtomicOperationsForBlocking WITH (NOLOCK)
ORDER BY OperationID;
```

### 8.2 Resolve operation types to atomic operations (via bridge)
```sql
SELECT  otb.OperationTypeID,
        otb.OperationDescription,
        aob.OperationID,
        aob.Description AS AtomicDescription
FROM    Dictionary.OperationTypesForBlocking otb WITH (NOLOCK)
JOIN    Trade.OperationTypeForBlockingToAtomic otfba WITH (NOLOCK)
        ON otb.OperationTypeID = otfba.OperationTypeID
JOIN    Dictionary.AtomicOperationsForBlocking aob WITH (NOLOCK)
        ON otfba.AtomicOperationID = aob.OperationID
ORDER BY otb.OperationTypeID, aob.OperationID;
```

### 8.3 Count customers blocked per atomic operation
```sql
SELECT  aob.Description,
        COUNT(DISTINCT bco.CID) AS BlockedCustomerCount
FROM    Customer.BlockedCustomerOperations bco WITH (NOLOCK)
JOIN    Trade.OperationTypeForBlockingToAtomic otfba WITH (NOLOCK)
        ON bco.OperationTypeID = otfba.OperationTypeID
JOIN    Dictionary.AtomicOperationsForBlocking aob WITH (NOLOCK)
        ON otfba.AtomicOperationID = aob.OperationID
GROUP BY aob.Description
ORDER BY BlockedCustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data (20 operations), codebase analysis of Trade.OperationTypeForBlockingToAtomic, Customer.BlockedCustomerOperations, and Trade procedures (GetOrderForOpenContextData, GetOrderForCloseContextData, GetUserWithRestirctions).

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AtomicOperationsForBlocking | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AtomicOperationsForBlocking.sql*
