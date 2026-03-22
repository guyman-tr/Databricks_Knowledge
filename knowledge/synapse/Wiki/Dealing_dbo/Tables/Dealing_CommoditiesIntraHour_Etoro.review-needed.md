---
object: Dealing_CommoditiesIntraHour_Etoro
schema: Dealing_dbo
review_status: Pending
batch: 14
---

# Review Checklist — Dealing_CommoditiesIntraHour_Etoro

## Automated Confidence Flags

| Flag | Detail |
|------|--------|
| ⚠️ HedgeServer transition | Changed HS=225 Apr 2025 (SR-310993). Historical LP account IDs/names may differ. |
| ⚠️ Netting table usage | SP uses both External_Etoro_Hedge_Netting and etoro_History_Netting_History — confirm which applies to Units_NOP vs ValueRealized |
| ⚠️ LiquidityAccountID scope | How many distinct LP accounts appear post-SR-310993? Is it always one per instrument? |
| ℹ️ Instrument mapping | Same set as Clients (Oil=17, Gold=18, NatGas=19, Silver=22, Copper=96). Confirm accuracy. |

## Questions for Reviewer

1. Do both External_Etoro_Hedge_Netting and etoro_History_Netting_History feed into Units_NOP, or does one feed Units_NOP and the other ValueRealized?
2. Are there multiple LiquidityAccountIDs per instrument (multiple LPs), or always one per commodity?
3. When HS changed to 225, did LP account names/IDs change? Is there a mapping of old vs new account IDs?
4. ValueRealized: is this the LP-side realized, or does it cross-reference client realized (Realized from Clients table)?

## Reviewer Corrections
<!-- Add corrections here. Format: FIELD: old value → new value. Mark [RESOLVED] when fixed. -->
