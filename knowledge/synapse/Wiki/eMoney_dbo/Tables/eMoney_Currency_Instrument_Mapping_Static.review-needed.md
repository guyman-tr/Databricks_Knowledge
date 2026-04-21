# Review Needed: eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static

**Generated**: 2026-04-21 | **Batch**: 13 | **Reviewer**: TBD

## Tier 4 Items (Require Verification)

None — all 10 columns are Tier 2 (manual static load; no upstream wiki or ETL SP to trace). Descriptions are inferred from column names and live data sampling.

## Tier 2 Items Requiring Business Context Confirmation

| Column | Question |
|--------|----------|
| BuyCurrencyID / SellCurrencyID | Internal DWH currency IDs (e.g., 5=AUD, 2=EUR). Confirm the full mapping of these internal IDs to ISO codes — no named source table found in DDL |
| Currency (all 21) | Confirm all 21 currencies and 145 FX pairs are still active and complete for current eToro Money operations (data is 3+ years old) |
| RUB (Russian Ruble) | 2 RUB instrument pairs present. Confirm whether RUB should remain in the mapping or be retired |

## Known Flags / Anomalies

- **Static data — never refreshed**: All 145 rows were loaded manually on 2022-11-21. No ETL SP writes to this table. If eToro Money has added currencies or instruments since 2022, this table will not reflect them.
- **InstrumentID = DWHInstrumentID**: Identical values confirmed for all 145 rows from live data. Redundant column retained for SP compatibility. Consider removing in a future cleanup after assessing all SP dependencies.
- **No Generic Pipeline export**: No confirmed Gold (UC) export pipeline. This table is consumed only via SP JOIN logic. If UC consumers need it, a pipeline must be created.
- **ROUND_ROBIN HEAP at 145 rows**: Trivially small for ROUND_ROBIN distribution. Not a performance issue at current scale, but worth noting for any future architectural review.
- **USD dominates**: USD appears in 52 of 145 instrument pairs (36% of all rows). Queries joining on Currency='USD' should account for the fan-out.

## Reviewer Checklist

- [ ] Confirm all 21 currencies and 145 FX pairs are still current and complete
- [ ] Confirm RUB (Russian Ruble) pairs should be retained or removed
- [ ] Identify the named DWH table that maps BuyCurrencyID / SellCurrencyID to ISO codes (not found in DDL)
- [ ] Confirm InstrumentID = DWHInstrumentID is permanently by design and document if so
- [ ] Assess whether a UC export pipeline is needed: `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_instrument_mapping_static`
- [ ] Confirm the table is still in active use by SP_eMoney_Dim_Account, SP_eMoney_Snapshot_Settled_Balance, SP_eMoney_Calculated_Balance
- [ ] Determine if an automated refresh process should replace the manual load pattern
