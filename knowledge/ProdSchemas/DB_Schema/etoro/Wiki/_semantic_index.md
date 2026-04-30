# Semantic Index - etoro

> Cross-schema knowledge graph: business concepts, shared elements, and object relationships.
> Generated: 2026-03-17 | Updated: 2026-03-18 (BackOffice Phase 12 - added BackOffice concepts, shared elements, cross-schema deps, deprecated objects map)

---

## Business Concepts

| Concept | Primary Objects | Related Objects | Description |
|---------|----------------|-----------------|-------------|
| KYC Reconfirmation | Compliance.GetQuestionsExpirationPopulation, Compliance.GetQuestionsExpirationPopulationNew | Compliance.GetUkClassificationGapPopulation | Periodic re-confirmation of customer trading knowledge/experience per MiFID II. TTL-based expiry in seconds. |
| Document Expiration Campaign | Compliance.GetPOADocumentsExpirationPopulationFor3Years, Compliance.GetPOIDocumentsExpirationPopulation | 3 JUNK deprecated SPs | Identifies customers whose POA/POI verification documents are expiring for re-upload notification. |
| CFD Restriction Monitoring | Compliance.GetCustomerRestrictionException | Compliance.GetCustomerRestrictionDiff | MiFID II appropriateness testing enforcement: detecting restrictions and cross-system drift. |
| Regulation Management | Compliance.AddNewRegulation | Dictionary.Regulation | System administration for adding new financial regulatory authorities to the platform. |
| WorldCheck KYC/AML Integration | Compliance.GetCountryLongAbbreviation | Dictionary.Country | Country-to-ISO code mapping feed for WorldCheck sanctions/PEP screening. |
| UK Classification Gap | Compliance.GetUkClassificationGapPopulation | - | FCA COBS requirement to re-classify UK customers as Retail vs Elective Professional per questions 172/175. |
| Customer Master Record | Customer.CustomerStatic | Customer.CustomerMoney, History.Customer, Customer.LastChanges | The central 84-column table for all 18.7M eToro customers. Three triggers maintain full point-in-time version history in History.Customer. PII protected by Dynamic Data Masking. Single source of truth for identity, demographics, status, and trading config. |
| Balance Management (MIMO) | Customer.CustomerMoney, Customer.SetBalance | Customer.SetBalanceDeposit, Customer.SetBalanceCashOut, Customer.SetBalanceClosePosition, Customer.PostMIMOOperations | MIMO = Money In, Money Out. CustomerMoney holds the current live balance (Credit, BonusCredit, RealizedEquity, BSLRealFunds). SetBalance routes all financial events to 10 specialized sub-procedures (modern path) or handles 20+ legacy CreditTypeIDs inline. Multi-currency migration in progress (March 2026): CustomerMoney will become a VIEW over CustomerMoneyByCurrency + CustomerAccount. |
| 2FA / OTP Security | Customer.TwoFactorVerificationDetails | Customer.InsertTwoFactorVerificationDetails, Customer.UpdateTwoFactorVerificationDetails, Customer.UpdateTwoFactorVerificationTries, Customer.GetTwoFactorVerificationDetails, Customer.GetLatestTwoFactorVerificationDetails, Customer.GetTwoFactorVerificationFailedRequestCount, Customer.GetOTPAbusers | Each OTP challenge creates a row in TwoFactorVerificationDetails (GCID+ReferenceID). InsertTwoFactorVerificationDetails creates the challenge. UpdateTwoFactorVerificationDetails marks it verified. GetTwoFactorVerificationFailedRequestCount enforces per-user rate limits. GetOTPAbusers detects SMS abuse over 7-day windows. |
| Customer Registration | Customer.RegisterReal, Customer.RegisterDemo, Customer.RegisterIB | Customer.InsertRealCustomer, Customer.PostRegisterOperations, Customer.CustomerStatic, Customer.CustomerMoney | Three registration entry points (real/demo/IB). RegisterReal creates CustomerStatic + CustomerMoney rows. PostRegisterOperations handles post-registration side effects (MRN sync, dynamics, tracking). InsertRealCustomer is the atomic SP for real account creation. |
| Mirror Validation (CopyTrading) | Customer.GetMirrorValidationsByCID, Customer.GetMirrorValidationsByGCID | Customer.GetMirrorValidationValuesByCID, Customer.GetMirrorValidationValuesByGCID, Customer.P_GetMirrorValidationValuesByUserNameAndPassword | Provides validation data for CopyTrading (mirror) eligibility checks. Returns the values needed to determine whether a customer can copy/be copied. Multiple variants: by CID, by GCID, by username+password. |
| Privacy / GDPR Compliance | Customer.PrivacyUniqueIdentity, Customer.GDPRDeleteUser | Customer.GetPrivacyUniqueIdentity, Customer.SetPrivacyUniqueIdentityNew, Customer.DeletePrivacyUniqueIdentity, Customer.GetUsersPrivacyPoliciesByCIDs | Manages GDPR data subject rights. PrivacyUniqueIdentity stores pseudonymized identifiers. GDPRDeleteUser hard-deletes all PII for a customer on erasure request. GetUsersPrivacyPoliciesByCIDs returns the privacy policy versions accepted. |
| Refer-a-Friend (RAF) Program | Customer.RAFGiven, Customer.RafCIDInProcess | Customer.SetRafCompensation, Customer.RAFCompensationProcess_NogaJunk210725, Customer.RafGetByReferedGCIDs, Customer.RafGetReferralHistory_NogaJunk210725 | Tracks referral relationships and compensation. RAFGiven records awarded referral bonuses. RafCIDInProcess locks a CID during compensation processing to prevent double-awards. SetRafCompensation credits the referrer. Multiple JUNK-suffix objects indicate experimental/deprecated RAF variants. |
| Customer Latin Name Transliteration | Customer.CustomerLatinName, Customer.CustomerLatinNameFromNonLatin | Customer.SetCustomerLatinName, Customer.SetCustomerLatinNameFromNonLatin | CustomerStatic stores names in Unicode (nvarchar) supporting all scripts. CustomerLatinName stores the Latin/ASCII transliteration for systems requiring Latin characters. SetCustomerLatinNameFromNonLatin automates diacritic-stripping from non-Latin names. |
| Message Queue / Notification | Customer.MessageQueue, Customer.CustomerToMessageQueue | Customer.SendMessage, Customer.ReceiveMessage, Customer.ReceiveMessageAll | Internal messaging system. MessageQueue stores the messages. CustomerToMessageQueue links messages to recipients. SendMessage enqueues. ReceiveMessage/ReceiveMessageAll dequeues with locking. |
| Balance Stop Loss (BSL) | Customer.CustomerMoney (BSLRealFunds), Customer.PostMIMOOperations | Customer.SetBalance, Trade system | BSLRealFunds in CustomerMoney is the USD threshold for Balance Stop Loss. When customer equity drops to BSLRealFunds, the BSL system triggers position liquidation. PostMIMOOperations updates BSLRealFunds after each deposit/withdrawal. |
| Position Lifecycle | Trade.PositionTbl | Trade.PositionOpen, Trade.PositionClose, Trade.PostOpenPositionActions, Trade.PostClosePositionActions, History.PositionSlim | Every trade creates a row in Trade.PositionTbl (StatusID=1=Open). PositionClose sets StatusID=2 and moves the row to History.Position_Active. ~2.1M rows live at any time. Partitioned by PositionID%50; clustered on CID. Hundreds of procedures and views read or write this table. Central to all platform functions: margin, PnL, hedge exposure, CopyTrader, fees, and dividends. |
| Copy Trading (Mirror System) | Trade.Mirror | Trade.RegisterMirror, Trade.MirrorPauseCopy, Trade.MirrorReopen, Trade.PositionTreeInfo, Trade.PositionTbl (MirrorID, TreeID, ParentPositionID) | Copier (CID) follows leader (ParentCID) via a Mirror row with allocation amount and stop-loss (MSL) settings. MirrorID=0 in PositionTbl = manual trade; MirrorID>0 = copy position (FK to Trade.Mirror). TreeID links the copy hierarchy: root position has TreeID=own PositionID; children share root's TreeID; negative=demo. Mirror stop-loss closes the mirror when equity falls below threshold. |
| Two-Phase Order Execution | Trade.OrderForOpen, Trade.OrderForClose | Trade.OpenExecutionPlan, Trade.ExecutedOpenOrders, Trade.CloseExecutionPlan, Trade.ExecutedCloseOrders, Trade.OrderForOpenCreate, Trade.OrderForOpenJob | Customer requests enter as orders (REQUEST phase), are planned into execution plans (PLAN phase), and executed into ExecutedOrders (RESULT phase), producing PositionTbl rows. Bulk orders (CopyAll, CloseAll) fan out from one OrderID to multiple positions. Historical archive in DB_Logs.History.* (cross-DB, via 23 Trade schema synonyms). |
| Instrument Configuration | Trade.InstrumentMetaData, Trade.Instrument | Trade.ProviderToInstrument, Trade.SpreadGroup, Trade.FeeInPercentageConfigurations, Trade.FixPerLotConfigurations | All tradable instrument metadata: leverage limits, slippage, margin, min/max position sizes, exchange assignment (ExchangeID 4/5=NYSE/NASDAQ, InstrumentTypeID=10=Crypto). ProviderToInstrument links instruments to liquidity providers with overnight fee rates. Three fee mechanisms: overnight rollover (BuyOverNightFee/SellOverNightFee), fee-in-percentage, and fix-per-lot. SpreadGroup determines bid/ask spread markup per customer segment. |
| Liquidity Provider Routing | Trade.LiquidityProvider, Trade.LiquidityProviderContract | Trade.TradonomiContract, Trade.TradonomiToLiquidityProviderContracts, Trade.SetTradonomiToLPContracts, Trade.SetNextLiquidityProviderID | Tradonomi contracts (internal) map to Liquidity Provider contracts (external broker agreements). XML-driven batch updates (<ROOT><ADD .../><DELETE .../></ROOT>). SetNextLiquidityProviderID/AccountID rotate the active LP for load balancing. HedgeID in PositionTbl is populated once the LP executes the order (NULL until then). |
| US Regulatory Monitoring (Apex) | Trade.USAggregatePositionBySymbol | Trade.USAggregatePositionBySymbolForMonitor, Trade.UsUsersCryptoStat, Customer.CustomerStatic (ApexID, CountryGroupID=4) | US customers require Apex Clearing integration (ApexID IS NOT NULL in CustomerStatic). Daily position aggregation by symbol enforces Apex limits: $4M gross notional value; 40,000 shares per instrument. CountryGroupID=4 identifies the US country group. Crypto stat reporting tracked separately via UsUsersCryptoStat. |
| OPS Config Management | Trade.UpdateInstrumentsTradingConfigurations | Trade.Update*Configurations* SPs, Trade.Validate*Configurations* SPs (XML or TVP input) | 30+ OPS-facing configuration SPs update instrument metadata, fee tables, interest rates, and rollover fees. Two patterns: XML-driven (older) and TVP-driven (modern, using 126 User Defined Types). All wrap in BEGIN TRY/COMMIT + CATCH/ROLLBACK RETURN(0/-1). Caller identity stamped via CONTEXT_INFO=CAST(@AppLoginName AS VARBINARY(128)) for trigger audit trail. |

