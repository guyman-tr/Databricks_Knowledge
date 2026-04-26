# BI_DB_dbo.BI_DB_MarketingCloudDaily — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Writer SP** | BI_DB_dbo.SP_MarketingCloudDaily |
| **Load Pattern** | Incremental merge (UPDATE existing + INSERT new CIDs per column-group) |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **UC Target** | _Not_Migrated (no Generic Pipeline mapping) |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|--------------|-----------|------|
| 1 | AccountId | DWH_dbo.Dim_Customer | SalesForceAccountID | Direct passthrough via RealCID join | T1 |
| 2 | CID | Multiple sources | CID/RealCID | Primary key — each column-group inserts new CIDs from its own source | T2 |
| 3 | MobileAppLastLogin | DWH_dbo.Fact_CustomerAction | Occurred | MAX where PlatformID IN (104,105,110,111) AND ActionTypeID=14 | T2 |
| 4 | WatchlistLastAddedETF | CopyFromLake.WatchListDB_dbo_WatchlistItems | ItemAddedDate | MAX where ItemType='Instrument' AND InstrumentTypeID=6 (via Dim_Instrument) | T2 |
| 5 | WatchlistLastAddedCrypto | CopyFromLake.WatchListDB_dbo_WatchlistItems | ItemAddedDate | MAX where InstrumentTypeID=10 | T2 |
| 6 | WatchlistLastAddedStocks | CopyFromLake.WatchListDB_dbo_WatchlistItems | ItemAddedDate | MAX where InstrumentTypeID=5 | T2 |
| 7 | WatchlistLastAddedCommodities | CopyFromLake.WatchListDB_dbo_WatchlistItems | ItemAddedDate | MAX where InstrumentTypeID=2 | T2 |
| 8 | WatchlistLastAddedIndecies | CopyFromLake.WatchListDB_dbo_WatchlistItems | ItemAddedDate | MAX where InstrumentTypeID=4 | T2 |
| 9 | WatchlistLastAddedPI | CopyFromLake.WatchListDB_dbo_WatchlistItems | ItemAddedDate | MAX where ItemType='User' AND GuruStatusID>=2 (PI flag from Dim_Customer) | T2 |
| 10 | WatchlistLastAddedCopyPortfolio | CopyFromLake.WatchListDB_dbo_WatchlistItems | ItemAddedDate | MAX where ItemType='User' AND AccountTypeID=9 (CopyPortfolio flag from Dim_Customer) | T2 |
| 11 | WatchlistLastAddedNonPIUser | CopyFromLake.WatchListDB_dbo_WatchlistItems | ItemAddedDate | MAX where ItemType='User' AND not PI/CP | T2 |
| 12 | WatchlistLastDateID | CopyFromLake.WatchListDB_dbo_WatchlistItems | ItemAddedDate | MAX(CONVERT(VARCHAR(8),ItemAddedDate,112)) — date key of latest watchlist add | T2 |
| 13 | GainThisWeek | BI_DB_dbo.DWH_GainDaily | Gain_w | Direct where Date=@date | T2 |
| 14 | GainOneMonthAgo | BI_DB_dbo.DWH_GainDaily | Gain_m | Direct where Date=@date | T2 |
| 15 | GainThreeMonthsAgo | BI_DB_dbo.DWH_GainDaily | Gain_q | Direct where Date=@date | T2 |
| 16 | GainSixMonthsAgo | BI_DB_dbo.DWH_GainDaily | Gain_h | Direct where Date=@date | T2 |
| 17 | GainOneYearAgo | BI_DB_dbo.DWH_GainDaily | Gain_y | Direct where Date=@date | T2 |
| 18 | GainLastDate | BI_DB_dbo.DWH_GainDaily | Date | Direct — retained when no new gain data | T2 |
| 19 | GainExecutionID | BI_DB_dbo.DWH_GainDaily | ExecutionID | Direct — retained when no new gain data | T2 |
| 20 | UpdateDate | ETL | GETDATE() | Set on every column-group UPDATE/INSERT | T5 |
| 21 | eMoneyIsInRollout | Legacy | — | No longer populated by SP (all NULL). Legacy column. | T4 |
| 22 | eMoneyIsInRolloutDate | Legacy | — | No longer populated by SP (all NULL). Legacy column. | T4 |
| 23 | AirDropRemainder | Legacy | — | No longer populated by SP (all NULL). Legacy column. | T4 |
| 24 | VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | Direct passthrough where VerificationLevel3Date>=@date | T2 |
| 25 | AirdropServeyDate | Legacy | — | No longer populated by SP (all NULL). Legacy column. | T4 |
| 26 | AirdropPotentialUpdateDate | Legacy | — | No longer populated by SP (all NULL). Legacy column. | T4 |
| 27 | WalletLastLogin | DWH_dbo.Fact_CustomerAction | Occurred | MAX where PlatformID IN (118,119,120) AND ActionTypeID=14 | T2 |
| 28 | eMoneyExternalTransferToIBANLastDate | eMoney_dbo.FiatTransactions + FiatTransactionsStatuses | TransactionOccured | MAX where TransactionTypeId=7 AND TransactionStatusId=2 | T2 |
| 29 | eMoneyDepositToPlatformLastDate | eMoney_dbo.FiatTransactions + FiatTransactionsStatuses | TransactionOccured | MAX where TransactionTypeId=6 AND TransactionStatusId=2 | T2 |
| 30 | eMoneyWithrawalFromPlatformLastDate | eMoney_dbo.FiatTransactions + FiatTransactionsStatuses | TransactionOccured | MAX where TransactionTypeId=5 AND TransactionStatusId=2 | T2 |
| 31 | eMoneyEODBalanceAmount | eMoney_dbo.CustomerEODBalance | EODBalanceAmount | Latest EODBalanceDate per GCID | T2 |
| 32 | eMoneyEODBalanceDate | eMoney_dbo.CustomerEODBalance | EODBalanceDate | MAX(EODBalanceDate) per GCID | T2 |
| 33 | eMoneyCardTransactionLastDate | eMoney_dbo.FiatTransactions + FiatTransactionsStatuses | TransactionOccured | MAX where TransactionCategory=1 AND TransactionTypeId NOT IN (9,10) AND TransactionStatusId=2 | T2 |
| 34 | KYCFlowName | BI_DB_dbo.External_ComplianceStateDB_Dictionary_KYCFlowType | ShortName | Joined via KYCFlowTypeID from External_ComplianceStateDB_Compliance_KycFlow, resolved to RealCID via Dim_Customer GCID | T2 |
| 35 | KYCLeadScore | BI_DB_dbo.BI_DB_KYC_Score_CID_Level | Cluster | Direct rename (Cluster→KYCLeadScore) where UpdateDate>=@date | T2 |
| 36 | AirdropCustomerID | DWH_dbo.Dim_Customer | ID | Direct passthrough where IsValidCustomer=1 | T1 |
| 37 | Credit | DWH_dbo.V_Liabilities | Credit | Direct where DateID=@dateID | T1 |
| 38 | FirstTimeCopiedDate | DWH_dbo.Dim_Mirror | OpenOccurred | MIN where MirrorTypeID<>4, joined on ParentCID via Dim_Customer | T2 |
| 39 | PrivacyPolicyID | DWH_dbo.Dim_Customer | PrivacyPolicyID | Direct passthrough | T1 |
| 40 | LSD | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | LSD | Latest active record (ToDateID=99991231, MAX DateID) | T2 |
| 41 | LSDDate | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | Date | Same as LSD — date of latest active record | T2 |
| 42 | TX_Tier_3M | eMoney_dbo.eMoney_Panel_Retention_Daily | TX_Tier_3M | Direct where Report_Date_ID=@dateID | T2 |
| 43 | Amount_Tier_3M | eMoney_dbo.eMoney_Panel_Retention_Daily | Amount_Tier_3M | Direct | T2 |
| 44 | TX_Tier_3M_Deposits | eMoney_dbo.eMoney_Panel_Retention_Daily | TX_Tier_3M_Deposits | Direct | T2 |
| 45 | TX_Tier_3M_CO | eMoney_dbo.eMoney_Panel_Retention_Daily | TX_Tier_3M_CO | Direct | T2 |
| 46 | Amount_Tier_3M_CO | eMoney_dbo.eMoney_Panel_Retention_Daily | Amount_Tier_3M_CO | Direct | T2 |
| 47 | Amount_Tier_3M_Deposits | eMoney_dbo.eMoney_Panel_Retention_Daily | Amount_Tier_3M_Deposits | Direct | T2 |
| 48 | AccountSubProgram | eMoney_dbo.eMoney_Dim_Account | AccountSubProgram | Direct where AccountProgramID=1 AND IsValidETM=1 AND GCID_Unique_Count=1 | T2 |
| 49 | CardCreateDate | eMoney_dbo.eMoney_Dim_Account | CardCreateDate | Direct where same filters as AccountSubProgram | T2 |
| 50 | KYC_Experience_Level | BI_DB_dbo.BI_DB_KYC_Panel | Experience_Level | Direct rename where KYC_LastUpdateDate>=@date | T2 |
| 51 | KYC_Planned_Invested_Amount | BI_DB_dbo.BI_DB_KYC_Panel | Q14_AnswerText | Direct rename where KYC_LastUpdateDate>=@date | T2 |
| 52 | KYC_CFD_Level | BI_DB_dbo.BI_DB_KYC_Panel | Is_PI_FX + Experience_Level + Total_PI_Answers | Computed CASE: Level_0 (no FX), Level_1 (Non+FX+multi-answer), Level_2 (experienced+FX or single-answer), NULL | T2 |
| 53 | IOB_Opt_In | BI_DB_dbo.External_Interest_Trade_InterestConsent | ConsentStatusID | Latest per CID (ROW_NUMBER by ValidFrom DESC, rn=1) | T2 |
| 54 | IOB_Opt_In_ValidFrom | BI_DB_dbo.External_Interest_Trade_InterestConsent | ValidFrom | Same as IOB_Opt_In | T2 |
| 55 | AmountToClubUpgrade | BI_DB_dbo.BI_DB_CID_DailyPanel_Club + External_ClubService_Clubs_UserBalances | AmountToUpgrade / computed gap | Club users: direct from CID_DailyPanel_Club. Non-club: gap to next tier (5K/10K/25K/50K/250K) from ClubService realized equity | T2 |
| 56 | UnRealizedEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Computed sum where DateID=@dateID | T2 |
| 57 | MaxEquity_LastYear | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | MAX over trailing 1 year | T2 |
| 58 | MaxEquity_LastWeek | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | MAX over trailing 7 days | T2 |
| 59 | CashoutAmount_LastWeek | DWH_dbo.Fact_CustomerAction | Amount | SUM where ActionTypeID=8 AND trailing 7 days | T2 |
| 60 | CashoutAmount_InProcess | DWH_dbo.V_Liabilities | InProcessCashouts | Direct where DateID=@dateID | T1 |
| 61 | TotalDepositsAmount_LastYear | DWH_dbo.Fact_CustomerAction | Amount | SUM where ActionTypeID=7 AND trailing 1 year | T2 |
| 62 | KYC_PlannedInvestment_Stocks | BI_DB_dbo.BI_DB_KYC_Panel | Is_PI_Stocks | Direct rename | T2 |
| 63 | KYC_PlannedInvestment_Crypto | BI_DB_dbo.BI_DB_KYC_Panel | Is_PI_Crypto | Direct rename | T2 |
| 64 | KYC_PlannedInvestment_FX | BI_DB_dbo.BI_DB_KYC_Panel | Is_PI_FX | Direct rename | T2 |
| 65 | Total_KYC_PlannedInvestment_Answers | BI_DB_dbo.BI_DB_KYC_Panel | Total_PI_Answers | Direct rename | T2 |
| 66 | StocksLendingStatusID | DWH_dbo.Dim_Customer + Ext_Dim_Customer_StocksLending | StocksLendingStatusID | Joined on GCID, filtered where StocksLendingStatusID=1 | T2 |
| 67 | StocksLendingOptInDate | DWH_dbo.Ext_Dim_Customer_StocksLending | ConsentDateTime | Direct rename where StocksLendingStatusID=1 | T2 |
| 68 | eTM_IBAN_Type | eMoney_dbo.eMoney_Dim_Account | BankAccountIBAN | LEFT(BankAccountIBAN, 2) — country code prefix | T2 |
| 69 | eTM_AccountName_LocalCurrency | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceISODesc | Direct rename where GCID_Unique_Count=1 AND IsValidETM=1 | T2 |
| 70 | Cluster | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | Direct rename (ClusterDetail→Cluster) for latest FromDateID>=@dateID | T2 |
| 71 | ClusterDate | BI_DB_dbo.BI_DB_CID_DailyCluster | FromDate | Direct for same record as Cluster | T2 |
| 72 | PositionOpen_LastDate_ETF | DWH_dbo.Dim_Position + Dim_Instrument | OpenOccurred | MAX where InstrumentTypeID=6 AND MirrorID=0 AND IsPartialCloseChild=0 AND IsAirDrop=0 | T2 |
| 73 | Rewarded_LastMonth_eMoney | eMoney_dbo.eMoney_Dim_Transaction + ETL_SettlementsTransactions | TxStatusModificationDate | DATEFROMPARTS month of latest settled card transactions (monthly on 1st only) | T2 |
| 74 | Monthly_CardSpent_eMoney | eMoney_dbo.eMoney_Dim_Transaction + ETL_SettlementsTransactions | HolderAmount | SUM(HolderAmount * -1) for prior month settled card transactions | T2 |
| 75 | Monthly_RewardedChashBack_eMoney | eMoney_dbo.eMoney_Dim_Transaction + ETL_SettlementsTransactions | HolderAmount | 4% of eligible spend, capped at 1500 | T2 |
| 76 | Monthly_CardEligibleCashBack_eMoney | eMoney_dbo.eMoney_Dim_Transaction + ETL_SettlementsTransactions | HolderAmount | SUM of eligible-MCC spend (excludes gambling, crypto, money transfer MCCs) * -1 | T2 |
| 77 | FirstDepositDateGlobal | BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms | FirstDepositDate | Direct from TVF(1) where FirstDepositDate=@date | T2 |
| 78 | DepositsUSD_Global | BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | AmountUSD | SUM where MIMOAction='Deposit' AND IsInternalTransfer=0 (all-time for users with deposit on @date) | T2 |
| 79 | BalanceGlobal | BI_DB_dbo.BI_DB_DDR_Fact_AUM | CreditTP + IBANBalance | Computed sum where DateID=@dateID | T2 |
| 80 | EquityGlobal | BI_DB_dbo.BI_DB_DDR_Fact_AUM | EquityGlobal | Direct where DateID=@dateID | T2 |
| 81 | Total_Deposit_USD | BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | AmountUSD | SUM where MIMOAction='Deposit' AND MIMOPlatform='TradingPlatform' AND IsInternalTransfer=0 | T2 |
| 82 | Total_Deposit_EUR | BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | AmountOrigCurrency | SUM where MIMOPlatform='eMoney' AND CurrencyID=2 (EUR) | T2 |
| 83 | Total_Deposit_GBP | BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | AmountOrigCurrency | SUM where MIMOPlatform='eMoney' AND CurrencyID=3 (GBP) | T2 |
| 84 | Current_Balance_USD | BI_DB_dbo.BI_DB_DDR_Fact_AUM | CreditTP | Direct where DateID=@dateID | T2 |
| 85 | Current_Balance_EUR | eMoney_dbo.eMoneyClientBalance + eMoney_Dim_Account | ClosingBalanceBO | SUM where CurrencyBalanceISOCode=978 AND GCID_Unique_Count=1 | T2 |
| 86 | Current_Balance_GBP | eMoney_dbo.eMoneyClientBalance + eMoney_Dim_Account | ClosingBalanceBO | SUM where CurrencyBalanceISOCode=826 AND GCID_Unique_Count=1 | T2 |
| 87 | LastTransactionDate | eMoney_dbo.eMoney_Panel_FirstDates + eMoney_Dim_Account | LastCardSettledTXDate | MAX where IsValidETM=1 AND GCID_Unique_Count=1 | T2 |
| 88 | AcceptedTnCs_Date | BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA | AcceptedTnCs_Date | Direct where AcceptedTnCs_Date=@date | T2 |
| 89 | DIY_PortfolioCreatedDate | BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA | PortfolioCreatedDate | MAX where ProductName_Code='isa-execution-only' | T2 |
| 90 | DIY_FirstDepositDate | BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA | PortfolioFirstDepositDate | MAX where ProductName_Code='isa-execution-only' | T2 |
| 91 | Cash_PortfolioCreatedDate | BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA | PortfolioCreatedDate | MAX where ProductName_Code='isa-cash' | T2 |
| 92 | Cash_FirstDepositDate | BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA | PortfolioFirstDepositDate | MAX where ProductName_Code='isa-cash' | T2 |
| 93 | Managed_PortfolioCreatedDate | BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA | PortfolioCreatedDate | MAX where ProductName_Code='isa-discretionary' | T2 |
| 94 | Managed_FirstDepositDate | BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA | PortfolioFirstDepositDate | MAX where ProductName_Code='isa-discretionary' | T2 |
| 95 | IsDefunded_across_all_portfolios | BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA | PortfolioDefunded | MIN(CASE WHEN PortfolioDefunded=1 THEN 1 ELSE 0 END) — 1 only if ALL portfolios defunded | T2 |
| 96 | RAF_Inviter | BI_DB_dbo.BI_DB_RAF_Invitees_KPIs + DWH_dbo.Dim_Customer | GCID | Invitee CID mapped to Inviter's GCID via Dim_Customer | T2 |
| 97 | RAF_LastCashoutDate | BI_DB_dbo.BI_DB_RAF_Invitees_KPIs | LastCashoutDate | MAX per Invitee | T2 |
| 98 | — | — | — | Note: eMoneyIsInRollout, eMoneyIsInRolloutDate, AirDropRemainder, AirdropServeyDate, AirdropPotentialUpdateDate are legacy columns (all NULL, not populated by current SP) | — |
