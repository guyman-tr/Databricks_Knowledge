-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.apex.OptionsReasoningFormQuestionsAnswers
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers SET TBLPROPERTIES (
    'comment' = 'Child table of OptionsReasoningForm storing the individual KYC question-answer pairs for each reasoning form, capturing which questions the customer changed and their reasoning. Source: USABroker.apex.OptionsReasoningFormQuestionsAnswers on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.OptionsReasoningFormQuestionsAnswers.md).'
);

ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'apex',
    'source_table' = 'OptionsReasoningFormQuestionsAnswers',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers ALTER COLUMN ReasoningFormID COMMENT 'FK to Apex.OptionsReasoningForm. Links this question-answer pair to its parent reasoning form. Part of the UNIQUE constraint with KycQuestionID. (Tier 1 - upstream wiki, USABroker.apex.OptionsReasoningFormQuestionsAnswers)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers ALTER COLUMN KycQuestionID COMMENT 'Identifier of the KYC (Know Your Customer) suitability question that was changed. References the suitability questionnaire system (external). Part of the UNIQUE constraint with ReasoningFormID. (Tier 1 - upstream wiki, USABroker.apex.OptionsReasoningFormQuestionsAnswers)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers ALTER COLUMN ReasoningFormAnswerID COMMENT 'The customer''s selected reasoning for changing this question. Implicit FK to Dictionary.OptionsReasoningFormAnswers: 1=Other, 2=Incorrect Selection, 3=Changed Mind, 4=Lifestyle Change. See Options Reasoning Form Answers. NULL until the customer provides their reasoning. (Tier 1 - upstream wiki, USABroker.apex.OptionsReasoningFormQuestionsAnswers)';
ALTER TABLE main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers ALTER COLUMN OldKycAnswerID COMMENT 'The answer ID the customer previously had for this KYC question before the change. Provides the "before" state for the audit trail. A value of 0 indicates the question was not previously answered. (Tier 1 - upstream wiki, USABroker.apex.OptionsReasoningFormQuestionsAnswers)';

