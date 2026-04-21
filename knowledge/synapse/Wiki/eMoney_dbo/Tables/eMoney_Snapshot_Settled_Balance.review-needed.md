# Review Needed: eMoney_dbo.eMoney_Snapshot_Settled_Balance

**Generated**: 2026-04-21  
**Reviewer**: Data Engineering / eToro Money Analytics Team  
**Priority**: Medium

---

## Tier 4 Items (Unverified — Require Business Confirmation)

None. All 27 columns traced to SP code or confirmed via eMoney_Dim_Transaction grouping logic and upstream identity columns.

---

## Open Questions

1. **TxTypeID groupings for MI/MO categories**: The wiki documents CardTx, IBANIn, IBANOut, DirectDebit, and Other as the five channel categories (inferred from column names and sample data). Confirm: what are the exact TxTypeID values that map to each category? For example, does CardTxMO cover TxTypeID IN (1,2,3,4) as in SP_eMoney_Card_Monthly_Snapshot, or a different set? The TxTypeID mapping affects how analysts interpret spikes in OtherMI/OtherMO.

2. **Duplicate rows (~544 AccountIDs with 2+ identical rows)**: Live data shows 1,287,999 total rows vs 1,287,455 distinct AccountIDs. Some AccountIDs appear 2–6 times with fully identical column values. This is a potential SP JOIN bug producing fan-out (possibly a cross-join with eMoney_Currency_Instrument_Mapping_Static or Fact_CurrencyPriceWithSplit). Confirm: is this known? And is downstream analytics on this table aggregating (SUM) rather than selecting rows directly?

3. **SP_eMoney_Snapshot_Settled_Balance orchestration**: The session summary indicates this SP runs as part of Execute_Group_One step 5. Confirm: is it still executed as part of that chain post-Synapse migration, or has it been moved to a separate ADF trigger? The SP must run after eMoney_Dim_Account (step 3) and eMoney_Dim_Transaction (step 4).

4. **DKK (ISO 208) handling**: 431 DKK rows have NULL HolderBalanceCurrency and NULL USDApprox* columns. From eMoney_EntityByCurrencyISO_MappingStatic, DKK entities report in EUR. Confirm: should DKK accounts be included in this snapshot with NULL USD columns (current behaviour), or should they be filtered out, or converted via EUR as their reporting currency?

5. **Historical balance access**: This table retains only one day of data (TRUNCATE+INSERT daily). Confirm: what is the canonical source for multi-day balance history? Is eMoney_Calculated_Balance (stale 2025-06-09) being replaced, or is there another daily balance table in eMoney_dbo that accumulates history?

---

## Validation Flags

- **Duplicate rows are a data quality issue**: 544 AccountIDs appear multiple times with identical column values. This inflates SUM aggregations by the duplication factor. Any downstream query using SUM(HolderBalance) or SUM(TotalMI) without DISTINCT or prior deduplication will overcount.
- **NULL category columns vs. zero**: CardTxMI=NULL does not mean zero card balance — it means the SP did not group any transactions into the card MI bucket. Use `COALESCE(CardTxMI, 0)` in aggregations.
- **DKK rows have no USD approximation**: Filter `WHERE USDApproxBalance IS NOT NULL` when computing USD totals to avoid silent miscount.
- **Single-day table — stale if SP misses**: If the nightly run fails, DateID will be from the previous run. Always check `SELECT MAX(DateID)` before relying on freshness.

---

## Cross-Object Consistency Check

| Shared Column | Source Description (eMoney_Dim_Account or eMoney_Dim_Transaction) | This Wiki Description | Match? |
|--------------|----------------------------------------------|----------------------|--------|
| AccountID | "Auto-incrementing surrogate primary key…" | Verbatim copy | YES |
| GCID | "Global Customer ID. Identifies the customer…" | Verbatim copy | YES |
| CID | "Customer ID - platform-internal primary key…" | Verbatim copy | YES |
| HolderBalance | SUM(HolderAmount, TxStatusID=2) concept | Consistent with eMoney_Dim_Transaction definition | YES |

---

*Review generated: 2026-04-21 | Object: eMoney_dbo.eMoney_Snapshot_Settled_Balance*
