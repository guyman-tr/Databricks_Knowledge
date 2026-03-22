---
object: Dealing_dbo.Dealing_DailySpread_ModeFrequency
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_DailySpread_ModeFrequency

## Auto-Generated Flags

- [ ] **`Daily_EtoroSpread_ModeFrequency` units**: Column is `float` — confirm if this is a raw count of times the mode appeared or a frequency fraction (0–1). Description will need updating.
- [ ] **`DailyPPSpread_DividedByEtoroSpread` formula**: Documented as DailyAvg_PPSpread / DailyAvg_EtoroSpread — confirm exact formula from SP. What happens when DailyAvg_EtoroSpread = 0?
- [ ] **Two rows per instrument per day**: Confirm `SpreadType` only ever takes 'Open' and 'Close' — no other values.
- [ ] **`char` column padding**: `InstrumentName`, `InstrumentType`, `SpreadType` use CHAR(50) — this means whitespace-padded values. Flag for downstream consumers using = comparisons without RTRIM.
- [ ] **Start date Mar 2024**: Confirm why data starts March 2024 — is this when the SP was deployed or when the source data became available?

## Reviewer Corrections

<!-- Add corrections here. -->
