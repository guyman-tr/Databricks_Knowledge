# BI_DB_dbo.BI_DB_Affiliate_Report

> **DORMANT — 0 rows, no writer SP, fully orphaned.** 27-column monthly affiliate performance reporting table with comprehensive funnel metrics (Registrations→FTDs→ActiveTraders), financial KPIs (deposits, cashouts, commissions, LTV, equity), and affiliate classification dimensions (Region, Channel, SubChannel, Contract). No stored procedure in Synapse SSDT reads or writes this table. ROUND_ROBIN with CLUSTERED INDEX on Month.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no writer SP in SSDT, no references |
| **Refresh** | **DORMANT** — no active ETL process |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Month ASC) |
| **Row Count** | 0 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Affiliate_Report` was designed as a **comprehensive monthly affiliate performance report** combining:
- **Funnel metrics**: Registrations, FTDs, FTDEs, ActiveTraders, Verification levels
- **Financial metrics**: FTD Amount, Deposit/Cashout amounts, Commission, Rollover Fees, Cost, Invested, Equity, LTV
- **Classification dimensions**: Region, Channel, SubChannel, AffiliatesGroupsName, Contact, ContractName

Each row would represent one affiliate's monthly performance for a specific region/channel/sub-channel combination. The table structure suggests it was an executive-level affiliate P&L report aggregating across the full customer lifecycle from registration through active trading and commission payout.

The table is currently **empty (0 rows)** and has **no writer SP** in the Synapse SSDT repository — fully orphaned. The related `BI_DB_Affiliate_Report_90898` table shares a similar pattern, suggesting this reporting was moved to another system (possibly Tableau, Looker, or direct Databricks reporting).

---

## 2. Business Logic

### 2.1 Affiliate Funnel Metrics (Inferred)

**What**: Full registration-to-trader funnel with KYC verification checkpoints.
**Columns Involved**: Registrations, FTDs, FTDEs, ActiveTraders, VerificationLevel2, VerificationLevel3
**Rules**:
- Registrations → VerificationLevel2 → VerificationLevel3 → FTDs → FTDEs → ActiveTraders
- FTDEs = First-Time Deposit Equivalent (likely normalized for multi-currency)
- VerificationLevel2/3 = KYC completion checkpoints (document upload, ID verification)

### 2.2 Financial KPIs (Inferred)

**What**: Complete P&L view per affiliate per month.
**Columns Involved**: FTD Amount, Deposit Amount, Cashout Amount, Full Commission, Rollover Fees, Cost, Invested, Equity, LTV
**Rules**:
- Revenue proxy: Rollover Fees + spread (not explicitly stored)
- Cost: Marketing spend for the affiliate
- LTV: Lifetime value of the affiliate's acquired customers
- Equity: Current portfolio value of affiliate's customers

### 2.3 Monthly Grain with Dimension Slicing

**What**: Monthly report with multiple classification dimensions.
**Columns Involved**: Month, MonthID, Region, Channel, SubChannel, AffiliatesGroupsName
**Rules**:
- Month = varchar(7) text (e.g., '2023-08')
- MonthID = integer key (likely YYYYMM format)
- One row per affiliate × region × channel × sub-channel × month

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Month — optimized for time-range queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Monthly affiliate P&L | Table is empty — check if reporting moved to BI_DB_AffiliateLifeCycle or external BI tool |
| Affiliate funnel conversion | Table is empty — use BI_DB_AffiliateLifeCycle or Marketing Cube outputs |

### 3.3 Common JOINs

None active — table is fully orphaned.

### 3.4 Gotchas

- **Table is empty and fully orphaned**: 0 rows, no SP references
- **Column name with space**: `[FTD Amount]` — requires bracket notation in queries
- **27 columns not 21**: DDL has 27 columns (batch metadata was inaccurate)
- **Decommission candidate**: Strong candidate for removal

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 4 | Inferred from column names and standard eToro affiliate business knowledge | Medium |
| Tier 5 | Standard ETL metadata | Canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Month | varchar(7) | YES | Monthly period in 'YYYY-MM' format (e.g., '2023-08'). Report grain. (Tier 4 — inferred from column name and type) |
| 2 | MonthID | int | YES | Integer month key in YYYYMM format (e.g., 202308). Enables integer comparison for range filtering. (Tier 4 — inferred from naming convention) |
| 3 | Region | nvarchar(500) | YES | Geographic marketing region where the affiliate operates. (Tier 4 — inferred from column name) |
| 4 | AffiliateID | int | YES | Affiliate partner identifier from the fiktivo system. (Tier 4 — inferred from column name) |
| 5 | AffiliatesGroupsName | nvarchar(50) | YES | Affiliate group/tier classification name (e.g., VIP, Standard, Premium). (Tier 4 — inferred from column name) |
| 6 | Channel | nvarchar(500) | YES | Primary marketing channel the affiliate uses (e.g., web, social, display). (Tier 4 — inferred from column name) |
| 7 | SubChannel | nvarchar(500) | YES | Sub-classification within the channel (e.g., Facebook under social, SEO under web). (Tier 4 — inferred from column name) |
| 8 | Contact | varchar(100) | YES | Affiliate manager or account contact person name. (Tier 4 — inferred from column name) |
| 9 | ContractName | varchar(100) | YES | Name of the affiliate's commission contract (e.g., CPA, Revenue Share, Hybrid). (Tier 4 — inferred from column name) |
| 10 | Registrations | int | NO | Number of customer registrations attributed to this affiliate for the month. (Tier 4 — inferred from column name) |
| 11 | FTDs | int | NO | Number of first-time deposits generated by this affiliate. Primary affiliate conversion KPI. (Tier 4 — inferred from column name) |
| 12 | FTDEs | int | NO | First-time deposit equivalents — likely normalized FTD count for multi-currency comparison. (Tier 4 — inferred from column name) |
| 13 | ActiveTraders | int | NO | Number of customers who actively traded during the month (attributed to this affiliate). (Tier 4 — inferred from column name) |
| 14 | VerificationLevel2 | int | NO | Number of customers who completed KYC Level 2 verification (document upload). (Tier 4 — inferred from column name) |
| 15 | VerificationLevel3 | int | NO | Number of customers who completed KYC Level 3 verification (full identity confirmation). (Tier 4 — inferred from column name) |
| 16 | FTD Amount | money | NO | Total monetary value of first-time deposits for this affiliate's customers in the month. (Tier 4 — inferred from column name) |
| 17 | Deposit Amount | decimal(38,2) | NO | Total deposit monetary value for this affiliate's customers in the month. (Tier 4 — inferred from column name) |
| 18 | Cashout Amount | decimal(38,2) | NO | Total withdrawal/cashout monetary value for this affiliate's customers. (Tier 4 — inferred from column name) |
| 19 | Depositing Users | int | NO | Distinct count of users who made at least one deposit in the month. (Tier 4 — inferred from column name) |
| 20 | Cashout Users | int | NO | Distinct count of users who made at least one withdrawal in the month. (Tier 4 — inferred from column name) |
| 21 | Full Commission | money | NO | Total affiliate commission paid for the month (CPA + revenue share combined). (Tier 4 — inferred from column name) |
| 22 | Rollover Fees | decimal(38,2) | NO | Total overnight/rollover fees generated by this affiliate's customers' positions. (Tier 4 — inferred from column name) |
| 23 | Cost | float | NO | Marketing cost/spend for this affiliate for the month. (Tier 4 — inferred from column name) |
| 24 | Invested | money | NO | Total amount invested (open positions) by this affiliate's customers. (Tier 4 — inferred from column name) |
| 25 | Equity | decimal(38,4) | NO | Total portfolio equity of this affiliate's customers at month-end. (Tier 4 — inferred from column name) |
| 26 | LTV | decimal(38,4) | YES | Lifetime value metric for the affiliate's customer cohort. (Tier 4 — inferred from column name) |
| 27 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated. (Tier 5 — standard ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All columns | Unknown | Unknown | No ETL exists — fully orphaned table |

### 5.2 ETL Pipeline

```
Unknown Production Sources (likely aggregation of:
  - fiktivo affiliate system (AffiliateID, Region, Channel, Contract)
  - DWH_dbo dimensions (customer registrations, verifications)
  - Billing facts (deposits, cashouts, commissions)
  - Trading facts (invested, equity, rollover fees)
  - LTV calculations)
  |-- [NO ETL PIPELINE EXISTS — FULLY ORPHANED] ---|
  v
BI_DB_dbo.BI_DB_Affiliate_Report (0 rows — DORMANT)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| AffiliateID | fiktivo affiliate system | Affiliate identifier (theoretical) |

### 6.2 Referenced By (other objects point to this)

No known consumers.

---

## 7. Sample Queries

### 7.1 Verify Table Is Still Empty

```sql
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_Affiliate_Report]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this dormant table.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 26 T4, 1 T5 | Elements: 27/27, Logic: 4/10, Completeness: 7/10*
*Object: BI_DB_dbo.BI_DB_Affiliate_Report | Type: Table | Production Source: Unknown (dormant, orphaned)*
