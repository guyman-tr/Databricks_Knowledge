# History.PostLogIn

> Decommissioned async post-login step (StepID=3) - all logic was commented out in 2016 when the Internal.CIDToMail insert was removed. The procedure accepts the standard async framework parameters (@Params XML, @PartsToDo, @ID) but performs no operations and always returns 0.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A - all body logic is commented out; procedure is a no-op |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PostLogIn` is registered as **StepID=3** in `Dictionary.Steps` ("After user login"), meaning it is enqueued in `Internal.ActionSteps` by the login path and called asynchronously by `Internal.AsyncExecuter{N}` after a user login.

**However, the procedure is effectively decommissioned.** A block comment dated **2016-03-07** with the note *"We Remove Insert into Internal.CIDToMail"* wraps the entire original logic, which is no longer executed. The procedure now only declares variables and returns 0.

**Original intent (pre-2016)**: After login, if the customer's CID met certain criteria (based on IsRealDB flag from Maintenance.Feature FeatureID=22), a row was inserted into `Internal.CIDToMail` to trigger a marketing email suggesting the customer start copying Popular Investors. This was a "first position suggestion" email mechanism.

**Current behavior**: The procedure accepts the standard async step signature (@Params, @PartsToDo, @ID), does nothing, and returns 0. It remains in the schema and registered in Dictionary.Steps but has no functional effect.

---

## 2. Business Logic

### 2.1 Decommissioned Logic (Reference Only)

**What**: The commented-out body inserted into Internal.CIDToMail to queue a marketing email after login.

**Status**: DISABLED since 2016-03-07.

**Rules** (commented out, no longer active):
- Parsed @CID from @Params XML: `@Params.value('(Root/CID/@Value)[1]','INT')`
- Read IsRealDB from Maintenance.Feature FeatureID=22 (0=Demo, 1=Real)
- Inserted into Internal.CIDToMail with GCID/RealCID/DemoCID routing:
  - Real environment (IsRealDB=1): RealCID = CID (if GCID=0) or 0 (if GCID<>0)
  - Demo environment (IsRealDB=0): DemoCID = CID (if GCID=0) or 0 (if GCID<>0)
- ImmediateSend=0, Status=0 on insert
- Errors were caught and @RetVal incremented by 1

### 2.2 Current Behavior

The procedure is a complete no-op:
```sql
SET @RetVal = 0
/* ... all logic commented out ... */
RETURN @RetVal  -- always returns 0
```

---

## 3. Data Overview

N/A for Stored Procedure. No data is read or written by this procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Params | XML | NO | - | CODE-BACKED | XML payload from the async framework. Declared but unused (body is commented out). Previously would have contained `<Root><CID Value="..."/></Root>`. |
| 2 | @PartsToDo | INT | NO | - | CODE-BACKED | Async framework bitmask. Declared but unused. Standard interface parameter for all Dictionary.Steps procedures. |
| 3 | @ID | INT | NO | - | CODE-BACKED | Action record ID from Internal.ActionSteps. Declared but unused. Standard interface parameter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No active references. All reference logic is in commented-out code.

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (commented out) Internal.CIDToMail | Internal.CIDToMail | INSERT (DISABLED) | Was: inserted post-login marketing email trigger records. Removed 2016-03-07. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.AsyncExecuter{N} | Dictionary.Steps StepID=3 | Calls (EXEC) | Called asynchronously after login events; procedure is a no-op but still registered |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PostLogIn (procedure, StepID=3)
+-- (no active dependencies - all logic commented out)
    (called by Internal.AsyncExecuter{N} via Dictionary.Steps StepID=3)
```

### 6.1 Objects This Depends On

No active dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.AsyncExecuter{N} | Procedure family | Calls this procedure as StepID=3 post-login handler; currently a no-op |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| All logic commented out | Decommissioned | Block comment dated 2016-03-07 disables all operational code |
| Always returns 0 | Behavior | No error path active; always succeeds with return code 0 |
| Still registered StepID=3 | Framework note | Still in Dictionary.Steps and called by async framework; framework call is harmless (no-op) |

---

## 8. Sample Queries

### 8.1 Confirm the procedure has no active logic

```sql
-- Verify Dictionary.Steps registration
SELECT StepID, ProcName
FROM Dictionary.Steps WITH (NOLOCK)
WHERE StepID = 3
-- Returns: 3, History.PostLogIn
```

### 8.2 Check how often this step is queued

```sql
SELECT COUNT(*) AS PostLoginActions
FROM Internal.ActionSteps WITH (NOLOCK)
WHERE StepID = 3
  AND IsProcessed = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PostLogIn | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.PostLogIn.sql*
