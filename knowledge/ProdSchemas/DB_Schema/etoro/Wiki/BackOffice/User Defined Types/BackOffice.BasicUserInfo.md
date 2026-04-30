# BackOffice.BasicUserInfo

> Table-valued parameter type defining the schema for bulk updates of basic customer profile attributes (language, gender, player level) from a remote sync process.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | GCID (Group Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.BasicUserInfo` is a Table-Valued Type (TVT) that defines the schema contract for bulk updates of core customer profile attributes: language preference, gender, and player level. These are the most fundamental personalisation fields stored against a customer's live account in `Customer.Customer`.

This type exists to define the shape of data expected by the `BackOffice.Bulk_UpdateBasicUserInfoRemote` stored procedure. The "Remote" suffix indicates this procedure is called from an external or remote system (likely a synchronisation service that replicates user profile data from a source-of-truth platform). The TVT defines exactly which customer profile fields that remote system is authorised to update.

Data flows into this type from the remote system as a batch of customer profile changes. The calling process populates a temp table `#BulkUpdateBasicUserInfo` matching this type's structure, then executes the SP. Each row represents one customer whose language, gender, or player level needs to be updated. NULL values are treated as "no change" via ISNULL-guarded updates. As of February 2025, the SP no longer updates the Demo_Customer table (removed by Ran Ovadia, PAYUS pattern).

---

## 2. Business Logic

### 2.1 NULL-as-No-Op Profile Update

**What**: All profile columns are nullable, enabling partial updates per customer without a separate call per field.

**Columns/Parameters Involved**: `GCID`, `languageId`, `gender`, `level`

**Rules**:
- GCID identifies the customer group record. Joins to Customer.Customer.GCID.
- NULL in languageId = do not update language preference.
- NULL in gender = do not update gender.
- NULL in level = do not update player level.
- The SP applies: `SET LanguageID = ISNULL(BulkTable.languageId, LanguageID)` etc.
- A row with all profile columns NULL (except GCID) is valid but a no-op.

**Diagram**:
```
Remote sync sends batch:
  (GCID=100, languageId=3, gender=NULL, level=NULL)  -> update language only
  (GCID=200, languageId=NULL, gender='M', level=5)   -> update gender + level only
        |
        v
#BulkUpdateBasicUserInfo (temp table matching this type)
        |
        v
Bulk_UpdateBasicUserInfoRemote
        |
        v
UPDATE Customer.Customer
  SET LanguageID   = ISNULL(BulkTable.languageId, LanguageID)
      Gender       = ISNULL(BulkTable.gender, Gender)
      PlayerLevelID = ISNULL(BulkTable.level, PlayerLevelID)
WHERE GCID = BulkTable.GCID
```

---

## 3. Data Overview

N/A for User Defined Type. This type defines the schema for a temporary staging structure, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | CODE-BACKED | Group Customer ID - the logical row key identifying which customer to update. Joins to Customer.Customer.GCID. Should never be NULL in valid usage even though the DDL allows it. |
| 2 | languageId | int | YES | - | CODE-BACKED | Language preference ID. Maps to Customer.Customer.LanguageID. Determines the customer's preferred display language in the platform. NULL = do not update. |
| 3 | gender | char(1) | YES | - | CODE-BACKED | Customer's gender: 'M' = Male, 'F' = Female. Uses Latin1_General_BIN collation for exact matching. Maps to Customer.Customer.Gender. NULL = do not update. |
| 4 | level | int | YES | - | CODE-BACKED | Player level tier. Maps to Customer.Customer.PlayerLevelID. Represents the customer's engagement or experience level within the platform gamification system. NULL = do not update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Customer.Customer.GCID | Implicit | Identifies the target customer record for profile updates |
| languageId | Customer.Customer.LanguageID | Implicit | Language preference field mapping |
| gender | Customer.Customer.Gender | Implicit | Gender field mapping |
| level | Customer.Customer.PlayerLevelID | Implicit | Player level field mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Bulk_UpdateBasicUserInfoRemote | (temp table #BulkUpdateBasicUserInfo) | Schema contract | SP uses a temp table matching this type's structure. The comment `--@BulkUpdateTable BackOffice.RiskUserInfo READONLY` shows the TVP approach was considered but the current implementation uses a temp table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Bulk_UpdateBasicUserInfoRemote | Stored Procedure | Consumes rows matching this type's schema via temp table #BulkUpdateBasicUserInfo. Updates Customer.Customer with language, gender, and player level. As of 2025-02-12, no longer updates Demo_Customer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type. No indexes defined.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| gender COLLATE Latin1_General_BIN | Collation | Binary collation on the gender char column for exact case-sensitive matching. |

---

## 8. Sample Queries

### 8.1 Declare and populate for a language-only update

```sql
DECLARE @Updates BackOffice.BasicUserInfo;

INSERT INTO @Updates (GCID, languageId)
VALUES (12345, 3);   -- 3 = Spanish (example)

SELECT * FROM @Updates WITH (NOLOCK);
```

### 8.2 Batch update - language and gender for multiple customers

```sql
DECLARE @Updates BackOffice.BasicUserInfo;

INSERT INTO @Updates (GCID, languageId, gender, level)
VALUES
    (10001, 2, 'M', NULL),
    (10002, NULL, 'F', 3),
    (10003, 5, NULL, NULL);

SELECT * FROM @Updates WITH (NOLOCK);
```

### 8.3 Verify current customer profile values before update

```sql
SELECT
    c.GCID,
    c.LanguageID,
    c.Gender,
    c.PlayerLevelID
FROM Customer.Customer c WITH (NOLOCK)
WHERE c.GCID IN (10001, 10002, 10003);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BasicUserInfo | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.BasicUserInfo.sql*
