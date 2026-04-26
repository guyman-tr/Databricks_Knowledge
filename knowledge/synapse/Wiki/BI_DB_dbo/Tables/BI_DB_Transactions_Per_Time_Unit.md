# BI_DB_dbo.BI_DB_Transactions_Per_Time_Unit

**Schema**: BI_DB_dbo | **Type**: Table | **Batch**: 34 | **Generated**: 2026-04-22

| Property | Value |
|---|---|
| **Writer SP** | `BI_DB_dbo.SP_Transactions_Per_Time_Unit` |
| **Frequency** | Daily (SB_Daily) |
| **Priority** | P20 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | (Date ASC) |
| **Grain** | Date — one row per calendar day |
| **Date Range** | 2021-01-01 – 2026-04-12 |
| **Total Rows** | ~1,928 (one per day) |
| **ETL Pattern** | DELETE WHERE Date=@Date + INSERT |

---

## 1. Business Meaning

Daily summary of platform-wide trading throughput, measuring the volume and timing of all position opens and closes. For each day, the table records the total transaction count, the peak activity at each sub-day granularity (hour, minute, second), and the corresponding unique-customer counts at each level. It also captures a daily snapshot of the total fully-verified depositor base.

The table is used by operations and management to monitor platform load capacity — identifying peak traffic windows that stress infrastructure, and tracking how daily transaction volumes trend over time. The Hour, Minute, and Second columns store the **clock value of the peak time bucket** (not a breakdown), enabling "what time was busiest?" analysis alongside the peak volume count.

---

## 2. Business Logic

### Source Data

**Transactions counted** = all positions with `OpenDateID = @DateINT` (opens) UNION all positions with `CloseDateID = @DateINT` (closes), subject to:
- **Opens**: `ISNULL(IsAirDrop, 0) = 0` — excludes airdrop positions (crypto promotional grants)
- **Closes**: `ClosePositionReasonID != 10` — excludes a specific close reason (admin/system close)
- **Closes**: joined to Fact_SnapshotCustomer via Dim_Range SCD2 for customer state resolution
- **UNION** (not UNION ALL): deduplicates full-row identical records (in practice, open and close records have different Type values so no functional difference)

### Peak Aggregations

```sql
-- Daily total
#daily: COUNT(PositionID), COUNT(DISTINCT CID) from #unioned

-- Peak hour: hour with most transactions
#hourly: TOP 1 Hour, COUNT(PositionID) AS Hourly, COUNT(DISTINCT CID) AS CID_Hourly
         ORDER BY COUNT(PositionID) DESC

-- Peak minute: hour+minute combination with most transactions
#minutely: TOP 1 Hour, Minute, COUNT(PositionID) AS Minutely, COUNT(DISTINCT CID) AS CID_Minutely
           ORDER BY COUNT(PositionID) DESC

-- Peak second: hour+minute+second combination with most transactions
#secondly: TOP 1 Hour, Minute, Second, COUNT(PositionID) AS Secondly, COUNT(DISTINCT CID) AS CID_Secondly
           ORDER BY COUNT(PositionID) DESC
```

### Customers_Cnt

```sql
SELECT COUNT(DISTINCT dc.RealCID)
FROM DWH_dbo.Dim_Customer dc
WHERE dc.IsValidCustomer = 1    -- not PI/label-30/CountryID=250
  AND dc.IsDepositor = 1        -- has ever made a deposit
  AND dc.VerificationLevelID = 3 -- fully KYC-verified
```

This subquery runs once per SP execution and captures the total active depositor base at ETL time. It is NOT scoped to @Date — it reflects the current state of Dim_Customer at the time the SP runs.

---

## 3. Query Advisory

| Concern | Guidance |
|---|---|
| **One row per date** | Table has exactly 1,928 rows (~5.3 years). No aggregation needed for date-level analysis. |
| **ROUND_ROBIN distribution** | No node locality. Clustered on Date — Date range queries are efficient. |
| **Hour/Minute/Second = peak time, not breakdown** | These are the clock values of the busiest time bucket, not cumulative counts. Minutely/Secondly are the volume IN that specific minute/second, not for the whole hour. |
| **Customers_Cnt is not scoped to @Date** | It counts the total valid depositor base at ETL run time (the following morning). It is not the count of customers who traded that day — that is CID_Daily. |
| **Daily counts both opens AND closes** | A position opened AND closed on the same day contributes 2 to Daily. It is a transaction count, not a position count. |
| **INT type may limit extreme volumes** | All count columns are INT. Days with >2.1 billion transactions would overflow; at current observed max (~12M/day) this is not an issue, but note for future capacity planning. |
| **No change history in SP** | The SP has no author/change-log header. Creation date and intent are not documented in the SQL source. |

---

