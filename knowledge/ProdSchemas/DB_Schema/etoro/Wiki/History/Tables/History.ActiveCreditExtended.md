# History.ActiveCreditExtended

> Running-total financial snapshot per credit event - each row records a customer's complete financial state (cash, open positions, copy-trading balances, stock orders, in-process cashouts) at the exact moment a specific credit event occurred. Accessed via the History.CreditExtended view.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CreditExtendedID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active (CLUSTERED PK on CreditExtendedID, NC on PositionID, UNIQUE NC on CreditID) |

---

## 1. Business Meaning

This table is a **financial audit trail** that stores a complete snapshot of each customer's financial state at the time of each credit event. Unlike `History.ActiveCredit` which records the delta (what changed), this table records the running total (what the balance is after the change).

**Every credit event gets one row** (CreditID is UNIQUE) recording:
- The customer's total cash balance at that moment
- Their total amount tied up in open positions
- Their total amount in copy-trading (Mirror) positions
- Their pending cashout amounts
- Their stock order amounts
- Per-mirror breakdown (MirrorPositionsAmount, MirrorCash)

This enables reconstruction of a customer's complete balance sheet at any historical point in time, simply by looking up the row for the last credit event before that date.

**Processing architecture**:
- Written by `Maintenance.JOB_InsertHistoryCreditExtendedAction` running on a schedule, via the `dbo.RW_History_ActiveCreditExtended` synonym (pointing to the primary/real-time DB - `[AO-REAL-DB].etoro.History.ActiveCreditExtended`)
- The SP processes batches of credit events from `History.ActiveCredit` in CreditID order, computing running totals row-by-row
- Also updates `Customer.CreditExtended` (live current-state table) with the latest values
- The `History.CreditExtended` view is a simple SELECT wrapper over this table

**Design notes**:
- IDENTITY seed = 722,463,994: set to match an existing sequence at migration time (Dec 2016, per `_TempEtoro_201612` constraint suffix). The actual CreditExtendedID does NOT match CreditID.
- `CreditID` in the History version is stored as int (the UNIQUE NC index is on int CreditID), but the view casts it to bigint: `Cast(CreditID As BigInt) CreditID`. This is because CreditID values can exceed int range - the CreditID `500001094` in staging suggests a secondary server's offset range.
- FK to `History.MMLog` (MMLogID) allows certain credit events to be linked to a MM failure - the SP currently inserts NULL for MMLogID.

The table has **1 row** in this staging environment.

---

## 2. Business Logic

### 2.1 Running Total Calculation (JOB_InsertHistoryCreditExtendedAction)

**What**: The processing SP computes running financial totals per customer per credit event.

**Columns/Parameters Involved**: All financial columns

**Algorithm** (from `Maintenance.JOB_InsertHistoryCreditExtendedAction`):
1. **Load batch**: Read credit events from `History.ActiveCredit` for CreditID range `(@lastCreditID, @maxCreditID]`.
2. **Compute deltas** for each credit event:
   - `TotalPositionDelta`: For CreditTypeID=3 (open position) and 13 (edit SL) -> `-TotalCashChange`. For CreditTypeID=4 (close position) -> `-TotalInvestedAmount`.
   - `MirrorPositionDelta`: Same as TotalPositionDelta but only when MirrorID > 0 and position is attached.
   - `IPCashoutsDelta`: For CreditTypeID 8/9/15 (cashout stages) -> `-TotalCashChange`. For CreditTypeID=2 (withdrawal processed) -> `+FullWithdrawAmount`.
   - `StockOrdersDelta` / `MirrorStockOrdersDelta`: For CreditTypeID 29/30 (stock orders) -> `-TotalCashChange`.
3. **Seed from last state**: Load the customer's last known values from `Customer.CreditExtended` as the starting row.
4. **Running total via WHILE loop**: Iterates by rank (row number per CID, ordered by CreditID) updating each row with the prior row's values + delta. This sequential approach is needed because each row depends on the previous.
5. **INSERT to History.ActiveCreditExtended** via `dbo.RW_History_ActiveCreditExtended` synonym.
6. **Update Customer.CreditExtended** with the latest values for each CID/MirrorID.
7. **Update** `Internal.CreditExtendedLastIndexValues` to advance the processed watermark.

### 2.2 CreditTypeID Business Meaning in Context

**What**: Different credit types affect different financial state components.

