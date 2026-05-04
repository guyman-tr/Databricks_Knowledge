-- UC ALTER deploy stub for main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
--
-- Source provenance (per .cursor/rules/uc-domain-doc/05-generate-doc.mdc):
--   * Each COMMENT text below is the wiki Section 3 `Description` column verbatim
--     (NOT the verbose `Notes & citations` column — that's wiki-only).
--   * Tier-1 columns are Confluence-anchored.
--   * Tier-5 columns are analyst-reviewed; full audit trail in
--     bi_output_moneyfarm_fact_portfolio_snapshot.review-log.md.
--   * One soft Tier-4 column (Product_Onboarding_Date) is deployed because its
--     wording is fully grounded in the sample with the provenance caveat made
--     explicit; no speculation.
--   * Currently NOT deployed (still pure Tier-4, no Confluence anchor):
--       Portfolio_Risk_Level, Last_Risk_Level_Change_Date, Previous_Risk_Level.
--   * No UNVERIFIED comments are emitted.
--
-- Citation tag legend used inline:
--   [Conf/XP/12216961926] = Moneyfarm V2 - HLD (eligibility / scope)
--   [Conf/XP/13551468545] = MF additions Deposit Event (event schema, AccountTypeId=4)
--   [Conf/MG/13600227427] = MoneyFarm global payments configurations (Dictionary mappings)
--   [T5 <YYYY-MM-DD>]     = analyst-reviewed promotion (see review-log.md)

-- ===== Object-level =====
COMMENT ON TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot IS 'eToro-side MoneyFarm portfolio snapshot fact. One row per (GCID, PortfolioID) refreshed daily, holding the current product-level state of every MoneyFarm portfolio belonging to an eToro customer linked through the MoneyFarm V2 ISA flow. Eligibility scope: countryID=UK + designatedRegulation=FCA + playerStatus=Normal + at least one Approved deposit + non-legacy [Conf/XP/12216961926]. Identity bridge: GCID via main.bi_db.bronze_sub_accounts_accounts where providerName=''Moneyfarm''. AccountTypeID=4 / FundingTypeID=44 are the MoneyFarm payment-dictionary keys [Conf/MG/13600227427]. Source: BI bizops_output curation pipeline subscribing to main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts where eventSource=''Moneyfarm''.';

-- ===== Column-level (Tier 1 — Confluence-anchored) =====
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN GCID                COMMENT 'eToro Global Customer ID (numeric LONG). FK to bi_db.bronze_sub_accounts_accounts.gcid where providerName=''Moneyfarm'' and to dwh.dim_customer.RealCID. Always populated. [Conf/XP/13551468545]';
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN PortfolioID         COMMENT 'UUID v4 per-portfolio (8-4-4-4-12 with hyphens). One GCID can hold multiple PortfolioIDs (1:N). FK to bi_output_moneyfarm_fact_transactions.PortfolioID and silver_moneyfarm_etoro_mf_aum.Portfolio_Id (note case difference). [Conf/XP/13551468545]';
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN Product_Name        COMMENT 'MoneyFarm product. Values: Managed ISA | DIY ISA | Cash ISA. UK + FCA only (V2 HLD eligibility scope). [Conf/XP/12216961926]';
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN Source_Type         COMMENT 'Provenance flag. Values: Live Event (streamed from sub-accounts EH; PORTFOLIO_DEPOSIT / USER_CASH_ACCOUNT_ACTIVATED) | Silver History (back-fill from silver_moneyfarm_etoro_mf_aum). Filter Source_Type=''Live Event'' for live activity only. [Conf/XP/13551468545]';

-- ===== Column-level (soft Tier 4 — sample-anchored only, no Confluence) =====
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN Product_Onboarding_Date COMMENT 'Onboarding date for this MoneyFarm product (NOT the row insertion date — see UpdateDate). Provenance not Confluence-confirmed. [uc_sample]';

-- ===== Analyst-reviewed (T5) =====
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN Current_Market_Value_GBP COMMENT 'Current GBP NAV at UpdateDate. Many rows are 0.00 (interpreted as freshly-created or NAV-zero pending daily mark-to-market in silver_moneyfarm_etoro_mf_aum). Currency assumed GBP per Dictionary.FundingType.DefaultCurrency=5. [T5 2026-05-04]';
ALTER TABLE main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot ALTER COLUMN UpdateDate              COMMENT 'Snapshot timestamp. All sampled rows in a given day share the same UpdateDate. History-retention not confirmed — verify with SELECT COUNT(DISTINCT UpdateDate) before time-series use. [T5 2026-05-04]';

-- ===== Tier-4 columns NOT deployed =====
--   Portfolio_Risk_Level         — values P0/P7/NULL observed; band semantics unsourced
--   Last_Risk_Level_Change_Date  — STRING type, sample is all NULL
--   Previous_Risk_Level          — STRING type, sample is all NULL
-- Promote these by appending ALTER COLUMN … COMMENT lines after analyst review,
-- and add the corresponding T5 entry to the review-log.md.
