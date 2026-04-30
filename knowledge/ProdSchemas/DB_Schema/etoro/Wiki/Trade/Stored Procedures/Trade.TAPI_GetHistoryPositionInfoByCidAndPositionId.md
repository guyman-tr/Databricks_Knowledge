# Trade.TAPI_GetHistoryPositionInfoByCidAndPositionId

> Trading API procedure that retrieves the full details of a single closed position by customer ID and position ID from the position history table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Cid INT + @PositionID BIGINT (composite point-lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a single-record point-lookup for a closed position. Given a customer's CID and a specific PositionID, it returns the key details needed to display or process that closed trade: what instrument was traded, the direction, leverage, size, P&L, how it was closed, and when.

The dual-key filter (`CID = @Cid AND PositionID = @PositionID`) enforces customer data isolation at the database level - a caller must provide both keys and can only retrieve positions belonging to the specified customer. This prevents cross-customer data access even if the application layer were to supply an arbitrary PositionID.

The procedure reads from `History.Position` (the full history table) rather than `History.PositionSlim` (the leaner aggregation-optimized table), allowing it to return a richer field set including `IsSettled`, `SettlementTypeID`, `RedeemID`, and the close action type. It is called by the Trading API (TDAPIUser) to serve individual position detail lookups, typically when a customer views the details panel for a specific closed trade.

---

## 2. Business Logic

### 2.1 Secure Customer-Scoped Lookup

**What**: Composite key filter prevents cross-customer data access.

**Columns/Parameters Involved**: `@Cid`, `@PositionID`, `CID`, `PositionID`

**Rules**:
- `WHERE CID = @Cid AND PositionID = @PositionID` - both keys must match; PositionID alone is not sufficient
- Returns at most one row (PositionID is the primary key of History.Position)
- If the position exists but belongs to a different CID, zero rows are returned
- This is the standard TAPI pattern: always include CID in the WHERE clause to scope to the requesting customer

### 2.2 Unit and Currency Conversion

**What**: Normalizes stored formats to application-friendly values before returning.

**Columns/Parameters Involved**: `InitialAmountCents`, `AmountInUnitsDecimal`, `RedeemID`, `MirrorID`

**Rules**:
- `InitialAmountCents / 100 AS InitialAmountInDollars` - database stores cents (integer), API returns dollars (decimal division)
- `ISNULL(AmountInUnitsDecimal, 0) AS Units` - null-safe, returns 0 if units not populated; aliased to the simpler "Units" name
- `ISNULL(RedeemID, 0) AS RedeemID` - null-safe default; 0 means not a redemption close
- `ISNULL(MirrorID, 0) AS MirrorID` - null-safe default; 0 means manually-opened position (not from a copy session)

### 2.3 Close Action Type Alias

**What**: Reveals the business reason why the position was closed.

**Columns/Parameters Involved**: `ActionType` (aliased as `ClosePositionActionType`)

**Rules**:
- `ActionType AS ClosePositionActionType` - the column alias is more descriptive than the storage name, revealing that ActionType in History.Position stores the close action
- Values represent how the position was closed: manually by the user, triggered by Stop Loss, Take Profit, system liquidation, redemption, etc.
- Alias matches the application-facing name used by the Trading API consumer

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cid | INT | NO | - | CODE-BACKED | Customer ID. Must match the CID of the position being requested. Acts as a security scope - prevents retrieving positions belonging to other customers. |
| 2 | @PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. Combined with @Cid to perform a point-lookup in History.Position. Returns zero rows if the PositionID does not belong to @Cid. |

### Output - Single Closed Position Detail

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID of the position owner. Returned from History.Position, matches @Cid. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument traded. FK to Trade.InstrumentMetaData. Identifies what asset was traded (stock, crypto, currency pair, etc.). |
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. Matches @PositionID input. Primary key of History.Position. |
| 4 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1 = Buy (Long), 0 = Sell (Short). For real stock positions (IsSettled=1), always 1 (Buy) as short selling is not supported for settled positions. |
| 5 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier applied to the position (e.g., 1, 2, 5, 10, 100). Real stock positions (IsSettled=1) always use Leverage=1. |
| 6 | IsSettled | BIT | NO | - | CODE-BACKED | Legacy settlement type flag: 1 = real stock position (customer owned actual shares), 0 = CFD position. Predates SettlementTypeID. When SettlementTypeID is NULL, IsSettled is used as the settlement type indicator. |
| 7 | RedeemID | INT | NO | 0 | CODE-BACKED | Stock redemption identifier: 0 = position was not closed by a redemption event. When > 0, references the redemption record that triggered this position close. ISNULL defaults NULL to 0. |
| 8 | Units | DECIMAL | NO | 0 | CODE-BACKED | Position size in instrument units (AmountInUnitsDecimal from History.Position). Represents the number of shares/units held. ISNULL defaults NULL to 0. Aliased from AmountInUnitsDecimal to the simpler application name. |
| 9 | InitialAmountInDollars | DECIMAL | NO | - | CODE-BACKED | Original invested amount in USD. Derived: InitialAmountCents / 100. The history table stores the amount in cents (integer) for precision; this column converts to dollars for the API consumer. |
| 10 | NetProfit | DECIMAL | YES | - | CODE-BACKED | Realized profit or loss from this position in USD. Positive = gain, negative = loss. Calculated at position close and stored in History.Position. |
| 11 | MirrorID | INT | NO | 0 | CODE-BACKED | Copy session association: 0 = manually-opened position (not from CopyTrader). When > 0, the position was opened as part of a copy session and references History.Mirror.MirrorID. ISNULL defaults NULL to 0. |
| 12 | ClosePositionActionType | INT | NO | - | CODE-BACKED | Reason the position was closed. Aliased from ActionType column of History.Position. Identifies whether the close was user-initiated, Stop Loss trigger, Take Profit trigger, system liquidation, margin call, redemption, or other action. FK to Dictionary.ClosePositionActionType. |
| 13 | CloseOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the position was closed. From History.Position.CloseOccurred. Used for date display in the position detail view. |
| 14 | SettlementTypeID | INT | YES | - | CODE-BACKED | Settlement type: identifies the type of financial instrument (real stock, CFD, crypto, etc.). Newer successor to the IsSettled flag. When NULL, IsSettled is used as the settlement type indicator. FK to Dictionary.SettlementTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PositionID | History.Position | Lookup (READ) | Point-lookup source for the single closed position |
| InstrumentID | Trade.InstrumentMetaData | Implicit FK | Identifies the traded asset |
| ClosePositionActionType | Dictionary.ClosePositionActionType | Implicit FK | Lookup for the close reason |
| SettlementTypeID | Dictionary.SettlementTypes | Implicit FK | Lookup for settlement type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account for individual position detail lookups.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetHistoryPositionInfoByCidAndPositionId (procedure)
└── History.Position (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table (cross-schema) | Source of all output columns; point-lookup by CID + PositionID |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Key behavioral characteristics:
- Returns at most one row (PositionID is PK of History.Position)
- No aggregation, no pagination, no temp tables - minimal overhead
- WITH (NOLOCK) on History.Position - read without blocking
- Security: CID is always required to scope results to the requesting customer

---

## 8. Sample Queries

### 8.1 Get closed position details for a specific position

```sql
EXEC Trade.TAPI_GetHistoryPositionInfoByCidAndPositionId
    @Cid = 12345,
    @PositionID = 987654321
```

### 8.2 Direct query equivalent

```sql
SELECT
    hp.CID,
    hp.InstrumentID,
    hp.PositionID,
    hp.IsBuy,
    hp.Leverage,
    hp.IsSettled,
    ISNULL(hp.RedeemID, 0) AS RedeemID,
    ISNULL(hp.AmountInUnitsDecimal, 0) AS Units,
    hp.InitialAmountCents / 100 AS InitialAmountInDollars,
    hp.NetProfit,
    ISNULL(hp.MirrorID, 0) AS MirrorID,
    hp.ActionType AS ClosePositionActionType,
    hp.CloseOccurred,
    hp.SettlementTypeID
FROM History.Position hp WITH (NOLOCK)
WHERE hp.CID = 12345
    AND hp.PositionID = 987654321
```

### 8.3 Lookup the close action type description

```sql
SELECT
    hp.CID,
    hp.PositionID,
    hp.ActionType AS ClosePositionActionType,
    cpat.Name AS CloseActionName,
    hp.CloseOccurred
FROM History.Position hp WITH (NOLOCK)
JOIN Dictionary.ClosePositionActionType cpat WITH (NOLOCK)
    ON hp.ActionType = cpat.ClosePositionActionTypeID
WHERE hp.CID = 12345
    AND hp.PositionID = 987654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetHistoryPositionInfoByCidAndPositionId | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetHistoryPositionInfoByCidAndPositionId.sql*
