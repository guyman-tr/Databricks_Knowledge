---
schema: BI_DB_dbo
table: BI_DB_USA_Equity_Deposits
documented: true
batch: 37
quality_score: 8.95
---

# BI_DB_USA_Equity_Deposits

## 1. Business Meaning

Daily equity and financial activity snapshot for **US-regulated eToro customers**, aggregated by regulation type, country, and US state. Tracks realized equity positions, cash balances, credit balances, deposits, and cashouts for customers regulated under US financial frameworks (eToroUS, FinCEN, FinCEN+FINRA).

Used for US regulatory reporting, compliance monitoring, and state-level equity analysis. The table covers the US-regulated customer population only (DWHRegulationID IN 6, 7, 8) and excludes all non-US-regulated accounts.

| Property | Value |
|----------|-------|
| Grain | One row per `DateID × RegulationName × CountryName × StateName` |
| Population | US-regulated customers: eToroUS (6), FinCEN (7), FinCEN+FINRA (8) |
| Date range | 20190101 – 20260412 (1,569 dates) |
| Row count | ~295,046 (as of 2026-04) |
| Regulation values | 'eToroUS', 'FinCEN', 'FinCEN+FINRA' |
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED (DateID ASC) |

---

## 2. Business Logic

### 2.1 ETL Pattern

Written daily by `SP_USA_Equity_Deposits @Date DATE`. The SP uses a DELETE-then-INSERT pattern on `DateID`:

```sql
DELETE FROM BI_DB_USA_Equity_Deposits WHERE DateID = @DateID
INSERT INTO BI_DB_USA_Equity_Deposits ... FROM #Pop_Full_Data_Agg
```

This is idempotent — re-running for the same date replaces the existing rows cleanly.

### 2.2 Population Assembly

The base population (`#Pop`) joins `DWH_dbo.Fact_SnapshotCustomer` with `Dim_Range` to resolve the correct snapshot row for `@Date`, then enriches with regulation name, country name, and state name.

```
DWH_dbo.Fact_SnapshotCustomer (WHERE RegulationID IN 6,7,8)
  → enriched with Dim_Regulation → RegulationName
  → enriched with Dim_Country → CountryName
  → LEFT JOIN Dim_State_and_Province → StateName (US only, else literal 'NULL')
```

### 2.3 Financial Metrics Assembly

Three separate temp tables feed the final aggregation:

| Temp Table | Source | What It Contains |
|-----------|--------|-----------------|
| `#RealizedEquity` | `DWH_dbo.V_Liabilities` | RealizedEquity, TotalCash, Credit (per CID, DateID) |
| `#Deposits` | `DWH_dbo.Fact_CustomerAction` | Deposits (ActionTypeID=7) and cashouts (ActionTypeID=8) amounts and counts |
| `#Revenue` | `BI_DB_dbo.BI_DB_DDR_CID_Level` | DDR_Revenue — **deprecated, always 0** |

These are LEFT JOIN'ed onto the population, then SUM-aggregated by segment (DateID × RegulationName × CountryName × StateName).

### 2.4 Segment Activity Filter

The HAVING clause excludes zero-activity segments:

```sql
HAVING SUM(ISNULL(RealizedEquity,0) + ISNULL(Total_Deposits_Amount,0)
         + ISNULL(Total_Deposits,0) + ISNULL(DDR_Revenue,0)) > 0
```

Because `DDR_Revenue` is always 0, segments with no equity balance AND no deposits on that date will not appear in the table.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID. For date-range queries, always filter by DateID first to leverage the index. No hash distribution — joins on DateID will cause data movement on large tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total deposits by US state today | `WHERE DateID = @today AND RegulationName = 'eToroUS' GROUP BY StateName` |
| Equity trend by regulation | `WHERE DateID BETWEEN @start AND @end GROUP BY DateID, RegulationName` |
| US vs non-US breakdown within table | `WHERE StateName != 'NULL'` (US) vs `WHERE StateName = 'NULL'` (non-US) |
| Cash balance for a regulation | `SUM(TotalCash) WHERE DateID = @date AND RegulationName = 'FinCEN'` |

### 3.3 Gotchas

