# Review Flags: BI_DB_Compliance_Surveillance_ShortTermTrades

## Flag 1 — Parameter Change History (INFO)
SP has been modified twice: `@min_num_trades` changed from 5 → 1 (2024-06-13), `@max_roundtrip_duration` changed from 180 → 300 minutes (2024-06-13). The current thresholds are very permissive — effectively any position closed within 5 hours qualifies. This means the table is broad surveillance data, not a pre-filtered short-list of suspicious cases.

## Flag 2 — DesignatedRegulationID vs RegulationID (SOFT)
This table uses `DesignatedRegulationID` for the Regulation column, unlike most BI_DB surveillance tables that use the primary `RegulationID`. For the ~7 regulations with designated overrides, the Regulation column shows the override entity, not the primary one. Consumers should be aware of this discrepancy when cross-referencing with other tables.

## Flag 3 — Empty String Sentinels (SOFT)
`ClientVerificationLevel3Date`, `ParentVerificationLevel3Date`, and `ParentCID` use empty string `''` as the null sentinel (not SQL NULL). Filtering for null-like values requires `WHERE col = ''` or `LEN(col) = 0`, not `IS NULL`. This inconsistency with SQL NULL conventions can cause bugs in downstream joins or aggregations.

## Flag 4 — Rolling Window Only (SOFT)
Table contains only yesterday's (last working day) positions — no historical accumulation. If Compliance needs a trend view or the batch fails one day, that day's data is permanently lost. Consider whether a history/archive table is needed.

## Flag 5 — PII Exposure (INFO)
Contains LastName, Postcode, LastIPAddress — moderate-sensitivity PII. IP address in particular can be used for geolocation. Dynamic data masking recommended in UC migration.

## Flag 6 — Postcode Placeholder Values (INFO)
Observed postcode values "99999" and "00000" indicate placeholder/unknown postcodes from Dim_Customer.Zip. These should be treated as NULL in postcode-based analysis.

## Flag 7 — InstrumentTypeID Scope (INFO)
SP filters on `InstrumentTypeID IN (5, 6)`. Based on SP author comment and live data (all samples show InstrumentType = "Stocks"), type 5 appears to be Stocks. Type 6 is likely ETFs — but no ETF rows observed in current data sample. Verify whether InstrumentTypeID=6 is active in production.
