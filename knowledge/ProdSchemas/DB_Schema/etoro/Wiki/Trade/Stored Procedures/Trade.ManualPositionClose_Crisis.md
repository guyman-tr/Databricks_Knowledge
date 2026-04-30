# Trade.ManualPositionClose_Crisis

> Closes a position and its entire copy-trade tree at current market rates in a crisis/emergency scenario, with optional CID-level validation, markup-aware rate calculation, and logging to History.ManualPositionClose_Crisis. Used by DBA operations and batch close tools.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (root position to close) |
| **Partition** | PartitionCol = @PositionID % 50 |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ManualPositionClose_Crisis is an emergency/crisis position close procedure designed for DBA-level and batch operations. Unlike Trade.ManualPositionClose (which closes a single position), this procedure closes the root position AND all its copy-trade children in a single call. It was designed for scenarios like market crises, regulatory actions, or mass-close operations where positions need to be forcibly closed.

The procedure supports optional CID verification via @UserName_LOWER to ensure the target position belongs to the correct customer. It calculates close rates with full markup awareness using Trade.FnGetCurrentClosingRate and Trade.FnIsRealPosition, then calls Trade.ManualPositionClose for each position. Each close is logged to History.ManualPositionClose_Crisis for audit purposes.

In Real environment (@IsReal=1), the procedure recursively traverses the copy-trade tree to find and close all child positions. Each child close is individually wrapped in TRY/CATCH to ensure one failure doesn't prevent closing other positions.

---

## 2. Business Logic

### 2.1 CID Validation (Optional)

**What**: When @UserName_LOWER is provided, validates the position belongs to that customer.

**Rules**:
- Resolves username to CID via Customer.Customer
- Checks Trade.PositionTbl for matching PositionID with StatusID=1
- If CID mismatch: prints warning and GOTO ReallyEndBit (skip close)
- If position already closed: prints warning and GOTO ReallyEndBit

### 2.2 Rate Calculation with Markup

**What**: Computes close rates accounting for markup, discounting, and skew.

**Rules**:
- BidSpreaded/AskSpreaded: uses FnGetCurrentClosingRate if not provided
- SkewValue: from Trade.CurrencyPrice (bid-side for buy, ask-side for sell)
- Markup: 0 for real positions (FnIsRealPosition), otherwise Bid-BidDiscounted or Ask-AskDiscounted
- EndForexRate: BidSpreaded for buy, AskSpreaded for sell
- If @BidSpread/@AskSpread are provided: uses those directly, overrides EndForexRateID to -1

### 2.3 Recursive Tree Close (Real Environment)

**What**: In Real environment, finds and closes all child positions.

**Rules**:
- Recursive CTE anchored at ParentPositionID = @PositionID, StatusID=1
- OPTION (OPTIMIZE FOR (@ParentPositionID=1)) — hint for plan stability
- ActionType for children: if original was 22 (ACATS), changed to 10 (hierarchical recovery)
- Each child close logged to History.ManualPositionClose_Crisis

### 2.4 Crisis Audit Logging

**What**: Every close (root + children) is logged to History.ManualPositionClose_Crisis.

**Rules**:
- Columns: OperationID (batch ID), PositionID
- Logged immediately after each ManualPositionClose call

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName_LOWER | VARCHAR(20) | YES | NULL | CODE-BACKED | Optional customer username for CID validation. When NULL, skips validation. |
| 2 | @PositionID | BIGINT | NO | - | VERIFIED | Root position to close. All children in the copy-trade tree will also be closed. |
| 3 | @BidSpread | dtPrice | YES | NULL | CODE-BACKED | Override bid spread. When NULL, calculated from live market data. |
| 4 | @AskSpread | dtPrice | YES | NULL | CODE-BACKED | Override ask spread. When NULL, calculated from live market data. |
| 5 | @OperationID | INT | NO | - | CODE-BACKED | Batch operation ID for audit logging. Stored in History.ManualPositionClose_Crisis. |
| 6 | @CloseActionType | INT | YES | NULL | CODE-BACKED | Override close action type. Default=10 (hierarchical close by recovery). |
| 7 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Override last operation conversion rate. |
| 8 | @LastOpConversionRateID | BIGINT | YES | -1 | CODE-BACKED | Override last operation conversion rate ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.CurrencyPrice | SELECT | Gets spreads, skew, discounted rates |
| FROM | Trade.PositionTbl | SELECT | Reads position data and traverses tree |
| FROM | Customer.Customer | SELECT | Resolves username to CID |
| APPLY | Trade.FnGetCurrentClosingRate | FUNCTION | Calculates closing rate |
| APPLY | Trade.FnIsRealPosition | FUNCTION | Determines if position is real (for markup) |
| EXEC | Trade.ManualPositionClose | EXEC | Closes each individual position |
| INSERT | History.ManualPositionClose_Crisis | INSERT | Audit log for each close |
| FROM | Maintenance.Feature | SELECT | Checks Real/Demo environment |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CloseAllOrphandPositions | (batch #23) | EXEC | Orphaned demo position cleanup |
| Trade.ClosePositionAtPriceRateID | (batch #24) | EXEC (dynamic) | Batch close at specific price rate |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ManualPositionClose_Crisis (procedure)
+-- Trade.CurrencyPrice (table)
+-- Trade.PositionTbl (table)
+-- Customer.Customer (table)
+-- Trade.FnGetCurrentClosingRate (function)
+-- Trade.FnIsRealPosition (function)
+-- Trade.ManualPositionClose (procedure)
+-- History.ManualPositionClose_Crisis (table)
+-- Maintenance.Feature (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | SELECT - market data |
| Trade.PositionTbl | Table | SELECT - position data, tree traversal |
| Customer.Customer | Table | SELECT - CID resolution |
| Trade.FnGetCurrentClosingRate | Function | CROSS APPLY - closing rate |
| Trade.FnIsRealPosition | Function | CROSS APPLY - markup eligibility |
| Trade.ManualPositionClose | Procedure | EXEC - closes positions |
| History.ManualPositionClose_Crisis | Table | INSERT - audit log |
| Maintenance.Feature | Table | SELECT - environment detection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseAllOrphandPositions | Procedure | EXEC - orphan cleanup |
| Trade.ClosePositionAtPriceRateID | Procedure | EXEC (dynamic SQL) - batch close |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CID-Position mismatch | Safety | @UserName_LOWER validation prevents closing wrong customer's position |
| GOTO flow control | Navigation | Uses GOTO ReallyEndBit for early exits |
| OPTIMIZE FOR hint | Performance | Tree traversal optimized for @ParentPositionID=1 |

---

## 8. Sample Queries

### 8.1 Execute crisis close for a position

```sql
EXEC Trade.ManualPositionClose_Crisis
    @PositionID = 12345,
    @OperationID = 1,
    @CloseActionType = 10;
```

### 8.2 Execute with CID validation

```sql
EXEC Trade.ManualPositionClose_Crisis
    @UserName_LOWER = 'johndoe',
    @PositionID = 12345,
    @OperationID = 1;
```

---

## 9. Atlassian Knowledge Sources

- RD-4033 (Jira): Referenced in code comments — Added Skew data to position close notifications.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 9.4/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ManualPositionClose_Crisis | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ManualPositionClose_Crisis.sql*
