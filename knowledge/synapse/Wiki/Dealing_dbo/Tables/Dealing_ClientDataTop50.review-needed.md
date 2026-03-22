---
object: Dealing_ClientDataTop50
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_ClientDataTop50 — Review Notes

## Auto-Generated Flags

- **rn column type is bigint**: The rank column (1–50) is declared as bigint — unusually large for a rank. Confirm this is correct and not an artifact of the ROW_NUMBER() OVER(...) window function output.
- **InstrumentTypeID filter**: Same as ClientDataFinal — only Stocks/Indices/Commodities (4,2,1). FX/Crypto top traders are not tracked here.
- **percentageOfAvgDailyVolume**: Confirm denominator — is it total AvgDailyVolume for the instrument from ClientDataFinal, or recomputed inline? If recomputed, may differ slightly.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