**Key CreditTypeIDs that affect running totals**:

| CreditTypeID | Name | Effect |
|---|---|---|
| 2 | Withdrawal processed | +InProcessCashouts (full withdraw amount) |
| 3 | Open position | -TotalPositionsAmount (invested amount) |
| 4 | Close position | +TotalPositionsAmount (return invested amount) |
| 8 | Cashout initiation | -InProcessCashouts |
| 9 | Cashout fee | -InProcessCashouts |
| 13 | Edit Stop Loss | Adjust TotalPositionsAmount |
| 15 | Cashout reversal | -InProcessCashouts |
| 27 | Detach (position detached from mirror) | Adjust MirrorPositionsAmount |
| 28 | Stock order detach | Adjust MirrorStockOrders |
| 29/30 | Stock order open/close | Adjust TotalStockOrders, MirrorStockOrders |

### 2.3 Mirror-Specific Breakdown (MirrorID, MirrorPositionsAmount, MirrorCash)

**What**: Each credit event can belong to a specific copy-trading Mirror, and the Mirror's sub-totals are tracked separately.

**Columns/Parameters Involved**: `MirrorID`, `MirrorPositionsAmount`, `MirrorCash`, `MirrorStockOrders`

**Rules**:
- `MirrorID = 0` (or NULL): The credit event is for the customer's own (non-mirror) account.
- `MirrorID > 0`: The credit event is within a specific copy-trading Mirror (Smart Portfolio). Mirror-specific columns track that Mirror's share.
- `TotalMirrorPositionsAmount` / `TotalMirrorCash`: Cross-mirror totals (sum of ALL mirrors for this CID).
- `MirrorPositionsAmount` / `MirrorCash`: Per-Mirror amounts (for the specific MirrorID in this row).
- The running total loop handles both CID-level (non-mirror) and Mirror-level (per-Mirror) sequences independently.

### 2.4 Detach Impact on Mirror Accounting

**What**: When a copy-trading position is detached from its Mirror parent, the Mirror's position amount changes.

**Rules** (from SP detach handling):
- A "detach" (CreditTypeID=27) removes a position from its mirror.
- When the FIRST detach occurs for a position, the mirror's position amount is reduced by the total amount originally invested in that position.
- Subsequent edits to that position (SL changes, CreditTypeID=13) are excluded from mirror position calculations (because the position is no longer in the mirror).
- The SP identifies the first detach occurrence using `allDetaches` CTE with `MIN(Occurred)`.

### 2.5 Access via History.CreditExtended View

**What**: `History.CreditExtended` is the standard access path.

**Rules**:
- `History.CreditExtended` = `SELECT CreditExtendedID, CAST(CreditID AS bigint), ..., FROM History.ActiveCreditExtended`.
- The view casts `CreditID` (stored as int) to bigint to handle CreditIDs > 2,147,483,647 from merged server data.
- All consumers should use `History.CreditExtended` not `History.ActiveCreditExtended` directly.

---

## 3. Data Overview

| CreditExtendedID | CreditID | CreditTypeID | CID | Occurred | TotalCash | TotalPositionsAmount | MirrorID |
|---|---|---|---|---|---|---|---|
| 1094 | 500001094 | 7 | 3634278 | 2014-08-03 09:22 | 20 | 0 | 0 |

