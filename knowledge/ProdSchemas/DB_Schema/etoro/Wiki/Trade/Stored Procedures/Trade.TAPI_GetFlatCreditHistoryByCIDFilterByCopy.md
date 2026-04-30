# Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy

> Trading API router procedure that dispatches to the correct copy-trading-filtered history implementation based on data age - returning only copy/mirror-related events (position closes, balance transfers) for the customer-facing copy filter tab.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the public-facing TAPI endpoint for the "copy" (copy trading) filter view within the flat portfolio history section. It returns only events related to copy trading activity: position closes that occurred within a copy relationship, mirror balance transfers, and mirror lifecycle events (start/transfer). It powers the "Copy" tab in the customer's portfolio history UI.

The routing logic is identical to all other flat history routers: requests older than ~367 days route to the full historical archive (`History.Credit`/`History.Position`), while recent or unfiltered requests use the active stores.

Unlike the cashflows filter (which is simple), the copy filter retains the CTE architecture from the full flat history - because copy events are inherently tied to mirror context and require the `closedMirrorAtEndTime` CTE to determine which copy events fall within the requested time window. The procedure also returns a second result set with position details.

---

## 2. Business Logic

### 2.1 Data Source Routing

Identical 367-day rule to all other flat history routers:
- `@startTime <= DATEADD(DAY, -367, GETUTCDATE())` -> `TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit`
- `ELSE` -> `TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit`

### 2.2 Copy Filter vs Full Flat History

| Aspect | Full Flat History | FilterByCopy |
|--------|------------------|--------------|
| Credit types | All (1-24 subset) | 4, 18, 19, 20, 21, 22, 24 only |
| Cashflow types (1,2,5-9,11-12,16-17) | Yes | No |
| Corporate actions (14) | Yes | No |
| Mirror events (12,13) | Yes | Yes |
| Position close (4) | Yes | Yes |
| Mirror balance transfers (18-22,24) | Yes | Yes |
| CorporateActionDescription | Yes | No |
| Result sets | 2 | 2 |
| CTE architecture | Yes | Yes |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Forwarded to delegate. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time. Drives routing: NULL or recent -> HistoryActiveCredit, >367 days ago -> HistoryCredit. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. Forwarded to delegate. |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. Forwarded to delegate. |

### Output

Returns result sets from delegate - see:
- `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit`
- `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit`

Two result sets: (1) paginated copy events (20 columns, no CorporateActionDescription), (2) position details from History.PositionSlim or History.Position.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (recent data) | Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit | EXEC (delegation) | Delegate for @startTime = NULL or within ~1 year |
| (historical data) | Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit | EXEC (delegation) | Delegate for @startTime older than ~367 days |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser (Trading Data API service account).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy (router)
├── Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit
└── Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit | Stored Procedure | Delegate for recent data |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit | Stored Procedure | Delegate for historical data |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

N/A for stored procedure.

---

## 8. Sample Queries

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy.sql*
