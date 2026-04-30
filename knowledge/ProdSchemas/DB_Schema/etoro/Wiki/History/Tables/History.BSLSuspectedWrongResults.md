# History.BSLSuspectedWrongResults

> Audit log of Balance Stop Loss execution results suspected to be incorrect; captures the equity snapshot per customer per execution where the BSL calculation was flagged as potentially erroneous for investigation.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap partitioned by EndMonth on Occurred) |
| **Partition** | Yes - EndMonth partition scheme on Occurred |
| **Indexes** | 0 (heap - no indexes defined) |

---

## 1. Business Meaning

History.BSLSuspectedWrongResults stores BSL equity calculation results that were flagged as potentially wrong during a BSL execution run. When Trade.CheckBSL compares the real-time BSL calculation against the expected outcome and detects a discrepancy - for example, when the equity computed from price snapshots differs significantly from the BSL-recorded equity - the suspect rows are written here for investigation.

This table serves as a quality-control audit log for the BSL system. With 711,383 rows spanning February 2024 to February 2025, it is actively used. The data enables the risk/operations team to investigate whether BSL warnings or close events were triggered correctly or whether a calculation error produced a false positive (unnecessary close) or false negative (missed close).

The table is partitioned by EndMonth on Occurred - records are distributed across monthly partitions for performance. Unlike the Partition-suffix tables which moved to PRIMARY filegroup, this table retains the EndMonth partitioning scheme.

---

## 2. Business Logic

### 2.1 BSL Result Discrepancy Detection

**What**: Each row represents one customer-execution pair where the BSL result was suspect.

**Columns/Parameters Involved**: `ExecutionID`, `CID`, `RealizedEquity`, `UnRealizedEquity`, `BSLRealFunds`, `BonusCredit`

**Rules**:
- A "suspected wrong result" occurs when Trade.CheckBSL detects that the equity values in BSLDataForAllUsers differ from what the independent recalculation (using price snapshots) produces
- The equity values captured here are the SUSPECTED values - the ones that raised the alert - not the corrected values
- Multiple rows for the same (ExecutionID, CID) are possible if multiple runs flagged the same customer
- Trade.CheckBSL sends an email alert with subject "wrong results for BSL with executionID - {N}" when such discrepancies are found
- The data from 2024-2025 shows this is an actively-triggered mechanism

**Diagram**:
```
Trade.CheckBSL(@ExecutionID):
  1. Recalculates unrealized PnL using BSLCurrencyPriceSnapShots
  2. Compares against History.BSLDataForAllUsers recorded equity
  3. If mismatch found:
     -> INSERT History.BSLSuspectedWrongResults (the suspect rows)
     -> Send email alert to operations team
```

---

## 3. Data Overview

| ExecutionID | CID | RealizedEquity | UnRealizedEquity | BSLRealFunds | BonusCredit | Meaning |
|---|---|---|---|---|---|---|
| 223804 | 3635309 | -37,834.09 | -37,828.39 | 2,400.00 | 0.00 | Customer with deeply negative realized and unrealized equity, BSLRealFunds far below actual equity loss - discrepancy triggered investigation in Feb 2025 |

(5 identical rows from the sample - duplicate ExecutionID/CID indicates repeated flagging in same run)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionID | int | NO | - | CODE-BACKED | The BSL execution run where the discrepancy was detected. Links to Trade.ManageBSL ExecutionID. Groups all suspect results from the same check cycle. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer whose BSL result was suspected incorrect. Implicit FK to Customer.Customer. |
| 3 | RealizedEquity | money | YES | - | CODE-BACKED | The realized equity value that was considered suspect in this execution. May differ from the independently recalculated value. Nullable - may not always be available. |
| 4 | UnRealizedEquity | money | YES | - | CODE-BACKED | The unrealized PnL value that was considered suspect. The discrepancy between this and the recalculated unrealized PnL is typically what triggers the flag. Nullable. |
| 5 | BSLRealFunds | money | YES | - | CODE-BACKED | The BSL real funds value (realized + unrealized, excluding bonus) that was flagged as suspect. This is the key threshold comparison value. Nullable. |
| 6 | BonusCredit | money | YES | - | CODE-BACKED | Bonus credit component of equity at time of suspect result. Nullable. |
| 7 | Occurred | datetime | NO | getdate() | CODE-BACKED | Server timestamp when the suspect result was recorded. Partition key - determines which monthly EndMonth partition this row resides in. Default = getdate(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionID | Trade.ManageBSL | Implicit | The BSL run that produced the suspect result |
| CID | Customer.Customer | Implicit | Customer with the suspect equity calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckBSL | ExecutionID, CID | Writer | Inserts flagged rows when equity discrepancies are detected |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSLSuspectedWrongResults (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckBSL | Stored Procedure | Writer - inserts suspected wrong results during BSL verification |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. The table is a heap, which is typical for high-volume append-only audit logs where reads are infrequent and done by full scan.

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (none) | - | - | - | - | - |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BSLSuspectedWrongResultsNEW | DEFAULT | Occurred = getdate() |

Storage: ON [EndMonth](Occurred) - monthly range partitioning scheme for data management.

---

## 8. Sample Queries

### 8.1 Get suspect results for a specific BSL execution
```sql
SELECT ExecutionID, CID, RealizedEquity, UnRealizedEquity, BSLRealFunds, BonusCredit, Occurred
FROM [History].[BSLSuspectedWrongResults] WITH (NOLOCK)
WHERE ExecutionID = @ExecutionID
ORDER BY CID
```

### 8.2 Find customers most frequently appearing in suspect results
```sql
SELECT CID, COUNT(DISTINCT ExecutionID) AS SuspectRunCount, MAX(Occurred) AS LastFlagged
FROM [History].[BSLSuspectedWrongResults] WITH (NOLOCK)
GROUP BY CID
ORDER BY SuspectRunCount DESC
```

### 8.3 Date range and count of suspect executions
```sql
SELECT MIN(Occurred) AS Earliest, MAX(Occurred) AS Latest, COUNT(*) AS TotalRows,
       COUNT(DISTINCT ExecutionID) AS DistinctExecutions
FROM [History].[BSLSuspectedWrongResults] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSLSuspectedWrongResults | Type: Table | Source: etoro/etoro/History/Tables/History.BSLSuspectedWrongResults.sql*
