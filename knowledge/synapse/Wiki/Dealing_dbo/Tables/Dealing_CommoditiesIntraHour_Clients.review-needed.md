---
object: Dealing_CommoditiesIntraHour_Clients
schema: Dealing_dbo
review_status: Pending
batch: 14
---

# Review Checklist — Dealing_CommoditiesIntraHour_Clients

## Automated Confidence Flags

| Flag | Detail |
|------|--------|
| ⚠️ HedgeServer transition | Changed HS=127→HS=225 on 2025-04-23 (SR-310993). Pre/post continuity gap may exist. Was HS=127 data deleted or retained? |
| ⚠️ Price smearing | Weekend rows use last known price up to 5 days prior — BidFirst/AskFirst may be stale on weekends |
| ⚠️ Instrument mapping | SP uses Oil=17, Gold=18, NatGas=19, Silver=22, Copper=96. Confirm these are still accurate against Dim_Instrument. |
| ℹ️ Instrument 150/151 | Priced from Gold (22) by convention — confirm this is still current in active SP version |
| ℹ️ Conversion instruments | Instruments added via PortfolioConversionConfigurations. Full list may expand over time. |

## Questions for Reviewer

1. When HS changed from 127 to 225 in Apr 2025, was historical data from HS=127 retained in this table, or is there a continuity break?
2. Are instruments 150/151 still active and still priced from Gold? The SP comment attributes this but may have changed.
3. Does "IsValidCustomer = 1" reflect the current business definition for valid customers?
4. Are all PortfolioConversionConfiguration instruments documented, or do new ones get added without wiki update?
5. Instrument ID mapping: confirm Oil=17, Gold=18, NatGas=19, Silver=22, Copper=96 vs Dim_Instrument.

## Reviewer Corrections
<!-- Add corrections here. Format: FIELD: old value → new value. Mark [RESOLVED] when fixed. -->
