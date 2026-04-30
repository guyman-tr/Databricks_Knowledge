# Trade.GetUserData

> Flexible single-customer lookup returning identity, country, account type, trading risk status, player level, and regulation data - accepts GCID, CID, or UserName as alternative lookup keys.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID OR @CID OR @UserName - at least one required |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserData` is a general-purpose customer profile lookup used in contexts where only one of GCID, CID, or UserName is known. It returns a single row (TOP 1 with priority ordering) combining data from Customer.CustomerStatic, BackOffice.Customer, and several Dictionary tables - providing a complete operational snapshot: who the user is, their country, account type, trading risk classification, player level, and effective regulation.

The procedure was introduced as part of TRADEA-387 (trade server detachment changes), reflecting a migration to the Customer.CustomerStatic view instead of Customer.Customer. This SP bridges the identity gap when callers have only one identifier - for example, a trade desk operator who knows only a username, or an API call that arrives with a GCID.

The priority ordering in ORDER BY ensures that if multiple rows match (rare but possible with loose OR conditions), the most specific match is returned: GCID match (score 10) > CID match (score 4) > UserName match (score 1).

---

## 2. Business Logic

### 2.1 At-Least-One-Parameter Validation

**What**: At least one of the three lookup parameters must be non-NULL; all-NULL is an error.

**Rules**:
- If `@GCID IS NULL AND @CID IS NULL AND @UserName IS NULL` -> RAISERROR severity 16, state 1
- Message: 'All parameters were null. At least one of them should have a value'
- The procedure returns immediately after the error

### 2.2 Multi-Key Lookup with OR Conditions

**What**: The WHERE clause uses OR to match against whichever parameter is provided.

**Rules**:
- `(@GCID > 0) AND (cc.GCID = @GCID)` - GCID match (> 0 guards against 0/negative)
- `(@CID > 0) AND (cc.CID = @CID)` - CID match
- `(ISNULL(@UserName,'') <> '') AND (UserName_LOWER = lower(@UserName))` - case-insensitive username match via `UserName_LOWER` computed/indexed column
- Multiple conditions can fire simultaneously if, e.g., both @GCID and @CID are provided

### 2.3 Priority Ordering for Deterministic TOP 1

**What**: ORDER BY scores the match type to ensure the most specific/reliable identifier wins.

**Rules**:
- GCID match = score 10 (highest priority - global identifier)
- CID match = score 4
- UserName match = score 1 (lowest priority - username can change)
- `TOP 1 ... ORDER BY ... DESC` returns the highest-scoring match
- If no conditions score (i.e., all params were provided but none matched), returns no row

### 2.4 Designated Regulation Override

**What**: Returns both base regulation and designated regulation separately.

**Rules**:
- `reg.Name AS Regulation`: from `BackOffice.Customer.RegulationID` -> `Dictionary.Regulation`
- `ISNULL(dreg.Name,'') AS DesignatedRegulation`: from `BackOffice.Customer.DesignatedRegulationID` -> `Dictionary.Regulation` (LEFT JOIN, so empty string when not set)
- The effective regulation for business purposes is DesignatedRegulation when non-empty, otherwise Regulation (the ISNULL pattern used elsewhere in the schema)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | YES | NULL | CODE-BACKED | Global Customer ID. If provided (> 0), used as primary lookup key. Highest-priority match (score 10). |
| 2 | @CID | INT | YES | NULL | CODE-BACKED | Customer ID (database-local). Secondary lookup key (score 4). |
| 3 | @UserName | VARCHAR(20) | YES | NULL | CODE-BACKED | Username string. Matched case-insensitively against UserName_LOWER. Lowest priority (score 1). |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | GCID | INT | NO | - | CODE-BACKED | Global Customer ID from Customer.CustomerStatic. |
| 5 | CID | INT | NO | - | CODE-BACKED | Database-local Customer ID. |
| 6 | UserName | VARCHAR | NO | - | CODE-BACKED | Customer's username. |
| 7 | Country | VARCHAR | NO | - | CODE-BACKED | Country name from Dictionary.Country.Name. |
| 8 | AccountType | VARCHAR | NO | - | CODE-BACKED | Account type name from Dictionary.AccountType.AccountTypeName. |
| 9 | Registered | DATETIME | NO | - | CODE-BACKED | Customer registration date from Customer.CustomerStatic. |
| 10 | CountryID | INT | NO | - | CODE-BACKED | Country ID from Dictionary.Country. FK to Dictionary.Country. |
| 11 | AccountTypeID | INT | NO | - | CODE-BACKED | Account type ID from BackOffice.Customer. Used to determine trading capabilities. |
| 12 | TradingRiskStatusID | INT | NO | - | CODE-BACKED | Current trading risk classification ID from BackOffice.Customer. FK to Dictionary.TradingRiskStatus. |
| 13 | TradingRiskStatus | VARCHAR | NO | - | CODE-BACKED | Trading risk status name from Dictionary.TradingRiskStatus. |
| 14 | PlayerLevel | VARCHAR | NO | - | CODE-BACKED | Player level name from Dictionary.PlayerLevel.Name (e.g., "Regular", "Popular Investor"). |
| 15 | PlayerLevelID | INT | NO | - | CODE-BACKED | Player level ID from Customer.CustomerStatic. FK to Dictionary.PlayerLevel. |
| 16 | Regulation | VARCHAR | NO | - | CODE-BACKED | Base regulation name from Dictionary.Regulation (via BackOffice.Customer.RegulationID). |
| 17 | DesignatedRegulation | VARCHAR | NO | '' | CODE-BACKED | Override regulation name (ISNULL to '' when not set). Overrides base Regulation when non-empty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Customer.CustomerStatic | FROM | Primary customer identity source (GCID, CID, UserName, CountryID, Registered, PlayerLevelID) |
| JOIN | Dictionary.Country | INNER JOIN | Country name and ID lookup |
| JOIN | BackOffice.Customer | INNER JOIN | AccountTypeID, TradingRiskStatusID, RegulationID, DesignatedRegulationID |
| JOIN | Dictionary.AccountType | INNER JOIN | AccountTypeName lookup |
| JOIN | Dictionary.TradingRiskStatus | INNER JOIN | TradingRiskStatus name lookup |
| JOIN | Dictionary.PlayerLevel | INNER JOIN | PlayerLevel name lookup |
| JOIN (base) | Dictionary.Regulation | INNER JOIN | Base regulation name (RegulationID) |
| JOIN (designated) | Dictionary.Regulation | LEFT JOIN | Override regulation name (DesignatedRegulationID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (trade desk / admin tools) | @GCID, @CID, @UserName | EXEC caller | Customer profile lookup during trade operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserData (procedure)
+-- Customer.CustomerStatic (view/table)
+-- Dictionary.Country (table)
+-- BackOffice.Customer (table)
+-- Dictionary.AccountType (table)
+-- Dictionary.TradingRiskStatus (table)
+-- Dictionary.PlayerLevel (table)
+-- Dictionary.Regulation (table) [x2: base + designated]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | View/Table | Primary identity source (GCID/CID/UserName/CountryID/Registered/PlayerLevelID) |
| Dictionary.Country | Table | Country name resolution |
| BackOffice.Customer | Table | AccountTypeID, TradingRiskStatusID, RegulationID, DesignatedRegulationID |
| Dictionary.AccountType | Table | Account type name |
| Dictionary.TradingRiskStatus | Table | Risk status name |
| Dictionary.PlayerLevel | Table | Player level name |
| Dictionary.Regulation | Table | Regulation name (joined twice: base and designated) |

### 6.2 Objects That Depend On This

No documented dependents. General-purpose lookup called by external tools and services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| All-NULL guard | Business rule | RAISERROR if all three params are NULL - prevents unbounded scan |
| TOP 1 + ORDER BY priority | Result limit | Returns at most one row; priority: GCID > CID > UserName |
| UserName_LOWER = lower(@UserName) | Case insensitive | Matches against lowercase computed column for index use |
| WITH (NOLOCK) | Isolation | Applied to Customer.CustomerStatic and Dictionary.Country (soft reads) |

---

## 8. Sample Queries

### 8.1 Lookup by GCID (primary key)
```sql
EXEC Trade.GetUserData @GCID = 12345678
```

### 8.2 Lookup by CID
```sql
EXEC Trade.GetUserData @CID = 987654
```

### 8.3 Lookup by username
```sql
EXEC Trade.GetUserData @UserName = 'johndoe'
```

---

## 9. Atlassian Knowledge Sources

**Jira**: TRADEA-387 (referenced in DDL comment) - "DB_DetachTradeServerChanges". The procedure was created/modified as part of trade server detachment work, which involved migrating from Customer.Customer to Customer.CustomerStatic as the lookup source.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Jira (TRADEA-387) + 0 Confluence | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserData.sql*
