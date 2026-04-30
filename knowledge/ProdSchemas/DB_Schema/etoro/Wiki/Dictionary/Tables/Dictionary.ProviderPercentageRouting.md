# Dictionary.ProviderPercentageRouting

> Configuration table defining percentage-based payment routing rules by depot and country — controlling how deposit transactions are distributed across payment providers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 PK clustered + 1 unique constraint |

---

## 1. Business Meaning

Dictionary.ProviderPercentageRouting defines rules for distributing payment transactions across different depots (payment processing configurations) based on country and transaction amount ranges. Each rule assigns a percentage of transactions to a specific depot for a given country and amount band.

This table exists because eToro routes payments through multiple providers and needs to balance transaction volume, optimize costs, and comply with regional regulations. For example, 100% of UK deposits may go to Depot 166 while 0% go to Depot 104, but US deposits may be split differently.

Currently contains 33 routing rules covering 2 primary depots (104 and 166) across multiple countries, plus depot 170 (global default), 173, 174 (multi-country), and 90. Only RoutingUser has direct permissions on this table.

---

## 2. Business Logic

### 2.1 Country-Depot Routing

**What**: Each row defines what percentage of transactions for a country+amount range go to a specific depot.

**Columns/Parameters Involved**: `DepotID`, `CountryID`, `FromAmount`, `ToAmount`, `Percentage`

**Rules**:
- Routes come in complementary pairs: if Depot 166 gets 100% for CountryID=218, then Depot 104 gets 0% for the same country.
- CountryID=0 is a wildcard (all countries not explicitly listed).
- FromAmount=0 with ToAmount=NULL means "any amount" (no amount filtering).
- Unique constraint on (DepotID, CountryID, FromAmount, ToAmount, Percentage) prevents duplicate rules.
- The default CountryID for the FK is 0 (see DEFAULT constraint).

---

## 3. Data Overview

| ID | DepotID | CountryID | FromAmount | ToAmount | Percentage | Meaning |
|---|---|---|---|---|---|---|
| 58 | 166 | 218 | 0 | NULL | 100 | 100% of US transactions routed to Depot 166 |
| 59 | 104 | 218 | 0 | NULL | 0 | 0% of US transactions to Depot 104 |
| 85 | 170 | 0 | 0 | NULL | 100 | 100% of all-country traffic to Depot 170 (global) |
| 87 | 174 | 47 | 0 | NULL | 100 | 100% of country 47 traffic to Depot 174 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing surrogate primary key. |
| 2 | DepotID | int | NO | - | VERIFIED | References a payment depot (Billing.Depot). Identifies which payment processing configuration receives the routed transactions. |
| 3 | CountryID | int | NO | 0 | VERIFIED | References Dictionary.Country. 0=global default (all countries). Specifies the customer's country for routing decisions. |
| 4 | FromAmount | money | NO | - | VERIFIED | Lower bound of the transaction amount range (inclusive). Typically 0 for "any amount". |
| 5 | ToAmount | money | YES | - | VERIFIED | Upper bound of the transaction amount range (inclusive). NULL means no upper limit. |
| 6 | Percentage | int | NO | - | VERIFIED | Percentage of matching transactions routed to this depot (0-100). Complementary rules for the same country should sum to 100. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | Relationship Type | Description |
|-------------------|---------|-------------------|-------------|
| Dictionary.Country | CountryID | Implicit | Customer's country for routing |
| Billing.Depot | DepotID | Implicit | Payment processing depot |

### 5.2 Referenced By (other objects point to this)

No direct FK consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object references Billing.Depot and Dictionary.Country implicitly.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Implicit — country for routing |
| Billing.Depot | Table | Implicit — payment depot target |

### 6.2 Objects That Depend On This

No known dependents. Managed directly via RoutingUser permissions.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryProviderPercentageRouting | CLUSTERED PK | ID ASC | - | - | Active (FF=95) |
| UNQ_ColumnsDictionaryProviderPercentageRouting | UNIQUE NONCLUSTERED | DepotID, CountryID, FromAmount, ToAmount, Percentage | - | - | Active (FF=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryProviderPercentageRouting | PRIMARY KEY | Unique row identifier |
| UNQ_ColumnsDictionaryProviderPercentageRouting | UNIQUE | Prevents duplicate routing rules |
| DF_DictionaryProviderPercentageRouting_CountryID | DEFAULT | CountryID defaults to 0 (global) |

---

## 8. Sample Queries

### 8.1 List all routing rules
```sql
SELECT  ID, DepotID, CountryID, FromAmount, ToAmount, Percentage
FROM    [Dictionary].[ProviderPercentageRouting] WITH (NOLOCK)
ORDER BY CountryID, DepotID;
```

### 8.2 Find routing rules for a specific country
```sql
SELECT  DepotID, Percentage, FromAmount, ToAmount
FROM    [Dictionary].[ProviderPercentageRouting] WITH (NOLOCK)
WHERE   CountryID = 218
ORDER BY DepotID;
```

### 8.3 Find countries with split routing
```sql
SELECT  CountryID, COUNT(DISTINCT DepotID) AS DepotCount
FROM    [Dictionary].[ProviderPercentageRouting] WITH (NOLOCK)
WHERE   Percentage > 0 AND Percentage < 100
GROUP BY CountryID
HAVING COUNT(DISTINCT DepotID) > 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ProviderPercentageRouting | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ProviderPercentageRouting.sql*
