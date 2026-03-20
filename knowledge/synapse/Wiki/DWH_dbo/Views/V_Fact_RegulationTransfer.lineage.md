# Column Lineage — DWH_dbo.V_Fact_RegulationTransfer

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| TransferDirection | Computed | `+1` (inbound branch) or `−1` (outbound branch) |
| RegulationID | Fact_RegulationTransfer.ToRegulationID / FromRegulationID | Aliased to unified `RegulationID` per direction |
| Remaining 28 columns | Fact_RegulationTransfer | Direct passthrough in both UNION ALL branches |