- **`StateName = 'NULL'` is a string, not SQL NULL.** Non-US customers have `StateName = 'NULL'` (a 4-character varchar value). Filtering `WHERE StateName IS NULL` returns 0 rows. Use `WHERE StateName = 'NULL'` or `WHERE StateName != 'NULL'` for US/non-US splits.
- **`Revenue` is always 0.** The source table (`BI_DB_DDR_CID_Level`) is decommissioned. Revenue has no analytical value. Do not include it in calculations.
- **HAVING filter: zero-activity segments are excluded.** A segment with customers who have no equity and no deposits on a given date will have no row for that date.
- **Inactive dates may have fewer regulation × state combinations.** The population is filtered by `Dim_Range` snapshot validity, not a fixed date calendar.
- **Duplicate StateName values across countries.** StateName is geographic name without country context — e.g., 'Georgia' could be US state or other. Always pair with `CountryName` for disambiguation.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — DWH_dbo wiki verbatim | (Tier 1 — DWH_dbo wiki, `{source}`) |
| Tier 2 — SP ETL code | (Tier 2 — SP_USA_Equity_Deposits) |
| Tier 4 — deprecated/unknown | (Tier 4 — deprecated source) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | ETL date key in YYYYMMDD integer format. Derived from `@Date` parameter: `CAST(CONVERT(CHAR(8), @Date, 112) AS INT)`. Primary time dimension and CLUSTERED INDEX column. (Tier 2 — SP_USA_Equity_Deposits) |
| 2 | RegulationName | varchar(30) | YES | Short code for the US regulation under which the customer is registered. Values: `'eToroUS'` (DWHRegulationID=6), `'FinCEN'` (DWHRegulationID=7), `'FinCEN+FINRA'` (DWHRegulationID=8). Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 — DWH_dbo wiki, Dim_Regulation) |
| 3 | CountryName | varchar(30) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — DWH_dbo wiki, Dim_Country) |
| 4 | StateName | varchar(30) | YES | Full human-readable geographic name of the region — state, province, or territory — for US-domiciled customers (CountryID=219). For non-US customers, stored as the literal string `'NULL'` (not SQL NULL). (Tier 1 — DWH_dbo wiki, Dim_State_and_Province) |
| 5 | RealizedEquity | money | YES | Total realized equity (account value) for all US-regulated customers in this segment on this date. Per customer: total account value including positions and cash, excluding unrealized PnL. Confluence: "Unrealized Equity — the total funds in the account, including profit/loss from open positions. The Portfolio value figure represented on the platform is Unrealized equity." Aggregated from `DWH_dbo.V_Liabilities.RealizedEquity`. (Tier 2 — SP_USA_Equity_Deposits aggregation of V_Liabilities) |
| 6 | Total_Deposits_Amount | decimal(11,2) | YES | Sum of deposit amounts (USD) for customers in this segment on this date. Source: `DWH_dbo.Fact_CustomerAction.Amount WHERE ActionTypeID = 7`. ISNULL to 0 before SUM. (Tier 2 — SP_USA_Equity_Deposits aggregation of Fact_CustomerAction) |
| 7 | Total_Deposits | int | YES | Count of deposit events with Amount >= 0 for customers in this segment on this date. Source: `DWH_dbo.Fact_CustomerAction WHERE ActionTypeID = 7`. (Tier 2 — SP_USA_Equity_Deposits aggregation of Fact_CustomerAction) |
| 8 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to `GETDATE()` on each daily run. (Tier 2 — ETL metadata) |
| 9 | Date | date | YES | Calendar date corresponding to DateID. Populated directly from `@Date` input parameter. Redundant with DateID but useful for direct date arithmetic without CONVERT. (Tier 2 — SP_USA_Equity_Deposits) |
| 10 | TotalCash | money | YES | Total cash balance for all customers in this segment on this date. Per customer: running daily balance = previous TotalCash + daily cash changes from History.ActiveCredit. Aggregated from `DWH_dbo.V_Liabilities.TotalCash`. Note: `TotalCash = Credit + TotalMirrorCash` (Confluence). (Tier 2 — SP_USA_Equity_Deposits aggregation of V_Liabilities) |
| 11 | Total_FreeCreditBalance | money | YES | Total outstanding credit/bonus balance for customers in this segment on this date. Maps to `DWH_dbo.V_Liabilities.Credit` (column renamed in SP). Per customer: last credit event per CID per day from History.ActiveCredit; negative values represent outstanding obligations. (Tier 2 — SP_USA_Equity_Deposits aggregation of V_Liabilities) |
| 12 | Total_Cashouts_Amount | decimal(11,2) | YES | Sum of cashout/withdrawal amounts (USD) for customers in this segment on this date. Source: `DWH_dbo.Fact_CustomerAction.Amount WHERE ActionTypeID = 8`. ISNULL to 0 before SUM. (Tier 2 — SP_USA_Equity_Deposits aggregation of Fact_CustomerAction) |
| 13 | Total_Cashouts | int | YES | Count of cashout/withdrawal events with Amount >= 0 for customers in this segment on this date. Source: `DWH_dbo.Fact_CustomerAction WHERE ActionTypeID = 8`. (Tier 2 — SP_USA_Equity_Deposits aggregation of Fact_CustomerAction) |
| 14 | Revenue | numeric(38,6) | YES | **DEPRECATED — always 0. Do not use.** Sourced from `BI_DB_dbo.BI_DB_DDR_CID_Level.Revenue`, which is permanently decommissioned. The join returns no rows; Revenue is always 0 in practice. (Tier 4 — deprecated source, BI_DB_DDR_CID_Level decommissioned) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| DateID | ETL parameter @Date | — | CONVERT YYYYMMDD integer |
| Date | ETL parameter @Date | — | Direct |
| RegulationName | DWH_dbo.Dim_Regulation | Name | Passthrough — DWHRegulationID IN (6,7,8) |
| CountryName | DWH_dbo.Dim_Country | Name | Passthrough |
| StateName | DWH_dbo.Dim_State_and_Province | Name | CASE: US = state name; else literal 'NULL' |
| RealizedEquity | DWH_dbo.V_Liabilities → Fact_SnapshotEquity | RealizedEquity | SUM per segment |
| TotalCash | DWH_dbo.V_Liabilities → Fact_SnapshotEquity | TotalCash | SUM per segment |
| Total_FreeCreditBalance | DWH_dbo.V_Liabilities → Fact_SnapshotEquity | Credit | SUM per segment, renamed |
| Total_Deposits_Amount | DWH_dbo.Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=7 |
| Total_Deposits | DWH_dbo.Fact_CustomerAction | Amount | COUNT >= 0 WHERE ActionTypeID=7 |
| Total_Cashouts_Amount | DWH_dbo.Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=8 |
| Total_Cashouts | DWH_dbo.Fact_CustomerAction | Amount | COUNT >= 0 WHERE ActionTypeID=8 |
| Revenue | BI_DB_dbo.BI_DB_DDR_CID_Level (decommissioned) | Revenue | ISNULL → 0 (always) |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (RegulationID IN 6,7,8)
  + DWH_dbo.Dim_Range (snapshot date resolution)
  + DWH_dbo.Dim_Regulation (RegulationName)
  + DWH_dbo.Dim_Country (CountryName)
  + DWH_dbo.Dim_State_and_Province (StateName for US)
  → #Pop (customer-level population for @Date)

