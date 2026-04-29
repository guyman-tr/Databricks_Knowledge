# BI_DB_dbo.Compliance_BI_Leverage_Dashboard — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code.

## Questions for Reviewer

1. **InstrumentTypeID 999 = forex**: The SP maps 'forex' (from ResourceName) to 999 but there's no InstrumentTypeID=999 in Dim_Instrument. Is this intentional as a catch-all?
2. **CM JOIN logic**: The SP joins #seperate to #cm on `ISNULL(ss.InstrumentID, cm.InstrumentTypeID) = ISNULL(cm.InstrumentID, cm.InstrumentTypeID)`. This effectively self-joins CM when no specific instrument is targeted. Is this producing correct results?
3. **Settings_Default_Value as varchar(1000)**: Why is a leverage value stored as varchar? Are there non-numeric values in this field?
4. **No UpdateDate column**: Unlike most BI_DB tables, this one has no UpdateDate. Is the Date column sufficient for tracking freshness?
