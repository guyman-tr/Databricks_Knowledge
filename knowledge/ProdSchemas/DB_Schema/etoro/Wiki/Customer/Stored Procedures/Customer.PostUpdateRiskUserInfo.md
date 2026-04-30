# Customer.PostUpdateRiskUserInfo

> XML-dispatched post-update bridge that propagates regulatory risk profile changes (DesignatedRegulationID, RegulationID) to the demo environment via dbo.Demo_UpdateRiskUserInfoRemote.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Params XML (contains GCID, DesignatedRegulationID, RegulationID); returns @RetVal INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

eToro customers are subject to different regulatory regimes depending on their country of residence and account type (e.g., ESMA-regulated EU, FCA-regulated UK, ASIC-regulated Australia). When a customer's regulatory classification changes in the real environment - for example, when they re-register under a different regulation, or their account is migrated - the demo environment must be updated to match. `PostUpdateRiskUserInfo` is the synchronization bridge for this risk/regulatory data.

The procedure is the most focused of the three PostUpdate* procs: it parses only three fields from the XML (GCID, DesignatedRegulationID, RegulationID), then calls `dbo.Demo_UpdateRiskUserInfoRemote` on the demo environment. Like its sibling procedures, it writes nothing to Customer schema tables directly.

---

## 2. Business Logic

### 2.1 Regulatory Profile Synchronization

**What**: Propagates regulation IDs from real to demo environment.

**Columns/Parameters Involved**: `@GCID`, `@DesignatedRegulationID`, `@RegulationID`

**Rules**:
- `@DesignatedRegulationID`: The regulatory framework the customer is designated to (planned/target regulation).
- `@RegulationID`: The customer's current active regulation.
- Both are nullable integers matching regulation lookup tables.
- Calls `dbo.Demo_UpdateRiskUserInfoRemote @GCID, @DesignatedRegulationID, @RegulationID`.
- @PartsToDo bitmask: 0 or bit-1 = execute. Standard PostUpdate* pattern.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | VERIFIED | XML document. Expected nodes: `<Root><gcid Value="{int}"/><designatedRegulationID Value="{int}"/><regulationID Value="{int}"/></Root>` |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Bitmask: 0 or bit-1 = execute demo sync. Standard PostUpdate* pattern. |
| 3 | @ID | INT | NO | - | NAME-INFERRED | Reserved - not used in body. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | dbo.Demo_UpdateRiskUserInfoRemote | Caller (EXEC) | Remote call to demo environment for regulatory profile update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer regulatory update pipeline | External | Caller | Called asynchronously after regulatory classification changes in real environment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PostUpdateRiskUserInfo (procedure)
+-- dbo.Demo_UpdateRiskUserInfoRemote (procedure) [demo environment remote call]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Demo_UpdateRiskUserInfoRemote | Procedure | EXEC - applies regulatory profile update in the demo environment |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None beyond standard error handling.

---

## 8. Sample Queries

### 8.1 Execute risk/regulatory info sync for a specific customer

```sql
DECLARE @params XML = '<Root>
    <gcid Value="1983586"/>
    <designatedRegulationID Value="3"/>
    <regulationID Value="2"/>
</Root>';

EXEC Customer.PostUpdateRiskUserInfo
    @Params = @params,
    @PartsToDo = 0,
    @ID = 0;
```

### 8.2 Compare all three PostUpdate demo-sync procedures

```sql
SELECT
    OBJECT_NAME(o.object_id) AS ProcName,
    o.create_date,
    o.modify_date,
    (SELECT COUNT(*) FROM sys.parameters p WHERE p.object_id = o.object_id) AS ParameterCount
FROM sys.objects o WITH (NOLOCK)
WHERE o.schema_id = SCHEMA_ID('Customer')
    AND OBJECT_NAME(o.object_id) IN (
        'PostUpdateBasicUserInfo',
        'PostUpdateContactUserInfo',
        'PostUpdateRiskUserInfo'
    )
ORDER BY OBJECT_NAME(o.object_id)
```

### 8.3 Verify the GCID being synced exists in CustomerStatic

```sql
DECLARE @gcid INT = 1983586;
SELECT
    cs.GCID,
    cs.CID,
    cs.UserName,
    cs.CountryID
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.GCID = @gcid
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 7.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.PostUpdateRiskUserInfo | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.PostUpdateRiskUserInfo.sql*