---

## Shared Elements

| Element | Appears In | Description |
|---------|-----------|-------------|
| GCID | GetCustomerRestrictionDiff, GetCustomerRestrictionException, GetPOADocumentsExpirationPopulationFor3Years, GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325, GetPOADocumentsExpirationPopulation_JUNKYulia0325, GetPOIDocumentsExpirationPopulation, GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325, GetQuestionsExpirationPopulation, GetQuestionsExpirationPopulationNew, GetUkClassificationGapPopulation, Customer.CustomerStatic, Customer.TwoFactorVerificationDetails, Customer.CustomerMoney, 100+ Customer SPs/Views/Functions | Global Customer ID (Group Customer ID) - eToro's universal cross-system customer identifier linking accounts across products. Integer, nullable (NULL for pre-GCID era accounts). Appears as a column in core tables and as @gcid parameter in most Customer SPs. |
| CID | GetCustomerRestrictionException, GetPOADocumentsExpirationPopulationFor3Years, GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325, GetPOADocumentsExpirationPopulation_JUNKYulia0325, GetPOIDocumentsExpirationPopulation, GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325, Customer.CustomerStatic (PK), Customer.CustomerMoney (PK), 178 Customer SPs | eToro per-entity integer customer ID. Primary key in CustomerStatic and CustomerMoney. The fundamental identifier within a single eToro entity/provider. |
| @BasePeriodSec | GetQuestionsExpirationPopulation, GetQuestionsExpirationPopulationNew, GetUkClassificationGapPopulation | TTL in seconds for KYC questionnaire answers. Typically 15552000 = 180 days. |
| @IsInternal | GetPOADocumentsExpirationPopulationFor3Years, GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325, GetPOADocumentsExpirationPopulation_JUNKYulia0325, GetPOIDocumentsExpirationPopulation, GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325, GetQuestionsExpirationPopulation, GetQuestionsExpirationPopulationNew | 0=external customers, 1=internal eToro employees (PlayerLevelID=4). Separates notification populations. |
| @StartDate | GetPOADocumentsExpirationPopulationFor3Years, GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325, GetPOADocumentsExpirationPopulation_JUNKYulia0325, GetPOIDocumentsExpirationPopulation, GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325 | Start of expiration window for document expiry SPs. |
| @MaxAllowedProcessingRowsPerCycle | GetPOADocumentsExpirationPopulation_JUNKYulia0325, GetPOIDocumentsExpirationPopulation | Dead parameter - declared but never referenced in query body. All rows always returned. Legacy batch design artifact. |
| RowNumber | GetPOADocumentsExpirationPopulationFor3Years, GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325, GetPOADocumentsExpirationPopulation_JUNKYulia0325, GetPOIDocumentsExpirationPopulation, GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325, GetQuestionsExpirationPopulation, GetQuestionsExpirationPopulationNew | Deduplication/pagination row rank. Always 1 in doc expiry result sets (latest document per customer). Used for page offset in KYC reconfirmation SPs. |
| Credit | Customer.CustomerMoney, Customer.SetBalance, Customer.SetBalanceDeposit, Customer.SetBalanceCashOut, Customer.SetBalanceClosePosition, Customer.SetBalanceBonus, Customer.SetBalanceChargeBack, 56 write SPs, 95 read SPs | The customer's current available USD balance. The core field updated by every financial event. Being split into per-currency rows in the multi-currency migration (March 2026). |
| PlayerStatusID | Customer.CustomerStatic, Customer.SetStatus, Customer.OperationBlockForCID, Customer.OperationUnBlockForCID | Compliance/trading status FK to Dictionary.PlayerStatus. 97.5% = 1 (Normal/Active). Changed by SetStatus. Non-1 values indicate restrictions ranging from partial blocks (deposit, copy) to full locks. |
| PlayerLevelID | Customer.CustomerStatic, Customer.SetPlayerLevel, Customer.SetPlayerLevelNoLot | Customer experience tier. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor (triggers IsHedged=0 via CustomerVersionUpdate trigger; treated as internal in Compliance SPs). |
| ReferenceID | Customer.TwoFactorVerificationDetails, Customer.InsertTwoFactorVerificationDetails, Customer.UpdateTwoFactorVerificationDetails, Customer.UpdateTwoFactorVerificationTries, Customer.GetTwoFactorVerificationDetails | Application-generated GUID uniquely identifying a 2FA OTP challenge session. NONCLUSTERED PK of TwoFactorVerificationDetails. Application retains this value across the 2FA lifecycle. |

