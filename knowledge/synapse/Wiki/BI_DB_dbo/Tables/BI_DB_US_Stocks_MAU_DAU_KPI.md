# BI_DB_US_Stocks_MAU_DAU_KPI

**Schema:** BI_DB_dbo  
**Type:** Table  
**Distribution:** ROUND_ROBIN  
**Index:** HEAP (no clustered index)  
**Writer SP:** `SP_US_Stocks_MAU_DAU_KPI`  
**Author:** Artyom Bogomolsky (2022-06-19)  
**Frequency:** Daily (SB_Daily, Priority 20)

---

## 1. Summary

Daily KPI table tracking Daily Active Users (DAU) and Monthly Active Users (MAU) for US customers trading real stocks and real crypto through eToro's US platform. One row per calendar day containing aggregated activity counts across three dimensions (stocks-only, crypto-only, dual) plus the total eligible customer population (StocksPotential, CryptoPotential).

Used for US business performance tracking, executive reporting, and regulatory monitoring of US trading activity.

---

## 2. Business Context

- **Domain**: US platform KPIs — real stocks and crypto activity
- **Purpose**: Single-row-per-day summary of how many US customers traded real stocks, real crypto, or both — and what the total eligible population is for each. Enables trend analysis, DAU/MAU ratio tracking, and regulatory reporting.
- **Population**: US customers regulated under NFA (RegulationID=7) and/or NYDFS (RegulationID=8). Potential population requires IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3 (fully KYC verified).
- **Activity definition**: A customer counts as "active" on a given day if they had a settled position that was opened or closed on that day. Positions held through the day (neither opened nor closed) are counted via the close date.
- **Producers**: `SP_US_Stocks_MAU_DAU_KPI` (Artyom Bogomolsky, 2022-06-19; RegulationID 7 + monthly fix added 2022-09-15).
- **Consumers**: US business analytics, executive dashboards, regulatory reporting.

**Scale**: ~1,567 rows (2022-01-01 to 2026-04-12). One row per calendar day (including weekends and holidays — stock activity = 0 on non-trading days, crypto active 24/7).

---

## 3. Column Descriptions

| # | Column | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | DateID | int | NOT NULL | ETL partition date in YYYYMMDD format. Computed as CONVERT(VARCHAR, @Date, 112). Primary identifier for the row. |
| 2 | Date | date | NOT NULL | Calendar date for this KPI row. Equals the @Date SP input parameter. DELETE is keyed on this column (not DateID). |
| 3 | EOM | date | NOT NULL | End of month for the Date: EOMONTH(@Date). Provides the month boundary for use in downstream reporting without recalculation. |
| 4 | StocksPotential | int | YES | Total number of US customers eligible to trade real stocks on this date. Computed from `Fact_SnapshotCustomer` WHERE RegulationID=8 (NYDFS only), IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3. NYDFS (NY Department of Financial Services) regulation is required for real stock trading. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 5 | CryptoPotential | int | YES | Total number of US customers eligible to trade real crypto on this date. COUNT(DISTINCT RealCID) from `Fact_SnapshotCustomer` WHERE RegulationID IN(7,8) — includes both NFA (RegulationID=7) and NYDFS (RegulationID=8), with same IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3 filters. Always ≥ StocksPotential because it includes NFA customers. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 6 | Daily_RealStocks_Activity | int | YES | DAU — number of US customers who had a settled real stock position (InstrumentTypeID IN(5,6), IsSettled=1) opened or closed on this date. Zero on weekends and market holidays when no stock trading occurs. (Tier 2 — DWH_dbo.Dim_Position, RegulationIDOnOpen IN(7,8)) |
| 7 | Daily_RealCrypto_Activity | int | YES | DAU — number of US customers who had a settled real crypto position (InstrumentTypeID=10, IsSettled=1) opened or closed on this date. Non-zero on weekends because crypto trades 24/7. (Tier 2 — DWH_dbo.Dim_Position, RegulationIDOnOpen IN(7,8)) |
| 8 | Daily_Dual_Activity | int | YES | DAU — number of US customers who had BOTH a real stock AND a real crypto settled position event on this date. Subset of Daily_Any_Activity. (Tier 2 — DWH_dbo.Dim_Position) |
| 9 | Daily_Any_Activity | int | YES | DAU — total number of US customers (RegulationIDOnOpen IN(7,8)) with ANY position event (any InstrumentType, including CFDs and unsettled) on this date. COUNT(*) of the customer-day join. (Tier 2 — DWH_dbo.Dim_Position) |
| 10 | Monthly_RealStocks_Activity | int | YES | MAU — cumulative distinct count of US customers who had any settled real stock position active during the current month up to and including this date. Window: @StartDate (first of month) to @Date. Resets to zero at start of each month. (Tier 2 — DWH_dbo.Dim_Position) |
| 11 | Monthly_RealCrypto_Activity | int | YES | MAU — cumulative distinct count of US customers who had any settled real crypto position during the current month-to-date window. (Tier 2 — DWH_dbo.Dim_Position) |
| 12 | Monthly_Dual_Activity | int | YES | MAU — cumulative distinct count of US customers active in both real stocks AND real crypto during the current month-to-date window. (Tier 2 — DWH_dbo.Dim_Position) |
| 13 | Monthly_Any_Activity | int | YES | MAU — cumulative distinct count of ALL US customers with any position event during the current month-to-date window. COUNT(*) from the monthly customer-day join. (Tier 2 — DWH_dbo.Dim_Position) |
| 14 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Always set to GETDATE() at ETL run time. |

