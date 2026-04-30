# Trade.TDAPI_GetLeaderCashFlows

> Returns a Popular Investor's performance fee payment history: a summary row (total count and amount in the look-back window) and a paginated, sortable list of individual fee payments, sourced from History.Credit with CreditTypeID=6 and CompensationReasonID in (41,50).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT (PI performance fee cashflows, two result sets, paginated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the "Cash Flows" section of a Popular Investor's profile dashboard in the Trading Data API. It shows the PI's history of receiving performance fees - the payments eToro makes to Popular Investors for being copied.

When a copier closes a position with profit, a portion of that profit is paid to the Popular Investor as a performance fee. These payments appear in `History.Credit` as CreditTypeID=6 with CompensationReasonID=41 (standard PI fee) or 50 (another PI compensation type). This procedure retrieves and paginates those payments.

The procedure returns two result sets:
1. **RS1 (header)**: Total count and total amount of payments within the look-back window - used to render the summary header and calculate page count
2. **RS2 (detail)**: Individual paginated and sortable payment rows - returned only if RS1 count > 0

This early-exit pattern (skip RS2 entirely when no payments exist) is a performance optimization common in the TDAPI procedures.

---

## 2. Business Logic

### 2.1 Time Window and 1-Year Cap

**What**: Establishes the look-back window for fee payments.

**Columns/Parameters Involved**: `@StartDate`, `@OneYearBackDate`

**Rules**:
- `@OneYearBackDate = CAST(DATEADD(year,-1,GETUTCDATE()) AS DATE)`
- `@StartDate = ISNULL(@StartDate, @OneYearBackDate)` - defaults to 1 year ago
- Both @StartDate AND @OneYearBackDate apply: `Occurred >= @StartDate AND Occurred >= @OneYearBackDate`
- The dual condition means: even if @StartDate < 1 year ago, only the last year is returned (the 1-year cap is always enforced)

### 2.2 Result Set 1 - Summary Header (Always Returned)

**What**: Counts and sums payments for the look-back window.

**Columns/Parameters Involved**: `CreditTypeID`, `CompensationReasonID`, `Payment`

**Rules**:
- Source: `History.Credit WHERE CreditTypeID=6 AND CompensationReasonID IN (41,50) AND CID=@CID`
- `@TotalPaymnetsCount` = total ever (no time filter) - used for PaymentNumber calculation
- `@TotalPaymnetsCountInTimeSpan` = count within @StartDate window - used in RS1 and early-exit check
- `@TotalPaymnetsAmountInTimeSpan` = SUM(Payment) within @StartDate window
- RS1 output: `TotalPaymnetsCount` (in time span), `TotalPaymnetsAmount` (in time span)
- Note: "Payments" is misspelled as "Paymnets" in the procedure - the output column names retain this spelling

### 2.3 Early Exit When No Payments

**What**: Skips RS2 entirely when there are no payments in the time window.

**Rules**:
- `IF @TotalPaymnetsCountInTimeSpan = 0 RETURN` - only RS1 is returned; RS2 is not produced
- Callers must check RS1 before attempting to read RS2

### 2.4 Result Set 2 - Payment Detail with Sequential Numbering

**What**: Paginated list of individual performance fee payments with a sequential payment number.

**Columns/Parameters Involved**: `@OrderColumn`, `@OrderbyDesc`, `@PageNumber`, `@ItemsPerPage`

**Rules**:
- PaymentNumber: `@TotalPaymnetsCount + 1 - ROW_NUMBER() OVER (ORDER BY Occurred DESC)` - reverse sequential numbering (most recent = PaymentNumber 1, oldest = PaymentNumber N). Uses @TotalPaymnetsCount (all-time total, not time-span) so numbering is consistent even when filtered by @StartDate
- Dynamic sort: `@OrderColumn` = 1 (PaymentNumber), 2 (Amount), 3 (PaymentDate); `@OrderbyDesc` = 1 (DESC), 0 (ASC). Default: PaymentDate DESC (column 3, desc 1)
- Pagination: OFFSET/FETCH on the dynamic sort
- CreditID added as secondary sort key for deterministic ordering

