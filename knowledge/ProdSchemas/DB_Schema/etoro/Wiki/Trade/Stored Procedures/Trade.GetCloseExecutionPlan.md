# Trade.GetCloseExecutionPlan

> Retrieves the close execution plan entries for a given close order, enriched with position details, customer data, and regulation information needed by the post-execution service to process hierarchical position closures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns enriched close execution plan rows by OrderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a critical component of the position close flow. When a close order is created (via manual close, stop loss, take profit, margin call, or tree cascade), the pre-execution service builds a CloseExecutionPlan - a memory-optimized table that lists every position in the copy-trading tree that needs to be closed, along with the hierarchy level for bottom-up processing. This procedure retrieves that plan, enriched with full position and customer context, so the post-execution service can process each close.

Without this procedure, the post-execution service would not have the data it needs to calculate PnL, apply forex conversions, and enforce regulatory rules during position closure. It bridges the gap between the planning phase (which determines WHAT to close) and the execution phase (which actually closes positions).

The data flow is: Pre-Execution Service creates entries in Trade.CloseExecutionPlan and Trade.OrderForClose -> this procedure joins CloseExecutionPlan with PositionTbl, CustomerStatic, and BackOffice.Customer to produce a rich dataset -> Post-Execution Service processes closes level by level (leaves first, root last).

---

## 2. Business Logic

### 2.1 Partition-Aligned Position Lookup

**What**: Position table access uses a modulo-based partition alignment for efficient lookups.

**Columns/Parameters Involved**: `PositionID`, `PartitionCol`

**Rules**:
- The JOIN condition `cep.PositionID = tp.PositionID AND cep.PositionID % 50 = tp.PartitionCol` ensures the query uses the partition scheme on Trade.PositionTbl
- PartitionCol is a computed column = PositionID % 50, and this explicit predicate enables partition elimination

### 2.2 Settlement Type Resolution

**What**: Legacy-compatible resolution of settlement type from either the modern SettlementTypeID or the legacy IsSettled flag.

**Columns/Parameters Involved**: `SettlementTypeID`, `IsSettled`

**Rules**:
- Uses `ISNULL(tp.SettlementTypeID, tp.IsSettled)` - prefers the modern SettlementTypeID column
- Falls back to IsSettled (BIT: 1=Real stock, 0=CFD) for older positions where SettlementTypeID is NULL
- The returned value determines PnL calculation version and fee logic

### 2.3 Initial Units Fallback

**What**: Resolves the original unit count at position open, handling positions created before the InitialUnits column existed.

**Columns/Parameters Involved**: `InitialUnits`, `AmountInUnitsDecimal`

**Rules**:
- Uses `ISNULL(tp.InitialUnits, tp.AmountInUnitsDecimal)` to fall back to current units for legacy positions
- InitialUnits preserves the original open amount even after partial closes; AmountInUnitsDecimal reflects the current (possibly reduced) amount

### 2.4 Units Base Value Fallback

**What**: Resolves the base value in cents for margin calculations.

**Columns/Parameters Involved**: `UnitsBaseValueCents`, `InitialAmountCents`

