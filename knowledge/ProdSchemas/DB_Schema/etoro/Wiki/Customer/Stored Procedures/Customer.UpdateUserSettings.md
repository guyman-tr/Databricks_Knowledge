# Customer.UpdateUserSettings

> Full customer settings update orchestrator: resolves GCID to CID, then updates both the etoro-DB privacy/opt-out settings (via UpdateUserSettingsRemote) and the UserApiDB social/display settings (via dbo.General_UpdateSettings) in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Orchestrates two sub-procedures; returns 1 if social settings update affected rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateUserSettings is the unified "write all user settings" entry point. It accepts all customer-configurable settings in one call and routes them to the appropriate storage layer. Privacy policy and opt-out preferences live in etoro DB (Customer.CustomerStatic, via Customer.UpdateUserSettingsRemote). Social display preferences (allow full name display, allow follow sharing, homepage preference) live in UserApiDB (via dbo.General_UpdateSettings). This procedure bridges the two storage layers so callers do not need to know the split.

The procedure first resolves the caller's GCID to CID - necessary because dbo.General_UpdateSettings operates on CID while Customer.UpdateUserSettingsRemote operates on GCID. This GCID-to-CID lookup reads Customer.CustomerStatic directly with NOLOCK, using the heavily-covered IDX_Customer_Customer_GCID index.

The GetAggregatedInfo API endpoint (UserApiDB, documented in Confluence 2025) exposes the full userSettings block containing all six fields: gcid, privacyPolicyId, allowDisplayFullName, allowShareFollow, homepage, optOutReasonId. Customer.UpdateUserSettings is the write-side counterpart for that read endpoint.

Data flows: application calls Customer.UpdateUserSettings -> this procedure resolves GCID, calls UpdateUserSettingsRemote (updates CustomerStatic.PrivacyPolicyID + OptOutReasonID in etoro DB), then calls dbo.General_UpdateSettings (updates UserApiDB settings). Returns 1 if General_UpdateSettings affected at least one row.

---

## 2. Business Logic

### 2.1 Dual-Database Settings Update

**What**: Customer settings are split across two databases; this procedure is the single write surface that updates both atomically within a single call scope (though not in a distributed transaction).

**Columns/Parameters Involved**: all six parameters + @cid (internal)

**Rules**:
- GCID -> CID resolution: reads Customer.CustomerStatic WITH(NOLOCK) - if GCID not found, @cid is NULL and General_UpdateSettings receives NULL
- UpdateUserSettingsRemote is called first: handles PrivacyPolicyID + OptOutReasonID in etoro DB (CustomerStatic)
- dbo.General_UpdateSettings is called second: handles AllowDisplayFullName, AllowShareFollow, HomepageId in UserApiDB
- The @@ROWCOUNT check and SELECT 1 return reflects General_UpdateSettings' row count, NOT UpdateUserSettingsRemote's - if General_UpdateSettings affects 0 rows (e.g., NULL CID), SELECT 1 is not returned even if privacy settings were updated
- All parameters have NULL defaults - caller can omit any that do not need updating (but UpdateUserSettingsRemote will still run with NULL values, which triggers the ISNULL(null,1)=1 path, setting OptOutReasonID=0)

**Diagram**:
```
EXEC Customer.UpdateUserSettings @gcid, @privacyPolicyId, @allowDisplayFullName,
                                  @allowShareFollow, @homepageId, @OptOutReasonID
         |
         v
SELECT @cid = CID FROM CustomerStatic WHERE GCID = @gcid
         |
    +----+----+
    |         |
CID found   CID not found
    |         |
@cid = N    @cid = NULL
    |              \
    +-------+-------+
            |
            v
EXEC Customer.UpdateUserSettingsRemote @gcid, @privacyPolicyId, @OptOutReasonID
  -> Updates CustomerStatic.PrivacyPolicyID + OptOutReasonID (etoro DB)
            |
            v
EXEC dbo.General_UpdateSettings @cid, @allowDisplayFullName, @allowShareFollow, @homepageId
  -> Updates UserApiDB.Customer settings (display/social preferences)
            |
    @@ROWCOUNT > 0?
    |           |
   YES          NO
SELECT 1    (no output)
(success)   (nothing returned)
```

### 2.2 Parameter Routing by Storage Layer

**What**: Each parameter targets a specific storage layer; the procedure routes automatically.

**Columns/Parameters Involved**: all parameters

