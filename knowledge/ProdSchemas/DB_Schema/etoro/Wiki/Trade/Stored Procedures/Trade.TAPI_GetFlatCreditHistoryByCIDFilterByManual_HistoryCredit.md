# Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit

> Trading API procedure that returns paginated non-copy (manual) position close history from the full historical archive - identical logic to the HistoryActiveCredit variant but sourced from History.Credit and History.Position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the "historical data" implementation of the manual filter view, called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual` when @startTime is older than ~367 days. All business logic is identical to `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit`. The only differences are data sources:
- `History.Credit` instead of `History.ActiveCredit`
- `History.Position` instead of `History.PositionSlim`

See `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit` for full documentation.

---

## 2. Business Logic

All logic identical to HistoryActiveCredit variant:
- `CreditTypeID IN (4, 22, 24) AND MirrorID = 0` - non-copy position closes
- Simple time filter: `(@startTime IS NULL) OR (Occurred >= @startTime)`
- ActionType != 20 exclusion via History.Position LEFT JOIN
- HistoryCreditActionsToHide filter
- Two result sets via temp table #t

**Key Data Source Difference**:

| Aspect | HistoryActiveCredit variant | HistoryCredit variant (this) |
|--------|-----------------------------|-----------------------------|
| Credit source | History.ActiveCredit | History.Credit |
| Position source | History.PositionSlim | History.Position |
| Data age | Recent (~<1 year) | Historical (>~367 days) |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All queries scoped to this customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time. This delegate is called when @startTime <= DATEADD(DAY, -367, GETUTCDATE()). |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. FETCH NEXT @itemsPerPage ROWS ONLY. |

### Output - Result Set 1 (Manual Position Close Credits - from History.Credit)

Identical 18-column schema to `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit` Result Set 1:
CreditID, CreditTypeID (4/22/24), Occurred, Payment, PositionID, ChampionshipID, CashoutID, PaymentID, WithdrawID, WithdrawProcessingID, DepositID, UpdateID, CampaignID, BonusTypeID, CompensationReasonID, ParentCID (always NULL), MoveMoneyReasonID, IsCopyDividend.

### Output - Result Set 2 (Position Details - from History.Position)

Same 34-column schema as HistoryActiveCredit variant, sourced from `History.Position` (full historical archive).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CreditTypeID | History.Credit | Lookup (READ) | Source for historical non-copy position close credits |
| PositionID | History.Position | Lookup (LEFT JOIN/INNER JOIN) | ActionType filter + position detail result set (historical) |
| CreditTypeID, CompensationReasonID | Dictionary.HistoryCreditActionsToHide | Lookup (LEFT JOIN) | Hide filter |

### 5.2 Referenced By (other objects point to this)

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual` (router) when @startTime <= DATEADD(DAY, -367, GETUTCDATE()). Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit (procedure)
├── History.Credit (table - cross-schema)
├── History.Position (table - cross-schema)
└── Dictionary.HistoryCreditActionsToHide (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | Primary source for historical non-copy close credit data |
| History.Position | Table (cross-schema) | ActionType filter + position detail result set |
| Dictionary.HistoryCreditActionsToHide | Table (cross-schema) | Hide filter |

### 6.2 Objects That Depend On This

Called by `Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual` (router). No other SQL dependents.

---

## 7. Technical Details

N/A for stored procedure. Uses temp table #t.

---

## 8. Sample Queries

```sql
EXEC Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit
    @cid = 12345,
    @startTime = '2024-01-01',
    @pageNumber = 1,
    @itemsPerPage = 20
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup used; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit.sql*