**Rules**:
- Uses `ISNULL(tp.UnitsBaseValueCents, CONVERT(INT, tp.InitialAmountCents))` for backward compatibility

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | BIGINT | NO | - | VERIFIED | Close order identifier. References Trade.OrderForClose. Each close order can have multiple execution plan entries (one per position in the copy-trading tree). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | VERIFIED | Customer ID who owns the position. From Trade.CloseExecutionPlan. |
| 2 | PositionID | BIGINT | NO | - | VERIFIED | Position to be closed. From Trade.CloseExecutionPlan. |
| 3 | Units | DECIMAL(16,6) | NO | - | VERIFIED | Number of units to close. Supports partial close - when less than full position units, only a portion is closed. From Trade.CloseExecutionPlan. |
| 4 | Level | SMALLINT | NO | - | VERIFIED | Hierarchy level in the copy-trading tree: 0=leaf positions (no children), 1=parent of leaves, N=higher levels. Positions are processed in descending level order (leaves first). From Trade.CloseExecutionPlan. |
| 5 | IsHedged | BIT | NO | - | VERIFIED | Whether this close entry has been hedged/processed: 0=pending, 1=processed. Prevents double-processing. From Trade.CloseExecutionPlan. |
| 6 | TreeID | BIGINT | - | - | CODE-BACKED | Copy-trading tree identifier. Links this position to its tree root. From Trade.PositionTbl. |
| 7 | InitDateTime | DATETIME | NO | - | CODE-BACKED | When the position was originally opened. From Trade.PositionTbl. |
| 8 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | PositionID of the parent in the copy-trading tree. NULL or 0 for root/manual positions. From Trade.PositionTbl. |
| 9 | InitForexRate | dtPrice | NO | - | CODE-BACKED | Forex conversion rate at position open time. Used in PnL calculations. From Trade.PositionTbl. |
| 10 | PositionAmount | MONEY | NO | - | CODE-BACKED | Current monetary amount invested. Aliased from Trade.PositionTbl.Amount. |
| 11 | PositionUnits | DECIMAL(16,6) | YES | - | CODE-BACKED | Current unit count of the position. Aliased from Trade.PositionTbl.AmountInUnitsDecimal. May differ from Units if this is a partial close. |
| 12 | UnitsBaseValueCents | INT | - | - | CODE-BACKED | Base value in cents for margin calculations. Computed: ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). From Trade.PositionTbl. |
| 13 | SettlementTypeID | TINYINT | - | - | VERIFIED | Settlement type: 1=Real stock, 0=CFD. Computed: ISNULL(SettlementTypeID, IsSettled). Determines PnL calculation version and fee logic. |
| 14 | IsComputeForHedge | BIT | - | - | CODE-BACKED | Whether this position contributes to hedge calculations. From Trade.PositionTbl. |
| 15 | GCID | INT | - | - | CODE-BACKED | Global Customer ID from Customer.CustomerStatic. Cross-system customer identifier. |
| 16 | CountryID | INT | - | - | CODE-BACKED | Customer's country of residence. From Customer.CustomerStatic. Used for regulatory determination. |
| 17 | InitConversionRate | - | - | - | CODE-BACKED | Forex conversion rate at open, possibly different from InitForexRate for specific conversion logic. From Trade.PositionTbl. |
| 18 | PnLVersion | INT | - | - | VERIFIED | PnL calculation version: 1=new formula (real stocks), 0=legacy formula (CFDs). Derived from settlement type. From Trade.PositionTbl. |
| 19 | AccountCurrencyID | INT | NO | - | CODE-BACKED | Currency of the customer's account. Aliased from Trade.PositionTbl.CurrencyID. Determines PnL conversion target currency. |
| 20 | MirrorID | BIGINT | - | - | CODE-BACKED | Copy-trading parent position link. 0=manual trade. Non-zero=copied position. From Trade.PositionTbl. |
| 21 | PlayerLevelID | INT | - | - | NAME-INFERRED | Customer tier/level classification. From Customer.CustomerStatic. |
| 22 | RegulationID | INT | - | - | CODE-BACKED | Customer's designated regulation. Computed: ISNULL(bc.DesignatedRegulationID, 0). 0=no specific regulation. From BackOffice.Customer. |
| 23 | OpenMarkup | - | - | - | NAME-INFERRED | Markup applied at position open. From Trade.PositionTbl. |
| 24 | OpenMarketSpread | - | - | - | NAME-INFERRED | Market spread at position open time. From Trade.PositionTbl. |
| 25 | InitialUnits | DECIMAL(16,6) | - | - | CODE-BACKED | Original unit count at open. Computed: ISNULL(InitialUnits, AmountInUnitsDecimal). Preserved even after partial closes. |
| 26 | Commission | MONEY | - | - | CODE-BACKED | Commission fee on position open. From Trade.PositionTbl. |
| 27 | FullCommission | MONEY | - | - | NAME-INFERRED | Full commission amount before any adjustments. From Trade.PositionTbl. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.CloseExecutionPlan | JOIN | Filters execution plan entries by close order |
| PositionID | Trade.PositionTbl | JOIN | Enriches with full position details using partition-aligned lookup |
| CID | Customer.CustomerStatic | JOIN | Enriches with GCID, CountryID, PlayerLevelID |
| CID | BackOffice.Customer | JOIN | Enriches with DesignatedRegulationID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Post-Execution Service | EXEC | Caller | Consumes the enriched plan to process position closes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCloseExecutionPlan (procedure)
├── Trade.CloseExecutionPlan (table, memory-optimized)
├── Trade.PositionTbl (table)
├── Customer.CustomerStatic (table)
└── BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseExecutionPlan | Table | Primary source - execution plan entries filtered by OrderID |
| Trade.PositionTbl | Table | JOINed on PositionID with partition alignment for position details |
| Customer.CustomerStatic | Table | JOINed on CID for GCID, CountryID, PlayerLevelID |
| BackOffice.Customer | Table | JOINed on CID for DesignatedRegulationID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Post-Execution Service | External Service | Calls this procedure to get enriched close plan data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure for a specific close order

```sql
EXEC Trade.GetCloseExecutionPlan @OrderID = 12345678;
```

### 8.2 Check what positions are in a close execution plan

```sql
SELECT cep.OrderID, cep.PositionID, cep.Units, cep.Level, cep.IsHedged, cep.CID
FROM Trade.CloseExecutionPlan cep WITH (NOLOCK)
WHERE cep.OrderID = 12345678
ORDER BY cep.Level DESC;
```

### 8.3 Find positions pending close with customer details

```sql
SELECT cep.PositionID, cep.Units, cep.Level, cep.IsHedged,
       tp.InstrumentID, tp.Leverage,
       ccs.GCID, ccs.CountryID
FROM Trade.CloseExecutionPlan cep WITH (NOLOCK)
INNER JOIN Trade.PositionTbl tp WITH (NOLOCK)
    ON cep.PositionID = tp.PositionID AND cep.PositionID % 50 = tp.PartitionCol
INNER JOIN Customer.CustomerStatic ccs WITH (NOLOCK)
    ON cep.CID = ccs.CID
WHERE cep.OrderID = 12345678 AND cep.IsHedged = 0
ORDER BY cep.Level DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.CloseExecutionPlan](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13796114493) | Confluence | Memory-optimized table structure, Level column semantics (0=leaf, N=higher), CloseActionType values (1=Manual, 2=SL, 3=TP, 4=Margin Call, 5=Tree Close), IsHedged processing flag, data flow from pre-execution to post-execution |

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.2/10 (Elements: 8.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCloseExecutionPlan | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCloseExecutionPlan.sql*
