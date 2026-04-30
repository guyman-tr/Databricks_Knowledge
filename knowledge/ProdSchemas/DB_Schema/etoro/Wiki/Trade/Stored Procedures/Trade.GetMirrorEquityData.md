# Trade.GetMirrorEquityData

> Returns the complete data set needed to calculate a mirror's equity: mirror metadata, all open positions, and active orders — used by the TradingEquityCalculator service.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @MirrorID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorEquityData is a high-performance data-retrieval procedure that supplies everything the TradingEquityCalculator needs to compute the real-time equity of a CopyTrader mirror. It produces three result sets in a single round-trip:

1. **Mirror metadata** — regulatory, account type, and financial details of the mirror relationship
2. **Open positions** — all positions belonging to this copier under this mirror, with root position settlement status for tree-based equity calculations
3. **Active orders** — open and close orders from memory-optimized tables (via `Trade.GetMirrorEquityDataInnerMOT`)

This single-call design avoids multiple database round-trips during equity recalculation, which is critical for real-time PnL accuracy in the CopyTrader system.

---

## 2. Business Logic

### 2.1 Mirror Metadata Retrieval (Result Set 1)

**What**: Returns the mirror's financial configuration and the copier's regulatory/account classification.

**Columns/Parameters Involved**: Trade.Mirror, Customer.Customer, BackOffice.Customer

**Rules**:
- Joins Trade.Mirror → Customer.Customer → BackOffice.Customer on CID
- RegulationID: Uses DesignatedRegulationID if set, otherwise falls back to RegulationID (ISNULL logic)
- Returns mirror-level: ParentCID, Amount, RealizedEquity, MirrorCalculationType, IsActive, PauseCopy
- Returns customer-level: CountryID, RegulationID, AccountTypeID, PlayerLevelID, PlayerStatusID

### 2.2 Open Positions (Result Set 2)

**What**: Returns all open positions for this CID+MirrorID pair, enriched with root position status.

**Columns/Parameters Involved**: Trade.Position (view), Trade.PositionTbl

**Rules**:
- Filters Trade.Position by CID and MirrorID
- LEFT JOIN to Trade.PositionTbl to determine if the root position (TreeID) is still open (StatusID=1)
- PositionTbl partition: PartitionCol = TreeID % 50
- RootPositionIsOpen: 1 if the tree root position exists and is active, 0 otherwise
- RootSettlementTypeID: Derived from root position's SettlementTypeID or IsSettled
- Returns position columns needed for equity: Amount, AmountInUnitsDecimal, Leverage, rates, settlement, PnL version, SL/TP settings

### 2.3 Active Orders (Result Set 3)

**What**: Delegates to Trade.GetMirrorEquityDataInnerMOT to return open and close orders from memory-optimized tables.

**Rules**:
- Calls the natively compiled procedure for high-performance order retrieval
- Returns two sub-result sets (open orders and close orders) as documented in Trade.GetMirrorEquityDataInnerMOT

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @CID | int | IN | - | CODE-BACKED | The copier's customer ID. |
| 2 | @MirrorID | int | IN | - | CODE-BACKED | The mirror relationship ID to calculate equity for. |

### 4.2 Result Set 1 — Mirror Metadata

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | ParentCID | int | YES | CODE-BACKED | The trader being copied (parent in mirror relationship). |
| 2 | Amount | money | YES | CODE-BACKED | The allocated amount for this mirror. |
| 3 | RealizedEquity | money | YES | CODE-BACKED | Mirror-level realized equity from Trade.Mirror. |
| 4 | MirrorCalculationType | int | YES | CODE-BACKED | Calculation method used for this mirror's equity. |
| 5 | IsActive | bit | YES | CODE-BACKED | Whether the mirror relationship is currently active. |
| 6 | PauseCopy | bit | YES | CODE-BACKED | Whether copy operations are paused for this mirror. |
| 7 | CountryID | int | YES | CODE-BACKED | Copier's country from Customer.Customer. |
| 8 | RegulationID | int | YES | CODE-BACKED | Effective regulation: DesignatedRegulationID if set, else RegulationID. |
| 9 | AccountTypeID | int | YES | CODE-BACKED | Account type from BackOffice.Customer. |
| 10 | PlayerLevelID | int | YES | CODE-BACKED | Player level from Customer.Customer. |
| 11 | PlayerStatusID | int | YES | CODE-BACKED | Player status from Customer.Customer. |

