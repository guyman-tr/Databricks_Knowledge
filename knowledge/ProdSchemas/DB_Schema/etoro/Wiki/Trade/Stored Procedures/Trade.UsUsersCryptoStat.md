# Trade.UsUsersCryptoStat

> Reports crypto trading statistics for US customers (CountryGroupID=4) over a specified date range (max 7 days), including open/close counts, fail-to-open/fail-to-close counts, and success percentages.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DateFrom / @Dateto (max 7-day range); reads Trade.Position, History.PositionSlim, History.PositionFail; InstrumentTypeID=10 (Crypto) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure generates a crypto trading activity summary specifically for US customers. It answers the question: "How many crypto positions did US customers attempt to open and close in this period, and what was the success rate?" The output supports compliance, monitoring, and operational reporting for the US crypto trading segment.

The US customer scope is defined by CountryGroupID=4 (joined from Dictionary.CountryToCountryGroup), which is the eToro grouping for US-regulated customers. Crypto instruments are identified by InstrumentTypeID=10 in Trade.InstrumentMetaData.

The procedure produces two result sets:
1. A summary with Open, Close, FailToOpen, FailToClose counts plus success percentages
2. A detailed fail breakdown by FailTypeID, ErrorCode, and FailReason - enabling operations teams to diagnose systemic issues (e.g., a specific error code causing mass FailToOpen events)

The WITH RECOMPILE option forces a fresh execution plan on every call to handle the variable date range parameters efficiently. The maximum 7-day range guard prevents expensive full-history scans.

---

## 2. Business Logic

### 2.1 Date Range Validation (7-Day Limit)

**What**: Prevents date ranges exceeding 7 days to avoid expensive scans.

**Columns/Parameters Involved**: `@DateFrom`, `@Dateto`, `DATEDIFF(DAY, ...)`

**Rules**:
- IF DATEDIFF(DAY, @DateFrom, @Dateto) > 7 -> RAISERROR 'Please inserts less days (until 1 week)', severity 16
- Execution stops on error (caller must handle the error)
- The RAISERROR message includes a typo ("inserts" instead of "insert") - preserved from original

### 2.2 US Customer Identification via CountryGroupID=4

**What**: Scopes all statistics to US-regulated customers only.

**Columns/Parameters Involved**: `CountryGroupID`, `Customer.CustomerStatic`, `Dictionary.CountryToCountryGroup`, `#USCID`

**Rules**:
- JOIN Customer.CustomerStatic to Dictionary.CountryToCountryGroup ON CountryID
- WHERE CountryGroupID = 4 (US customer group)
- #USCID = all CID values for US customers, used as a filter in all subsequent queries
- Uses READ UNCOMMITTED isolation for the session (SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED at top)

### 2.3 Open Position Count (Live + History Combined)

**What**: The "Open" count combines currently open crypto positions with historically opened ones to represent "all positions that were opened in the date range."

**Columns/Parameters Involved**: `Trade.Position`, `History.PositionSlim`, `@positionOpen`, `InitDateTime`, `MirrorID`

**Rules**:
- @positionOpen = COUNT(*) from Trade.Position WHERE InstrumentTypeID=10 AND InitDateTime BETWEEN @DateFrom AND @Dateto AND MirrorID=0 AND CID IN #USCID
- Then #A Status='Open' count = COUNT(*) from History.PositionSlim (same filter) + @positionOpen
- MirrorID=0 in both queries = self-directed (not mirror/copy) positions only
- InstrumentTypeID=10 from Trade.InstrumentMetaData subquery = Crypto instruments

### 2.4 Five-Metric Summary Result Set

**What**: First result set: 6 rows - Open, Close, FailToOpen, FailToClose counts + success percentages.

**Columns/Parameters Involved**: `#A`, `Status`, `Total`

**Rules**:
- Open: COUNT from History.PositionSlim (InitDateTime in range) + @positionOpen (live open)
- Close: COUNT from History.PositionSlim (CloseOccurred in range)
- FailToOpen: COUNT from History.PositionFail WHERE FailTypeID=3 AND MirrorID=0 AND FailOccurred in range
- FailToClose: COUNT from History.PositionFail WHERE FailTypeID=4 AND MirrorID=0 AND FailOccurred in range
- Success % of Open = Open / (Open + FailToOpen) * 100
- Success % of Close = Close / (Close + FailToClose) * 100
- FailTypeID=3 = FailToOpen; FailTypeID=4 = FailToClose (Dictionary.FailType lookup)
- Output ordered: Open(1), Close(2), FailToOpen(3), FailToClose(4), Success%Open(5), Success%Close(6)

**Diagram**:
```
Result Set 1 (6 rows):
  Status='Open'                         -> total opens attempted
  Status='Close'                        -> total closes completed
  Status='FailToOpen'                   -> FailTypeID=3 count
  Status='FailToClose'                  -> FailTypeID=4 count
  Status='Success percentage of Open'  -> Open/(Open+FailToOpen)*100
  Status='Success percentage of Close' -> Close/(Close+FailToClose)*100
```

### 2.5 Fail Detail Result Set

**What**: Second result set: breakdown of failures by FailTypeID, ErrorCode, FailReason.

**Columns/Parameters Involved**: `History.PositionFail`, `FailTypeID`, `ErrorCode`, `FailReason`

