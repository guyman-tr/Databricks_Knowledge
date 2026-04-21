# Review Needed — eMoney_dbo.eMoney_Aggregated_Tribe_Balance

**Generated**: 2026-04-21
**Wiki Quality**: 8.9/10
**Reviewer**: eMoney Data Analytics Team

---

## Tier 4 Items (Low-Confidence — Requires Business Review)

None. All 28 columns are Tier 2 (SP code evidence) or Tier 3 (naming convention). No Tier 4 items.

---

## Open Questions

1. **EpmMethodID semantics**: The `EpmMethodID` column is passed directly from ETL_AccountSnapshot but is NULL in most rows visible in the sample. What are the valid values and their business meaning? Is there a Dictionary table for this field?

2. **CASS reporting usage**: Is `CASSBalances` directly used in regulatory CASS returns to the FCA? Or is it only an internal monitoring metric? This affects how strictly the "should be zero NegativeBalances" expectation should be enforced.

3. **BalanceDateID as distribution key**: The HASH(BalanceDateID) distribution means all rows for a given day land on the same distribution node. Given 67,580 total rows across ~800 days, this is ~85 rows/day on average — not ideal for parallelism. Was this intentional? A ROUND_ROBIN or HASH(Entity) might perform better for cross-date queries.

4. **SP_eMoney_Aggregated_Tribe_Balance not in Execute_Group_One**: The orchestration SP has all other eMoney SPs but not this one. It appears to be scheduled separately. What is its current schedule? Daily? When relative to ETL_AccountSnapshot population?

5. **"eToro Money AUS" entity added 2025-09-28**: The SP history notes Lior added AUS entity. Were there backfilled historical rows for AUS from before this date? The minimum BalanceDate is 2024-01-31 — does AUS data start only from 2025-09-28?

---

## Corrections from Previous Documentation

None — first-time documentation.

---

## Cross-Object Consistency Checks

| Column | Also in | Verified Match? |
|--------|---------|----------------|
| AccountSubProgramID | eMoney_Dictionary_AccountSubProgram | FK confirmed; inline values not repeated here (>15 values) |
| CurrencyIson | eMoney_Currency_Mapping_ISO | ISO 4217 numeric codes consistent (36=AUD, 208=DKK, 826=GBP, 978=EUR) |
| Entity | eMoney_EntityByCurrencyISO_MappingStatic | 3 entities (UK/Malta/AUS) confirmed from live query |
