# Review Needed: Dealing_dbo.Dealing_Apex_PnL_EE

## 1. Stale Data — Pipeline Status Unknown

The Apex LP pipeline has not loaded data since **2024-06-08** (last row date 2024-06-07). It is unclear whether:
- Apex Clearing remains eToro's active US equities LP
- The pipeline was intentionally decommissioned or is blocked by an operational issue
- Downstream consumers have migrated to alternative data sources

**Action**: Confirm with Middle Office / Dealing team whether this pipeline is expected to resume or should be marked as deprecated.

## 2. No Tier 1 Inheritance

All 8 columns are Tier 2 (SP code). The upstream sources are Apex LP external staging tables (`LP_APEX_EXT981_3EU`, `LP_APEX_EXT869_3EU`, `LP_APEX_EXT869_3EU`) which have no wiki documentation. This is expected -- LP external files are not part of the standard DWH upstream wiki ecosystem.

## 3. NULL Equity_End Rate (14%)

739 out of 5,130 rows (14%) have NULL `Equity_End`. This may indicate missing Apex equity files for certain dates/accounts. Confirm whether these NULLs represent genuine data gaps or expected behavior (e.g., accounts closed mid-week, holidays without LP files).

## 4. Dividends Not in PnL Formula

The SP computes `PnL = Equity_End - Equity_Start - Transfers` but does **not** include Dividends in the formula. Dividends are stored as a separate informational column. This differs from the per-symbol tables where dividend impact is captured within the PnL bridge. Confirm this is intentional (dividends are already reflected in Equity_End).

## 5. UC Target Pending

No Unity Catalog target has been configured for this table. Given the stale status, confirm whether UC migration is planned or if this table should be excluded from the UC export pipeline.

---

*Generated: 2026-04-28 | Object: Dealing_dbo.Dealing_Apex_PnL_EE | Regen attempt: 1*
