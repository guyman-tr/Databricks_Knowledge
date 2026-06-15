-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_usabroker_dictionary_userprogram
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.UserProgram.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_usabroker_dictionary_userprogram SET TBLPROPERTIES (
    'comment' = '`Dictionary.UserProgram` is a static reference table that enumerates the optional value-added programmes that a brokerage user can enrol in beyond their standard account. Each programme offers a distinct financial service or shareholder-participation feature that the user must explicitly opt into, and the enrolment state is tracked separately in `Apex.UserProgramEnrolment`. The programmes currently offered span three domains: securities lending (`FPSL` - Fully Paid Securities Lending), cryptocurrency staking (`CryptoStaking`, `EthStaking`), and shareholder proxy voting (`ProxyVotingManualPositions`, `ProxyVotingCopiedPositions`). The `None` sentinel (ID 0) is used where no specific programme applies. FPSL allows users to lend out fully paid securities in exchange for a fee. The two staking programmes allow users to participate in proof-of-stake blockchain validation rewards.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_usabroker_dictionary_userprogram ALTER COLUMN UserProgramID COMMENT 'Stable numeric identifier for the programme; 0 is the sentinel for no specific programme.';
ALTER TABLE main.general.bronze_usabroker_dictionary_userprogram ALTER COLUMN Name COMMENT 'Short programme code used throughout the application layer; note ID 4 has a trailing space in the live data.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:31 UTC
-- Statements: 3/3 succeeded
-- ====================
