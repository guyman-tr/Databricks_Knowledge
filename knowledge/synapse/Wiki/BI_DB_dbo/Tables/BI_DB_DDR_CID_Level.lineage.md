# BI_DB_dbo.BI_DB_DDR_CID_Level — Column Lineage

Generated: 2026-04-21 | Pipeline: Phase 10B

## Source Objects

| Source Type | Object | Role |
|-------------|--------|------|
| DWH Fact Table | DWH_dbo.Fact_SnapshotCustomer | Customer attributes, flags (IsDepositor, IsValidCustomer, IsCreditReportValidCB, VerificationLevelID, PlayerStatusID), regulatory/segmentation dim keys |
| DWH Dimension | DWH_dbo.Dim_Regulation | Resolves Regulation name |
| DWH Dimension | DWH_dbo.Dim_AccountType | Resolves AccountType name |
| DWH Dimension | DWH_dbo.Dim_Country | Resolves Country name |
| DWH Dimension | DWH_dbo.Dim_Label | Resolves Label name |
| DWH Dimension | DWH_dbo.Dim_MifidCategory | Resolves MifidCategory name |
| DWH Dimension | DWH_dbo.Dim_PlayerLevel | Resolves PlayerLevel name |
| DWH Dimension | DWH_dbo.Dim_PlayerStatus | Resolves PlayerStatus name |
| DWH Dimension | DWH_dbo.Dim_Region | Resolves Region name |
| DWH Fact Table | DWH_dbo.Fact_CustomerAction | All transaction metrics: deposits, cashouts, commissions, bonuses, copy amounts, activity flags, first action metadata |
| DWH Fact Table | DWH_dbo.Fact_SnapshotEquity | NOP metrics, PositionPNL, PositionAmount, NOP breakdowns by asset class |
| DWH Fact Table | DWH_dbo.Fact_CustomerUnrealized_PnL | Unrealized P&L and daily changes (PnlChange, UnrealizedPnL, UnrealizedPnLChange) |
| BI_DB Table | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | InProcessCashout, Credit, TotalCash, StockOrders (cash-side equity components) |
| DWH View | DWH_dbo.V_Liabilities | TotalLiability per CID |
| DWH View | DWH_dbo.V_GermanBaFin | IsGermanBaFin flag |
| DWH TVF | DWH_dbo.Function_Population_First_Time_Funded | FirstTimeFunded flag — 5-criteria FTF computation (FTD + Verification + Trade/IOB/Options) |
| ETL Writer | BI_DB_dbo.SP_DDR | Computes all metrics in #CIDAgg and loads table via DELETE+INSERT per @dateID |

## Column Lineage

