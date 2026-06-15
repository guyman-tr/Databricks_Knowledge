# Column Lineage: main.bi_output.vg_acquisitionfunnel_em1

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_acquisitionfunnel_em1` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_acquisitionfunnel_em1.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_acquisitionfunnel_em1.json` (rows: 17, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Reports_AcquisitionFunnel.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel   ←── primary upstream
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account   (JOIN)
        │
        ▼
main.bi_output.vg_acquisitionfunnel_em1   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `CID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | a.CID /* Identifiers */ |
| 2 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `GCID` | `passthrough` | (Tier 1 — dbo.FiatAccount) | a.GCID |
| 3 | `Country_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `Country` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.Country AS Country_as_of_yesterday /* Customer attributes (as of yesterday) */ |
| 4 | `Club_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `Club` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.Club AS Club_as_of_yesterday |
| 5 | `IsValidForFunnel_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IsValidForFunnel` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IsValidForFunnel AS IsValidForFunnel_as_of_yesterday /* Funnel & verification flags (as of yesterday) */ |
| 6 | `IsVerifiedFTD_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IsVerifiedFTD` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IsVerifiedFTD AS IsVerifiedFTD_as_of_yesterday |
| 7 | `IsVerifiedFTDPlus2Weeks_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IsVerifiedFTDPlus2Weeks` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IsVerifiedFTDPlus2Weeks AS IsVerifiedFTDPlus2Weeks_as_of_yesterday |
| 8 | `IsActiveMIMO_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IsActiveMIMO` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IsActiveMIMO AS IsActiveMIMO_as_of_yesterday |
| 9 | `HasEMoneyAccount_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IseMoneyAccount` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IseMoneyAccount AS HasEMoneyAccount_as_of_yesterday |
| 10 | `IsFMI_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IsFMI` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IsFMI AS IsFMI_as_of_yesterday /* FMI / FMO / Card flags (by yesterday) */ |
| 11 | `IsFMO_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IsFMO` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IsFMO AS IsFMO_as_of_yesterday |
| 12 | `IsCardCreated_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IsCardCreated` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IsCardCreated AS IsCardCreated_as_of_yesterday |
| 13 | `IsCardActivated_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IsCardActivated` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IsCardActivated AS IsCardActivated_as_of_yesterday |
| 14 | `IsCardFirstTx_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` | `IsCardFirstTx` | `rename` | (Tier 2 — SP_eMoney_Reports_Daily) | a.IsCardFirstTx AS IsCardFirstTx_as_of_yesterday |
| 15 | `AccountSubProgram_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `AccountSubProgram` | `join_enriched` | (Tier 2 — SP_eMoney_Dim_Account) | b.AccountSubProgram AS AccountSubProgram_as_of_yesterday /* eMoney account program (as of yesterday) */ |
| 16 | `AccountSubProgramID_as_of_yesterday` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `AccountSubProgramID` | `join_enriched` | (Tier 1 — dbo.FiatAccount) | b.AccountSubProgramID AS AccountSubProgramID_as_of_yesterday |
| 17 | `eMoneyAccountCreateDate` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `AccountCreateDate` | `join_enriched` | (Tier 2 — SP_eMoney_Dim_Account) | b.AccountCreateDate AS eMoneyAccountCreateDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **17**
- OK: **17**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **3**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account AS b ON a.CID = b.CID AND b.GCID_Unique_Count = 1 AND b.IsValidETM = 1 AND b.IsValidCustomer = 1
