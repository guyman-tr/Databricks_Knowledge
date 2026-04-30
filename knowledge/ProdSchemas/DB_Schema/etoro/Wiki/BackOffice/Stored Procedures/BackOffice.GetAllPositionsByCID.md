# BackOffice.GetAllPositionsByCID

> Returns all trading positions (open and closed) for a specific customer within a specific copy-trade mirror, sourced from the Trade schema's external-use views.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @MirrorID - customer + mirror combination; returns one row per position |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAllPositionsByCID` retrieves the full position history for a customer within a specific CopyTrader mirror (a copy-trade relationship). Despite the name suggesting "all positions by CID," the procedure requires both a CID and a MirrorID - it returns positions scoped to one copy-trade session, not the customer's entire position history across all trading.

The procedure is used by BackOffice staff to inspect a customer's copy-trade positions within a specific mirror, showing each position's open/closed status, instrument, amounts, P&L, rates, and whether the position was inherited from a parent (CopyTrader hierarchy). It reads from `Trade.GetPositionDataForExternalUse` - a cross-schema view providing real-time position data in a form suitable for external consumption - and enriches it with instrument names from `Trade.GetInstrument`.

The commented-out performance logging infrastructure (ManageLoggedProcedures / SqlPerf) was once used to time slow executions but has since been disabled. It survives in the codebase as a historical artifact.

---

## 2. Business Logic

### 2.1 Open/Closed Status Display

**What**: The IsOpened flag from Trade.GetPositionDataForExternalUse is translated to a human-readable label.

**Columns/Parameters Involved**: `TGEP.IsOpened`

**Rules**:
- IsOpened=1 -> "Open" (position is currently active)
- IsOpened=0/any other -> "Closed" (position has been closed)

### 2.2 Direction Display (Buy/Sell)

**What**: The IsBuy flag is translated to a directional label.

**Columns/Parameters Involved**: `TGEP.IsBuy`

**Rules**:
- IsBuy='true' -> "Buy" (long position)
- IsBuy='false' -> "Sell" (short/sell position)
- Any other value -> "Unknown" (data quality catch-all)
- Note: IsBuy is compared as a string ('true'/'false'), not a BIT - this is consistent with the Trade view's output format.

### 2.3 Over Weekend (CloseOnEndOfWeek Inversion)

**What**: The CloseOnEndOfWeek flag is displayed as "Over weekend" but with inverted logic.

**Columns/Parameters Involved**: `TGEP.CloseOnEndOfWeek`

**Rules**:
- CloseOnEndOfWeek='false' -> "Yes" (position is held over the weekend - the weekend fee applies)
- CloseOnEndOfWeek='true' or NULL -> "" (position closes at end of week - no weekend fee)
- The column name and the display label are semantically opposite - "CloseOnEndOfWeek=false" means it does NOT close on the weekend, hence it IS held over the weekend.

### 2.4 Net Profit Display

**What**: PnL display format differs between open and closed positions.

**Columns/Parameters Involved**: `TGEP.PnLInDollars`, `TGEP.IsOpened`

**Rules**:
- IsOpened=1 (open): PnLInDollars CAST to DECIMAL(16,2) - live unrealized P&L
- IsOpened=0 (closed): PnLInDollars as-is (raw type from Trade view) - realized P&L at close

### 2.5 Mirror Scope Filter

**What**: The procedure filters positions to a single mirror, showing the copy-trade session context.

**Columns/Parameters Involved**: `@CID`, `@MirrorID`, `TGEP.MirrorID`

