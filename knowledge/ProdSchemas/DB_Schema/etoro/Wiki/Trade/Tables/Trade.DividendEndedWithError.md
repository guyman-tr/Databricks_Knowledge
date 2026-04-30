# Trade.DividendEndedWithError

> Error log table that records dividend payment operations that failed during processing, including position, customer, mirror, and fee context for retry or manual resolution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY), CIX on (CurrentDate, DividendID, PositionID) |
| **Partition** | No |
| **Indexes** | 2 |

---

## 1. Business Meaning

**WHAT**: Trade.DividendEndedWithError is an error-log table that captures dividend payment attempts that failed during the index dividend process. Each row represents a dividend payment that could not be completed—either due to balance adjustment failure, transaction rollback, or other exceptions in the dividend payment pipeline. The table stores the DividendID, PositionID, CID, MirrorID, ParentPositionID, FeeInDollars, and CurrentDate to allow operators to retry or manually reconcile failed payments.

**WHY**: When Trade.GetCIDsForIndexDividends_New processes dividends, it calculates fees per position and attempts to credit customer accounts. If a payment fails (e.g., in a CATCH block after ROLLBACK), the system needs a durable record of what failed so that: (1) operators can investigate and retry, (2) audit trails exist for compliance, and (3) failed positions are not silently dropped. Without this table, failed dividend payments would be lost. MirrorID links to Trade.Mirror for copy-trade attribution when dividends fail on copier positions.

**HOW**: Trade.GetCIDsForIndexDividends_New inserts into DividendEndedWithError in its CATCH block after a rollback: it copies rows from the in-memory #CIDsToCharge temp table that were supposed to be charged but failed. Monitor.Dividends_Unpaid reads recent rows (CurrentDate > Convert(Date, GetUTCDate())) to surface unpaid dividends for monitoring. The clustered index on (CurrentDate, DividendID, PositionID) supports time-based and dividend-based lookups.

---

## 2. Business Logic

### 2.1 Failed Dividend Payment Capture

**What**: When the dividend payment procedure encounters an error and rolls back, it persists the intended payment records into DividendEndedWithError before exiting.

**Columns/Parameters Involved**: DividendID, PositionID, CID, MirrorID, ParentPositionID, FeeInDollars, CurrentDate

**Rules**:
- INSERT occurs in the CATCH block of Trade.GetCIDsForIndexDividends_New
- All rows from #CIDsToCharge (which contains calculated FeeInDollars, CID, MirrorID, ParentPositionID) are inserted
- CurrentDate is set to GETDATE() at insert time
- No explicit cleanup—rows remain for monitoring and manual resolution

### 2.2 Mirror and Copy-Trade Context

**What**: MirrorID and ParentPositionID provide copy-trading context for failed dividend payments.

**Columns/Parameters Involved**: MirrorID, ParentPositionID, CID

**Rules**:
- MirrorID links to Trade.Mirror—identifies which copy relationship the position belongs to
- ParentPositionID > 0 indicates a copier position; ParentPositionID = 0 indicates a leader position
- When dividend fails on a copier, both MirrorID and ParentPositionID are stored for traceability to the leader position

### 2.3 Unpaid Dividend Monitoring

**What**: Monitor.Dividends_Unpaid selects recent rows for operational visibility.

**Columns/Parameters Involved**: CurrentDate, DividendID, PositionID

**Rules**:
- Query: `SELECT TOP 300 * FROM Trade.DividendEndedWithError WITH (NOLOCK) WHERE CurrentDate > Convert(Date, GetUTCDate())`
- Used to identify today's unpaid dividend attempts for follow-up

---

## 3. Data Overview

| ID | DividendID | PositionID | CID | MirrorID | ParentPositionID | FeeInDollars | CurrentDate | Meaning |
|----|------------|------------|-----|----------|------------------|--------------|-------------|---------|
| (Sample) | 1234 | 987654321 | 100001 | 500 | NULL | -12.50 | 2026-03-14 10:00 | Leader position dividend payment failed; -12.50 fee not credited. |
| (Sample) | 1234 | 987654322 | 200002 | 501 | 987654321 | -6.25 | 2026-03-14 10:00 | Copier position dividend failed; links to parent 987654321 via MirrorID 501. |

