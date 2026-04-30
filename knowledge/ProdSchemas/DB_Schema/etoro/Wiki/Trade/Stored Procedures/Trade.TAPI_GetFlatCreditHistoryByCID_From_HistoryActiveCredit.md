# Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit

> Trading API procedure that returns paginated flat portfolio history (credits + mirror events) from the active credit store, with a second result set of position details - serving customers whose requested history is within approximately one year.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the "recent data" implementation of the flat portfolio history API, called by the router `Trade.TAPI_GetFlatCreditHistoryByCID` when the requested start time is within approximately one year (or NULL). It reads from `History.ActiveCredit` and `History.Mirror` - the live, frequently-accessed stores - and returns the comprehensive account activity timeline shown in the customer-facing portfolio history section.

"Flat" means this procedure combines multiple event types in one unified chronological feed:
1. **Standard money movements**: Deposits (1), cashouts (2), bonuses (7), chargebacks (11), refunds (12), etc.
2. **Position close credits**: CreditTypeID=4 (Close Position) - unlike the non-flat TAPI variant which excludes these
3. **Copy trading (mirror) balance transfers**: Types 18 (balance to mirror), 19 (mirror to account), 20 (register new mirror), 21 (unregister mirror), 22 (hierarchical close), 24 (close by recovery)
4. **Corporate actions**: CreditTypeID=14 where Description LIKE 'CA Type=%' (stock splits, dividends processed as credit adjustments)
5. **Mirror lifecycle events**: MirrorOperationID 12 (start copy) and 13 (transfer) injected as synthetic rows (IsCredit=0, zero Payment) to show when copy relationships began

The procedure also returns a second result set: position details from `History.PositionSlim` for each position referenced in the first result set. This allows clients to render rich position information (instrument, amount, P&L, direction) alongside each credit event in a single API call.

---

## 2. Business Logic

### 2.1 Broad CreditType Filter - The "Flat" Scope

**What**: Includes all credit types relevant to the complete account activity feed, including position closes and mirror operations excluded from the non-flat variant.

**Columns/Parameters Involved**: `CreditTypeID`, `Description`

**Rules**:
- Standard IN filter: `CreditTypeID IN (1, 2, 4, 5, 6, 7, 8, 9, 11, 12, 16, 17, 18, 19, 20, 21, 22, 24)`
- Corporate actions: `OR (CreditTypeID = 14 AND Description LIKE 'CA Type=%')`
- Note: Type 15 (Cashout Fee) is excluded. Types 3 (Open Position) and 10 (IB sync) are excluded.
- Excluded type 4 (Close Position) for mirror-linked events has special handling via the copy position filter branch (see 2.3).
- Excluded from HistoryCreditActionsToHide: `hsa.CreditTypeID IS NULL` - hides specific compensation types that should not appear in the customer view.

**CreditType key values**:
- 1=Deposit, 2=Cashout, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 11=Chargeback, 12=Refund, 14=End Of Week Fee (corp action variant), 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18=Account balance to mirror, 19=Mirror balance to account, 20=Register new mirror, 21=Unregister mirror, 22=Mirror Hierarchical Close position, 24=Close position by recovery

### 2.2 Two CTEs: closedMirrorAtEndTime and HistoryMirrorAndCredit

**What**: CTE architecture that first identifies relevant mirror closures, then builds the unified credit+mirror event stream.

**Rules for closedMirrorAtEndTime**:
- Selects all History.Mirror records for @cid where MirrorOperationID = 2 (mirror closed).
- Filtered by `ModificationDate > @startTime` when @startTime is set - only mirrors that closed within or after the requested time window.
- When @startTime IS NULL: all closed mirrors for the customer.
- Returns: MirrorID, ParentCID (the trader being copied), Occurred (when the mirror was closed).

