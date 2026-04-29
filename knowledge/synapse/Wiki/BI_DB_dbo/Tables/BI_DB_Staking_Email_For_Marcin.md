# BI_DB_dbo.BI_DB_Staking_Email_For_Marcin

> 3-row weekly/daily snapshot of FCA crypto staking metrics for ADA (Cardano) and TRX (Tron) positions, plus a Total row. Built by SP_W_Mon_Staking_Email_for_Marcin for FCA-regulated customers (RegulationID=2) with valid credit reports and no Tangany wallet. TRUNCATE+INSERT replaces all data each run. Used for internal staking pool reporting email.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_W_Mon_Staking_Email_for_Marcin (BI_DB_dbo) |
| **Refresh** | Weekly/Monday — TRUNCATE+INSERT (full replacement) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_staking_email_for_marcin` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

This is a compact reporting table powering a weekly staking summary email for FCA regulatory compliance. It shows the count of unique customers, total units held, NOP (net open position), and staking-pool-eligible amounts for Cardano (ADA, InstrumentID=100017) and Tron (TRX, InstrumentID=100026) staking positions.

The population is FCA-regulated customers (RegulationID=2) with IsCreditReportValidCB=1 and TanganyStatusID IS NULL (no Tangany custodial wallet). The staking pool eligibility excludes US customers (CountryID=219) and UK customers registered after 2022-02-08 (CountryID=218 AND RegisteredReal > '20220208'), and for TRX additionally excludes unsettled positions.

The table always contains exactly 3 rows: one for ADA, one for TRX, one for Total. All numeric values are stored as formatted money strings (nvarchar(max)) for direct email embedding.

---

## 2. Business Logic

### 2.1 Staking Pool Eligibility Filter

**What**: Determines which positions count toward the staking pool.
**Columns Involved**: Amount_For_StakingPool, NOP_For_StakingPool
**Rules**:
- For ADA (100017): Include if CountryID != 219 (not US) AND NOT (CountryID=218 AND RegisteredReal > '20220208')
- For TRX (100026): Same country filter PLUS IsSettled != 0 (must be settled)
- Otherwise: Amount = 0

### 2.2 Formatted String Output

**What**: All numeric columns are formatted as money strings for email consumption.
**Columns Involved**: Num_of_CID, Amount_IN_Units, NOP, Amount_For_StakingPool, NOP_For_StakingPool
**Rules**:
- CONVERT(varchar, CAST(value AS money), 1) — produces comma-separated format like "229,567,298.73"
- ISNULL wrapper defaults to 0 on INSERT

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Only 3 rows. No performance concerns.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current staking snapshot | `SELECT * FROM BI_DB_dbo.BI_DB_Staking_Email_For_Marcin` |

### 3.3 Common JOINs

None needed — self-contained summary table.

### 3.4 Gotchas

- **All numeric columns are nvarchar(max)**: Values like "229,567,298.73" are strings — CAST to numeric before math
- **Only 3 rows**: TRUNCATE+INSERT replaces all data; no historical retention
- **Named after a person ("Marcin")**: Internal operational table — specific recipient for staking pool email
- **FCA only**: RegulationID=2 — does not cover CySEC, ASIC, or other regulated entities

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High |
| Tier 5 | ETL metadata | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NOT NULL | Reporting date (input parameter). Single snapshot date. (Tier 2 — SP_W_Mon_Staking_Email_for_Marcin) |
| 2 | Num_of_CID | nvarchar(max) | NOT NULL | Count of distinct FCA customers holding ADA/TRX positions, formatted as money string (e.g., "111,403.00"). (Tier 2 — SP_W_Mon_Staking_Email_for_Marcin) |
| 3 | Amount_IN_Units | nvarchar(max) | NOT NULL | Total crypto units held (AmountInUnitsDecimal), formatted as money string. All eligible FCA customers. (Tier 2 — SP_W_Mon_Staking_Email_for_Marcin) |
| 4 | NOP | nvarchar(max) | NOT NULL | Net open position in USD for settled positions (IsSettled=1), formatted as money string. (Tier 2 — SP_W_Mon_Staking_Email_for_Marcin) |
| 5 | Amount_For_StakingPool | nvarchar(max) | NOT NULL | Staking-pool-eligible units. Excludes US (CountryID=219) and UK post-Feb-2022 customers. For TRX also excludes unsettled. Formatted money string. (Tier 2 — SP_W_Mon_Staking_Email_for_Marcin) |
| 6 | NOP_For_StakingPool | nvarchar(max) | NOT NULL | Staking-pool-eligible NOP. Same exclusion filters as Amount_For_StakingPool. Formatted money string. (Tier 2 — SP_W_Mon_Staking_Email_for_Marcin) |
| 7 | UpdateDate | date | YES | ETL metadata: date when this snapshot was generated. (Tier 5 — ETL metadata) |
| 8 | InstrumentName | varchar(50) | YES | Instrument symbol: 'ADA' (Cardano), 'TRX' (Tron), or 'Total'. From Dim_Instrument.Symbol. (Tier 2 — SP_W_Mon_Staking_Email_for_Marcin) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Num_of_CID | BI_DB_PositionPnL | CID | COUNT DISTINCT, money format |
| Amount_IN_Units | BI_DB_PositionPnL | AmountInUnitsDecimal | SUM, money format |
| NOP | BI_DB_PositionPnL | NOP | SUM WHERE IsSettled=1 |
| Amount/NOP_For_StakingPool | BI_DB_PositionPnL | AmountInUnitsDecimal, NOP | SUM with country exclusions |
| InstrumentName | Dim_Instrument | Symbol | Passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (position snapshot)
DWH_dbo.Dim_Customer (FCA filter, RegulationID=2)
DWH_dbo.Dim_Instrument (Symbol name)
DWH_dbo.Dim_Country + Dim_Regulation + Dim_Language (eligibility filters)
  |-- SP_W_Mon_Staking_Email_for_Marcin @Date (TRUNCATE+INSERT) ---|
  v
BI_DB_dbo.BI_DB_Staking_Email_For_Marcin (3 rows: ADA + TRX + Total)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_staking_email_for_marcin
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentName | DWH_dbo.Dim_Instrument | ADA/TRX instrument lookup |

### 6.2 Referenced By (other objects point to this)

No known consumers. Used for email generation.

---

## 7. Sample Queries

### 7.1 Current Staking Summary

```sql
SELECT InstrumentName, Num_of_CID, Amount_IN_Units, NOP, Amount_For_StakingPool
FROM BI_DB_dbo.BI_DB_Staking_Email_For_Marcin
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 7 T2, 0 T3, 0 T4, 1 T5 | Elements: 8/8, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Staking_Email_For_Marcin | Type: Table | Production Source: SP_W_Mon_Staking_Email_for_Marcin*