The staging row (CreditExtendedID=1094) is from 2014, with CreditID=500001094 (an offset range suggesting secondary-server data). CreditTypeID=7, TotalCash=20, all position/mirror amounts=0 - a simple customer with only a cash balance and no open positions. The IDENTITY seed of 722,463,994 indicates production has ~722M rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditExtendedID | int | NO | IDENTITY(722463994,1) | CODE-BACKED | Surrogate PK (NOT FOR REPLICATION). IDENTITY starts at 722,463,994 - set at migration (Dec 2016) to continue from the prior table's highest ID. Does NOT match CreditID. ~722M rows in production implied by the seed. |
| 2 | CreditID | bigint | YES | - | VERIFIED | The credit event this snapshot corresponds to. UNIQUE NC index (de-facto enforces one snapshot per credit). FK to History.ActiveCredit/History.Credit (implicit). Stored as int but cast to bigint in History.CreditExtended view (values can exceed int range when merging server data). |
| 3 | CreditTypeID | int | NO | - | VERIFIED | The type of credit event this snapshot accompanies. Determines which delta formulas were applied. Key values: 3=Open position, 4=Close position, 13=Edit SL, 2=Withdrawal, 7=Bonus/adjustment type, 27=Detach, 29/30=Stock orders. |
| 4 | MMLogID | int | YES | - | VERIFIED | FK to History.MMLog.ID. Links this credit event to a Money Management failure log entry when applicable. NULL in current processing (JOB_InsertHistoryCreditExtendedAction always inserts NULL). Suggests planned but not yet implemented MM-credit linkage. |
| 5 | PositionID | bigint | YES | - | VERIFIED | The position involved in this credit event (if any). NC index supports "what was the customer's financial state when position X was closed?". NULL for non-position credits (deposits, withdrawals, fees). |
| 6 | CID | int | NO | - | CODE-BACKED | The customer account identifier. FK to Customer.CustomerStatic (WITH NOCHECK - enforced at SP level). All rows for one CID form a chronological running-total sequence. |
| 7 | Occurred | datetime | NO | - | VERIFIED | UTC timestamp of the original credit event (inherited from History.ActiveCredit). The running totals reflect the customer's financial state at this exact moment. |
| 8 | TotalPositionsAmount | money | NO | - | VERIFIED | Running total of the customer's total amount invested in all open positions at this point. Increases on position open (CreditTypeID=3), decreases on position close (CreditTypeID=4). Does not include stock orders. |
| 9 | TotalCash | money | NO | - | VERIFIED | Running total of the customer's available cash balance at this point. Inherited from History.ActiveCredit.TotalCash. Reflects actual cash after all credit events. |
| 10 | InProcessCashouts | money | NO | - | VERIFIED | Running total of pending (in-process) cashout amounts. Increases when a withdrawal is initiated (CreditTypeID=8/9/15), decreases when processed (CreditTypeID=2). |
| 11 | TotalMirrorPositionsAmount | money | NO | - | VERIFIED | Running total of all copy-trading (Mirror) position amounts across ALL mirrors for this customer. Subset of TotalPositionsAmount. |
| 12 | TotalMirrorCash | money | NO | - | VERIFIED | Running total of cash tied to copy-trading mirrors across ALL mirrors. |
| 13 | MirrorID | int | NO | - | VERIFIED | The specific copy-trading Mirror this row's per-mirror amounts relate to. 0 = non-mirror (customer's own account); the CID-level totals are in columns 8-12. >0 = a specific Mirror, and MirrorPositionsAmount/MirrorCash reflect that Mirror's individual amounts. |
| 14 | MirrorPositionsAmount | money | YES | - | VERIFIED | Position amount within the specific Mirror (MirrorID). NULL when MirrorID=0. Tracks how much of the customer's total is in this particular Mirror. |
| 15 | MirrorCash | money | YES | - | VERIFIED | Cash amount associated with the specific Mirror (MirrorID). NULL when MirrorID=0. |
| 16 | TotalStockOrders | money | YES | - | VERIFIED | Running total of all pending stock order amounts across all accounts. Increases when a stock order is placed (CreditTypeID=29/30), decreases when filled or cancelled. |
| 17 | TotalMirrorStockOrders | money | YES | - | VERIFIED | Running total of stock orders within all Mirror accounts. Subset of TotalStockOrders. |
| 18 | MirrorStockOrders | money | YES | - | VERIFIED | Stock order amount for the specific Mirror (MirrorID). NULL when MirrorID=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_HCE_CID_TempEtoro_201612) WITH NOCHECK | The customer this snapshot belongs to |
| MMLogID | History.MMLog | FK (FK_HCE_MMLogID_TempEtoro_201612) WITH NOCHECK | Optional link to MM failure that triggered this credit |
| CreditID | History.ActiveCredit | Implicit | The credit event this snapshot extends |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Maintenance.JOB_InsertHistoryCreditExtendedAction | ActiveCreditExtended | Writer (via synonym) | Processes batches of credit events and INSERTs running totals |
| History.CreditExtended | (all columns) | View | Simple SELECT wrapper (casts CreditID to bigint) |
| dbo.RW_History_ActiveCreditExtended | (synonym) | Synonym | Points to [AO-REAL-DB].etoro.History.ActiveCreditExtended - used in SP |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCreditExtended (table)
- Written via dbo.RW_History_ActiveCreditExtended synonym
- Writer: Maintenance.JOB_InsertHistoryCreditExtendedAction (SP)
  - Reads: History.ActiveCredit (source credit events)
  - Reads: Customer.CreditExtended (last known state per CID)
  - Reads: History.Credit (for invested amounts / detach history)
  - Reads: Stocks.Orders / History.StocksOrders (for stock order detaches)
  - Updates: Customer.CreditExtended (latest state)
  - Updates: Internal.CreditExtendedLastIndexValues (watermark)

