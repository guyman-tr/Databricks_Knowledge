# Review Needed: BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level

## Items Requiring Human Verification

### HIGH Priority

1. **RegTransferDirection semantics confirmed** — The dual-row pattern (direction=1 receiving, -1 sending on regulation-transfer days) is documented in the SP header comment and explicitly in the SP code. Verify that `NEVER GROUP BY CID AND Regulation` rule is correctly propagated to all downstream documentation and analytics using this table.

2. **TotalZero reconciliation expectation** — The wiki states TotalZero should net ~zero. Confirm with Finance/CMR team whether this is a hard invariant (always exactly zero within rounding) or an approximate check (small deviations expected due to partial-close adjustments).

3. **TicketFeeByPercentOnOpen data type** — `decimal(38,18)` vs `money` for OnClose is an inconsistency. Confirm with Guy Manova whether this was intentional (different precision requirements) or an oversight.

### MEDIUM Priority

4. **TanganyStatus NULL semantics** — Wiki states NULL = non-Tangany client. This was inferred from the code (sourced from `BI_DB_Client_Balance_CID_Level_New` with no ISNULL fallback). Confirm with Adi Meidan or Guy Manova that NULL is the correct representation for non-Tangany clients (not a join miss).

5. **CommissionVersion values** — Only value `2` observed in the sample row. Confirm whether `1` (legacy) still exists in the table for historical dates or if all rows now carry version 2.

6. **SettlementTypeID values** — SettlementTypeID is a GROUP BY key in the final aggregation but the wiki does not enumerate its values. Check `DWH_dbo.Dim_SettlementType` for the value dictionary and add inline if ≤15 values.

7. **IsC2P definition** — `CompensationReasonID=134` in `External_Bronze_etoro_Trade_AdminPositionLog` is identified as Copy-to-Portfolio. Confirm with the compensation team that CompensationReasonID=134 exclusively identifies C2P positions.

### LOW Priority

8. **Transition field future use** — Always `NoTransition` since at least 2023-01-01. Confirm whether this field has any planned future use or can be considered permanently dormant.

9. **US_State population** — US_State is from `Dim_State_and_Province WHERE CountryID=219`. Confirm: (a) CountryID=219 is definitively the US, and (b) US clients without a known state get NULL vs a default state value.

10. **IsSQF positions scope** — Code filters `OpenDateID >= 20250601` for SQF positions. Confirm whether pre-June-2025 SQF positions are excluded from IsSQF=1 intentionally (the function still scans all historical positions via `BI_DB_dbo.Function_Revenue_TicketFeeByPercent(20250601, @DateID, 0)` for TicketFeeByPercent but the SQF temp table filters to OpenDateID >= 20250601).

## Columns with T3/T4 Confidence

None — all column descriptions are T2 (SP-derived, code-verified). No T3/T4 inferences were necessary.

## Data Quality Observations

- `RegTransferDirection = -1` rows: 142 rows on 2026-04-12 (very small population). If TotalZero checks fail, this population is the most likely source.
- `InstrumentType = NULL` rows: 0 observed (good — all positions have valid instrument resolution).
- `TanganyStatus` cardinality is higher than expected (7 values including NULL) — `Pending` had only 4 rows on 2026-04-12, may be transient.
