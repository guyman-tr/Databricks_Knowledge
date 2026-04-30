# BI_DB_dbo.BI_DB_EY_Audit_ChangeLog

> 86M-row daily changelog table capturing position amount adjustments and settlement changes for EY audit purposes, sourced from DWH_dbo.Dim_PositionChangeLog (ChangeTypeID 12 and 13 only) enriched with prior-day unit counts and end-of-day USD-converted prices. Data covers 2023-01-01 to 2025-10-27, loaded daily by SP_EY_Audit_ChangeLog with automatic gap-filling for missing dates.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_PositionChangeLog + Dim_Position + BI_DB_PositionPnL + Fact_CurrencyPriceWithSplit via SP_EY_Audit_ChangeLog |
| **Refresh** | Daily (delete-insert by OccurredDateID, with auto-completion for missing dates) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | N/A (BI_DB audit table, no UC migration identified) |

---

## 1. Business Meaning

BI_DB_EY_Audit_ChangeLog is a daily reduced position changelog built specifically for EY audit reporting. It captures position change events of type 12 (amount adjustment) and 13 (settlement-related) from the full `DWH_dbo.Dim_PositionChangeLog`, enriching each event with the position's unit count at the start of the day (`UnitsOpenStartOfDay`) and the end-of-day price in USD (`EODPrice`).

The table contains approximately 86 million rows spanning from 2023-01-01 to 2025-10-27. ChangeTypeID 12 (amount adjustments) accounts for 99.98% of rows (~85.95M); ChangeTypeID 13 accounts for the remaining ~12.9K rows. Buy-side positions (IsBuy=1) dominate at ~98.5% in recent data.

Data is loaded daily by `BI_DB_dbo.SP_EY_Audit_ChangeLog(@date)`. The SP includes automatic gap-filling logic: before processing `@date`, it checks if any dates are missing between the table's max `OccurredDateID` and `@date`, and recursively calls itself for each missing date. For each date, the SP:
1. Builds `#Prices` from `Fact_CurrencyPriceWithSplit` joined with `Dim_Instrument` (latest price per instrument for the date)
2. Loads prior-day position data from `BI_DB_PositionPnL` into `#pnl`
3. Builds `#changelog` from `Dim_PositionChangeLog` joined with `Dim_Position` and left-joined with `#pnl`, filtering to ChangeTypeID IN (12, 13)
4. Computes `EODPrice` using a USD cross-rate conversion chain (same pattern as BI_DB_PositionPnL NOP calculation)
5. Backfills NULL unit values for specific ChangeTypeIDs
6. Deletes existing rows for the date and inserts the enriched changelog

Author: Guy Manova (2023-06-09). Notable fix: 2024-02-06 addressed a float-to-int truncation issue by using explicit CREATE TABLE with typed columns.

---

## 2. Business Logic

### 2.1 Change Type Filtering

**What**: Only two change types from the full position changelog are captured for audit purposes.

**Columns Involved**: `ChangeTypeID`

**Rules**:
- ChangeTypeID=12: Amount adjustment — position amount was modified (e.g., partial close). Accounts for 99.98% of rows.
- ChangeTypeID=13: Purpose not officially documented; accounts for ~12.9K rows total. Likely settlement-related based on the IsSettled backfill logic applied only to this type.
- All other ChangeTypeIDs (0, 1, 2, 5, 11) from Dim_PositionChangeLog are excluded.

### 2.2 EODPrice USD Conversion

**What**: Computes the end-of-day price for the position's instrument in USD, using the same cross-rate conversion pattern as BI_DB_PositionPnL.

**Columns Involved**: `EODPrice`, `IsBuy`, `InstrumentID`

**Rules**:
- For buy positions (IsBuy=1): base rate = BidSpreaded; for sell positions (IsBuy=0): base rate = AskSpreaded
- USD conversion factor depends on the instrument's currency pair (from Dim_Instrument):
  - SellCurrencyID=1 (USD is quote): factor = 1.00
  - BuyCurrencyID=1 (USD is base): factor = 1/Bid (buy) or 1/Ask (sell)
  - Neither is USD: cross-rate via a bridging instrument with USD as base or quote
  - Fallback: COALESCE(..., 1.00) if no cross-rate found
- EODPrice = direction-adjusted rate * USD conversion factor

