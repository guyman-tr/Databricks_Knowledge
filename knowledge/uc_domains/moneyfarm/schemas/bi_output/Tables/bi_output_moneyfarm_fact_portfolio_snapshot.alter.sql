-- UC ALTER deploy stub for main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
--
-- Source provenance (per .cursor/rules/uc-domain-doc/05-generate-doc.mdc):
--   * No pre-existing UC comment to preserve — this is a fresh authoring.
--   * Table comment: synthesised from Confluence Tier-1 anchors (XP HLD, MG Payments Configs).
--   * Column comments emitted for Tier-1 + Tier-3 columns only (per rule §"Tier-4 comments optional").
--   * Tier-4 columns (Current_Market_Value_GBP, Portfolio_Risk_Level,
--     Last_Risk_Level_Change_Date, Previous_Risk_Level) are documented in the
--     wiki but NOT deployed here. They can be promoted later if MoneyFarm-side
--     documentation surfaces or after analyst review.
--   * No UNVERIFIED comments are emitted.
--
-- Confluence citation tags inside comments:
--   [Conf/XP/12216961926] = Moneyfarm V2 - HLD (eligibility / scope)
--   [Conf/XP/13551468545] = MF additions Deposit Event (event schema, AccountTypeId=4)
--   [Conf/MG/13600227427] = MoneyFarm global payments configurations (Dictionary mappings)
--   [Genie/UK-BA-WIP]    = Genie space 01f12202...

-- ===== Object-level =====
COMMENT ON TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot IS 'eToro-side MoneyFarm portfolio snapshot fact. One row per (GCID, PortfolioID) refreshed daily, holding the current product-level state of every MoneyFarm portfolio belonging to an eToro customer linked through the MoneyFarm V2 ISA flow. Eligibility scope: countryID=UK + designatedRegulation=FCA + playerStatus=Normal + at least one Approved deposit + non-legacy [Conf/XP/12216961926]. Identity bridge: GCID via main.bi_db.bronze_sub_accounts_accounts where providerName=''Moneyfarm'' [Genie/UK-BA-WIP]. AccountTypeID=4 / FundingTypeID=44 are the MoneyFarm payment-dictionary keys [Conf/MG/13600227427]. Daily refresh is end-to-end: UpdateDate is uniform across rows in a given day. Source: BI bizops_output curation pipeline subscribing to main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts where eventSource=''Moneyfarm''.';

-- ===== Column-level (Tier 1 + Tier 3 only) =====
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN GCID                COMMENT 'eToro Global Customer ID. Always populated. Maps to MoneyFarm-side users via main.bi_db.bronze_sub_accounts_accounts (filter providerName=''Moneyfarm'') and to dwh.dim_customer.RealCID. [Conf/XP/13551468545; Genie/UK-BA-WIP]';
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN PortfolioID         COMMENT 'UUID identifying a single MoneyFarm portfolio. A single GCID can hold multiple PortfolioIDs (one-to-many). FK to bi_output.bi_output_moneyfarm_fact_transactions.PortfolioID and money_farm.silver_moneyfarm_etoro_mf_aum.Portfolio_Id. [Genie/UK-BA-WIP join_spec instruction]';
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN Product_Onboarding_Date COMMENT 'Date the customer onboarded onto this MoneyFarm product (NOT the row insertion date — see UpdateDate). Sample values cluster in 2025-2026 consistent with the MoneyFarm V2 rollout window. [uc_sample]';
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN Product_Name        COMMENT 'MoneyFarm product type. Active values today: Managed ISA, DIY ISA, Cash ISA — all Individual Savings Account variants, consistent with the V2 HLD eligibility scope (UK + FCA). [Conf/XP/12216961926; uc_sample]';
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN Source_Type         COMMENT 'Provenance flag: ''Live Event'' = streamed from a real-time MoneyFarm sub-accounts event; ''Silver History'' = back-filled from money_farm.silver_moneyfarm_etoro_mf_aum history. Filter to ''Live Event'' to count live MoneyFarm activity. [uc_sample]';
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN UpdateDate          COMMENT 'Snapshot timestamp. All rows in a given day share the same UpdateDate — this is a daily-rebuilt snapshot, not a slowly-changing dimension. [uc_sample]';

-- Tier-4 columns (NOT deployed by default):
--   Current_Market_Value_GBP  — sample shows many 0.00 rows; documented in wiki §3
--   Portfolio_Risk_Level      — P0..P7 codes per MoneyFarm risk system; sample-inferred
--   Last_Risk_Level_Change_Date — STRING type, sample is all NULL
--   Previous_Risk_Level       — STRING type, sample is all NULL
-- Promote these by adding ALTER COLUMN … COMMENT lines after analyst review.
