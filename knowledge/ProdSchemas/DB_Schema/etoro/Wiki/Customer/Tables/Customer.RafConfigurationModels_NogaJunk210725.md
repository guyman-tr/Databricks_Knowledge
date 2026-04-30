# Customer.RafConfigurationModels_NogaJunk210725

> RAF compensation model detail table: per-configuration, per-model-type, per-model compensation amounts and caps. Versioned to History.CustomerRafonfigurationModels. Drives model-aware RAF payout selection based on customer PlayerLevel (Club) or GuruStatus (PI).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | (RafConfigurationID, RafModelTypeID, RafModelID) composite PK |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 1 (clustered composite PK) |

---

## 1. Business Meaning

Customer.RafConfigurationModels_NogaJunk210725 stores the model-level RAF (Refer-a-Friend) compensation overrides for each RAF configuration. It is a child table to Customer.CountryRafConfiguration_NogaJunk210725: each `RafConfigurationID` in that table can have multiple model rows here, one per (RafModelTypeID, RafModelID) combination.

**Two model type axes:**
- `RafModelTypeID=1` (Club model): Compensation varies by the **referring customer's PlayerLevelID**. `RafModelID` matches the PlayerLevelID. RafModelID=100 is the special BronzePlus tier (set by the `@IsBronzePlus` parameter in calling procedures). CHECK constraint bars RafModelID=4 for this type (PlayerLevelID=4 = Popular Investor, who uses the PI model path).
- `RafModelTypeID=2` (PI model): Compensation varies by the **referring customer's GuruStatusID**. `RafModelID` matches the GuruStatusID. CHECK constraint bars RafModelIDs 0,1,7,8 for this type.

246 rows across 24 distinct configurations. `ReferredCompensationInCents` is 0 for all 246 rows - the referred (new) customer receives no compensation from this model; only the referrer does.

The table resides on the DICTIONARY filegroup for fast lookup performance. Temporal SYSTEM_VERSIONING (-> History.CustomerRafonfigurationModels, note: typo in history table name vs this table) provides full audit trail of compensation rule changes.

**Non-suffixed counterpart**: `Customer.RafConfigurationModels` (no suffix) does NOT exist in this database. The stored procedures `Customer.GetRafConfiguration_NogaJunk210725` and `Customer.GetRafStatusByGCID_NogaJunk210725` reference the non-suffixed name in their SQL, suggesting either a synonym maps to this table, or these procedures are in development alongside this table.

---

## 2. Business Logic

### 2.1 Model Selection - Best Compensation Wins

**What**: When determining a referring customer's RAF entitlement, the system evaluates both the Club (PlayerLevel) model row and the PI (GuruStatus) model row, then chooses whichever offers higher total potential payout.

**Columns/Parameters Involved**: `RafModelTypeID`, `RafModelID`, `ReferringCompensationInCents`, `MaxNumberOfCompensations`

