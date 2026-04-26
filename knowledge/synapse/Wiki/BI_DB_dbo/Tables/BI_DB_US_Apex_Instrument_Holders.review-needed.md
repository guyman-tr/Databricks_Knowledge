# Review Needed: BI_DB_US_Apex_Instrument_Holders

**Batch:** 36  
**Date:** 2026-04-22  
**Confidence:** High overall; two items need domain confirmation.

## Items for Review

### 1. InstrumentName format (MEDIUM confidence)
- **Claim**: InstrumentName is `Dim_Instrument.Name` and appears as "NVDA/USD" format (internal name), not the consumer display name.
- **Evidence**: SP code uses `di.Name AS 'InstrumentName'`; sample data from top holders on 2026-04-12 shows "NVDA" symbol with USD pairing consistent with this format.
- **Action**: Confirm with US equities team whether downstream consumers expect internal name or display name here. If display name is needed, `Dim_Instrument.InstrumentDisplayName` should be used instead.

### 2. GCID source (LOW risk, confirm if discrepancy found)
- **Claim**: GCID is sourced from `External_USABroker_Apex_UserData.GCID`, not from Dim_Customer.
- **Risk**: For edge-case Apex accounts, the GCID from Apex external data may differ from the GCID in the customer dimension. If reconciliation issues arise, check GCID source alignment.
- **Action**: Low priority — only investigate if reporting discrepancies surface.

### 3. Short position coverage (CONFIRM)
- **Claim**: Only long positions (IsBuy=1) are included. Short positions are excluded.
- **Action**: Confirm with Apex reporting team that no short-position reporting is expected from this table. If shorts need to be tracked, a separate table or SP modification would be required.

### 4. SP author unknown
- **Note**: The SP `SP_US_Apex_Instrument_Holders` has no author header. Other Apex SPs (SP_US_Apex_Recon_Cash_To_Clients_Accounts, SP_US_Stocks_Apex_PFOF, SP_US_Stocks_MAU_DAU_KPI) are authored by Artyom Bogomolsky. Ownership unclear — may be same author without header.
- **Action**: No documentation impact; note for maintenance contacts.
