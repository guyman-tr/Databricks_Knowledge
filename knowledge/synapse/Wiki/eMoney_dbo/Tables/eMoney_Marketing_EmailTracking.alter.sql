-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Marketing_EmailTracking
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- `eMoney_Marketing_EmailTracking` is the eToro Money marketing campaign performance table. Each row represents **one email campaign on one send date for one country × club segment**, aggregating email engagement and 3-day conversion funnel metrics. The table tracks eToro Money acquisition campaigns — marketing emails sent to existing eToro trading customers to encourage them to open an eToro Money account (FMI: First Money In) or activate an eTM card. Data is sourced from **Salesforce Marketing Cloud (SFMC)** via `BI_DB_dbo.BI_DB_SFMC_Report` which ingests email delivery and engagement events. Key metrics captured: - **Email delivery and engagement**: Delivered (distinct recipients), UniqueOpen, CountOpen, UniqueClicks, CountClicks - **3-day account creation conversion**: CreatedAccount_Open (opened email → created eTM account within 3 days), CreateAccount_Clicks (clicked → created accoun