**Rules**:
- GROUP BY FailType (3=FailToOpen, 4=FailToClose) + ErrorCode
- FailReason = MAX(FailReason) - one representative reason per group
- Ordered by Total DESC
- Enables operations to identify the top error codes causing failures

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of the reporting window (inclusive). Combined with @Dateto, the range must be <= 7 days or the procedure raises an error. Used as BETWEEN lower bound for InitDateTime (opens) and FailOccurred (fails). |
| 2 | @Dateto | DATETIME | NO | - | CODE-BACKED | End of the reporting window (inclusive). Maximum 7 days after @DateFrom. Note: legacy parameter name typo - "Dateto" (lowercase 't') instead of "DateTo". Both BETWEEN upper bounds use this value. |

**Output - Result Set 1 (Summary):**

| # | Column | Description |
|---|--------|-------------|
| 1 | Status | Category label: 'Open', 'Close', 'FailToOpen', 'FailToClose', 'Success percentage of Open', 'Success percentage of Close' |
| 2 | Total | Count or percentage for the category |

**Output - Result Set 2 (Fail Detail):**

| # | Column | Description |
|---|--------|-------------|
| 1 | Total | Count of failures in this group |
| 2 | FailType | 'FailToOpen' (FailTypeID=3) or 'FailToClose' (FailTypeID=4) |
| 3 | ErrorCode | System error code from the failed position attempt |
| 4 | FailReason | Descriptive reason for the failure (MAX per group) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| US customer scope | Customer.CustomerStatic | Reader (cross-schema) | CID source for US customers |
| Country grouping | Dictionary.CountryToCountryGroup | Reader | JOIN on CountryID to get CountryGroupID=4 (US) |
| Crypto instrument filter | Trade.InstrumentMetaData | Reader | Subquery WHERE InstrumentTypeID=10 to identify crypto instruments |
| Open positions (live) | Trade.Position | Reader | COUNT of currently open crypto positions for US customers opened in range |
| Open/close counts | History.PositionSlim | Reader (cross-schema) | Counts of positions by InitDateTime and CloseOccurred within date range |
| Fail counts | History.PositionFail | Reader (cross-schema) | FailToOpen (FailTypeID=3) and FailToClose (FailTypeID=4) counts and error details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Nagios monitoring / linked server monitoring | EXECUTE permission | Caller | Referenced in permissions for Nagios monitoring and linked server access, suggesting automated monitoring invocation |
| US crypto operations reporting | EXECUTE | Caller | Manual execution by operations for US crypto trading health checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UsUsersCryptoStat (procedure)
├── Customer.CustomerStatic (table - US CID source, cross-schema)
├── Dictionary.CountryToCountryGroup (table - CountryGroupID=4 filter)
├── Trade.InstrumentMetaData (table - InstrumentTypeID=10 crypto filter)
├── Trade.Position (table - live open position count)
├── History.PositionSlim (table - open/close history, cross-schema)
└── History.PositionFail (table - fail counts and details, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | US customer CID set for scoping all queries |
| Dictionary.CountryToCountryGroup | Table | JOIN to resolve CountryGroupID=4 (US) from CountryID |
| Trade.InstrumentMetaData | Table | Subquery filter for InstrumentTypeID=10 (Crypto) |
| Trade.Position | Table | COUNT of currently open US crypto positions initiated in the date range |
| History.PositionSlim | Table | COUNT of opened/closed US crypto positions in the date range |
| History.PositionFail | Table | COUNT and detail of FailToOpen (3) and FailToClose (4) events in the date range |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Nagios / linked server monitoring | External system | Automated health monitoring of US crypto trading activity |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Procedure option | Forces a new execution plan on every call. Prevents parameter-sniffing issues across different date ranges which can vary widely in result set size. |
| SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED | Session setting | Allows dirty reads across all queries in this procedure. Acceptable for reporting/monitoring where exact consistency is less important than query speed. |
| 7-day max range | Business logic | DATEDIFF(DAY, @DateFrom, @Dateto) > 7 -> RAISERROR (severity 16). Prevents runaway queries against historical tables. |
| MirrorID = 0 | Business logic | All queries filter to MirrorID=0 to count only self-directed crypto trades, excluding copy/mirror positions. |
| InstrumentTypeID = 10 | Business logic | Hardcoded Crypto instrument type filter across all queries. |

---

## 8. Sample Queries

### 8.1 Get US crypto stats for the last 7 days

```sql
EXEC Trade.UsUsersCryptoStat
    @DateFrom = DATEADD(DAY, -7, GETUTCDATE()),
    @Dateto = GETUTCDATE()
```

### 8.2 Get US crypto stats for a specific date range

```sql
EXEC Trade.UsUsersCryptoStat
    @DateFrom = '2026-03-11 00:00:00',
    @Dateto = '2026-03-17 23:59:59'
```

### 8.3 Preview US customer count

```sql
SELECT COUNT(DISTINCT cs.CID) AS USCustomerCount
FROM Customer.CustomerStatic cs WITH (NOLOCK)
JOIN Dictionary.CountryToCountryGroup ctcg WITH (NOLOCK)
    ON cs.CountryID = ctcg.CountryID
WHERE ctcg.CountryGroupID = 4
```

### 8.4 Preview crypto instruments (InstrumentTypeID=10)

```sql
SELECT
    InstrumentID,
    Symbol,
    InstrumentDisplayName
FROM Trade.InstrumentMetaData WITH (NOLOCK)
WHERE InstrumentTypeID = 10
ORDER BY Symbol
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UsUsersCryptoStat | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UsUsersCryptoStat.sql*
