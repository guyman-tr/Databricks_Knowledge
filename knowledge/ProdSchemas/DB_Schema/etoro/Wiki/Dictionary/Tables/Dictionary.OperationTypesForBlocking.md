# Dictionary.OperationTypesForBlocking

> Lookup table defining the high-level operation categories that can be blocked per customer. Parent level in a two-tier blocking system with AtomicOperationsForBlocking.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OperationTypeID (int, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.OperationTypesForBlocking defines the high-level operation categories that can be blocked per customer. It works as the parent level in a two-tier blocking system: this table defines *what* can be blocked (e.g., Copy User, Trading, Manual Edit SL), while Dictionary.AtomicOperationsForBlocking defines the granular sub-operations, and Trade.OperationTypeForBlockingToAtomic maps between them. Customer.BlockedCustomerOperations stores the actual per-customer blocks.

Used by compliance, risk, and BackOffice to selectively restrict what a customer can do. For example, a customer might be blocked from Copy Trading (Copy User, Copied) but allowed manual trading (Trading, Position Open). The 24 operation types cover copy trading, order management, mirror management, and internal instrument access. SettingsDB maintains a replicated copy for distributed resolution via Trading.BlockedCustomerOperationsResolver.

---

## 2. Business Logic

### 2.1 Two-Tier Blocking Model

**What**: OperationTypesForBlocking = parent; AtomicOperationsForBlocking = child. Trade.OperationTypeForBlockingToAtomic bridges them. Customer.BlockedCustomerOperations stores blocks at the OperationTypeID level.

**Columns/Parameters Involved**: `OperationTypeID`, `OperationDescription`

**Rules**:
- **OperationTypeID 1–24**: Each ID maps to a human-readable OperationDescription.
- **Blocking flow**: BackOffice blocks OperationTypeID for a CID → Customer.BlockedCustomerOperations. Resolution uses Trade.OperationTypeForBlockingToAtomic to expand to AtomicOperations when needed.
- **Replication**: SettingsDB.Dictionary.OperationTypesForBlocking holds a copy; SettingsDB.Trading.BlockedCustomerOperationsResolver resolves blocks across environments.

**Diagram**:
```
Blocking Flow:

  BackOffice blocks OperationTypeID for CID
        │
        ▼
  Customer.BlockedCustomerOperations (OperationTypeID)
        │
        ▼
  Customer.OperationBlockForCID / GetBlockedOperationsForCID
        │
        ├── Trade.OperationTypeForBlockingToAtomic (map to AtomicOperations)
        └── SettingsDB.BlockedCustomerOperationsResolver (replicated resolver)
```

---

## 3. Data Overview

| OperationTypeID | OperationDescription | Meaning |
|---|---|---|
| 1 | Copy User | Copy trading: registering as a copier |
| 2 | Copied | Being copied by others |
| 4 | Trading | General trading operations |
| 5 | Position Open | Opening new positions |
| 12 | Manual Edit SL | Manual stop-loss edit |
| 20 | Manual Pause Copy | Pausing copy trading |

*Sample of 24 MCP-verified rows. Full list: Copy User, Copied, Public Portfolio Visible, Trading, Position Open, Manual Position Close, Manual Open Exit Order, Open Entry Order, Open Order, Open Open, Manual Unregister Mirror, Manual Edit SL, Manual Edit TP, Manual Edit TSL, Manual Close Entry Order, Manual Close Exit Order, Order Close, Manual Edit Mirror SL, Manual Edit Mirror SL Percentage, Manual Pause Copy, Manual Execution Block, Internal Instruments Allowed, SmartCopyUnblock, Detach Position.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationTypeID | int | NO | - | VERIFIED | Primary key. 1–24. MCP-verified. FK target from Customer.BlockedCustomerOperations and Trade.OperationTypeForBlockingToAtomic. |
| 2 | OperationDescription | varchar(50) | NO | - | VERIFIED | Human-readable description. Values: 'Copy User', 'Copied', 'Trading', 'Position Open', 'Manual Edit SL', etc. MCP-verified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.BlockedCustomerOperations | OperationTypeID | FK | Stores which operations are blocked per customer |
| Customer.OperationBlockForCID | @OperationTypeID | Parameter | Proc to block operations for a CID |
| Customer.OperationUnBlockForCID | @OperationTypeID | Parameter | Proc to unblock operations |
| Customer.GetBlockedOperationsForCID | OperationTypeID | Read | Proc to read blocks |
| Trade.OperationTypeForBlockingToAtomic | OperationTypeID | FK | Bridge table mapping OperationTypes to AtomicOperations |
| SettingsDB.Dictionary.OperationTypesForBlocking | - | Replicated | Replicated copy for distributed resolver |
| SettingsDB.Trading.BlockedCustomerOperationsResolver | - | Resolver | Resolves blocks across environments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.OperationTypesForBlocking
  ← Customer.BlockedCustomerOperations
  ← Trade.OperationTypeForBlockingToAtomic
  ← Customer.OperationBlockForCID / OperationUnBlockForCID / GetBlockedOperationsForCID
  ← SettingsDB.Trading.BlockedCustomerOperationsResolver
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | FK OperationTypeID |
| Trade.OperationTypeForBlockingToAtomic | Table | FK OperationTypeID |
| Customer.OperationBlockForCID | Procedure | Block by OperationTypeID |
| Customer.OperationUnBlockForCID | Procedure | Unblock by OperationTypeID |
| Customer.GetBlockedOperationsForCID | Procedure | Read blocks by OperationTypeID |
| SettingsDB.Dictionary.OperationTypesForBlocking | Table | Replicated copy |
| SettingsDB.Trading.BlockedCustomerOperationsResolver | Procedure | Resolver |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryOperationTypesForBlocking | CLUSTERED PK | OperationTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryOperationTypesForBlocking | PRIMARY KEY | Unique operation type. DICTIONARY filegroup. |

---

## 8. Sample Queries

### 8.1 List all operation types for blocking
```sql
SELECT  OperationTypeID,
        OperationDescription
FROM    Dictionary.OperationTypesForBlocking WITH (NOLOCK)
ORDER BY OperationTypeID;
```

### 8.2 Find operation by description
```sql
SELECT  OperationTypeID,
        OperationDescription
FROM    Dictionary.OperationTypesForBlocking WITH (NOLOCK)
WHERE   OperationDescription LIKE '%Copy%'
ORDER BY OperationTypeID;
```

### 8.3 Count blocked customers per operation type
```sql
SELECT  ot.OperationDescription,
        COUNT(DISTINCT bco.CID) AS BlockedCustomerCount
FROM    Dictionary.OperationTypesForBlocking ot WITH (NOLOCK)
LEFT JOIN Customer.BlockedCustomerOperations bco WITH (NOLOCK)
        ON bco.OperationTypeID = ot.OperationTypeID
GROUP BY ot.OperationTypeID,
         ot.OperationDescription
ORDER BY BlockedCustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5+ analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Dictionary.OperationTypesForBlocking | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OperationTypesForBlocking.sql*
