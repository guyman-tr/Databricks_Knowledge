# History.CustomerRafonfigurationModels

> Temporal system-versioned history table storing all past versions of Refer-a-Friend (RAF) compensation configuration rules - recording every change made to which payout amounts and models were assigned to each RAF configuration.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (RafConfigurationID, RafModelTypeID, RafModelID) + ValidFrom + ValidTo |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo, ValidFrom) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Customer.RafConfigurationModels` (the source table is currently named `Customer.RafConfigurationModels_NogaJunk210725` in the SSDT repo, reflecting a developer rename during migration). SQL Server automatically moves rows here whenever a compensation model row is updated or deleted in the source table.

The source table defines the **Refer-a-Friend (RAF) compensation rules**: for a given RAF configuration (`RafConfigurationID`) and payout model combination (`RafModelTypeID`, `RafModelID`), it specifies how much money the referring user gets (`ReferringCompensationInCents`) and how many times they can receive it (`MaxNumberOfCompensations`). These rules determine the monetary incentive paid to customers who successfully recruit new depositing users to eToro.

This history table enables compliance auditing of compensation rule changes, investigation of payout disputes ("what was the configured compensation when this referral was made?"), and regulatory traceability of RAF program changes over time. The `Trace` column provides a JSON audit trail of who made each change and from which application.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever a compensation model row is modified or deleted.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, `RafConfigurationID`, `RafModelTypeID`, `RafModelID`

**Rules**:
- When a compensation rule is **updated**: SQL Server moves the old version here with `ValidTo` = the moment of update, `ValidFrom` = when that version was first active.
- When a compensation rule is **deleted**: SQL Server moves the row here with `ValidTo` = deletion timestamp.
- Rows currently active in the source table have `ValidTo = '9999-12-31...'` and are NOT in this history table.
- The CLUSTERED index on `(ValidTo, ValidFrom)` enables efficient `FOR SYSTEM_TIME AS OF` temporal point-in-time queries.

**Diagram**:
```
INSERT compensation rule (RafConfigurationID=46, RafModelTypeID=1, RafModelID=7, 50000 cents x 10)
  -> Row enters Customer.RafConfigurationModels (ValidFrom=NOW, ValidTo=9999-12-31)

UPDATE: change ReferringCompensationInCents from 50000 to 20000
  -> OLD row moves to History.CustomerRafonfigurationModels
       ValidFrom=original_time, ValidTo=NOW (e.g., 2025-05-04)
  -> NEW row stays in Customer.RafConfigurationModels
       ValidFrom=NOW, ValidTo=9999-12-31
```

### 2.2 RAF Compensation Model Structure

**What**: Each row defines one (Configuration, ModelType, Model) combination with its specific payout terms.

**Columns/Parameters Involved**: `RafConfigurationID`, `RafModelTypeID`, `RafModelID`, `MaxNumberOfCompensations`, `ReferringCompensationInCents`, `ReferredCompensationInCents`

**Rules**:
- `RafConfigurationID` identifies the geographic/regulatory scope of the RAF program (e.g., different configurations for different countries or regulatory regimes).
- `RafModelTypeID` distinguishes the model category: observed values are 1 and 2. CHECK constraint on source table (`CHK_Legal_ModelID`) enforces legal restrictions per type:
  - TypeID=1: RafModelID=4 is FORBIDDEN (blocked for legal reasons)
  - TypeID=2: RafModelIDs 0, 1, 7, 8 are FORBIDDEN
- `RafModelID` identifies the specific payout model variant (2, 3, 4, 5, 6, 7, 100 observed in history). Model 100 appears to be a special/legacy model.
- `ReferringCompensationInCents`: the reward paid to the referrer (person who invited). Historical values: 1000 ($10), 2400 ($24), 2500 ($25), 4000 ($40), 5000 ($50), 6000 ($60), 10000 ($100), 11000 ($110), 20000 ($200), 50000 ($500).
- `ReferredCompensationInCents`: reward for the newly registered user. Historically always 0 - referred users do not receive direct cash compensation under these models.
- `MaxNumberOfCompensations`: caps how many successful referrals a single user can be compensated for (3, 5, 8, 9, 10, 11, 12, 14, 18, 19 observed).

### 2.3 Change Audit via Trace Column

**What**: Every row version captures a JSON audit record of who made the change.

**Columns/Parameters Involved**: `Trace`

**Rules**:
- Computed on source table as: `CONCAT('{"HostName": "',host_name(),...}')` - captures session context at the moment of the DML operation.
- JSON structure: `HostName`, `AppName`, `SUserName` (SQL Server login), `SPID`, `DBName`, `ObjectName` (stored procedure name if called via SP, empty if direct query).
- When moved to history, the Trace captures the identity of whoever made the change (the version being stored).
- Historical data shows changes made via SSMS (`AppName = "Microsoft SQL Server Management Studio - Query"`) and application (`AppName = "Framework Microsoft SqlClient Data Provider"`), with SQL login `TRAD\nogaro`.

