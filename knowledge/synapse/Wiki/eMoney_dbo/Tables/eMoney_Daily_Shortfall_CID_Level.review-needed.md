# Review Needed — eMoney_dbo.eMoney_Daily_Shortfall_CID_Level

**Generated**: 2026-04-21  
**Wiki Quality**: 8.8/10  
**Reviewer**: eMoney Data Analytics Team  

---

## Tier 4 Items

None. All 18 columns are Tier 2 — direct from eMoneyClientBalance or computed from its columns with full SP code evidence.

---

## Open Questions

1. **EtoroDeposits filter intent**: The SP filters `EtoroDeposits > 0` to exclude accounts with no eToro deposits. Is this `EtoroDeposits` the cumulative lifetime total or the daily deposit value? If it's daily, an account with a zero-deposit day but a prior history would be excluded from shortfall reporting for that day. Clarification would affect completeness of regulatory coverage.

2. **Date range start — 2024-01-01**: The earliest observed data is 2024-01-01. Was this table created in 2024? If shortfall monitoring existed before Synapse migration, was it stored elsewhere? Is there a pre-2024 history that should be backfilled?

3. **Shortfall column sign convention**: All values are negative by definition (SP filter ensures this). Downstream consumers should be aware that Shortfall represents a deficit magnitude as a negative number, not an absolute value. Any reporting using `ABS(Shortfall)` will flip the sign — is that the expected usage pattern in Tableau/Power BI dashboards?

4. **HASH(CID) distribution**: Queries filtering by Date (not CID) will perform a full distributed scan. If most production queries filter by date range (e.g., "show me all overdrawn accounts this week"), a ROUND_ROBIN or date-partitioned design might be more efficient. Is the current distribution intentional?

5. **UpdateDate nullability**: UpdateDate is NULL-able here. In practice, will it ever be NULL? The INSERT always calls `GETDATE()` — the column should never be NULL post-insert. Consider adding a NOT NULL constraint at the next DDL revision.

6. **Entity coverage**: Only 3 entities appear in recent data (UK, Malta, AUS). Does this reflect the current rollout footprint, or are other entities (e.g., Lithuania, Cyprus) filtered out earlier in the eMoneyClientBalance pipeline?

---

## Cross-Object Consistency Checks

| Column | Checked Against | Result |
|--------|----------------|--------|
| Entity | eMoney_Aggregated_Tribe_Balance | CONSISTENT — same entity codes (826=UK, 978=Malta, 36=AUS) |
| CurrencyIson | eMoney_EntityByCurrencyISO_MappingStatic | CONSISTENT — ISO 4217 numeric codes match known entity-currency pairs |
| DateID / Date | eMoneyClientBalance.BalanceDateID / BalanceDate | RENAMED (no value mismatch) — DateID ← BalanceDateID, Date ← BalanceDate |
| Shortfall formula components | SP_eMoney_Daily_Shortfall_CID_Level.sql | ALL 10 components verified from SELECT list in SP code |
