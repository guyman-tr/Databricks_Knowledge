# BackOffice.PlayerLevels

> Single-column table-valued parameter type for passing a set of player level (Club Group) IDs as a filter list to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | PlayerLevelID (nullable - no PK constraint) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.PlayerLevels` is a single-column Table-Valued Type (TVT) that holds a set of `PlayerLevelID` values for use as a multi-value filter in BackOffice stored procedures. It allows callers to pass a list of player level (eToro Club Group) identifiers in a single READONLY parameter, enabling queries scoped to specific tiers of the eToro loyalty/club programme.

This type exists to support tier-based reporting and customer segmentation in the back-office. A manager or analyst can specify which Club Group tiers (e.g., Silver, Gold, Platinum, Diamond) they want to view, and the procedure filters accordingly. Without this TVT, tier filtering would require dynamic SQL or string manipulation.

Data flows into this type from the back-office portal or CRM. The caller inserts the desired player level IDs and passes the list to `BackOffice.GetMyCustomers`, which filters `Customer.Customer.PlayerLevelID IN (SELECT PlayerLevelID FROM @PlayerLevelIds)`.

---

## 2. Business Logic

### 2.1 Club Group (Player Level) Tier Filtering

**What**: Scopes a customer query to specific eToro Club Group tiers, enabling managers to work with specific customer segments.

**Columns/Parameters Involved**: `PlayerLevelID`

**Rules**:
- `PlayerLevelID` maps to `Customer.Customer.PlayerLevelID` and `Dictionary.PlayerLevel.PlayerLevelID`.
- An empty table (no rows) results in no customers being returned (IN clause with empty subquery returns no matches).
- No uniqueness constraint - duplicate PlayerLevelIDs are silently harmless (IN subquery deduplicates naturally).
- Nullable in DDL but NULL values would match customers with PlayerLevelID IS NULL depending on SP implementation.

**Diagram**:
```
Caller passes @levelIds AS BackOffice.PlayerLevels:
  [(PlayerLevelID=3),  <- Gold
   (PlayerLevelID=4)]  <- Platinum
         |
         v
BackOffice.GetMyCustomers
  WHERE CC.PlayerLevelID IN (SELECT PlayerLevelID FROM @PlayerLevelIds)
         |
         v
  Returns only Gold and Platinum customers for the specified managers
```

---

## 3. Data Overview

N/A for User Defined Type. This is a transient parameter container, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerLevelID | int | YES | - | CODE-BACKED | eToro Club Group tier identifier. References Dictionary.PlayerLevel.PlayerLevelID and Customer.Customer.PlayerLevelID. Identifies which loyalty tier customers should be included in the result set. Examples: Silver, Gold, Platinum, Diamond (exact values defined in Dictionary.PlayerLevel). Nullable in DDL but expected to be non-NULL in valid usage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerLevelID | Dictionary.PlayerLevel.PlayerLevelID | Implicit | Identifies the Club Group tier to filter on |
| PlayerLevelID | Customer.Customer.PlayerLevelID | Implicit | Used in IN-filter against the customer table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetMyCustomers | @PlayerLevelIds parameter | Schema contract | Filters Customer.Customer.PlayerLevelID using IN subquery on this TVT |

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
| BackOffice.GetMyCustomers | Stored Procedure | READONLY parameter @PlayerLevelIds - used in WHERE CC.PlayerLevelID IN (SELECT PlayerLevelID FROM @PlayerLevelIds) to scope the result set to specific Club Group tiers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. PlayerLevelID is nullable with no uniqueness enforcement.

---

## 8. Sample Queries

### 8.1 Get customers at Gold and Platinum levels for a manager

```sql
DECLARE @managers BackOffice.Managers;
DECLARE @levels BackOffice.PlayerLevels;

INSERT INTO @managers VALUES (101);
INSERT INTO @levels VALUES (3), (4); -- Gold=3, Platinum=4

EXEC BackOffice.GetMyCustomers
    @ManagerIds = @managers,
    @RegisteredFrom = '2024-01-01',
    @RegisteredTo = '2026-03-17',
    @PlayerLevelIds = @levels;
```

### 8.2 Get all Club Group levels (no tier filtering)

```sql
DECLARE @levels BackOffice.PlayerLevels;
DECLARE @managers BackOffice.Managers;

-- Insert all existing level IDs
INSERT INTO @levels
SELECT PlayerLevelID FROM Dictionary.PlayerLevel WITH (NOLOCK);

INSERT INTO @managers VALUES (101);

EXEC BackOffice.GetMyCustomers
    @ManagerIds = @managers,
    @RegisteredFrom = '2026-01-01',
    @RegisteredTo = '2026-03-17',
    @PlayerLevelIds = @levels;
```

### 8.3 Inspect player level names before filtering

```sql
DECLARE @levels BackOffice.PlayerLevels;

INSERT INTO @levels VALUES (1), (2), (3), (4);

SELECT l.PlayerLevelID, pl.Name AS LevelName
FROM @levels l WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK)
    ON pl.PlayerLevelID = l.PlayerLevelID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.PlayerLevels | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.PlayerLevels.sql*
