# BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **PlayerStatus tier**: Assigned Tier 2 (SP_Dictionaries_DL_To_Synapse) since the Dim_PlayerStatus upstream wiki may classify Name as Tier 2. Verify against the actual Dim_PlayerStatus wiki.
2. **Equity is point-in-time**: Equity is captured once when the customer is first detected. Should it be refreshed daily for existing records?
3. **PlayerStatusID exclusions**: PlayerStatusID 2 and 4 are excluded — what statuses do these represent, and is this filter still correct?
4. **Accumulation without deduplication**: If a customer's US mailing address is removed and re-added, they would not be re-detected (already in table). Is this the intended behavior?