**Diagram**:
```
For each changelog row on @dateID:
  Pair = Dim_Instrument for position's InstrumentID
  PairPrice = latest Fact_CurrencyPriceWithSplit row for that instrument on @dateID (rn=1)
  
  EODPrice = (IsBuy=1 ? PairPrice.RateBid : PairPrice.RateAsk)
           * USD_Conversion(Pair.BuyCurrencyID, Pair.SellCurrencyID, PairPrice, I2Price, I3Price)
```

### 2.3 UnitsOpenStartOfDay Derivation

**What**: Captures how many units the position held at the start of the changelog day, using prior-day snapshot or initial position data as fallback.

**Columns Involved**: `UnitsOpenStartOfDay`, `PreviousAmountInUnits`, `AmountInUnits`

**Rules**:
- Primary source: `BI_DB_PositionPnL.AmountInUnitsDecimal` for the prior day (`@datePrevID`)
- Fallback (when position not in prior-day PnL): `Dim_Position.InitialUnits`
- Post-insert backfill for ChangeTypeID=12: if UnitsOpenStartOfDay is still NULL, set to PreviousAmountInUnits
- Post-insert backfill for ChangeTypeID=13: if PreviousAmountInUnits or AmountInUnits is NULL, set both to UnitsOpenStartOfDay

### 2.4 Automatic Date Gap Filling

**What**: Before processing the requested date, the SP detects and fills any missing dates between the table's latest data and the target date.

**Columns Involved**: `OccurredDateID`

**Rules**:
- Reads MAX(OccurredDateID) from the table
- If MAX < target date: iterates day-by-day, recursively calling SP_EY_Audit_ChangeLog for each missing date
- Ensures continuous daily coverage without manual intervention

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP storage (no clustered index). This table has no distribution key optimization — all JOINs require data movement. For position-level lookups, filter on `PositionID` to reduce scan scope. For date-range queries, always filter on `OccurredDateID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All changes for a position on a date | `WHERE PositionID = @id AND OccurredDateID = @dateID` |
| Amount adjustments for a customer | `WHERE CID = @cid AND ChangeTypeID = 12 AND OccurredDateID BETWEEN @start AND @end` |
| Settlement changes only | `WHERE ChangeTypeID = 13 AND OccurredDateID = @dateID` |
| Daily change volume | `SELECT OccurredDateID, COUNT(*) FROM ... WHERE OccurredDateID BETWEEN @start AND @end GROUP BY OccurredDateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID | Full position details (Amount, Leverage, OpenOccurred) |
| DWH_dbo.Dim_Instrument | ON InstrumentID | Instrument name, symbol, asset class |
| DWH_dbo.Dim_Customer | ON CID | Customer details for audit reporting |
| BI_DB_dbo.BI_DB_PositionPnL | ON PositionID AND DateID = OccurredDateID | Same-day or prior-day P&L snapshot |

### 3.4 Gotchas

