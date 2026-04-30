# Trade.OperationTypeForBlockingToAtomic

> Mapping table that decomposes high-level blocking operation types into atomic sub-operations, enabling customer restriction checks to validate both the blocking type and its constituent actions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OperationTypeID, AtomicOperationID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK) |

---

## 1. Business Meaning

Trade.OperationTypeForBlockingToAtomic maps "blocking" operation types (e.g., "Trading", "Position Open", "Manual Edit SL") to their atomic sub-operations. Customer.BlockedCustomerOperations stores which OperationTypeIDs are blocked for a customer. When the system needs to check "Can this user perform action X?", it must resolve the high-level OperationTypeID into the atomic operations it implies. For most types (1-20), the mapping is 1:1 - OperationTypeID=5 maps to AtomicOperationID=5. For "Manual Execution Block" (OperationTypeID=21), one blocking type maps to five atomic operations: Copy User (1), Position Open (5), Open Entry Order (8), Open Order (9), Manual Close Exit Order (16). This allows a single block to prevent multiple granular actions.

This table exists because BlockedCustomerOperations uses high-level types (user-friendly), while execution and validation logic often work at atomic-operation granularity. GetOrderForCloseContextData and GetOrderForOpenContextData JOIN here to translate blocked OperationTypeIDs into AtomicOperationIDs for restriction checks. GetUserWithRestirctions uses it to determine which atomic operations a user is blocked from.

Data is static configuration - populated by deployment scripts. Read by Trade.GetOrderForCloseContextData, Trade.GetOrderForOpenContextData, Trade.GetUserWithRestirctions. No INSERT/UPDATE/DELETE procedures in codebase - DBA-managed.

---

## 2. Business Logic

### 2.1 One-to-One vs One-to-Many Mapping

**What**: Most blocking types map 1:1 to an atomic operation. OperationTypeID 21 ("Manual Execution Block") maps to multiple atomic operations.

**Columns/Parameters Involved**: `OperationTypeID`, `AtomicOperationID`

**Rules**:
- OperationTypeID 1-20: single row per type, AtomicOperationID equals OperationTypeID.
- OperationTypeID 21: five rows - AtomicOperationID in (1, 5, 8, 9, 16). Blocking "Manual Execution Block" prevents Copy User, Position Open, Open Entry Order, Open Order, Manual Close Exit Order.
- Composite PK prevents duplicates. FKs to Dictionary.OperationTypesForBlocking and Dictionary.AtomicOperationsForBlocking.

**Diagram**:
```
OperationTypeID=4 (Trading)      -> AtomicOperationID=4
OperationTypeID=5 (Position Open) -> AtomicOperationID=5
OperationTypeID=21 (Manual Execution Block)
  -> AtomicOperationID=1  (Copy User)
  -> AtomicOperationID=5  (Position Open)
  -> AtomicOperationID=8  (Open Entry Order)
  -> AtomicOperationID=9  (Open Order)
  -> AtomicOperationID=16 (Manual Close Exit Order)
```

### 2.2 Restriction Check Flow

**What**: BlockedCustomerOperations stores OperationTypeID. Procedures JOIN to OperationTypeForBlockingToAtomic to get AtomicOperationID set, then use that for validation.

**Columns/Parameters Involved**: `OperationTypeID`, `AtomicOperationID`

**Rules**:
- GetOrderForCloseContextData: SELECT CID, OTFBA.AtomicOperationID, BlockReasonID, OTFBA.OperationTypeID FROM Customer.BlockedCustomerOperations BCO INNER JOIN Trade.OperationTypeForBlockingToAtomic OTFBA ON BCO.OperationTypeID = OTFBA.OperationTypeID. Returns atomic ops for blocked types.
- GetUserWithRestirctions: Same JOIN pattern. Used to determine user restrictions for open/close context.

---

## 3. Data Overview

| OperationTypeID | AtomicOperationID | OperationTypeDescription | AtomicDescription | Meaning |
|-----------------|-------------------|--------------------------|-------------------|---------|
| 1 | 1 | Copy User | Copy User | 1:1 mapping. Blocking "Copy User" prevents atomic "Copy User". |
| 4 | 4 | Trading | Trading | Blocking "Trading" prevents atomic "Trading". |
| 5 | 5 | Position Open | Position Open | Blocking "Position Open" prevents opening positions. |
| 21 | 1 | Manual Execution Block | Copy User | Manual Execution Block prevents 5 atomic ops - one is Copy User. |
| 21 | 5 | Manual Execution Block | Position Open | Same block also prevents Position Open. |
| 21 | 8 | Manual Execution Block | Open Entry Order | Also prevents Open Entry Order. |
| 21 | 9 | Manual Execution Block | Open Order | Also prevents Open Order. |
| 21 | 16 | Manual Execution Block | Manual Close Exit Order | Also prevents Manual Close Exit Order. |