---

## 3. Data Overview

| RafConfigurationID | RafModelTypeID | RafModelID | MaxCompensations | ReferringCents | ValidFrom | ValidTo | Meaning |
|----|---|---|---|---|---|---|---|
| 46 | 1 | 7 | 10 | 50,000 ($500) | 2024-05-15 | 2025-05-04 | RAF config 46 with model type 1, model 7: a premium RAF offer paying $500 per referral up to 10 times. This version was active from May 2024 until replaced in May 2025. |
| 46 | 1 | 3 | 3 | 20,000 ($200) | 2024-11-28 | 2025-05-04 | Same config 46, different model (3): $200 per referral, max 3 referrals. Shorter program variant running concurrently with model 7 in a different slot. |
| 46 | 1 | 2 | 10 | 20,000 ($200) | 2024-05-15 | 2025-05-04 | Config 46, model 2: $200 per referral up to 10 times. Lower-tier offer compared to model 7 ($500). |
| 4 | 1 | 3 | 3 | 20,000 ($200) | 2024-10-13 | 2025-04-30 | Different RAF config (4), same model structure. Multiple configurations run different RAF programs simultaneously for different geographic/regulatory scopes. |
| 46 | 1 | 6 | 10 | 50,000 ($500) | 2024-05-15 | 2025-05-04 | Config 46, model 6: another $500 x 10 slot - config 46 had multiple $500-per-referral models active simultaneously. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RafConfigurationID | int | NO | - | CODE-BACKED | Identifier for the RAF (Refer-a-Friend) program configuration. Groups related compensation models under a common geographic/regulatory scope. One configuration can have multiple model rows (one per RafModelTypeID + RafModelID combination). Composite PK component in source table. |
| 2 | RafModelTypeID | int | NO | - | CODE-BACKED | Category of the compensation model. Two values observed: 1 and 2. Legal restrictions differ between types (see CHK_Legal_ModelID constraint): Type=1 forbids ModelID=4; Type=2 forbids ModelIDs 0, 1, 7, 8. Exact business labels for Type 1 vs Type 2 not defined in DDL - likely Standard vs Extended or Cash vs Credit. Composite PK component in source table. |
| 3 | RafModelID | int | NO | - | CODE-BACKED | Identifies the specific payout model variant within a type. Observed values: 2, 3, 4, 5, 6, 7, 100. Higher IDs appear to be newer program generations. Model 100 appears to be a legacy or special-purpose model (low compensation amounts, $50-$100 range). Composite PK component in source table. |
| 4 | MaxNumberOfCompensations | int | NO | - | CODE-BACKED | Maximum number of successful referrals for which the referring customer receives the compensation amount. Caps the total payout per referrer. Historical values: 3, 5, 8, 9, 10, 11, 12, 14, 18, 19. Value of 10 is the most common cap. |
| 5 | ReferringCompensationInCents | int | NO | 0 | CODE-BACKED | The cash reward paid to the customer who referred a new depositing user, in USD cents. Examples from history: 1000=$10, 5000=$50, 10000=$100, 20000=$200, 50000=$500. The compensation amount that changed most frequently as RAF program terms evolved. |
| 6 | ReferredCompensationInCents | int | NO | 0 | CODE-BACKED | The cash reward paid to the newly registered (referred) customer, in USD cents. Historically always 0 - referred users do not receive direct cash bonuses under these model configurations. The referring user is the incentivized party. |
| 7 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON audit string computed at time of DML on source table, capturing: HostName (server), AppName (SQL client application), SUserName (SQL Server login), SPID (connection ID), DBName, ObjectName (calling stored procedure, or empty for direct queries). Fixed max length of 733 characters matches the computed JSON format. Used for change attribution in compliance reviews. |
| 8 | ValidFrom | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version of the compensation model became active in Customer.RafConfigurationModels (i.e., when it was inserted or last updated). Managed by SQL Server temporal system-versioning. Lower bound for FOR SYSTEM_TIME point-in-time queries. |
| 9 | ValidTo | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded (modified or deleted from source table). Managed by SQL Server temporal system-versioning. Clustered index leading column for efficient temporal range lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RafConfigurationID | Customer.RafConfiguration (or similar) | Implicit | The RAF program configuration scope this model belongs to |
| RafModelTypeID | Dictionary or application enum | Implicit | The category of compensation model |
| RafModelID | Customer.RafModel (or similar) | Implicit | The specific payout model variant |
| (all columns) | Customer.RafConfigurationModels | Temporal | This row is a historical version of the source table row with matching composite key |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RafConfigurationModels | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server automatically writes superseded rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CustomerRafonfigurationModels (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Customer.RafConfigurationModels (table)
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RafConfigurationModels | Table | Source table - SQL Server writes old row versions here automatically on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_CustomerRafonfigurationModels | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

**Filegroup**: [DICTIONARY] - same as source table, consistent with configuration data classification.
**Storage**: DATA_COMPRESSION = PAGE.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

---

## 8. Sample Queries

### 8.1 What compensation terms were active for a configuration on a specific date
```sql
SELECT RafConfigurationID, RafModelTypeID, RafModelID,
       MaxNumberOfCompensations, ReferringCompensationInCents,
       ValidFrom, ValidTo
FROM [History].[CustomerRafonfigurationModels] WITH (NOLOCK)
WHERE RafConfigurationID = 46
  AND '2024-12-01' BETWEEN ValidFrom AND ValidTo
ORDER BY RafModelTypeID, RafModelID
```

### 8.2 Full change history for a specific configuration
```sql
-- History versions
SELECT 'History' AS Source, RafConfigurationID, RafModelTypeID, RafModelID,
       MaxNumberOfCompensations, ReferringCompensationInCents / 100.0 AS CompensationUSD,
       ValidFrom, ValidTo,
       JSON_VALUE(Trace, '$.SUserName') AS ChangedBy
FROM [History].[CustomerRafonfigurationModels] WITH (NOLOCK)
WHERE RafConfigurationID = 46
UNION ALL
-- Current versions
SELECT 'Current' AS Source, RafConfigurationID, RafModelTypeID, RafModelID,
       MaxNumberOfCompensations, ReferringCompensationInCents / 100.0 AS CompensationUSD,
       ValidFrom, ValidTo,
       JSON_VALUE(Trace, '$.SUserName') AS ChangedBy
FROM [Customer].[RafConfigurationModels_NogaJunk210725] WITH (NOLOCK)
WHERE RafConfigurationID = 46
ORDER BY RafModelTypeID, RafModelID, ValidFrom
```

### 8.3 Most frequently changed RAF models
```sql
SELECT RafConfigurationID, RafModelTypeID, RafModelID,
       COUNT(*) AS VersionCount,
       MIN(ReferringCompensationInCents) / 100.0 AS MinCompUSD,
       MAX(ReferringCompensationInCents) / 100.0 AS MaxCompUSD,
       MIN(ValidFrom) AS FirstChange,
       MAX(ValidTo) AS LastChange
FROM [History].[CustomerRafonfigurationModels] WITH (NOLOCK)
GROUP BY RafConfigurationID, RafModelTypeID, RafModelID
ORDER BY VersionCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [RAF Compensation System Design - Phase 1](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11988373449/RAF+Compensation+System+Design+-+Phase+1) | Confluence | RAF compensation system design documentation (content not accessible via API) |
| [Refer a Friend API - Getting Started](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12155554436/Refer+a+Friend+API+-+Getting+Started) | Confluence | RAF API documentation providing context on the Refer-a-Friend program architecture |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CustomerRafonfigurationModels | Type: Table | Source: etoro/etoro/History/Tables/History.CustomerRafonfigurationModels.sql*
