# Dealing_dbo.Dealing_LP_StocksNOP — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all descriptions derived from SP code analysis (Tier 2).

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| Real/CFD server mapping | Is the hardcoded list of Real servers (3,9,102,112,125,126,81) still accurate? When new hedge servers are added, is this SP updated? | Hardcoded in SP, no dynamic lookup |
| LP_VolumeBuy/Sell | Why is LP volume only tracked for HedgeServerID=81? Is this the only server with execution log data, or is it a deliberate filter? | SP code: `WHERE el.HedgeServerID = 81` — explicit filter |
| Excluded servers | What are servers 101, 221, 223-226, 5000? Are they test/internal/deprecated servers? | `WHERE h.HedgeServerID NOT IN (101, 221, 223, 224, 225, 226, 5000)` in #LP creation |
| OPShort sign | Are negative OPShort values intentional for LP positions? The formula `(2*IsBuy-1)` yields -1 for shorts, making the value negative. Client table uses ABS() instead. | Live data confirms negative values, e.g. `-23448056.1378` |

## Structural Questions

| Question | Context |
|----------|---------|
| Is this table analyzed alongside Dealing_ClientsCapitalAdequacy and Dealing_NOP_LPandClients as a trio? | All three populated by related SPs, all in same priority tier |
| The FX conversion to CurrencyID=1 (USD) — is CurrencyID=1 always USD? | Assumed from code; needs confirmation from Dim_Currency reference |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