**Rules**:
- Both @CID AND @MirrorID are required - neither is optional.
- Returns only positions matching BOTH conditions: positions opened by this customer within this specific mirror.
- MirrorID=0 or NULL typically represents non-mirror (manual) positions; use the actual mirror ID to see copy-trade positions.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer Identifier. Filters Trade.GetPositionDataForExternalUse to one customer's positions. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | Mirror (copy-trade relationship) identifier. Filters positions to those opened within this specific CopyTrader mirror session. Both @CID and @MirrorID are required - no defaults. |
| 3 | PositionID | INT/BIGINT | NO | - | CODE-BACKED | Unique position identifier from Trade.GetPositionDataForExternalUse. |
| 4 | Open/Closed | VARCHAR | NO | - | CODE-BACKED | Human-readable status: "Open" (IsOpened=1, position active) or "Closed" (position settled). |
| 5 | Name | NVARCHAR | YES | - | CODE-BACKED | Instrument display name from Trade.GetInstrument (e.g., "Bitcoin", "Apple", "EUR/USD"). NULL if instrument not found in Trade.GetInstrument (LEFT JOIN - should not normally be NULL). |
| 6 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier from Trade.GetPositionDataForExternalUse. FK to Trade instrument registry. |
| 7 | Initial amount | DECIMAL | NO | - | CODE-BACKED | The position's initial investment amount in account currency. Sourced from TGEP.Amount. (Note: an earlier version used History.Credit.TotalCashChange, now commented out.) |
| 8 | Amount | DECIMAL(16,2) | NO | - | CODE-BACKED | Position amount cast to DECIMAL(16,2) - same value as Initial amount but with explicit 2-decimal precision. Duplicate of column 7 with guaranteed formatting. |
| 9 | Leverage | INT | NO | - | CODE-BACKED | Position leverage multiplier (e.g., 1=no leverage, 5=5x, 10=10x). From Trade.GetPositionDataForExternalUse.Leverage. |
| 10 | LotCount | DECIMAL | YES | - | CODE-BACKED | Number of lots in this position. From Trade.GetPositionDataForExternalUse.LotCountDecimal. |
| 11 | Net profit | DECIMAL(16,2) or raw | YES | - | CODE-BACKED | P&L for this position in account currency. Open positions: CAST(PnLInDollars AS DECIMAL(16,2)) - unrealized. Closed positions: raw PnLInDollars - realized. |
| 12 | InitDateTime | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the position was opened. From Trade.GetPositionDataForExternalUse.InitDateTime. |
| 13 | Buy\Sell | VARCHAR | NO | - | CODE-BACKED | Trade direction: "Buy" (IsBuy='true', long), "Sell" (IsBuy='false', short), or "Unknown" (unexpected value). Note: column alias uses backslash, unusual in SQL. |
| 14 | Init rate | DECIMAL(16,4) | YES | - | CODE-BACKED | Opening rate (price) for this position, to 4 decimal places. From TGEP.InitForexRate. |
| 15 | Stop rate | DECIMAL(16,4) | YES | - | CODE-BACKED | Stop-loss rate for this position. From TGEP.StopRate. 0 or NULL if no stop-loss set. |
| 16 | Limit rate | DECIMAL(16,4) | YES | - | CODE-BACKED | Take-profit rate for this position. From TGEP.LimitRate. 0 or NULL if no take-profit set. |
| 17 | ComissionOnOPen | DECIMAL(16,2) | YES | - | CODE-BACKED | Commission charged at position open, in account currency. From TGEP.Commission. Note: column alias has intentional (legacy) typo - double capitals "OPen". |
| 18 | MirrorID | INT | YES | - | CODE-BACKED | Copy-trade mirror ID this position belongs to. Same as @MirrorID filter (all rows will have this value). From TGEP.MirrorID. |
| 19 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | For copy-trade positions: the leader's position that this position mirrors. NULL for manual (non-copy) positions. From TGEP.ParentPositionID. |
| 20 | OrigParentPositionID | BIGINT | YES | - | CODE-BACKED | Original parent position ID in multi-level copy hierarchies (when a copy-of-a-copy is made). From TGEP.OrigParentPositionID. |
| 21 | Over weekend | VARCHAR | YES | - | CODE-BACKED | Whether this position is held over the weekend (weekend fee applies). "Yes" when CloseOnEndOfWeek='false' (position stays open over weekend); "" when CloseOnEndOfWeek='true' (position closes at end of week). Inverted logic: 'false'="Yes, stays over weekend". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / @MirrorID | Trade.GetPositionDataForExternalUse | Primary source (cross-schema view) | Retrieves position data filtered by CID + MirrorID. |
| InstrumentID | Trade.GetInstrument | Lookup (LEFT JOIN, cross-schema) | Provides instrument display name for each position. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Found only in PROD_BIadmins (permissions). No SQL procedure callers in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAllPositionsByCID (procedure)
├── Trade.GetPositionDataForExternalUse (view) [cross-schema]
└── Trade.GetInstrument (view) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionDataForExternalUse | View (cross-schema) | Main data source - all position fields filtered by CID and MirrorID. |
| Trade.GetInstrument | View (cross-schema) | LEFT JOIN on InstrumentID to retrieve instrument Name. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally (PROD_BIadmins grant only). No SQL procedure callers in repository. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. NOLOCK on both Trade views. Commented-out performance logging (ManageLoggedProcedures / SqlPerf INSERT) - was used to track slow executions, now disabled. @BeginDateTime variable declared but unused since logging was removed.

---

## 8. Sample Queries

### 8.1 Get all positions for a customer in a specific mirror
```sql
EXEC BackOffice.GetAllPositionsByCID
    @CID = 10848122,
    @MirrorID = 4005632;
```

### 8.2 Get open positions only (using inline query)
```sql
SELECT TGEP.PositionID,
    TGIN.Name AS InstrumentName,
    TGEP.Amount,
    CAST(TGEP.PnLInDollars AS DECIMAL(16,2)) AS NetProfit,
    TGEP.InitDateTime
FROM Trade.GetPositionDataForExternalUse TGEP WITH (NOLOCK)
LEFT JOIN Trade.GetInstrument TGIN WITH (NOLOCK) ON TGIN.InstrumentID = TGEP.InstrumentID
WHERE TGEP.CID = 10848122
  AND TGEP.MirrorID = 4005632
  AND TGEP.IsOpened = 1;
```

### 8.3 Summarize copy-trade position P&L for a mirror
```sql
SELECT
    COUNT(*) AS TotalPositions,
    SUM(CASE WHEN IsOpened=1 THEN 1 ELSE 0 END) AS OpenPositions,
    SUM(CASE WHEN IsOpened=0 THEN 1 ELSE 0 END) AS ClosedPositions,
    SUM(CAST(PnLInDollars AS DECIMAL(16,2))) AS TotalPnL
FROM Trade.GetPositionDataForExternalUse WITH (NOLOCK)
WHERE CID = 10848122
  AND MirrorID = 4005632;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAllPositionsByCID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAllPositionsByCID.sql*