### 4.3 Result Set 2 — Open Positions

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | PositionID | bigint | NO | CODE-BACKED | The position identifier. |
| 2 | ParentPositionID | bigint | YES | CODE-BACKED | The parent position this was copied from. |
| 3 | InstrumentID | int | NO | CODE-BACKED | Financial instrument traded. |
| 4 | IsBuy | bit | NO | CODE-BACKED | 1=Long, 0=Short. |
| 5 | Leverage | int | NO | CODE-BACKED | Leverage multiplier applied to the position. |
| 6 | IsDiscounted | bit | YES | CODE-BACKED | Legacy flag, marked for removal ("todo: remove in next version"). |
| 7 | Amount | money | NO | CODE-BACKED | Position amount in dollars. |
| 8 | AmountInUnitsDecimal | decimal | YES | CODE-BACKED | Position amount in units (shares/contracts). |
| 9 | UnitsBaseValueCents | bigint | YES | CODE-BACKED | Base value in cents for unit-based calculations. |
| 10 | InitForexRate | decimal | YES | CODE-BACKED | Forex rate at position open. |
| 11 | InitConversionRate | decimal | YES | CODE-BACKED | Currency conversion rate at position open. |
| 12 | LastOpConversionRate | decimal | YES | CODE-BACKED | Conversion rate at last operation. |
| 13 | InitDateTime | datetime | NO | CODE-BACKED | When the position was opened. |
| 14 | SettlementTypeID | int | YES | CODE-BACKED | Settlement type (e.g., CFD, real stock). |
| 15 | RootHedgeServerID | int | YES | CODE-BACKED | Hedge server assigned to the root position. |
| 16 | HedgeServerID | int | YES | CODE-BACKED | Hedge server for this position. |
| 17 | TreeID | bigint | YES | CODE-BACKED | The root position ID in the copy tree. |
| 18 | IsSettled | bit | YES | CODE-BACKED | Whether the position has been settled. |
| 19 | RootPositionIsOpen | int | NO | CODE-BACKED | 1 if the tree root position is still open (StatusID=1), 0 otherwise. Computed from Trade.PositionTbl. |
| 20 | RootSettlementTypeID | int | YES | CODE-BACKED | Root position's settlement type. ISNULL(SettlementTypeID, IsSettled) from Trade.PositionTbl. |
| 21 | PnLVersion | int | YES | CODE-BACKED | PnL calculation version for this position. |
| 22 | IsNoStopLoss | bit | YES | CODE-BACKED | 1 if the position has no stop-loss set. |
| 23 | IsNoTakeProfit | bit | YES | CODE-BACKED | 1 if the position has no take-profit set. |
| 24 | LotCountDecimal | decimal | YES | CODE-BACKED | Lot count with decimal precision. |
| 25 | StopRate | decimal | YES | CODE-BACKED | Current stop-loss rate. |
| 26 | LimitRate | decimal | YES | CODE-BACKED | Current take-profit rate. |
| 27 | SLManualVer | int | YES | CODE-BACKED | Stop-loss manual version counter. |

### 4.4 Result Sets 3 & 4 — Active Orders (via GetMirrorEquityDataInnerMOT)

See [Trade.GetMirrorEquityDataInnerMOT](Trade.GetMirrorEquityDataInnerMOT.md) documentation for the open orders and close orders result sets returned by the inner memory-optimized procedure.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Mirror | SELECT (READER) | Mirror metadata |
| INNER JOIN | Customer.Customer | SELECT (READER) | Customer demographic/financial data |
| INNER JOIN | BackOffice.Customer | SELECT (READER) | Regulation and account type |
| FROM | Trade.Position | SELECT (READER) | Open positions for this mirror |
| LEFT JOIN | Trade.PositionTbl | SELECT (READER) | Root position status check |
| EXEC | Trade.GetMirrorEquityDataInnerMOT | Stored Procedure | Active orders from MOT tables |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TradingEquityCalculator | App Service | Application | The service account granted EXEC permission on this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorEquityData (procedure)
+-- Trade.Mirror (table)
+-- Customer.Customer (table)
+-- BackOffice.Customer (table)
+-- Trade.Position (view)
+-- Trade.PositionTbl (table)
+-- Trade.GetMirrorEquityDataInnerMOT (procedure, memory-optimized)
    +-- Trade.OrdersOpenMOT (MOT table)
    +-- Trade.OrdersExitMOT (MOT table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Mirror metadata retrieval |
| Customer.Customer | Table | Customer financial/demographic data |
| BackOffice.Customer | Table | Regulation and account classification |
| Trade.Position | View | Open positions |
| Trade.PositionTbl | Table | Root position status |
| Trade.GetMirrorEquityDataInnerMOT | Stored Procedure | Active orders (MOT) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TradingEquityCalculator | Service Account | Application calls this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses NOLOCK hints throughout for real-time performance
- Position partitioning: Trade.PositionTbl uses PartitionCol = TreeID % 50
- Delegates order retrieval to natively compiled procedure for memory-optimized table access
- IsDiscounted column marked as deprecated ("todo: remove in next version")

---

## 8. Sample Queries

### 8.1 Get mirror equity data

```sql
EXEC Trade.GetMirrorEquityData
    @CID = 11111,
    @MirrorID = 22222;
```

### 8.2 Verify mirror relationship exists

```sql
SELECT  MirrorID, CID, ParentCID, Amount, RealizedEquity, IsActive, PauseCopy
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   CID = 11111
        AND MirrorID = 22222;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 27 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Dependencies inherited: Trade.GetMirrorEquityDataInnerMOT.md, Trade.Mirror.md, Trade.Position.md*
*Object: Trade.GetMirrorEquityData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorEquityData.sql*
