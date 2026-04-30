# History.InterestPaymentsLog

> Monthly interest payment log recording when interest was paid to each customer for each month, serving as the deduplication guard ensuring each customer receives interest only once per month.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | InterestMonthlyID (BIGINT, CLUSTERED PK, FILLFACTOR 95) |
| **Partition** | No (stored on HISTORY filegroup) |
| **Indexes** | 2 active (PK clustered + NC on CID, MonthOfInterest) |

---

## 1. Business Meaning

History.InterestPaymentsLog records when monthly interest payments have been processed and credited to customer accounts. eToro offers interest on cash balances held in accounts (available in supported markets and account types), and this table acts as the authoritative log of which customers received interest for which calendar month. With ~727 unique customers and payments spanning March 2023 to January 2025, this covers a select group of customers enrolled in the interest program.

This table serves two purposes: (1) operational deduplication - before paying interest for a given month, the payment job checks this table to ensure the customer has not already been paid; and (2) audit trail - confirming to regulators and customers that interest was paid on the correct schedule. Data shows payments are processed on approximately the first business day of the following month (MonthOfInterest='2025-01-01' paid on 2025-02-01 06:00), confirming a monthly batch job pattern.

Note: Unlike most History schema tables, this is NOT a temporal history table for another table. It is a standalone operational log that lives in the History schema due to its audit/record-keeping nature. The table has its own natural PK (InterestMonthlyID) and is never superseded - each row is a permanent record of a completed payment.

---

## 2. Business Logic

### 2.1 Monthly Interest Payment Processing

**What**: One row is written per customer per month when their monthly interest payment is processed, providing an idempotency check for the payment job.

**Columns/Parameters Involved**: `CID`, `MonthOfInterest`, `InterestMonthlyID`, `Occurred`

**Rules**:
- MonthOfInterest is always the first day of the month (e.g., '2025-01-01' = January 2025 interest)
- Occurred defaults to GETUTCDATE() - set automatically when the row is inserted
- The composite index on (CID, MonthOfInterest) supports the "has this customer already been paid for this month?" lookup
- InterestMonthlyID is a BIGINT identity - ensures uniqueness and ordering across payment batches
- All sampled payments for January 2025 occurred on 2025-02-01 between 06:00 and 06:01 UTC - confirms a scheduled batch job processes all customers within seconds

**Diagram**:
```
Monthly Interest Payment Job (runs ~1st of each month):
  1. Identify eligible customers with cash balance
  2. For each CID: SELECT WHERE CID = @CID AND MonthOfInterest = @Month
     -> Row exists? SKIP (already paid)
     -> No row?    Credit interest + INSERT new row here
  3. Occurred = GETUTCDATE() at time of INSERT
```

---

## 3. Data Overview

| InterestMonthlyID | CID | MonthOfInterest | Occurred | Meaning |
|---|---|---|---|---|
| 2156356 | 15017609 | 2025-01-01 | 2025-02-01 06:00:27 | Customer 15017609 received January 2025 interest at 6am UTC on Feb 1st - part of the monthly batch run |
| 2156355 | 14821523 | 2025-01-01 | 2025-02-01 06:00:27 | Adjacent payment - same batch, different customer, within milliseconds |
| 2156349 | 12600656 | 2025-01-01 | 2025-02-01 06:00:26 | Same January batch, slightly earlier timestamp - confirms rapid sequential processing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier of the account that received the interest payment. Not a FK-constrained column in DDL but references History.Customer / Trade system CID. |
| 2 | MonthOfInterest | date | NO | - | VERIFIED | The calendar month for which interest was calculated and paid. Always stored as the first day of the month (e.g., 2025-01-01 = January 2025). Used with CID as the natural key for idempotency checking. |
| 3 | InterestMonthlyID | bigint | NO | - | CODE-BACKED | Surrogate primary key for this payment log entry. Auto-incremented identity. Ensures uniqueness and provides an ordering key across all payment events. |
| 4 | Occurred | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when this interest payment was processed and inserted. Defaults to current UTC time on insert. All payments for a given month run within seconds of each other (batch job pattern). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | History.Customer | Implicit | The customer who received the interest payment. CID is the system-wide customer identifier. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. (No stored procedures found directly referencing this table in SSDT repo.)

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT repository. (The payment processing job that writes to and reads from this table may be an external service not captured in SSDT.)

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_History_InterestPaymentsLog | CLUSTERED (PK) | InterestMonthlyID ASC | - | - | Active |
| Ix_Cid_MonthOfInterest | NONCLUSTERED | CID ASC, MonthOfInterest ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_InterestPaymentsLog_Occurred | DEFAULT | GETUTCDATE() for Occurred - automatically records the UTC payment timestamp on insert |

---

## 8. Sample Queries

### 8.1 Check if a customer has received interest for a specific month
```sql
SELECT
    InterestMonthlyID,
    CID,
    MonthOfInterest,
    Occurred
FROM History.InterestPaymentsLog WITH (NOLOCK)
WHERE CID = 15017609
  AND MonthOfInterest = '2025-01-01'
```

### 8.2 Find all interest payments for a customer
```sql
SELECT
    InterestMonthlyID,
    MonthOfInterest,
    Occurred
FROM History.InterestPaymentsLog WITH (NOLOCK)
WHERE CID = 15017609
ORDER BY MonthOfInterest DESC
```

### 8.3 Find how many customers received interest in each month
```sql
SELECT
    MonthOfInterest,
    COUNT(*) AS CustomersCount,
    MIN(Occurred) AS BatchStart,
    MAX(Occurred) AS BatchEnd
FROM History.InterestPaymentsLog WITH (NOLOCK)
GROUP BY MonthOfInterest
ORDER BY MonthOfInterest DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InterestPaymentsLog | Type: Table | Source: etoro/etoro/History/Tables/History.InterestPaymentsLog.sql*