- **ROUND_ROBIN + HEAP**: No distribution key and no clustered index. Large JOINs will cause data movement across all nodes. Filter aggressively on OccurredDateID.
- **ChangeTypeID is almost exclusively 12**: 99.98% of rows are ChangeTypeID=12. ChangeTypeID=13 rows are rare (~12.9K total). Do not assume even distribution.
- **PreviousIsSettled/IsSettled are mostly NULL**: ~85% of recent rows have NULL for both settlement columns. NULL means the change event did not involve a settlement status modification.
- **EODPrice can be 0.0**: When `InstrumentID=0` (sentinel) or when no price was found for the date, EODPrice may be 0.0. Check for this in calculations.
- **Multiple rows per position per day**: A position can have multiple changelog entries on the same OccurredDateID. Do not assume uniqueness on (PositionID, OccurredDateID).
- **Data starts at 2023-01-01**: Unlike Dim_PositionChangeLog which has data from the full position history, this audit table only covers 2023 onwards.
- **IsBuy is int, not bit**: Unlike Dim_Position where IsBuy is bit, here it is stored as int (0/1). Functionally identical.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 — Expert Review)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 — source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 — source)` | From SP code / DDL analysis |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 — inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | YES | FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs. (Tier 1 — Dim_PositionChangeLog) |
| 2 | CID | int | YES | Customer ID who owns the position. Nullable (some system positions may not have CID). (Tier 1 — Dim_PositionChangeLog) |
| 3 | Occurred | datetime | NO | Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog. (Tier 1 — Dim_PositionChangeLog) |
| 4 | OccurredDateID | int | YES | ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance. (Tier 1 — Dim_PositionChangeLog) |
| 5 | ChangeTypeID | tinyint | YES | [UNVERIFIED] Type of change event. In this table only two values: 12=Amount adjustment, 13=Unknown (likely settlement-related). No official lookup table in DWH. (Tier 4 — inferred from SP filter and Dim_PositionChangeLog) |
| 6 | PreviousAmount | money | NO | Position amount (USD) before this change. NOT NULL -- always captured. (Tier 1 — Dim_PositionChangeLog) |
| 7 | AmountChanged | money | NO | Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL. (Tier 1 — Dim_PositionChangeLog) |
| 8 | NewAmount | numeric(16,8) | YES | Position amount after this change. Nullable -- may be absent for non-amount change types. (Tier 1 — Dim_PositionChangeLog) |
| 9 | PreviousIsSettled | int | YES | Before the change: 1 = real asset, 0 = CFD asset. Cast from bit in staging. NULL if this event did not involve a settlement change. (Tier 5 — Expert Review) |
| 10 | IsSettled | int | YES | After the change: 1 = real asset, 0 = CFD asset. NULL if this event did not involve a settlement change. (Tier 5 — Expert Review) |
| 11 | PreviousStopRate | numeric(16,8) | NO | Stop-loss rate before this change. NOT NULL. (Tier 1 — Dim_PositionChangeLog) |
| 12 | StopRate | numeric(16,8) | NO | Stop-loss rate after this change. NOT NULL. (Tier 1 — Dim_PositionChangeLog) |
| 13 | PreviousAmountInUnits | numeric(16,6) | YES | Unit count (shares/coins) before this change. Added for futures/unit-based positions. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL. (Tier 1 — Dim_PositionChangeLog) |
| 14 | AmountInUnits | numeric(16,6) | YES | Unit count after this change. DWH note: for ChangeTypeID=13, backfilled from UnitsOpenStartOfDay when NULL. (Tier 1 — Dim_PositionChangeLog) |
| 15 | UnitsOpenStartOfDay | float | YES | Unit count the position held at start of the changelog day. CASE: BI_DB_PositionPnL.AmountInUnitsDecimal for prior day when available, else Dim_Position.InitialUnits; fallback to PreviousAmountInUnits for ChangeTypeID=12 when still NULL. (Tier 2 — Dim_Position / BI_DB_PositionPnL) |
| 16 | EODPrice | float | YES | End-of-day instrument price in USD. Computed as direction-adjusted bid/ask from Fact_CurrencyPriceWithSplit multiplied by a USD cross-rate conversion factor derived from Dim_Instrument currency pairs. Can be 0.0 when no price found. (Tier 2 — Fact_CurrencyPriceWithSplit / Dim_Instrument) |
| 17 | IsBuy | int | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) |
| 18 | InstrumentID | int | YES | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 19 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at insert time. Not from production source. (Tier 2 — SP_EY_Audit_ChangeLog) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PositionID | Dim_PositionChangeLog | PositionID | Passthrough |
| CID | Dim_PositionChangeLog | CID | Passthrough |
| Occurred | Dim_PositionChangeLog | Occurred | Passthrough |
| OccurredDateID | Dim_PositionChangeLog | OccurredDateID | Passthrough |
| ChangeTypeID | Dim_PositionChangeLog | ChangeTypeID | Passthrough; filtered to IN (12, 13) |
| PreviousAmount | Dim_PositionChangeLog | PreviousAmount | Passthrough |
| AmountChanged | Dim_PositionChangeLog | AmountChanged | Passthrough |
| NewAmount | Dim_PositionChangeLog | NewAmount | Passthrough |
| PreviousIsSettled | Dim_PositionChangeLog | PreviousIsSettled | Passthrough |
| IsSettled | Dim_PositionChangeLog | IsSettled | Passthrough |
| PreviousStopRate | Dim_PositionChangeLog | PreviousStopRate | Passthrough |
| StopRate | Dim_PositionChangeLog | StopRate | Passthrough |
| PreviousAmountInUnits | Dim_PositionChangeLog | PreviousAmountInUnits | Passthrough; NULL backfill for ChangeTypeID=13 |
| AmountInUnits | Dim_PositionChangeLog | AmountInUnits | Passthrough; NULL backfill for ChangeTypeID=13 |
| UnitsOpenStartOfDay | BI_DB_PositionPnL / Dim_Position | AmountInUnitsDecimal / InitialUnits | CASE with fallback chain |
| EODPrice | Fact_CurrencyPriceWithSplit / Dim_Instrument | BidSpreaded, AskSpreaded, BuyCurrencyID, SellCurrencyID | Direction-adjusted rate * USD conversion |
| IsBuy | Dim_Position | IsBuy | Passthrough (bit to int) |
| InstrumentID | Dim_Position | InstrumentID | Passthrough |
| UpdateDate | ETL-computed | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_PositionChangeLog (WHERE ChangeTypeID IN (12,13) AND OccurredDateID = @dateID)
  + JOIN DWH_dbo.Dim_Position (IsBuy, InstrumentID, InitialUnits)
  + LEFT JOIN BI_DB_dbo.BI_DB_PositionPnL (prior-day AmountInUnitsDecimal)
    |
    v
  #changelog (enriched with UnitsOpenStartOfDay)
    |
    + UPDATE EODPrice from:
    |   DWH_dbo.Fact_CurrencyPriceWithSplit (latest bid/ask per instrument on @dateID, rn=1)
    |   + DWH_dbo.Dim_Instrument (currency pair for USD cross-rate chain)
    |
    + UPDATE backfill NULLs (PreviousAmountInUnits, AmountInUnits, UnitsOpenStartOfDay)
    |
    v
  DELETE FROM BI_DB_EY_Audit_ChangeLog WHERE OccurredDateID = @dateID
  INSERT INTO BI_DB_EY_Audit_ChangeLog (+ UpdateDate = GETDATE())
    |
    v
  BI_DB_dbo.BI_DB_EY_Audit_ChangeLog (~86M rows, 2023-01 to present)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo.Dim_Position | Full position lifecycle record |
| CID | DWH_dbo.Dim_Customer | Customer who owns the position |
| InstrumentID | DWH_dbo.Dim_Instrument | Financial instrument details |
| OccurredDateID | DWH_dbo.Dim_Date | Calendar date dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (None identified) | — | This table appears to be a terminal reporting artifact for EY audit; no downstream consumers identified in the SSDT repo |

---

## 7. Sample Queries

### 7.1 Amount adjustments for a customer on a date range

```sql
SELECT PositionID, CID, Occurred, ChangeTypeID,
       PreviousAmount, AmountChanged, NewAmount,
       UnitsOpenStartOfDay, EODPrice, IsBuy
