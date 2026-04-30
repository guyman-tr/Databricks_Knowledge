# Customer.PostUpdateBasicUserInfo

> XML-dispatched post-update bridge that propagates basic customer profile changes (name, DOB, gender, language, level) to the demo environment via dbo.Demo_UpdateBasicUserInfoRemote.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params XML (contains GCID, CID, and basic profile fields); returns @RetVal INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

eToro maintains parallel real-money and demo (paper-trading) environments. When a customer updates their basic profile information in the real environment, that change must be propagated to the demo environment to keep the two in sync. `PostUpdateBasicUserInfo` is the synchronization bridge for basic user info: name, date of birth, gender, language preference, and account level.

The procedure receives all data in a single XML parameter (the same @Params/@PartsToDo/@ID signature pattern used across all PostUpdate* procedures), parses out the individual field values, and calls `dbo.Demo_UpdateBasicUserInfoRemote` on the demo environment with those values. It writes nothing to the Customer schema directly.

A notable data-quality fix (added 08/02/2018) handles the edge case where `@gender` arrives as an empty string `''` - this is coerced to NULL before the remote call, because the CustomerBasic table in the demo environment has a constraint rejecting empty-string gender values.

---

## 2. Business Logic

### 2.1 Real-to-Demo Synchronization

**What**: Propagates basic profile updates from the real environment to the demo environment.

**Columns/Parameters Involved**: `@gcid`, `@fName`, `@lName`, `@languageId`, `@dob`, `@gender`, `@level`

**Rules**:
- Only Part 1 exists (@PartsToDo = 0 OR bit-1 set = execute).
- Calls `dbo.Demo_UpdateBasicUserInfoRemote` - a remote-linked stored procedure on the demo database.
- The GCID (Group Customer ID) is the cross-environment identity; CID is parsed from XML but not passed to the remote call.
- Failure to call the remote procedure increments @RetVal but does not prevent return (non-fatal).

### 2.2 Gender Empty-String Guard

**What**: Empty-string gender values are coerced to NULL before the demo sync call.

**Rules**:
- `IF (@gender = '') SET @gender = NULL`
- Added 08/02/2018 to handle upstream data that sent `gender=''` instead of omitting the field.
- Prevents constraint violation on the CustomerBasic table in the demo environment.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | VERIFIED | XML document containing basic user profile data. Expected structure: `<Root><gcid Value="{int}"/><cid Value="{int}"/><uName Value="{varchar(20)}"/><fName Value="{nvarchar(50)}"/><lName Value="{nvarchar(50)}"/><languageId Value="{int}"/><dob Value="{datetime}"/><gender Value="{char(1)}"/><level Value="{int}"/></Root>` |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bitmask controlling execution. 0 or bit-1 = execute Part 1 (demo sync). Follows the same pattern as all PostUpdate*/PostMIMO* procedures. |
| 3 | @ID | INT | NO | - | NAME-INFERRED | Reserved parameter - not used in the procedure body. Likely for future extension. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Demo_UpdateBasicUserInfoRemote | Caller (EXEC) | Remote procedure on demo environment that applies the profile update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer profile update pipeline | External | Caller | Called asynchronously after customer updates their basic profile in the real environment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PostUpdateBasicUserInfo (procedure)
+-- dbo.Demo_UpdateBasicUserInfoRemote (procedure) [demo environment remote call]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Demo_UpdateBasicUserInfoRemote | Procedure | EXEC - applies basic profile update in the demo environment |

### 6.2 Objects That Depend On This

No dependents found. Called by external customer profile update pipeline.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Gender empty-string guard | Data fix | `IF (@gender = '') SET @gender = NULL` - prevents constraint violation on demo CustomerBasic table (added 08/02/2018) |

---

## 8. Sample Queries

### 8.1 Execute basic user info sync for a specific customer

```sql
DECLARE @params XML = '<Root>
    <gcid Value="1983586"/>
    <cid Value="12345"/>
    <uName Value="johndoe"/>
    <fName Value="John"/>
    <lName Value="Doe"/>
    <languageId Value="1"/>
    <dob Value="1985-05-15"/>
    <gender Value="M"/>
    <level Value="2"/>
</Root>';

EXEC Customer.PostUpdateBasicUserInfo
    @Params = @params,
    @PartsToDo = 0,
    @ID = 0;
```

### 8.2 Check if @RetVal indicates success or failure

```sql
DECLARE @ret INT;
DECLARE @params XML = '<Root><gcid Value="1983586"/><fName Value="John"/><lName Value="Doe"/></Root>';

EXEC @ret = Customer.PostUpdateBasicUserInfo
    @Params = @params,
    @PartsToDo = 0,
    @ID = 0;

SELECT
    @ret AS ReturnValue,
    CASE @ret
        WHEN 0 THEN 'Success'
        WHEN -1 THEN 'XML parsing failed'
        ELSE 'Part 1 demo sync failed (count: ' + CAST(@ret AS VARCHAR) + ')'
    END AS Status;
```

### 8.3 Inspect the procedure signature for XML structure

```sql
SELECT
    OBJECT_NAME(object_id) AS ProcName,
    OBJECT_DEFINITION(object_id) AS Definition
FROM sys.objects WITH (NOLOCK)
WHERE OBJECT_NAME(object_id) = 'PostUpdateBasicUserInfo'
    AND schema_id = SCHEMA_ID('Customer')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 7.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.PostUpdateBasicUserInfo | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.PostUpdateBasicUserInfo.sql*
