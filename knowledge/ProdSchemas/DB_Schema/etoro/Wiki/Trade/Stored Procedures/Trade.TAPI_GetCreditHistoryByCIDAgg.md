# Trade.TAPI_GetCreditHistoryByCIDAgg

> Trading API procedure that returns aggregated credit totals (total amount and count) per credit type for a customer - the summary counterpart to Trade.TAPI_GetCreditHistoryByCID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TAPI (Trading API) procedure is the aggregation companion to `Trade.TAPI_GetCreditHistoryByCID`. While that procedure returns individual paginated credit events, this one returns summary totals (total amount and count) per credit type for the same customer and time range. It powers summary views such as "Total Deposited: $X" and "Total Withdrawn: $Y" shown at the top of the portfolio history section.

The procedure sources from `History.Credit` (the full archived history) rather than `History.ActiveCredit` (which holds only recent/active records). This makes the aggregation complete - capturing all historical transactions, not just recent ones. It also includes `CreditTypeID = 15` (Cashout Fee) which is excluded from the individual list procedure, providing a complete financial summary.

The procedure is called by the TDAPIUser (Trading Data API service account) that serves the customer-facing trading platform.

---

## 2. Business Logic

### 2.1 CreditType Aggregation Scope

**What**: Same money-movement filter as TAPI_GetCreditHistoryByCID plus Cashout Fee.

**Columns/Parameters Involved**: `CreditTypeID`

**Rules**:
- Included credit types (from Dictionary.CreditType):
  - 1 = Deposit
  - 2 = Cashout
  - 5 = Champ Winner
  - 6 = Compensation
  - 7 = Bonus
  - 8 = Reverse cashout
  - 9 = Cashout request
  - 11 = Chargeback
  - 12 = Refund
  - 15 = Cashout Fee (included here but NOT in TAPI_GetCreditHistoryByCID individual list)
  - 16 = Refund As ChargeBack
  - 17 = FixHistoryCreditChargeBacks
- Returns one aggregate row per credit type (GROUP BY CreditTypeID).
- ISNULL(..., 0) ensures zero values are returned rather than NULLs for types with no data.

### 2.2 History.Credit vs History.ActiveCredit

**What**: Uses the full history archive rather than the active/recent credit table.

**Rules**:
- `History.Credit`: Full historical archive of all credit events for all customers. Includes events that have been moved out of History.ActiveCredit.
- `History.ActiveCredit`: Contains recent/active credit records. Used by the individual-record procedure.
- For aggregation totals (lifetime sums), the full history is required. Using ActiveCredit would under-count for customers with long histories.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All aggregation is scoped to this single customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start time filter. When provided, aggregates only credit events with Occurred >= @startTime. When NULL, aggregates all history. |

### Output Columns (Result Set - one row per CreditTypeID)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditTypeID | INT | NO | - | VERIFIED | Credit event category: 1=Deposit, 2=Cashout, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 11=Chargeback, 12=Refund, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks. (Dictionary.CreditType) |
| 2 | Payment | MONEY | NO | - | CODE-BACKED | Total dollar amount for this credit type: SUM(Payment) with ISNULL default 0. Positive = net credit, negative = net debit. Represents the lifetime total (or total since @startTime) for this credit category. |
| 3 | Total | INT | NO | - | CODE-BACKED | Total number of credit events for this type: COUNT(1) with ISNULL default 0. Represents how many individual transactions make up the Payment total. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | History.Credit | Lookup (READ) | Full historical credit archive; aggregated by CreditTypeID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser (Trading Data API service account).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetCreditHistoryByCIDAgg (procedure)
└── History.Credit (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | Aggregation source for full historical credit data |

### 6.2 Objects That Depend On This

No SQL dependents found. Called by TDAPIUser (Trading Data API service account). See also `Trade.TAPI_GetCreditHistoryByCID` for the individual-record companion procedure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get lifetime credit summary for a customer

```sql
EXEC Trade.TAPI_GetCreditHistoryByCIDAgg
    @cid = 12345,
    @startTime = NULL
```

### 8.2 Get credit summary since start of year

```sql
EXEC Trade.TAPI_GetCreditHistoryByCIDAgg
    @cid = 12345,
    @startTime = '2026-01-01'
```

### 8.3 Preview aggregated credit totals with type names directly

```sql
SELECT
    hc.CreditTypeID,
    RTRIM(ct.Name) AS CreditTypeName,
    ISNULL(SUM(hc.Payment), 0) AS TotalPayment,
    ISNULL(COUNT(1), 0) AS EventCount
FROM History.Credit hc WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ct.CreditTypeID = hc.CreditTypeID
WHERE hc.CID = 12345
    AND hc.CreditTypeID IN (1, 2, 5, 6, 7, 8, 9, 11, 12, 15, 16, 17)
GROUP BY hc.CreditTypeID, ct.Name
ORDER BY hc.CreditTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetCreditHistoryByCIDAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetCreditHistoryByCIDAgg.sql*
