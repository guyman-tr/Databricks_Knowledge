# BackOffice.AllPositionsByCID_Lite

> Returns a lightweight position list for a customer - all open and closed positions with key display fields (name, status, amount, leverage, P&L, rates, direction, copy-trade links) used by the BackOffice position viewer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the BackOffice lightweight position viewer. It returns all positions for a customer - both open and closed - in a single pre-formatted result set suitable for direct display in a BackOffice UI grid. The "Lite" suffix reflects that it was created in October 2020 (MIMOPS-2637) as a performance-optimised rewrite of the original "All Positions By CID" procedure, reducing the column set to the most operationally relevant fields and using `GetPositionDataForExternalUse` (the safe external view, WITH NOLOCK).

The procedure exists to give BackOffice agents a quick, flat view of a customer's full position history without needing multiple queries or complex joins. It shows the initial investment amount, current or realized P&L, direction (buy/sell), copy-trade linkage (MirrorID, ParentPositionID), and whether the position was re-opened (OriginalPositionID).

Data flows in one direction: pure read. The SELECT sources from `Trade.GetPositionDataForExternalUse` (all positions for the CID), enriches with `Trade.InstrumentMetaData` for display names, and LEFT JOINs `History.Credit` (CreditTypeID=3 = Open Position credit) to derive the initial investment amount as the negation of that credit's TotalCashChange.

---

## 2. Business Logic

### 2.1 Open vs Closed P&L Display

**What**: Net Profit is shown differently for open vs closed positions to give the most meaningful value in each case.

**Columns/Parameters Involved**: `IsOpened`, `PnLInDollars`, `NetProfit`

**Rules**:
- `IsOpened=1` (position is open) -> Net profit = `PnLInDollars` (current unrealized P&L, live calculated)
- `IsOpened=0` (position is closed) -> Net profit = `NetProfit` (realized P&L from the close event)
- This CASE logic ensures the Net profit column always shows the economically relevant value

### 2.2 Initial Amount Derivation

**What**: The "Initial amount" is the customer's original investment, derived from the open-position credit event in History.Credit.

**Columns/Parameters Involved**: `Initial amount` (derived), `History.Credit.TotalCashChange`, `CreditTypeID`

