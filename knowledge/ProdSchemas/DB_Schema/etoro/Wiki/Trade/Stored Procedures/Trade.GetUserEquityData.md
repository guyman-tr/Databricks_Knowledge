# Trade.GetUserEquityData

> Returns four result sets for a single customer's full equity context: (1) cash balance and realized equity, (2) mirror investment amounts, (3) open positions with settlement and copy-root status, and (4) pending close orders waiting for market execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer whose equity data is loaded |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserEquityData` is a multi-result-set loader that assembles all data needed to compute a customer's real-time equity state. It is called by the equity calculation engine when it needs a complete picture of one customer's financial position: how much cash they have, how much is invested in copy relationships, what open positions they hold, and what positions are in a pending-close state (orders submitted but waiting for market execution).

The four result sets correspond to distinct subsystems:
1. **CustomerMoney** - the "wallet": Credit and RealizedEquity from the billing side
2. **Mirror amounts** - copy investments: all Mirror rows for this CID (Amount per mirror)
3. **Open positions** - the trading book: every open position with instrument, leverage, rates, copy tree linkage, and settlement type
4. **Pending close orders** - the "in-flight" closes: orders in StatusID=11 ("Waiting for market") that are submitted but not yet executed (these reduce effective equity since the position is about to close)

Result set 3 includes a particularly important computed field: `RootPositionIsOpen` (0 or 1). For copy positions (MirrorID > 0), this indicates whether the parent (root) position is still open - a copy position whose parent has closed is in a transitional state. The `RootSettlementTypeID` similarly reads the settlement type of the copy root from Trade.PositionTbl.

---

## 2. Business Logic

### 2.1 CustomerMoney Result Set

**What**: Wallet state - credit available and total realized equity.

**Columns**: `CID, Credit, RealizedEquity`

**Rules**:
- Reads directly from `Customer.CustomerMoney` with NOLOCK
- Returns one row per CID (1:1 relationship)
- Credit = available trading credit/balance; RealizedEquity = historical realized gains/losses

### 2.2 Mirror Amounts Result Set

**What**: Total investment amounts in each copy relationship.

**Columns**: `Amount`

**Rules**:
- Reads all rows from `Trade.Mirror` where CID = @CID (all mirrors for this customer, regardless of IsActive)
- Amount = the invested amount in each copy relationship
- Used to compute total "money in copy" for equity calculation

### 2.3 Open Positions Result Set

**What**: Full detail of all currently open positions for the customer, with copy-root linkage and settlement type resolution.

**Key computed columns**:
- `SettlementTypeID = ISNULL(p.SettlementTypeID, p.IsSettled)`: normalizes legacy IsSettled (bit) with new SettlementTypeID (int). Handles migration from old to new settlement type system.
- `RootSettlementTypeID`: For copy positions (MirrorID > 0), reads the settlement type of the ROOT position (the original position that was copied, identified by TreeID). For non-copy positions, same as SettlementTypeID.
- `RootPositionIsOpen = IIF(p.MirrorID > 0 AND tp.PositionID IS NULL, 0, 1)`: If this is a copy position (MirrorID > 0) and the root position (Trade.PositionTbl WHERE PositionID=TreeID AND StatusID=1) does NOT exist -> root is closed -> returns 0. Otherwise returns 1.
- `IsDiscounted`: Marked with "todo: remove in next version" - retained for backwards compatibility.

**Root position lookup**:
- `LEFT JOIN Trade.PositionTbl tp ON p.MirrorID > 0 AND tp.PartitionCol = p.TreeID % 50 AND tp.PositionID = p.TreeID AND tp.StatusID = 1`
- Joins only for copy positions (MirrorID > 0), uses partition column for performance, StatusID=1 means open

### 2.4 Pending Close Orders (via GetUserEquityDataInnerMOT)

**What**: Orders submitted for close but waiting for market execution (StatusID=11).

**Rules**:
- Delegated to `Trade.GetUserEquityDataInnerMOT` (natively compiled MOT procedure)
- Returns OrderID, PositionID, UnitsToDeduct, RequestGuid, StatusID
- StatusID=11 = "Waiting for market" - order has been submitted to the execution engine but not yet filled
- `UnitsToDeduct`: the units that will be removed from the position when the close executes - used by equity calculation to adjust open position units downward

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID for which to retrieve equity data. All four result sets are filtered to this CID. |