FROM [BI_DB_dbo].[BI_DB_EY_Audit_ChangeLog]
WHERE CID = 15257899
  AND OccurredDateID BETWEEN 20250101 AND 20250331
ORDER BY Occurred;
```

### 7.2 Daily change event counts by type

```sql
SELECT OccurredDateID, ChangeTypeID, COUNT(*) AS event_count,
       SUM(CAST(AmountChanged AS DECIMAL(20,2))) AS total_amount_changed
FROM [BI_DB_dbo].[BI_DB_EY_Audit_ChangeLog]
WHERE OccurredDateID BETWEEN 20250101 AND 20250131
GROUP BY OccurredDateID, ChangeTypeID
ORDER BY OccurredDateID;
```

### 7.3 Settlement change events (ChangeTypeID=13)

```sql
SELECT PositionID, CID, Occurred,
       PreviousIsSettled, IsSettled,
       PreviousAmount, NewAmount,
       UnitsOpenStartOfDay, EODPrice
FROM [BI_DB_dbo].[BI_DB_EY_Audit_ChangeLog]
WHERE ChangeTypeID = 13
  AND OccurredDateID BETWEEN 20250101 AND 20251027
ORDER BY Occurred;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode -- Atlassian MCP skipped).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 13 T1, 3 T2, 0 T3, 1 T4 [UNVERIFIED], 2 T5 | Elements: 19/19, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_EY_Audit_ChangeLog | Type: Table | Production Source: Dim_PositionChangeLog + Dim_Position + BI_DB_PositionPnL + Fact_CurrencyPriceWithSplit via SP_EY_Audit_ChangeLog*
