# Trade.TAPI_GetPostionsUnitsByInstrumentTypeId

> Trading API procedure that returns open direct real-stock buy positions for a customer filtered by instrument type, providing the per-position unit count (share quantity) for each matching position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT + @InstrumentTypeId INT (open real-stock positions by instrument type) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the individual open positions and their unit/share quantities for a customer's direct real-stock holdings, filtered to a specific instrument type category (e.g., stocks, crypto, ETFs). It answers: "For customer X, what open real-stock positions do they have in instrument type Y, and how many units do they hold in each?"

The result set returns one row per open position - not aggregated - giving the caller both the instrument ID and the precise `AmountInUnitsDecimal` (fractional share count) for each position. This supports portfolio display where the app needs to render unit counts alongside the position details.

The filter combination - `IsSettled = 1, MirrorID = 0, IsBuy = 1, StatusID = 1` - identifies direct, open, long real-stock positions placed by the customer themselves (not via a copy-trade session). Unlike `TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds`, this procedure has no Leverage filter and explicitly includes only open positions (StatusID = 1, commented in code as "Indicates whether the position is still open").

The JOIN to `Trade.GetInstrument` enriches the position with `InstrumentTypeID` for the type-based filter, since `Trade.PositionTbl` itself does not store InstrumentTypeID.

Note: The procedure name contains a typo ("Postions" instead of "Positions") - this is a cosmetic issue only; the behavior is correct.

---

## 2. Business Logic

### 2.1 Open Real-Stock Direct Long Filter by Instrument Type

**What**: Selects open, uncopied, long real-stock positions for a customer within a specific instrument type.

**Columns/Parameters Involved**: `StatusID`, `IsSettled`, `MirrorID`, `IsBuy`, `InstrumentTypeID`, `@CID`, `@InstrumentTypeId`

**Rules**:
- `p.CID = @CID` - scopes results to the specified customer
- `gi.InstrumentTypeID = @InstrumentTypeId` - filters to the specified instrument type category (from Trade.GetInstrument view); e.g., InstrumentTypeID 1=Currency, 5=Stocks, 6=ETF, 10=Crypto
- `p.IsSettled = 1` - real stock positions only (customer owns actual shares, not CFD derivatives)
- `p.MirrorID = 0` - manual/direct positions only; copy-trade positions excluded
- `p.IsBuy = 1` - long (buy) positions only; short positions excluded
- `p.StatusID = 1` - open positions only; closed positions excluded (explicit comment in source code)
- No Leverage filter (unlike `TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds`)
- Result ordered by `p.InstrumentID` for consistent grouping in the response

### 2.2 Instrument Type Resolution via GetInstrument View

**What**: Joins to Trade.GetInstrument to obtain InstrumentTypeID for the type filter.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentTypeID`, `Trade.GetInstrument`

**Rules**:
- `INNER JOIN Trade.GetInstrument gi WITH (NOLOCK) ON p.InstrumentID = gi.InstrumentID` - every position must have a matching instrument (INNER JOIN; positions with no instrument record are excluded, which should not occur in practice)
- InstrumentTypeID is from the view (not stored in PositionTbl)
- The view is used read-only here; no write operations

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Scopes position results to this customer's own open positions. |
| 2 | @InstrumentTypeId | INT | NO | - | CODE-BACKED | Instrument type category. Filters to positions in instruments of this type. From Trade.GetInstrument.InstrumentTypeID (e.g., stocks, crypto, ETFs). |

### Output - Open Positions with Unit Counts

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | YES | - | CODE-BACKED | Customer ID. Matches @CID for all rows. |
| 2 | InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument type category. Matches @InstrumentTypeId for all rows. From Trade.GetInstrument. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. Sort key (ORDER BY InstrumentID). |
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. Primary key of Trade.PositionTbl. One row per open position. |
| 5 | AmountInUnitsDecimal | DECIMAL(16,6) | YES | - | CODE-BACKED | Position size in instrument units (fractional shares). The number of shares/units held in this position. Supports fractional ownership. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, InstrumentID, IsSettled, MirrorID, IsBuy, StatusID | Trade.PositionTbl | Lookup (READ) | Source of open position data |
| InstrumentID, InstrumentTypeID | Trade.GetInstrument | Lookup (READ) | Provides InstrumentTypeID for the type-based filter |
| InstrumentID | Trade.Instrument | Implicit FK (via GetInstrument) | Identifies the traded asset |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPostionsUnitsByInstrumentTypeId (procedure)
├── Trade.PositionTbl (table)
└── Trade.GetInstrument (view)
    └── Trade.Instrument (table - base)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source of open position data (CID, InstrumentID, PositionID, AmountInUnitsDecimal, IsSettled, MirrorID, IsBuy, StatusID) |
| Trade.GetInstrument | View | Provides InstrumentTypeID for the type-based filter JOIN |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Query likely uses `IX_CID_InstrumentIdNew1` on Trade.PositionTbl (CID, MirrorID, InstrumentID, Leverage, IsBuy, StatusID) for the initial filter, then JOINs to GetInstrument for InstrumentTypeID filtering.

### 7.2 Constraints

None. Key behavioral characteristics:
- SET NOCOUNT ON - suppresses row count messages
- TRY/CATCH with THROW - exceptions are re-raised to the caller
- StatusID = 1 explicitly filters to open positions only (commented in source code)
- INNER JOIN to GetInstrument - positions with no matching instrument record are excluded
- WITH (NOLOCK) on both sources - dirty reads allowed for performance
- Results ordered by InstrumentID for grouping consistency

---

## 8. Sample Queries

### 8.1 Get open stock positions with unit counts

```sql
-- InstrumentTypeID 5 = Stocks (example)
EXEC Trade.TAPI_GetPostionsUnitsByInstrumentTypeId
    @CID = 12345,
    @InstrumentTypeId = 5
```

### 8.2 Preview directly - same filter logic

```sql
SELECT
    p.CID,
    gi.InstrumentTypeID,
    p.InstrumentID,
    p.PositionID,
    p.AmountInUnitsDecimal
FROM Trade.PositionTbl p WITH (NOLOCK)
INNER JOIN Trade.GetInstrument gi WITH (NOLOCK)
    ON p.InstrumentID = gi.InstrumentID
WHERE p.CID = 12345
    AND gi.InstrumentTypeID = 5
    AND p.IsSettled = 1
    AND p.MirrorID = 0
    AND p.IsBuy = 1
    AND p.StatusID = 1
ORDER BY p.InstrumentID
```

### 8.3 Look up available instrument types

```sql
SELECT DISTINCT gi.InstrumentTypeID, it.InstrumentTypeName
FROM Trade.GetInstrument gi WITH (NOLOCK)
INNER JOIN Dictionary.InstrumentType it WITH (NOLOCK)
    ON gi.InstrumentTypeID = it.InstrumentTypeID
ORDER BY gi.InstrumentTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPostionsUnitsByInstrumentTypeId | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPostionsUnitsByInstrumentTypeId.sql*