---

## Trade Schema - Shared Elements

| Element | Appears In | Description |
|---------|-----------|-------------|
| PositionID | Trade.PositionTbl (PK), 300+ position SPs and views | Unique position identifier (BIGINT). Allocated by Internal.GetPositionID_Bigint. PartitionCol=PositionID%50 drives the table partition function PS_PositionTbl_BIGINT. Used as @PositionID parameter in all position-management SPs. |
| InstrumentID | Trade.PositionTbl, Trade.OrderForOpen, Trade.InstrumentMetaData, Trade.FeeInPercentageConfigurations, Trade.FixPerLotConfigurations, 200+ SPs/views | FK to Trade.Instrument. Identifies the financial instrument being traded (stock, crypto, forex, index, commodity). Used in fee lookup, hedge routing, US compliance aggregation, and all position lifecycle SPs. Also in Customer.GetActiveInstruments for provider-instrument availability. |
| MirrorID | Trade.PositionTbl (0/NULL=manual, >0=copy-trade; FK to Trade.Mirror), Trade.Mirror (IDENTITY PK) | Copy-trade identifier. 0 or NULL in PositionTbl = customer's own trade. Positive = copy position; FK to Trade.Mirror (copier-leader relationship). Used as @MirrorID parameter in all mirror-management SPs (RegisterMirror, MirrorPauseCopy, MirrorReopen, etc.). |
| TreeID | Trade.PositionTbl, Trade.PositionTreeInfo | Copy hierarchy root (BIGINT). Self-referencing: root position has TreeID=own PositionID; copier child positions inherit the root's TreeID. Demo positions use negative TreeID. PositionTreeInfo stores SL/TP/TSL settings at tree level shared across all positions in the tree. |
| IsSettled | Trade.PositionTbl, Trade.FnIsRealPosition, 50+ SPs | LEGACY BIT. 1=real stock (customer owns actual shares via Apex Clearing), 0=CFD (contract for difference). Superseded by SettlementTypeID for new positions. Used as fallback via Trade.FnIsRealPosition(IsSettled, InstrumentID) and ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)). |
| SettlementTypeID | Trade.PositionTbl, Trade.FnIsRealPosition, fee SPs | Modern settlement classification (tinyint). 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE (Dictionary.SettlementTypes). NULL for legacy positions (fallback to IsSettled). Determines which fee mechanism and margin treatment applies. |
| IsBuy | Trade.PositionTbl, Trade.OrderForOpen, 100+ SPs/views | Trade direction: 1=buy/long position, 0=sell/short position. Appears as column in position/order tables and as @IsBuy parameter in all order and position open/close procedures. |
| StatusID | Trade.PositionTbl (1=Open, 2=Closed), Trade.OrderForOpen, Trade.Mirror | Position/order/mirror state. In PositionTbl: 1=Open (live, accumulating PnL/fees), 2=Closed (terminated; row moved to History.Position_Active after close). Also used in OrderForOpen for order lifecycle state and in Mirror for mirror activity state. |
| NtileTreeID | Trade.PositionTbl, Trade.PositionTreeInfo, hedge exposure SPs | Parallel processing partition key (INT). Derived from TreeID for concurrent hedge aggregation without locking the full copy tree. Used internally by BSL (NewCheckBSL) and hedge exposure calculations. |
| ProviderID | Trade.PositionTbl, Trade.Provider (PK), Customer.CustomerStatic | FK to Trade.Provider. Execution provider/broker assignment. Default 1=TRADONOMI (set by PositionOpen). Also FK in Customer.CustomerStatic for customer-level provider assignment. Determines which liquidity provider contract is used for hedge routing. |
| HedgeID | Trade.PositionTbl, Trade.Hedge (PK) | FK to Trade.Hedge. The executed hedge at the liquidity provider. NULL in PositionTbl until the LP confirms execution. SetHedgeOrderID updates this after successful hedge. |

