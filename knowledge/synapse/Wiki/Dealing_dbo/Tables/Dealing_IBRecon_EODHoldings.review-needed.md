# Review Needed — Dealing_IBRecon_EODHoldings

**Generated**: 2026-03-21
**Quality Score**: 7.8/10

## Items for Human Review

1. **HS 121 — stopped 2024-04-15** — Live data shows HedgeServerID 121 with a last date of 2024-04-15. Confirm whether this HS was decommissioned and whether historical rows are retained for audit purposes or should be excluded from active reporting.

2. **Reality vs Supposed columns** — `IB_Reality_Units` vs `IB_Supposed_Units` (and the diff) are unique to the IB recon. Confirm the business definition: is "Supposed" the units IB should hold based on eToro's hedge orders, or units IB reports as the expected position?

3. **ClientAccountID** — Appears in the IB tables but not BNY/GS. Confirm what IB entity/account this maps to and whether it corresponds to the IB prime brokerage account number.

4. **IsBuy (bit)** — Direction stored as a bit flag rather than 'Buy'/'Sell' varchar used in BNY/GS tables. Confirm this is intentional and how downstream consumers interpret it.
