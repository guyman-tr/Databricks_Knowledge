# Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows

> Trading API procedure that returns paginated cashflow (money movement) events for a specific mirror session - deposits, withdrawals, dividends, and mirror state changes, excluding position closes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @mirrorId INT (cashflows-only filter, paginated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the cashflows-only filter variant within the mirror history family. It returns the money movement and mirror state change timeline for a specific copy session, without any position data. This powers a dedicated "Cashflows" tab in the mirror detail view that shows only financial flows: initial allocation, additional deposits, withdrawals, dividend credits, and mirror state events (pauses, resumes).

The filter logic uses CreditTypeID IN (18, 19, 20, 21, 27) - these are the money movement types, explicitly excluding the position-closing credit types (4, 22, 24) that appear in the "Copy" (positions) filter. Mirror state events (MirrorOperationID IN (12, 13)) are also included. The result is a single paginated result set, unlike the full `TAPI_GetMirrorHistoryWithCIDAndMirrorId` which returns two result sets.

---

## 2. Business Logic

### 2.1 Cashflow-Only Credit Type Filter

**What**: Selects only money movement credits, excluding position-closing events.

**Columns/Parameters Involved**: `CreditTypeID`, `@mirrorId`, `@cid`, `@startTime`

**Rules**:
- CreditTypeID IN (18, 19, 20, 21, 27) - money movement types only:
  - 18 = Account balance to mirror (deposit into copy session)
  - 19 = Mirror balance to account (withdrawal/money out), IsMoneyOut=1
  - 20 = Register new mirror (initial allocation), -> HistoryMirrorOperation 1
  - 21 = Mirror de-allocation (reduction), IsMoneyOut=1, -> HistoryMirrorOperation 2
  - 27 = Mirror money type 10, IsMoneyOut=1
- Excludes 4, 22, 24 (position closes) - those are in FilterByCopy
- UNION ALL with History.Mirror WHERE MirrorOperationID IN (12, 13) - special state events (pause/resume)
- `(Occurred >= @startTime OR @startTime IS NULL)` - optional date filter applied to both branches

### 2.2 HistoryMirrorOperation Mapping

**What**: Converts CreditTypeID values to standardized MirrorOperation display codes.

**Columns/Parameters Involved**: `CreditTypeID`, `HistoryMirrorOperation`

**Rules**:
- `CASE CreditTypeID WHEN 20 THEN 1 WHEN 21 THEN 2 WHEN 27 THEN 10 ELSE 3 END`
- CreditType 20 -> Op 1 (register/deposit)
- CreditType 21 -> Op 2 (withdrawal)
- CreditType 27 -> Op 10 (money movement type 10)
- CreditTypes 18, 19 -> Op 3 (general cashflow)
- Mirror state rows: HistoryMirrorOperation = MirrorOperationID directly (12 or 13)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). Scopes all events to this customer's mirror session. |
| 2 | @mirrorId | INT | NO | - | CODE-BACKED | Mirror session ID. Only cashflow events for this specific copy session are returned. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional period start. Applied to Credit.Occurred and Mirror.ModificationDate. When NULL: all-time cashflows for this mirror. |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Number of cashflow/state event rows per page. |

### Output - Cashflow Events and Mirror State Changes

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IsMoneyOut | BIT | NO | - | CODE-BACKED | 1 = funds left the mirror allocation (CreditTypeID IN 19, 21, 27: withdrawals and money-out events). 0 = funds entered or neutral state event. Mirror state rows always 0. |
| 2 | HistoryMirrorOperation | INT | NO | - | CODE-BACKED | Display code for the event type. Credit branch: 1=deposit/register (type 20), 2=withdrawal (type 21), 10=money type 27, 3=general cashflow (types 18,19). Mirror state branch: 12 or 13 (state event IDs passed through directly). See Dictionary.MirrorOperation for labels. |
| 3 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp of the event. From Credit.Occurred for cashflow rows; Mirror.ModificationDate for state rows. Sort key (DESC order). |
| 4 | MirrorAmountDelta | DECIMAL | NO | - | CODE-BACKED | Amount involved in the event (Payment * -1 for credit rows). Payment is stored as negative for debits; inversion gives the positive display amount. Always 0 for mirror state rows. |
| 5 | IsCopyDividend | BIT | NO | - | CODE-BACKED | 1 = this event is a dividend from a copy position (History.Credit.MirrorDividendID is populated). 0 = regular money flow. Always 0 for mirror state rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, CreditTypeID | History.Credit | Lookup (READ) | Source of all cashflow events (money movement credit types only) |
| MirrorID, CID, MirrorOperationID | History.Mirror | Lookup (READ) | Source of mirror state change events (MirrorOperationID 12, 13) |
| CreditTypeID | Dictionary.CreditType | Implicit FK | Classifies the cashflow event type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorId` (full two-result-set), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg` (summary), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCopy` (positions only).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows (procedure)
├── History.Credit (table - cross-schema)
└── History.Mirror (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | Cashflow events for the mirror session (money movement credit types) |
| History.Mirror | Table (cross-schema) | Mirror state change events (MirrorOperationID 12, 13) |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. No temp tables.

### 7.2 Constraints

None. Key behavioral characteristics:
- Single result set (cashflows only - no position data)
- No temp table - simpler than `TAPI_GetMirrorHistoryWithCIDAndMirrorId` (no #t staging)
- WITH (NOLOCK) on both History tables
- MirrorOperationID 27 for cashflow events is excluded from TotalCashflowItems in the Agg SP's count - but included in the list here (per CreditTypeID IN (18,19,20,21,27) filter)

---

## 8. Sample Queries

### 8.1 Get cashflow events for a mirror session

```sql
EXEC Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Get recent cashflows with date filter

```sql
EXEC Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = DATEADD(MONTH, -6, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.3 Preview cashflow events directly

```sql
SELECT
    CASE WHEN hc.CreditTypeID IN (19,21,27) THEN 1 ELSE 0 END AS IsMoneyOut,
    CASE hc.CreditTypeID WHEN 20 THEN 1 WHEN 21 THEN 2 WHEN 27 THEN 10 ELSE 3 END AS HistoryMirrorOperation,
    hc.Occurred,
    hc.Payment * -1 AS MirrorAmountDelta,
    CASE ISNULL(hc.MirrorDividendID, 0) WHEN 0 THEN 0 ELSE 1 END AS IsCopyDividend
FROM History.Credit hc WITH (NOLOCK)
WHERE hc.CID = 12345
    AND hc.MirrorID = 67890
    AND hc.CreditTypeID IN (18, 19, 20, 21, 27)
ORDER BY hc.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdFilterByCashflows.sql*
