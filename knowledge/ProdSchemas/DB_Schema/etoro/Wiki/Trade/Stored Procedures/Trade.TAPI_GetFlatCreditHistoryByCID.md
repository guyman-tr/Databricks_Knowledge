# Trade.TAPI_GetFlatCreditHistoryByCID

> Trading API router procedure that dispatches to the correct flat credit history implementation based on whether the requested time range falls within the active credit store (<=367 days) or the full historical archive (>367 days old).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the single public-facing TAPI (Trading API) endpoint for the "flat" portfolio history view - the comprehensive account activity feed that shows money movements, position closes, copy trading events, and corporate actions all in one unified timeline. It is the entry point for clients; all routing logic is encapsulated here so the caller does not need to know which underlying data store is queried.

The "flat" naming distinguishes this family from `Trade.TAPI_GetCreditHistoryByCID` (the non-flat variant). The flat version includes a broader credit type set - notably CreditTypeID=4 (Close Position), mirror balance transfers (types 18-22), and corporate actions (type 14 with 'CA Type=%') - and returns a second result set with position details for each credit event. This makes it the richer, more complete API for portfolio history rendering.

The routing decision is based on data residency: credit records older than approximately one year (>367 days) are archived from `History.ActiveCredit` into `History.Credit`. The 367-day threshold (365 + 2 buffer days, per code comment "1 YEAR - 2 DAYS TO BE SURE") ensures requests for old data are directed to the full historical archive without missing edge-case records near the boundary.

The procedure is called by the TDAPIUser service account (Trading Data API), which serves the customer-facing trading platform.

---

## 2. Business Logic

### 2.1 Data Source Routing - The 367-Day Rule

**What**: Routes to different underlying procedures depending on the age of the requested data.

**Columns/Parameters Involved**: `@startTime`

**Rules**:
- `IF @startTime <= DATEADD(DAY, -367, GETUTCDATE())` -> data is older than ~1 year -> route to `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit` (full historical archive).
- `ELSE` (including @startTime = NULL, since NULL compared with <= evaluates to UNKNOWN/false in SQL Server) -> recent or no time filter -> route to `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit`.
- The "367" is 365 days + 2 safety days to avoid boundary misses during the archival transition window.
- NULL @startTime: NULL <= date is UNKNOWN in SQL Server, which evaluates as false in IF, so NULL always routes to HistoryActiveCredit (correct - no start time means "load all available" which is the active store).

**Diagram**:
```
TAPI_GetFlatCreditHistoryByCID
  |
  |-- IF @startTime <= GETUTCDATE() - 367 days
  |     -> EXEC TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit
  |        (source: History.Credit + History.Position)
  |
  |-- ELSE (recent or NULL)
        -> EXEC TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit
           (source: History.ActiveCredit + History.PositionSlim)
```

### 2.2 Parameter Pass-Through

**What**: All parameters are passed unchanged to the delegate procedure.

**Rules**:
- @cid, @startTime, @pageNumber, @itemsPerPage are all forwarded verbatim.
- The delegate applies pagination (OFFSET/FETCH) and time filtering; this router does no data manipulation.
- Both delegates return identical result set schemas (20 columns in result set 1, 30 columns in result set 2).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Scopes all history to this single customer. Forwarded to the delegate procedure. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time filter. If <= 367 days ago -> routes to HistoryCredit archive. If NULL or recent -> routes to HistoryActiveCredit. NULL means "no start filter" (load all available history). |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number for pagination. Forwarded to the delegate which applies OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Number of rows per page. Forwarded to the delegate which applies FETCH NEXT @itemsPerPage ROWS ONLY. |

### Output

This procedure returns the result sets from its delegate - see:
- `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit` for the result set schema (recent data path)
- `Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit` for the result set schema (historical data path)

Both delegates return 2 result sets with identical schemas:
- **Result Set 1**: Paginated flat credit/mirror events (20 columns: CreditID, CreditTypeID, MirrorOperationID, Occurred, Payment, PositionID, ChampionshipID, CashoutID, PaymentID, WithdrawID, WithdrawProcessingID, DepositID, UpdateID, CampaignID, BonusTypeID, CompensationReasonID, MoveMoneyReasonID, ParentCID, IsCopyDividend, CashoutReasonID, CorporateActionDescription)
- **Result Set 2**: Position details for positions referenced in Result Set 1 (30 columns from History.PositionSlim or History.Position)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (recent data) | Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit | EXEC (delegation) | Delegate for @startTime = NULL or within ~1 year |
| (historical data) | Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit | EXEC (delegation) | Delegate for @startTime older than ~367 days |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser (Trading Data API service account) serving the customer-facing trading platform.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCID (router)
├── Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit (recent data path)
│   ├── History.ActiveCredit
│   ├── History.Mirror
│   ├── Billing.Withdraw
│   ├── History.PositionSlim
│   └── Dictionary.HistoryCreditActionsToHide
└── Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit (historical data path)
    ├── History.Credit
    ├── History.Mirror
    ├── Billing.Withdraw
    ├── History.Position
    └── Dictionary.HistoryCreditActionsToHide
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit | Stored Procedure | Delegate for recent/no-filter requests |
| Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit | Stored Procedure | Delegate for historical (>367 days) requests |

### 6.2 Objects That Depend On This

No SQL dependents found. Called by TDAPIUser (Trading Data API service account).

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Note: NULL @startTime routes to HistoryActiveCredit because `NULL <= date` evaluates as UNKNOWN (false) in the IF condition - this is intentional and correct behavior.

---

## 8. Sample Queries

### 8.1 Get first page of flat credit history (no time filter)

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCID
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Get credit history from recent period (routes to HistoryActiveCredit)

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCID
    @cid = 12345,
    @startTime = '2026-01-01',
    @pageNumber = 1,
    @itemsPerPage = 50
```

### 8.3 Get credit history from historical archive (routes to HistoryCredit)

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCID
    @cid = 12345,
    @startTime = '2024-01-01',  -- >367 days ago from 2026-03-17
    @pageNumber = 1,
    @itemsPerPage = 50
```

### 8.4 Check the routing boundary

```sql
-- Any @startTime older than this date will route to HistoryCredit:
SELECT DATEADD(DAY, -367, GETUTCDATE()) AS RoutingBoundary
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCID.sql*