---

## Customer Schema - Key Cross-Schema Dependencies

| Customer Object | External Schema | Object | Usage |
|----------------|----------------|--------|-------|
| Customer.CustomerStatic | Trade | Trade.Provider | ProviderID FK - trading provider/broker assignment |
| Customer.CustomerStatic | Trade | Trade.SpreadGroup | SpreadGroupID FK - pricing group |
| Customer.CustomerStatic | BackOffice | BackOffice.Affiliate | SerialID FK - affiliate acquisition |
| Customer.CustomerStatic | BackOffice | BackOffice.Campaign | CampaignID FK - marketing campaign |
| Customer.CustomerStatic | Dictionary | Dictionary.Country (x3) | CountryID, CitizenshipCountryID, POBCountryID FKs |
| Customer.CustomerStatic | Dictionary | Dictionary.PlayerStatus | PlayerStatusID FK (critical: 97.5% = 1/Normal) |
| Customer.CustomerStatic | Dictionary | Dictionary.PlayerLevel | PlayerLevelID FK (4=Popular Investor triggers IsHedged=0) |
| Customer.CustomerStatic | History | History.Customer | Trigger-maintained version history (all INSERT/UPDATE/DELETE) |
| Customer.CustomerStatic | BackOffice | BackOffice.Customer | FXEligibilityDate updated on PlayerLevelID change via trigger |
| Customer.CustomerMoney | Customer | Customer.CustomerStatic | Implicit CID join - companion balance table |
| Customer.CustomerMoney | History | History.ActiveCredit_BIGINT | Append-only transaction ledger; CustomerMoney = current state |
| Customer.SetBalance | BackOffice | BackOffice.UpsertMIMOAggregation | Called after Deposit/CashOut/Bonus (CreditTypeIDs 1,2,7) for MIMO aggregation |
| Customer.RegisterReal | Trade | Trade system | Provider registration coordination |
| Customer.GDPRDeleteUser | Multiple schemas | CustomerStatic, CustomerMoney, Login, and cross-schema PII fields | Hard-deletes all PII per GDPR erasure request |
| Customer.GetActiveInstruments | Trade | Trade.Instrument | Returns active instrument list for the customer's provider |
| Customer.GetUSCustomersWithActiveCopiers | Trade | Trade.Mirror | Identifies US customers (CySEC accounts) with active copy relationships |
| Customer.PostMIMOOperations | Customer | Customer.CustomerMoney (BSLRealFunds) | Updates BSLRealFunds after deposit/withdrawal MIMO events |

