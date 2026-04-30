# Lineage: BI_DB_dbo.BI_DB_EY_Audit_Cashouts

## Source Objects

| # | Source Object | Schema | Type | Relationship | Join/Filter |
|---|--------------|--------|------|-------------|-------------|
| 1 | Fact_CustomerAction | DWH_dbo | Table | Primary event source | WHERE ActionTypeID IN (7,8,11,12,13,37) AND DateID = @DateID; cashout path uses ActionTypeID IN (8,11,12,13,37) AND WithdrawID IS NOT NULL |
| 2 | Fact_BillingWithdraw | DWH_dbo | Table | Cashout metadata | LEFT JOIN ON WithdrawPaymentID; WHERE CashoutStatusID_Funding = 3 AND ModificationDateID = @DateID |
| 3 | Fact_SnapshotCustomer | DWH_dbo | Table | Customer snapshot | JOIN ON RealCID; date-range filtered via Dim_Range |
| 4 | BI_DB_DepositWithdrawFee | BI_DB_dbo | Table | Exchange rate source | LEFT JOIN on WithdrawPaymentID (via #pips TransactionID); WHERE TransactionType = 'Withdraw' |
| 5 | Dim_Customer | DWH_dbo | Table | Customer dimension | JOIN ON RealCID; provides ExternalID |
| 6 | Dim_Regulation | DWH_dbo | Table | Regulation lookup | LEFT JOIN ON fsc.RegulationID = dr1.DWHRegulationID; provides Regulation Name |
| 7 | Dim_Range | DWH_dbo | Table | Date range helper | JOIN ON fsc.DateRangeID = dr.DateRangeID AND DateID BETWEEN FromDateID AND ToDateID |
| 8 | Dim_BillingDepot | DWH_dbo | Table | Depot lookup | LEFT JOIN ON fbw.DepotID = dbd.DepotID; provides Depot Name |
| 9 | Dim_FundingType | DWH_dbo | Table | Payment method lookup | LEFT JOIN ON dbd.FundingTypeID = dft.FundingTypeID; provides PaymentMethod Name |
| 10 | Dim_CardType | DWH_dbo | Table | Card type lookup | LEFT JOIN ON fbw.CardTypeIDAsInteger = dct.CardTypeID; provides CarTypeName |
| 11 | Dim_ActionType | DWH_dbo | Table | Action type lookup | JOIN ON ActionTypeID (for non-cashout refund/chargeback rows only); provides ActionType Name |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform |
|---|--------------|---------------|---------------|-----------|
| 1 | RealCID | Dim_Customer | RealCID | Passthrough (JOIN from Fact_CustomerAction.RealCID → Dim_Customer.RealCID) |
| 2 | DateID | SP_EY_Audit_Deposit_Cashouts | @Date parameter | ETL-computed: CAST(CONVERT(VARCHAR(10), @Date, 112) AS INT) |
| 3 | Date | SP_EY_Audit_Deposit_Cashouts | @Date parameter | Passthrough of @Date parameter |
| 4 | ExternalID | Dim_Customer | ExternalID | Passthrough via JOIN on RealCID |
| 5 | ActionType | Fact_CustomerAction / Dim_ActionType | ActionTypeID → Name | Hardcoded 'Cashout' for ActionTypeID=8; Dim_ActionType.Name for ActionTypeID IN (11,12,13,37) |
| 6 | WithdrawID | Fact_CustomerAction | WithdrawID | Passthrough |
| 7 | WithdrawPaymentID | Fact_CustomerAction | WithdrawPaymentID | Passthrough |
| 8 | Occurred | Fact_CustomerAction | Occurred | Passthrough |
| 9 | Amount | Fact_CustomerAction | Amount | Passthrough (cashout/refund amount for these ActionTypeIDs) |
| 10 | PaymentMethod | Dim_FundingType | Name | Dim-lookup passthrough via Dim_BillingDepot.FundingTypeID → Dim_FundingType.Name |
| 11 | Depot | Dim_BillingDepot | Name | Dim-lookup passthrough via Fact_BillingWithdraw.DepotID → Dim_BillingDepot.Name |
| 12 | BankNameAsString | Fact_BillingWithdraw | ClientBankNameAsString / BankNameAsString | CASE WHEN ClientBankNameAsString IS NULL THEN BankNameAsString ELSE ClientBankNameAsString END |
| 13 | CardType | Dim_CardType | CarTypeName | Dim-lookup passthrough via Fact_BillingWithdraw.CardTypeIDAsInteger → Dim_CardType.CarTypeName |
| 14 | Regulation | Dim_Regulation | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.Name |
| 15 | IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough (date-range filtered snapshot) |
| 16 | BaseExchangeRate | BI_DB_DepositWithdrawFee | BaseExchangeRate | Passthrough via #pips temp table (matched on WithdrawPaymentID) |
| 17 | ExchangeFee | BI_DB_DepositWithdrawFee | ExchangeFee | Passthrough via #pips temp table (matched on WithdrawPaymentID) |
| 18 | VerificationCode | Fact_BillingWithdraw | VerificationCode | Passthrough |
| 19 | UpdateDate | SP_EY_Audit_Deposit_Cashouts | GETDATE() | ETL load timestamp |
