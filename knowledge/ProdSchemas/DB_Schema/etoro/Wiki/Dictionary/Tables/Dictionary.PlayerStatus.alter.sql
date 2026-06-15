-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_playerstatus  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatus.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN PlayerStatusID COMMENT 'Primary key identifying the restriction state. 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 11=Social Index, 12=Copy Block, 13=Pending Verification, 14=Failed Verification, 15=Block Deposit & Trading. Stored in Customer.CustomerStatic.PlayerStatusID. See [Player Status](_glossary.md#player-status). (Dictionary.PlayerStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN Name COMMENT 'Human-readable label for the status. UNIQUE constraint ensures no duplicate names. Used in BackOffice UI, compliance reports, and monitoring dashboards.';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN IsBlocked COMMENT 'Master block flag. When true (statuses 2, 4, 6, 7, 8, 14), ALL capabilities are disabled including login. When false, individual CanX flags control specific permissions. Checked by Customer.CustomerSafty view and login procedures (History.LogIn).';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN CanEditPosition COMMENT 'Whether the user can modify existing position parameters (SL, TP, trailing stop). When false, positions are frozen in their current configuration.';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN CanOpenPosition COMMENT 'Whether the user can open new trading positions. When false, the user can only close existing positions. Checked by Trade order entry procedures (Trade.OrderEntryOpen) and Stocks.AddExitOrder.';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN CanClosePosition COMMENT 'Whether the user can close existing positions. Almost always true even for restricted statuses - only fully blocked accounts (IsBlocked=1) cannot close. Regulators require users to be able to exit positions.';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN CanDeposit COMMENT 'Whether the user can add funds to their account. When false, the user cannot make deposits through any payment method. Checked by Billing deposit procedures (Billing.GetCustomerDepositInfo).';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN CanRequestWithdraw COMMENT 'Whether the user can request withdrawals. When false, funds are locked in the account. Checked by Billing cashout procedures (BackOffice.GetCashOutRequests_Main).';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN CanLogin COMMENT 'Whether the user can authenticate and access the platform. When false, login attempts are rejected at the gate. Checked by History.LogIn and History.LogInIB procedures.';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN CanChatAndPost COMMENT 'Whether the user can post to the social feed, comment, or chat. When false, the user can view social content but cannot contribute. Applied by status 3 (Chat Blocked) for social policy violations.';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN CanBeCopied COMMENT 'Whether other users can start copying this user''s trades. When false, the user is hidden from the CopyTrader marketplace. Applied during compliance restrictions to prevent new copiers.';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN CanCopy COMMENT 'Whether this user can copy other traders. Default is true (1) for all statuses - legacy design decision. Status 12 (Copy Block) is the only status that sets this to false.';
ALTER TABLE main.general.bronze_etoro_dictionary_playerstatus ALTER COLUMN GetsInterest COMMENT 'Whether overnight fees/credits are calculated for this user''s positions. When false, no interest accrues or is charged. Blocked users (IsBlocked=1) and financially restricted users (9, 10, 13, 15) do not get interest. Used by Trade.UpdateInterestRate calculations.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:25:49 UTC
-- Statements: 13/13 succeeded
-- ====================