```
CreditTypeID=6 AND CompensationReasonID IN (41,50)
     |
     v
RS1: TotalPaymnetsCount + TotalPaymnetsAmount (in window)
     |
     |-- Count = 0 --> RETURN (RS2 not produced)
     |-- Count > 0 --> RS2: paged list of individual payments
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The Popular Investor's customer ID. All cash flow data is for this CID. |
| 2 | @StartDate | DATE | YES | 1 year ago | CODE-BACKED | Look-back window start. Defaults to 1 year ago. A hard 1-year cap is always enforced regardless of @StartDate value. |
| 3 | @OrderbyDesc | BIT | YES | 1 | CODE-BACKED | Sort direction: 1=DESC (default), 0=ASC. Applied to the column specified by @OrderColumn. |
| 4 | @OrderColumn | INT | YES | 3 | CODE-BACKED | Column to sort by: 1=PaymentNumber, 2=Amount, 3=PaymentDate (default). |
| 5 | @PageNumber | INT | YES | 1 | CODE-BACKED | 1-based page number for RS2. OFFSET = @ItemsPerPage * (@PageNumber - 1). |
| 6 | @ItemsPerPage | INT | YES | 3 | CODE-BACKED | Page size for RS2. Default 3 (small default - suitable for a dashboard widget showing recent payments). |

### Output - Result Set 1 (Summary Header)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TotalPaymnetsCount | INT | NO | 0 | CODE-BACKED | Count of performance fee payments within the look-back window (note: "Paymnets" spelling in output column name is as-is in the procedure). 0 if no payments exist. |
| 2 | TotalPaymnetsAmount | MONEY | NO | 0 | CODE-BACKED | Total amount of performance fees received within the look-back window. 0 if no payments. Always returned, even when RS2 is empty. |

### Output - Result Set 2 (Individual Payment Detail - only when RS1 count > 0)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentNumber | INT | NO | - | CODE-BACKED | Sequential payment number: @TotalPaymnetsCount + 1 - ROW_NUMBER(). Most recent payment = 1, oldest = N. Consistent all-time numbering even when time-filtered. |
| 2 | Amount | MONEY | NO | 0 | CODE-BACKED | ISNULL(Payment, 0). Performance fee amount for this payment (always positive for PI income). |
| 3 | PaymentDate | DATETIME | NO | - | CODE-BACKED | History.Credit.Occurred for this credit. Date/time the fee was credited to the PI's account. Default sort: DESC (most recent first). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CreditTypeID, CompensationReasonID, Payment, Occurred | History.Credit | Lookup (READ) | Source of all performance fee payments. Filtered to CreditTypeID=6 (performance fee) AND CompensationReasonID IN (41,50). |
| CompensationReasonID | Dictionary.CompensationReason | Lookup | 41 and 50 are PI performance fee compensation reason codes. FK to compensation reason dictionary. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account - serves the Popular Investor cash flows dashboard widget.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderCashFlows (procedure)
└── History.Credit (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | Source of all PI performance fee credit records. Filtered to CreditTypeID=6, CompensationReasonID IN (41,50). |

### 6.2 Objects That Depend On This

No dependents found from procedure search.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get a PI's recent performance fee payments (last year, latest 3)
```sql
EXEC Trade.TDAPI_GetLeaderCashFlows
    @CID = 55555,
    @StartDate = NULL,
    @OrderbyDesc = 1,
    @OrderColumn = 3,
    @PageNumber = 1,
    @ItemsPerPage = 3
-- RS1: summary; RS2: 3 most recent payments
```

### 8.2 Sort by payment amount descending (largest fees first)
```sql
EXEC Trade.TDAPI_GetLeaderCashFlows
    @CID = 55555,
    @StartDate = '2024-01-01',
    @OrderbyDesc = 1,
    @OrderColumn = 2,
    @PageNumber = 1,
    @ItemsPerPage = 10
```

### 8.3 Query PI performance fee history directly
```sql
SELECT hc.CreditID, hc.CID, hc.Payment, hc.Occurred, hc.CompensationReasonID
FROM History.Credit hc WITH (NOLOCK)
WHERE hc.CID = 55555
    AND hc.CreditTypeID = 6
    AND hc.CompensationReasonID IN (41, 50)
    AND hc.Occurred >= DATEADD(year, -1, GETUTCDATE())
ORDER BY hc.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderCashFlows | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderCashFlows.sql*
