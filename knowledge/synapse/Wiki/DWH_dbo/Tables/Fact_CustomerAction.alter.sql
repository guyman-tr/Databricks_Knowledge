-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_CustomerAction
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Fact_CustomerAction` is the unified customer event log for the eToro platform. Every significant action a customer performs - opening a position, closing a position, depositing money, withdrawing, logging in, publishing a social post, receiving a fee, getting a bonus, registering an account - is captured as a single row in this table. It answers: "What did this customer do, when, and what were the financial details?" The table consolidates events from five distinct production sources into a single ActionTypeID-driven schema: 1. **Position opens** (ActionTypeID 1-3, 39): From `Trade.OpenPositionEndOfDay` via the Generic Pipeline + staging 2. **Position closes** (ActionTypeID 4-6, 28, 40): From `History.ClosePositionEndOfDay` via the Generic Pipeline + staging 3. **Credit/financial events** (ActionTypeID 7-13, 15-20, 27, 30, 32, 34-38, 42-45): From `History.Credit` (which unions `History.ActiveCredit` + archived Credit partition tables back to 2007) 4. **Logins** (ActionTypeID 14): From `STS_Audit_U...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction SET TAGS (
    'domain' = 'customer',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(RealCID)',
    'synapse_index' = 'CLUSTERED COLUMNSTORE + 4 nonclustered',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN HistoryID COMMENT 'Intended as a unique key but contains duplicates - NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN GCID COMMENT 'Global Customer ID - the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DemoCID COMMENT 'Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 - ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Occurred COMMENT 'UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 - source-dependent)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IPNumber COMMENT 'IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 - STS/Billing.Login)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReal COMMENT 'Account type flag. Always 1 in this table (real accounts only). (Tier 3 - ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ActionTypeID COMMENT 'Event classifier - join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from **`CreditTypeID`** & branch router in loader + positional feeds. (Tier 1 - History.Credit / Trade snapshots / STS / Customer payloads)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformTypeID COMMENT 'Legacy platform discriminator (`0` default; `99` STS-heavy logins sampled 202601+). (Tier 3 - ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InstrumentID COMMENT 'FK to `Trade.Instrument`. Financial instrument being traded when row is instrument-bearing. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Amount COMMENT 'Position / ledger amount discipline per branch (cash change on opens; fee/deposit sizing on ledger rows - see lineage). Must be  >= 0 on trade opens historically. (Tier 1 - Trade.PositionTbl / History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Leverage COMMENT 'Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement posture. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN NetProfit COMMENT 'Realized PnL. 0 when open; populated on closes in position currency. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Commission COMMENT 'Open commission in dollars (`/100` cents conversion on ingest per `Dim_Position` lineage notes). (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PositionID COMMENT 'Surrogate bigint from `Internal.GetPositionID_Bigint` domain; unique trade position key. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CampaignID COMMENT 'Marketing campaign identifier - 0 if not campaign-bound. References `Dim_Campaign`. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN BonusTypeID COMMENT 'Bonus classifier on bonus credit rows (`ActionTypeID=9`). 0 elsewhere. References `Dim_BonusType`. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FundingTypeID COMMENT 'Ledger funding / wallet channel identifier (deposits & cash-outs). Nullable upstream coerced with `ISNULL(...,0)` sentinel row **`0`** (`Dim_FundingType.md`). **Value 27 pairs with redeem flag derivation on cash-outs.** References `Dim_FundingType`. (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN LoginID COMMENT 'Billing login session key (`Billing.Login` lineage). 0 off-login. (Tier 1 - Billing.Login)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MirrorID COMMENT 'FK to Trade.Mirror (`0`/NULL ⇒ manual trading; >0 ⇒ copy-trade child). (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawID COMMENT 'Withdrawal request identifier for cash-out credits; 0 when absent. (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DurationInSeconds COMMENT 'Login session dwell seconds (NULL outside login cashier events). (Tier 1 - Billing.Login)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostID COMMENT 'Social GUID for deprecated social action types (**21‑26**) - stale per historical wiki audits. NULL otherwise. (Tier 1 - Social platform)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CaseID COMMENT 'CRM case (`ActionTypeID=31`). 0 default. (Tier 1 - CRM)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN UpdateDate COMMENT 'Last successful fact loader write (`GETDATE()`/`GETUTCDATE()` parity in ops). (Tier 2 - SP_Fact_CustomerAction)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DateID COMMENT '**`Occurred`** -> `YYYYMMDD` int (nonclustered index driver). (Tier 2 - SP_Fact_CustomerAction)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN TimeID COMMENT 'Hour bucket `DATEPART(HOUR,Occurred)`. (Tier 2 - SP_Fact_CustomerAction)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN StatusID COMMENT 'Row vitality flag (**1** almost always; rare NULL cohort). (Tier 3 - ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PreviousOccurred COMMENT 'Deprecated / unreliable historical column - analysts should ignore. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CompensationReasonID COMMENT '`BackOffice.CompensationReason` code on comps & some opens for airdrops. (Tier 1 - History.Credit, updated wiki 2025-12)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawPaymentID COMMENT 'Payment-processing key for withdrawals; used to collapse duplicate WithdrawProcessing tuples per historical ETL memo. (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnClose COMMENT 'Close commission dollars - reopen-adjust net-of-original per `Dim_Position` wiki. **`CommissionOnCloseOrig` preserves untouched close fee.** (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPlug COMMENT 'Deprecated placeholder (`NULL`). (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DepositID COMMENT 'Deposit transaction reference on inbound money rows (`NULL` off-deposit actions). (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostRootID COMMENT 'Deprecated social threading key. NULL off-social. (Tier 1 - Social platform)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommission COMMENT 'Gross commission inclusive of hidden spread uplift at open (`/100` ingestion note). (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnClose COMMENT 'Gross commission on exit - symmetrical reopen-adjust story to `CommissionOnClose`. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemID COMMENT 'Billing.Redeem reference when position closed via redeem. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemStatus COMMENT 'Redemption state. Billing.Redeem integration. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SessionID COMMENT 'STS session BIGINT for opens/logins (`NULL` off those branches). (Tier 1 - STS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsRedeem COMMENT '**Dual-semantics redeem flag.** (A) **Ledger / Crypto-wallet Path:** Loader CASE documented in **`Dim_FundingType.md` section 2.3 (`CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`)** tagging **eToroCryptoWallet (`FundingTypeID=27`) cash-outs** (`ActionTypeID = 8` sample slice **100 % FundingType 27 whenever `IsRedeem=1`** for `DateID >= 20260101`). Revenue TVF **`Function_Revenue_TransferCoinFee`** filters **`Fact_CustomerAction` with `ActionTypeID = 30` AND `IsRedeem = 1`** - interpret as **transfer-to-coin / fiat-wallet -> on-chain custody** (**not** shorthand for bank cash-out). (B) **CFD Billing.Redeem Path:** Positional closes (`ActionTypeID∈{4,5,6,…}`) can emit **`IsRedeem=1` alongside `RedeemID`/`RedeemStatus`** (Billing.Redeem integration per `Trade.PositionTbl`) - orthogonal to transfercoin semantics. CLOSE-branch **`CASE` text unavailable** (`sys.sql_modules.definition` **NULL** for `SP_Fact_CustomerAction` on this Synapse warehouse). **Do not equate blindly to non-existent `...';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RegulationIDOnOpen COMMENT 'Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to etoro_History_BackOfficeCustomer (customer regulation history). ISNULL(..., 0) when no regulation match found. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformID COMMENT 'Product/platform identifier - badly named, references `Dim_Product.ProductID`; resolve Product/Platform/SubPlatform columns via JOIN (`ActionTypeID` **14**/ **41** focus). (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ReopenForPositionID COMMENT 'When position reopened: erroneous prior **`PositionID`**. NULL if virgin cycle. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReOpen COMMENT '1=this position was reopened from `ReopenForPositionID`. CASE WHEN **`ReopenForPositionID`** NOT NULL ⇒1 else0 default. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnCloseOrig COMMENT '**`CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0`** - preserves naive close commission before netting. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnCloseOrig COMMENT '**`CASE WHEN ReopenForPositionID IS NOT NULL THEN FullCommissionOnClose ELSE 0`** (default zeros). (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OriginalPositionID COMMENT 'Source position BEFORE partial-split chains. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseParent COMMENT 'Marks parent row around partial-close split (subject to **`SP_Fact_CustomerAction_IsParitalCloseParent`** post-job). Analyst filtering nuance persists from `Dim_Position` guidance. (Tier 5 - domain expert, SP_Fact_CustomerAction_IsParitalCloseParent)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseChild COMMENT 'Marks remainder leg after partial close - filter guidance identical to **`Dim_Position`**: avoid dropping CLOSE child rows blindly. (Tier 5 - domain expert, SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InitialUnits COMMENT 'Opening unit count denominator for partial proration ladders. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PaymentStatusID COMMENT 'Payment pipeline status IDs on inbound/outbound monies - join `Dim_PaymentStatus`. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsDiscounted COMMENT '1=commission discount applied at open (legacy bit widening). (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 - Expert Review)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionByUnits COMMENT 'Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 - Trade.Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionByUnits COMMENT 'Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 - Trade.Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFTD COMMENT 'First-Time Deposit tagging on qualifying deposit/action rows (NULL elsewhere). Derived during credit classification & snapshot merges. (Tier 2 - SP_Fact_CustomerAction)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CountryIDByIP COMMENT 'Geo-IP-derived country surrogate - join **`Dim_Country`**. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAnonymousIP COMMENT 'Anonymous / proxy heuristic flag STS path. NULL off relevant rows. (Tier 1 - IP geolocation service)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ProxyType COMMENT 'Proxy taxonomy (`DCH`, `VPN`, `TOR`, etc.) from STS classifications. NULL if direct. (Tier 1 - STS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFeeDividend COMMENT 'Fee subclass for **`ActionTypeID=35`** (1 nightly/weekend fee, 2 dividend, 3 SDRT, 4 ticket aggregates) encoded off **`Description`** heuristics (DSM‑1463). NULL off-fee rows. (Tier 2 - SP_Fact_CustomerAction)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAirDrop COMMENT '**`JOIN`** to **`etoro_Trade_PositionAirdropLog`** path per `Dim_Position` - 1 denotes airdrop-sourced crypto open. NULL otherwise. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DividendID COMMENT 'Dividend event pointer for dividend-driven fee deductions. NULL off-dividend. (Tier 1 - Trade.Positions/dividends lineage)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MoveMoneyReasonID COMMENT 'Dictionary.MoveMoneyReason code on internal sweeps (**5/6**/recurring enums per prior audits). References dictionary dimension. Some low-volume codepoints flagged `[UNVERIFIED]` historically in **`Dim_MoveMoneyReason`** - revalidate joins. (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SettlementTypeID COMMENT '**`Dictionary.SettlementTypes`** modern encoding (`0 CFD`, `1 REAL`, `2 TRS`, `3 CMT`, `4 REAL_FUTURES`, `5 MARGIN_TRADE`). Supersedes naïve `IsSettled` reads. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTOpen COMMENT 'Distributed-ledger telemetry captured at OPEN (Prod addition 2024‑06‑02 per dim wiki). NULL historical. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTClose COMMENT 'Ledger telemetry captured at CLOSE mirroring **`DLTOpen`**. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OpenMarkupByUnits COMMENT 'Prorated open markup **`OpenMarkup * AmountInUnitsDecimal / InitialUnits`** for partial closes. (Tier 1 - Trade.Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Description COMMENT 'Operational narrative pulled from Credits / fees ("Over night fee", ticket fee tokens, Payments deposit processor strings). (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsBuy COMMENT '**`1`** Long **`0`** Short; NULL ⇒ non-trade row sentinel. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CreditID COMMENT 'Direct pointer to **`History.Credit.CreditID`** lineage for reversible audits. Added 2025 loader wave. (Tier 1 - History.Credit)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN HistoryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DemoCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IPNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN NetProfit SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Commission SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CampaignID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN BonusTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN LoginID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DurationInSeconds SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CaseID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN TimeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PreviousOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CompensationReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPlug SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostRootID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SessionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsRedeem SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RegulationIDOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ReopenForPositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnCloseOrig SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnCloseOrig SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OriginalPositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseParent SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseChild SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InitialUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PaymentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsDiscounted SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CountryIDByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAnonymousIP SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ProxyType SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFeeDividend SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DividendID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MoveMoneyReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SettlementTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTClose SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OpenMarkupByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CreditID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Description SET TAGS ('pii' = 'none');

