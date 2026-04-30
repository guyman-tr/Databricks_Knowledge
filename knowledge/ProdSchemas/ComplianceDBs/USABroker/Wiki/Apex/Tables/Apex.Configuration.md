# Apex.Configuration

> Key-value configuration store for Apex integration runtime settings such as branch codes and representative codes.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 1 unique constraint (Key) |

---

## 1. Business Meaning

Apex.Configuration is a simple key-value store that holds runtime configuration settings for the Apex Clearing integration. Each row represents a single named configuration parameter with a string value (often JSON-encoded for complex settings). This allows the application to retrieve and update configuration without code deployments.

This table exists to externalize integration-specific settings that may need to change independently of the application code. For example, the branch and representative codes used when submitting account applications to Apex Clearing are stored here rather than hardcoded, allowing operations staff to update them if the clearing arrangement changes.

Data flows through two procedures: Apex.GetConfiguration retrieves a setting by key name, and Apex.SaveConfiguration upserts a setting (UPDATE if the key exists, INSERT if new). Currently contains a single configuration entry for the branch/rep code mapping.

---

## 2. Business Logic

### 2.1 Branch and Representative Code Configuration

**What**: The BranchName configuration stores the Apex Clearing branch code and representative code used when submitting account applications.

**Columns/Parameters Involved**: `Key`, `Value`

**Rules**:
- The "BranchName" key holds a JSON object: `{"Branch":"3FN","RepCode":"ETA"}`
- "3FN" is the Apex branch identifier assigned to this platform
- "ETA" is the representative code (likely "eToro America" or similar)
- These values are included in Apex API calls for account creation and are required by Apex Clearing to identify which introducing broker submitted the application

---

## 3. Data Overview

| ID | Key | Value | Meaning |
|----|-----|-------|---------|
| 1 | BranchName | {"Branch":"3FN","RepCode":"ETA"} | Apex Clearing branch assignment for this platform. Branch "3FN" with representative code "ETA" - used in all account creation/update API calls to identify the introducing broker relationship. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Key | varchar(50) | NO | - | CODE-BACKED | The unique configuration parameter name. Acts as the logical key (UNIQUE constraint) used by GetConfiguration and SaveConfiguration for lookups. Known key: "BranchName" for Apex branch/rep code configuration. |
| 2 | Value | varchar(1024) | YES | - | CODE-BACKED | The configuration value as a string. May contain plain text or JSON-encoded complex objects. NULL is allowed for configuration keys that have been defined but not yet assigned a value. Maximum 1024 characters. |
| 3 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. While the logical key is the Key column (unique constraint), ID serves as the clustered PK for physical storage efficiency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.GetConfiguration | @key | Reader | Retrieves configuration value by key name |
| Apex.SaveConfiguration | @key, @value | Writer | Upserts configuration - updates existing key or inserts new one |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.GetConfiguration | Stored Procedure | Reader - retrieves config by key |
| Apex.SaveConfiguration | Stored Procedure | Writer - upserts config key/value |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Configuration | CLUSTERED PK | ID ASC | - | - | Active |
| UN_Configuration_Key | NC UNIQUE | Key ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Configuration | PRIMARY KEY | Clustered on ID - surrogate key |
| UN_Configuration_Key | UNIQUE | Key must be unique - each configuration parameter appears once |

---

## 8. Sample Queries

### 8.1 Retrieve all configuration settings

```sql
SELECT ID, [Key], [Value]
FROM Apex.Configuration WITH (NOLOCK)
ORDER BY [Key];
```

### 8.2 Get the branch configuration as parsed JSON

```sql
SELECT [Key], [Value],
       JSON_VALUE([Value], '$.Branch') AS Branch,
       JSON_VALUE([Value], '$.RepCode') AS RepCode
FROM Apex.Configuration WITH (NOLOCK)
WHERE [Key] = 'BranchName';
```

### 8.3 Check for configuration keys without values

```sql
SELECT ID, [Key]
FROM Apex.Configuration WITH (NOLOCK)
WHERE [Value] IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.Configuration | Type: Table | Source: USABroker/Apex/Tables/Apex.Configuration.sql*