---

## Cross-Schema Dependencies

| Compliance SP | External Schema | Object | Usage |
|--------------|----------------|--------|-------|
| AddNewRegulation | Dictionary | Regulation | INSERT + validation; calls dbo.Demo_AddNewRegulation |
| GetCountryLongAbbreviation | Dictionary | Country | SELECT CountryID, LongAbbreviation (all 251 rows) |
| GetCustomerRestrictionException | Trade | Position | Scans for manual CFD positions (MirrorID=0, IsSettled=0) |
| GetCustomerRestrictionException | Customer | CustomerStatic | CID->GCID join for restriction lookup |
| GetPOADocumentsExpirationPopulationFor3Years | BackOffice | CustomerDocumentToDocumentType, CustomerDocument, Customer | Document metadata and eligibility filters |
| GetPOADocumentsExpirationPopulationFor3Years | Customer | CustomerStatic | GCID, UserName, Email output + block status filter |
| GetPOADocumentsExpirationPopulationFor3Years | Dictionary | PlayerStatus | Blocked status IDs for exclusion |
| GetPOADocumentsExpirationPopulationFor3Years | Billing | Deposit | IsFTD=1 deposit eligibility check |
| GetPOIDocumentsExpirationPopulation | BackOffice | CustomerDocumentToDocumentType, CustomerDocument, Customer | Document metadata and eligibility filters |
| GetPOIDocumentsExpirationPopulation | Customer | Customer | GCID, UserName, Email + block/internal filters |
| GetPOIDocumentsExpirationPopulation | Dictionary | PlayerStatus | Blocked status IDs |
| GetPOIDocumentsExpirationPopulation | Billing | Deposit | PaymentStatusID=2 deposit eligibility |
| GetQuestionsExpirationPopulation | Customer | Customer | PlayerLevelID filter |
| GetQuestionsExpirationPopulation | BackOffice | Customer | VerificationLevelID=3, RegulationID filter |
| GetUkClassificationGapPopulation | Customer | CustomerStatic | CountryID=218 (UK) filter |

---

## Cross-DB Synonym Dependencies

| SP | Synonym | Points To | Purpose |
|----|---------|-----------|---------|
| GetCustomerRestrictionDiff | Compliance_CustomerRestriction_Compliance | ComplianceStateDB.Compliance.CustomerRestriction_v | Restriction state source of truth |
| GetCustomerRestrictionDiff | Compliance_CustomerRestriction_Settings | SettingsAzureDB.Compliance.CustomerRestriction_v | Configuration distribution copy |
| GetCustomerRestrictionException | Compliance_CustomerRestriction_v | ComplianceStateDB.Compliance.CustomerRestriction_v | Active restriction existence check |
| GetQuestionsExpirationPopulation | KYC_CustomerAnswers | UserApiDB.KYC.CustomerAnswers | Answer timestamps for expiry calculation |
| GetQuestionsExpirationPopulation | KYC_Questions | UserApiDB.KYC.Questions | Active question definitions |
| GetQuestionsExpirationPopulation | Compliance_WorkFlowDocumentState | ComplianceStateDB.Compliance.WorkFlowDocumentState | Active reconfirmation workflow exclusion |
| GetUkClassificationGapPopulation | KYC_CustomerAnswers | UserApiDB.KYC.CustomerAnswers | Questions 172/175 answer timestamps |
| GetUkClassificationGapPopulation | Compliance_CustomerRequirementsOverviewStatus | ComplianceStateDB.Compliance.CustomerRequirementsOverviewStatus | Open UK Classification requirement exclusion |

---

## Trade Schema - Key Cross-Schema Dependencies

| Trade Object | External Schema | Object | Usage |
|-------------|----------------|--------|-------|
| Trade.PositionTbl | Dictionary | SettlementTypes, PositionStatus, OrderType, Currency, InstrumentType, and 15+ others | FK source for all enum/status/type/classification columns; provides lookup values for status, settlement, currency, order type |
| Trade.PositionTbl | Customer | Customer.CustomerStatic | CID FK - customer identity and provider assignment; ApexID for US Apex Clearing customers |
| Trade.PositionClose | History | History.PositionSlim / History.Position_Active | Destination for closed positions: INSERT on close, then DELETE from PositionTbl; closed positions permanently archived here |
| Trade order SPs | DB_Logs.History | History.OrderForOpen, History.ExecutedOpenOrders, History.OpenExecutionPlan, etc. | Cross-DB order archive via 23 Trade schema synonyms pointing to DB_Logs database |
| Trade.USAggregatePositionBySymbol | Customer | Customer.CustomerStatic | ApexID IS NOT NULL + CountryGroupID=4 filter for US Apex Clearing customer identification |
| Trade.ProviderToInstrument | Dictionary | Dictionary.InstrumentType | InstrumentTypeID=10=Crypto, ExchangeID 4/5=NYSE/NASDAQ for US stock routing decisions |
| Trade.RegisterMirror | Customer | Customer.BlockedCustomerOperations | Copy restrictions (IsPublicReader, IsPrivateReader) checked before activating a mirror |
| Trade.GetActiveInstruments | Customer | Customer.CustomerStatic | ProviderID join for customer-provider instrument availability check |
| Trade.PayCashDividendByPayDate | Trade | Trade.Instrument, Trade.PositionTbl | Dividend payment to holders of real-stock positions (IsSettled=1 or SettlementTypeID=1) |
| Trade.PositionTbl | BackOffice | BackOffice.Affiliate, BackOffice.Campaign | Referenced indirectly via Customer.CustomerStatic for affiliate/campaign attribution on position open |

