# Column Lineage: main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_conversionfee_withpositiondata.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_conversionfee_withpositiondata.json` (rows: 27, mismatches: 4) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Positions_Closed_To_IBAN.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Positions_Opened_From_IBAN.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.dim_position` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw   (JOIN)
  + main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban   (JOIN)
  + main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban   (JOIN)
  + main.dwh.dim_position   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `CID` | `passthrough` | — | fca.CID |
| 2 | `GCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GCID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.GCID |
| 3 | `DateID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `DateID` | `passthrough` | — | fca.DateID |
| 4 | `ConversionFee` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `PIPsCalculation` | `rename` | — | fca.PIPsCalculation AS ConversionFee |
| 5 | `TransactionType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `TransactionType` | `passthrough` | — | fca.TransactionType |
| 6 | `IsIBANTrade` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `IsIBANTrade` | `passthrough` | — | fca.IsIBANTrade |
| 7 | `TransactionID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `—` | `unknown` | — | CAST(LEFT(fca.TransactionID, LENGTH(fca.TransactionID) - 1) AS INT) AS TransactionID |
| 8 | `PaymentMethod` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `PaymentMethod` | `passthrough` | — | fca.PaymentMethod |
| 9 | `Amount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `Amount` | `passthrough` | — | fca.Amount |
| 10 | `Currency` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `Currency` | `passthrough` | — | fca.Currency |
| 11 | `AmountUSD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `AmountUSD` | `passthrough` | — | fca.AmountUSD |
| 12 | `ExchangeRate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `ExchangeRate` | `passthrough` | — | fca.ExchangeRate |
| 13 | `BaseExchangeRate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `BaseExchangeRate` | `passthrough` | — | fca.BaseExchangeRate |
| 14 | `Depot` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `Depot` | `passthrough` | — | fca.Depot |
| 15 | `MIDValue` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | `MIDValue` | `passthrough` | — | fca.MIDValue |
| 16 | `IsRecurring` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | `IsRecurring` | `join_enriched` | (Tier 2 — Billing.RecurringDeposit) | fbd.IsRecurring |
| 17 | `PositionID` | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban / main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` | `—` | `coalesce` | — | COALESCE(bdpcti.PositionID, bdpofi.PositionID) AS PositionID |
| 18 | `IsSettled` | `main.dwh.dim_position` | `IsSettled` | `join_enriched` | — | dp.IsSettled |
| 19 | `IsBuy` | `main.dwh.dim_position` | `IsBuy` | `join_enriched` | — | dp.IsBuy |
| 20 | `Leverage` | `main.dwh.dim_position` | `Leverage` | `join_enriched` | — | dp.Leverage |
| 21 | `IsAirDrop` | `main.dwh.dim_position` | `IsAirDrop` | `join_enriched` | — | dp.IsAirDrop |
| 22 | `ExecutionIBANTradeSuccess` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban / main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` | `—` | `case` | — | CASE WHEN COALESCE(bdpcti.PositionID, bdpofi.PositionID) IS NULL AND fca.IsIBANTrade = 1 THEN 0 ELSE 1 END AS ExecutionIBANTradeSuccess |
| 23 | `InstrumentID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentID` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.InstrumentID |
| 24 | `InstrumentTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentTypeID` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.InstrumentTypeID |
| 25 | `InstrumentType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentType` | `join_enriched` | (Tier 2 — SP_Dim_Instrument) | di.InstrumentType |
| 26 | `IsCopy` | `main.dwh.dim_position` | `—` | `case` | — | CASE WHEN dp.MirrorID > 0 THEN 1 ELSE 0 END AS IsCopy |
| 27 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsValidCustomer` | `join_enriched` | — | fsc.IsValidCustomer |

## Cross-check vs system.access.column_lineage

- Total target columns: **27**
- OK: **23**, WARN: **0**, ERROR: **4**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `TransactionID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee.transactionid` | ERROR |
| `PositionID` | — | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban.positionid`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban.positionid` | ERROR |
| `ExecutionIBANTradeSuccess` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee.isibantrade`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban.positionid`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban.positionid` | ERROR |
| `IsCopy` | — | `main.dwh.dim_position.mirrorid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **12**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fca.CID = fsc.RealCID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit AS fbd ON CAST(LEFT(fca.TransactionID, LENGTH(fca.TransactionID) - 1) AS INT) = fbd.DepositID AND fca.TransactionType = 'Deposit'
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw AS fbw ON CAST(LEFT(fca.TransactionID, LENGTH(fca.TransactionID) - 1) AS INT) = fbw.WithdrawPaymentID AND fca.TransactionType = 'Withdraw'
- `LEFT JOIN` — LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban AS bdpofi ON fca.DepositID = bdpofi.DepositID
- `LEFT JOIN` — LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban AS bdpcti ON fca.WithdrawPaymentID = bdpcti.WithdrawPaymentID
- `LEFT JOIN` — LEFT JOIN main.dwh.dim_position AS dp ON COALESCE(bdpcti.PositionID, bdpofi.PositionID) = dp.PositionID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dp.InstrumentID = di.InstrumentID
