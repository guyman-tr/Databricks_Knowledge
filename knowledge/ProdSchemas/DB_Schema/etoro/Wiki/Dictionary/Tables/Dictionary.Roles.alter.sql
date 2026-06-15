-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_roles
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Roles.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_roles SET TBLPROPERTIES (
    'comment' = 'A role-based access control (RBAC) definition table that maps named roles to specific application objects with read/write permission flags. Each role grants or restricts access to a particular area of the Configuration Manager / Dealing Reports internal tool. eToro''s internal tools (Configuration Manager, CEP engine, Dealing Reports) require granular access control. Rather than hardcoding permissions, this table allows dynamic assignment of read/write access per application object. Roles are assigned to user groups via the `Internal.GroupsAndRoles` junction table, enabling group-based permission inheritance. When an internal user performs an operation in an admin tool, the system calls `Internal.CheckSinglePermission`, which joins `Dictionary.Groups` -> `Internal.GroupsAndRoles` -> `Dictionary.Roles` -> `Dictionary.Objects` to determine whether the user''s group has read or write access to...'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_roles ALTER COLUMN RoleID COMMENT 'Primary key. Sequential identifier for each role definition. Range: 1-36.';
ALTER TABLE main.general.bronze_etoro_dictionary_roles ALTER COLUMN RoleName COMMENT 'Human-readable role name following `{Verb}{ObjectName}` convention. Used in Group-to-Role assignment and audit. Verbs: Read, Update, Edit, Execute, Create.';
ALTER TABLE main.general.bronze_etoro_dictionary_roles ALTER COLUMN RoleDesc COMMENT 'Free-text description of what the role permits. Written by developers when adding roles. Documents the business action allowed.';
ALTER TABLE main.general.bronze_etoro_dictionary_roles ALTER COLUMN ObjectID COMMENT 'FK -> `Dictionary.Objects`. The application object this role controls access to. Each object typically has 2 roles (read + write).';
ALTER TABLE main.general.bronze_etoro_dictionary_roles ALTER COLUMN CanRead COMMENT 'Read permission flag. 1 = role grants read access to the object. All 36 roles have CanRead=1 (every role grants at least read).';
ALTER TABLE main.general.bronze_etoro_dictionary_roles ALTER COLUMN CanWrite COMMENT 'Write permission flag. 1 = role grants modify/execute access. 0 = read-only. `Internal.CheckSinglePermission` evaluates this based on the requested operation ("Read" vs "Write").';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:15 UTC
-- Statements: 7/7 succeeded
-- ====================
