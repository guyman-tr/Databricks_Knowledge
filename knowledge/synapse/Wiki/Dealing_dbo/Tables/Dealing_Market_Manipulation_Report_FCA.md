# Dealing_dbo.Dealing_Market_Manipulation_Report_FCA

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_Market_Manipulation_Report_FCA |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `Date` |
| **Columns** | 18 |
| **Primary Source** | Multi-source: DWH_dbo.Dim_Position, DWH_dbo.V_Liabilities, DWH_dbo.Fact_SnapshotCustomer, BI_DB_dbo.BI_DB_PositionPnL |
| **ETL SP** | `Dealing_dbo.SP_Market_Manipulation_Report_FCA` |
| **Refresh** | Daily per @dd date |
| **PII** | YES — contains CID, UserName, Country, Manager |
| **Tags** | dealing, market-manipulation, compliance, surveillance, fca, pnl, nop, top-traders |

---

## 1. Business Meaning

`Dealing_Market_Manipulation_Report_FCA` is the **FCA-scoped variant** of `Dealing_Market_Manipulation_Report`. It uses identical schema and produces the same multi-KPI leaderboard structure (top/bottom PnL, equity, NOP, short-duration trades) but restricts the customer universe to **FCA-regulated customers only** (RegulationID=2).

The FCA table is maintained separately from the main report because the FCA regulator (UK Financial Conduct Authority) has specific surveillance and reporting obligations that require a dedicated, regulator-scoped view of dealing activity. Using `Fact_SnapshotCustomer` + `Dim_Range` for regulation lookup (rather than `Dim_Customer.RegulationID` directly) ensures historical accuracy when the SP is run retroactively.

**Key differences from `Dealing_Market_Manipulation_Report`:**
1. **FCA-only**: `DWHRegulationID=2` applied to both customer universe and NOP position filter
2. **Historical regulation via snapshot**: Uses `Fact_SnapshotCustomer` joined to `Dim_Range` for regulation, not `Dim_Customer.RegulationID` — captures what regulation a customer was under AT @dd
3. **No GURU KPIs**: The `GURU_YDay_Profit` and `GURU_WTD_Profit` segments (Popular Investor copy PnL) are absent from this SP
4. **ROUND_ROBIN distribution** (vs HASH(CID) in the main table)

**SP Author**: Jenia (2019-10-17); Synapse migration 2024 (SR-243935).

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per Date

`SP_Market_Manipulation_Report_FCA(@dd)` follows the same pipeline as `SP_Market_Manipulation_Report` with the following FCA-specific modifications:

#### Customer Universe (`#temp`)

Joins `Dim_Customer` to `Fact_SnapshotCustomer` + `Dim_Range` (where `@yesterdayINT BETWEEN FromDateID AND ToDateID`) and `Dim_Regulation` to get the **historical regulation at @dd**. Filters: `IsValidCustomer=1`, equity ≥ $100, **and `DWHRegulationID=2` (FCA only)**.

#### Position Universe (`#positions`)

Same structure and duration filter (≤48h/72h/96h by weekday) as the main SP. MirrorID=0, valid customers only.

#### NOP Computation (`#All_Positions`, `#Nop_*`)

Also filters: `DWHRegulationID=2` applied at the customer join. Stocks variants present (`#Nop_Stocks`, `#Nop_CIDs_Stocks`).

#### Short-Duration Trades (`#10Min`)

Same as main SP: top 100 customers with profitable positions ≤10 min duration.

#### KPI Segments (subset of main table — no GURU KPIs)

