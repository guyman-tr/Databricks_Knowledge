# Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit

> Trading API procedure that returns paginated flat portfolio history (credits + mirror events) from the full historical credit archive, with a second result set of position details - serving customers whose requested history is older than approximately one year.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the "historical data" implementation of the flat portfolio history API, called by the router `Trade.TAPI_GetFlatCreditHistoryByCID` when the requested start time is older than approximately 367 days. It reads from `History.Credit` and `History.Mirror` - the full historical archive stores - and returns the same comprehensive account activity timeline as its sibling `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit`, but sourced from long-term storage.

The business logic, result set schema, filtering rules, CTE architecture, and pagination mechanism are **identical** to the HistoryActiveCredit variant. The only differences are:
1. `History.Credit` instead of `History.ActiveCredit` as the credit event source
2. `History.Position` instead of `History.PositionSlim` as the position detail source for Result Set 2

This separation exists because `History.ActiveCredit` holds only recent/active records (approximately the past year), while `History.Credit` is the complete historical archive including records that have been aged out of the active store. Using the correct table for the correct time range ensures performance (ActiveCredit is indexed and sized for fast recent lookups) and completeness (Credit has the full history for older requests).

See `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit` for full documentation of all business logic - this procedure is a mirror of that one with different data sources.

---

## 2. Business Logic

All business logic is identical to `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit`. See that procedure's documentation for full details. Key logic summary:

### 2.1 Broad CreditType Filter - The "Flat" Scope

Same as HistoryActiveCredit variant:
- `CreditTypeID IN (1, 2, 4, 5, 6, 7, 8, 9, 11, 12, 16, 17, 18, 19, 20, 21, 22, 24)`
- `OR (CreditTypeID = 14 AND Description LIKE 'CA Type=%')` for corporate actions
- Filtered through `Dictionary.HistoryCreditActionsToHide` to hide specific compensation types

### 2.2 Two CTEs: closedMirrorAtEndTime and HistoryMirrorAndCredit

Same CTE structure as HistoryActiveCredit variant, with `History.Credit` as the credit source:
- `closedMirrorAtEndTime`: mirrors where MirrorOperationID=2 (closed) within the time window
- `HistoryMirrorAndCredit` UNION ALL: credit branch (IsCredit=1) from `History.Credit` + mirror event branch (IsCredit=0) for MirrorOperationID IN (12,13)

### 2.3 Complex WHERE Filter - Four OR Branches

Identical to HistoryActiveCredit variant - same 4-branch logic for copy vs. non-copy event inclusion.

### 2.4 ActionType=20 Exclusion

Identical: `ISNULL(p.ActionType, 0) != 20` - but joins to `History.Position` (not PositionSlim).

### 2.5 Pagination via Temp Table

Identical: INSERT INTO #t with ORDER BY then OFFSET/FETCH, two SELECT queries against #t.

### 2.6 Key Difference: Data Sources

| Aspect | HistoryActiveCredit variant | HistoryCredit variant (this) |
|--------|-----------------------------|-----------------------------|
| Credit source | History.ActiveCredit | History.Credit |
| Position source | History.PositionSlim | History.Position |
| Data age | Recent (~<1 year) | Historical (>~367 days) |
| Called when | @startTime > 367 days ago OR NULL | @startTime <= 367 days ago |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All queries are scoped to this customer. Required. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time filter. This delegate is called when @startTime <= DATEADD(DAY, -367, GETUTCDATE()) by the router. Applies the 4-branch copy/non-copy filter logic. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number for pagination. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Number of rows per page. Applied as FETCH NEXT @itemsPerPage ROWS ONLY. |

### Output - Result Set 1 (Flat Credit/Mirror Events - Paginated)

