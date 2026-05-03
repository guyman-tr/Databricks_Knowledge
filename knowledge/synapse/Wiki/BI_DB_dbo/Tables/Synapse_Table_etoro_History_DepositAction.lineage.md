# Lineage: BI_DB_dbo.Synapse_Table_etoro_History_DepositAction

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship | Notes |
|---|--------------|-------------|--------|----------|-------------|-------|
| 1 | History.DepositAction | Table | History | etoro | Bronze passthrough | Production source. Exported via Generic Pipeline (Append, daily) to Bronze parquet. COPY INTO loads into this Synapse table. |
| 2 | SP_Create_Synapse_Table_etoro_History_DepositAction | Stored Procedure | BI_DB_dbo | Synapse | Writer | Drops and recreates the table via COPY INTO from Bronze parquet files. |
| 3 | SP_AllDeposits | Stored Procedure | BI_DB_dbo | Synapse | Reader | Reads latest ResponseID per DepositID, joins with Dictionary_Response, feeds BI_DB_AllDeposits. |
| 4 | SP_H_Deposits | Stored Procedure | BI_DB_dbo | Synapse | Reader | Uses External_etoro_History_DepositAction_Yesterday (external table variant) for similar ResponseID resolution into BI_DB_Deposits. |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | DepositActionID | History.DepositAction | DepositActionID | Passthrough (IDENTITY stripped in Synapse) | Tier 1 |
| 2 | DepositID | History.DepositAction | DepositID | Passthrough | Tier 1 |
| 3 | PaymentActionStatusID | History.DepositAction | PaymentActionStatusID | Passthrough | Tier 1 |
| 4 | PaymentActionTypeID | History.DepositAction | PaymentActionTypeID | Passthrough | Tier 1 |
| 5 | PaymentStatusID | History.DepositAction | PaymentStatusID | Passthrough | Tier 1 |
| 6 | ResponseID | History.DepositAction | ResponseID | Passthrough | Tier 1 |
| 7 | ManagerID | History.DepositAction | ManagerID | Passthrough | Tier 1 |
| 8 | ExchangeRate | History.DepositAction | ExchangeRate | Passthrough (dbo.dtPrice -> numeric(16,8)) | Tier 1 |
| 9 | ApprovalNumber | History.DepositAction | ApprovalNumber | Passthrough (varchar(20) -> varchar(max)) | Tier 1 |
| 10 | AuthCode | History.DepositAction | AuthCode | Passthrough (varchar(20) -> varchar(max)) | Tier 1 |
| 11 | ModificationDate | History.DepositAction | ModificationDate | Passthrough (datetime -> datetime2(7)) | Tier 1 |
| 12 | ClearingHouseEffectiveDate | History.DepositAction | ClearingHouseEffectiveDate | Passthrough (datetime -> datetime2(7)) | Tier 1 |
| 13 | Amount | History.DepositAction | Amount | Passthrough (money -> numeric(19,4)) | Tier 1 |
| 14 | CurrencyID | History.DepositAction | CurrencyID | Passthrough | Tier 1 |
| 15 | MatchStatusID | History.DepositAction | MatchStatusID | Passthrough (tinyint -> int) | Tier 1 |
| 16 | Remark | History.DepositAction | Remark | Passthrough (varchar(255) -> varchar(max)) | Tier 1 |
| 17 | SessionID | History.DepositAction | SessionID | Passthrough | Tier 1 |
| 18 | DepotID | History.DepositAction | DepotID | Passthrough | Tier 1 |
| 19 | ExchangeFee | History.DepositAction | ExchangeFee | Passthrough | Tier 1 |
| 20 | BaseExchangeRate | History.DepositAction | BaseExchangeRate | Passthrough (dbo.dtPrice -> numeric(16,8)) | Tier 1 |
| 21 | PaymentGeneration | History.DepositAction | PaymentGeneration | Passthrough | Tier 1 |
| 22 | ProcessRegulationID | History.DepositAction | ProcessRegulationID | Passthrough | Tier 1 |
| 23 | MerchantAccountID | History.DepositAction | MerchantAccountID | Passthrough | Tier 1 |