**Rules**:
- `CreditTypeID=3` in History.Credit = Open Position event
- `TotalCashChange` for this event is a negative value (debit from the customer's account)
- `(-1) * HSCR.TotalCashChange` = positive initial investment amount
- LEFT JOIN: if no CreditTypeID=3 record is found (e.g., legacy positions), Initial amount = NULL

### 2.3 Re-opened Position Detection

**What**: Positions can be re-opened after being closed (e.g., due to a margin call reversal or error correction). OriginalPositionID tracks the lineage.

**Columns/Parameters Involved**: `OriginalPositionID`, `PositionID`

**Rules**:
- If `OriginalPositionID = PositionID`: this is the original position, shown as NULL (no re-open link)
- If `OriginalPositionID != PositionID`: this position was re-opened, shows the original PositionID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters Trade.GetPositionDataForExternalUse and History.Credit to this customer's positions only. |

**Result Set - Position List (one row per position, all open and closed):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | - | NO | - | CODE-BACKED | Unique position identifier. Primary key of the position in Trade.GetPositionDataForExternalUse. |
| 3 | Open/Closed | VARCHAR | NO | - | VERIFIED | Display status: 'Open' when IsOpened=1, 'Closed' otherwise. |
| 4 | Name | NVARCHAR | YES | - | CODE-BACKED | Instrument display name from Trade.InstrumentMetaData.InstrumentDisplayName. NULL if no InstrumentMetaData record (legacy instruments). |
| 5 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument identifier. FK to Trade.InstrumentMetaData. Used to identify the traded asset. |
| 6 | Initial amount | DECIMAL(16,2) | YES | - | VERIFIED | Customer's original investment amount: `(-1) * History.Credit.TotalCashChange` for CreditTypeID=3 (Open Position). Negated because the credit is a debit (negative) in the account. NULL for positions with no open-credit record. |
| 7 | Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | Current position value in USD from Trade.GetPositionDataForExternalUse.Amount. |
| 8 | Leverage | INT | YES | - | CODE-BACKED | Position leverage multiplier (e.g., 1, 2, 5, 10, 25, 50, 100, 200). 1 = no leverage (real asset). |
| 9 | Units | DECIMAL | YES | - | CODE-BACKED | Position size in instrument units (AmountInUnitsDecimal). For real stocks: number of shares. For crypto: coin count. |
| 10 | Net profit | DECIMAL(16,2) | YES | - | VERIFIED | P&L value: for open positions = PnLInDollars (current unrealized P&L); for closed positions = NetProfit (realized P&L from the close event). |
| 11 | InitDateTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the position was opened. |
| 12 | Buy\Sell | VARCHAR | NO | - | VERIFIED | Direction label: 'Buy' (long, IsBuy='true'), 'Sell' (short, IsBuy='false'), 'Unknown' for any other value. |
| 13 | Init rate | DECIMAL(16,6) | YES | - | CODE-BACKED | Opening rate (InitForexRate): the instrument price at position open, formatted to 6 decimal places. |
| 14 | Stop rate | DECIMAL(16,6) | YES | - | CODE-BACKED | Stop-loss rate (StopRate): the price level at which the position auto-closes at a loss. NULL if no stop loss set. |
| 15 | Limit rate | DECIMAL(16,6) | YES | - | CODE-BACKED | Take-profit rate (LimitRate): the price level at which the position auto-closes at a profit. NULL if no take profit set. |
| 16 | ComissionOnOPen | DECIMAL(16,2) | YES | - | CODE-BACKED | Commission charged at position open (Commission from GetPositionDataForExternalUse). Note: column name has a typo ("ComissionOnOPen") retained from original SP definition. |
| 17 | MirrorID | INT | YES | - | CODE-BACKED | Copy-trade mirror/portfolio ID. 0 or NULL = manual trade. Non-zero = position opened as part of a CopyTrader portfolio. |
| 18 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | Parent position ID in the copy-trade tree. NULL or 0 = no parent (leaf node or manual). Non-zero = this position was copied from the parent. |
| 19 | Orig PositionID | BIGINT | YES | - | VERIFIED | OriginalPositionID when it differs from PositionID - indicates this position was re-opened. NULL when OriginalPositionID = PositionID (original position, not re-opened). |
| 20 | OrigParentPositionID | BIGINT | YES | - | CODE-BACKED | Original parent position ID before any re-open or tree restructure. Tracks lineage of copy-trade positions through re-open events. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / PositionID | Trade.GetPositionDataForExternalUse | Implicit | Primary source: all position data for the customer |
| InstrumentID | Trade.InstrumentMetaData | Lookup (LEFT JOIN) | Provides InstrumentDisplayName for the position's traded asset |
| PositionID | History.Credit | Lookup (LEFT JOIN) | CreditTypeID=3 records provide the initial investment amount |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in SSDT. Called directly from BackOffice application (position viewer UI).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AllPositionsByCID_Lite (procedure)
|- Trade.GetPositionDataForExternalUse (view) [primary data source - all positions for CID]
|- Trade.InstrumentMetaData (table/view) [LEFT JOIN for instrument display name]
+-- History.Credit (table) [LEFT JOIN for CreditTypeID=3 initial investment amount]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionDataForExternalUse | View | Primary source: all position data (IsOpened, Amount, Leverage, P&L, rates, direction, copy-trade fields) |
| Trade.InstrumentMetaData | Table/View | LEFT JOIN on InstrumentID for InstrumentDisplayName |
| History.Credit | Table | LEFT JOIN on PositionID + CreditTypeID=3 + CID for initial investment amount derivation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Position viewer UI; called to display customer's full position history in a grid |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH NOLOCK | Design | Both Trade.GetPositionDataForExternalUse and Trade.InstrumentMetaData queries use WITH NOLOCK - read uncommitted for performance |
| CreditTypeID=3 filter | Application | Only Open Position credits used for Initial amount; other credit types ignored |
| Column name typo | Design | Output column "ComissionOnOPen" has a typo (double capital O, single s) - retained for backward compatibility |

---

## 8. Sample Queries

### 8.1 Get all positions for a customer

```sql
EXEC BackOffice.AllPositionsByCID_Lite @CID = 12345
-- Returns one row per position (open and closed), ordered by Trade.GetPositionDataForExternalUse default
```

### 8.2 Filter result to open positions only

```sql
-- After executing the proc, filter in application or wrap in a temp table:
DECLARE @t TABLE (PositionID BIGINT, [Open/Closed] VARCHAR(10), [Name] NVARCHAR(200), InstrumentID INT,
    [Initial amount] DECIMAL(16,2), Amount DECIMAL(16,2), Leverage INT, Units DECIMAL(18,8),
    [Net profit] DECIMAL(16,2), InitDateTime DATETIME, [Buy\Sell] VARCHAR(10),
    [Init rate] DECIMAL(16,6), [Stop rate] DECIMAL(16,6), [Limit rate] DECIMAL(16,6),
    ComissionOnOPen DECIMAL(16,2), MirrorID INT, ParentPositionID BIGINT,
    [Orig PositionID] BIGINT, OrigParentPositionID BIGINT)
INSERT @t EXEC BackOffice.AllPositionsByCID_Lite @CID = 12345
SELECT * FROM @t WHERE [Open/Closed] = 'Open'
```

### 8.3 Check CreditTypeID=3 (Open Position) credits for a customer

```sql
SELECT TOP 5 PositionID, TotalCashChange, Occurred
FROM History.Credit WITH (NOLOCK)
WHERE CID = 12345 AND CreditTypeID = 3
ORDER BY Occurred DESC
-- TotalCashChange is negative (debit); proc negates it to show positive Initial amount
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AllPositionsByCID_Lite | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AllPositionsByCID_Lite.sql*