Identical schema to `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit` Result Set 1:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | INT | YES | - | CODE-BACKED | Credit record ID from History.Credit. 0 for mirror lifecycle synthetic rows. |
| 2 | CreditTypeID | INT | YES | - | CODE-BACKED | Credit event type. NULL for mirror events. See HistoryActiveCredit variant for full value map. (Dictionary.CreditType) |
| 3 | MirrorOperationID | INT | YES | - | CODE-BACKED | Mirror lifecycle operation. NULL for credit rows. 12=start copy, 13=transfer for mirror events. |
| 4 | Occurred | DATETIME | NO | - | CODE-BACKED | Event timestamp. Primary sort key (DESC). |
| 5 | Payment | MONEY | YES | - | CODE-BACKED | Dollar amount. 0 for mirror events. |
| 6 | PositionID | BIGINT | YES | - | CODE-BACKED | Associated position. NULL for CreditTypeID=6 (Compensation). 0 for mirror events. |
| 7 | ChampionshipID | INT | YES | - | CODE-BACKED | Championship ID for CreditTypeID=5. 0 for mirror events. |
| 8 | CashoutID | INT | YES | - | CODE-BACKED | Cashout transaction ID. FK to Billing.Cashout. 0 for mirror events. |
| 9 | PaymentID | INT | YES | - | CODE-BACKED | Payment gateway ID. 0 for mirror events. |
| 10 | WithdrawID | INT | YES | - | CODE-BACKED | Withdrawal transaction ID. 0 for mirror events. |
| 11 | WithdrawProcessingID | INT | YES | - | CODE-BACKED | Withdrawal processing batch ID. 0 for mirror events. |
| 12 | DepositID | INT | YES | - | CODE-BACKED | Deposit transaction ID for CreditTypeID=1. 0 for mirror events. |
| 13 | UpdateID | INT | YES | - | CODE-BACKED | Internal update identifier. 0 for mirror events. |
| 14 | CampaignID | INT | YES | - | CODE-BACKED | Marketing campaign ID. 0 for mirror events. |
| 15 | BonusTypeID | INT | YES | - | CODE-BACKED | Bonus type for CreditTypeID=7. 0 for mirror events. |
| 16 | CompensationReasonID | INT | YES | - | CODE-BACKED | Compensation reason for CreditTypeID=6. 0 for mirror events. |
| 17 | MoveMoneyReasonID | INT | YES | - | CODE-BACKED | Internal money movement reason code. 0 for mirror events. |
| 18 | ParentCID | INT | YES | - | CODE-BACKED | Popular Investor CID for copy-related credits. From closedMirrorAtEndTime.ParentCID. |
| 19 | IsCopyDividend | BIT | NO | - | CODE-BACKED | 1 if this credit is a copy trading dividend (non-null/non-zero MirrorDividendID). |
| 20 | CashoutReasonID | INT | NO | - | CODE-BACKED | Cashout reason from Billing.Withdraw. ISNULL-defaulted to 0. |
| 21 | CorporateActionDescription | VARCHAR | YES | - | CODE-BACKED | Corporate action description for CreditTypeID=14 with 'CA Type=%' description. NULL otherwise. |

### Output - Result Set 2 (Position Details - from History.Position)

Identical schema to `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit` Result Set 2, but sourced from `History.Position` instead of `History.PositionSlim`:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Amount | MONEY | YES | - | CODE-BACKED | Originally invested dollar amount. From History.Position. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument traded. FK to Trade.InstrumentMetaData. |
| 4 | IsBuy | BIT | NO | - | CODE-BACKED | 1=Buy/Long, 0=Sell/Short. |
| 5 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier at open. |
| 6 | InitDateTime | DATETIME | YES | - | CODE-BACKED | Position open timestamp. |
| 7 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Currency conversion rate at open. |
| 8 | PositionID | BIGINT | NO | - | CODE-BACKED | Position identifier. Joins to PositionID in Result Set 1. |
| 9 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop-loss rate at open. |
| 10 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take-profit rate at open. |
| 11 | AmountInUnitsDecimal | DECIMAL | NO | - | CODE-BACKED | Position size in units. ISNULL-defaulted to 0. |
| 12 | EndOfWeekFee | MONEY | YES | - | CODE-BACKED | Accumulated end-of-week fees. |
| 13 | InitialAmountInDollars | MONEY | YES | - | CODE-BACKED | InitialAmountCents / 100. Cost basis in dollars. |
| 14 | OrderID | INT | NO | - | CODE-BACKED | Order that opened this position. ISNULL-defaulted to 0. |
| 15 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | Parent position for copy trades. ISNULL-defaulted to 0. |
| 16 | MirrorID | INT | NO | - | CODE-BACKED | Copy mirror ID. ISNULL-defaulted to 0. |
| 17 | ActionType | INT | YES | - | CODE-BACKED | Close action type. Type 20 is excluded by the credit CTE filter. |
| 18 | NetProfit | MONEY | YES | - | CODE-BACKED | Net P&L on close. |
| 19 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Currency conversion rate at close. |
| 20 | CloseOccurred | DATETIME | YES | - | CODE-BACKED | Position close timestamp. Result Set 2 ordered by CloseOccurred DESC. |
| 21 | ParentCID | INT | NO | - | CODE-BACKED | Popular Investor CID for copy positions. ISNULL-defaulted to 0. From #t.ParentCID. |
| 22 | IsSettled | BIT | YES | - | CODE-BACKED | Whether position has completed settlement. |
| 23 | SettlementTypeID | INT | YES | - | CODE-BACKED | Settlement type. FK to Dictionary.SettlementType. |
| 24 | RedeemStatus | INT | NO | - | CODE-BACKED | Redeem/withdrawal status. ISNULL-defaulted to 0. |
| 25 | OriginalPositionID | BIGINT | NO | - | CODE-BACKED | Original position ID before migrations. ISNULL-defaulted to PositionID. |
| 26 | InitialUnits | DECIMAL | YES | - | CODE-BACKED | Units at original open. |
| 27 | OpenActionType | INT | YES | - | CODE-BACKED | Action type that triggered position open. FK to Dictionary.OpenPositionActionType. |
| 28 | CloseTotalFees | MONEY | YES | - | CODE-BACKED | Total fees at close. |
| 29 | CloseTotalTaxes | MONEY | YES | - | CODE-BACKED | Total taxes at close. |
| 30 | OpenTotalFees | MONEY | YES | - | CODE-BACKED | Total fees at open. |
| 31 | OpenTotalTaxes | MONEY | YES | - | CODE-BACKED | Total taxes at open. |
| 32 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots. |
| 33 | InitialLotCount | DECIMAL | YES | - | CODE-BACKED | Lot count at original open. |
| 34 | OriginalOpenActionType | INT | YES | - | CODE-BACKED | Original open action type before modification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CreditTypeID | History.Credit | Lookup (READ) | Primary source for credit event data (full historical archive) |
| MirrorID, CID | History.Mirror | Lookup (READ) | Source for mirror lifecycle events (closures + start/transfer operations) |
| WithdrawID | Billing.Withdraw | Lookup (LEFT JOIN) | Enriches cashout credits with CashoutReasonID |
| PositionID | History.Position | Lookup (LEFT JOIN) | ActionType filter + full position detail result set (historical version) |
| CreditTypeID, CompensationReasonID | Dictionary.HistoryCreditActionsToHide | Lookup (LEFT JOIN) | Hide filter for specific compensation credit types |

