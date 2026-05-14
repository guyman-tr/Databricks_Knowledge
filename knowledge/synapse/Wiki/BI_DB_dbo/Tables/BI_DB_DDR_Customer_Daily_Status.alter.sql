-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status > 13.3B-row DDR customer daily status dimension - full daily snapshot of every customer''s deposit status, account segmentation, FTD dates across all platforms (TP, IBAN, Options, MoneyFarm), regulation, login activity, and funded/active trading flags, providing the segmentation backbone for the entire DDR framework. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table (Dimension - DDR daily customer status snapshot) | | **Production Source** | Derived from 15+ sources via `SP_DDR_Customer_Daily_Status` - `BI_DB_Client_Balance_CID_Level_New`, `Dim_Customer`, `Fact_SnapshotCustomer`, `Fact_CustomerAction`, `eMoney_Fact_Transaction_Status`, `MIMO_AllPlatforms`, plus 5 population functions | | **Refresh** | Daily - `DELETE WHERE DateID = @dateID` + `INSERT` per business date | | | | | **Synapse Distribution**'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Date COMMENT 'Calendar business date evaluated by `SP_DDR_Customer_Daily_Status` (= `@date` parameter). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DateID COMMENT '`@dateID` (`YYYYMMDD`) - partition / delete key for the narrow table. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN RealCID COMMENT 'Real customer identifier (HASH distribution key). One row per `RealCID` per `DateID` after RN dedup. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTD_DateID COMMENT 'Trading-platform first-deposit surrogate key from `#globalDepositorsAlltime` (`CASE` branch where `Dim_FTDPlatform.FTDPlatformName = ''TradingPlatform''`). (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTD_Date COMMENT 'Trading-platform FTD timestamp (paired with TP_FTD_* IDs). Source CASE columns from aggregated `Dim_Customer`/`#globalFTDs`. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTDA COMMENT 'Trading-platform FTD amount (USD). CASE branch tied to TP platform FTD rows. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTD_DateID COMMENT 'IBAN / eMoney first-deposit surrogate key (`FTDPlatform = ''eMoney''` branch). (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTD_Date COMMENT 'IBAN FTD timestamp. CASE branch sourced from aggregated `Dim_Customer`. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTDA COMMENT 'IBAN FTD amount. CASE branch sourced from aggregated `Dim_Customer`. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_External_FTDA COMMENT 'External-facing TP FTD amount component sourced from aggregated MIMO prep (`TPExternalFTDA` path in `#enrichStatusActions`). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTD_DateID COMMENT 'Minimum first-deposit `DateID` across platform-specific FTD CASE outputs (`MinFirstDepositDateID`). Earliest-platform FTD. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTD_Date COMMENT 'Minimum first-deposit calendar datetime across platform branches (`MinFirstDepositDate`). (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTDA COMMENT 'FTD monetary amount paired with globally winning FTD date (chosen via CASE bundle in `#globalDepositorsAlltime`). (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsDepositorGlobal COMMENT 'Lifetime global depositor flag inside SP helper (`CASE WHEN FirstDepositDate > ''1900-01-01'' THEN 1 ELSE 0`). Mirrors “ever deposited anywhere” semantics feeding DDR depositors-login logic. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalDeposited COMMENT '1 if customer had a non-internal **Deposit** row on **`DateID`** in MIMO-prepared data (`GlobalDeposited` aggregator). Includes later Options-specific UPDATE patch paths. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalFirstDeposited COMMENT '1 if **global first deposit event** flagged on **`DateID`** (`IsGlobalFTD` path in `#mimoUsers` aggregations); subject to coercion inserts for Options gaps. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalRedeposited COMMENT '1 if customer deposited on **`DateID`** when **not** flagged as FTD (`IsGlobalFTD = 0`, non-internal). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalCashedOut COMMENT '1 if customer withdrew (non-internal) on **`DateID`**; redeemed-withdraw overlays may mark activity for FTD-timing fixes. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Redeemed COMMENT '1 if a **billing redeem-linked** withdrawal (`IsRedeem = 1` on `#mimo_coerced_withdraw` rollup) intersects **`DateID`**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedTP COMMENT '1 if **TradingPlatform** deposit (non-internal) occurred on **`DateID`**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedIBAN COMMENT '1 if **eMoney / IBAN** deposit (non-internal) occurred on **`DateID`**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedTP COMMENT '1 if **TP** redeposit (non-internal, non-FTD platform flag) occurred on **`DateID`**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedIBAN COMMENT '1 if **IBAN** redeposit occurred on **`DateID`** under redeposit CASE logic (`IsPlatformFTD = 0`). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TPFirstDeposited COMMENT '1 if **TradingPlatform FTD** (`IsPlatformFTD = 1`) occurred on **`DateID`**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBANFirstDeposited COMMENT '1 if **IBAN FTD** occurred on **`DateID`** under MIMO aggregations (`IsPlatformFTD = 1` on eMoney path). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TPExternalFirstDeposited COMMENT '1 if **external** TP FTD (non-internal transfer) flagged on **`DateID`**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ActiveTraded COMMENT '1 when `Function_Population_Active_Traders(@dateID,@dateID)` marks the CID as DDR-active (explicit trades / mirror participation / qualifying Options actions - see TVF wiki / SP commentary). Default `ISNULL` to 0 in INSERT. (Tier 2 - Function_Population_Active_Traders)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN BalanceOnlyAccount COMMENT 'Presence/measure flag from `Function_Population_Balance_Only_Accounts(@dateID,@dateID)` - customer had **positive equity** but **no** qualifying open-position / trading activity tiers. Stored as int indicator in INSERT path. (Tier 2 - Function_Population_Balance_Only_Accounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Portfolio_Only COMMENT '**`Function_Population_Portfolio_Only`** output persisted as DECIMAL per DDL - analytics treat nonzero as **portfolio/HODL** segment participation for `@date`. `AccountActive` tests `ISNULL(Portfolio_Only,0)` in SP logic. (Tier 2 - Function_Population_Portfolio_Only)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountActive COMMENT 'Derived: **`1` iff `ActiveTraded = 1 OR ISNULL(Portfolio_Only,0) <> 0`** (see `#enrichStatusActions`). Encapsulates intentional engagement vs inactive tiers. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountInActive COMMENT 'Derived flag for customers occupying the explicit **inactive** bucket after removing balanced segment winners (`EXCEPT` ladders in `#inactive`). Requires understanding mutual exclusivity with active tiers - see sibling periodic wiki diagrams. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN RegulationID COMMENT 'Customer''s assigned regulatory jurisdiction for the **`Fact_SnapshotCustomer` slice active on `@dateID`**. Taken from **`Fact_SnapshotCustomer.RegulationID`**. FK to **`Dim_Regulation`**. Same description spine as **`Fact_SnapshotCustomer`**. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DesignatedRegulationID COMMENT 'Secondary / designated jurisdiction from **`Fact_SnapshotCustomer.DesignatedRegulationID`**. FK to **`Dim_Regulation`**. Same meaning as **`Fact_SnapshotCustomer`**. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN PlayerStatusID COMMENT 'Customer lifecycle **`PlayerStatusID`** sourced from **`Fact_SnapshotCustomer`**. FK to **`Dim_PlayerStatus`**. Same meaning as **`Fact_SnapshotCustomer`**. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsCreditReportValidCB COMMENT '**`IsCreditReportValidCB = 1` is the regulatory-focused filter for Credit Balance reporting (CB = Client Balance). It includes a small number of subsidiary CB users that `IsValidCustomer` / analytic `IsValidUser` excludes from the standard CB view.** ETL CASE reference: **`Fact_SnapshotCustomer` section 2.3**. Column is **passed through from `Fact_SnapshotCustomer`** for the snapshot window intersecting **`@dateID`**. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsValidCustomer COMMENT '**`IsValidCustomer = 1` corresponds to analytic `IsValidUser = 1`: the standard business filter (excludes test / internal users); this is the DEFAULT filter for ~99% of analytics. The semantic is “user is real and tradeable for business analytics”. Popular Investors (PIs) are valid users - do NOT treat PIs as non-valid.** Physical column persists `Fact_SnapshotCustomer.IsValidCustomer` for **`@dateID`**. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountTypeID COMMENT '**`Fact_SnapshotCustomer.AccountTypeID`** (Back Office semantics). FK to **`Dim_AccountType`**. Used upstream in **`IsCreditReportValidCB`** logic. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN CountryID COMMENT '**`Fact_SnapshotCustomer.CountryID`** stored as DECIMAL in narrow table DDL - analytic meaning unchanged (registered country FK to **`Dim_Country`**). Same description lineage as **`Fact_SnapshotCustomer.CountryID`**. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MarketingRegion COMMENT '**`Dim_Country.MarketingRegionManualName`** per final INNER JOIN (`dc.CountryID = sa.CountryID`). Manual marketing-region override sourced from **`Ext_Dim_Country`** lineage per **`Dim_Country` wiki**. Same content meaning as **`Dim_Country.MarketingRegionManualName`**. (Tier 3 - Ext_Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MifidCategorizationID COMMENT '**`Fact_SnapshotCustomer.MifidCategorizationID`**, stored DECIMAL in DDL. MiFID categorization FK to **`Dim_MifidCategorization`**. Same meaning as Fact table column. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN PlayerLevelID COMMENT 'Account tier **`PlayerLevelID`** from **`Fact_SnapshotCustomer`**. FK to **`Dim_PlayerLevel`**. Critical upstream driver for analytic filters (paired with stewardship notes in **`Fact_SnapshotCustomer` section 2.2**). (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsDepositor COMMENT '**`Fact_SnapshotCustomer.IsDepositor`** (FTD sentinel from DWH ingestion) surfaced as **`int`** with `ISNULL(...,0)` in INSERT - same analytic meaning as **`Fact_SnapshotCustomer`**. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsFunded COMMENT 'Indicator that customer appears in **`Function_Population_Funded(@dateID)`** output for that date (`CASE WHEN Equity join exists`). (Tier 2 - Function_Population_Funded)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstTimeFunded COMMENT '1 when **`FirstFundedDateID = @dateID`** from **`Function_Population_First_Time_Funded`**. Signals first crossing into fully-funded DDR definition used by downstream dashboards. (Tier 2 - Function_Population_First_Time_Funded)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstFundedDateID COMMENT 'CID’s first-funded **`DateID`** from **`Function_Population_First_Time_Funded`**, **`ISNULL` -> `30000101`** sentinel when unknown. (Tier 2 - Function_Population_First_Time_Funded)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstActionType COMMENT 'First qualitative trading/action label from **`Function_Population_First_Trading_Action(1)`**, trimmed by CASE when future-dated vs `@dateID` ⇒ `''NoAction''`. **`ISNULL` -> `''NoAction''`** at insert shield. (Tier 2 - Function_Population_First_Trading_Action)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstActionDateID COMMENT '`FirstTradeDateID` surrogate passed through `#basicStatuses`; inserted as **`ISNULL(...,30000101)`**. Represents DDR “first meaningful action date” hooking TVF naming. (Tier 2 - Function_Population_First_Trading_Action)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedIn COMMENT '1 if **`Fact_CustomerAction`** has **`ActionTypeID = 14`** on **`@dateID`** for CID (login aggregator). **`ISNULL` -> 0** in INSERT. (Tier 2 - Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInTPDepositor COMMENT 'Login flag intersected with **TP FTD cohort** marker from **`#depositorsLoggedIn.TPDepositor`**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInIBANDepositor COMMENT 'Login ∧ **IBAN FTD** cohort (see `#depositorsLoggedIn.IBANDepositor`). (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInGlobalDepositor COMMENT 'Login ∧ **global depositor** marker from **`#globalDepositorsAlltime`** join. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN UpdateDate COMMENT '`GETDATE()` stamp at insert - operational telemetry, **not business event time**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstIOBDateID COMMENT '**`Function_Population_First_Time_Funded.FirstIOBDateID`**, first inbound balance event metadata (DDR IOB rollout per SP changelog). (Tier 2 - Function_Population_First_Time_Funded)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstIOBTime COMMENT '**`Function_Population_First_Time_Funded.FirstIOBTime`** pairing for IOB timestamps. (Tier 2 - Function_Population_First_Time_Funded)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTD_DateID COMMENT '**`#globalDepositorsAlltime` CASE branch** for **`FTDPlatform = ''Options''`** - Options platform FTD `DateID`. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTD_Date COMMENT 'Options FTD calendar datetime companion. Source CASE logic from **`Dim_Customer`**. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTDA COMMENT 'Options FTD amount branch from **`Dim_Customer`** aggregator; typed **`money`** in DDL. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN OptionsFirstDeposited COMMENT '**`#mimoUsers.OptionsFirstDeposited`** indicator for Options-platform FTDs executed on **`DateID`**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedOptions COMMENT '**`#mimoUsers.DepositedOptions`** indicator - deposit on Options channel on **`DateID`**. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedOptions COMMENT '**`#mimoUsers.ReDepositedOptions`** indicator - redeposit on Options **`DateID`**, non-first-deposit semantics. (Tier 2 - SP_DDR_Customer_Daily_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTD_DateID COMMENT '**`#globalDepositorsAlltime` CASE branch** for MoneyFarm **`FTDPlatformID = 4`**. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTD_Date COMMENT '**`date`-typed MoneyFarm FTD calendar date** sourced from aggregator CASE branches. (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTDA COMMENT '**`money`-typed MoneyFarm FTD monetary amount.** (Tier 2 - Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarmFirstDeposited COMMENT 'Derived insert flag: **`1` iff `MoneyFarm_FTD_DateID = @dateID`**, else **`0`** - aligns Options/MoneyFarm onboarding telemetry with daily grain. (Tier 2 - SP_DDR_Customer_Daily_Status)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBAN_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TP_External_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Global_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsDepositorGlobal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalRedeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN GlobalCashedOut SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Redeemed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedTP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedTP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TPFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IBANFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN TPExternalFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ActiveTraded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN BalanceOnlyAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Portfolio_Only SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountActive SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountInActive SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DesignatedRegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MarketingRegion SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MifidCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN IsFunded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstTimeFunded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstFundedDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstActionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstActionDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedIn SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInTPDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInIBANDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN LoggedInGlobalDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstIOBDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN FirstIOBTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN Options_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN OptionsFirstDeposited SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN DepositedOptions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN ReDepositedOptions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTD_DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTD_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarm_FTDA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ALTER COLUMN MoneyFarmFirstDeposited SET TAGS ('pii' = 'none');

