# DWH_dbo.Fact_FirstCustomerAction — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Immediate Source** | DWH_dbo.Fact_CustomerAction |
| **Origin** | DWH-internal derivation (not a production import) |
| **ETL SP** | SP_Fact_FirstCustomerAction (two-stage MERGE) |
| **Orchestrator SP** | SP_Fact_FirstCustomerAction_DL_To_Synapse (DELETE + EXEC) |
| **Upstream Wiki** | Fact_CustomerAction.md (documented) |

## Column Lineage

| # | DWH Column | Source Column | Transform | Notes |
|---|-----------|---------------|-----------|-------|
| 1 | GCID | Fact_CustomerAction.GCID | Passthrough | Part of business key |
| 2 | RealCID | Fact_CustomerAction.RealCID | Passthrough | Distribution key |
| 3 | DemoCID | Fact_CustomerAction.DemoCID | Passthrough | |
| 4 | FirstOccurred | Fact_CustomerAction.Occurred | Renamed | First event timestamp |
| 5 | IPNumber | Fact_CustomerAction.IPNumber | Passthrough | |
| 6 | IsReal | Fact_CustomerAction.IsReal | Passthrough | |
| 7 | ActionTypeID | Fact_CustomerAction.ActionTypeID | Passthrough | Part of business key |
| 8 | PlatformTypeID | Fact_CustomerAction.PlatformTypeID | Passthrough | |
| 9 | InstrumentID | Fact_CustomerAction.InstrumentID | Passthrough | Default 0 |
| 10 | Amount | Fact_CustomerAction.Amount | Passthrough | |
| 11 | PositionID | Fact_CustomerAction.PositionID | Passthrough | Default 0 |
| 12 | CampaignID | Fact_CustomerAction.CampaignID | Passthrough | Default 0 |
| 13 | BonusTypeID | Fact_CustomerAction.BonusTypeID | Passthrough | Default 0 |
| 14 | FundingTypeID | Fact_CustomerAction.FundingTypeID | Passthrough | Default 0 |
| 15 | LoginID | Fact_CustomerAction.LoginID | Passthrough | Default 0 |
| 16 | MirrorID | Fact_CustomerAction.MirrorID | Passthrough | Default 0 |
| 17 | WithdrawID | Fact_CustomerAction.WithdrawID | Passthrough | Default 0 |
| 18 | PostID | Fact_CustomerAction.PostID | Passthrough | |
| 19 | CaseID | Fact_CustomerAction.CaseID | Passthrough | Default 0 |
| 20 | UpdateDate | Computed | GETDATE() | ETL timestamp |
| 21 | UpdateDateID | Unknown | — | Not set in SP code |
| 22 | DateID | Fact_CustomerAction.DateID | Passthrough | |
| 23 | TimeID | Fact_CustomerAction.TimeID | Passthrough | |
| 24 | CompensationReasonID | Fact_CustomerAction.CompensationReasonID | Passthrough | Default 0 |
| 25 | WithdrawPaymentID | Fact_CustomerAction.WithdrawPaymentID | Passthrough | Default 0 |
| 26 | DepositID | Fact_CustomerAction.DepositID | Passthrough | |
| 27 | HistoryID | Fact_CustomerAction.HistoryID | Passthrough | Secondary MERGE key |
| 28 | FirstEver | Computed | — | 1 = first MERGE (per GCID+ActionTypeID), 0 = second MERGE (per HistoryID) |