DWH_dbo.V_Liabilities (DateID = @DateID)
  JOIN #Pop ON CID = RealCID
  → #RealizedEquity (RealizedEquity, TotalCash, Credit per CID)

DWH_dbo.Fact_CustomerAction (DateID = @DateID, ActionTypeID IN 7,8)
  JOIN #Pop ON RealCID
  → #Deposits (deposits + cashouts per CID)

BI_DB_dbo.BI_DB_DDR_CID_Level [DECOMMISSIONED]
  → #Revenue (always 0)

#Pop + #RealizedEquity + #Deposits + #Revenue
  → #Pop_Full_Data (customer-level join)
  → GROUP BY DateID, Date, RegulationName, CountryName, StateName
  → HAVING > 0
  → #Pop_Full_Data_Agg (segment-level)

DELETE + INSERT → BI_DB_dbo.BI_DB_USA_Equity_Deposits
```

---

## 6. Relationships

| Related Object | Relationship | Join |
|---------------|-------------|------|
| DWH_dbo.Dim_Regulation | Source dimension (RegulationName) | `Dim_Regulation.DWHRegulationID = RegulationID` |
| DWH_dbo.Dim_Country | Source dimension (CountryName) | `Dim_Country.CountryID = CountryID` |
| DWH_dbo.Dim_State_and_Province | Source dimension (StateName for US) | `Dim_State_and_Province.RegionByIP_ID = RegionID` |
| DWH_dbo.V_Liabilities | Source view (equity metrics) | `V_Liabilities.CID = RealCID AND DateID = @DateID` |
| DWH_dbo.Fact_CustomerAction | Source fact (deposits/cashouts) | `Fact_CustomerAction.RealCID AND DateID = @DateID AND ActionTypeID IN (7,8)` |

---

## 7. Sample Queries

### Total deposits by US state for a given date
```sql
SELECT StateName,
       SUM(Total_Deposits_Amount) AS TotalDeposits,
       SUM(Total_Deposits)        AS DepositCount
FROM BI_DB_dbo.BI_DB_USA_Equity_Deposits
WHERE DateID = 20260101
  AND StateName != 'NULL'   -- US states only
GROUP BY StateName
ORDER BY TotalDeposits DESC;
```

### Equity trend by regulation over last 30 days
```sql
SELECT DateID,
       RegulationName,
       SUM(RealizedEquity)  AS TotalEquity,
       SUM(TotalCash)       AS TotalCash
FROM BI_DB_dbo.BI_DB_USA_Equity_Deposits
WHERE DateID >= 20260323
GROUP BY DateID, RegulationName
ORDER BY DateID, RegulationName;
```

### Net flow (deposits minus cashouts) by regulation
```sql
SELECT DateID,
       RegulationName,
       SUM(Total_Deposits_Amount)  AS TotalDeposited,
       SUM(Total_Cashouts_Amount)  AS TotalCashedOut,
       SUM(Total_Deposits_Amount - Total_Cashouts_Amount) AS NetFlow
FROM BI_DB_dbo.BI_DB_USA_Equity_Deposits
WHERE DateID BETWEEN 20260101 AND 20260412
GROUP BY DateID, RegulationName
ORDER BY DateID;
```

---

## 8. Atlassian / External References

No Jira tickets or Confluence pages identified for this table during documentation.

---

*Generated: 2026-04-22 | Batch 37 | Quality: 8.95/10*
