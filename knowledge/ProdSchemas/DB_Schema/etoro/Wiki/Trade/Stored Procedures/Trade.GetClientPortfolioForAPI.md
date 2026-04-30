# Trade.GetClientPortfolioForAPI

> Main portfolio retrieval procedure for the Trading API. Returns 8 result sets with customer credit, legacy orders, active mirrors, open positions, and orders for close/open. Used by TAPI and TradingSettingsAPI.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid - primary output is 8 coordinated result sets |
| **Partition** | Uses partition elimination (PartitionCol = PositionID%50, @cid%50) |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary portfolio retrieval endpoint for the Trading API. It returns a comprehensive view of a customer's trading state: balance, legacy orders, active copy-trade mirrors, open positions, and pending close/open orders. TAPI (Trading API) and TradingSettingsAPI call it when a user views their portfolio or when client apps need to sync trading state.

Without this procedure, each API consumer would need to assemble these 8 result sets from disparate tables with different filters and ISNULL wrappers. Centralizing here ensures consistent null handling, partition elimination, and a single source of truth for portfolio representation across API versions.

Data flows from Customer.CustomerMoney (credit), Trade.Orders (legacy), Trade.Mirror (active mirrors), Trade.Position (open positions), Stocks.Orders, Trade.OrdersEntry, Trade.OrdersExit, and Trade.PortfolioForApiInnerMot (orders for close/open). Result sets 5-7 contain dead code (WHERE 1=0) and return empty. Result set 8 delegates to the inner procedure.

---

## 2. Business Logic

### 2.1 Result Set Assembly and Partition Elimination

**What**: The procedure assembles 8 coordinated result sets using partition-aligned predicates for performance.

**Columns/Parameters Involved**: `@cid`, `PartitionCol`, `PositionID`

**Rules**:
- Partition elimination: Position queries use `PartitionCol = PositionID % 50`, mirror queries use `PartitionCol = @cid % 50`
- Result set 1: Customer credit (Credit, BonusCredit) from Customer.CustomerMoney
- Result sets 2-4: Legacy orders, active mirrors, open positions - all filtered by @cid or mirror hierarchy
- Result sets 5-7: Dead code (WHERE 1=0) - Stocks orders, Entry orders, Exit orders
- Result set 8: Delegates to Trade.PortfolioForApiInnerMot for orders for close/open

### 2.2 Position Mirror Hierarchy Toggle

**What**: When @returnPositionMirrorHierarchy=1, position data is extended with parent/grandparent copy-trade context.

**Columns/Parameters Involved**: `@returnPositionMirrorHierarchy`, `ParentCID`, `GrandParentCID`, `ParentUserName`, `GrandParentUserName`, `ParentMirrorID`

**Rules**:
- @returnPositionMirrorHierarchy=0: Direct position data with ~30 columns (Amount, InitForexRate, MirrorID, etc.)
- @returnPositionMirrorHierarchy=1: Same columns plus LEFT JOINs to Trade.Position and Trade.Mirror for ParentCID, GrandParentCID, ParentUserName, GrandParentUserName, ParentMirrorID
- Used when API consumers need full copy-tree context for display or compliance

### 2.3 Amount Conversion (Cents to Dollars)

**What**: InitialAmountCents is converted to InitialAmountInDollars via /100.

**Columns/Parameters Involved**: `InitialAmountCents`, `InitialAmountInDollars`

**Rules**:
- InitialAmountInDollars = InitialAmountCents / 100 (legacy convention for API compatibility)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Filters all result sets to this customer. |
| 2 | @returnPositionMirrorHierarchy | BIT | YES | 0 | CODE-BACKED | 0 = positions without parent/grandparent mirror info; 1 = include ParentCID, GrandParentCID, ParentUserName, GrandParentUserName, ParentMirrorID via JOINs |
| 3 | @OpenActionType | INT | YES | NULL | CODE-BACKED | Optional filter passed to Trade.PortfolioForApiInnerMot for orders for close/open |
| 4 | Credit | MONEY | NO | - | CODE-BACKED | Customer credit balance (Result Set 1) |
| 5 | BonusCredit | MONEY | NO | - | CODE-BACKED | Customer bonus credit balance (Result Set 1) |
| 6 | (Result Set 2-8 columns) | various | - | - | CODE-BACKED | Legacy orders, mirrors, positions, stock orders, entry orders, exit orders, and orders for close/open - see procedure DDL for full column lists |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | Trade.PortfolioForApiInnerMot | Call | Delegates orders for close/open to inner procedure |
| FROM | Customer.CustomerMoney | Table | Customer credit |
| FROM | Trade.Orders | Table | Legacy orders |
| FROM | Trade.Mirror | Table | Active mirrors |
| FROM | Trade.Position | Table | Open positions |
| FROM | Stocks.Orders | Table | Stocks orders (dead code) |
| FROM | Trade.OrdersEntry | Table | Entry orders (dead code) |
| FROM | Trade.OrdersExit | Table | Exit orders (dead code) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TAPI (TAPIUser permission) | Caller | API | Trading API calls for portfolio |
| TradingSettingsAPI | Caller | API | Trading settings API calls for portfolio |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetClientPortfolioForAPI (procedure)
+-- Customer.CustomerMoney (table)
+-- Trade.Orders (table)
+-- Trade.Mirror (table)
+-- Trade.Position (table)
+-- Stocks.Orders (table)
+-- Trade.OrdersEntry (table)
+-- Trade.OrdersExit (table)
+-- Trade.PositionTbl (table, via JOINs)
+-- Trade.PortfolioForApiInnerMot (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | FROM - credit and bonus credit |
| Trade.Orders | Table | FROM - legacy orders with ISNULL wrappers |
| Trade.Mirror | Table | FROM - active mirrors, hierarchy JOINs |
| Trade.Position | Table | FROM - open positions |
| Stocks.Orders | Table | FROM - dead code WHERE 1=0 |
| Trade.OrdersEntry | Table | FROM - dead code and 1=0 |
| Trade.OrdersExit | Table | FROM - joined to PositionTbl, dead code and 1=0 |
| Trade.PortfolioForApiInnerMot | Procedure | EXEC - orders for close/open |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TAPI | API | Calls for portfolio retrieval |
| TradingSettingsAPI | API | Calls for portfolio retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses partition elimination: PartitionCol = PositionID%50 and PartitionCol = @cid%50
- ISNULL wrappers on nullable fields in legacy orders result set
- Change history: FB 53719 Free Stocks (2019), Partition Elimination (2020), OrderState (2021), OrdersForOpen/Close (2021), OrigParentPositionID (2022)

---

## 8. Sample Queries

### 8.1 Basic portfolio retrieval

```sql
EXEC Trade.GetClientPortfolioForAPI @cid = 12345;
```

### 8.2 Portfolio with mirror hierarchy for positions

```sql
EXEC Trade.GetClientPortfolioForAPI
    @cid = 12345,
    @returnPositionMirrorHierarchy = 1;
```

### 8.3 Portfolio with open action type filter

```sql
EXEC Trade.GetClientPortfolioForAPI
    @cid = 12345,
    @returnPositionMirrorHierarchy = 0,
    @OpenActionType = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetClientPortfolioForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetClientPortfolioForAPI.sql*