**Rules for HistoryMirrorAndCredit UNION ALL**:
- **Branch 1** (IsCredit=1): Credit records from History.ActiveCredit with:
  - LEFT JOIN to closedMirrorAtEndTime on MirrorID -> populates ParentCID for copy-related credits
  - LEFT JOIN to Billing.Withdraw on WithdrawID -> adds CashoutReasonID
  - LEFT JOIN to History.PositionSlim on PositionID -> used only for the ActionType filter (ISNULL(p.ActionType,0) != 20 excludes certain close types)
  - LEFT JOIN to Dictionary.HistoryCreditActionsToHide -> hide filter
  - CreditTypeID=6 (Compensation): PositionID forced to NULL (compensations should not link to a position)
  - CorporateActionDescription: populated only for CreditTypeID=14 with 'CA Type=%' description
- **Branch 2** (IsCredit=0): Synthetic mirror event rows from History.Mirror:
  - Only MirrorOperationID IN (12, 13) - start copy and transfer events
  - INNER JOIN to closedMirrorAtEndTime (only includes events for mirrors that were closed in the time window)
  - Zero values for all financial fields (Payment=0, CreditID=0, etc.)
  - CreditTypeID=NULL (these are not credit records, they are mirror lifecycle events)

### 2.3 Complex WHERE Filter - Four OR Branches

**What**: The WHERE clause on the credit branch uses 4 OR branches to handle the interaction between @startTime and copy/non-copy position types correctly.

**Columns/Parameters Involved**: `@startTime`, `MirrorID`, `CreditTypeID`, `closedMirrorAtEndTime.MirrorID`, `Occurred`