---

## Trade Schema - Cross-DB Synonym Dependencies

| Trade SP | Synonym | Points To | Purpose |
|----------|---------|-----------|---------|
| Order archive SPs | Trade.History_OrderForOpen | DB_Logs.History.OrderForOpen | Archive completed open orders (23 total synonym-based cross-DB links in Trade schema) |
| Order archive SPs | Trade.History_ExecutedOpenOrders | DB_Logs.History.ExecutedOpenOrders | Archive executed open order records |
| Order archive SPs | Trade.History_OpenExecutionPlan | DB_Logs.History.OpenExecutionPlan | Archive open execution plans |
| Order archive SPs | Trade.History_OrderForClose | DB_Logs.History.OrderForClose | Archive completed close orders |
| Order archive SPs | Trade.History_ExecutedCloseOrders | DB_Logs.History.ExecutedCloseOrders | Archive executed close order records |
| Position archive SPs | Trade.PositionSlim_Active | History.PositionSlim_Active | Active closed position slim read view (cross-schema) |
| Position archive SPs | Trade.PositionFail | History.PositionFail | Failed position archive (cross-schema) |

---

## BackOffice Schema - Business Concepts

| Concept | Primary Objects | Related Objects | Description |
|---------|----------------|-----------------|-------------|
| KYC/AML Customer Governance | BackOffice.Customer | BackOffice.CustomerDocument, BackOffice.CustomerDocumentToDocumentType, BackOffice.KYC, BackOffice.ElectronicIdentityCheck | BackOffice.Customer is the operational governance layer for all 18.7M customer accounts: RegulationID, VerificationLevelID, MifidCategorizationID, IsEDD, WorldCheckID, EIDStatusID. Documents flow through CustomerDocument (8.78M docs, AI-classified by Au10tix/Onfido) into CustomerDocumentToDocumentType (formal classification). KYC (US/regulated entity questionnaire). Three CustomerHistoryUpdate/Insert/Delete triggers maintain full History.BackOfficeCustomer audit trail. |
| BackOffice Staff Management | BackOffice.Manager | BackOffice.ManagerToPermission, BackOffice.Login, BackOffice.T_GroupsDictionary, BackOffice.T_ManagerAccessGroupToConnectionStrings | Manager is the user directory for all 960 BackOffice staff (505 active). Authentication via LogIn (Login+IsActive=1). ManagerID=0=System pseudo-account. UserGroupID assigns department (1=Admin, 3=Risk, 7=Sales, 8=Account Mgmt, 34=MimoOps, 35=MimoApps, 36=AML). ManagerGroupID routes queries to multi-environment DBs (346 managers, primarily MIMO ops). Every BackOffice action table stores ManagerID as the acting-agent reference. |
| Risk Alert Management | BackOffice.CustomerRisk, BackOffice.CustomerRisk_Updated_2308 | BackOffice.CustomerSetRiskStatus, BackOffice.GetCustomerRisks, BackOffice.NewRiskAlertsPCIVersion | CustomerRisk is the Risk team's alert registry. Composite PK on (GCID, RiskStatusID) - one flag per risk type per person. 1.46M rows for 1.36M unique GCIDs, 93% On (active). 90 risk types in 17 categories: deposit velocity, fraud, geo conflicts, document quality, FATF country, withdraw behavior. Lifecycle: automated rule fires -> On -> InProcess (agent investigating) -> Off (resolved). Drives account restrictions (deposit blocks, withdrawal suspensions, account freezes). |
| Customer Financial Aggregation (MIMO) | BackOffice.CustomerAllTimeAggregatedData_1 | BackOffice.CustomerDTDAggregatedData_1, BackOffice.CustomerMTDAggregatedData_1, BackOffice.CustomerMIMOAllTimeAggregatedData, BackOffice.UpsertIntoAggregationTablesAction | Three-tier aggregation: AllTime (lifetime), MTD (month-to-date by year/month), DTD (day-to-date by date). 6.736M rows (AllTime), one per CID. Continuously updated by UpsertIntoAggregationTablesAction from History.ActiveCredit events (CreditTypeID mapping: 1=Deposit, 2=Cashout, 4=Position close P&L, 7=Bonus, etc.). Drives BackOffice customer header, risk exposure reports, SalesForce CRM sync (LastOccurredTriggerToSF), and DWH pipeline. CustomerAllTimeAggregatedData (view, backward compat) wraps the _1 physical table. |
| Affiliate Program Management | BackOffice.Affiliate, BackOffice.AffiliateToUserGroup | BackOffice.AffiliateEdit, BackOffice.Campaign, BackOffice.CampaignGroup | 45,621 affiliate partners. AffiliateID = the affiliate's own CID. AffiliateStatusID=1(Normal)=93.2%. SpreadGroupID change cascades to all referred customers (Customer.Customer.SpreadGroupID update). Dynamics CRM sync via Service Broker on every AffiliateEdit. Campaign/CampaignGroup track marketing acquisition. CampaignID stored in Customer.CustomerStatic for attribution. |
| Regulatory Assignment and Trading Risk | BackOffice.Customer (TradingRiskStatusID, RegulationID, MifidCategorizationID) | BackOffice.RegulationChangeLog, BackOffice.ChangeCustomerRegulation | TradingRiskStatusID is a computed column on BackOffice.Customer deriving effective protection tier from regulation+categorization: 3=Standard Retail (88.3%), 4=Default/QA (9.3%), 1=Eligible Counterparty (2.4%), 2=Professional (0.01%). RegulationID changes trigger RegulationChangeLog insert + RegulationChangeDate update via CustomerHistoryUpdate trigger. DesignatedRegulationID handles multi-jurisdiction accounts (e.g., Australian customer under CySEC + ASIC constraint). |
| Withdrawal Approval Workflow | BackOffice.WithdrawApproval, BackOffice.RedeemApproval | BackOffice.WithdrawApprovalAdd, BackOffice.WithdrawApprovalGet, BackOffice.WithdrawApprovalUpsert, BackOffice.WithdrawRequestApprove, BackOffice.GetWithdrawRequests | Two-stage withdrawal review: RedeemApproval (copy trading exits) and WithdrawApproval (cash withdrawals). Both require ManagerID approval. GetWithdrawRequests returns pending withdrawal queue for agents. WithdrawRequestApprove finalizes approval. CalculateDailyLimitForRedeem/AutoExecution enforces per-customer daily limits. |
| Bonus Management | BackOffice.Bonus, BackOffice.BonusType, BackOffice.CampaignToBonusType, BackOffice.BonusOnlyCustomers | BackOffice.BonusAdd, BackOffice.BonusEdit, BackOffice.BonusLinkToCampaign | Bonus definitions (BonusType), individual bonus records (Bonus), and campaign-bonus linking (CampaignToBonusType). BonusOnlyCustomers tracks customers with bonus-only accounts. BackOffice agents add/edit bonuses and link them to campaigns for targeted promotions. |
| Scheduled Job Management | BackOffice.ScheduledJob, BackOffice.ScheduledJobHistory | BackOffice.ScheduledJobHistoryEdit, BackOffice.ScheduledJobHistoryGetLast, BackOffice.ScheduledJobsGet | Registry of automated BackOffice jobs and their execution history. BackOffice operations team monitors job health via ScheduledJobsGet. ScheduledJobHistoryEdit records run outcomes. |
| Task and Note Management | BackOffice.Task, BackOffice.CustomerNotes | BackOffice.TaskAdd, BackOffice.TaskAssign, BackOffice.TaskClose, BackOffice.CustomerEditComment | Task-based workflow system for BackOffice agents: create, assign, close. CustomerNotes stores historical comment records per customer. |

