# Customer.PostUpdateContactUserInfo

> XML-dispatched post-update bridge that propagates contact information changes (country, email, address, phone, region) to the demo environment via Demo_UpdateContactUserInfoRemote.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params XML (contains GCID and contact fields); returns @RetVal INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer updates their contact information in the eToro real environment (address, phone, email, country of residence, etc.), that change must be synchronized to the demo environment. `PostUpdateContactUserInfo` is the bridge for contact data sync - it receives all contact fields in an XML parameter, parses them, and delegates to `Demo_UpdateContactUserInfoRemote` on the demo database.

This procedure is part of the same PostUpdate* family as PostUpdateBasicUserInfo and PostUpdateRiskUserInfo, all using the identical @Params/@PartsToDo/@ID signature to enable a unified asynchronous dispatch pattern. The procedure writes nothing to the Customer schema directly - its sole action is unwrapping XML and forwarding to the demo environment.

The `@SubRegionID` parameter was added on 05/08/2019 by Ran Ovadia to extend contact info with sub-regional classification (likely for compliance/regulatory routing based on geographic sub-divisions).

---

## 2. Business Logic

### 2.1 Real-to-Demo Contact Info Synchronization

**What**: Propagates contact profile updates from real to demo environment.

**Columns/Parameters Involved**: `@gcid`, `@countryId`, `@email`, `@address`, `@city`, `@zip`, `@phone`, `@phonePrefix`, `@phoneBody`, `@mobile`, `@fax`, `@stateId`, `@buildingNumber`, `@RegionID`, `@SubRegionID`

**Rules**:
- Calls `Demo_UpdateContactUserInfoRemote` (note: no schema prefix - resolves to dbo).
- GCID is the cross-environment customer identity.
- `@buildingNumber` is parsed from XML but passed as NULL in the remote call (13th argument is NULL literal).
- All fields are nullable with NULL defaults; only fields present in the XML are populated.
- @PartsToDo bitmask: 0 or bit-1 set = execute.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | VERIFIED | XML document containing contact info. Expected nodes: gcid, countryId, email, address, city, zip, phone, phonePrefix, phoneBody, mobile, fax, stateId, buildingNumber, RegionID, SubRegionID. |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bitmask: 0 or bit-1 = execute demo sync. Standard PostUpdate* pattern. |
| 3 | @ID | INT | NO | - | NAME-INFERRED | Reserved - not used in body. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Demo_UpdateContactUserInfoRemote | Caller (EXEC) | Remote call to demo environment for contact info update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer contact update pipeline | External | Caller | Called asynchronously after contact info change in real environment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PostUpdateContactUserInfo (procedure)
+-- dbo.Demo_UpdateContactUserInfoRemote (procedure) [demo environment remote call]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Demo_UpdateContactUserInfoRemote | Procedure | EXEC - applies contact info update in the demo environment |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @buildingNumber NULL in EXEC | Design | buildingNumber is parsed from XML but the remote call passes NULL for it (13th parameter). Likely unused or unsupported by the demo procedure signature. |
| SubRegionID added 2019-05-08 | Change history | Added by Ran Ovadia for sub-regional classification support (compliance/routing). |

---

## 8. Sample Queries

### 8.1 Execute contact info sync for a specific customer

```sql
DECLARE @params XML = '<Root>
    <gcid Value="1983586"/>
    <countryId Value="1"/>
    <email Value="test@example.com"/>
    <address Value="123 Main St"/>
    <city Value="New York"/>
    <zip Value="10001"/>
    <phone Value="+12125550100"/>
    <phonePrefix Value="+1"/>
    <phoneBody Value="2125550100"/>
    <RegionID Value="10"/>
    <SubRegionID Value="5"/>
</Root>';

EXEC Customer.PostUpdateContactUserInfo
    @Params = @params,
    @PartsToDo = 0,
    @ID = 0;
```

### 8.2 Return value interpretation

```sql
DECLARE @ret INT;
EXEC @ret = Customer.PostUpdateContactUserInfo
    @Params = '<Root><gcid Value="1983586"/></Root>',
    @PartsToDo = 0,
    @ID = 0;
-- 0 = success, -1 = XML parse error, >0 = remote call failed
SELECT @ret AS ReturnValue;
```

### 8.3 Find all PostUpdate* procedures in Customer schema

```sql
SELECT
    OBJECT_NAME(object_id) AS ProcName,
    create_date,
    modify_date
FROM sys.objects WITH (NOLOCK)
WHERE schema_id = SCHEMA_ID('Customer')
    AND OBJECT_NAME(object_id) LIKE 'PostUpdate%'
    AND type = 'P'
ORDER BY ProcName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 7.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.PostUpdateContactUserInfo | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.PostUpdateContactUserInfo.sql*