| KPI | Description |
|-----|-------------|
| `PnLs_YDay_Gain`, `PnLs_WTD_Gain`, `PnLs_MTD_Gain`, `PnLs_YTD_Gain` | Top 100 by realized gain rate per period |
| `PnLs_YDay_Profit`, `PnLs_YDay_Loss` | Top/Bottom 100 by yesterday PnL |
| `PnLs_WTD_Profit`, `PnLs_WTD_Loss` | Top/Bottom 100 by WTD PnL |
| `PnLs_MTD_Profit`, `PnLs_MTD_Loss` | Top/Bottom 100 by MTD PnL |
| `PnLs_YTD_Profit`, `PnLs_YTD_Loss` | Top/Bottom 100 by YTD PnL |
| `YDay_Equity` | Top 100 by yesterday equity |
| `YDay_NOP_Instruments` | Top 100 instruments by NOP (FCA customers) |
| `YDay_NOP_Stocks` | Top 100 stocks by NOP (FCA customers) |
| `YDay_NOP_By_Inst_CID` | Top 100 customer×instrument by NOP |
| `YDay_NOP_By_Stock_CID` | Top 100 customer×stock by NOP |
| `10Min_Trades_YDay` | Top 100 customers by yesterday short-duration profitable trades |
| `10Min_Trades_WTD` | Top 100 customers by WTD short-duration profitable trades |

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `Dealing_dbo.Dealing_Market_Manipulation_Report` | `Date, KPI, CID` | Same structure; FCA-scoped variant |
| `DWH_dbo.Dim_Position` | `PositionID, CID` | Position universe |
| `DWH_dbo.Dim_Customer` | `RealCID` | Valid customer filter + demographics |
| `DWH_dbo.Fact_SnapshotCustomer` | `RealCID, DateRangeID` | Historical regulation at @dd |
| `DWH_dbo.Dim_Range` | `DateRangeID` | Date range for snapshot validity |
| `DWH_dbo.Dim_Regulation` | `DWHRegulationID` | Regulation filter (=2, FCA only) |
| `DWH_dbo.V_Liabilities` | `CID, DateID` | Yesterday equity |
| `DWH_dbo.Dim_Country` | `CountryID` | Country, Desk, Region |
| `DWH_dbo.Dim_Manager` | `ManagerID` | Account manager |
| `DWH_dbo.Dim_PlayerLevel` | `PlayerLevelID` | Club tier |
| `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument metadata |
| `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted` | `InstrumentID` | Last price for NOP |
| `BI_DB_dbo.BI_DB_PositionPnL` | `PositionID, DateID` | Open position mark-to-market PnL |

---

## 4. Elements

All 18 columns are identical in type and semantics to `Dealing_Market_Manipulation_Report`. See that table's Elements section for full descriptions.

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Market_Manipulation_Report_FCA)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Notes vs Main Table |
|---|---------|------|----------|---------------------|
| 1 | Date | date | NOT NULL | Same |
| 2 | KPI | varchar(50) | NOT NULL | Same values EXCEPT no `GURU_*` KPIs |
| 3 | Equity | money | YES | Same |
| 4 | PnL | money | YES | Same |
| 5 | Gain | decimal(16,8) | YES | Same |
| 6 | InstrumentName | varchar(max) | YES | Same |
| 7 | PositionID | bigint | YES | Always NULL (same as main) |
| 8 | NOP | money | YES | Same formula; FCA customers only |
| 9 | RN | int | YES | Same |
| 10 | CID | bigint | YES | FCA customers only. PII |
| 11 | UserName | varchar(max) | YES | PII |
| 12 | Club | varchar(100) | YES | PII |
| 13 | Desk | varchar(100) | YES | PII |
| 14 | Region | varchar(100) | YES | PII |
| 15 | Country | varchar(100) | YES | PII |
| 16 | Manager | varchar(100) | YES | PII |
| 17 | Regulation | varchar(100) | YES | Always 'FCA' (or equivalent for RegulationID=2) |
| 18 | UpdateDate | datetime | NOT NULL | ETL metadata |

---

## 5. Usage Notes

**Always 'FCA' in Regulation column**: Since the filter is `DWHRegulationID=2`, all rows will have the same Regulation value. This column is included for structural consistency with the main table.

**Historical regulation accuracy**: Unlike the main table (which uses `Dim_Customer.RegulationID` — current regulation), the FCA table uses `Fact_SnapshotCustomer` + `Dim_Range` — the regulation as of `@dd`. This matters for historical back-fills where customers may have changed regulation since.

**No GURU rows**: Do not query for `GURU_*` KPI values — they don't exist in this table. Use `Dealing_Market_Manipulation_Report` filtered to Regulation='FCA' for GURU data if needed.

**Data staleness**: Max date in live sample is 2025-07-12 (vs 2026-03-10 for main table). Confirm whether this table is still actively refreshed.

**ROUND_ROBIN distribution**: Unlike the main table (HASH on CID), this table uses ROUND_ROBIN. Always filter on Date first.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Dim_Position, Fact_SnapshotCustomer, V_Liabilities, BI_DB_PositionPnL |
| **Refresh** | Daily per date via `SP_Market_Manipulation_Report_FCA(@dd)` |
| **SP Author** | Jenia (2019-10-17); Synapse migration 2024 (SR-243935) |
| **Last Modified** | Dec 2024 (SR-283378: removed hardcoded InstrumentID 1000–99999 filter) |
| **PII** | YES — CID, UserName, Country, Manager, Club, Desk, Region |
| **Compliance** | FCA-specific market manipulation surveillance |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 3/5 | Sample confirmed; max date 2025-07-12 — potentially stale |
| SP Logic | 4/5 | Full SP analyzed (919 lines); differences from main SP documented |
| Upstream Wiki | 2/5 | Multi-source; shared sources with main table |
| Business Context | 2/5 | Atlassian MCP unavailable; FCA-scoped purpose inferred from SP |
| **Total** | **7.2/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