## 4. Elements

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | Date | DATE | NOT NULL | T2 | Calendar date of the reporting day. Primary key in practice (one row per day). Serves as the clustered index and DELETE key. |
| 2 | Daily | INT | NULL | T2 | Total count of position events (opens + closes) on Date. Each position open and each position close counts as one transaction. Excludes airdrop opens and admin closes (ClosePositionReasonID=10). |
| 3 | Hour | INT | NULL | T2 | Hour of day (0–23) of the single busiest hour — the hour that had the most transactions on Date. |
| 4 | Hourly | INT | NULL | T2 | Transaction count within the peak hour (the hour identified by the Hour column). Represents maximum hourly throughput for the day. |
| 5 | Minute | INT | NULL | T2 | Minute of the hour (0–59) of the single busiest minute — the minute within the peak hour that had the most transactions. |
| 6 | Minutely | INT | NULL | T2 | Transaction count within the peak minute (the hour+minute identified by Hour and Minute). Represents maximum per-minute throughput for the day. |
| 7 | Second | INT | NULL | T2 | Second of the minute (0–59) of the single busiest second — the second within the peak minute that had the most transactions. |
| 8 | Secondly | INT | NULL | T2 | Transaction count within the peak second (the hour+minute+second identified by Hour, Minute, and Second). Represents maximum per-second throughput for the day. |
| 9 | CID_Daily | INT | NULL | T2 | Count of distinct customers (CID) who had at least one position event (open or close) on Date. |
| 10 | CID_Hourly | INT | NULL | T2 | Count of distinct customers active within the peak hour. |
| 11 | CID_Minutely | INT | NULL | T2 | Count of distinct customers active within the peak minute. |
| 12 | CID_Secondly | INT | NULL | T2 | Count of distinct customers active within the peak second. |
| 13 | Customers_Cnt | INT | NULL | T2 | Total count of fully-verified depositing customers at ETL run time. Computed as COUNT(DISTINCT Dim_Customer.RealCID) WHERE IsValidCustomer=1 AND IsDepositor=1 AND VerificationLevelID=3 (KYC-complete). Not scoped to Date — reflects the customer base size at time of SP execution. |
| 14 | UpdateDate | DATETIME | NOT NULL | T2 | ETL execution timestamp (GETDATE() at INSERT). |

---

## 5. Lineage

**Writer SP**: `BI_DB_dbo.SP_Transactions_Per_Time_Unit`
**Root Sources**: `DWH_dbo.Dim_Position` (transaction events), `DWH_dbo.Dim_Customer` (customer base count)

```
DWH_dbo.Dim_Position
  |-- opens: WHERE OpenDateID=@DateINT, IsAirDrop=0 --|
  |-- closes: WHERE CloseDateID=@DateINT, ClosePositionReasonID!=10 --|
  |-- UNION → #unioned --|
  |-- aggregate to daily/hourly/minutely/secondly peak stats --|
  v
DWH_dbo.Dim_Customer (subquery, unscoped to date)
  |-- COUNT(DISTINCT RealCID) WHERE IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3 --|
  v
BI_DB_dbo.BI_DB_Transactions_Per_Time_Unit
  (1 row/date — daily peak throughput + customer base)
```

See `BI_DB_Transactions_Per_Time_Unit.lineage.md` for full column-level lineage.

---

## 6. Relationships

| Relationship | Object | Join / Notes |
|---|---|---|
| **Source** | `DWH_dbo.Dim_Position` | Opens (OpenDateID=@DateINT) and closes (CloseDateID=@DateINT); InstrumentID joined to Dim_Instrument for intermediate temp tables only |
| **Source** | `DWH_dbo.Dim_Customer` | Subquery for Customers_Cnt; not joined to position data |
| **Source (intermediate)** | `DWH_dbo.Fact_SnapshotCustomer + Dim_Range` | SCD2 close-date resolution for close positions; not output to final table |
| **Sibling** | `BI_DB_dbo.BI_DB_US_Stocks_Transactions_Per_Time_Unit` | US Stocks variant written by SP_US_Stocks_Transactions_Per_Time_Unit (P0) |
| **Downstream** | Unknown | No SSDT references found. Likely consumed by operations dashboards or capacity monitoring tools. |

---

## 7. Sample Queries

```sql
-- Latest 7 days of trading volume and peak throughput
SELECT TOP 7 Date, Daily, Hour, Hourly, Minute, Minutely, Second, Secondly,
       CID_Daily, Customers_Cnt
FROM BI_DB_dbo.BI_DB_Transactions_Per_Time_Unit
ORDER BY Date DESC;

-- Busiest trading days (top 10 by transaction volume)
SELECT TOP 10 Date, Daily, Hour, Hourly, CID_Daily
FROM BI_DB_dbo.BI_DB_Transactions_Per_Time_Unit
ORDER BY Daily DESC;

-- Year-over-year monthly average daily transaction volume
SELECT YEAR(Date) AS yr, MONTH(Date) AS mo,
       AVG(CAST(Daily AS BIGINT)) AS avg_daily_txns,
       AVG(CAST(CID_Daily AS BIGINT)) AS avg_daily_customers
FROM BI_DB_dbo.BI_DB_Transactions_Per_Time_Unit
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY yr DESC, mo DESC;
```

---

## 8. Atlassian

No Confluence page found for this table. It is an operations/capacity monitoring table with no clear owner team identified in the SP. Recommended search terms: "transactions per time unit", "peak trading load", "platform throughput".
