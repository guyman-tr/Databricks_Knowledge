# BI_DB_dbo.BI_DB_M_AML_Report_AGG

> 1.23M-row monthly AML aggregated summary table. Pre-grouped companion to BI_DB_M_AML_Report: one row per unique dimension combination per EOM month, with CID = customer COUNT and Wire fields summed. Same SP writes both tables. 28 months of history (2023-12 to 2026-03); ~42K–44K groups per month covering ~5.7M customers in latest EOM.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_M_AML_Report` (#Final_Table intermediate; same SP run) via SP_M_AML_Report |
| **Refresh** | Monthly (EOM parameter). DELETE WHERE EOM + INSERT — replaces target month only, preserves history. Written in same SP execution as BI_DB_M_AML_Report. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Copy Strategy** | — |
| **Business Group** | compliance / AML |

---

## 1. Business Meaning

`BI_DB_M_AML_Report_AGG` is the pre-aggregated companion table to `BI_DB_M_AML_Report`. It reduces the per-customer rows into dimension-grouped summaries, collapsing ~5.7M individual customer rows per EOM month into ~42,000–44,000 unique dimension combinations. This enables efficient group-level AML reporting without scanning the full 144M-row detail table.

**Critical semantic distinction**: The `CID` column in this table is **NOT a customer identifier**. It holds `COUNT(CID)` — the number of customers in each dimension group for the snapshot month. All other dimension columns (Regulation, Country, PlayerStatus, etc.) retain their text values and serve as grouping keys.

The `Wire_Transactions` and `Wire_Amount` columns are the summed totals across all customers in each group (not per-customer values). All other flag columns (Is_FTD, Is_Active, HasWallet, Is_EEA_EU_Country, VerificationLevelID) remain as group-level filters (all customers in a given group share the same flag value because they are part of the GROUP BY).

The table is written in the same SP execution as BI_DB_M_AML_Report, immediately after the per-customer data is loaded. Both tables are refreshed together for each EOM.

As of 2026-03-31: 42,491 dimension groups; 5,711,421 total customers (SUM of CID); largest single group contains 241,814 customers.

---

## 2. Business Logic

### 2.1 Aggregation Logic

The AGG table is produced by `SELECT COUNT(CID) AS CID, [all dimension columns], SUM(Wire_Transactions), SUM(Wire_Amount) FROM #Final_Table GROUP BY [all dimension columns]` within SP_M_AML_Report. The GROUP BY key is the full set of dimension columns: Regulation, AML_Sub_Entity, Country, Is_EEA_EU_Country, PlayerStatus, PlayerStatusReason, Club, RiskGroup, RiskScore, Is_FTD, Is_Active, ScreeningStatus, HasWallet, VerificationLevelID, Prev_Regulation, EOM.

This means each row represents a unique combination of ALL dimension values. Adding or removing any dimension from the GROUP BY would collapse or expand the rows significantly.

### 2.2 Monthly Partitioning

Identical to BI_DB_M_AML_Report: `DELETE WHERE EOM = @EndOfMonth` followed by `INSERT`. Same 28-month history (2023-12-31 to 2026-03-31). Written in the same SP run immediately after the detail table.

### 2.3 All Business Logic Inherited from BI_DB_M_AML_Report

All population logic, risk classification, wire threshold, Is_Active definition, EEA/EU list, and regulation change tracking are identical to `BI_DB_M_AML_Report`. See that table's wiki for details on:
- Population filter (VerificationLevelID 3, or 2 for CySEC)
- RiskGroup = country risk (not customer risk)
- Wire threshold = $150K large wire deposits only
- Is_Active 12-month window (comment/code discrepancy: comment says 3 months)
- Is_EEA_EU_Country = hardcoded 37-country list

### 2.4 Column Order Difference

The column order in BI_DB_M_AML_Report_AGG differs from BI_DB_M_AML_Report in positions 10–12:
- BI_DB_M_AML_Report: ...Is_FTD, **ScreeningStatus**, **HasWallet**, **Is_Active**...
- BI_DB_M_AML_Report_AGG: ...Is_FTD, **Is_Active**, **ScreeningStatus**, **HasWallet**...

