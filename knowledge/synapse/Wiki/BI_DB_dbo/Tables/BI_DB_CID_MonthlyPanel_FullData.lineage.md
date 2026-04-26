# BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData — Column Lineage

## Writer
`BI_DB_dbo.SP_CID_MonthlyPanel_FullData` — Author: Amir Gurewitz (2019-07-18); extended through 2025-07-13 by Tom Boksenbojm, Guy Manova, Luda Garces, Or Filizer, Adva Jakobson, Eden Winkler, Eti Rozolio, Tal Cohen, Boris, and others.

- **OpsDB**: Priority 0, FrequencySP = SB_Daily (run daily)
- **Pattern**: `DELETE WHERE ActiveDate = @BeginOfMonth` → `INSERT` → 4× POST-INSERT UPDATE passes
- **Self-reference**: Reads prior month's row via `WHERE ActiveDate = DATEADD(MONTH,-1,@BeginOfMonth)` to seed ACC_ accumulating columns
- **LTV exception**: LTV_1Y, LTV_3Y, LTV_8Y, LTV_8Y_NoExtreme, LTV_Expected_bySeniority, NoExtremeLTV_Expected_bySeniority inserted as `0`; written separately by `SP_LTV_BI_Actual`

---

## ETL Pipeline Diagram

```
Production Sources                DWH Layer                  BI_DB Intermediates
────────────────────────────────────────────────────────────────────────────────
etoro.Customer.Customer         →  Dim_Customer              
etoro.Dictionary.PlayerLevel    →  Dim_PlayerLevel (EOM club)
etoro.Dictionary.Country        →  Dim_Country            
etoro.Dictionary.Regulation     →  Dim_Regulation         
etoro.Dealing.Position          →  Fact_CustomerAction    ──→ #Active, #ActiveOpen, #rev
                                →  Fact_SnapshotCustomer  ──→ #CIDs (EOM equity, club, reg)
                                →  Dim_Range (SCD2)        ──→ EOM club/regulation snapshot
                                →  V_Liabilities           ──→ EOM equity/balance
                                →  Dim_Mirror              ──→ #mrr, #addmrr (mirror flags)
BI_DB_DailyCommisionReport      ──────────────────────────────→ #rev (FullCommissions)
BI_DB_PositionPnL               ──────────────────────────────→ #pnl
BI_DB_CIDFirstDates             ──────────────────────────────→ FTDdate, RegDate
BI_DB_First5Actions             ──────────────────────────────→ FirstAction, FirstInstrument
BI_DB_NewBonusReport            ──────────────────────────────→ bonus context
BI_DB_CID_DailyCluster          ──────────────────────────────→ ClusterDetail
BI_DB_CID_LifeStageDefinition   ──────────────────────────────→ #LifeStage (EOM_LSD)
BI_DB_V_DDR_Daily_Panel         ──────────────────────────────→ #AdCO (CashoutsAdjusted)
BI_DB_SF_Cases_Panel            ──────────────────────────────→ #AML (LastAMLTicketDate) [POST-UPDATE]
BI_DB_CID_MonthlyPanel_FullData ──────────────────────────────→ #History (prior month ACC_ seed)
Ext. External_BI_OUTPUT_Customer_ProfessionalCustomers ──────→ IsPro
Function_Revenue_ConversionFee  ──────────────────────────────→ Revenue_ConversionFees
Function_Revenue_AdminFee       ──────────────────────────────→ Revenue_IslamicFees (partial)
Function_Revenue_SpotAdjustFee  ──────────────────────────────→ Revenue_IslamicFees (partial)
Function_Revenue_TicketFee      ──────────────────────────────→ Revenue_TicketFees
Function_Revenue_TicketFeeByPercent ──────────────────────────→ Revenue_TicketFeeByPercent
                                                               ↓
                                              BI_DB_CID_MonthlyPanel_FullData
                                                               ↑
                               SP_LTV_BI_Actual (separate run) ─→ LTV_1Y/3Y/8Y columns (UPDATE)
                               SP_CID_MonthlyPanel_FullData  ───→ Seniority_FundedNew (POST-UPDATE)
                                                                → IsChurn_ThisM / IsWB_ThisM (POST-UPDATE)
                                                                → LastAMLTicketDate (POST-UPDATE)
```

---

## Source Table Reference

