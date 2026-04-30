# Trade.UsersDataFilters

> TVP for filtering user/customer data by username, CID, country, regulation, player level, status, and account type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | UserName (varchar), GCID (int), CID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

UsersDataFilters carries filter criteria for user/customer data queries. Each row represents a set of optional filters: UserName, GCID, CID, Country, DesignatedRegulation, PlayerLevel, PlayerStatus, AccountType. Callers pass one or more filter rows to Trade.GetUsersDataByFilters to retrieve filtered user data.

This type exists to support flexible multi-criteria filtering of user data without dynamic SQL. Reporting and admin tools pass filter combinations as a TVP.

The type flows from reporting or admin services into Trade.GetUsersDataByFilters. The procedure applies the filters (AND/OR logic) to return matching user records.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Each column is an optional filter criterion; multiple rows may represent OR logic depending on procedure implementation.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserName | varchar(20) | YES | - | CODE-BACKED | Username filter |
| 2 | GCID | int | YES | - | CODE-BACKED | Global/gateway customer ID filter |
| 3 | CID | int | YES | - | CODE-BACKED | Customer ID filter |
| 4 | Country | varchar(50) | YES | - | CODE-BACKED | Country filter |
| 5 | DesignatedRegulation | varchar(50) | YES | - | CODE-BACKED | Regulatory jurisdiction filter |
| 6 | PlayerLevel | varchar(50) | YES | - | CODE-BACKED | Player/tier level filter |
| 7 | PlayerStatus | varchar(50) | YES | - | CODE-BACKED | Player status filter |
| 8 | AccountType | varchar(50) | YES | - | CODE-BACKED | Account type filter |

---

## 5. Relationships

### 5.1 References To (this object points to)

GCID, CID semantically reference Customer tables; Country, DesignatedRegulation, PlayerLevel, PlayerStatus, AccountType reference domain lookup values.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetUsersDataByFilters | @Filters | Parameter (TVP) | Retrieves user data filtered by the criteria |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUsersDataByFilters | Stored Procedure | READONLY parameter for filtered user data retrieval |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Filter by country and regulation
```sql
DECLARE @Filters Trade.UsersDataFilters;
INSERT INTO @Filters (UserName, GCID, CID, Country, DesignatedRegulation, PlayerLevel, PlayerStatus, AccountType)
VALUES (NULL, NULL, NULL, 'US', 'SEC', NULL, NULL, NULL);
EXEC Trade.GetUsersDataByFilters @Filters = @Filters;
```

### 8.2 Filter by specific user
```sql
DECLARE @Filters Trade.UsersDataFilters;
INSERT INTO @Filters (UserName, GCID, CID, Country, DesignatedRegulation, PlayerLevel, PlayerStatus, AccountType)
VALUES ('john.doe', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
EXEC Trade.GetUsersDataByFilters @Filters = @Filters;
```

### 8.3 Multiple filter rows (OR logic)
```sql
DECLARE @Filters Trade.UsersDataFilters;
INSERT INTO @Filters (UserName, GCID, CID, Country, DesignatedRegulation, PlayerLevel, PlayerStatus, AccountType)
VALUES (NULL, NULL, 100, NULL, NULL, NULL, NULL, NULL),
       (NULL, NULL, 101, NULL, NULL, NULL, NULL, NULL);
EXEC Trade.GetUsersDataByFilters @Filters = @Filters;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.3/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UsersDataFilters | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.UsersDataFilters.sql*