---

## BackOffice Schema - Shared Elements

| Element | Appears In | Description |
|---------|-----------|-------------|
| ManagerID | BackOffice.Manager (PK), BackOffice.Customer (x3: current/previous/FTD), BackOffice.CustomerRisk, BackOffice.CustomerDocument, BackOffice.KYC, BackOffice.Task, BackOffice.Downtime, BackOffice.RedeemApproval, BackOffice.WithdrawApproval, BackOffice.Affiliate, 40+ SPs | Universal "acting BackOffice agent" reference. ManagerID=0=System (automated); ManagerID=1=bootstrap admin. Every operational action in BackOffice carries a ManagerID for audit trail. BackOffice.Manager.IsActive=1 required for authentication. |
| GCID | BackOffice.CustomerRisk (PK part), BackOffice.CustomerDocument, BackOffice.CustomerMIMOAllTimeAggregatedData, BackOffice.CustomerMIMOMTDAggregatedData, BackOffice.CustomerMIMODTDAggregatedData, 30+ SPs | Group Customer ID (person-level). Links all CIDs across regulatory jurisdictions. GCID is the primary lookup key in document retrieval (GetAllUserDocuments), risk flag management (CustomerRisk composite PK), and MIMO aggregation. See Customer schema for full definition. |
| CID | BackOffice.Customer (PK), BackOffice.CustomerDocument, BackOffice.CustomerAllTimeAggregatedData_1, BackOffice.CustomerDTDAggregatedData_1, BackOffice.CustomerMTDAggregatedData_1, BackOffice.CustomerNotes, BackOffice.Bonus, 200+ SPs | Per-entity customer account ID. One-to-one with Customer.CustomerStatic.CID. PK of BackOffice.Customer, clustered key in CustomerDocument (CID, DocumentID), PK in all three aggregation tables. |
| VerificationLevelID | BackOffice.Customer (FK, indexed), Compliance SPs (eligibility filter >= 2) | KYC milestone level. 0=unverified(34.2%), 1=partial(12.4%), 2=intermediate(6.2%), 3=fully verified(47.1%). DEFAULT=0. Required to reach Level 3 for full withdrawal access. |
| RegulationID | BackOffice.Customer (FK WITH CHECK, NOT NULL DEFAULT=0), BackOffice.RegulationChangeLog | Primary regulatory assignment. Top values: CySEC(39.4%), BVI(38.9%), FCA(6.2%). Changes trigger RegulationChangeLog insert + RegulationChangeDate update. |
| TradingRiskStatusID | BackOffice.Customer (computed, always derived) | Computed risk protection tier: 3=Standard Retail(88.3%), 4=QA/default(9.3%), 1=Eligible Counterparty(2.4%), 2=Professional(0.01%). Never set directly - always recomputed from RegulationID + MifidCategorizationID + AsicClassificationID + SeychellesCategorizationID. |
| AffiliateID | BackOffice.Affiliate (PK), Customer.CustomerStatic (SerialID) | Affiliate's own customer CID. 45,621 affiliates. NOT an independent identity - maps directly to the customer's trading account. |

