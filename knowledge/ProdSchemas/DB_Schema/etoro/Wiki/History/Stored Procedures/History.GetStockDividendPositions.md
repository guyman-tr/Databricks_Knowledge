# History.GetStockDividendPositions

> Returns customer IDs and usernames for positions opened via stock dividend within a configurable lookback period, used for dividend processing audit and reporting.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LookbackMonths - defines the reporting window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.GetStockDividendPositions` identifies positions that were created as a result of stock dividend corporate actions. The platform models stock dividends as position open events with a specific action type (OpenActionType = 4 = Stock dividend). This procedure queries `Trade.AdminPositionLog` filtered to OpenActionType=4, JOINed with `Customer.Customer` to resolve customer names, and returns only positions executed within the configured lookback window.

The procedure exists to support dividend processing workflows, compliance audits, and corporate action reporting. It answers the question: "Which customers received stock dividend positions in the past N months?" The result set can be used to validate dividend distributions, investigate discrepancies, or generate reports for regulatory filings.

Data is sourced from `Trade.AdminPositionLog`, which records admin-driven position events (including dividend distributions). The JOIN to `Customer.Customer` enriches each record with the customer's username. ExecutionOccurred is aliased as DividendDate to emphasize the business context.

---

## 2. Business Logic

### 2.1 Stock Dividend Position Filter

**What**: Isolates position events that represent stock dividend distributions using the OpenActionType discriminator.

**Columns/Parameters Involved**: `apl.OpenActionType`, `@LookbackMonths`, `@StartDate`, `apl.ExecutionOccurred`

**Rules**:
- `OpenActionType = 4` identifies stock dividend positions (inline code comment: "Stock dividend")
- `@LookbackMonths` (default 24) defines how far back to look - @StartDate = DATEADD(MONTH, -@LookbackMonths, GETDATE())
- Filter: `apl.ExecutionOccurred >= @StartDate` - only dividend positions executed within the window
- No end date cap - includes positions from @StartDate through the current moment
- INNER JOIN to Customer.Customer ensures only rows with a valid customer record are returned

**Diagram**:
```
@LookbackMonths (default 24)
      |
      v
@StartDate = DATEADD(MONTH, -24, GETDATE())
      |
      v
Trade.AdminPositionLog (OpenActionType = 4, ExecutionOccurred >= @StartDate)
      |-- INNER JOIN Customer.Customer ON apl.CID = c.CID
      |
      v
Returns: CID, UserName, ID (Customer.ID), DividendDate
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LookbackMonths | INT | YES | 24 | CODE-BACKED | Number of months to look back from today. Determines the @StartDate cutoff: DATEADD(MONTH, -@LookbackMonths, GETDATE()). Default of 24 months covers two years of dividend history. Pass a smaller value for recent activity or larger for extended history. |

**Output columns** (returned by SELECT):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID from Trade.AdminPositionLog. The eToro customer who received the stock dividend position. Used as the primary identifier for dividend recipients. |
| 2 | UserName | VARCHAR | YES | - | CODE-BACKED | The customer's username from Customer.Customer. Provided for human-readable identification in reports and audit outputs. |
| 3 | ID | INT | NO | - | CODE-BACKED | Customer.Customer.ID - the internal customer record ID (distinct from CID). Included to support joins with other Customer schema objects that use ID rather than CID. |
| 4 | DividendDate | DATETIME | NO | - | CODE-BACKED | The execution timestamp of the dividend position, aliased from Trade.AdminPositionLog.ExecutionOccurred. Represents when the stock dividend was credited to the customer's account. Used as the date range filter (@StartDate cutoff). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.AdminPositionLog | Reads (filtered) | SELECT with OpenActionType=4 and ExecutionOccurred date filter |
| CID | Customer.Customer | Reads (JOIN) | INNER JOIN to resolve username and customer ID |

### 5.2 Referenced By (other objects point to this)

No callers found in the etoro SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetStockDividendPositions (procedure)
├── Trade.AdminPositionLog (table)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | SELECT - filtered by OpenActionType=4 and ExecutionOccurred >= @StartDate |
| Customer.Customer | Table | INNER JOIN on CID - provides UserName and ID |

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Note: `SET NOCOUNT ON` applied. Both source tables queried WITH (NOLOCK).

---

## 8. Sample Queries

### 8.1 Get stock dividend positions for the default 24-month window

```sql
EXEC History.GetStockDividendPositions
```

### 8.2 Get stock dividend positions for the last 6 months

```sql
EXEC History.GetStockDividendPositions @LookbackMonths = 6
```

### 8.3 Direct query to find dividend positions with additional instrument detail

```sql
SELECT
    apl.CID,
    c.UserName,
    c.ID,
    apl.ExecutionOccurred AS DividendDate,
    apl.InstrumentID
FROM Trade.AdminPositionLog apl WITH (NOLOCK)
INNER JOIN Customer.Customer c WITH (NOLOCK)
    ON apl.CID = c.CID
WHERE apl.OpenActionType = 4  -- Stock dividend
  AND apl.ExecutionOccurred >= DATEADD(MONTH, -24, GETDATE())
ORDER BY apl.ExecutionOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Corporate Actions HLD - Draft](https://etoro-jira.atlassian.net/wiki/spaces/EMM/pages/13388709916) | Confluence | Found via search (updated 2025-11-24) - page not accessible; likely contains HLD for corporate action processing including stock dividends |
| [Stock Dividend Fix - Prod Before and After](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13251117326) | Confluence | Found via search (updated 2025-06-29) - page not accessible; likely documents a production fix related to stock dividend processing |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 2 Confluence found (inaccessible) + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.GetStockDividendPositions | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetStockDividendPositions.sql*
