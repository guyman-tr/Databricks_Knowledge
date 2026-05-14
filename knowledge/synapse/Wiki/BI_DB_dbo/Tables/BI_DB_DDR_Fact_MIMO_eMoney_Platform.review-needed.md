# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform — Review Needed

## Tier 4 / Open Questions

1. **`IsIBANQuickTransfer` vs SP body** — Header comment (2025-06-16) references **MoveMoneyReason = 6** for eMoney “Internal Transfer”, but `INSERT` hard-codes `0 AS IsIBANQuickTransfer` and there is **no** `MoveMoneyReasonID` predicate in the procedure. Should the SP be updated, or should AllPlatforms / Confluence text stop claiming MoveMoneyReasonID=6 for this column until implemented?

2. **`TxTypeID = 8` withdraw rows** — Author notes these are **trade open** on the fiat side and may be removed from DDR MIMO. Confirm with product/DA whether withdraw `TxTypeID IN (8,6)` remains the long-term contract.

3. **Unity Catalog export** — Sampled Databricks catalog listed `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` but **no** dedicated `..._mimo_emoney_platform` table. Confirm whether eMoney MIMO is lake-only via AllPlatforms / another path, or under a different `gold_` name.

4. **`IsRedeem` downstream wording** — `BI_DB_DDR_Fact_MIMO_AllPlatforms.md` still describes `IsRedeem` on the unified table as “eMoney balance redeemed to bank account.” This conflicts with **this** SP (always 0) and with **`Fact_CustomerAction`** semantics. **Do not change sibling wikis in this task** — flag for a separate AllPlatforms regeneration pass.

5. **PII mirror** — `SHOW TABLES IN main.pii_data LIKE '*emoney*platform*'` returned **0** rows (2026-05-14). Confirm whether a PII clone is required for this fact or only for AllPlatforms / customer joins.

## Reviewer Checklist

- [ ] Spot-check 5 random `TransactionID` values: Synapse row vs `eMoney_Fact_Transaction_Status` source for same `DateID`.
- [ ] Confirm `ReferenceNumber = '-1'` sentinel volume is acceptable for analysts.
- [ ] Re-run UC discovery when export naming is finalized.

## Phase 16 — Adversarial Notes (generator self-critique)

- **Strengths**: `IsRedeem` and `IsCryptoToFiat` grounded with **verbatim** SQL fragments; eMoney vs TP differences called out for `IsInternalTransfer`.
- **Risks**: `CurrencyID` Tier 1 description copied from `Dim_Currency.md` with **dual join** note — if strict transitivity purists require Tier 2 for any SP-branched column, downgrade #11 to Tier 2 in a follow-up.
