# Hedge.ArchiveCustomerClosedPositions

> Archives Hedge.CustomerClosedPositions data to History.CustomerClosedPositions by aggregating customer-level realized P&L into configurable time-interval buckets.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Reads Hedge.CustomerClosedPositions; writes History.CustomerClosedPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ArchiveCustomerClosedPositions` archives the real-time customer closed position table (`Hedge.CustomerClosedPositions`) to its history equivalent. This table captures aggregated realized P&L from customer position closures at the HedgeServer/Instrument level - representing what customers collectively realized when closing positions.

Like `ArchiveAccountClosedPositions`, this procedure SUMs the P&L fields (NetPL, CommissionOnClose, ExecutionVolumeInUSD) within each time bucket, producing a compressed history of customer realized outcomes by server and instrument.

The history data in `History.CustomerClosedPositions` feeds `HedgeCostReportHistoryPerDay` and `HedgeCostReportHistoryPerHour`, which use `SUM(NetPL)`, `SUM(CommissionOnClose)`, and `SUM(ZeroPL)` per date to compute the "Clients P&L - Realized" and "Etoro Commission - Realized" components of the hedge cost report.

Called by `Hedge.ArchiveHedgeTables` (but NOT `ArchiveHedgeTables_SS` - this procedure was found in ArchiveHedgeTables only).

---

## 2. Business Logic

### 2.1 Interval-Based Summation of Customer Realized P&L

**What**: Aggregates fine-grained customer closed position events into time-bucket summaries.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@IntervalInMinutes`

**Rules**:
- Groups by (HedgeServerID, InstrumentID, interval_bucket) - note: unlike the account archive, there is NO LiquidityAccountID grouping. Customer closed positions are server+instrument level aggregates.
- `OccurredAt` in output = MAX(OccurredAt) within the bucket.
- SUMs: `NetPL`, `CommissionOnClose`, `ExecutionVolumeInUSD`.
- Full transaction with TRY/CATCH.
- The comment "Grouping of 15 minutes" in the code confirms 15 minutes as the standard interval.

### 2.2 Downstream Use in HedgeCostReport

**What**: Customer-level P&L data feeds the HedgeCost report's realized customer section.

**Rules**:
- `SUM(NetPL)` from History.CustomerClosedPositions = "Clients P&L - Realized" in the hedge cost report.
- `SUM(CommissionOnClose)` = "Etoro Commission - Realized" (eToro's revenue from closed customer positions).
- `SUM(ZeroPL)` = "Etoro Zero" (Zero-commission P&L component).

**Diagram**:
```
Hedge.CustomerClosedPositions (fine-grained events)
  |
  | GROUP BY (HedgeServerID, InstrumentID, interval_bucket)
  | SUM(NetPL), SUM(CommissionOnClose), SUM(ExecutionVolumeInUSD), MAX(OccurredAt)
  |
  v
History.CustomerClosedPositions
  |
  +-> HedgeCostReportHistoryPerDay/PerHour:
      SUM(NetPL) = "Clients P&L - Realized"
      SUM(CommissionOnClose) = "Etoro Commission - Realized"
      SUM(ZeroPL) = "Etoro Zero"
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | CODE-BACKED | Archive window start (inclusive). Rows with OccurredAt >= @StartDate are included in aggregation. |
| 2 | @EndDate | datetime | NO | - | CODE-BACKED | Archive window end (exclusive). Rows with OccurredAt < @EndDate are processed. |
| 3 | @IntervalInMinutes | int | NO | - | CODE-BACKED | Aggregation granularity in minutes. Standard value is 15 minutes per developer comment. Determines the time resolution of the history data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.CustomerClosedPositions | READ (CTE) | Source of real-time customer closed position P&L data |
| - | History.CustomerClosedPositions | WRITER (INSERT) | Target for time-interval aggregated customer P&L history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ArchiveHedgeTables | EXEC call | Caller | Main archive orchestrator |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ArchiveCustomerClosedPositions (procedure)
├── Hedge.CustomerClosedPositions (table) [READ]
└── History.CustomerClosedPositions (table) [WRITER - INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerClosedPositions | Table | Source of real-time customer closed position data |
| History.CustomerClosedPositions | Table | Target for aggregated history data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ArchiveHedgeTables | Stored Procedure | Calls this as part of the archival job |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH + TRANSACTION | Error handling | Full rollback on error with diagnostic RAISERROR |

---

## 8. Sample Queries

### 8.1 Execute archival
```sql
EXEC [Hedge].[ArchiveCustomerClosedPositions]
    @StartDate = '2026-03-18 00:00:00',
    @EndDate   = '2026-03-19 00:00:00',
    @IntervalInMinutes = 15
```

### 8.2 View archived customer P&L for a hedge server
```sql
SELECT TOP 10 HedgeServerID, InstrumentID, OccurredAt,
       NetPL, CommissionOnClose, ExecutionVolumeInUSD
FROM [History].[CustomerClosedPositions] WITH (NOLOCK)
WHERE HedgeServerID = 1 AND OccurredAt >= '2026-03-18 00:00:00'
ORDER BY OccurredAt DESC
```

### 8.3 Calculate total customer P&L and commission by server for a day
```sql
SELECT HedgeServerID,
       SUM(NetPL) AS TotalClientPL,
       SUM(CommissionOnClose) AS TotalEtoroCommission
FROM [History].[CustomerClosedPositions] WITH (NOLOCK)
WHERE OccurredAt BETWEEN '2026-03-18 00:00:00' AND '2026-03-19 00:00:00'
GROUP BY HedgeServerID
ORDER BY HedgeServerID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | CustomerPL (realized) from History.CustomerClosedPositions drives "Clients P&L - Realized" and "Etoro Commission - Realized" in INSight HedgeCost display |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ArchiveCustomerClosedPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ArchiveCustomerClosedPositions.sql*
