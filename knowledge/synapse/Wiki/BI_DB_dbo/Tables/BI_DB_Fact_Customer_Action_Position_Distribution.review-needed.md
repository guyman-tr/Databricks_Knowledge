# BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution — Review Needed

## Tier 4 Items

None — all columns traced to upstream DWH_dbo wikis or SP code.

## Open Questions

1. **IsSettled tier**: Assigned Tier 5 (Expert Review) matching Dim_Position and Fact_CustomerAction wikis. The semantic meaning (1=real, 0=CFD) is well-established but the tier was set by expert review rather than upstream production documentation.
2. **CompensationReasonID filtering**: Only reasons 56, 117, 118 are included for ActionTypeID=36. What do these specific reason codes represent? The BackOffice.CompensationReason dictionary was not queried.
3. **Amount precision**: DDL is decimal(16,6) but Fact_CustomerAction wiki says decimal(11,2). The wider precision in this table may be intentional for fee calculations.

## Corrections for Reviewer

- Fact_SnapshotCustomer columns are tagged Tier 1 from DWH_dbo.Fact_SnapshotCustomer wiki. In the FSC wiki itself, they're marked Tier 2 (ETL-computed in SP_Fact_SnapshotCustomer). From this table's perspective they are passthroughs from a documented DWH_dbo source.
- PositionID description includes DWH note about the compensation extraction logic per the Tier 1 + DWH note pattern.
- SettlementTypeID description includes DWH note about the source switch from FCA to Dim_Position.
