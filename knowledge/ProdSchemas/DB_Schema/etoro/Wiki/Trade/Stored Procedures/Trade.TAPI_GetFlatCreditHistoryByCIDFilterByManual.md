# Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual

> Trading API router procedure that dispatches to the correct manual (non-copy) position close history implementation based on data age - returning only manually-opened position closes for the customer-facing manual filter tab.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the public-facing TAPI endpoint for the "manual" filter view within the flat portfolio history section. It returns only position close credits for positions that were NOT opened via copy trading - i.e., manually opened positions. It powers the "Manual" tab in the customer's portfolio history UI.

Together, the three filter variants partition the portfolio history into complementary views:
- **Cashflows** (TAPI_GetFlatCreditHistoryByCIDFilterByCashflows): deposits, withdrawals, bonuses, etc. - no position closes
- **Copy** (TAPI_GetFlatCreditHistoryByCIDFilterByCopy): copy position closes and mirror lifecycle events (MirrorID > 0)
- **Manual** (this): non-copy position closes (MirrorID = 0)

The routing logic is identical to all other flat history routers: requests older than ~367 days route to the full historical archive.

---

## 2. Business Logic

### 2.1 Data Source Routing

Identical 367-day rule: `@startTime <= DATEADD(DAY, -367, GETUTCDATE())` -> HistoryCredit delegate, ELSE -> HistoryActiveCredit delegate.

### 2.2 Manual vs Copy Partitioning

| Filter | Credit Types | MirrorID Filter |
|--------|-------------|-----------------|
| FilterByCopy | 4, 18, 19, 20, 21, 22, 24 | MirrorID > 0 (copy positions) |
| FilterByManual | 4, 22, 24 | MirrorID = 0 (non-copy positions) |

Manual positions are: Close Position (type 4), Mirror Hierarchical Close (type 22), and Close by recovery (type 24) - but ONLY where `ISNULL(MirrorID, 0) = 0` (not part of a copy relationship).

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

Returns result sets from delegate. Two result sets: (1) manual position close credits (18 columns), (2) position details.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (recent data) | Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit | EXEC (delegation) | Delegate for @startTime = NULL or within ~1 year |
| (historical data) | Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit | EXEC (delegation) | Delegate for @startTime older than ~367 days |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.

---

## 6. Dependencies

```
Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual (router)
├── Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit
└── Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit
```

---

## 7. Technical Details

N/A for stored procedure.

---

## 8. Sample Queries

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual
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
*Object: Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual.sql*