This is a cosmetic DDL difference — the data is semantically identical.

---

## 3. Data Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | **Customer COUNT** — number of customers in this dimension group for the EOM month. NOT a customer identifier. Use SUM(CID) to get totals; compare to BI_DB_M_AML_Report.CID which is the actual customer ID. (Tier 2 — SP_M_AML_Report aggregation) |
| 2 | Regulation | varchar(250) | YES | Regulatory framework grouping key. Text name from Dim_Regulation. Dominant: CySEC, FCA, ASIC & GAML, FinCEN+FINRA. (Tier 2 — SP_M_AML_Report) |
| 3 | Country | varchar(250) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name. Grouping key in this table. (Tier 1 — Dictionary.Country) |
| 4 | PlayerStatus | varchar(250) | YES | Player account status text grouping key at EOM. Sourced from Dim_PlayerStatus via Fact_SnapshotCustomer. (Tier 2 — SP_M_AML_Report) |
| 5 | PlayerStatusReason | varchar(250) | YES | Reason text for the player status restriction. Grouping key. NULL for unrestricted customers. (Tier 2 — SP_M_AML_Report) |
| 6 | Club | varchar(250) | YES | Customer loyalty/VIP tier grouping key at EOM. Values: Bronze, Silver, Gold, Platinum, Diamond. (Tier 2 — SP_M_AML_Report) |
| 7 | RiskGroup | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. IsHighRiskCountry is derived from this column. Passthrough from Dim_Country.RiskGroupID. Renamed from RiskGroupID. Grouping key. (Tier 1 — Dictionary.Country) |
| 8 | RiskScore | varchar(250) | YES | Customer-level AML risk text grouping key. Values: Low, Medium, High, NULL. From External_RiskClassification data lake. (Tier 2 — SP_M_AML_Report) |
| 9 | Is_FTD | int | YES | 1 if first deposit was in EOM month. Grouping key flag. (Tier 2 — SP_M_AML_Report) |
| 10 | Is_Active | int | YES | 1 if any qualifying activity within 12 months before EOM (ActionTypeIDs 1–8, 39–40, 42–43). Grouping key flag. See BI_DB_M_AML_Report.md Section 2.5 for 3/12-month discrepancy note. (Tier 2 — SP_M_AML_Report) |
| 11 | ScreeningStatus | varchar(250) | YES | Compliance screening result text grouping key. Values: NoMatch (dominant), PendingInvestigation, PEP, RiskMatch, SanctionsMatch, MultipleMatch, Unknown, NULL. (Tier 2 — SP_M_AML_Report) |
| 12 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Grouping key flag. (Tier 1 — BackOffice.Customer) |
| 13 | Wire_Transactions | int | YES | SUM of approved large wire deposit counts (FundingTypeID=2, ≥$150K) across all customers in this group for the EOM month. 0 if none. (Tier 2 — SP_M_AML_Report) |
| 14 | Wire_Amount | money | YES | SUM of approved large wire deposit amounts (FundingTypeID=2, ≥$150K) across all customers in this group for the EOM month. 0.00 if none. (Tier 2 — SP_M_AML_Report) |
| 15 | Prev_Regulation | varchar(250) | YES | Previous regulation for customers who changed regulation in the EOM month. NULL if no change. Grouping key. (Tier 2 — SP_M_AML_Report) |
| 16 | EOM | date | YES | End-of-month snapshot date. Partition key. Range: 2023-12-31 to 2026-03-31 (28 months). (Tier 5 — ETL metadata) |
| 17 | UpdateDate | datetime | YES | ETL insert timestamp (GETDATE() at run time). All rows in a given month's refresh share the same UpdateDate. (Tier 5 — ETL metadata) |
| 18 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. This table: only values 2 and 3 present (SP population filter). Grouping key. (Tier 1 — BackOffice.Customer) |
| 19 | Is_EEA_EU_Country | int | YES | 1 if customer's country is in EU/EEA (hardcoded 37 DWHCountryIDs in SP). Grouping key flag. (Tier 2 — SP_M_AML_Report) |
| 20 | AML_Sub_Entity | varchar(max) | YES | Comma-separated list of eToro AML sub-entities. Possible values (may be combined): eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta. NULL if no entity applies. Use LIKE '%value%' for filtering. Grouping key. (Tier 2 — SP_M_AML_Report) |

