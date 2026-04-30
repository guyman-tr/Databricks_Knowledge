# BackOffice.Bulk_UpdateBasicUserInfoRemote

> Applies a batch of basic profile field updates to Customer.Customer from a pre-populated temp table (#BulkUpdateBasicUserInfo), using GCID-based matching and NULL-preserving updates.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | #BulkUpdateBasicUserInfo.GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of the three-procedure bulk update suite for batch customer updates. Bulk_UpdateBasicUserInfoRemote handles the basic demographic and profile fields: gender, language preference, and player level. Like its siblings (Bulk_UpdateAccountUserInfoRemote, Bulk_UpdateRiskUserInfoRemote), it reads from a pre-populated temp table, requires no parameters, and uses ISNULL-preserving updates.

The `_Remote` suffix indicates this is called from a centralized service or orchestration layer. The procedure was modified on 12/02/2025 (Ran Ovadia) to remove the corresponding Demo_Customer update, concentrating all changes on the live Customer.Customer table only.

Note: PlayerLevelID uses `[level]` in the temp table column name (level is a reserved word in SQL, hence the brackets), mapping to Customer.Customer.PlayerLevelID.

---

## 2. Business Logic

### 2.1 Basic Profile Bulk Update via GCID

**What**: Updates three demographic/profile fields in Customer.Customer for all matching GCIDs.

**Tables Involved**: `#BulkUpdateBasicUserInfo`, `Customer.Customer`

**Rules**:
- Reads from temp table `#BulkUpdateBasicUserInfo` (must exist on calling connection)
- No parameters - caller creates and populates temp table before EXEC
- Updates Customer.Customer SET Gender, LanguageID, PlayerLevelID WHERE GCID matches
- ISNULL(BulkTable.Value, CurrentValue) - NULL = preserve existing value
- Demo_Customer update was removed 12/02/2025 (previously also updated Demo_Customer with same fields)
- Returns no result set

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Temp Table Input (no parameters - reads from #BulkUpdateBasicUserInfo):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | (caller-defined) | NO | - | CODE-BACKED | Global Customer ID used to match rows in Customer.Customer. Join key. |
| 2 | gender | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.Customer.Gender. NULL = preserve existing. Customer gender identifier. |
| 3 | languageId | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.Customer.LanguageID. NULL = preserve existing. Customer's preferred language for platform UI and communications. |
| 4 | level | (caller-defined) | YES | - | CODE-BACKED | Maps to Customer.Customer.PlayerLevelID. NULL = preserve existing. Customer's player/gamification level. Column name is `[level]` in SQL (reserved word, requires brackets). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| #BulkUpdateBasicUserInfo.GCID | Customer.Customer | MODIFIER | Bulk-updates Gender, LanguageID, PlayerLevelID matched by GCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestration / sync service | #BulkUpdateBasicUserInfo temp table | Caller | Creates temp table, populates it, then calls this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Bulk_UpdateBasicUserInfoRemote (procedure)
|- #BulkUpdateBasicUserInfo (temp table) [caller must create and populate before EXEC]
+-- Customer.Customer (table) [UPDATE target - Gender, LanguageID, PlayerLevelID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| #BulkUpdateBasicUserInfo | Temp Table | Source data - must exist on calling connection |
| Customer.Customer | Table (cross-schema) | UPDATE target for basic profile fields matched by GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External bulk update service | External | Calls after populating #BulkUpdateBasicUserInfo |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No parameters | Design | Reads exclusively from temp table |
| ISNULL preserving pattern | Design | NULL in bulk table = keep existing value |
| Demo_Customer removed | Change history | As of 12/02/2025 (Ran Ovadia), the corresponding Demo_Customer update was removed - only live Customer.Customer is updated |
| Reserved word column | Design | Temp table column `[level]` requires brackets in SQL (level is a reserved keyword) |

---

## 8. Sample Queries

### 8.1 Bulk update language and player level

```sql
CREATE TABLE #BulkUpdateBasicUserInfo (
    GCID        INT,
    gender      TINYINT,
    languageId  INT,
    [level]     INT
)

INSERT INTO #BulkUpdateBasicUserInfo (GCID, languageId)
VALUES (100001, 5), (100002, 5)  -- update language only (gender and level = NULL = preserve)

EXEC BackOffice.Bulk_UpdateBasicUserInfoRemote

DROP TABLE #BulkUpdateBasicUserInfo
```

### 8.2 Verify updates

```sql
SELECT GCID, Gender, LanguageID, PlayerLevelID
FROM Customer.Customer WITH (NOLOCK)
WHERE GCID IN (100001, 100002)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Bulk_UpdateBasicUserInfoRemote | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.Bulk_UpdateBasicUserInfoRemote.sql*
