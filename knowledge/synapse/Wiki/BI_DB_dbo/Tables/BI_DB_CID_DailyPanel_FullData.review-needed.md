# Review Needed: BI_DB_dbo.BI_DB_CID_DailyPanel_FullData

> Items requiring human review, verification, or future investigation.

---

## HIGH PRIORITY

### 1. Daily_Classification Column Status

**Issue**: `Daily_Classification` (mapped from `EOD_Segment`) is an empty string for ALL rows across 2025–2026 data, including for the entire 2025 year (sampled at 2025-01-01: 5.2M rows, all empty). Historical 2019 data shows values like "Traders", "Crypto". The SP explicitly sets `EOD_Segment = NULL` and depends on `SP_CID_DailyPanel_UpdateCluster` to update it post-insert.

**Questions**:
1. Is `SP_CID_DailyPanel_UpdateCluster` still scheduled and running? Or was it decommissioned post-Synapse migration?
2. If deprecated: should the column be removed from the table DDL and documentation?
3. If still operational: what is the cluster assignment source (was it `BI_DB_CID_DailyCluster`, which the SP comment says was removed in April 2021)?

**Impact**: Any analytics or reports using `Daily_Classification` as a segment filter are getting blank results.

---

### 2. Revenue_Total Formula Completeness

**Issue**: The Revenue_Total formula includes `Revenue_Other` from `BI_DB_DailyCommisionReport` where `InstrumentID = -1`. This represents trades on instrument ID -1 (likely a legacy/catch-all instrument). The documentation covers this as part of the total but it's not documented as a standalone column.

**Questions**:
1. Is Revenue_Other material in size? Should it be exposed as a standalone column?
2. What does InstrumentID=-1 represent in current data?

---

### 3. ACC_ChurnDays Semantics Confirmation

**Issue**: `ACC_ChurnDays` increments by 1 each day where `IsFunded_New=0` and `@date > FirstNewFundedDate`. It resets to 0 when `IsFunded_New=1`. This definition means it counts "days since becoming unfunded" — but the exact business definition of "churn" should be confirmed.

**Questions**:
1. Is ACC_ChurnDays = "consecutive days with no active funding" or "days since first funded but currently unfunded"?
2. Does it reset across all customers on their re-funding date, or only for the specific customer?
3. Are there downstream reports or SLAs that depend on this metric?

---

## MEDIUM PRIORITY

### 4. OpsDB Priority Inconsistency

**Issue**: `SP_CID_DailyPanel_FullData` is listed as Priority 0 in OpsDB, but it reads from `BI_DB_CIDFirstDates` (produced by `SP_CIDFirstDates` at Priority 90) and `BI_DB_DailyCommisionReport` (Priority 20). A Priority 0 SP reading Priority 20/90 outputs appears contradictory.

**Possible explanations**:
- `BI_DB_CIDFirstDates` is a slowly-changing reference table that may not need to be refreshed daily for FullData's purpose
- Priority in OpsDB may reflect a different orchestration layer than assumed
- The Priority 0 designation may be stale metadata

**Action needed**: Confirm with Data Engineering whether this SP correctly runs after Priority 20 dependencies complete.

---

### 5. AirDrop Position Handling

**Issue**: `IsAirDrop=1` positions are excluded from `Active_Real_Stocks`, `Active_Real_Crypto` (flagged in SP comments as "non-AirDrop" condition). But `ActiveOpen_AirDrop` captures them separately. The `ActiveOpen` aggregate also explicitly excludes AirDrop.

**Questions**:
1. What are AirDrop positions? Are they promotional crypto awards?
2. Should AirDrop positions be included or excluded in any revenue/PnL columns?
3. AirDrop seems to only affect Active/ActiveOpen flags — does it affect NewTrades_Real_Stocks, NewTrades_Real_Crypto, PnL_Real_*, Revenue_Real_* counts? Based on SP code, NewTrades counts do NOT filter out AirDrop (no IsAirDrop check in #ActiveOpen NewTrades SUM). Is this intentional?

---

### 6. IsOTD Definition

**Issue**: `IsOTD` is described as "One Trade Done" but the SP logic checks `ActionTypeID=7` (which is Deposit, not a trade). The comment in the SP says "One Trade Done" but the implementation queries deposits (AT=7).

**Questions**:
1. Is IsOTD measuring "made exactly one deposit" or "made exactly one trade"?
2. Should it be renamed to IsOTD_Deposit or similar for clarity?
3. Confirm ActionTypeID=7 = Deposit in DWH_dbo.Dim_ActionType.

---

### 7. Revenue_IslamicFees Components

**Issue**: `Revenue_IslamicFees = Function_Revenue_AdminFee + Function_Revenue_SpotAdjustFee`. These two functions are documented as separate fee types:
- AdminFee: Islamic account admin fee (weekend/Islamic fee charge)
- SpotAdjustFee: Spot price adjustment fee

**Question**: Are both always charged together (i.e., are they both zero for non-Islamic accounts), or can SpotAdjustFee be non-zero for non-Islamic customers?

---

## LOW PRIORITY

### 8. Companion SP Usage

**Issue**: Three companion SPs exist alongside the main SP:
- `SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE`
- `SP_BI_DB_CID_DailyPanel_FullData_SWITCH`
- `SP_CID_DailyPanel_FullData_ofir` (development/test SP by Ofir)

**Questions**:
1. When are the SWITCH SPs used? For historical backfill only, or as part of normal daily orchestration?
2. Should `SP_CID_DailyPanel_FullData_ofir` be cleaned up (untracked dev SP)?

---

### 9. UC Migration Status

**Issue**: UC Target is `_Not_Migrated`. Given this is a 183-column, 64.5M rows/day table in the primary CRM panel family, it likely has high demand for UC migration.

**Questions**:
1. Is there a UC migration plan for BI_DB_CID_DailyPanel_FullData?
2. Would the UC target be a full copy or a view/aggregate?
3. Given the PII columns (CID, AccountManager, Channel, AffiliateID, Country), would masking be required?

---

### 10. Historical Partition UpdateDate Pattern

**Observation**: All rows with DateID=20190101 (from TOP 10 sample) have UpdateDate=2021-04-21. This confirms that historical partitions were bulk-loaded/refreshed in April 2021 during the initial BI_DB_CID_DailyPanel_FullData backfill. The data itself is historically accurate but UpdateDate does not reflect the original ETL date for pre-2021 rows.

**Note for users**: Do not use UpdateDate for historical data freshness assessment prior to April 2021.

---

### 11. BI_DB_V_DDR_Daily_Panel Dependency

**Issue**: `CashoutsAdjusted` is sourced from `BI_DB_V_DDR_Daily_Panel` (a view/table in BI_DB_dbo). This creates a dependency on the DDR pipeline for a column in the FullData table. DDR objects are known to have long refresh times.

**Question**: Does `BI_DB_V_DDR_Daily_Panel` complete before SP_CID_DailyPanel_FullData runs at Priority 0? The DDR SP runs at Priority 60+. This seems like another Priority ordering inconsistency.

---

*Generated: 2026-04-23 | Batch 67 | Pipeline: DWH Semantic Documentation v2*
