# Column Lineage: main.bi_output.vg_positionsvolumeandattributes_lc4_source

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_positionsvolumeandattributes_lc4_source` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_positionsvolumeandattributes_lc4_source.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_positionsvolumeandattributes_lc4_source.json` (rows: 15, mismatches: 11) |
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
main.bi_output.vg_positionsvolumeandattributes_lc4_source   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `AccountTypeID_as_of_position_date` | `main.dwh.dim_position` | `AccountTypeID` | `rename` | — | AccountTypeID AS AccountTypeID_as_of_position_date |
| 2 | `Region_as_of_position_date` | `main.dwh.dim_position` | `Region` | `rename` | — | Region AS Region_as_of_position_date |
| 3 | `CountryName_as_of_position_date` | `main.dwh.dim_position` | `CountryName` | `rename` | — | CountryName AS CountryName_as_of_position_date |
| 4 | `SellCurrencyID` | `main.dwh.dim_position` | `SellCurrencyID` | `passthrough` | — | SellCurrencyID |
| 5 | `InstrumentType` | `main.dwh.dim_position` | `InstrumentType` | `passthrough` | — | InstrumentType |
| 6 | `IsSettled` | `main.dwh.dim_position` | `IsSettled` | `passthrough` | — | IsSettled |
| 7 | `CID` | `main.dwh.dim_position` | `CID` | `passthrough` | — | CID |
| 8 | `position_event_date` | `main.dwh.dim_position` | `Date_` | `rename` | — | Date_ AS position_event_date |
| 9 | `position_event_flag` | `main.dwh.dim_position` | `position_event_flag` | `passthrough` | — | position_event_flag |
| 10 | `Amount_Total` | `main.dwh.dim_position` | `Amount_Total` | `passthrough` | — | Amount_Total |
| 11 | `Amount_lc` | `main.dwh.dim_position` | `Amount_lc` | `passthrough` | — | Amount_lc |
| 12 | `num_positions_total` | `main.dwh.dim_position` | `num_positions_total` | `passthrough` | — | num_positions_total |
| 13 | `num_positions_lc` | `main.dwh.dim_position` | `num_positions_lc` | `passthrough` | — | num_positions_lc |
| 14 | `Club_as_of_position_date` | `main.dwh.dim_position` | `Club` | `rename` | — | Club AS Club_as_of_position_date |
| 15 | `HasEMoneyAccount` | `main.dwh.dim_position` | `HasEMoneyAccount` | `passthrough` | — | HasEMoneyAccount |

## Cross-check vs system.access.column_lineage

- Total target columns: **15**
- OK: **2**, WARN: **11**, ERROR: **0**, INFO: **2**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `AccountTypeID_as_of_position_date` | `main.dwh.dim_position.accounttypeid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.accounttypeid` | WARN |
| `Region_as_of_position_date` | `main.dwh.dim_position.region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country.region` | WARN |
| `CountryName_as_of_position_date` | `main.dwh.dim_position.countryname` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country.name` | WARN |
| `SellCurrencyID` | `main.dwh.dim_position.sellcurrencyid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.sellcurrencyid` | WARN |
| `InstrumentType` | `main.dwh.dim_position.instrumenttype` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttype` | WARN |
| `position_event_date` | `main.dwh.dim_position.date_` | `main.dwh.dim_position.closeoccurred`, `main.dwh.dim_position.openoccurred` | WARN |
| `Amount_Total` | `main.dwh.dim_position.amount_total` | `main.dwh.dim_position.amount` | WARN |
| `Amount_lc` | `main.dwh.dim_position.amount_lc` | `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.positionid`, `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet.positionid`, `main.dwh.dim_position.amount` | WARN |
| `num_positions_lc` | `main.dwh.dim_position.num_positions_lc` | `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.positionid`, `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet.positionid`, `main.dwh.dim_position.positionid` | WARN |
| `Club_as_of_position_date` | `main.dwh.dim_position.club` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel.name` | WARN |
| `HasEMoneyAccount` | `main.dwh.dim_position.hasemoneyaccount` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account.cid` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **0**

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
