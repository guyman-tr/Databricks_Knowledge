# Review Needed: BI_DB_US_Stocks_Apex_PFOF

**Batch:** 36  
**Date:** 2026-04-22  
**Confidence:** High overall; table name is misleading.

## Items for Review

### 1. Table name misleading — options data included (HIGH visibility)
- **Claim**: Despite being named "US_Stocks_Apex_PFOF", the table contains both equity (82%) and options (18%) PFOF records.
- **Evidence**: Confirmed via live query: `SELECT InstrumentType, COUNT(*) FROM ... GROUP BY InstrumentType` returns 'Equity' and 'Option'.
- **Action**: Confirm with US reporting team that options coverage is intentional and whether the table name should be updated (e.g., "US_Securities_Apex_PFOF"). Any consumer filtering "all PFOF" from this table without an InstrumentType filter is including options — which may or may not be desired.

### 2. CustomerPFOFPayback sign convention (CONFIRM)
- **Claim**: CustomerPFOFPayback is always ≤ 0 (max value = 0.00). Negative = cost to eToro / payment made to customer.
- **Evidence**: `MIN = -253.47, MAX = 0.00` from live count query; consistent with PFOF payback being an outflow from eToro's books.
- **Action**: Confirm with finance team that this is the intended sign convention. If downstream reports sum this column, the total will be negative = total PFOF paid out. This is correct but easy to misinterpret.

### 3. Description field format (LOW risk, documentation only)
- **Claim**: The Description column format "MAKER_Strategy_Type" is sourced directly from Apex EXT1047. Common market maker codes: JANE=Jane Street, SIG=Susquehanna International Group, Citadel, WATERSHED, LIQPOINT.
- **Action**: If a complete market maker codebook exists in Confluence or Apex documentation, link it to this wiki. Current documentation is derived from data patterns only.

### 4. InstrumentID NULL for ~3.9% of equity rows
- **Claim**: ~12,419 equity rows (3.9% of 2026 YTD equities) have NULL InstrumentID, likely because their CUSIP from EXT872 is not in Dim_Instrument.
- **Action**: No immediate action — these are likely newer or less-common instruments not yet in the eToro instrument catalog. If InstrumentID is used for joins in downstream reports, consumers should handle NULL InstrumentID gracefully.