| Source Table | Schema | Join/Use | Target Columns |
|---|---|---|---|
| Fact_SnapshotCustomer | DWH_dbo | CID EOM snapshot; DATEADD(MM,-1,@nextM) date | EOM_Equity, EOM_Balance, EOM_Club, EOM_Regulation, EOM_IsFunded, IsEOM_Funded_NEW, IsPro, various demographic |
| Dim_Customer | DWH_dbo | Demographic attributes | CID, AffiliateID, Channel, SubChannel, Region, Country, AccountManager, IsIslamic, V2_Complete, V3_Complete, FirstAction, FirstInstrument, CountryID |
| Dim_Range (SCD2) | DWH_dbo | Current row (`END_DATE = '9999-01-01'`) | EOM_Club (via PlayerLevelName), EOM_Regulation (via RegulationName) |
| V_Liabilities | DWH_dbo | EOM equity/balance calculation | EOM_Equity (total), EOM_Balance (cash) |
| Fact_CustomerAction | DWH_dbo | Monthly grouped by CID, InstrumentType | Active_*, ActiveOpen_*, NewTrades_*, AmountIn_*, Revenue (FullCommissions), PnL_* |
| Dim_Mirror | DWH_dbo | Mirror/copy-add detection | ActiveOpen_Mirror (#mrr, #addmrr) |
| BI_DB_DailyCommisionReport | BI_DB_dbo | Monthly sum of commissions per CID | Revenue_Copy/Real_Stocks/CFD_Stocks/Real_Crypto/CFD_Crypto/FX_Comm_Ind/Other (FullCommissions) |
| BI_DB_PositionPnL | BI_DB_dbo | Monthly PnL by CID and instrument type | PnL_Copy/Real_Stocks/CFD_Stocks/Real_Crypto/CFD_Crypto/FX_Comm_Ind |
| BI_DB_CIDFirstDates | BI_DB_dbo | FTD and registration dates | FTDdate, FTD_Month, IsFTD_ThisM, Seniority, RegDate, RegMonth, IsReg_ThisM, FTDA |
| BI_DB_First5Actions | BI_DB_dbo | First action/instrument lookup | FirstAction (override), FirstInstrument (override) |
| BI_DB_NewBonusReport | BI_DB_dbo | Bonus context for cashflow | TotalDeposits, CountDeposits, TotalCashouts, NetDeposits context |
| BI_DB_CID_DailyCluster | BI_DB_dbo | Latest cluster for CID | ClusterDetail |
| BI_DB_CID_LifeStageDefinition | BI_DB_dbo | EOM life stage | EOM_LSD |
| BI_DB_V_DDR_Daily_Panel | BI_DB_dbo | CashoutsAdjusted for the period | CashoutsAdjusted |
| BI_DB_SF_Cases_Panel | BI_DB_dbo | AML case history | LastAMLTicketDate (POST-UPDATE) |
| BI_DB_CID_MonthlyPanel_FullData | BI_DB_dbo | Prior month row (DATEADD(MM,-1,@BeginOfMonth)) | ACC_ column seeds; IsChurn_ThisM/IsWB_ThisM base |
| External_BI_OUTPUT_Customer_ProfessionalCustomers | BI_DB_dbo | External table (professional clients) | IsPro |
| Function_Revenue_ConversionFee | BI_DB_dbo | Called per CID for the month | Revenue_ConversionFees (#rev_convfees) |
| Function_Revenue_AdminFee | BI_DB_dbo | Called per CID for the month | Revenue_IslamicFees (partial: AdminFee) (#rev_adminfee) |
| Function_Revenue_SpotAdjustFee | BI_DB_dbo | Called per CID for the month | Revenue_IslamicFees (partial: SpotAdjustFee) (#rev_spotadjustfee) |
| Function_Revenue_TicketFee | BI_DB_dbo | Called per CID for the month | Revenue_TicketFees, Revenue_Real_Stocks_Lev1 (partial) (#rev_ticketfees) |
| Function_Revenue_TicketFeeByPercent | BI_DB_dbo | Called per CID for the month | Revenue_TicketFeeByPercent, Revenue_CFD_Stocks_LevCFD (partial), Revenue_CFD_Crypto_LevCFD (partial), Revenue_Real_Crypto_Lev1 (partial) (#rev_crypto_ticketfees) |

---

## Key Column Lineage

### Identity / Grain

| Column | Source | Transform |
|---|---|---|
| CID | Fact_SnapshotCustomer.CID | passthrough from #CIDs |
| ActiveDate | @BeginOfMonth (SP input) | `DATEFROMPARTS(YEAR(@date), MONTH(@date), 1)` |
| Active_Month | @month (SP-computed) | `CONVERT(char(7), @BeginOfMonth, 120)` padded to char(7) |
| UpdateDate | ETL-computed | `GETDATE()` at run time |

### Registration & Acquisition

| Column | Source | Transform |
|---|---|---|
| Seniority | BI_DB_CIDFirstDates.FirstDepositDate | `DATEDIFF(MONTH, FTDdate, @BeginOfMonth)` |
| RegDate | Fact_SnapshotCustomer / Dim_Customer | registration date passthrough |
| RegMonth | Dim_Customer.RegDate | `CONVERT(char(7), RegDate, 120)` |
| IsReg_ThisM | BI_DB_CIDFirstDates | `CASE WHEN RegDate BETWEEN @BeginOfMonth AND DATEADD(MM,1,@BeginOfMonth) THEN 1 ELSE 0 END` |
| FTDdate | BI_DB_CIDFirstDates.FirstDepositDate | passthrough |
| FTD_Month | BI_DB_CIDFirstDates | `CONVERT(char(7), FirstDepositDate, 120)` |
| IsFTD_ThisM | BI_DB_CIDFirstDates | flag if FTD falls in current month |
| FTDA | BI_DB_CIDFirstDates | First time deposit amount |
| Region | Dim_Customer.Region / Fact_SnapshotCustomer | marketing region name (passthrough) |
| Country | Dim_Customer.Country / Fact_SnapshotCustomer | country name (passthrough) |
| Channel, SubChannel | Dim_Customer (via Dim_Campaign join) | acquisition channel |
| AffiliateID | Dim_Customer.AffiliateID | passthrough |
| FirstAction | BI_DB_First5Actions (first action type) | instrument type of first trade |
| FirstInstrument | BI_DB_First5Actions (first instrument) | instrument name of first trade |
| V2_Complete | Dim_Customer | KYC level 2 flag |
| V3_Complete | Dim_Customer | KYC level 3 flag |

### EOM Classification

| Column | Source | Transform |
|---|---|---|
| EOM_Club | Dim_Range SCD2 current row via #CIDs | PlayerLevelName; Bronze split at $1,000 equity → LowBronze / HighBronze |
| EOM_Regulation | Dim_Range / Dim_Regulation via #CIDs | Regulation name string at EOM snapshot |
| EOM_Equity | V_Liabilities.Equity | EOM equity snapshot (USD) |
| EOM_Balance | V_Liabilities.Balance | EOM cash balance (USD) |
| EOM_Segment | — | Always NULL (reserved, never assigned) |
| ActiveUser | #CIDs derived | 1 if EOM_Equity > 0 (has any equity at month end) |
| EOM_IsFunded | #CIDs derived | Snapshot funded flag (legacy; from Fact_SnapshotCustomer IsFunded) |
| IsEOM_Funded_NEW | #CIDs.EOM_IsFunded_NEW | New funded definition at EOM |
| IsFunded_New | #CIDs.IsFunded_New | New funded definition (used for IsChurn/IsWB) |
| IsChurn_ThisM | BI_DB_CID_MonthlyPanel_FullData (POST-UPDATE) | 1 if prior month IsFunded_New=1 AND this month IsFunded_New=0 |
| IsWB_ThisM | BI_DB_CID_MonthlyPanel_FullData (POST-UPDATE) | 1 if prior month IsFunded_New=0 AND this month IsFunded_New=1 |
| EOM_LSD | BI_DB_CID_LifeStageDefinition.EOM_LSD | Life stage description at EOM (e.g., "Holder", "Active Open Club") |
| NewMarketingRegion | Dim_Customer / Fact_SnapshotCustomer | NewMarketingRegion label |
| ClusterDetail | BI_DB_CID_DailyCluster | Cluster segment name |
| CountryID | Dim_Customer.CountryID | FK → DWH_dbo.Dim_Country.CountryID |
| LastAMLTicketDate | BI_DB_SF_Cases_Panel (POST-UPDATE) | MAX(CreatedDate) WHERE ActionType_AtOpen LIKE '%AML%' AND date < @date |
| Seniority_FundedNew | BI_DB_CIDFirstDates + BI_DB_First5Actions (POST-UPDATE) | `DATEDIFF(MONTH, NewFunded_Date0, ActiveDate)` where NewFunded_Date0 = MAX(FTDDate_month, FirstAction_month, V3_month) |

### Activity

| Column | Source | Transform |
|---|---|---|
| Active | Fact_CustomerAction (#Active) | 1 if customer closed ≥1 position this month (any asset class) |
| ActiveOpen | SP derived (post-insert from ActiveOpen sub-flags) | `CASE WHEN ActiveOpen_Manual=1 OR ActiveOpen_NewMirror=1 OR ActiveOpen_AddMirror=1 THEN 1 ELSE 0 END` (Or Filizer 2025-01-06) |
| Active_[AssetClass] | Fact_CustomerAction grouped monthly | 1 if customer closed ≥1 position in that asset class |
| ActiveOpen_[AssetClass] | Fact_CustomerAction / Dim_Mirror | 1 if open position in asset class at EOM |
| ActiveOpen_AirDrop | #ActiveOpen.ActiveOpen_AirDrop | 1 if has open airdrop-type position at EOM |
| ActiveOpen_Mirror | Dim_Mirror (#mrr + #addmrr) | `CASE WHEN ActiveOpen_NewMirror=1 OR ActiveOpen_AddMirror=1 THEN 1 ELSE 0 END` |
| ActiveOpen_Manual | #ActiveOpen.ActiveOpen_Manual | 1 if has manually-opened position at EOM |
| ActiveOpen_IncludeCopy | #ActiveOpen.ActiveOpen_IncludeCopy | 1 if has open position including copy trades |
| ActiveOpenManual | #ActiveOpen.ActiveOpenManual | Count of open manual positions (note: stores count, not flag) |
| ActiveOpenWOAirdrop | #ActiveOpen.ActiveOpenWOAirdrop | Active open count excluding airdrop positions |
| ActiveOpenWOAirdropManual | #ActiveOpen.ActiveOpenWOAirdropManual | Active open count excluding airdrop, manual-only |
| NewTrades_[AssetClass] | Fact_CustomerAction monthly count | Count of newly opened positions in that asset class |
| AmountIn_NewTrades_[AssetClass] | Fact_CustomerAction | USD amount allocated to new positions in that asset class |

### Revenue

| Column | Source | Transform |
|---|---|---|
| Revenue_[AssetClass] | BI_DB_DailyCommisionReport (#rev) | Monthly sum of FullCommissions by asset class |
| Revenue_Total | BI_DB_DailyCommisionReport | Legacy sum of FullCommissions only (no function fees) |
| Revenue_IslamicFees | Function_Revenue_AdminFee + Function_Revenue_SpotAdjustFee | Islamic swap-free account fee components: AdminFee + SpotAdjustFee |
| Revenue_TicketFees | Function_Revenue_TicketFee | Per-position ticket fees |
| Revenue_ConversionFees | Function_Revenue_ConversionFee | Currency conversion fees |
| Revenue_TicketFeeByPercent | Function_Revenue_TicketFeeByPercent | Percent-based ticket fees (crypto/stocks CFD levered) |
| Revenue_Total_New | All above combined | FullCommissions + AdminFee + TicketFees + ConversionFees + SpotAdjustFee + TicketFeeByPercent (Or Filizer 2025) |
| Transactional_Revenue_Total | Revenue_Total_New - Revenue_ConversionFees | Excludes currency conversion fees; pure trading/position revenue |
| A_Revenue_Currencies | BI_DB_DailyCommisionReport (#rev.A_Revenue_Currencies) | Revenue from currency CFD instruments |
| A_Revenue_Commodities | BI_DB_DailyCommisionReport | Revenue from commodity CFD instruments |
| A_Revenue_Crypto | BI_DB_DailyCommisionReport + TicketFeeByPercent | Revenue from all crypto subtypes combined (CFD + Real) |
| A_Revenue_Equities | BI_DB_DailyCommisionReport | Revenue from equity instruments |
| Revenue_[AssetClass]_Lev1/LevCFD | BI_DB_DailyCommisionReport (Lev sub-split) + partial TicketFeeByPercent | Revenue sub-tier: Lev1 = un-leveraged 1:1 longs; LevCFD = leveraged/short positions |

### Accumulated (ACC_) Columns

| Column | Source | Transform |
|---|---|---|
| ACC_Revenue_[AssetClass] | Self-reference #History + current month | prior month ACC_Revenue_[AssetClass] + this month Revenue_[AssetClass] |
| ACC_Revenue_Total | Self-reference | prior ACC_Revenue_Total + this month Revenue_Total (legacy formula) |
| ACC_Revenue_Total_New | Self-reference | prior ACC_Revenue_Total_New + this month Revenue_Total_New (2025 formula) |
| ACC_Transactional_Revenue_Total | Self-reference | prior ACC_Transactional_Revenue_Total + this month Transactional_Revenue_Total |
| A_ACC_Revenue_[AssetClass] | Self-reference | prior A_ACC_Revenue_[AssetClass] + this month A_Revenue_[AssetClass] |
| ACC_PnL_[AssetClass] | Self-reference | prior ACC_PnL_[AssetClass] + this month PnL_[AssetClass] |
| ACC_TotalDeposits | Self-reference | prior ACC_TotalDeposits + this month TotalDeposits |
| ACC_CountDeposits | Self-reference | prior ACC_CountDeposits + this month CountDeposits |
| ACC_TotalCashouts | Self-reference | prior ACC_TotalCashouts + this month TotalCashouts |
| ACC_TotalCoFee | Self-reference | prior ACC_TotalCoFee + this month TotalCoFee |
| ACC_NetDeposits | Self-reference | prior ACC_NetDeposits + this month NetDeposits |
| ACC_WithdrawalToWallet | Self-reference | prior ACC_WithdrawalToWallet + this month WithdrawalToWallet |

### LTV (Lifetime Value)

| Column | Source | Transform |
|---|---|---|
| LTV_1Y | SP_LTV_BI_Actual (separate UPDATE) | 1-year LTV model prediction; inserted as 0 by SP_CID_MonthlyPanel_FullData |
| LTV_3Y | SP_LTV_BI_Actual | 3-year LTV model prediction |
| LTV_8Y | SP_LTV_BI_Actual | 8-year LTV model prediction |
| LTV_8Y_NoExtreme | SP_LTV_BI_Actual | 8-year LTV excluding outlier customers |
| LTV_Expected_bySeniority | SP_LTV_BI_Actual | Expected LTV based on seniority cohort |
| NoExtremeLTV_Expected_bySeniority | SP_LTV_BI_Actual | No-extreme LTV by seniority cohort |

---

## Downstream Consumers

| Consumer SP / Object | Schema | Usage |
|---|---|---|
| SP_LTV_BI_Actual | BI_DB_dbo | Reads full table; writes LTV_1Y/3Y/8Y columns back via UPDATE |
| SP_BI_DB_LTV_Conversions_Multipliers_Table | BI_DB_dbo | LTV conversion modeling; reads revenue and segment data |
| SP_LTV_Multiplier_Model | BI_DB_dbo | LTV multiplier model |
| SP_M_LTV_Multipliers | BI_DB_dbo | LTV multiplier computation |
| SP_Group_LTV_Table | BI_DB_dbo | Group-level LTV analytics |
| SP_P_M_LTV_Multipliers | BI_DB_dbo | LTV multiplier pipeline |
| SP_CID_DailyPanel_FullData | BI_DB_dbo | Reads monthly panel for monthly ACC_ backfill context |
| SP_Cross_Selling_Monthly | BI_DB_dbo | Cross-sell analytics (monthly level) |
| SP_Cross_Selling_Daily | BI_DB_dbo | Cross-sell analytics (daily level using monthly reference) |
| SP_UsersEngagement | BI_DB_dbo | User engagement metrics |
| SP_CorpDevDashboard | BI_DB_dbo | Corporate development dashboard |
| SP_ClubUsersDataRemarketingGoogle | BI_DB_dbo | Google Ads Club-tier remarketing audiences |
| SP_AffiliatePaymentsReport | BI_DB_dbo | Affiliate commission reporting |
| SP_D_Compliance_Surveillance_KYC_PnL_Monitoring | BI_DB_dbo | KYC PnL compliance surveillance |
| SP_W_Compliance_Vulnerability_Detection | BI_DB_dbo | AML/vulnerability compliance detection |
| SP_Crypto_Top_1000_List | BI_DB_dbo | Crypto top 1000 customer list |
