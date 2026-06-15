# Column Lineage: main.bi_output.positionsvolumeandattributes_lc4_source

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.positionsvolumeandattributes_lc4_source` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\positionsvolumeandattributes_lc4_source.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\positionsvolumeandattributes_lc4_source.json` (rows: 15, mismatches: 8) |
| **Primary upstream** | `main.dwh.dim_position` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.dim_position` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
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
  + main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet   (JOIN)
        │
        ▼
main.bi_output.positionsvolumeandattributes_lc4_source   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `AccountTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `AccountTypeID` | `passthrough` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.AccountTypeID |
| 2 | `CountryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `CountryID` | `passthrough` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.CountryID AS CountryID |
| 3 | `Region` | `—` | `—` | `literal` | — | literal `NULL` — NULL AS Region |
| 4 | `CountryName` | `—` | `—` | `literal` | — | literal `NULL` — NULL AS CountryName |
| 5 | `SellCurrencyID` | `—` | `SellCurrencyID` | `passthrough` | — | bse.SellCurrencyID |
| 6 | `InstrumentType` | `—` | `InstrumentType` | `passthrough` | — | bse.InstrumentType |
| 7 | `IsSettled` | `—` | `IsSettled` | `passthrough` | — | bse.IsSettled |
| 8 | `CID` | `—` | `CID` | `passthrough` | — | bse.CID |
| 9 | `Date_` | `—` | `Date_` | `passthrough` | — | bse.Date_ |
| 10 | `position_event_flag` | `—` | `position_event_flag` | `passthrough` | — | bse.position_event_flag |
| 11 | `Amount_Total` | `—` | `Amount_Total` | `passthrough` | — | bse.Amount_Total |
| 12 | `Amount_lc` | `—` | `Amount_lc` | `passthrough` | — | bse.Amount_lc |
| 13 | `num_position_open_total` | `—` | `num_position_open_total` | `passthrough` | — | bse.num_position_open_total |
| 14 | `num_position_open_lc` | `—` | `num_position_open_lc` | `passthrough` | — | bse.num_position_open_lc |
| 15 | `Club` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `rename` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS Club |

## Cross-check vs system.access.column_lineage

- Total target columns: **15**
- OK: **7**, WARN: **0**, ERROR: **8**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `SellCurrencyID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.sellcurrencyid` | ERROR |
| `InstrumentType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttype` | ERROR |
| `IsSettled` | — | `main.dwh.dim_position.issettled` | ERROR |
| `CID` | — | `main.dwh.dim_position.cid` | ERROR |
| `Date_` | — | `main.dwh.dim_position.closeoccurred`, `main.dwh.dim_position.openoccurred` | ERROR |
| `Amount_Total` | — | `main.dwh.dim_position.amount` | ERROR |
| `Amount_lc` | — | `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.positionid`, `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet.positionid`, `main.dwh.dim_position.amount` | ERROR |
| `num_position_open_lc` | — | `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban_parquet.positionid`, `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet.positionid`, `main.dwh.dim_position.positionid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dp.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban_parquet AS oi ON dp.PositionID = oi.PositionID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bse.CID = fsc.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON dr.DateRangeID = fsc.DateRangeID AND CAST(DATE_FORMAT(bse.Date_, 'yyyyMMdd') AS INT) BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dp.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN main.bi_output.BI_OUTPUT_Finance_Tables_bi_db_positions_closed_to_iban_parquet AS ci ON dp.PositionID = ci.PositionID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bse.CID = fsc.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON dr.DateRangeID = fsc.DateRangeID AND CAST(DATE_FORMAT(bse.Date_, 'yyyyMMdd') AS INT) BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
