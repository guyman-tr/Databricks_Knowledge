# Dealing_dbo.Dealing_Staking_Parameters — Review Needed

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Columns Needing Clarification

| Column | Question | Evidence |
|--------|----------|----------|
| LiquidityBuffer | Is this the fraction reserved or the fraction available for staking? | Values 0.60-1.00. If buffer=1.00 for ETH, does that mean 100% is buffered (no staking) or 100% is available? |
| InstrumentID 100xxx | Are these the same InstrumentIDs used in Dim_Instrument? | 100xxx range not observed in standard Dim_Instrument. May be a separate instrument registry for staking. |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