**Rules (all four branches are OR'd)**:
```
Branch 1: @startTime IS NULL AND NOT (MirrorID > 0 AND cm.MirrorID IS NULL)
  -> When no time filter, include all records EXCEPT copy-related records
     (types 18/19/20/21/22/24) where the mirror was not closed in the window
     (prevents showing dangling copy events with no mirror context)

Branch 2: Occurred >= @startTime AND CreditTypeID NOT IN (4, 18, 19, 20, 21, 22, 24)
  -> Standard money movements (deposits, cashouts, bonuses, etc.): simply filter by date

Branch 3: Occurred >= @startTime AND CreditTypeID IN (4, 22, 24) AND MirrorID = 0
  -> Non-copy close positions / hierarchical close / recovery close: filter by date normally
     (these are manual/direct close credits, not copy-linked)

Branch 4: cm.Occurred IS NOT NULL AND CreditTypeID IN (4, 18, 19, 20, 21, 22, 24) AND MirrorID > 0
  -> Copy-linked events: include if the mirror was closed within the time window
     (regardless of the credit's own Occurred - the mirror close determines inclusion)
```

This logic ensures that copy trading history is shown only in the context of its mirror lifecycle: if a customer closed a copy at time T, all balance transfers and position closes belonging to that mirror appear together in the history view.

### 2.4 ActionType=20 Exclusion

**What**: Excludes position close credits where the position was closed with ActionType=20.

**Columns/Parameters Involved**: `History.PositionSlim.ActionType`, `CreditTypeID=4`

**Rules**:
- `ISNULL(p.ActionType, 0) != 20` - excludes position close credits where the underlying position has ActionType=20.
- ActionType=20 in PositionSlim is an internal system close type that should not appear in customer-facing history.
- The LEFT JOIN to History.PositionSlim is used solely for this filter - it does not add any columns to the result set.

### 2.5 Pagination via Temp Table

**What**: OFFSET/FETCH pagination is applied by inserting into a temp table #t, which is then queried twice for the two result sets.

**Rules**:
- `@offsetRows = @itemsPerPage * (@pageNumber - 1)` - 1-based page numbering.
- Data is inserted into `#t` with ORDER BY CID, Occurred DESC, CreditID DESC.
- Result Set 1 queries `#t` directly (already paginated).
- Result Set 2 queries `History.PositionSlim` INNER JOIN `#t` on PositionID - returns position details only for positions in the paginated result set where IsCredit=1.

### 2.6 Copy Dividend Detection

**What**: Flags credits derived from copy trading dividends.

**Rules**:
- `CASE ISNULL(MirrorDividendID, 0) WHEN 0 THEN 0 ELSE 1 END AS IsCopyDividend`
- IsCopyDividend=1 when the credit has a non-null, non-zero MirrorDividendID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All queries are scoped to this customer. Required. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time filter. When NULL: no date filter (loads all available from ActiveCredit). When set: applies the 4-branch filter for copy vs. non-copy events. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number for pagination. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Number of rows per page. Applied as FETCH NEXT @itemsPerPage ROWS ONLY in the temp table insert. |

### Output - Result Set 1 (Flat Credit/Mirror Events - Paginated)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | INT | YES | - | CODE-BACKED | Credit record ID from History.ActiveCredit. 0 for mirror lifecycle synthetic rows (IsCredit=0). |
| 2 | CreditTypeID | INT | YES | - | CODE-BACKED | Credit event type. NULL for mirror lifecycle events (IsCredit=0). For credit rows: 1=Deposit, 2=Cashout, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 11=Chargeback, 12=Refund, 14=End Of Week Fee (corp action variant), 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18=Account balance to mirror, 19=Mirror balance to account, 20=Register new mirror, 21=Unregister mirror, 22=Mirror Hierarchical Close, 24=Close by recovery. (Dictionary.CreditType) |
| 3 | MirrorOperationID | INT | YES | - | CODE-BACKED | Mirror lifecycle operation type. NULL for credit rows. For mirror event rows: 12=start copy, 13=transfer. (History.Mirror.MirrorOperationID) |
| 4 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp of the event. Used for primary ordering (DESC). For mirror events: ModificationDate from History.Mirror. |
| 5 | Payment | MONEY | YES | - | CODE-BACKED | Dollar amount of the credit. Positive=credit to account, negative=debit. 0 for mirror lifecycle events (they have no financial impact). |
| 6 | PositionID | BIGINT | YES | - | CODE-BACKED | Associated position ID. NULL for CreditTypeID=6 (Compensation - PositionID is forced NULL). 0 for mirror events. |
| 7 | ChampionshipID | INT | YES | - | CODE-BACKED | Championship ID for CreditTypeID=5 (Champ Winner) events. 0 for mirror events. |
| 8 | CashoutID | INT | YES | - | CODE-BACKED | Cashout transaction ID for cashout-related credit types (2, 8, 9). FK to Billing.Cashout. 0 for mirror events. |
| 9 | PaymentID | INT | YES | - | CODE-BACKED | Payment gateway transaction ID for deposit/cashout events. 0 for mirror events. |
| 10 | WithdrawID | INT | YES | - | CODE-BACKED | Withdrawal transaction ID. Used in LEFT JOIN to Billing.Withdraw for CashoutReasonID. 0 for mirror events. |
| 11 | WithdrawProcessingID | INT | YES | - | CODE-BACKED | Withdrawal processing batch ID. 0 for mirror events. |
| 12 | DepositID | INT | YES | - | CODE-BACKED | Deposit transaction ID for CreditTypeID=1 events. FK to Billing.Deposit. 0 for mirror events. |
| 13 | UpdateID | INT | YES | - | CODE-BACKED | Internal update/batch identifier for this credit record. 0 for mirror events. |
| 14 | CampaignID | INT | YES | - | CODE-BACKED | Marketing campaign ID for campaign-linked deposits or bonuses. 0 for mirror events. |
| 15 | BonusTypeID | INT | YES | - | CODE-BACKED | Bonus type for CreditTypeID=7 (Bonus) events. 0 for mirror events. |
| 16 | CompensationReasonID | INT | YES | - | CODE-BACKED | Reason code for CreditTypeID=6 (Compensation). 0 for mirror events. Used together with CreditTypeID in Dictionary.HistoryCreditActionsToHide filter. |
| 17 | MoveMoneyReasonID | INT | YES | - | CODE-BACKED | Reason code for internal money movement operations. Used for regulatory tracking. 0 for mirror events. |
| 18 | ParentCID | INT | YES | - | CODE-BACKED | The CID of the Popular Investor being copied, for copy-related credit events. From closedMirrorAtEndTime.ParentCID. 0 for non-copy or mirror events without a match. |
| 19 | IsCopyDividend | BIT | NO | - | CODE-BACKED | 1 if this credit is a dividend from copy trading (MirrorDividendID is non-null/non-zero). 0 for mirror events and non-copy dividends. |
| 20 | CashoutReasonID | INT | NO | - | CODE-BACKED | Reason code for cashout events from Billing.Withdraw. 0 (via ISNULL) when no matching Withdraw record. |
| 21 | CorporateActionDescription | VARCHAR | YES | - | CODE-BACKED | Description for corporate action credits: populated as hc.Description only when CreditTypeID=14 AND Description LIKE 'CA Type=%'. NULL for all other credit types and mirror events. |

### Output - Result Set 2 (Position Details for Credits in Result Set 1)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Amount | MONEY | YES | - | CODE-BACKED | Originally invested dollar amount for the position. From History.PositionSlim. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID owning the position. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument traded. FK to Trade.InstrumentMetaData. |
| 4 | IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1=Buy/Long, 0=Sell/Short. |
| 5 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier applied at open. |
| 6 | InitDateTime | DATETIME | YES | - | CODE-BACKED | Position open timestamp. |
| 7 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Currency conversion rate at open time. |
| 8 | PositionID | BIGINT | NO | - | CODE-BACKED | Position identifier. Joins to PositionID in Result Set 1. |
| 9 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop-loss rate at open. |
| 10 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take-profit rate at open. |
| 11 | AmountInUnitsDecimal | DECIMAL | NO | - | CODE-BACKED | Position size in units. ISNULL-defaulted to 0. |
| 12 | EndOfWeekFee | MONEY | YES | - | CODE-BACKED | Accumulated end-of-week fees charged to this position. |
| 13 | InitialAmountInDollars | MONEY | YES | - | CODE-BACKED | Computed: InitialAmountCents / 100. The initial cost basis in dollars. |
| 14 | OrderID | INT | NO | - | CODE-BACKED | Order that opened this position. ISNULL-defaulted to 0. |
| 15 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | Parent position for copy trades. ISNULL-defaulted to 0. >0 indicates this is a copied position. |
| 16 | MirrorID | INT | NO | - | CODE-BACKED | Copy mirror ID. ISNULL-defaulted to 0. >0 indicates a copy trade position. |
| 17 | ActionType | INT | YES | - | CODE-BACKED | Close action type. From History.PositionSlim. Type 20 is excluded by the credit filter (ActionType != 20 in the CTE). |
| 18 | NetProfit | MONEY | YES | - | CODE-BACKED | Net P&L on position close. |
| 19 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Currency conversion rate at close time. |
| 20 | CloseOccurred | DATETIME | YES | - | CODE-BACKED | Position close timestamp. Result Set 2 is ordered by CloseOccurred DESC. |
| 21 | ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor CID for copy positions. ISNULL-defaulted to 0. Sourced from #t.ParentCID (closedMirrorAtEndTime). |
| 22 | IsSettled | BIT | YES | - | CODE-BACKED | Whether the position has completed settlement (relevant for US equities T+1 settlement). |
| 23 | SettlementTypeID | INT | YES | - | CODE-BACKED | Settlement type. FK to Dictionary.SettlementType. |
| 24 | RedeemStatus | INT | NO | - | CODE-BACKED | Redeem/withdrawal status for the position's proceeds. ISNULL-defaulted to 0. |
| 25 | OriginalPositionID | BIGINT | NO | - | CODE-BACKED | Original position ID before any migrations or splits. ISNULL-defaulted to PositionID when null. |
| 26 | InitialUnits | DECIMAL | YES | - | CODE-BACKED | Units at original open (before any partial close). |
| 27 | OpenActionType | INT | YES | - | CODE-BACKED | Action type that triggered the position open. FK to Dictionary.OpenPositionActionType. |
| 28 | CloseTotalFees | MONEY | YES | - | CODE-BACKED | Total fees charged at position close. |
| 29 | CloseTotalTaxes | MONEY | YES | - | CODE-BACKED | Total taxes charged at position close. |
| 30 | OpenTotalFees | MONEY | YES | - | CODE-BACKED | Total fees charged at position open. |
| 31 | OpenTotalTaxes | MONEY | YES | - | CODE-BACKED | Total taxes charged at position open. |
| 32 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots (decimal precision). |
| 33 | InitialLotCount | DECIMAL | YES | - | CODE-BACKED | Lot count at original open. |
| 34 | OriginalOpenActionType | INT | YES | - | CODE-BACKED | The original open action type before any modification. Tracks how the position was originally initiated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CreditTypeID | History.ActiveCredit | Lookup (READ) | Primary source for credit event data (recent/active records) |
| MirrorID, CID | History.Mirror | Lookup (READ) | Source for mirror lifecycle events (closures + start/transfer operations) |
| WithdrawID | Billing.Withdraw | Lookup (LEFT JOIN) | Enriches cashout credits with CashoutReasonID |
| PositionID | History.PositionSlim | Lookup (LEFT JOIN) | ActionType filter + full position detail result set |
| CreditTypeID, CompensationReasonID | Dictionary.HistoryCreditActionsToHide | Lookup (LEFT JOIN) | Hide filter - excludes specific compensation credit types from customer view |

### 5.2 Referenced By (other objects point to this)

Called by `Trade.TAPI_GetFlatCreditHistoryByCID` (the public router) when @startTime is NULL or within ~367 days. Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit (procedure)
├── History.ActiveCredit (table - cross-schema)
├── History.Mirror (table - cross-schema)
├── Billing.Withdraw (table - cross-schema)
├── History.PositionSlim (table - cross-schema)
└── Dictionary.HistoryCreditActionsToHide (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table (cross-schema) | Primary credit event source for recent data |
| History.Mirror | Table (cross-schema) | Mirror closure detection (CTE) + mirror lifecycle event injection (UNION branch) |
| Billing.Withdraw | Table (cross-schema) | LEFT JOIN for CashoutReasonID on cashout credits |
| History.PositionSlim | Table (cross-schema) | ActionType filter in CTE + full position detail in Result Set 2 |
| Dictionary.HistoryCreditActionsToHide | Table (cross-schema) | Exclude specific (CreditTypeID, CompensationReasonID) pairs from customer view |

### 6.2 Objects That Depend On This

Called by `Trade.TAPI_GetFlatCreditHistoryByCID` (router). No other SQL dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table #t for paginated intermediate results.

### 7.2 Constraints

None. Note: CreditTypeID=6 (Compensation) has its PositionID forced to NULL in the SELECT - this is a data quality safeguard ensuring compensation credits are not accidentally linked to positions in the portfolio view.

---

## 8. Sample Queries

### 8.1 Get first page of flat history (no filter)

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Get flat history since a specific date

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit
    @cid = 12345,
    @startTime = '2026-01-01',
    @pageNumber = 1,
    @itemsPerPage = 50
```

### 8.3 Preview raw active credit feed with broad filter

```sql
SELECT TOP 20
    hc.CreditID,
    hc.CreditTypeID,
    RTRIM(ct.Name) AS CreditTypeName,
    hc.Occurred,
    hc.Payment,
    hc.PositionID,
    CASE ISNULL(hc.MirrorDividendID, 0) WHEN 0 THEN 0 ELSE 1 END AS IsCopyDividend
FROM History.ActiveCredit hc WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ct.CreditTypeID = hc.CreditTypeID
WHERE hc.CID = 12345
    AND (hc.CreditTypeID IN (1, 2, 4, 5, 6, 7, 8, 9, 11, 12, 16, 17, 18, 19, 20, 21, 22, 24)
        OR (hc.CreditTypeID = 14 AND hc.Description LIKE 'CA Type=%'))
ORDER BY hc.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup used; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit.sql*
