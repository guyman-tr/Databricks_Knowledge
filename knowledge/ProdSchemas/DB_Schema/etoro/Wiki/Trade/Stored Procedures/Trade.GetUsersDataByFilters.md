# Trade.GetUsersDataByFilters

> Multi-filter customer search via TVP - accepts a Trade.UsersDataFilters TVP with optional filter conditions (UserName, CID, GCID, Country, Regulation, PlayerLevel, PlayerStatus, AccountType) and returns matching customers with descriptive names resolved.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Filters TVP - Trade.UsersDataFilters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUsersDataByFilters` is a flexible customer search procedure designed for admin/tooling use cases. It accepts a table-valued parameter of type `Trade.UsersDataFilters` where each filter column is optional (NULL = no filter on that dimension). This enables a single SP to handle a variety of search queries: find by username, find all customers in a specific country with a specific regulation, find all Popular Investors, etc.

The result returns human-readable names (Country.Name, PlayerLevel.Name, etc.) rather than IDs, making it suitable for display in admin tools or reporting interfaces.

Note: The DesignatedRegulation join uses a direct INNER JOIN (not LEFT JOIN), meaning only customers with a DesignatedRegulationID set will be returned. Customers with only a base RegulationID (DesignatedRegulationID IS NULL) would be excluded. This is a potential data completeness consideration for callers.

---

## 2. Business Logic

### 2.1 TVP Filter Join (NULL = Wildcard)

**What**: Each filter column in the TVP is optional - NULL means "no filter on this dimension".

**Rules**:
- `JOIN @Filters F ON (F.UserName IS NULL OR F.UserName = cc.UserName) AND ...`
- Each condition in the JOIN uses `(F.X IS NULL OR F.X = resolvedValue)` pattern
- Multiple filter rows in the TVP create OR-like behavior (any row matching)
- This allows callers to specify 1 or many filter dimensions in a single call

### 2.2 DesignatedRegulation INNER JOIN

**What**: Only customers with a DesignatedRegulationID (non-NULL) are returned.

**Rules**:
- `JOIN Dictionary.Regulation dg ON bc.DesignatedRegulationID = dg.ID`
- INNER JOIN means customers with NULL DesignatedRegulationID are excluded
- This is unlike most other SPs in this batch which use ISNULL(DesignatedRegulationID, RegulationID)
- Callers should be aware that searches for customers by regulation may miss those with only base RegulationID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Filters | Trade.UsersDataFilters READONLY | NO | - | CODE-BACKED | TVP with optional filter columns: UserName, CID, GCID, Country, DesignatedRegulation, PlayerLevel, PlayerStatus, AccountType. NULL column = no filter. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | UserName | VARCHAR | NO | - | CODE-BACKED | Customer username. |
| 3 | GCID | INT | NO | - | CODE-BACKED | Global Customer ID. |
| 4 | CID | INT | NO | - | CODE-BACKED | Database-local Customer ID. |
| 5 | Country | VARCHAR | NO | - | CODE-BACKED | Country name from Dictionary.Country. |
| 6 | DesignatedRegulation | VARCHAR | NO | - | CODE-BACKED | Designated regulation name from Dictionary.Regulation (only customers with non-NULL DesignatedRegulationID are returned). |
| 7 | PlayerLevel | VARCHAR | NO | - | CODE-BACKED | Player level name from Dictionary.PlayerLevel. |
| 8 | PlayerStatus | VARCHAR | NO | - | CODE-BACKED | Player status name from Dictionary.PlayerStatus. |
| 9 | AccountType | VARCHAR | NO | - | CODE-BACKED | Account type name from Dictionary.AccountType. |
| 10 | Registered | DATETIME | NO | - | CODE-BACKED | Customer registration date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TVP | Trade.UsersDataFilters | User Defined Type | Input filter TVP |
| FROM | Customer.Customer | FROM | Primary customer data |
| JOIN | BackOffice.Customer | INNER JOIN | AccountTypeID, DesignatedRegulationID |
| JOIN | Dictionary.PlayerLevel | INNER JOIN | PlayerLevel name |
| JOIN | Dictionary.AccountType | INNER JOIN | AccountType name |
| JOIN | Dictionary.Country | INNER JOIN | Country name |
| JOIN | Dictionary.Regulation | INNER JOIN | DesignatedRegulation name |
| JOIN | Dictionary.PlayerStatus | INNER JOIN | PlayerStatus name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (admin/reporting tools) | @Filters TVP | EXEC caller | Customer search with multi-dimensional filtering |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUsersDataByFilters (procedure)
+-- Trade.UsersDataFilters (UDT - TVP type)
+-- Customer.Customer (table)
+-- BackOffice.Customer (table)
+-- Dictionary.PlayerLevel (table)
+-- Dictionary.AccountType (table)
+-- Dictionary.Country (table)
+-- Dictionary.Regulation (table) [DesignatedRegulationID]
+-- Dictionary.PlayerStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.UsersDataFilters | User Defined Type | Input filter TVP type |
| Customer.Customer | Table | UserName, GCID, CID, CountryID, PlayerLevelID, PlayerStatusID, Registered |
| BackOffice.Customer | Table | AccountTypeID, DesignatedRegulationID |
| Dictionary.PlayerLevel | Table | PlayerLevel name |
| Dictionary.AccountType | Table | AccountType name |
| Dictionary.Country | Table | Country name |
| Dictionary.Regulation | Table | DesignatedRegulation name |
| Dictionary.PlayerStatus | Table | PlayerStatus name |

### 6.2 Objects That Depend On This

No documented dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Isolation | All table reads use dirty read |
| INNER JOIN @Filters | Filter pattern | NULL column in TVP acts as wildcard |
| INNER JOIN on DesignatedRegulationID | Data limitation | Excludes customers without a DesignatedRegulationID set |

---

## 8. Sample Queries

### 8.1 Search by country and player level
```sql
DECLARE @filters Trade.UsersDataFilters;
INSERT INTO @filters (Country, PlayerLevel) VALUES ('United Kingdom', 'Popular Investor');
EXEC Trade.GetUsersDataByFilters @Filters = @filters;
```

### 8.2 Search by CID
```sql
DECLARE @filters Trade.UsersDataFilters;
INSERT INTO @filters (CID) VALUES (123456);
EXEC Trade.GetUsersDataByFilters @Filters = @filters;
```

### 8.3 N/A - third query not applicable

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Admin/reporting search procedure not documented in TRAD/DB Confluence.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUsersDataByFilters | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUsersDataByFilters.sql*