---

## 4. Sample Rows

Sample (mixed EOM months, showing aggregated counts in CID):

| CID (count) | Regulation | Country | PlayerStatus | RiskGroup | RiskScore | Is_Active | ScreeningStatus | HasWallet | Wire_Transactions | Wire_Amount | EOM |
|------------|-----------|---------|-------------|-----------|-----------|-----------|----------------|-----------|-------------------|-------------|-----|
| 1 | FSA Seychelles | Malaysia | Blocked | 0 | Medium | 1 | NoMatch | 0 | 0 | 0 | 2024-02-29 |
| 36 | CySEC | Slovakia | Normal | 0 | Medium | 1 | NoMatch | 1 | 0 | 0 | 2024-03-31 |
| 51 | CySEC | Cote d'Ivoire | Blocked | 1 | Medium | 0 | NoMatch | 0 | 0 | 0 | 2024-01-31 |

_CID = count of customers in each dimension group. Total customers per EOM: ~5.7M (SUM of CID). Rows per EOM: ~42K–44K._

---

## 5. Lineage at a Glance

See `BI_DB_M_AML_Report_AGG.lineage.md` for full column-level lineage.

**ETL Summary:**
- Writer SP: `BI_DB_dbo.SP_M_AML_Report` (same SP as BI_DB_M_AML_Report)
- Intermediate: `#agg_table` temp table (GROUP BY from `#Final_Table`)
- Pattern: DELETE WHERE EOM + INSERT (monthly partition refresh)
- Source: Aggregated from same sources as BI_DB_M_AML_Report

---

## 6. Related Objects

| Object | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_M_AML_Report | BI_DB_dbo | Detail-level companion table. CID = actual customer ID (int). Same SP, same EOM range. |
| SP_M_AML_Report | BI_DB_dbo | Writer SP for both tables. AGG written after detail table in same execution. |
| BI_DB_AML_SubEntity_Categorization | BI_DB_dbo | Upstream source for AML_Sub_Entity. |

---

## 7. Change History

| Date | Author | Change |
|------|--------|--------|
| — | — | Original creation date unknown. SP has no DDL comment. |
| 2023-12-31 | ETL | Earliest EOM partition. |
| 2026-03-31 | ETL | Latest EOM partition in current dataset. |

---

## 8. Open Questions / Caveats

1. **CID = COUNT, Not Customer ID**: The most important semantic caveat. `CID` in this table is `COUNT(CID)` from #agg_table. Any JOIN on CID to a customer table is invalid and will produce wrong results. Use `BI_DB_M_AML_Report` for customer-level analysis.

2. **All Caveats from BI_DB_M_AML_Report Apply**: Is_Active 3/12-month discrepancy, RiskGroup = country risk, Wire threshold $150K hardcoded, Is_EEA_EU_Country hardcoded list, AML_Sub_Entity historical drift — see BI_DB_M_AML_Report.md Section 8 for full detail.

3. **AML_Sub_Entity as GROUP BY Key**: Since AML_Sub_Entity is a multi-value CSV string (e.g., "eToro_Gibraltar, eToro_Money_UK"), GROUP BY on this column treats each unique string as a distinct key. "eToro_Gibraltar, eToro_Money_UK" and "eToro_Money_UK, eToro_Gibraltar" would be separate groups. Use LIKE '%value%' for sub-entity analysis on the detail table instead.

4. **Column Order Differs from M_AML_Report**: Positions 10–12 are swapped (Is_Active ↔ ScreeningStatus/HasWallet). Use column names explicitly; do not rely on positional access.