---

## BackOffice Schema - Cross-Schema Dependencies

| BackOffice Object | External Schema | Object | Usage |
|------------------|----------------|--------|-------|
| BackOffice.Customer | Customer | Customer.CustomerStatic | FK on CID - identity anchor for all 18.7M accounts |
| BackOffice.Customer | Dictionary | Regulation, VerificationLevel, MifidCategorization, SalesStatus, AcceptanceStatus, CashoutFeeGroup, GuruStatus, RiskClassification, GDCCheck, WorldCheck, UserGroup, EIDStatus (x14) | FK source for all status/classification columns |
| BackOffice.CustomerDocument | Customer | Customer.CustomerStatic | FK on CID - document ownership |
| BackOffice.CustomerDocument | Dictionary | DocumentType, DocumentSizeActionType | FK source for document classification |
| BackOffice.CustomerAllTimeAggregatedData_1 | Customer | Customer.CustomerMoney | LastRealizedEquity sourced at upsert time |
| BackOffice.CustomerAllTimeAggregatedData_1 | History | History.ActiveCredit | Credit events for all financial delta computations |
| BackOffice.CustomerAllTimeAggregatedData_1 | Billing | Billing.Deposit | FTD milestone date calculation |
| BackOffice.Manager | Dictionary | UserGroup, ManagerTitle | FK source for department and job title |
| BackOffice.Affiliate | Customer | Customer.Customer | SpreadGroupID cascade update on affiliate spread change |
| BackOffice.GetCustomerHeader | Customer | Customer.Customer | Primary source for name, balance, email, GCID |
| BackOffice.UpsertMIMOAggregation | Customer | Customer.SetBalance | Called after Deposit/CashOut/Bonus (CreditTypeIDs 1,2,7) |

---

## BackOffice Schema - Deprecated / JUNK Objects

| Deprecated Object | Type | Active Replacement | Reason Deprecated |
|------------------|------|-------------------|-------------------|
| BackOffice.JUNK_GetAggregateDepositByDayInterval | Function | BackOffice.GetAggregateAggregateCashoutByDayInterval (active variant) | JUNK prefix - decommissioned aggregate function; retained for audit history only |
| BackOffice.JUNK_GetCustomerSegment | Function | Active segmentation queries | Legacy customer segmentation function; JUNK prefix marks decommissioned |
| BackOffice.JUNK_PortFolio | Function | Active portfolio queries | Legacy portfolio function; JUNK prefix marks decommissioned |
| All BackOffice.JUNK_* functions | Function | Schema-specific active equivalents | Platform-wide JUNK_ convention: decommissioned, retained for audit history, must not be called in production |
| BackOffice.CustomerDocumentAdd_JUNKYulia0325 | SP | BackOffice.AddDocumentClassification | JUNK suffix - deprecated variant; replaced by active classification workflow |
| BackOffice.CheckPhoneVerifiedByAnotherCustomer_JunkNoga240325 | SP | BackOffice.CustomerIsPhoneVerified_JunkNoga240325 | Double-JUNK - both are deprecated phone verification procedures |
| BackOffice.JUNK_CashierHistory | View | Active billing/cashier reports | Legacy cashier history view; JUNK prefix marks as deprecated |
| BackOffice.JUNK_GetAverageLotCount | View | Active trading analytics | Legacy lot count aggregation view |

---

## Deprecated / Junk Objects Map

### Compliance Schema Deprecated Objects

| Deprecated SP | Active Replacement | Reason Deprecated |
|--------------|--------------------|-------------------|
| GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325 | GetPOADocumentsExpirationPopulationFor3Years | 1-year expiry, 15-day window, RUNTIME ERROR (missing INSERT target table) |
| GetPOADocumentsExpirationPopulation_JUNKYulia0325 | GetPOADocumentsExpirationPopulationFor3Years | 1-year expiry, 15-day window, dead @MaxAllowedProcessingRowsPerCycle parameter |
| GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325 | GetPOIDocumentsExpirationPopulation | Near-identical to active SP; @MaxAllowedProcessingRowsPerCycle commented out vs declared |

### Trade Schema Deprecated Objects

| Deprecated Object | Type | Active Replacement | Reason Deprecated |
|------------------|------|-------------------|-------------------|
| Trade.JUNK_ChangeMirrorAmount | SP | Trade.ChangeMirrorAmountForMoe | JUNK prefix convention - decommissioned; retained in SSDT for historical reference only; must not be called by applications |
| All Trade.JUNK_* SPs | SP | Schema-specific active equivalents | Platform-wide convention: JUNK_ prefix marks decommissioned procedures kept for audit history. Covers deprecated reporting, analytics, and operation utilities. Do not execute in production. |

---

## Schema Coverage

| Schema | Objects | Documented | Coverage |
|--------|---------|-----------|---------|
| Compliance | 12 | 12 | 100% |
| Customer | 253 | 253 | 100% |
| Trade | 1,422 | 1,422 | 100% |
| BackOffice | 502 | 502 | 100% |

*Index generated from: 12 Compliance + 253 Customer + 1,422 Trade + 502 BackOffice objects | Enrichment: 2026-03-18*
