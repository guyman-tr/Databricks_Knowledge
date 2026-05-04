-- ============================================================================
-- main.bi_output.bi_output_moneyfarm_customers  —  P6 UC ALTER stub
-- ============================================================================
-- Generated:    2026-05-04
-- Wiki:         knowledge/uc_domains/moneyfarm/schemas/bi_output/Tables/bi_output_moneyfarm_customers.md
-- Tier source:  Date_Source_Type = T1 (Confluence XP/13551468545); other 3 = T4 [uc_sample].
-- ============================================================================

COMMENT ON TABLE main.bi_output.bi_output_moneyfarm_customers IS
'eToro-side dim of MoneyFarm-onboarded customers. Granularity: one row per GCID. MF_Journey_Beginning = earliest date this GCID was observed as a MoneyFarm customer across a 3-rung provenance ladder: Live Event (New) (sub-accounts EH stream, 49k rows), Bronze Table (Recent) (general.bronze_moneyfarm_users, 45k), Silver AUM Snapshot (Legacy) (money_farm.silver_moneyfarm_etoro_mf_aum back-fill, 1.8k). Wider ladder than the 2-rung version on fact_portfolio_snapshot.Source_Type. [Confluence/XP/13551468545]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_customers ALTER COLUMN GCID COMMENT
'eToro Global Customer ID. Primary key. FK to main.bi_db.gold_sub_accounts_accounts.gcid (filter providerName=''Moneyfarm''). [uc_sample]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_customers ALTER COLUMN MF_Journey_Beginning COMMENT
'Earliest date this GCID was observed as a MoneyFarm customer across the Live Event / Bronze / Silver ladder. NOT the eToro account creation date. [uc_sample]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_customers ALTER COLUMN Date_Source_Type COMMENT
'Provenance flag for MF_Journey_Beginning. Values: ''Live Event (New)'' (49189 rows), ''Bronze Table (Recent)'' (45270), ''Silver AUM Snapshot (Legacy)'' (1797). Live Event = streamed from sub-accounts EH; Silver AUM Snapshot = back-fill from money_farm.silver_moneyfarm_etoro_mf_aum. [Confluence/XP/13551468545]';

ALTER TABLE main.bi_output.bi_output_moneyfarm_customers ALTER COLUMN UpdateDate COMMENT
'Snapshot refresh timestamp (UTC). All rows in a refresh share the same value. [uc_sample]';

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-04 12:57:51 UTC
-- Batch deploy resume: bi_output deploy batch 2
-- Statements: 5/5 succeeded
-- ====================
