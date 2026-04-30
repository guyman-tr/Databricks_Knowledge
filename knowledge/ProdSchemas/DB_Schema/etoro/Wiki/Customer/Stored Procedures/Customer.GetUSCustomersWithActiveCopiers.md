# Customer.GetUSCustomersWithActiveCopiers

> Returns the distinct CID and UserName of customers from a given country who are active Popular Investors (CopyTrader leaders) with at least one copier currently holding an open position.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CountryID -> DISTINCT CID, UserName from Customer.CustomerStatic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUSCustomersWithActiveCopiers identifies customers from a specified country who are currently serving as Popular Investors (CopyTrader leaders) with active copier positions. The name implies its original use case: finding US-based leaders with active copiers for regulatory/compliance checks - but the @CountryID parameter makes it usable for any country.

The procedure determines "active leader with copiers" by chaining three conditions: the customer is registered in the target country (Customer.CustomerStatic.CountryID = @CountryID), they have at least one active mirror relationship (Trade.Mirror.IsActive = 1 where they are the parent/leader), and those mirrors contain at least one open copier position (JOIN to Trade.Position on MirrorID). The DISTINCT eliminates duplicates when a leader has multiple mirrors or positions.

Data flows: Customer.CustomerStatic is the master record source. Trade.Mirror holds the copy trading relationship (ParentCID = leader's CID). Trade.Position holds the positions opened by copiers within each mirror. This procedure is a read-only snapshot query; StatsWatcherServiceUser has EXECUTE permission, indicating it is called by the StatsWatcher compliance monitoring service.

---

## 2. Business Logic

### 2.1 Active Leader Identification via Cross-Schema JOIN

**What**: A three-way JOIN determines which country-filtered customers qualify as "Popular Investors with active copiers."

**Columns/Parameters Involved**: `@CountryID`, `Customer.CustomerStatic.CountryID`, `Trade.Mirror.ParentCID`, `Trade.Mirror.IsActive`, `Trade.Position.MirrorID`

**Rules**:
- Customer.CustomerStatic is filtered by CountryID = @CountryID (e.g., US CountryID)
- Trade.Mirror.ParentCID = C.CID links the customer to mirrors where THEY are the leader (parent), not a copier (child)
- Trade.Mirror.IsActive = 1 filters to currently active mirror relationships (inactive/stopped mirrors are excluded)
- JOIN to Trade.Position ON M.MirrorID = P.MirrorID ensures the mirror has at least one open position (a copier has capital deployed)
- DISTINCT on CID, UserName: a leader may have multiple active mirrors and many copier positions - one row per leader is returned

**Diagram**:
```
Customer.CustomerStatic (CountryID=@CountryID)
  C.CID = M.ParentCID (leader role)
         |
  Trade.Mirror (IsActive=1)
  M.MirrorID = P.MirrorID (has open copier positions)
         |
  Trade.Position
         |
  Result: DISTINCT leaders from that country with active copiers
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | int | NO | - | CODE-BACKED | ID of the country to filter by, matching Customer.CustomerStatic.CountryID. Originally intended for the US CountryID but parameterized to support any country. Used by StatsWatcher for per-country regulatory compliance checks on active Popular Investors. See Dictionary.Country for the full country ID mapping. |

**Output columns** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID from Customer.CustomerStatic - the unique identifier of the Popular Investor (leader). Each returned CID represents a distinct leader from the target country who currently has active copiers following them. |
| 2 | UserName | varchar | NO | - | VERIFIED | Public username of the Popular Investor from Customer.CustomerStatic. Returned to allow the StatsWatcher service or compliance teams to identify the customer by their platform handle without needing a secondary lookup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CountryID | Customer.CustomerStatic.CountryID | Reader (WHERE filter) | Filters the customer master record to the target country |
| C.CID = M.ParentCID | Trade.Mirror | Reader (JOIN) | Identifies the customer as a CopyTrader leader (parent in mirror relationship) |
| M.MirrorID = P.MirrorID | Trade.Position | Reader (JOIN) | Ensures the leader has at least one copier with an open position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| StatsWatcherServiceUser | EXECUTE permission | Caller | StatsWatcher compliance monitoring service calls this procedure for country-specific Popular Investor checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUSCustomersWithActiveCopiers (procedure)
├── Customer.CustomerStatic (table)
├── Trade.Mirror (table)
└── Trade.Position (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Primary source - filtered by CountryID, provides CID and UserName |
| Trade.Mirror | Table | INNER JOIN on ParentCID - identifies leader mirror relationships; filtered to IsActive=1 |
| Trade.Position | Table | INNER JOIN on MirrorID - ensures mirror has at least one open copier position |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| StatsWatcherServiceUser | Service account | Calls this procedure for compliance monitoring of active Popular Investors by country |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get US-based Popular Investors with active copiers
```sql
-- Pass the US CountryID (check Dictionary.Country for the value)
EXEC Customer.GetUSCustomersWithActiveCopiers @CountryID = 250; -- example value
```

### 8.2 Get UK-based Popular Investors with active copiers
```sql
EXEC Customer.GetUSCustomersWithActiveCopiers @CountryID = 235; -- example UK value
```

### 8.3 Direct equivalent query for debugging
```sql
SELECT DISTINCT
    C.CID,
    C.UserName
FROM Customer.CustomerStatic C WITH (NOLOCK)
INNER JOIN Trade.Mirror M WITH (NOLOCK) ON C.CID = M.ParentCID
INNER JOIN Trade.Position P WITH (NOLOCK) ON M.MirrorID = P.MirrorID
WHERE C.CountryID = 250  -- target country
  AND M.IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetUSCustomersWithActiveCopiers | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetUSCustomersWithActiveCopiers.sql*
