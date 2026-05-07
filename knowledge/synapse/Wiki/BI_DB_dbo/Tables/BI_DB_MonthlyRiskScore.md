# BI_DB_dbo.BI_DB_MonthlyRiskScore

**Schema**: BI_DB_dbo | **UC Target**: `general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore`
**Row count**: ~105.9M (2013-01-01 → 2024-04-01) | **Refresh**: nominally daily (Override) but **STALE since 2024-04-08**
**Distribution**: ROUND_ROBIN | **Clustered Index**: (Year, Month, CID)

---

## 1. Business Meaning

Monthly customer-level **risk score** assignment table. One row per (Year, Month, CID) gives the customer's `MonthlyRiskScore` (integer 1–10) for that calendar month. The score was historically used by AML/compliance pipelines as a periodic risk-tier label per customer.

> ⚠️ **STALE TABLE** — last refresh in production: **2024-04-08 07:29 UTC** for the period 2024-04-01 → 2024-04-30. No new rows after `EndPeriod = 2024-04-30`. The writer SP/job that populated this table appears to have been retired or moved to a different system. **Do not use for current AML/risk decisions.** For active risk scoring, see `BI_DB_dbo.BI_DB_KYC_Score_CID_Level` and the EWS (Early Warning Score) views.

---

## 2. Business Logic

The `MonthlyRiskScore` is an integer in the range 1–10 (sample shows values 7, 8 prevalent), where higher generally means higher risk. The full scoring algorithm is not in current Synapse code — `BI_DB_MonthlyRiskScore` was migrated as a JUNK target (see `2024_09_22_17_11_39_BI_DB_Migration.JUNK_BI_DB_MonthlyRiskScore.sql`), suggesting the population process was deprecated during the 2024 migration.

The table acts as a **monthly snapshot** with `(Year, Month, CID)` grain. `StartPeriod`, `EndPeriod`, `StartDateID`, `EndDateID` redundantly encode the month boundaries.

---

## 3. Query Advisory

### 3.1 Frozen at 2024-04-30
The latest `EndPeriod` is `2024-04-30` (loaded on `2024-04-08`). Any analysis intended for current/recent risk MUST use a different source. This table is retained for historical lookback only.

### 3.2 (Year, Month, CID) Grain
Querying for a single CID's history: `WHERE CID = @cid ORDER BY Year, Month`. Joining to a fact: prefer `(Year, Month, CID) = (YEAR(@dt), MONTH(@dt), Fact.CID)`. The `StartDateID`/`EndDateID` columns can be joined to `DWH_dbo.Dim_Date.DateID` if a date-key join is needed.

### 3.3 ROUND_ROBIN Distribution
The table is ROUND_ROBIN distributed (not HASH(CID)). Joining on CID to a HASH(CID) fact will trigger a redistribution. For very large analyses, consider materializing into a HASH(CID) staging table first.

### 3.4 No Update Within Month
Once a row is written for (Year, Month, CID), the score is fixed (no in-month re-scoring captured here).

---

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Year | int NOT NULL | Calendar year of the scoring period (e.g., 2024). |
| Month | int NOT NULL | Calendar month of the scoring period (1–12). |
| CID | int NOT NULL | Customer ID. Joins to `DWH_dbo.Dim_Customer.CID`. |
| MonthlyRiskScore | int NOT NULL | Risk score for the customer in this month (integer 1–10; higher = higher risk). |
| StartPeriod | date NOT NULL | First day of the scoring month (e.g., 2024-04-01). |
| EndPeriod | date NOT NULL | Last day of the scoring month (e.g., 2024-04-30). |
| StartDateID | int NOT NULL | YYYYMMDD integer for `StartPeriod`. Joins to `DWH_dbo.Dim_Date.DateID`. |
| EndDateID | int NOT NULL | YYYYMMDD integer for `EndPeriod`. Joins to `DWH_dbo.Dim_Date.DateID`. |
| UpdateDate | datetime | Insert timestamp from the legacy writer (not the scoring date itself). All current rows have UpdateDate around 2024-04-08. |

---

## 5. Lineage

### 5.1 Source / Writer
The active writer SP for this table is **not present** in the current Synapse codebase. The table was migrated from a legacy BI database (see `BI_DB_Migration.BI_DB_MonthlyRiskScore.sql` and `JUNK_BI_DB_MonthlyRiskScore.sql`). No current SP/job is observed populating new rows after April 2024.

### 5.2 Consumers
- Generic Pipeline → `general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_monthlyriskscore` (UC export, daily)

The pipeline still runs and refreshes the UC target with the same stale data. UC consumers will observe the same frozen window.

---

## 6. Status & Recommendation

| Property | Value |
|----------|-------|
| **Status** | **STALE / Frozen since 2024-04-30** |
| **Active in production?** | No new data writes |
| **Replacement** | `BI_DB_dbo.BI_DB_KYC_Score_CID_Level` (KYC-level customer score), EWS view family (Early Warning Score) |
| **Recommendation** | Use only for historical (≤2024-04-30) risk-tier lookback. Document any current-state AML use case via newer EWS/KYC sources. |

---

*Generated as part of Wave 2 medium-priority documentation effort.*