### 5.2 Referenced By (other objects point to this)

Called by `Trade.TAPI_GetFlatCreditHistoryByCID` (router) when @startTime <= DATEADD(DAY, -367, GETUTCDATE()). Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit (procedure)
├── History.Credit (table - cross-schema)
├── History.Mirror (table - cross-schema)
├── Billing.Withdraw (table - cross-schema)
├── History.Position (table - cross-schema)
└── Dictionary.HistoryCreditActionsToHide (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | Primary credit event source for historical data (>~367 days) |
| History.Mirror | Table (cross-schema) | Mirror closure detection (CTE) + mirror lifecycle event injection |
| Billing.Withdraw | Table (cross-schema) | LEFT JOIN for CashoutReasonID on cashout credits |
| History.Position | Table (cross-schema) | ActionType filter + full position detail in Result Set 2 (historical archive) |
| Dictionary.HistoryCreditActionsToHide | Table (cross-schema) | Exclude specific (CreditTypeID, CompensationReasonID) pairs from customer view |

### 6.2 Objects That Depend On This

Called by `Trade.TAPI_GetFlatCreditHistoryByCID` (router). No other SQL dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table #t for paginated intermediate results.

### 7.2 Constraints

None. Note: `History.Position` is the full historical position archive (as opposed to `History.PositionSlim` used by the ActiveCredit variant). History.Position contains the complete field set; PositionSlim is a leaner store for recent data. The column set returned by Result Set 2 is identical between both variants.

---

## 8. Sample Queries

### 8.1 Get historical flat credit history (older than 1 year)

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit
    @cid = 12345,
    @startTime = '2024-01-01',  -- >367 days ago
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Preview historical credit data directly

```sql
SELECT TOP 20
    hc.CreditID,
    hc.CreditTypeID,
    RTRIM(ct.Name) AS CreditTypeName,
    hc.Occurred,
    hc.Payment,
    hc.PositionID
FROM History.Credit hc WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ct.CreditTypeID = hc.CreditTypeID
WHERE hc.CID = 12345
    AND (hc.CreditTypeID IN (1, 2, 4, 5, 6, 7, 8, 9, 11, 12, 16, 17, 18, 19, 20, 21, 22, 24)
        OR (hc.CreditTypeID = 14 AND hc.Description LIKE 'CA Type=%'))
ORDER BY hc.Occurred DESC
```

### 8.3 Compare volume between History.Credit and History.ActiveCredit for a customer

```sql
SELECT 'History.Credit' AS Source, COUNT(*) AS RecordCount
FROM History.Credit WITH (NOLOCK)
WHERE CID = 12345

UNION ALL

SELECT 'History.ActiveCredit', COUNT(*)
FROM History.ActiveCredit WITH (NOLOCK)
WHERE CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup used; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit.sql*