**Result Set 1 - CustomerMoney:**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 2 | CID | INT | NO | CODE-BACKED | Customer ID from Customer.CustomerMoney. |
| 3 | Credit | MONEY | NO | CODE-BACKED | Available trading credit/balance from Customer.CustomerMoney. |
| 4 | RealizedEquity | MONEY | NO | CODE-BACKED | Cumulative realized P&L from Customer.CustomerMoney. |

**Result Set 2 - Mirror Amounts:**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 5 | Amount | DECIMAL | YES | CODE-BACKED | Investment amount in each copy relationship from Trade.Mirror. All mirrors for @CID regardless of IsActive status. |

**Result Set 3 - Open Positions:**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 6 | PositionID | BIGINT | NO | CODE-BACKED | Position identifier. |
| 7 | InstrumentID | INT | NO | CODE-BACKED | Trading instrument. FK to Trade.Instrument. |
| 8 | IsBuy | BIT | NO | CODE-BACKED | 1=long, 0=short. |
| 9 | Leverage | INT | NO | CODE-BACKED | Leverage multiplier for this position. |
| 10 | IsDiscounted | BIT | YES | CODE-BACKED | Deprecated flag marked for removal. Retained for backwards compatibility. |
| 11 | Amount | MONEY | NO | CODE-BACKED | Position investment amount in account currency. |
| 12 | AmountInUnitsDecimal | DECIMAL | NO | CODE-BACKED | Position size in instrument units. |
| 13 | UnitsBaseValueCents | BIGINT | YES | CODE-BACKED | Base value of position units in cents. |
| 14 | InitForexRate | DECIMAL | NO | CODE-BACKED | FX rate at position open for currency conversion. |
| 15 | InitConversionRate | DECIMAL | NO | CODE-BACKED | Conversion rate at open. |
| 16 | LastOpConversionRate | DECIMAL | YES | CODE-BACKED | Conversion rate at last operation. |
| 17 | ParentPositionID | BIGINT | YES | CODE-BACKED | Parent position ID in copy tree (0 for root). |
| 18 | InitDateTime | DATETIME | NO | CODE-BACKED | Position open timestamp. |
| 19 | SettlementTypeID | INT | NO | CODE-BACKED | ISNULL(p.SettlementTypeID, p.IsSettled) - normalized settlement type. 1=CFD, 2=real stock. |
| 20 | RootHedgeServerID | INT | YES | CODE-BACKED | Hedge server for the copy tree root. |
| 21 | HedgeServerID | INT | YES | CODE-BACKED | Hedge server for this position. |
| 22 | TreeID | BIGINT | YES | CODE-BACKED | Copy tree identifier (PositionID of tree root). |
| 23 | StopRate | DECIMAL | YES | CODE-BACKED | Stop-loss rate. |
| 24 | IsTslEnabled | BIT | YES | CODE-BACKED | 1 = Trailing Stop Loss enabled. |
| 25 | LimitRate | DECIMAL | YES | CODE-BACKED | Take-profit rate. |
| 26 | SLManualVer | INT | YES | CODE-BACKED | Stop-loss manual version counter. |
| 27 | MirrorID | INT | YES | CODE-BACKED | Mirror ID if this is a copy position (>0). 0 for manual positions. |
| 28 | RootSettlementTypeID | INT | NO | CODE-BACKED | For copy positions: ISNULL(tp.SettlementTypeID, tp.IsSettled) of the root (TreeID) position. For non-copy: same as SettlementTypeID. |
| 29 | RootPositionIsOpen | BIT | NO | CODE-BACKED | 1 = root copy position is still open; 0 = root has closed (copy position is now "orphaned"). Only meaningful when MirrorID > 0. |
| 30 | IsSettled | BIT | NO | CODE-BACKED | Legacy settlement flag (1=real stock, 0=CFD). Superseded by SettlementTypeID. |
| 31 | PnLVersion | INT | YES | CODE-BACKED | P&L calculation version for this position. |
| 32 | LotCountDecimal | DECIMAL | YES | CODE-BACKED | Position size in lots. |