| # | Synapse Column | Source Table(s) | Source Column(s) | Transform | Tier |
|---|---------------|-----------------|------------------|-----------|------|
| 1 | CID | Fact_CustomerAction + BI_DB_Client_Balance_CID_Level_New | CID | UNION of distinct CIDs across #fca and #ClientBalance, assembled in #allUsers | Tier 2 |
| 2 | DateID | SP_DDR parameter | @date | Computed: CONVERT(int, CONVERT(varchar(8), @date, 112)) — YYYYMMDD int | Tier 2 |
| 3 | Regulation | Fact_SnapshotCustomer + Dim_Regulation | RegulationID | Dim name resolved via #fsc2days JOIN | Tier 2 |
| 4 | IsBlocked | Fact_SnapshotCustomer | PlayerStatusID | CASE WHEN PlayerStatusID NOT IN (1,3,5,7) THEN 1 ELSE 0 | Tier 2 |
| 5 | IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough flag from #fsc2days | Tier 2 |
| 6 | IsGermanBaFin | V_GermanBaFin | — | LEFT JOIN; 1 if CID appears in V_GermanBaFin, else 0 | Tier 2 |
| 7 | IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | Passthrough flag from #fsc2days | Tier 2 |
| 8 | AccountType | Fact_SnapshotCustomer + Dim_AccountType | AccountTypeID | Dim name resolved via #fsc2days JOIN | Tier 2 |
| 9 | Country | Fact_SnapshotCustomer + Dim_Country | CountryID | Dim name resolved via #fsc2days JOIN | Tier 2 |
| 10 | Label | Fact_SnapshotCustomer + Dim_Label | LabelID | Dim name resolved via #fsc2days JOIN | Tier 2 |
| 11 | MifidCategory | Fact_SnapshotCustomer + Dim_MifidCategory | MifidCategoryID | Dim name resolved via #fsc2days JOIN | Tier 2 |
| 12 | PlayerLevel | Fact_SnapshotCustomer + Dim_PlayerLevel | PlayerLevelID | Dim name resolved via #fsc2days JOIN | Tier 2 |
| 13 | PlayerStatus | Fact_SnapshotCustomer + Dim_PlayerStatus | PlayerStatusID | Dim name resolved via #fsc2days JOIN | Tier 2 |
| 14 | Region | Fact_SnapshotCustomer + Dim_Region | RegionID | Dim name resolved via #fsc2days JOIN | Tier 2 |
| 15 | IsDepositor | Fact_SnapshotCustomer | IsDepositor | Passthrough flag from #fsc2days | Tier 2 |
| 16 | Deposits | Fact_CustomerAction | Amount | SUM where ActionTypeID = Deposit | Tier 2 |
| 17 | Bonus | Fact_CustomerAction | Amount | SUM where ActionTypeID = Bonus | Tier 2 |
| 18 | Compensation | Fact_CustomerAction | Amount | SUM where ActionTypeID = Compensation | Tier 2 |
| 19 | Cashouts | Fact_CustomerAction | Amount | SUM where ActionTypeID = Cashout (excl. redeem) | Tier 2 |
| 20 | CashoutsIncludingRedeem | Fact_CustomerAction | Amount | SUM where ActionTypeID IN (Cashout, Redeem) | Tier 2 |
| 21 | CashoutFee | Fact_CustomerAction | Amount | SUM of cashout fee charges | Tier 2 |
| 22 | OvernightFee | Fact_CustomerAction | Amount | SUM of overnight/rollover fee charges | Tier 2 |
| 23 | CompensationPnLAdjustments | Fact_CustomerAction | Amount | SUM of compensation P&L adjustment actions | Tier 2 |
| 24 | TransferCoins | Fact_CustomerAction | Amount | SUM of coin transfer amounts | Tier 2 |
| 25 | TransferCoinFees | Fact_CustomerAction | Amount | SUM of coin transfer fee charges | Tier 2 |
| 26 | realizedEquity | Fact_CustomerAction | Amount | SUM of realized equity movements | Tier 2 |
| 27 | DividendsPaid | Fact_CustomerAction | Amount | SUM of dividend payment actions | Tier 2 |
| 28 | TotalLiability | V_Liabilities | — | SUM liability per CID via #liabilities LEFT JOIN | Tier 2 |
| 29 | InProcessCashout | BI_DB_Client_Balance_CID_Level_New | InProcessCashout | Passthrough via #ClientBalance | Tier 2 |
| 30 | NOPCrypto | Fact_SnapshotEquity | NOPCrypto | SUM crypto real NOP from #fse2days | Tier 2 |
| 31 | NOPCryptoCFD | Fact_SnapshotEquity | NOPCryptoCFD | SUM crypto CFD NOP from #fse2days | Tier 2 |
| 32 | NOPStocks | Fact_SnapshotEquity | NOPStocks | SUM stocks real NOP from #fse2days | Tier 2 |
| 33 | NOPStocksCFD | Fact_SnapshotEquity | NOPStocksCFD | SUM stocks CFD NOP from #fse2days | Tier 2 |
| 34 | TotalRealCryptoLoan | Fact_SnapshotEquity | TotalRealCryptoLoan | SUM from #fse2days | Tier 2 |
| 35 | PositionPNL | Fact_SnapshotEquity | PositionPNL | SUM unrealized P&L across all open positions from #fse2days | Tier 2 |
| 36 | NOP | Fact_SnapshotEquity | NOP | SUM total net open positions from #fse2days | Tier 2 |
| 37 | PositionAmount | Fact_SnapshotEquity | PositionAmount | SUM invested amount in open positions from #fse2days | Tier 2 |
| 38 | StockOrders | BI_DB_Client_Balance_CID_Level_New | StockOrders | Pending stock order value from #ClientBalance | Tier 2 |
| 39 | actualNWA | Fact_SnapshotEquity | actualNWA | SUM net worth adjustment from #fse2days | Tier 2 |
| 40 | UnrealizedPnLChange | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of total unrealized P&L (#customerUnrealizedNewMetrics) | Tier 2 |
| 41 | UnrealizedPnLChangeCFD | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of CFD unrealized P&L | Tier 2 |
| 42 | UnrealizedPnLChangeCryptoReal | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of real crypto unrealized P&L | Tier 2 |
| 43 | UnrealizedPnLChangeStocksReal | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of real stocks unrealized P&L | Tier 2 |
| 44 | DepositsCount | Fact_CustomerAction | — | COUNT of deposit actions | Tier 2 |
| 45 | Deposited | Fact_CustomerAction | — | FLAG: 1 if customer made any deposit on @date | Tier 2 |
| 46 | CompensationRAFInvited | Fact_CustomerAction | Amount | SUM of RAF invite compensation received | Tier 2 |
| 47 | CompensationRAFInviting | Fact_CustomerAction | Amount | SUM of RAF inviting compensation paid | Tier 2 |
| 48 | CompensationOther | Fact_CustomerAction | Amount | SUM of other compensation types | Tier 2 |
| 49 | CompensationPIWithCO | Fact_CustomerAction | Amount | SUM of PI compensation with cashout | Tier 2 |
| 50 | CompensationPINoCO | Fact_CustomerAction | Amount | SUM of PI compensation without cashout | Tier 2 |
| 51 | CompensationToAffiliateWithCO | Fact_CustomerAction | Amount | SUM of affiliate compensation with cashout | Tier 2 |
| 52 | CompensationToAffiliateNoCO | Fact_CustomerAction | Amount | SUM of affiliate compensation without cashout | Tier 2 |
| 53 | CashoutsCount | Fact_CustomerAction | — | COUNT of cashout actions | Tier 2 |
| 54 | NewTrades | Fact_CustomerAction | — | COUNT of new position opens on @date | Tier 2 |
| 55 | NumberOfClosedPositions | Fact_CustomerAction | — | COUNT of position closes on @date | Tier 2 |
| 56 | EditStoplossAmounts | Fact_CustomerAction | Amount | SUM of stop-loss edit amounts | Tier 2 |
| 57 | TotalInvestmentAmountInNewTrades | Fact_CustomerAction | Amount | SUM of investment amounts in new trades opened on @date | Tier 2 |
| 58 | FirstDepositors | Fact_CustomerAction | — | FLAG: 1 if this is the customer's first ever deposit | Tier 2 |
| 59 | LoggedIn | Fact_CustomerAction | — | FLAG: 1 if customer logged in on @date | Tier 2 |
| 60 | DepositorsLoggedIn | Fact_CustomerAction | — | FLAG: 1 if depositor who also logged in on @date | Tier 2 |
| 61 | FirstDepositAmounts | Fact_CustomerAction | Amount | Amount of first-time deposit (FTD) | Tier 2 |
| 62 | Registrations | Fact_CustomerAction | — | FLAG: 1 if customer registered on @date | Tier 2 |
| 63 | CashedOut | Fact_CustomerAction | — | FLAG: 1 if customer made any cashout on @date | Tier 2 |
| 64 | Redeemed | Fact_CustomerAction | — | FLAG: 1 if customer redeemed on @date | Tier 2 |
| 65 | CompensationRAFInvitedInviting | Fact_CustomerAction | Amount | SUM of combined RAF invite+inviting compensation | Tier 2 |
| 66 | AccountBalanceToMirrorAmount | Fact_CustomerAction | Amount | Amount moved from account balance to copy trading | Tier 2 |
| 67 | MirrorAmountToAccountBalance | Fact_CustomerAction | Amount | Amount returned from copy trading to account balance | Tier 2 |
| 68 | NewCopyAmount | Fact_CustomerAction | Amount | SUM of new copy allocations started on @date | Tier 2 |
| 69 | StopCopyAmount | Fact_CustomerAction | Amount | SUM of copy allocations stopped on @date | Tier 2 |
| 70 | NewCopyActions | Fact_CustomerAction | — | COUNT of new copy relationships started on @date | Tier 2 |
| 71 | StopCopyActions | Fact_CustomerAction | — | COUNT of copy relationships stopped on @date | Tier 2 |
| 72 | PublishPost | Fact_CustomerAction | — | COUNT of news feed posts published on @date | Tier 2 |
| 73 | PublishComment | Fact_CustomerAction | — | COUNT of comments published on @date | Tier 2 |
| 74 | PublishLike | Fact_CustomerAction | — | COUNT of likes given on @date | Tier 2 |
| 75 | EngagedInFeed | Fact_CustomerAction | — | FLAG: 1 if customer had any social feed engagement on @date | Tier 2 |
| 76 | TotalNetProfit | Fact_CustomerAction | NetProfit | SUM net profit across all position types | Tier 2 |
| 77 | ManualNetProfit | Fact_CustomerAction | NetProfit | SUM net profit from manually opened positions | Tier 2 |
| 78 | CopyNetProfit | Fact_CustomerAction | NetProfit | SUM net profit from copy-traded positions | Tier 2 |
| 79 | StocksNetProfit | Fact_CustomerAction | NetProfit | SUM net profit from CFD stocks positions | Tier 2 |
| 80 | StocksRealNetProfit | Fact_CustomerAction | NetProfit | SUM net profit from real stocks positions | Tier 2 |
| 81 | CryptoNetProfit | Fact_CustomerAction | NetProfit | SUM net profit from CFD crypto positions | Tier 2 |
| 82 | CryptoRealNetProfit | Fact_CustomerAction | NetProfit | SUM net profit from real crypto positions | Tier 2 |
| 83 | TotalCommission | Fact_CustomerAction | Commission | SUM spread/commission charged on closed positions | Tier 2 |
| 84 | FullTotalCommission | Fact_CustomerAction | Commission | SUM full commission (open+close) across all position types | Tier 2 |
| 85 | ManualCommission | Fact_CustomerAction | Commission | SUM commission from manual positions | Tier 2 |
| 86 | CopyCommission | Fact_CustomerAction | Commission | SUM commission from copy positions | Tier 2 |
| 87 | CurrenciesCommission | Fact_CustomerAction | Commission | SUM commission from FX/currency positions | Tier 2 |
| 88 | CommoditiesCommission | Fact_CustomerAction | Commission | SUM commission from commodity positions | Tier 2 |
| 89 | IndicesCommission | Fact_CustomerAction | Commission | SUM commission from index positions | Tier 2 |
| 90 | StocksOnlyCommission | Fact_CustomerAction | Commission | SUM commission from CFD stock positions only | Tier 2 |
| 91 | ETFCommission | Fact_CustomerAction | Commission | SUM commission from ETF positions | Tier 2 |
| 92 | StocksAndETFsCommission | Fact_CustomerAction | Commission | SUM commission from stocks + ETFs (CFD) | Tier 2 |
| 93 | RealStocksCommission | Fact_CustomerAction | Commission | SUM commission from real stocks positions | Tier 2 |
| 94 | CryptoCommission | Fact_CustomerAction | Commission | SUM commission from crypto (CFD + real) | Tier 2 |
| 95 | PnLAdjustment | Fact_CustomerAction | Amount | SUM of P&L adjustment actions | Tier 2 |
| 96 | FullManualCommission | Fact_CustomerAction | Commission | SUM full open+close commission from manual positions | Tier 2 |
| 97 | FullCopyCommission | Fact_CustomerAction | Commission | SUM full open+close commission from copy positions | Tier 2 |
| 98 | FullStocksCommission | Fact_CustomerAction | Commission | SUM full commission from stocks positions | Tier 2 |
| 99 | FullCryptoCommission | Fact_CustomerAction | Commission | SUM full commission from crypto positions | Tier 2 |
| 100 | PnlChange | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of total unrealized P&L per CID | Tier 2 |
| 101 | CopyPnlChange | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of copy position unrealized P&L | Tier 2 |
| 102 | StocksPnlChange | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of CFD stocks unrealized P&L | Tier 2 |
| 103 | CryptoPnLChange | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of crypto unrealized P&L | Tier 2 |
| 104 | ManualsPnlChange | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of manual position unrealized P&L | Tier 2 |
| 105 | StocksRealPnlChange | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of real stocks unrealized P&L | Tier 2 |
| 106 | CryptoRealPnlChange | Fact_CustomerUnrealized_PnL | — | Day-over-day diff of real crypto unrealized P&L | Tier 2 |
| 107 | ActiveCopy | Fact_CustomerAction | — | FLAG: 1 if customer had active copy relationships on @date | Tier 2 |
| 108 | ActiveManualStocksETFs | Fact_CustomerAction | — | FLAG: 1 if customer had open manual stocks/ETF positions on @date | Tier 2 |
| 109 | ActiveManualFXCommoditiesIndices | Fact_CustomerAction | — | FLAG: 1 if customer had open manual FX/commodities/indices positions | Tier 2 |
| 110 | ActiveManualCrypto | Fact_CustomerAction | — | FLAG: 1 if customer had open manual crypto positions | Tier 2 |
| 111 | ActiveOpen | Fact_CustomerAction | — | FLAG: 1 if customer had any open position (manual or copy) on @date | Tier 2 |
| 112 | ActiveOpenManual | Fact_CustomerAction | — | FLAG: 1 if customer had any open manual position on @date | Tier 2 |
| 113 | ActiveFunded | Fact_CustomerAction | — | FLAG: 1 if customer had positive account balance on @date | Tier 2 |
| 114 | ActiveTrader | Fact_CustomerAction | — | FLAG: 1 if customer traded (opened or closed position) on @date | Tier 2 |
| 115 | FirstDepositDate | #FirstActionsFinal | — | Calendar date of first ever deposit (date type) | Tier 2 |
| 116 | FirstDepositDateID | #FirstActionsFinal | — | YYYYMMDD int of first ever deposit date | Tier 2 |
| 117 | PositionID | #FirstActionsFinal | PositionID | Position ID of first trade action | Tier 2 |
| 118 | ActionTypeID | #FirstActionsFinal | ActionTypeID | ActionTypeID of first ever customer action | Tier 2 |
| 119 | FirstActionDateID | #FirstActionsFinal | — | YYYYMMDD int of first ever action date | Tier 2 |
| 120 | InstrumentTypeID | #FirstActionsFinal | InstrumentTypeID | InstrumentTypeID of first position | Tier 2 |
| 121 | MirrorID | #FirstActionsFinal | MirrorID | MirrorID of first copy action (NULL if manual) | Tier 2 |
| 122 | FirstActionType | #FirstActionsFinal | — | Label for first action type: 'Copy', 'Manual', 'NoAction', etc. | Tier 2 |
| 123 | Revenue | Fact_CustomerAction | — | FullTotalCommissionOnOpen + OvernightFee + CashoutFee + FullCommissionCloseAdjustment + TransferCoinFees | Tier 2 |
| 124 | Equity | Multiple | — | PositionPNL + InProcessCashout + PositionAmount + TotalCash + StockOrders (client equity snapshot) | Tier 2 |
| 125 | NetNewTrades | Fact_CustomerAction | — | NewTrades - NumberOfClosedPositions | Tier 2 |
| 126 | NetDeposit | Fact_CustomerAction | — | Deposits - Cashouts | Tier 2 |
| 127 | OtherCompensationAmount | Fact_CustomerAction | Amount | SUM of misc compensation not in standard categories | Tier 2 |
| 128 | InvestedInManualTradeing | Fact_CustomerAction | Amount | SUM invested in manually opened trades on @date | Tier 2 |
| 129 | RealizedEquityCalculated | Multiple | — | Derived from realized equity movements (realizedEquity ± adjustments) | Tier 2 |
| 130 | NewCopyNetActions | Fact_CustomerAction | — | NewCopyActions - StopCopyActions | Tier 2 |
| 131 | InvestedInStocksManual | Fact_CustomerAction | Amount | SUM invested in manual stocks positions on @date | Tier 2 |
| 132 | InvestedInCryptoManual | Fact_CustomerAction | Amount | SUM invested in manual crypto positions on @date | Tier 2 |
| 133 | InvestedInCopyIncludingCash | Fact_CustomerAction | Amount | SUM total allocated to copy trading (incl. idle cash in copy) | Tier 2 |
| 134 | NewCopyUniqueUsers | Fact_CustomerAction | — | COUNT distinct popular investors copied by this customer on @date | Tier 2 |
| 135 | NetMoneyIntoExistingCopy | Fact_CustomerAction | Amount | Net money movement into existing copy relationships | Tier 2 |
| 136 | MoneyIntoExistingCopy | Fact_CustomerAction | Amount | Gross money added to existing copy relationships | Tier 2 |
| 137 | NetMoneyIntoCopy | Fact_CustomerAction | Amount | Net money movement into all copy relationships (new + existing) | Tier 2 |
| 138 | FTDAmountEver | Fact_CustomerAction | Amount | First time deposit amount (lifetime, not necessarily on @date) | Tier 2 |
| 139 | CustomerPnL | Fact_CustomerAction | NetProfit | SUM total customer net profit (closed positions) | Tier 2 |
| 140 | CustomerPnLStocks | Fact_CustomerAction | NetProfit | SUM customer net profit from stocks | Tier 2 |
| 141 | CustomerPnLCopy | Fact_CustomerAction | NetProfit | SUM customer net profit from copy positions | Tier 2 |
| 142 | CustomerPnLManual | Fact_CustomerAction | NetProfit | SUM customer net profit from manual positions | Tier 2 |
| 143 | CustomerPnLCrypto | Fact_CustomerAction | NetProfit | SUM customer net profit from crypto | Tier 2 |
| 144 | CustomerPnLStocksReal | Fact_CustomerAction | NetProfit | SUM customer net profit from real stocks | Tier 2 |
| 145 | CustomerPnLCryptoReal | Fact_CustomerAction | NetProfit | SUM customer net profit from real crypto | Tier 2 |
| 146 | FullTotalCommissionFromBreakdown | Fact_CustomerAction | Commission | Full commission cross-validated from position-level breakdown | Tier 2 |
| 147 | TotalCommissionFromBreakdown | Fact_CustomerAction | Commission | Total commission cross-validated from position-level breakdown | Tier 2 |
| 148 | CashoutsAdjusted | Fact_CustomerAction | Amount | Cashouts adjusted for redemptions/reversals | Tier 2 |
| 149 | AdjustedNetDeposit | Multiple | — | NetDeposit adjusted for cashout reversals and redemptions | Tier 2 |
| 150 | UnrealizedPnL | Fact_CustomerUnrealized_PnL | — | Total unrealized P&L snapshot for @date | Tier 2 |
| 151 | CustomerZeroPnL | Fact_CustomerAction | — | FLAG: 1 if CustomerPnL = 0 (zero net profit) | Tier 2 |
| 152 | CustomerZeroPnLAdjusted | Fact_CustomerAction | — | FLAG: 1 if CustomerPnLAdjusted = 0 | Tier 2 |
| 153 | CustomerCopyZeroPnL | Fact_CustomerAction | — | FLAG: 1 if CustomerPnLCopy = 0 | Tier 2 |
| 154 | CustomerStocksZeroPnL | Fact_CustomerAction | — | FLAG: 1 if CustomerPnLStocks = 0 | Tier 2 |
| 155 | CustomerPnLAdjusted | Fact_CustomerAction | — | CustomerPnL adjusted for P&L adjustment actions | Tier 2 |
| 156 | Redeposit | Fact_CustomerAction | — | FLAG or amount: customer made a subsequent deposit (not first deposit) | Tier 2 |
| 157 | CashedOutDefinition2 | Fact_CustomerAction | — | FLAG: alternative cashout definition (specific regulatory reporting) | Tier 2 |
| 158 | StockTraderWithProfit | Fact_CustomerAction | — | FLAG: 1 if stock trader with positive net profit on @date | Tier 2 |
| 159 | StockTraderWithLoss | Fact_CustomerAction | — | FLAG: 1 if stock trader with negative net profit on @date | Tier 2 |
| 160 | CopyTraderWithProfit | Fact_CustomerAction | — | FLAG: 1 if copy trader with positive net profit on @date | Tier 2 |
| 161 | CopyTraderWithLoss | Fact_CustomerAction | — | FLAG: 1 if copy trader with negative net profit on @date | Tier 2 |
| 162 | TraderWithProfit | Fact_CustomerAction | — | FLAG: 1 if customer (any type) had positive net profit on @date | Tier 2 |
| 163 | TraderWithLoss | Fact_CustomerAction | — | FLAG: 1 if customer (any type) had negative net profit on @date | Tier 2 |
| 164 | Credit | BI_DB_Client_Balance_CID_Level_New | Credit | Credit balance (non-withdrawable) from #ClientBalance | Tier 2 |
| 165 | UpdateDate | SP_DDR | — | GETDATE() at SP execution time — ETL run timestamp, not a business date | Tier 2 |
| 166 | FirstTimeFunded | Function_Population_First_Time_Funded | — | CASE WHEN f1.RealCID IS NOT NULL THEN 1 ELSE 0 — 5-criteria FTF flag (FTD+Verified+Trade/IOB/Options) | Tier 2 |
| 167 | Funded_New_Def | Multiple | — | CASE WHEN Equity>0 AND VerificationLevelID=3 AND FirstActionType<>'NoAction' THEN 1 ELSE 0 | Tier 2 |
| 168 | FTDCurrentYear | Fact_CustomerAction | — | FLAG: 1 if customer's first time deposit occurred in the current calendar year | Tier 2 |
| 169 | ReportDate | SP_DDR parameter | @date | DATEADD(DAY,1,@date) — the day after the data date (report delivery date) | Tier 2 |
| 170 | ReportDateID | SP_DDR parameter | @date | CONVERT(int, CONVERT(varchar(8), DATEADD(DAY,1,@date), 112)) | Tier 2 |
| 171 | DormantFee | Fact_CustomerAction | Amount | SUM of dormant account fee charges | Tier 2 |
| 172 | InvestedInCryptoTRS | Fact_CustomerAction | Amount | SUM invested in crypto TRS (total return swaps) positions | Tier 2 |
| 173 | TotalCash | BI_DB_Client_Balance_CID_Level_New | TotalCash | Used in Equity computation; cash component of client balance | Tier 2 |
| 174 | — | — | — | Note: TotalCash is an intermediate calculation in #ClientBalance, not a standalone DDR column | — |

> **Note**: Column #173/174 entry is a clarification note — TotalCash from #ClientBalance feeds into the Equity formula but does not appear as a standalone column in the DDR table. All 174 DDL columns are accounted for in rows 1–172.

## Source Assembly — #CIDAgg

SP_DDR assembles all metrics in the `#CIDAgg` temp table via LEFT JOINs from `#allUsers` (the CID universe). Source temp tables:

| Temp Table | Source Object | Role in #CIDAgg |
|------------|---------------|-----------------|
| #fsc2days | Fact_SnapshotCustomer + dim tables | Customer attributes, regulatory segments, flags |
| #fca | Fact_CustomerAction | All transaction/action metrics (deposits, commissions, etc.) |
| #FirstActionsFinal | Fact_CustomerAction | First deposit/trade action metadata per CID |
| #tradersActive | Fact_CustomerAction | Active trader/depositor flags |
| #customerUnrealizedNewMetrics | Fact_CustomerUnrealized_PnL | Unrealized P&L and daily changes |
| #liabilities | V_Liabilities | TotalLiability per CID |
| #fse2days | Fact_SnapshotEquity | NOP metrics, PositionPNL, PositionAmount |
| #ClientBalance | BI_DB_Client_Balance_CID_Level_New | InProcessCashout, Credit, TotalCash, StockOrders |
| #FTF | Function_Population_First_Time_Funded() | FirstTimeFunded flag |
| #GermanBaFin | V_GermanBaFin | IsGermanBaFin flag |
| #allUsers | Fact_CustomerAction ∪ #ClientBalance | Master CID universe for @date |

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_* ──────→ #fsc2days (customer attributes for @dateID)
DWH_dbo.Fact_CustomerAction ─────────────────→ #fca (transactions for @date)
                                             → #FirstActionsFinal (first actions per CID)
                                             → #tradersActive (activity flags)
DWH_dbo.Fact_CustomerUnrealized_PnL ────────→ #customerUnrealizedNewMetrics (PnL changes)
DWH_dbo.V_Liabilities ──────────────────────→ #liabilities (liability per CID)
DWH_dbo.Fact_SnapshotEquity ────────────────→ #fse2days (NOP/equity snapshot for @dateID)
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New→ #ClientBalance (cash balance components)
Function_Population_First_Time_Funded() ─────→ #FTF (5-criteria FTF flag)
DWH_dbo.V_GermanBaFin ──────────────────────→ #GermanBaFin (regulatory flag)

#fca ∪ #ClientBalance → #allUsers (CID universe)

#allUsers LEFT JOIN all temp tables → #CIDAgg (174-column aggregate)

DELETE FROM BI_DB_dbo.BI_DB_DDR_CID_Level WHERE DateID = @dateID
INSERT INTO BI_DB_dbo.BI_DB_DDR_CID_Level SELECT * FROM #CIDAgg

↓ (downstream readers)
BI_DB_dbo.SP_DDR_Auxiliary_Metrics → BI_DB_dbo.BI_DB_DDR_CID_Level_Auxiliary_Metrics
BI_DB_dbo.SP_DDR → BI_DB_dbo.BI_DB_DDR_Daily_Aggregated (GROUP BY from #CIDAgg)
```

## UC External Lineage

UC Target: `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level`
UC Format: Delta
Synapse → UC via Generic Pipeline (generic_pipeline_mapping.json entry confirmed)
