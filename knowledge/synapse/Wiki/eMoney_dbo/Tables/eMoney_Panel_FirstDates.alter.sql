-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Panel_FirstDates
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates SET TBLPROPERTIES (
    'comment' = '`eMoney_Panel_FirstDates` is the central milestone-tracking panel for eToro Money accounts. Each row represents one eMoney account and records when (and how) that account first moved money in and out, the date ranges of IBAN and card activity, the card activation timestamp, and the first 5 transactions across three category cuts (all types, IBAN only, card only). As of 2026-04-12 the table has **2,031,884 rows** (2,031,882 distinct CIDs - 2 accounts share a CID, likely a data anomaly). The earliest FMI_Date is 2020-11-10, corresponding to the UK launch. Key adoption rates: | Milestone | Count | % of accounts | |-----------|-------|---------------| | Has FMI (ever funded) | 1,286,611 | 63.3% | | Has FMO (ever sent) | 1,242,239 | 61.1% | | Card activated | 26,832 | 1.3% | | Card first tx | 25,135 | 1.2% | |  >= 1 settled action | 1,287,451 | 63.4% | |  >= 5 settled actions | 687,082 | 33.8% | The table is the authoritative source for FMI/FMO signals in the eMoney acquisition funnel (`SP_eMoney_Reports_Daily` JOINs...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `AccountID` COMMENT 'Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `GCID` COMMENT 'Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `CID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMI_Date` COMMENT 'Date of the account''s first settled money-in transaction (TxTypeID IN [5,7], TxStatusID=2, HolderAmount != 0). Derived from TxStatusModificationDate of ROW_NUMBER=1 (ASC by TxStatusModificationTime). NULL for 36.7% of accounts that have never funded. Earliest value: 2020-11-10 (UK launch). (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Seniority_FMI` COMMENT 'Months elapsed between FMI_Date and the SP run date. DATEDIFF(MONTH, FMI_Date, @Date). NULL when FMI_Date is NULL. Computed at INSERT time - recalculate DATEDIFF directly for real-time values. (Tier 2 - SP_eMoney_Panel_FirstDates)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMI_Time` COMMENT 'Full timestamp of the first settled money-in transaction. Derived from TxStatusModificationTime of ROW_NUMBER=1 (ASC). NULL when FMI_Date is NULL. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMI_Source` COMMENT 'Origin classification of the first money-in: `''TP''` (TxTypeID=5, TransferReceived - internal eToro transfer) or `''External''` (TxTypeID=7, PaymentReceived - bank/external). As of 2026-04-12: TP=672,868 (52.3%), External=613,743 (47.7%). NULL when FMI_Date is NULL. (Tier 2 - SP_eMoney_Panel_FirstDates)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMO_Date` COMMENT 'Date of the account''s first settled money-out transaction (TxTypeID IN [1,2,3,4,6,8,13], TxStatusID=2, HolderAmount != 0). Derived from TxStatusModificationDate of ROW_NUMBER=1 (ASC by TxStatusModificationTime). NULL for 38.9% of accounts that have never sent. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Seniority_FMO` COMMENT 'Months elapsed between FMO_Date and the SP run date. DATEDIFF(MONTH, FMO_Date, @Date). NULL when FMO_Date is NULL. Computed at INSERT time. (Tier 2 - SP_eMoney_Panel_FirstDates)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMO_Time` COMMENT 'Full timestamp of the first settled money-out transaction. Derived from TxStatusModificationTime of ROW_NUMBER=1 (ASC). NULL when FMO_Date is NULL. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMO_Target` COMMENT 'Destination classification of the first money-out: `''TP''` (TxTypeID=6 - internal Transfer to eToro user) or `''External''` (all other OUT types - bank, card, DD). As of 2026-04-12: TP=700,796 (56.4%), External=541,443 (43.6%). NULL when FMO_Date is NULL. (Tier 2 - SP_eMoney_Panel_FirstDates)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMO_MOP` COMMENT 'Method of payment for the first money-out: `''Card''` (TxTypeID IN [1,2,3,4]), `''IBAN''` (TxTypeID IN [6,8]), `''DirectDebit''` (TxTypeID=13). As of 2026-04-12: IBAN=1,235,319 (99.4% of FMO accounts), Card=6,908 (0.6%), DirectDebit=12 (<0.01%). NULL when FMO_Date is NULL. (Tier 2 - SP_eMoney_Panel_FirstDates)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `LastSettledTXDate` COMMENT 'Date of the account''s most recent settled transaction across all types (TxStatusID=2, HolderAmount != 0). MAX(TxStatusModificationDate). Used as a recency signal; compare to GETDATE() for churn analysis. NULL if no settled transactions. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Seniority_LastTXDate` COMMENT 'Months elapsed between LastSettledTXDate and the SP run date. DATEDIFF(MONTH, LastSettledTXDate, @Date). Accounts with Seniority_LastTXDate <= 3 are typically considered active. Computed at INSERT time. (Tier 2 - SP_eMoney_Panel_FirstDates)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FirstIBANSettledTXDate` COMMENT 'Date of the account''s first settled IBAN-rail transaction (TxTypeID IN [5,6,7,8]). MIN(TxStatusModificationDate) for IBAN types. NULL if no IBAN activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `LastIBANSettledTXDate` COMMENT 'Date of the account''s most recent settled IBAN-rail transaction (TxTypeID IN [5,6,7,8]). MAX(TxStatusModificationDate) for IBAN types. NULL if no IBAN activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `CardActivationTime` COMMENT 'Timestamp when the card reached activated status. CASE WHEN CardStatusID=1 THEN CardStatusTime ELSE NULL END, sourced from eMoney_Dim_Account. NULL for 98.7% of accounts with no activated card. (Tier 2 - eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FirstCardSettledTXDate` COMMENT 'Date of the account''s first settled card-rail transaction (TxTypeID IN [1,2,3,4]). MIN(TxStatusModificationDate) for card types. NULL if no card activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `LastCardSettledTXDate` COMMENT 'Date of the account''s most recent settled card-rail transaction (TxTypeID IN [1,2,3,4]). MAX(TxStatusModificationDate) for card types. NULL if no card activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `1stActionDate` COMMENT 'Date of the account''s 1st settled transaction (all types, ranked ASC by TxStatusModificationTime). MAX(CASE WHEN RowNumASC=1 THEN TxStatusModificationDate END). NULL if no settled tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `1stActionType` COMMENT 'TxType name of the 1st settled transaction. MAX(CASE WHEN RowNumASC=1 THEN TxType END). Values: CardPayment, Transfer, PaymentReceived, etc. NULL if no settled tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `1stActionUSDApproxAmount` COMMENT 'Approximate USD value of the 1st settled transaction. MAX(CASE WHEN RowNumASC=1 THEN USDAmountApprox END). ROUND(HolderAmount × mid-rate, 2). NULL for DKK and if no settled tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `2ndActionDate` COMMENT 'Date of the account''s 2nd settled transaction (all types, ranked ASC). NULL if fewer than 2 settled tx. Same derivation as 1stActionDate with RowNumASC=2. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `2ndActionType` COMMENT 'TxType name of the 2nd settled transaction. NULL if fewer than 2. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `2ndActionUSDApproxAmount` COMMENT 'USD approximate amount of the 2nd settled transaction. NULL if fewer than 2. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `3rdActionDate` COMMENT 'Date of the 3rd settled transaction (all types, ranked ASC). NULL if fewer than 3. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `3rdActionType` COMMENT 'TxType name of the 3rd settled transaction. NULL if fewer than 3. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `3rdActionUSDApproxAmount` COMMENT 'USD approximate amount of the 3rd settled transaction. NULL if fewer than 3. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `4thActionDate` COMMENT 'Date of the 4th settled transaction (all types, ranked ASC). NULL if fewer than 4. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `4thActionType` COMMENT 'TxType name of the 4th settled transaction. NULL if fewer than 4. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `4thActionUSDApproxAmount` COMMENT 'USD approximate amount of the 4th settled transaction. NULL if fewer than 4. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `5thActionDate` COMMENT 'Date of the 5th settled transaction (all types, ranked ASC). NULL if fewer than 5. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `5thActionType` COMMENT 'TxType name of the 5th settled transaction. NULL if fewer than 5. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `5thActionUSDApproxAmount` COMMENT 'USD approximate amount of the 5th settled transaction. NULL if fewer than 5. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN1stActionDate` COMMENT 'Date of the account''s 1st settled IBAN-rail transaction (TxTypeID IN [5,6,7,8]), ranked ASC. NULL if no IBAN activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN1stActionType` COMMENT 'TxType name of the 1st settled IBAN transaction. Values: Transfer, TransferReceived, PaymentReceived, Payment. NULL if no IBAN activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN1stActionUSDApproxAmount` COMMENT 'USD approximate amount of the 1st settled IBAN transaction. NULL for DKK and no IBAN activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN2ndActionDate` COMMENT 'Date of the 2nd settled IBAN transaction. NULL if fewer than 2 IBAN tx. Same derivation as IBAN1st with RowNumASC=2. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN2ndActionType` COMMENT 'TxType of the 2nd settled IBAN transaction. NULL if fewer than 2 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN2ndActionUSDApproxAmount` COMMENT 'USD amount of the 2nd settled IBAN transaction. NULL if fewer than 2 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN3rdActionDate` COMMENT 'Date of the 3rd settled IBAN transaction. NULL if fewer than 3 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN3rdActionType` COMMENT 'TxType of the 3rd settled IBAN transaction. NULL if fewer than 3 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN3rdActionUSDApproxAmount` COMMENT 'USD amount of the 3rd settled IBAN transaction. NULL if fewer than 3 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN4thActionDate` COMMENT 'Date of the 4th settled IBAN transaction. NULL if fewer than 4 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN4thActionType` COMMENT 'TxType of the 4th settled IBAN transaction. NULL if fewer than 4 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN4thActionUSDApproxAmount` COMMENT 'USD amount of the 4th settled IBAN transaction. NULL if fewer than 4 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN5thActionDate` COMMENT 'Date of the 5th settled IBAN transaction. NULL if fewer than 5 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN5thActionType` COMMENT 'TxType of the 5th settled IBAN transaction. NULL if fewer than 5 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN5thActionUSDApproxAmount` COMMENT 'USD amount of the 5th settled IBAN transaction. NULL if fewer than 5 IBAN tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card1stActionDate` COMMENT 'Date of the account''s 1st settled card-rail transaction (TxTypeID IN [1,2,3,4]), ranked ASC. NULL for 98.7% of accounts with no card activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card1stActionType` COMMENT 'TxType name of the 1st settled card transaction. Values: CardPayment, ContactlessPayment, CardCashWithdrawal, CardRefund. NULL if no card activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card1stActionUSDApproxAmount` COMMENT 'USD approximate amount of the 1st settled card transaction. NULL if no card activity. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card2ndActionDate` COMMENT 'Date of the 2nd settled card transaction. NULL if fewer than 2 card tx. Same derivation as Card1st with RowNumASC=2. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card2ndActionType` COMMENT 'TxType of the 2nd settled card transaction. NULL if fewer than 2 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card2ndActionUSDApproxAmount` COMMENT 'USD amount of the 2nd settled card transaction. NULL if fewer than 2 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card3rdActionDate` COMMENT 'Date of the 3rd settled card transaction. NULL if fewer than 3 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card3rdActionType` COMMENT 'TxType of the 3rd settled card transaction. NULL if fewer than 3 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card3rdActionUSDApproxAmount` COMMENT 'USD amount of the 3rd settled card transaction. NULL if fewer than 3 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card4thActionDate` COMMENT 'Date of the 4th settled card transaction. NULL if fewer than 4 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card4thActionType` COMMENT 'TxType of the 4th settled card transaction. NULL if fewer than 4 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card4thActionUSDApproxAmount` COMMENT 'USD amount of the 4th settled card transaction. NULL if fewer than 4 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card5thActionDate` COMMENT 'Date of the 5th settled card transaction. NULL if fewer than 5 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card5thActionType` COMMENT 'TxType of the 5th settled card transaction. NULL if fewer than 5 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card5thActionUSDApproxAmount` COMMENT 'USD amount of the 5th settled card transaction. NULL if fewer than 5 card tx. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of the most recent SP refresh. Set to GETDATE() at INSERT time; all rows share the same value per daily run. Last observed: 2026-04-12. (Tier 2 - SP_eMoney_Panel_FirstDates)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `AccountID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMI_Date` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Seniority_FMI` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMI_Time` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMI_Source` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMO_Date` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Seniority_FMO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMO_Time` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMO_Target` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FMO_MOP` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `LastSettledTXDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Seniority_LastTXDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FirstIBANSettledTXDate` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `LastIBANSettledTXDate` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `CardActivationTime` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `FirstCardSettledTXDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `LastCardSettledTXDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `1stActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `1stActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `1stActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `2ndActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `2ndActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `2ndActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `3rdActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `3rdActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `3rdActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `4thActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `4thActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `4thActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `5thActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `5thActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `5thActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN1stActionDate` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN1stActionType` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN1stActionUSDApproxAmount` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN2ndActionDate` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN2ndActionType` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN2ndActionUSDApproxAmount` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN3rdActionDate` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN3rdActionType` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN3rdActionUSDApproxAmount` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN4thActionDate` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN4thActionType` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN4thActionUSDApproxAmount` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN5thActionDate` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN5thActionType` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `IBAN5thActionUSDApproxAmount` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card1stActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card1stActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card1stActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card2ndActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card2ndActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card2ndActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card3rdActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card3rdActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card3rdActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card4thActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card4thActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card4thActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card5thActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card5thActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `Card5thActionUSDApproxAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