**Result Set 4 - Pending Close Orders (from GetUserEquityDataInnerMOT):**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 33 | OrderID | BIGINT | NO | CODE-BACKED | Close order identifier. FK to Trade.OrderForClose. |
| 34 | PositionID | BIGINT | NO | CODE-BACKED | Position being closed by this order. FK to Trade.CloseExecutionPlan. |
| 35 | UnitsToDeduct | DECIMAL | YES | CODE-BACKED | Units to be removed from position when close executes. Used to adjust open position size in equity calculation. |
| 36 | RequestGuid | UNIQUEIDENTIFIER | YES | CODE-BACKED | Idempotency GUID for this close request. |
| 37 | StatusID | INT | NO | CODE-BACKED | Always 11 ("Waiting for market") - filter applied in GetUserEquityDataInnerMOT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Result Set 1 | Customer.CustomerMoney | FROM | Customer cash balance and realized equity |
| Result Set 2 | Trade.Mirror | FROM | All mirror (copy) relationships and their investment amounts |
| Result Set 3 | Trade.Position | FROM | View of open positions |
| Result Set 3 JOIN | Trade.PositionTbl | LEFT JOIN | Root position lookup (TreeID, StatusID=1) for copy status and settlement type |
| Result Set 4 | Trade.GetUserEquityDataInnerMOT | EXEC | Natively compiled MOT proc returning pending close orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (equity calculation engine) | @CID | EXEC caller | Called to load complete customer equity state |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserEquityData (procedure)
+-- Customer.CustomerMoney (table)
+-- Trade.Mirror (table)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
+-- Trade.PositionTbl (table) [direct - root position lookup]
+-- Trade.GetUserEquityDataInnerMOT (natively compiled SP)
      +-- Trade.OrderForClose (table)
      +-- Trade.CloseExecutionPlan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | Result set 1: Credit and RealizedEquity |
| Trade.Mirror | Table | Result set 2: investment amounts per copy |
| Trade.Position | View | Result set 3: open positions source |
| Trade.PositionTbl | Table | Result set 3: root position lookup for copy status |
| Trade.GetUserEquityDataInnerMOT | Stored Procedure | Result set 4: pending close orders |

### 6.2 Objects That Depend On This

No documented dependents. Called by equity calculation engine.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Isolation | CustomerMoney, Mirror, Position reads all use NOLOCK |
| tp.PartitionCol = p.TreeID % 50 | Partition filter | Ensures partition elimination when looking up root position in PositionTbl |
| tp.StatusID = 1 | Status filter | Only join to root position if it is still open (StatusID=1) |
| ISNULL(p.SettlementTypeID, p.IsSettled) | Migration pattern | Handles both old IsSettled (bit) and new SettlementTypeID (int) column |

---

## 8. Sample Queries

### 8.1 Get full equity data for a customer
```sql
EXEC Trade.GetUserEquityData @CID = 123456
-- Returns 4 result sets: CustomerMoney, Mirror amounts, Open Positions, Pending Closes
```

### 8.2 Check root position open status for a copy portfolio
```sql
-- Understanding RootPositionIsOpen
SELECT p.PositionID, p.MirrorID, p.TreeID,
       IIF(p.MirrorID > 0 AND tp.PositionID IS NULL, 0, 1) AS RootPositionIsOpen
FROM Trade.Position p WITH (NOLOCK)
     LEFT JOIN Trade.PositionTbl tp WITH (NOLOCK)
         ON p.MirrorID > 0
         AND tp.PartitionCol = p.TreeID % 50
         AND tp.PositionID = p.TreeID
         AND tp.StatusID = 1
WHERE p.CID = 123456
```

### 8.3 Check pending closes for a customer
```sql
SELECT ofc.OrderID, cep.PositionID, ofc.UnitsToDeduct, ofc.StatusID
FROM Trade.OrderForClose ofc WITH (NOLOCK)
     INNER JOIN Trade.CloseExecutionPlan cep WITH (NOLOCK) ON ofc.OrderID = cep.OrderID
WHERE ofc.CID = 123456
  AND ofc.StatusID = 11  -- Waiting for market
```

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian documentation found. The equity data loading pattern is an internal execution engine concern not covered in the TRAD/DB Confluence folder.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 27 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserEquityData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserEquityData.sql*
