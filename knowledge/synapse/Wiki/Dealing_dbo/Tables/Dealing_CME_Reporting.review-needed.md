---
object: Dealing_CME_Reporting
review_type: completeness
priority: low
---

# Review Notes — Dealing_CME_Reporting

## Items Needing Confirmation

1. **Crude oil instrument names**: The SP normalizes crude oil futures to `'Crude Oil Future'` via a name pattern. The exact pattern string is not documented here — confirm what display names get collapsed (e.g., "Crude Oil (WTI)", "Brent Crude Oil Future").

2. **SR-303463 instrument additions**: Three InstrumentIDs (380, 381, 382) were added 2025-03-05. Their display names are not confirmed — verify against `DWH_dbo.Dim_Instrument` if needed.

3. **Volume units**: `Monthly_Volume` is USD-approximated (Dim_Position.Volume = AmountInUnitsDecimal × InitForexRate × USD conversion). For futures, this may not equal notional contract value — confirm if CME expects notional or USD volume.

4. **Customer filter**: IsValidCustomer=1 is applied — does CME reporting require all clients including test/internal accounts, or only valid retail clients? Confirm scope with Dealing/Compliance.

## No Blocking Issues

Table is well-understood with clear regulatory purpose. All columns traced to SP logic. Low priority review.