---

## 4. Distribution & Partitioning

- **Distribution**: ROUND_ROBIN — rows spread evenly; no hash key.
- **Index**: HEAP — no clustered index. Table is small (~1,600 rows); full scans are fast.
- **ETL Pattern**: DELETE WHERE Date=@Date (date column, not DateID) → INSERT SELECT. Note: the delete key is `Date` (date type), not `DateID` (int).

---

## 5. Relationships

**Upstream (inputs to this table):**

| Source Table | Role | Filter |
|---|---|---|
| `DWH_dbo.Dim_Position` | Daily and monthly trading activity | RegulationIDOnOpen IN(7,8); daily: OpenDateID=@DateID OR CloseDateID=@DateID; monthly: BETWEEN @StartDateID and @DateID |
| `DWH_dbo.Dim_Instrument` | Instrument type classification | InstrumentTypeID IN(5,6) = RealStocks; =10 = RealCrypto |
| `DWH_dbo.Fact_SnapshotCustomer` | Eligible population base | RegulationID IN(7,8), IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3 |
| `DWH_dbo.Dim_Range` | SCD date-range join | @DateID BETWEEN FromDateID AND ToDateID — resolves snapshot attributes to the given date |

**Downstream (tables that read from this table):**
- US KPI dashboards
- Executive reporting
- No confirmed downstream SP references found in BI_DB_dbo SP set.

---

## 6. ETL & Lifecycle

- **Frequency**: Daily, run via SB_Daily scheduler.
- **Priority**: 20 (third wave — depends on Priority 0 outputs including Dim_Position and Fact_SnapshotCustomer).
- **ProcessType**: 1 (SQL stored procedure).
- **Backfill**: Single-date replace. Pass @Date as date type; DELETE uses the `Date` column.
- **Monthly metrics reset**: Monthly_* columns rebuild from month start each day. Each row's Monthly_* reflects all activity from the 1st of the month through that date.
- **Data start**: 2022-01-01 (US trading KPI tracking inception).
- **Latest data**: 2026-04-12 (confirmed via live Synapse query).

---

## 7. Known Caveats & Gotchas

- **DELETE keys on `Date`, not `DateID`**: The ETL DELETE is `WHERE Date=@Date` (date type), not `WHERE DateID=@DateID` (int). Backfill scripts must pass a proper DATE value.
- **StocksPotential ≠ CryptoPotential**: StocksPotential counts only NYDFS (RegulationID=8) customers. CryptoPotential counts NFA (RegulationID=7) + NYDFS (RegulationID=8) customers. CryptoPotential is always ≥ StocksPotential (typically 100K+ larger). Avoid comparing the two as equivalent denominators.
- **RegulationIDOnOpen for activity**: Activity filtering uses `Dim_Position.RegulationIDOnOpen` — the regulation at the time the position was opened. If a customer's regulation status changed after open, the historical activity retains the original classification.
- **Stock DAU = 0 on weekends/holidays**: Real stock trading does not occur on weekends. `Daily_RealStocks_Activity = 0` on Saturdays and Sundays is correct, not a data quality issue.
- **Activity includes all positions opened OR closed on the day**: A position opened months ago and closed on @Date counts as "active" on @Date. This is different from a "position held" definition.
- **Monthly metrics are point-in-time cumulative**: The Monthly_Any_Activity on the 15th of a month shows customers active from the 1st through the 15th — not the final monthly total. Do not compare mid-month values to prior month-end values.
- **RegulationID 7 added 2022-09-15**: Before this date, CryptoPotential excluded NFA customers. Time series before vs after this date shows a step change in CryptoPotential (~100K+ increase).
- **OtherPositions in activity**: The #dtrading CTE counts positions that are NOT RealStocks or RealCrypto (CFDs, unsettled positions) as 'OtherPositions'. These count toward `Daily_Any_Activity` / `Monthly_Any_Activity` but not toward stocks or crypto metrics.

---

## 8. Sample Data (recent dates)

| DateID | Date | StocksPotential | CryptoPotential | Daily_Stocks | Daily_Crypto | Daily_Dual | Daily_Any | Monthly_Stocks | Monthly_Crypto |
|---|---|---|---|---|---|---|---|---|---|
| 20260412 | Sat 2026-04-12 | 329,797 | 430,332 | 0 | 231 | 0 | 231 | 2,970 | 4,049 |
| 20260411 | Fri 2026-04-11 | 329,752 | 430,289 | 0 | 263 | 0 | 263 | 2,970 | 3,948 |
| 20260410 | Thu 2026-04-10 | 329,707 | 430,246 | 910 | 352 | 105 | 1,157 | 2,970 | 3,806 |

Note: Weekend (Apr 12, 11) shows zero stock activity — markets closed. Crypto remains active ($231, $263 customers). Thursday (Apr 10) shows dual activity: 105 customers traded both stocks and crypto that day. Monthly_Stocks stabilizing at 2,970 = MTD active stocks customers. DAU/MAU ratio for stocks on Apr 10: 910/329,707 = 0.28%.