**Rules** (from Customer.GetRafStatusByGCID_NogaJunk210725):
- For a given `RafConfigurationID` (derived from the customer's country/regulation):
  - Find TypeID=1 row WHERE `RafModelID = @PlayerLevelID` (or 100 for BronzePlus)
  - Find TypeID=2 row WHERE `RafModelID = @GuruStatusID`
- Compare: (RM_PI.ReferringCompensationInCents * RM_PI.MaxNumberOfCompensations) vs (RM_Club.ReferringCompensationInCents * RM_Club.MaxNumberOfCompensations)
- Choose the model with higher total potential payout; if tie, prefer Club
- If neither model row matches (customer has no relevant PlayerLevel/GuruStatus match): fall back to CountryRafConfiguration.MaxNumberOfCompensations
- `@MaxNumberOfCompensations` = NULL if no model row exists for this config -> `@RafStatus=3` (exists but no configuration)

### 2.2 Club Model Tiers (RafModelTypeID=1)

**What**: Different PlayerLevelIDs earn different compensation amounts.

**Rules**:
- RafModelID=2: MaxComps=3-10, Referring=$100-$200 (varies by config)
- RafModelID=3: MaxComps=3-10, Referring=$100-$200
- RafModelID=5: MaxComps=3-10, Referring=$50-$200
- RafModelID=6: MaxComps=10, Referring=$500 (premium tier)
- RafModelID=7: MaxComps=10, Referring=$500 (premium tier)
- RafModelID=100 (BronzePlus): MaxComps=3, Referring=$10-$100
- RafModelID=4 is BANNED by CHK_Legal_ModelID (Popular Investors use TypeID=2 path instead)

### 2.3 PI Model Tiers (RafModelTypeID=2)

**What**: Popular Investors (Guru-status customers) use a separate model with higher caps.

**Rules**:
- All TypeID=2 rows have MaxNumberOfCompensations=50 (vs 3-10 for TypeID=1)
- ReferringCompensationInCents=$200 for all PI tiers in current data
- RafModelIDs 2,3,4,5,6 = GuruStatusID values for PI tiers
- RafModelIDs 0,1,7,8 are BANNED by CHK_Legal_ModelID

### 2.4 CHECK Constraint - Legal Model ID Validation

**What**: Prevents invalid model IDs that would break the RAF payout logic.

**Expression**: `(RafModelTypeID=1 AND RafModelID<>4) OR (RafModelTypeID=2 AND RafModelID NOT IN (8,7,1,0))`

**Rules**:
- TypeID=1 cannot use RafModelID=4 (Popular Investor - use TypeID=2 instead)
- TypeID=2 cannot use RafModelIDs 0,1,7,8 (undefined/invalid GuruStatus IDs in this context)

### 2.5 Temporal Versioning

**What**: All changes to compensation rules are automatically versioned to History.CustomerRafonfigurationModels.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- ValidFrom/ValidTo: GENERATED ALWAYS AS ROW START/END - system-managed
- Query historical config: FOR SYSTEM_TIME AS OF `{timestamp}`
- History table name has a typo: "CustomerRafonfigurationModels" (missing "C" in "Configuration")

---

## 3. Data Overview

| RafModelTypeID | RowCount | DistinctModels | RafModelIDs | MaxComps Range | ReferringCents Range |
|----------------|----------|----------------|-------------|----------------|---------------------|
| 1 (Club) | ~168 | 6 (2,3,5,6,7,100) | See above | 3-10 | 1000-50000 |
| 2 (PI) | ~78 | 5 (2,3,4,5,6) | See above | 50 | 20000 |

*246 total rows. 24 distinct RafConfigurationIDs: 1-5, 26-36, 45-51, 58. Gaps (6-25, 37-44, 52-57) indicate deleted/expired configurations preserved in History.CustomerRafonfigurationModels. ReferredCompensationInCents=0 for all 246 rows.*

**Sample - Config 1 (TypeID=1, Club model):**

| RafConfigurationID | RafModelTypeID | RafModelID | MaxComps | ReferringCents | Meaning |
|--------------------|----------------|------------|----------|----------------|---------|
| 1 | 1 | 2 | 10 | 20000 | PlayerLevel 2: $200, up to 10x |
| 1 | 1 | 5 | 10 | 10000 | PlayerLevel 5: $100, up to 10x |
| 1 | 1 | 6 | 10 | 50000 | PlayerLevel 6: $500, up to 10x (premium) |
| 1 | 1 | 100 | 3 | 5000 | BronzePlus: $50, up to 3x |
| 2 | 2 | 4 | 50 | 20000 | GuruStatus 4: $200, up to 50x (PI model) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RafConfigurationID | int | NO | - | VERIFIED | FK to Customer.CountryRafConfiguration_NogaJunk210725.RafConfigurationID (implicit - no FK constraint). Identifies which country/regulation RAF program this model applies to. Part of composite PK. |
| 2 | RafModelTypeID | int | NO | - | VERIFIED | Model axis type. 1 = Club model (compensation varies by customer PlayerLevelID); 2 = PI model (compensation varies by customer GuruStatusID). Validated by CHK_Legal_ModelID. Part of composite PK. |
| 3 | RafModelID | int | NO | - | VERIFIED | Specific tier within the model type. TypeID=1: matches PlayerLevelID (2,3,5,6,7) or 100 for BronzePlus. TypeID=2: matches GuruStatusID (2,3,4,5,6). Validated by CHK_Legal_ModelID to exclude invalid IDs. Part of composite PK. |
| 4 | MaxNumberOfCompensations | int | NO | - | VERIFIED | Maximum number of RAF compensation awards the referrer can earn under this model for this configuration. TypeID=1: 3 or 10 (varies by tier and config). TypeID=2: always 50 (PI model is more generous). |
| 5 | ReferringCompensationInCents | int | NO | 0 | VERIFIED | Cash compensation (USD cents) awarded to the REFERRING customer per successful RAF award under this model. Values in data: 1000 ($10), 5000 ($50), 10000 ($100), 20000 ($200), 50000 ($500). Default=0 (defined as DF_ReferringMinPositionsAmountInCents). |
| 6 | ReferredCompensationInCents | int | NO | 0 | VERIFIED | Cash compensation (USD cents) for the REFERRED (new) customer. Currently 0 for all 246 rows - referred customer compensation is not configured here. Default=0 (defined as DF_ReferredMinPositionsAmountInCents). |
| 7 | Trace | computed nvarchar | YES | - | CODE-BACKED | Runtime audit computed column: JSON string capturing HostName, AppName, SUserName, SPID, DBName, ObjectName at the time of the last modification. Not persisted - recalculated on read. Diagnostic tool for tracking which app/procedure last modified a row. |
| 8 | ValidFrom | datetime2(7) | NO | - | VERIFIED | Temporal period start - GENERATED ALWAYS AS ROW START. System-assigned UTC timestamp when this row version became current. |
| 9 | ValidTo | datetime2(7) | NO | - | VERIFIED | Temporal period end - GENERATED ALWAYS AS ROW END. '9999-12-31' for current rows; set to actual change time when row is superseded in History.CustomerRafonfigurationModels. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RafConfigurationID | Customer.CountryRafConfiguration_NogaJunk210725 | Implicit (no FK) | Parent RAF configuration (country/regulation scope). JOIN ON RafConfigurationID. |
| RafModelID (TypeID=1) | Customer.CustomerStatic | Implicit | Matches PlayerLevelID of referring customer. No FK - join performed at query time. |
| RafModelID (TypeID=2) | BackOffice.Customer (GuruStatusID) | Implicit | Matches GuruStatusID of referring customer. No FK - join performed at query time. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.GetRafStatusByGCID_NogaJunk210725 | RafConfigurationID, RafModelTypeID, RafModelID | READER | Double LEFT JOIN: one alias for TypeID=1 (Club), one for TypeID=2 (PI). Picks best compensation. |
| Customer.GetRafConfiguration_NogaJunk210725 | RafConfigurationID | READER | LEFT JOINs models to CountryRafConfiguration for full config export. Returns ModelReferringCompensationInCents, ModelMaxNumberOfCompensations per row. |
| History.CustomerRafonfigurationModels | - | Temporal History | Receives superseded row versions automatically. Note typo in history table name. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RafConfigurationModels_NogaJunk210725
|- Customer.CountryRafConfiguration_NogaJunk210725 [implicit FK - RafConfigurationID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CountryRafConfiguration_NogaJunk210725 | Table | Parent config - RafConfigurationID ties models to country/regulation scopes |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetRafStatusByGCID_NogaJunk210725 | Stored Procedure | Looks up Club and PI model rows to determine @MaxNumberOfCompensations for RAF status check |
| Customer.GetRafConfiguration_NogaJunk210725 | Stored Procedure | LEFT JOINs to return model-level compensation details alongside country config |
| History.CustomerRafonfigurationModels | Table | Temporal history destination |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RafConfigurationModels | CLUSTERED | RafConfigurationID ASC, RafModelTypeID ASC, RafModelID ASC | - | - | Active (fillfactor=100, DICTIONARY filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RafConfigurationModels | PRIMARY KEY | (RafConfigurationID, RafModelTypeID, RafModelID) unique - one compensation rule per config+type+model combination |
| CHK_Legal_ModelID | CHECK | TypeID=1: RafModelID<>4 (Popular Investors use TypeID=2). TypeID=2: RafModelID NOT IN (0,1,7,8) (invalid GuruStatus IDs) |
| DF_ReferringMinPositionsAmountInCents | DEFAULT | ReferringCompensationInCents = 0 |
| DF_ReferredMinPositionsAmountInCents | DEFAULT | ReferredCompensationInCents = 0 |

---

## 8. Sample Queries

### 8.1 Get all model rows for a specific RAF configuration

```sql
SELECT
    RafModelTypeID,
    CASE RafModelTypeID WHEN 1 THEN 'Club (PlayerLevel)' WHEN 2 THEN 'PI (GuruStatus)' END AS ModelTypeName,
    RafModelID,
    MaxNumberOfCompensations,
    ReferringCompensationInCents / 100.0 AS ReferringCompensationUSD,
    ReferredCompensationInCents / 100.0 AS ReferredCompensationUSD
FROM Customer.RafConfigurationModels_NogaJunk210725 WITH (NOLOCK)
WHERE RafConfigurationID = 1
ORDER BY RafModelTypeID, RafModelID
```

### 8.2 Simulate model selection for a customer (Club vs PI)

```sql
DECLARE @RafConfigurationID INT = 1, @PlayerLevelID INT = 6, @GuruStatusID INT = 0

SELECT
    CASE
        WHEN ISNULL(rm_pi.ReferringCompensationInCents,0)*ISNULL(rm_pi.MaxNumberOfCompensations,0)
             > ISNULL(rm_club.ReferringCompensationInCents,0)*ISNULL(rm_club.MaxNumberOfCompensations,0)
             AND rm_pi.MaxNumberOfCompensations IS NOT NULL THEN 'PI model wins'
        WHEN rm_club.MaxNumberOfCompensations IS NOT NULL THEN 'Club model wins'
        ELSE 'Fallback to CountryRafConfiguration'
    END AS SelectedModel,
    rm_club.ReferringCompensationInCents / 100.0 AS ClubCompUSD,
    rm_club.MaxNumberOfCompensations AS ClubMaxComps,
    rm_pi.ReferringCompensationInCents / 100.0 AS PICompUSD,
    rm_pi.MaxNumberOfCompensations AS PIMaxComps
FROM (SELECT 1 AS Dummy) x
LEFT JOIN Customer.RafConfigurationModels_NogaJunk210725 rm_club WITH (NOLOCK)
    ON rm_club.RafConfigurationID = @RafConfigurationID
    AND rm_club.RafModelTypeID = 1 AND rm_club.RafModelID = @PlayerLevelID
LEFT JOIN Customer.RafConfigurationModels_NogaJunk210725 rm_pi WITH (NOLOCK)
    ON rm_pi.RafConfigurationID = @RafConfigurationID
    AND rm_pi.RafModelTypeID = 2 AND rm_pi.RafModelID = @GuruStatusID
```

### 8.3 View compensation history for a configuration

```sql
SELECT
    RafConfigurationID, RafModelTypeID, RafModelID,
    ReferringCompensationInCents / 100.0 AS ReferringUSD,
    MaxNumberOfCompensations,
    ValidFrom, ValidTo
FROM Customer.RafConfigurationModels_NogaJunk210725
FOR SYSTEM_TIME ALL
WHERE RafConfigurationID = 1
ORDER BY RafModelTypeID, RafModelID, ValidFrom
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [RAF Compensation System Design - Phase 1](https://etoro-jira.atlassian.net/wiki/spaces) (ID: 11988373449) | Confluence | Page exists but was not accessible in current session |
| [PART-475](https://etoro-jira.atlassian.net/browse/PART-475) | Jira | GetRafStatusByGCID: returns RafStatus (0-3) and IsFraud for UI referral status display |
| [PART-1488](https://etoro-jira.atlassian.net/browse/PART-1488) | Jira | Added support for PI (GuruStatus) and Club (PlayerLevel) models in GetRafStatusByGCID |
| [PART-2869](https://etoro-jira.atlassian.net/browse/PART-2869) | Jira | Added @IsBronzePlus parameter (sets PlayerLevelID=100) to GetRafStatusByGCID |
| [PART-2828](https://etoro-jira.atlassian.net/browse/PART-2828) | Jira | Added ReferredMinDepositInCents and ReferringMinDepositInCents to GetRafConfiguration |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 4 Jira (from procedure comments) | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RafConfigurationModels_NogaJunk210725 | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.RafConfigurationModels_NogaJunk210725.sql*
