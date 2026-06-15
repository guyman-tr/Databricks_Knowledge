# Column Lineage: main.bi_output.vg_positionsvolumeandattributes_lc4_source_test1

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_positionsvolumeandattributes_lc4_source_test1` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_positionsvolumeandattributes_lc4_source_test1.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_positionsvolumeandattributes_lc4_source_test1.json` (rows: 15, mismatches: 0) |
| **Primary upstream** | `main.dwh.dim_position` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.dim_position` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Account.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet.md` |

## Lineage Chain

```
main.dwh.dim_position   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account   (JOIN)
  + main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet   (JOIN)
        │
        ▼
main.bi_output.vg_positionsvolumeandattributes_lc4_source_test1   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `passthrough` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountTypeID |
| 2 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Region` | `passthrough` | (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse) | c.Region |
| 3 | `CountryName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `rename` | (Tier 1 - Dictionary.Country upstream wiki) | c.Name AS CountryName |
| 4 | `SellCurrencyID` | `—` | `SellCurrencyID` | `passthrough` | — | bse.SellCurrencyID |
| 5 | `InstrumentType` | `—` | `InstrumentType` | `passthrough` | — | bse.InstrumentType |
| 6 | `IsSettled` | `—` | `IsSettled` | `passthrough` | — | bse.IsSettled |
| 7 | `CID` | `—` | `CID` | `passthrough` | — | bse.CID |
| 8 | `Date_` | `—` | `Date_` | `passthrough` | — | bse.Date_ |
| 9 | `position_event_flag` | `—` | `position_event_flag` | `passthrough` | — | bse.position_event_flag |
| 10 | `Amount_Total` | `—` | `—` | `coalesce` | — | COALESCE(bse.Amount_Total, 0) AS Amount_Total |
| 11 | `Amount_lc` | `—` | `—` | `coalesce` | — | COALESCE(bse.Amount_lc, 0) AS Amount_lc |
| 12 | `num_positions_total` | `—` | `—` | `coalesce` | — | COALESCE(bse.num_positions_total, 0) AS num_positions_total |
| 13 | `num_positions_lc` | `—` | `—` | `coalesce` | — | COALESCE(bse.num_positions_lc, 0) AS num_positions_lc |
| 14 | `Club` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `rename` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS Club |
| 15 | `HasEMoneyAccount` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | `—` | `case` | — | CASE WHEN NOT ema.CID IS NULL THEN 1 ELSE 0 END AS HasEMoneyAccount |

## Cross-check vs system.access.column_lineage

- Total target columns: **15**
- OK: **11**, WARN: **0**, ERROR: **0**, INFO: **4**  ✓

## Lost / added columns

- Computed/added columns vs primary: **1**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dp.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet AS oi ON dp.PositionID = oi.PositionID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bse.CID = fsc.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON dr.DateRangeID = fsc.DateRangeID AND CAST(DATE_FORMAT(bse.Date_, 'yyyyMMdd') AS INT) BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS c ON fsc.CountryID = c.CountryID
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account AS ema ON bse.CID = ema.CID AND ema.GCID_Unique_Count = 1 AND ema.IsValidCustomer = 1
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dp.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet AS ci ON dp.PositionID = ci.PositionID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bse.CID = fsc.RealCID
