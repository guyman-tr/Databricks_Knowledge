# Billing.GetRecurringThreeDsDateByDepositIds

> Given a comma-separated list of DepositIDs, returns the RecurringDepositID, DepositID, and 3DS authentication date for each matched recurring deposit execution record.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @depositIds (CSV input); returns one row per matched RecurringDeposit row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRecurringThreeDsDateByDepositIds` is a batch lookup for 3DS authentication timestamps associated with recurring deposit executions. After a recurring charge is processed, the application may need to retrieve the 3DS date for a set of deposits - for example, to check whether 3DS authentication occurred within a required window, to populate a report, or to drive retry logic for deposits that missed 3DS.

The procedure exists because `Billing.RecurringDeposit` links recurring execution jobs to their resulting deposits and records the `3dsDate` at the moment the deposit outcome is written back by `SetDepositIdToRecurringDeposit`. Reading this date from a raw JOIN across `RecurringDeposit` requires handling the CSV-to-rows conversion - this procedure encapsulates that parsing.

Data flow: the application builds a comma-separated list of DepositIDs it wants to look up, calls this procedure, and receives back the `3dsDate` for each ID. The `3dsDate` is NULL for recurring deposits that did not go through 3DS authentication. The procedure is read-only and uses `NOLOCK` for throughput.

---

## 2. Business Logic

### 2.1 CSV Parsing with Safe Integer Conversion

**What**: The input is a raw CSV string; the procedure defensively parses it into a keyed temp table before joining to avoid errors from non-integer values.

**Columns/Parameters Involved**: `@depositIds`, `#ids.DepositID`

**Rules**:
- `STRING_SPLIT(@depositIds, ',')` splits the CSV into individual values
- `TRY_CONVERT(INT, value)` converts each token to INT; returns NULL for non-numeric tokens (empty strings, stray commas, garbage data)
- `WHERE TRY_CONVERT(INT, value) IS NOT NULL` discards failed conversions - the procedure silently ignores invalid tokens rather than raising an error
- `DISTINCT` eliminates duplicate DepositIDs - safe to call with overlapping sets without producing duplicate result rows
- The temp table `#ids` is created with a PRIMARY KEY CLUSTERED on DepositID, giving it an index for the INNER JOIN

**Diagram**:
```
@depositIds = '101,202,303,abc,101'
   |
   v
STRING_SPLIT -> ['101','202','303','abc','101']
   |
   v
TRY_CONVERT + IS NOT NULL filter -> [101, 202, 303, 101]
   |
   v
DISTINCT -> [101, 202, 303]
   |
   v
INSERT INTO #ids -> clustered PK on DepositID
   |
   v
INNER JOIN RecurringDeposit ON DepositID -> returns 3dsDate per match
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @depositIds | NVARCHAR(MAX) | NO | - | CODE-BACKED | Comma-separated list of DepositID integer values to look up. Example: `'12345,12346,12347'`. Non-numeric tokens and duplicates are silently discarded via `TRY_CONVERT` and `DISTINCT`. Maps to `Billing.RecurringDeposit.DepositID`. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | RecurringDepositID | INT | NO | - | CODE-BACKED | Primary key of the `Billing.RecurringDeposit` row that links the recurring execution job to this deposit. Allows the caller to reference the full recurring execution record if needed. |
| 3 | DepositID | INT | YES | - | CODE-BACKED | The deposit record identifier from `Billing.Deposit`. Echoed back from the input so the caller can correlate results to its input list without re-joining. NULL in RecurringDeposit until `SetDepositIdToRecurringDeposit` runs; only non-NULL DepositIDs can match the INNER JOIN in this procedure. |
| 4 | 3dsDate | DATETIME2 | YES | - | CODE-BACKED | The datetime when 3DS authentication was performed for this recurring deposit execution. Set by `Billing.SetDepositIdToRecurringDeposit` when the payment processor returns a 3DS result. NULL = the recurring charge did not involve 3DS authentication. The caller uses this date to verify 3DS recency or to filter which charges require a 3DS retry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @depositIds values | Billing.RecurringDeposit | INNER JOIN on DepositID | Retrieves 3dsDate and RecurringDepositID for each matched recurring execution |
| RecurringDeposit.DepositID | Billing.Deposit | Implicit | DepositID in RecurringDeposit is a FK to Billing.Deposit; this procedure surfaces it as output |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application (recurring deposit service) | @depositIds | EXEC | Called by the application after processing a batch of recurring charges to retrieve 3DS dates for post-processing or retry logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRecurringThreeDsDateByDepositIds (procedure)
└── Billing.RecurringDeposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RecurringDeposit | Table | INNER JOIN on DepositID; reads RecurringDepositID and 3dsDate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application recurring deposit service | External | Calls this procedure to retrieve 3DS authentication dates for a batch of deposit IDs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Safe CSV parsing | Business rule | `TRY_CONVERT(INT, value) IS NOT NULL` silently drops non-integer tokens; callers can safely pass malformed input without causing errors |
| Deduplication | Business rule | `DISTINCT` on DepositID prevents duplicate rows in result when the input CSV contains the same ID multiple times |
| INNER JOIN on DepositID | Business rule | Only recurring deposit rows where `DepositID` has been set are returned; executions not yet linked to a deposit (DepositID = NULL) do not appear |

---

## 8. Sample Queries

### 8.1 Retrieve 3DS dates for a specific set of deposits
```sql
EXEC Billing.GetRecurringThreeDsDateByDepositIds
    @depositIds = N'5001234,5001235,5001236';
```

### 8.2 Find recurring deposits with 3DS date in the last 7 days
```sql
SELECT rd.RecurringDepositID, rd.DepositID, rd.[3dsDate]
FROM Billing.RecurringDeposit rd WITH (NOLOCK)
WHERE rd.DepositID IS NOT NULL
  AND rd.[3dsDate] >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY rd.[3dsDate] DESC;
```

### 8.3 Inspect full recurring deposit record alongside 3DS date
```sql
SELECT
    rd.RecurringDepositID,
    rd.DepositID,
    rd.[3dsDate],
    rd.ExecutionID,
    rd.ExecutionKey,
    rd.Generation,
    rd.CreateDate
FROM Billing.RecurringDeposit rd WITH (NOLOCK)
WHERE rd.DepositID IN (5001234, 5001235, 5001236);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRecurringThreeDsDateByDepositIds | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRecurringThreeDsDateByDepositIds.sql*
