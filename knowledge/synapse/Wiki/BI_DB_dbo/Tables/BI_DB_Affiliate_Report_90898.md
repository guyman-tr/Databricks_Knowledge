# BI_DB_dbo.BI_DB_Affiliate_Report_90898

> **DORMANT — 0 rows, no writer SP, fully orphaned.** 11-column customer-level affiliate report table, likely created for a specific affiliate (ID 90898). Tracks customer lifecycle from registration through first deposit, trading activity, cashouts, chargebacks, and commission. ROUND_ROBIN with CLUSTERED INDEX on RealCID. No stored procedure in Synapse SSDT reads or writes this table.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no writer SP in SSDT, no references |
| **Refresh** | **DORMANT** — no active ETL process |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **Row Count** | 0 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Affiliate_Report_90898` appears to be a **customer-level report table created for a specific affiliate** (likely affiliate ID 90898). Unlike the parent `BI_DB_Affiliate_Report` which aggregates monthly metrics per affiliate, this table tracks individual customers (RealCID) attributed to this specific affiliate, with their registration date, first deposit, trading activity, cashout behavior, chargeback history, and commission earned.

The "90898" suffix strongly suggests this is a **per-affiliate custom report** — a common pattern where high-value or strategic affiliates receive dedicated tracking tables. The SubSerialID column (varchar(1024)) suggests tracking sub-accounts or tracking parameters used by the affiliate.

The table is currently **empty (0 rows)** and has **no writer SP or references** in the Synapse SSDT repository. The affiliate relationship has likely ended or the reporting was moved elsewhere.

---

## 2. Business Logic

### 2.1 Customer Lifecycle Tracking (Inferred)

**What**: Tracks each customer's progression from registration to active trading.
**Columns Involved**: RegisteredReal, FirstDepositDate, FirstDepositAmount, PositionOpen
**Rules**:
- RegisteredReal = date customer opened a real-money account
- FirstDepositDate = date of first deposit (FTD milestone)
- PositionOpen = likely count of positions opened (activity indicator)

### 2.2 Risk Indicators (Inferred)

**What**: Tracks negative customer behaviors that affect affiliate commission.
**Columns Involved**: Cashout_request, Chargeback, Commission
**Rules**:
- Cashout_request = number of withdrawal requests (or flag)
- Chargeback = credit card chargeback count (or flag) — can trigger commission clawback
- Commission = affiliate commission for this specific customer

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on RealCID — optimized for customer-level lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Activity for affiliate 90898's customers | Table is empty — check alternative reporting |

### 3.3 Common JOINs

None active — table is fully orphaned.

### 3.4 Gotchas

- **Table is empty and fully orphaned**: 0 rows, no SP references
- **Affiliate-specific table**: 90898 suffix means this only tracked one affiliate's customers
- **SubSerialID**: varchar(1024) — unusually wide, may hold URL tracking parameters or compound identifiers
- **Decommission candidate**: Per-affiliate tables are high candidates for removal

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 4 | Inferred from column names and affiliate domain knowledge | Medium |
| Tier 5 | Standard ETL metadata | Canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Original customer ID (the real/root CID before any migration or merge). One row per customer attributed to affiliate 90898. (Tier 4 — inferred from naming convention) |
| 2 | Country | varchar(50) | YES | Customer's country of registration. (Tier 4 — inferred from column name) |
| 3 | SubSerialID | varchar(1024) | YES | Sub-account serial identifier or affiliate tracking parameter. Unusually wide (1024 chars) suggests URL parameters or compound tracking codes. (Tier 4 — inferred from column name and type) |
| 4 | RegisteredReal | datetime | YES | Date when the customer registered a real-money account (as opposed to virtual/demo). (Tier 4 — inferred from column name) |
| 5 | FirstDepositDate | datetime | YES | Date of the customer's first deposit (FTD milestone) after registration. (Tier 4 — inferred from column name) |
| 6 | FirstDepositAmount | money | YES | Monetary value of the customer's first deposit. (Tier 4 — inferred from column name) |
| 7 | PositionOpen | int | YES | Count of positions opened by this customer (trading activity indicator). (Tier 4 — inferred from column name) |
| 8 | Cashout_request | int | NO | Count of withdrawal/cashout requests made by this customer. High values may indicate risk. (Tier 4 — inferred from column name) |
| 9 | Chargeback | int | NO | Count of credit card chargebacks for this customer. Chargebacks can trigger affiliate commission clawback. (Tier 4 — inferred from column name) |
| 10 | Commission | float | YES | Affiliate commission amount earned for acquiring this customer. May be clawed back on chargebacks. (Tier 4 — inferred from column name) |
| 11 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated. (Tier 5 — standard ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All columns | Unknown | Unknown | No ETL exists — fully orphaned table |

### 5.2 ETL Pipeline

```
Unknown Production Sources (likely aggregation of:
  - Customer registration (RealCID, Country, RegisteredReal)
  - Billing system (FirstDepositDate, FirstDepositAmount, Cashout)
  - Trading system (PositionOpen)
  - Payment disputes (Chargeback)
  - Affiliate commission system (Commission))
  |-- [NO ETL PIPELINE EXISTS — FULLY ORPHANED] ---|
  v
BI_DB_dbo.BI_DB_Affiliate_Report_90898 (0 rows — DORMANT)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension (theoretical) |

### 6.2 Referenced By (other objects point to this)

No known consumers.

---

## 7. Sample Queries

### 7.1 Verify Table Is Still Empty

```sql
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_Affiliate_Report_90898]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this dormant affiliate-specific table.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 10 T4, 1 T5 | Elements: 11/11, Logic: 4/10, Completeness: 7/10*
*Object: BI_DB_dbo.BI_DB_Affiliate_Report_90898 | Type: Table | Production Source: Unknown (dormant, orphaned)*