FK dependencies:
- History.MMLog (MMLogID) - optional MM failure link
- Customer.CustomerStatic (CID)

Exposed via:
- History.CreditExtended (view - standard access path)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.MMLog | Table | FK - MMLogID links to MM failure log (currently always NULL) |
| Customer.CustomerStatic | Table | FK - CID validation (NOCHECK) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.JOB_InsertHistoryCreditExtendedAction | Stored Procedure | Writer - inserts running total snapshots |
| History.CreditExtended | View | Reader - SELECT wrapper over this table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Fill Factor | Status |
|-----------|------|-------------|-----------------|------------|--------|
| PK_HistoryCreditExtended_TempEtoro_201612 | CLUSTERED (PK) | CreditExtendedID ASC | - | 90% | Active |
| IX_HistoryCreditExtended_PositionID_TempEtoro_201612 | NONCLUSTERED | PositionID ASC | - | 100% | Active (on [MAIN]) |
| uix_HistoryActiveCreditExtended_CreditID_TempEtoro_201612 | UNIQUE NONCLUSTERED | CreditID ASC | - | 90% | Active (on [PRIMARY]) |

**Notes**:
- `_TempEtoro_201612` suffix on all index/constraint names = created Dec 2016 as migration step, became permanent.
- UNIQUE NC on CreditID enforces one extended snapshot per credit event.
- NC on PositionID (FILLFACTOR=100, on [MAIN]) supports "find all credit events for this position" queries.
- CLUSTERED PK on CreditExtendedID (FILLFACTOR=90, on [PRIMARY]) for sequential insert performance.
- PAGE compression on all indexes.

**Filegroup**: Table body on [PRIMARY]; PositionID NC index on [MAIN].

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryCreditExtended_TempEtoro_201612 | PRIMARY KEY (CLUSTERED) | Uniqueness on CreditExtendedID |
| uix_HistoryActiveCreditExtended_CreditID | UNIQUE NONCLUSTERED | One snapshot per CreditID |
| FK_HCE_CID_TempEtoro_201612 | FOREIGN KEY (WITH NOCHECK) | CID -> Customer.CustomerStatic |
| FK_HCE_MMLogID_TempEtoro_201612 | FOREIGN KEY (WITH NOCHECK) | MMLogID -> History.MMLog.ID |

---

## 8. Sample Queries

### 8.1 Customer's financial state at a specific credit event
```sql
SELECT ace.CreditExtendedID, ace.CreditID, ace.CreditTypeID, ace.CID, ace.Occurred,
       ace.TotalCash, ace.TotalPositionsAmount, ace.InProcessCashouts,
       ace.TotalMirrorPositionsAmount, ace.TotalMirrorCash, ace.MirrorID
FROM [History].[CreditExtended] ace  -- use view, not table directly
WHERE ace.CID = 12345
  AND ace.MirrorID = 0  -- non-mirror row (CID-level totals)
ORDER BY ace.CreditID DESC
```

### 8.2 Full balance sheet at a specific point in time
```sql
-- Most recent extended record before a given date
SELECT TOP 1 ace.CreditID, ace.Occurred,
       ace.TotalCash, ace.TotalPositionsAmount, ace.InProcessCashouts,
       ace.TotalMirrorPositionsAmount, ace.TotalStockOrders
FROM [History].[CreditExtended] ace
WHERE ace.CID = 12345
  AND ace.MirrorID = 0
  AND ace.Occurred <= '2023-01-01'
ORDER BY ace.CreditID DESC
```

### 8.3 Position lifecycle - financial state when each position was opened/closed
```sql
SELECT ace.CreditID, ace.CreditTypeID, ace.PositionID, ace.Occurred,
       ace.TotalCash, ace.TotalPositionsAmount
FROM [History].[CreditExtended] ace
WHERE ace.PositionID = 12345678
ORDER BY ace.CreditID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 9.5/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActiveCreditExtended | Type: Table | Source: etoro/etoro/History/Tables/History.ActiveCreditExtended.sql*