**Note**: Live data sample returned empty from MCP (no recent failures). Sample rows above illustrate typical structure. When failures occur, rows are inserted in bulk from #CIDsToCharge.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY | CODE-BACKED | Surrogate key. Auto-incremented on INSERT. Used for ordering. |
| 2 | DividendID | int | YES | - | CODE-BACKED | FK to Trade.IndexDividends (implicit). Identifies which dividend payment failed. Populated from #CIDsToCharge.DividendID. |
| 3 | PositionID | bigint | YES | - | CODE-BACKED | FK to Trade.Position (implicit). The position for which the dividend payment failed. |
| 4 | CID | int | YES | - | CODE-BACKED | Customer ID. The customer who was supposed to receive (or be charged) the dividend. Implicit FK to Customer.Customer. |
| 5 | MirrorID | int | YES | - | CODE-BACKED | FK to Trade.Mirror (implicit). Copy-trade mirror when position is a copier. NULL for leader positions. Links failed copier dividend to mirror relationship. |
| 6 | ParentPositionID | bigint | YES | - | CODE-BACKED | Leader position ID when this is a copier position. NULL for leader positions. Used for traceability. |
| 7 | FeeInDollars | decimal(18,6) | YES | - | CODE-BACKED | The calculated dividend amount (as fee) in USD that failed to be applied. Negative for dividends (credit to customer). |
| 8 | CurrentDate | datetime | YES | - | CODE-BACKED | When the failure was recorded. Set to GETDATE() at INSERT. Supports time-based queries and Monitor.Dividends_Unpaid. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| DividendID | Trade.IndexDividends | Implicit | The dividend that was being paid |
| PositionID | Trade.Position | Implicit | The position that was to receive the dividend |
| CID | Customer.Customer | Implicit | The customer for whom payment failed |
| MirrorID | Trade.Mirror | Implicit | Copy-trade mirror when position is a copier |
| ParentPositionID | Trade.Position | Implicit | Leader position when this is a copier |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCIDsForIndexDividends_New | INSERT | Writer | Inserts failed payment records in CATCH block |
| Monitor.Dividends_Unpaid | SELECT | Reader | Selects recent unpaid dividends for monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DividendEndedWithError (table)
├── Trade.IndexDividends (implicit via DividendID)
├── Trade.Position (implicit via PositionID, ParentPositionID)
├── Trade.Mirror (implicit via MirrorID)
└── Customer.Customer (implicit via CID)
```

### 6.1 Objects This Depends On

No explicit FKs. Implicit: Trade.IndexDividends, Trade.Position, Trade.Mirror, Customer.Customer.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCIDsForIndexDividends_New | Procedure | INSERT in CATCH block |
| Monitor.Dividends_Unpaid | Procedure | SELECT for unpaid monitoring |
| tradonomi (GetCIDsForIndexDividends_New) | External | Runs dividend process |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX | CLUSTERED | CurrentDate, DividendID, PositionID | - | - | Active |
| IX | NC | DividendID, PositionID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none explicit) | - | Table has IDENTITY on ID; no CHECK or FK constraints in DDL |

---

## 8. Sample Queries

### 8.1 Unpaid dividends from today (monitoring)
```sql
SELECT TOP 300
       DEWE.ID, DEWE.DividendID, DEWE.PositionID, DEWE.CID, DEWE.MirrorID,
       DEWE.ParentPositionID, DEWE.FeeInDollars, DEWE.CurrentDate
  FROM Trade.DividendEndedWithError DEWE WITH (NOLOCK)
 WHERE DEWE.CurrentDate > CONVERT(DATE, GETUTCDATE())
 ORDER BY DEWE.CurrentDate DESC
```

### 8.2 Failed dividends for a specific dividend with mirror context
```sql
SELECT DEWE.DividendID, DEWE.PositionID, DEWE.CID, M.ParentCID, DEWE.FeeInDollars
  FROM Trade.DividendEndedWithError DEWE WITH (NOLOCK)
  LEFT JOIN Trade.Mirror M WITH (NOLOCK) ON DEWE.MirrorID = M.MirrorID
 WHERE DEWE.DividendID = 1234
 ORDER BY DEWE.PositionID
```

### 8.3 Count of failed payments per dividend
```sql
SELECT DEWE.DividendID,
       COUNT(*) AS FailedPaymentCount,
       SUM(DEWE.FeeInDollars) AS TotalFailedFee
  FROM Trade.DividendEndedWithError DEWE WITH (NOLOCK)
 WHERE DEWE.CurrentDate >= DATEADD(DAY, -7, GETUTCDATE())
 GROUP BY DEWE.DividendID
 ORDER BY FailedPaymentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | Object: Trade.DividendEndedWithError | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.DividendEndedWithError.sql*
