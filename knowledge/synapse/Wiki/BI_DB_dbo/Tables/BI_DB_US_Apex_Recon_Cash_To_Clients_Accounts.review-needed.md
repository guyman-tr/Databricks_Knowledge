# Review Needed: BI_DB_US_Apex_Recon_Cash_To_Clients_Accounts

**Batch:** 36  
**Date:** 2026-04-22  
**Confidence:** High overall; two items need domain confirmation.

## Items for Review

### 1. CashFlowAmount negative sign semantics (MEDIUM confidence)
- **Claim**: CashFlowAmount is always negative when present — represents cash journaled/credited into the Apex account from eToro's perspective (debit to ledger).
- **Evidence**: All non-NULL values in sample data are negative; source is EXT869 Amount SUM.
- **Action**: Confirm with Apex reconciliation team whether "negative = journal credit to account" is the correct interpretation, or whether the sign convention originates from Apex's file format.

### 2. 5GU-prefix accounts (LOW risk)
- **Claim**: 5GU-prefix accounts (e.g., 5GU18555) are institutional or sub-accounts that lack eToro CID/GCID mapping.
- **Evidence**: In sample data, 5GU accounts consistently have NULL CID and GCID.
- **Action**: Confirm with Apex team whether 5GU accounts represent a specific account category (e.g., margin, institutional) and whether they should ever have CID mappings.

### 3. Historical Trade_Amount semantics (DATA QUALITY NOTE)
- **Claim**: Rows before 2021-10-13 capture Buy Amount only (not Net Amount). After 2021-10-13, Trade_Amount = Net Amount (buys + sells net).
- **Evidence**: SP changelog entry: "Trading Amount was changed from Buy Amount to Net Amount" on 2021-10-13.
- **Action**: If comparing Trade_Amount across dates straddling 2021-10-13, filter to ProcessDate >= '2021-10-13' for consistency. Document this break in any downstream reporting that uses historical Trade_Amount.

### 4. FOFAmount vs CashFlowAmount alignment
- **Observation**: In most rows, ABS(CashFlowAmount) ≈ FOFAmount (e.g., -99,531.20 vs 99,531.20). For some accounts, CashFlowAmount and FOFAmount differ (e.g., 3EZ87387: -0.20 vs 0.20; 3EW95384: -13,999.75 vs 13,999.75).
- **Action**: If reconciliation break analysis is needed, the delta between ABS(CashFlowAmount) and FOFAmount is the key metric. No wiki action required — note this for consumers building reconciliation reports.
