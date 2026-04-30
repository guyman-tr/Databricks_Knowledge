# Trade.GetOrderForCloseContextData_EladTest

> Test/experimental variant of GetOrderForCloseContextData that delegates position data retrieval to TradeGetCloseContestDataInnerElad - used for testing alternative inner-query implementations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT + @PositionIDs TVP + @CallerService TINYINT |
| **Partition** | N/A (delegated to inner proc) |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForCloseContextData_EladTest` is an experimental variant of `Trade.GetOrderForCloseContextData`. It shares the same parameter signature and the same logic for result sets 1 (blocked operations), 2 (customer profile), and 4 (pending open order). However, instead of executing the position data query (result set 3) directly, it delegates to `TradeGetCloseContestDataInnerElad` - a separate procedure.

**WHY:** This appears to be a test/development procedure (named `_EladTest` suggesting it was created by a developer named "Elad" for testing an alternative inner-query implementation). It allows testing a refactored inner procedure without changing the production SP.

**HOW:** Same flow as `GetOrderForCloseContextData` except result set 3 is produced by `EXEC TradeGetCloseContestDataInnerElad` with the same parameters passed through. The caller sees the same shape of results.

---

## 2. Business Logic

### 2.1 Identical to GetOrderForCloseContextData Except RS3

**What:** All logic for blocked operations (RS1), customer profile (RS2), and pending open order check (RS4) is identical to `Trade.GetOrderForCloseContextData`. See that SP's documentation for details.

**Rules:**
- RS1 (blocked ops): same as parent SP
- RS2 (customer): same as parent SP - includes FeatureID=22 IsReal check, IsBeingCopied detection
- RS3 (positions): DELEGATED to `TradeGetCloseContestDataInnerElad` proc
- RS4 (pending open): same as parent SP - only for PreExecution

### 2.2 Delegation to Inner Procedure

**What:** The inner SP `TradeGetCloseContestDataInnerElad` receives the same parameters and is expected to produce the position data result set.

**Columns/Parameters Involved:** `@LockPosition`, `@CID`, `@InstrumentID`, `@PositionIDs`, `@CallerService`, `@OrderID`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID. Passed to both inline queries and inner proc. |
| 2 | @PositionIDs | Trade.PositionIDsTbl_MOT READONLY | NO | - | CODE-BACKED | Memory-optimized TVP of PositionIDs. Passed to inner proc. |
| 3 | @CallerService | tinyint | NO | - | CODE-BACKED | 0=PreExecution, 1=PostExecution. Controls same branching as parent SP. |
| 4 | @LockPosition | bit | YES | 0 | CODE-BACKED | Lock mode passed to inner proc. |
| 5 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument being closed. Passed to inner proc. |
| 6 | @OrderID | bigint | YES | 0 | CODE-BACKED | Current close order ID. Passed to inner proc. |

**Return Columns:** Same shape as `Trade.GetOrderForCloseContextData`. See that SP's documentation for return column details.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.BlockedCustomerOperations | Direct query (RS1) | Same as parent SP |
| @CID | Customer.Customer + BackOffice.Customer | Direct query (RS2) | Same as parent SP |
| @CID | Trade.Mirror | Subquery (RS2) | IsBeingCopied check |
| @CID, Maintenance.Feature | Maintenance.Feature | Scalar subquery | FeatureID=22 |
| All params | TradeGetCloseContestDataInnerElad | EXEC | Delegates RS3 position data retrieval |
| @CID, @InstrumentID | Trade.OrderForOpen | Direct query (RS4) | Same as parent SP |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Test/development environment | N/A | CALLER | Testing alternative inner implementation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForCloseContextData_EladTest (procedure)
├── Customer.BlockedCustomerOperations (table)
├── Trade.OperationTypeForBlockingToAtomic (table)
├── Maintenance.Feature (table)
├── Trade.Mirror (table)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── TradeGetCloseContestDataInnerElad (procedure)
└── Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionIDsTbl_MOT | User Defined Type | Input TVP parameter type |
| Customer.BlockedCustomerOperations | Table | RS1 blocked ops check |
| Trade.OperationTypeForBlockingToAtomic | Table | RS1 operation type mapping |
| Maintenance.Feature | Table | IsReal flag (FeatureID=22) |
| Trade.Mirror | Table | IsBeingCopied check |
| Customer.Customer | Table | Customer profile |
| BackOffice.Customer | Table | Account type, regulation |
| TradeGetCloseContestDataInnerElad | Procedure | RS3 position data (delegated) |
| Trade.OrderForOpen | Table | RS4 pending open order check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Test environments | External | Testing alternative inner procedure implementation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** This is a test procedure and should not be used in production. The `_EladTest` suffix strongly suggests it is a developer test artifact. The production equivalent is `Trade.GetOrderForCloseContextData`.

---

## 8. Sample Queries

### 8.1 Test mode execution
```sql
DECLARE @ids Trade.PositionIDsTbl_MOT
INSERT INTO @ids VALUES (111111111)
EXEC Trade.GetOrderForCloseContextData_EladTest
    @CID = 9876543,
    @PositionIDs = @ids,
    @CallerService = 0,
    @LockPosition = 0,
    @InstrumentID = 1234,
    @OrderID = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForCloseContextData_EladTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForCloseContextData_EladTest.sql*