**Rules**:
| Parameter | Routed To | Storage Layer |
|-----------|-----------|---------------|
| @privacyPolicyId | UpdateUserSettingsRemote -> CustomerStatic.PrivacyPolicyID | etoro DB |
| @OptOutReasonID | UpdateUserSettingsRemote -> CustomerStatic.OptOutReasonID | etoro DB |
| @allowDisplayFullName | dbo.General_UpdateSettings -> UserApiDB | UserApiDB |
| @allowShareFollow | dbo.General_UpdateSettings -> UserApiDB | UserApiDB |
| @homepageId | dbo.General_UpdateSettings -> UserApiDB | UserApiDB |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | VERIFIED | Group Customer ID of the customer whose settings are being updated. Used to resolve CID from CustomerStatic (needed for General_UpdateSettings) and passed to UpdateUserSettingsRemote (which updates CustomerStatic directly by GCID). |
| 2 | @privacyPolicyId | INT | YES | NULL | VERIFIED | Privacy policy version the customer is accepting. Passed to Customer.UpdateUserSettingsRemote which writes to CustomerStatic.PrivacyPolicyID. NULL or 1 resets opt-out (see UpdateUserSettingsRemote for the conditional logic). Per GetAggregatedInfo API docs: this is the `privacyPolicyId` in userSettings response. |
| 3 | @allowDisplayFullName | BIT | YES | NULL | VERIFIED | Whether the customer's full name is publicly visible on their profile. Passed to dbo.General_UpdateSettings which writes to UserApiDB. Per GetAggregatedInfo API docs: this is `allowDisplayFullName` in userSettings response. NULL = no change to existing setting. |
| 4 | @allowShareFollow | BIT | YES | NULL | VERIFIED | Whether other users can follow and copy this customer's trades. Passed to dbo.General_UpdateSettings which writes to UserApiDB. Per GetAggregatedInfo API docs: this is `allowShareFollow` in userSettings response. NULL = no change to existing setting. |
| 5 | @homepageId | INT | YES | NULL | CODE-BACKED | Homepage/landing page preference ID for the customer's platform experience. Passed to dbo.General_UpdateSettings which writes to UserApiDB. Per GetAggregatedInfo API docs: this is `homepage` in userSettings response. NULL = no change. |
| 6 | @OptOutReasonID | SMALLINT | YES | NULL | VERIFIED | GDPR opt-out reason code. Passed to Customer.UpdateUserSettingsRemote which writes to CustomerStatic.OptOutReasonID (conditionally - only when @privacyPolicyId is a non-default value). Per GetAggregatedInfo API docs: this is `optOutReasonId` in userSettings response. NULL defaults to reason 1 via ISNULL in UpdateUserSettingsRemote. |
| 7 | Return: SELECT 1 | INT | - | - | VERIFIED | Returns 1 if dbo.General_UpdateSettings affected at least one row (@@ROWCOUNT > 0). Nothing is returned if General_UpdateSettings affects 0 rows. Note: this reflects General_UpdateSettings outcome only - UpdateUserSettingsRemote's row count is NOT checked here. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | Reader (SELECT) | Resolves GCID to CID via NOLOCK lookup before calling sub-procedures |
| @gcid, @privacyPolicyId, @OptOutReasonID | Customer.UpdateUserSettingsRemote | Caller | Handles the etoro-DB privacy/opt-out settings portion |
| @cid, @allowDisplayFullName, @allowShareFollow, @homepageId | dbo.General_UpdateSettings | Caller | Handles the UserApiDB social/display settings portion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (application layer - User-API service) | - | Caller | Called by the User-API service when customer updates any settings from the userSettings block |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateUserSettings (procedure)
├── Customer.CustomerStatic (table) [GCID->CID resolution]
├── Customer.UpdateUserSettingsRemote (procedure)
│     └── Customer.Customer (view)
│           ├── Customer.CustomerStatic (table)
│           └── Customer.CustomerMoney (table)
└── dbo.General_UpdateSettings (procedure) [cross-schema, writes to UserApiDB]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT NOLOCK to resolve GCID to CID |
| Customer.UpdateUserSettingsRemote | Stored Procedure | Called to update PrivacyPolicyID + OptOutReasonID in CustomerStatic |
| dbo.General_UpdateSettings | Stored Procedure | Called to update AllowDisplayFullName, AllowShareFollow, HomepageId in UserApiDB |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (User-API application service) | Application | Calls this as the write-side counterpart to the GetAggregatedInfo userSettings read |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. CustomerStatic.GCID lookup uses IDX_Customer_Customer_GCID (NC, wide INCLUDE).

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Update all user settings at once

```sql
EXEC Customer.UpdateUserSettings
    @gcid = 12345678,
    @privacyPolicyId = 3,
    @allowDisplayFullName = 1,
    @allowShareFollow = 0,
    @homepageId = 2,
    @OptOutReasonID = 2;
-- Returns 1 if General_UpdateSettings succeeded
```

### 8.2 Update only privacy policy (leave social settings unchanged)

```sql
EXEC Customer.UpdateUserSettings
    @gcid = 12345678,
    @privacyPolicyId = NULL,
    @allowDisplayFullName = NULL,
    @allowShareFollow = NULL,
    @homepageId = NULL,
    @OptOutReasonID = NULL;
-- Resets OptOutReasonID to 0 in CustomerStatic; social settings passed as NULL to General_UpdateSettings
```

### 8.3 Verify current settings after update

```sql
-- Privacy/opt-out fields (etoro DB side)
SELECT
    cs.GCID,
    cs.CID,
    cs.PrivacyPolicyID,
    cs.OptOutReasonID
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.GCID = 12345678;

-- Social/display fields (UserApiDB side)
SELECT *
FROM Customer.Settings WITH (NOLOCK)
WHERE GCID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [GetAggregatedInfo API Documentation](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/13140426755/GetAggregatedInfo+API+Documentation) | Confluence (CR) | userSettings response block documents all six fields managed by this procedure: gcid, privacyPolicyId, allowDisplayFullName, allowShareFollow, homepage, optOutReasonId. Confirms the split: privacy fields in etoro DB, social settings in UserApiDB. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.UpdateUserSettings | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateUserSettings.sql*