**Selection criteria for the 5 rows:** Included 1:1 examples (1, 4, 5) and the composite type 21 with its five atomic mappings. Full 25 rows in table: 20 single + 5 for type 21.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationTypeID | int | NO | - | CODE-BACKED | FK to Dictionary.OperationTypesForBlocking. High-level blocking type (e.g., 1=Copy User, 4=Trading, 5=Position Open, 21=Manual Execution Block). Part of PK. |
| 2 | AtomicOperationID | int | NO | - | CODE-BACKED | FK to Dictionary.AtomicOperationsForBlocking. Granular sub-operation (e.g., 1=Copy User, 5=Position Open, 8=Open Entry Order). Part of PK. 1:1 for types 1-20; type 21 maps to (1,5,8,9,16). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OperationTypeID | Dictionary.OperationTypesForBlocking | FK | Blocking type. FK_OperationTypeForBlockingToAtomic_OperationTypeID. |
| AtomicOperationID | Dictionary.AtomicOperationsForBlocking | FK | Atomic operation. FK_OperationTypeForBlockingToAtomic_AtomicOperationD. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrderForCloseContextData | OTFBA | JOIN | Translates blocked OperationTypeIDs to AtomicOperationIDs for close context. |
| Trade.GetOrderForOpenContextData | OTFBA | JOIN | Same for open context. |
| Trade.GetUserWithRestirctions | OTFBA | JOIN | Determines user restrictions by atomic operation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OperationTypeForBlockingToAtomic (table)
├── Dictionary.OperationTypesForBlocking (table)
└── Dictionary.AtomicOperationsForBlocking (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OperationTypesForBlocking | Table | FK OperationTypeID -> OperationTypeID |
| Dictionary.AtomicOperationsForBlocking | Table | FK AtomicOperationID -> OperationID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrderForCloseContextData | Procedure | JOIN |
| Trade.GetOrderForOpenContextData | Procedure | JOIN |
| Trade.GetUserWithRestirctions | Procedure | JOIN |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_OperationTypeForBlockingToAtomic | CLUSTERED | OperationTypeID, AtomicOperationID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_OperationTypeForBlockingToAtomic_AtomicOperationD | FK | AtomicOperationID -> Dictionary.AtomicOperationsForBlocking.OperationID |
| FK_OperationTypeForBlockingToAtomic_OperationTypeID | FK | OperationTypeID -> Dictionary.OperationTypesForBlocking.OperationTypeID |

---

## 8. Sample Queries

### 8.1 All mappings with human-readable names
```sql
SELECT OTFBA.OperationTypeID,
       OTFO.OperationDescription AS BlockingType,
       OTFBA.AtomicOperationID,
       AOFO.Description AS AtomicOp
  FROM Trade.OperationTypeForBlockingToAtomic OTFBA WITH (NOLOCK)
 INNER JOIN Dictionary.OperationTypesForBlocking OTFO WITH (NOLOCK)
         ON OTFO.OperationTypeID = OTFBA.OperationTypeID
 INNER JOIN Dictionary.AtomicOperationsForBlocking AOFO WITH (NOLOCK)
         ON AOFO.OperationID = OTFBA.AtomicOperationID
 ORDER BY OTFBA.OperationTypeID, OTFBA.AtomicOperationID;
```

### 8.2 Blocking types that map to multiple atomic operations
```sql
SELECT OTFBA.OperationTypeID,
       OTFO.OperationDescription,
       COUNT(OTFBA.AtomicOperationID) AS AtomicCount
  FROM Trade.OperationTypeForBlockingToAtomic OTFBA WITH (NOLOCK)
 INNER JOIN Dictionary.OperationTypesForBlocking OTFO WITH (NOLOCK)
         ON OTFO.OperationTypeID = OTFBA.OperationTypeID
 GROUP BY OTFBA.OperationTypeID, OTFO.OperationDescription
HAVING COUNT(OTFBA.AtomicOperationID) > 1
 ORDER BY AtomicCount DESC;
```

### 8.3 Atomic operations for a specific blocking type (e.g., Manual Execution Block)
```sql
SELECT OTFBA.AtomicOperationID,
       AOFO.Description AS AtomicOperation
  FROM Trade.OperationTypeForBlockingToAtomic OTFBA WITH (NOLOCK)
 INNER JOIN Dictionary.AtomicOperationsForBlocking AOFO WITH (NOLOCK)
         ON AOFO.OperationID = OTFBA.AtomicOperationID
 WHERE OTFBA.OperationTypeID = 21
 ORDER BY OTFBA.AtomicOperationID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.6/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OperationTypeForBlockingToAtomic | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.OperationTypeForBlockingToAtomic.sql*
