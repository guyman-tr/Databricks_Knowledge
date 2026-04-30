# Customer.Settings

> Cross-database synonym: provides a local alias in the etoro database for UserApiDB.Customer.Settings, enabling etoro-side code to query or write customer settings stored in the User API database without hardcoding the target database name.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Synonym |
| **Key Identifier** | N/A (synonym - delegates to UserApiDB.Customer.Settings) |
| **Partition** | N/A |
| **Indexes** | N/A (see target object in UserApiDB) |

---

## 1. Business Meaning

Customer.Settings is a SQL Server synonym that creates a local name in the etoro database pointing to `UserApiDB.Customer.Settings`. SQL Server synonyms allow code in the etoro DB to reference the target object without explicitly specifying the `UserApiDB` database prefix, improving portability and allowing the target to be redirected by changing the synonym rather than all calling code.

The target object (`UserApiDB.Customer.Settings`) belongs to the User API service - a separate database that owns customer-facing settings data. Based on the UpdateUserSettings procedure (which handles @allowDisplayFullName, @allowShareFollow, @homepageId alongside privacy settings) and the GetAggregatedInfo API Documentation (Confluence 2025), UserApiDB.Customer contains settings tables tracking social display preferences (AllowDisplayFullName, AllowShareFollow) and UI personalization (HomepageId). The `Customer.Settings` object is likely the primary settings store or a read view for these preferences.

The synonym is part of the architectural boundary between the etoro DB (core trading/customer identity data) and UserApiDB (customer-facing settings and social preferences). Cross-DB access via synonym avoids linked-server overhead for same-instance access.

---

## 2. Business Logic

### 2.1 Cross-Database Settings Architecture

**What**: Customer settings are split between two databases: compliance/identity fields (PrivacyPolicyID, OptOutReasonID) live in CustomerStatic (etoro DB), while social display preferences and UI settings live in UserApiDB.

**Columns/Parameters Involved**: N/A (synonym itself has no columns - delegates to UserApiDB.Customer.Settings)

**Rules**:
- Any SELECT/INSERT/UPDATE/DELETE on `Customer.Settings` in etoro DB is transparently redirected to `UserApiDB.Customer.Settings`
- The synonym must be recreated if the target object changes name or moves to a different database
- Applications reading settings see a unified API surface via the GetAggregatedInfo endpoint (Confluence: userSettings block includes both etoro-DB fields and UserApiDB fields)
- Customer.UpdateUserSettings orchestrates both sides: UpdateUserSettingsRemote (etoro DB) + dbo.General_UpdateSettings (which likely writes to UserApiDB.Customer.Settings or the underlying settings tables)

---

## 3. Data Overview

N/A for Synonym (delegates to UserApiDB.Customer.Settings; schema defined in UserApiDB).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (synonym) | - | - | - | - | NAME-INFERRED | Customer.Settings is a synonym, not a table or view - it has no own columns. All column definitions are in UserApiDB.Customer.Settings. Based on context from UserApiDB schema analysis (EDM Compliance Planning, Confluence) and the UpdateUserSettings procedure parameters, the target object likely contains: GCID (int), AllowDisplayFullName (bit), AllowShareFollow (bit), HomepageId (int) - the social/display settings managed by dbo.General_UpdateSettings. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all access) | UserApiDB.Customer.Settings | Synonym (transparent redirect) | All SQL operations on Customer.Settings in etoro DB are transparently forwarded to UserApiDB.Customer.Settings |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.General_UpdateSettings | - | Likely consumer | The cross-schema SP called by Customer.UpdateUserSettings writes social display settings, likely using this synonym path to reach UserApiDB |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Settings (synonym)
└── UserApiDB.Customer.Settings (target object in UserApiDB)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| UserApiDB.Customer.Settings | Table or View (in UserApiDB) | Synonym target - all access is transparently redirected |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.General_UpdateSettings | Stored Procedure (cross-schema) | Likely writes social settings (AllowDisplayFullName, AllowShareFollow, HomepageId) via this synonym path |
| Customer.UpdateUserSettings | Stored Procedure | Orchestrator that ultimately writes to UserApiDB via this synonym (indirectly through dbo.General_UpdateSettings) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym. Indexes are on the target table in UserApiDB.Customer.Settings.

### 7.2 Constraints

N/A for Synonym. Constraints are on the target table in UserApiDB.

---

## 8. Sample Queries

### 8.1 Query customer settings via the synonym

```sql
SELECT *
FROM Customer.Settings WITH (NOLOCK)
WHERE GCID = 12345678;
-- Transparently queries UserApiDB.Customer.Settings
```

### 8.2 Verify the synonym definition

```sql
SELECT
    s.name AS SynonymName,
    s.base_object_name AS TargetObject,
    SCHEMA_NAME(s.schema_id) AS SchemaName
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'Settings'
  AND SCHEMA_NAME(s.schema_id) = 'Customer';
-- Returns: Customer | Settings | UserApiDB.Customer.Settings
```

### 8.3 Check settings for multiple customers

```sql
SELECT
    gs.GCID,
    gs.AllowDisplayFullName,
    gs.AllowShareFollow,
    gs.HomepageId
FROM Customer.Settings gs WITH (NOLOCK)
WHERE gs.GCID IN (12345678, 23456789, 34567890);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [GetAggregatedInfo API Documentation](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/13140426755/GetAggregatedInfo+API+Documentation) | Confluence (CR) | userSettings response block confirms the settings fields managed via UserApiDB: allowDisplayFullName, allowShareFollow, homepage (homepageId), privacyPolicyId, optOutReasonId |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 6/10, Logic: 7/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.Settings | Type: Synonym | Source: etoro/etoro/Customer/Synonyms/Customer.Settings.sql*
