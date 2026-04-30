# Trade.GetDetachRequiredData

> Retrieves all data needed to detach a position from its copy-trade tree, including position details, mirror status, customer info, instrument type, and whether the tree root is a real stock position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDetachRequiredData collects all the information the trading engine requires to detach (disconnect) a position from its copy-trade tree. When a copier wants to take manual control of a copied position, the system needs to know the position's details, whether the mirror is still active, the customer's profile, the instrument type, and critically whether the original tree root was a real stock position (which affects settlement and fee handling).

This procedure exists because detaching from a copy-trade tree is a complex operation that changes the position's relationship structure. The system must validate: Is the mirror active? Is the customer being copied by others? What instrument type is it? What settlement type does the root position use?

Data flows from Trade.Position (open position view, partition-aligned), joined with Trade.Mirror (copy-trade relationship), Customer.Customer (GCID), BackOffice.Customer (trading risk status), Trade.InstrumentMetaData (instrument type). A separate subquery resolves the tree root's IsSettled flag by navigating from PositionTbl -> RealOpenPositions using ABS(TreeID) as the root PositionID.

---

## 2. Business Logic

### 2.1 Tree Root Settlement Detection

**What**: Determines whether the root position of the copy-trade tree is a real stock (IsSettled=1) or CFD position.

**Columns/Parameters Involved**: `TreeID`, `IsSettled`, `@Root_IsSettled`

**Rules**:
- ABS(TreeID) is the root position's PositionID
- RealOpenPositions is queried with PositionPartitionCol = ABS(TreeID) % 50 for partition alignment
- The root's IsSettled value affects how the detached position is treated (real vs CFD settlement)
- ISNULL(@Root_IsSettled, 0) defaults to CFD if the root cannot be found

### 2.2 Copy Relationship Context

**What**: Determines the mirror state and whether the customer is being copied by others.

**Columns/Parameters Involved**: `MirrorID`, `IsActive`, `IsBeingCopied`

**Rules**:
- Trade.Mirror.IsActive: whether the copy-trade relationship is still active
- IsBeingCopied: OUTER APPLY checks if any Trade.Mirror row has ParentCID = this position's CID
- If IsBeingCopied = 1, the detach may cascade to sub-copiers

**Diagram**:
```
@PositionID
  |
  +-- Trade.PositionTbl -> ABS(TreeID) -> RealOpenPositions -> @Root_IsSettled
  |
  +-- Trade.Position (partition-aligned)
  |     +-- Trade.Mirror (MirrorID -> IsActive)
  |     +-- Customer.Customer (CID -> GCID)
  |     +-- BackOffice.Customer (TradingRiskStatusID)
  |     +-- Trade.InstrumentMetaData (InstrumentTypeID)
  |     +-- OUTER APPLY Trade.Mirror (ParentCID check -> IsBeingCopied)
  |
  Output: Position details + mirror status + customer info + root settlement
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | bigint | NO | - | CODE-BACKED | Position to detach from its copy-trade tree. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer who owns the position. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | The position being detached. |
| 3 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror relationship ID. |
| 4 | IsActive | bit | YES | - | CODE-BACKED | Whether the mirror relationship is still active. From Trade.Mirror. |
| 5 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server managing this position. |
| 6 | IsBeingCopied | bit | YES | - | CODE-BACKED | Whether this customer is being copied by others (0 if not). |
| 7 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. From Customer.Customer. |
| 8 | InstrumentID | int | NO | - | CODE-BACKED | Instrument of the position. |
| 9 | IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 10 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier. |
| 11 | TradingRiskStatusID | int | YES | - | CODE-BACKED | Trading risk classification. From BackOffice.Customer. |
| 12 | Amount | money | NO | - | CODE-BACKED | Position amount in denomination currency. |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. |
| 14 | InitForexRate | float | YES | - | CODE-BACKED | Open rate. |
| 15 | IsTslEnabled | bit | YES | - | CODE-BACKED | Whether trailing stop-loss is enabled. |
| 16 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether the position has a fee discount. |
| 17 | IsSettled | bit | NO | - | CODE-BACKED | 1=real stock, 0=CFD. The position's own settlement flag. |
| 18 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Modern settlement type. FK to Dictionary.SettlementTypes. |
| 19 | InstrumentTypeID | int | YES | - | CODE-BACKED | Asset class (4=Index, 5=Stock). From Trade.InstrumentMetaData. |
| 20 | OrigTreeIsSettled | bit | NO | - | CODE-BACKED | Whether the tree ROOT position is real stock. ISNULL(@Root_IsSettled, 0). |
| 21 | InitConversionRate | float | YES | - | CODE-BACKED | Conversion rate at position open. |
| 22 | PnLVersion | int | YES | - | CODE-BACKED | PnL calculation version. |
| 23 | InitDateTime | datetime | YES | - | CODE-BACKED | When the position was opened. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.Position (view) | FROM | Open position data |
| PositionID | Trade.PositionTbl | FROM | Root position lookup via TreeID |
| MirrorID | Trade.Mirror | JOIN | Mirror relationship status |
| CID | Customer.Customer | JOIN | GCID lookup |
| CID | BackOffice.Customer | JOIN | Trading risk status |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Instrument type |
| TreeID | RealOpenPositions (synonym) | INNER JOIN | Root position IsSettled check |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDetachRequiredData (procedure)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.PositionTbl (table) - for root lookup
+-- RealOpenPositions (synonym -> Trade.PositionTbl)
+-- Trade.Mirror (table)
+-- Customer.Customer (table)
+-- BackOffice.Customer (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | FROM - open position data (partition-aligned) |
| Trade.PositionTbl | Table | Subquery - root position lookup via TreeID |
| RealOpenPositions | Synonym | INNER JOIN - root IsSettled lookup |
| Trade.Mirror | Table | JOIN - mirror relationship status |
| Customer.Customer | Table | JOIN - GCID |
| BackOffice.Customer | Table | JOIN - trading risk status |
| Trade.InstrumentMetaData | Table | JOIN - instrument type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by CopyTrader detach service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Uses partition-aligned queries: PartitionCol = @PositionID % 50 and PositionPartitionCol = ABS(TreeID) % 50.

---

## 8. Sample Queries

### 8.1 Get detach data for a specific position

```sql
EXEC Trade.GetDetachRequiredData @PositionID = 123456789;
```

### 8.2 Check if a position's tree root is real stock

```sql
SELECT  tp.PositionID, ABS(tp.TreeID) AS RootPositionID,
        tpRoot.IsSettled AS RootIsSettled
FROM    Trade.PositionTbl tp WITH (NOLOCK)
INNER JOIN Trade.PositionTbl tpRoot WITH (NOLOCK)
        ON ABS(tp.TreeID) = tpRoot.PositionID
        AND tpRoot.PartitionCol = ABS(tp.TreeID) % 50
WHERE   tp.PositionID = 123456789
        AND tp.PartitionCol = 123456789 % 50;
```

### 8.3 Find positions with active mirrors that could be detached

```sql
SELECT  tp.PositionID, tp.CID, tp.MirrorID, m.IsActive
FROM    Trade.Position tp WITH (NOLOCK)
INNER JOIN Trade.Mirror m WITH (NOLOCK) ON tp.MirrorID = m.MirrorID
WHERE   tp.MirrorID > 0
        AND m.IsActive = 1
        AND tp.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDetachRequiredData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDetachRequiredData.sql*
