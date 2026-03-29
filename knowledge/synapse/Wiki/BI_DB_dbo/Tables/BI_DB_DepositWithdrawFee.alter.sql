-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DepositWithdrawFee
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DepositWithdrawFee'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN DateID COMMENT 'Business date as **YYYYMMDD** for the load (**@StartDateID**). (Tier 2 -- SP_DepositWithdrawFee, @StartDateID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CID COMMENT 'Internal customer id (**RealCID**) from deposit or cashout state. (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.CID / Fact_Cashout_State.CID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN DepositWithdrawID COMMENT '**DepositID** or **WithdrawID** depending on path -- stable id for the cash event. (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.DepositID / Fact_Cashout_State.WithdrawID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Occurred COMMENT 'Event timestamp (**ModificationDate** from state fact). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ModificationDate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CreditTypeID COMMENT 'Set to **NULL** in the current procedure (legacy column retired). (Tier 2 -- SP_DepositWithdrawFee, NULL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN TransactionID COMMENT 'Synthetic id: deposit id + **D** or WP id + **W**. (Tier 2 -- SP_DepositWithdrawFee, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Date COMMENT 'Calendar date of **ModificationDate**. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ModificationDate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Customer COMMENT 'External customer id (**Dim_Customer.ExternalID**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Customer.ExternalID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN TransactionType COMMENT 'Type string from state (**Deposit**, **Withdraw**, chargebacks, refunds, rollbacks, etc.). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.TransactionType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PaymentMethod COMMENT 'Funding type name (**Dim_FundingType.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_FundingType.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Amount COMMENT 'Transaction amount in original currency; **ABS** at insert then signed via **#amountDirections** (and edge-case **UPDATE**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.Amount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Currency COMMENT 'Currency code (**Dim_Currency.Abbreviation**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Currency.Abbreviation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN ExchangeRate COMMENT 'FX rate on the state row. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ExchangeRate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN AmountUSD COMMENT 'USD amount; **ABS** at insert then signed like **Amount**. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.AmountInUSD)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN RegulationID COMMENT 'Regulation key from customer snapshot. (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.RegulationID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN LabelID COMMENT 'Marketing / label id from snapshot (deposit path uses **dc.LabelID** join in one branch). (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.LabelID / Dim_Customer.LabelID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PlayerLevelID COMMENT 'Player level id from snapshot. (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.PlayerLevelID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Regulation COMMENT 'Regulation name (**Dim_Regulation.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Regulation.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Label COMMENT 'Label name (**Dim_Label.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Label.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN IsValidCustomer COMMENT 'Snapshot validity flag. (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.IsValidCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN UpdateDate COMMENT 'Row load timestamp (**GETDATE()** at insert). (Tier 3 -- SP_DepositWithdrawFee, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN BaseExchangeRate COMMENT 'Base FX rate from state. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.BaseExchangeRate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN ExchangeFee COMMENT 'Exchange fee from state. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ExchangeFee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN ExternalTransactionID COMMENT 'Provider transaction id (**ExTransactionID**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ExTransactionID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Depot COMMENT 'Billing depot name (**Dim_BillingDepot**). (Tier 2 -- SP_DepositWithdrawFee, Dim_BillingDepot.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN MIDValue COMMENT 'Merchant id value on the state row (**MID**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.MID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Club COMMENT 'Player level / club name (**Dim_PlayerLevel.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_PlayerLevel.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PlayerStatus COMMENT 'Player status label (**Dim_PlayerStatus.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_PlayerStatus.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PIPsCalculation COMMENT '**ABS(PIPsInUSD)** at insert; adjusted by direction rules and post-join **UPDATE**s (rollbacks, chargeback reversals, **Fact_CustomerAction** tie-break). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.PIPsInUSD)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN RegCountry COMMENT 'Registration country from snapshot **CountryID**. (Tier 2 -- SP_DepositWithdrawFee, Dim_Country.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN RegCountryByIP COMMENT 'Country from customer **CountryIDByIP**. (Tier 2 -- SP_DepositWithdrawFee, Dim_Country.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CardType COMMENT 'Card type name (**Dim_CardType.CarTypeName**) or raw **Fact_Deposit_State.CardType** on deposit path. (Tier 2 -- SP_DepositWithdrawFee, Dim_CardType / Fact_Deposit_State)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CardCategory COMMENT 'Card category from billing deposit or withdraw. (Tier 2 -- SP_DepositWithdrawFee, Fact_BillingDeposit / Fact_BillingWithdraw)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN BinCountry COMMENT 'Country from BIN country id on billing. (Tier 2 -- SP_DepositWithdrawFee, Dim_Country.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN MOPCountry COMMENT 'Not populated (**NULL**) in current SP. (Tier 2 -- SP_DepositWithdrawFee, NULL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN IsGermanBaFin COMMENT 'Not populated (**NULL**) in current SP. (Tier 2 -- SP_DepositWithdrawFee, NULL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN IsIBANTrade COMMENT '**1** when deposit **FlowID** = 1 or withdraw **FlowID** = 2 on billing fact. (Tier 2 -- SP_DepositWithdrawFee, Fact_BillingDeposit.FlowID / Fact_BillingWithdraw.FlowID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN MIDName COMMENT 'Merchant display name from state. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.MIDName)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN GuruStatus COMMENT 'Guru status from snapshot (**Dim_GuruStatus**). (Tier 2 -- SP_DepositWithdrawFee, Dim_GuruStatus.GuruStatusName)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PreviousTransactionStatus COMMENT 'Prior status on state (**PreviousStatus** / **PreviousStatus**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.PreviousStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN TransactionStatus COMMENT 'Current status (**DepositStatus** or **CashoutStatus**). (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.DepositStatus / Fact_Cashout_State.CashoutStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN DepositID COMMENT 'Populated on deposit rows; **NULL** on withdraw rows. (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.DepositID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN WithdrawPaymentID COMMENT 'Populated on withdraw rows; **NULL** on deposit rows. (Tier 2 -- SP_DepositWithdrawFee, Fact_BillingWithdraw.WithdrawPaymentID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CreditID COMMENT 'Credit id from state (**CreditID**) for reconciliation to **Fact_CustomerAction**. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.CreditID)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN DepositWithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CreditTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN TransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Customer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN TransactionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PaymentMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN LabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Label SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN ExchangeFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN ExternalTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Depot SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN MIDValue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PIPsCalculation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN RegCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN RegCountryByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CardType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CardCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN BinCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN MOPCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN IsIBANTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN MIDName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN GuruStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN PreviousTransactionStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN TransactionStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN CreditID SET TAGS ('pii' = 'none');
