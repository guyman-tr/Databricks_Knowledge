# Billing.GetCustomerCompensations

> Returns a customer's compensation credit history within a date range by unioning archived records from History.Credit and recent records from the in-memory History.ActiveCreditRecentMemoryBucket, ordered by occurrence date descending.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid + @fromDate + @toDate date-range filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerCompensations` retrieves all compensation credits (CreditTypeID=6) awarded to a customer within a specified date window. Compensations are discretionary credits applied by operations staff to remedy service issues - market disruptions, system errors, or other events that adversely affected the customer's account.

The procedure implements a **dual-source pattern** to handle the split between recent and archived credit data: recent records live in the in-memory table `History.ActiveCreditRecentMemoryBucket` (for low-latency reads), while older records are in the archived `History.Credit` table. Both sources are queried for the same CID and date range, inserted into a clustered temp table (#Result), and returned as a single merged result set ordered by date.

Data flow: Called by the Withdrawal service and Redeem service (likely when validating or displaying compensation history before or during a withdrawal/redeem request), and by BI admins for reporting. The result set is typically displayed to operations staff or included in customer account statements. Created 2021-01-03 by Shay Oren.

---

## 2. Business Logic

### 2.1 Dual-Source Read Pattern (Archive + In-Memory)

**What**: Compensations are stored in two tables depending on recency - the procedure merges both sources transparently.

**Columns/Parameters Involved**: `@cid`, `@fromDate`, `@toDate`, `History.Credit`, `History.ActiveCreditRecentMemoryBucket`

**Rules**:
- Source 1 - `History.Credit WITH (NOLOCK)`: archived credit records. Contains the bulk of historical compensation data. Queried with date range.
- Source 2 - `History.ActiveCreditRecentMemoryBucket`: in-memory optimized table for recent credits. Provides low-latency access to credits not yet archived. No NOLOCK hint (not applicable for memory-optimized tables).
- Both sources use `CreditTypeID = 6` (Compensation) filter and the same CID + date range.
- Result merging: both INSERTs write to #Result (temp table with clustered index on Occurred), then a single SELECT returns all rows ORDER BY Occurred DESC.
- If a record somehow exists in both sources, it would be duplicated - the procedure doesn't deduplicate. In practice, records should only exist in one source (archived OR recent).

**Diagram**:
```
                     @cid, @fromDate, @toDate, CreditTypeID=6
                        /                    \
          History.Credit              History.ActiveCreditRecentMemoryBucket
          (archived data)             (in-memory recent data)
                        \                    /
                         INSERT -> #Result
                              |
                         SELECT * ORDER BY Occurred DESC
```

### 2.2 Temp Table with Clustered Index for Merge Performance

**What**: A temp table with a clustered index on Occurred is used as the merge buffer before the final ordered output.

**Rules**:
- `CREATE TABLE #Result (Occurred, CompensationReasonID, Credit, Payment)`
- `CREATE CLUSTERED INDEX #IX_Res ON #Result(Occurred)`: ensures rows are physically ordered by date as they're inserted.
- The final `SELECT * FROM #Result ORDER BY Occurred DESC` returns all rows in reverse chronological order.
- This pattern is used instead of a UNION ALL with ORDER BY to handle the dual-source nature and allow each source to be inserted independently.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INTEGER | NO | - | CODE-BACKED | Customer ID whose compensation history to retrieve. Filters both History.Credit and History.ActiveCreditRecentMemoryBucket. |
| 2 | @fromDate | DATETIME | NO | - | CODE-BACKED | Start of date range (inclusive - BETWEEN @fromDate AND @toDate). Filters on History.Credit.Occurred / History.ActiveCreditRecentMemoryBucket.Occurred. |
| 3 | @toDate | DATETIME | NO | - | CODE-BACKED | End of date range (inclusive). Combined with @fromDate to define the compensation history window. |

**Returns** (SELECT output columns from #Result):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | Occurred | DATETIME | NO | CODE-BACKED | UTC timestamp when the compensation credit was applied to the customer's account. Used as the clustered index key in #Result - result is ordered by this column descending. |
| 2 | CompensationReasonID | INT | YES | CODE-BACKED | Reason code for the compensation. FK to BackOffice.CompensationReason. Identifies WHY the compensation was applied (e.g., market disruption, system error). NULL if no reason code was recorded. Use GetCreditsHistoryByDate for the human-readable name. |
| 3 | Credit | MONEY | YES | CODE-BACKED | Balance credit amount in USD applied to the customer's account for this compensation. Positive value = credit added. |
| 4 | Payment | MONEY | YES | CODE-BACKED | Payment amount in USD associated with this compensation event. May represent the monetary value of the compensation as recorded in the credit system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Occurred, CreditTypeID | History.Credit | Direct read | Source of archived compensation records (CreditTypeID=6) |
| CID, Occurred, CreditTypeID | History.ActiveCreditRecentMemoryBucket | Direct read | Source of recent in-memory compensation records (CreditTypeID=6) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawalServiceUser | EXECUTE grant | Permission | Withdrawal service checks compensation history during withdrawal processing |
| RedeemServiceUser | EXECUTE grant | Permission | Redeem service checks compensation history during redemption flow |
| PROD_BIadmins | EXECUTE grant | Permission | BI admin reporting access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerCompensations (procedure)
├── History.Credit (table - archive DB)
└── History.ActiveCreditRecentMemoryBucket (memory-optimized table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (archive) | INSERT INTO #Result - archived compensations WHERE CreditTypeID=6 in date range |
| History.ActiveCreditRecentMemoryBucket | Memory-optimized table | INSERT INTO #Result - recent in-memory compensations WHERE CreditTypeID=6 in date range |

### 6.2 Objects That Depend On This

No stored procedures found calling this procedure in the SSDT repo. Called directly by WithdrawalService and RedeemService applications.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| Temp table | #Result created per execution with clustered index on Occurred for merge sort |
| Dual-source pattern | Both History.Credit and History.ActiveCreditRecentMemoryBucket queried; results merged via temp table |

---

## 8. Sample Queries

### 8.1 Get compensation history for a customer in a date range

```sql
-- Returns all compensations for customer 1234567 in 2024
EXEC [Billing].[GetCustomerCompensations]
    @cid = 1234567,
    @fromDate = '2024-01-01',
    @toDate = '2024-12-31'
```

### 8.2 Check compensation reason codes

```sql
-- Look up what CompensationReasonIDs mean
SELECT CompensationReasonID, DisplayName
FROM [BackOffice].[CompensationReason] WITH (NOLOCK)
ORDER BY CompensationReasonID
```

### 8.3 Query archived compensations directly (same filter as SP source 1)

```sql
-- Direct query to History.Credit for compensations (archived source)
SELECT Occurred, CompensationReasonID, Credit, Payment
FROM [History].[Credit] WITH (NOLOCK)
WHERE CID = 1234567
  AND CreditTypeID = 6
  AND Occurred BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerCompensations | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerCompensations.sql*
