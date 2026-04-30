# Billing.GetUserCountryRisk

> Returns a customer's country-based risk group IDs (from both declared and IP-detected countries) plus their all-time total deposits and compensation: used by the billing service for risk-based payment routing and limit decisions.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID; returns one row with riskGroupByCountryByIP, riskGroupByCountryID, TotalDepositAndCompensation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetUserCountryRisk assembles the three key risk inputs for a customer needed by billing payment routing logic:

1. **riskGroupByCountryByIP**: Risk group assigned to the country detected from the customer's IP at registration - reflects where the customer actually is
2. **riskGroupByCountryID**: Risk group assigned to the customer's declared country - reflects where the customer says they are
3. **TotalDepositAndCompensation**: The customer's all-time total deposits plus compensation (from BackOffice.CustomerAllTimeAggregatedData) - reflects their financial engagement level

The two risk groups allow billing logic to consider both declared and geo-detected country risk. Discrepancies between the two may indicate country of residence misrepresentation, which is itself a risk signal. The aggregate deposit amount adds a financial dimension to the risk profile.

Modified 09 Nov 2017 (Geri Reshef, ticket 49466 - "Adding missing NoLock").

Referenced in "Billing Service Database Readonly Separation" (Confluence MG space) - part of the read-only billing service query layer.

---

## 2. Business Logic

### 2.1 Dual Country Risk Group Lookup

**What**: Resolves RiskGroupID from Dictionary.Country for both the customer's declared country and IP-detected country.

**Columns/Parameters Involved**: `Customer.Customer.CountryID`, `Customer.Customer.CountryIDByIP`, `Dictionary.Country.RiskGroupID`

**Rules**:
- LEFT JOIN `Dictionary.Country` (aliased `bcid`) on `cc.CountryID = bcid.CountryID` -> `bcid.RiskGroupID` AS `riskGroupByCountryID`
- LEFT JOIN `Dictionary.Country` (aliased `bcip`) on `cc.CountryIDByIP = bcip.CountryID` -> `bcip.RiskGroupID` AS `riskGroupByCountryByIP`
- Both are LEFT JOINs - returns NULL if country is not set or not found in Dictionary.Country
- Dictionary.Country.RiskGroupID maps each country to a risk tier (e.g., 1=Low, 2=Medium, 3=High)

### 2.2 All-Time Deposit + Compensation Aggregation

**What**: Returns the customer's total financial value (deposits + compensations) from the pre-aggregated BackOffice table.

**Columns/Parameters Involved**: `BackOffice.CustomerAllTimeAggregatedData.TotalDeposit`, `BackOffice.CustomerAllTimeAggregatedData.TotalCompensation`

**Rules**:
- LEFT JOIN `BackOffice.CustomerAllTimeAggregatedData atd` ON `atd.CID = cc.CID`
- `IsNull((atd.TotalDeposit + atd.TotalCompensation), 0)` AS `TotalDepositAndCompensation`
- NULL-safe: if the customer has no record in CustomerAllTimeAggregatedData, returns 0
- Uses pre-aggregated BackOffice table (not a live SUM from Billing.Deposit) for performance

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Filters Customer.Customer to this single customer. |
| - | riskGroupByCountryByIP | INT | YES | - | CODE-BACKED | RiskGroupID from Dictionary.Country for the customer's IP-detected country (CountryIDByIP). NULL if CountryIDByIP is not set or not found in Dictionary.Country. Higher values typically indicate higher risk. |
| - | riskGroupByCountryID | INT | YES | - | CODE-BACKED | RiskGroupID from Dictionary.Country for the customer's declared country (CountryID). NULL if CountryID is not set. May differ from riskGroupByCountryByIP; discrepancy is itself a risk signal. |
| - | TotalDepositAndCompensation | DECIMAL | NO | 0 | CODE-BACKED | Sum of TotalDeposit + TotalCompensation from BackOffice.CustomerAllTimeAggregatedData. All-time USD-equivalent value of customer's deposits and platform compensations. ISNULL to 0 if no aggregated data exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CountryID, CountryIDByIP | Customer.Customer | SELECT (anchor) | Source of both country identifiers for the customer |
| CountryID | Dictionary.Country (as bcid) | LEFT JOIN | Declared country -> RiskGroupID |
| CountryIDByIP | Dictionary.Country (as bcip) | LEFT JOIN | IP country -> RiskGroupID |
| CID | BackOffice.CustomerAllTimeAggregatedData | LEFT JOIN | Pre-aggregated all-time TotalDeposit + TotalCompensation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing service (read-only API) | @CID | EXEC | Risk scoring inputs for payment routing decisions (Billing Service Database Readonly Separation, Confluence MG) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetUserCountryRisk (procedure)
+-- Customer.Customer (table) [CountryID + CountryIDByIP]
+-- Dictionary.Country (table) [RiskGroupID - joined twice]
+-- BackOffice.CustomerAllTimeAggregatedData (table) [TotalDeposit + TotalCompensation]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | CID anchor; provides CountryID and CountryIDByIP |
| Dictionary.Country | Table | LEFT JOIN (twice) to resolve RiskGroupID for each country source |
| BackOffice.CustomerAllTimeAggregatedData | Table | LEFT JOIN for pre-aggregated all-time deposit + compensation totals |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing service (read-only API) | External | Country-based risk inputs for payment method eligibility and routing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK throughout | Concurrency | All joins use WITH (NOLOCK); NOLOCK was added in ticket 49466 (was missing originally) |
| BackOffice pre-aggregated | Performance | Uses CustomerAllTimeAggregatedData (daily batch updated) not live SUM from Billing.Deposit - faster but may lag by up to 1 day |
| NULL risk groups | Behavior | Both riskGroupByCountryByIP and riskGroupByCountryID can be NULL; callers must handle NULL risk group |

---

## 8. Sample Queries

### 8.1 Get risk profile for a customer

```sql
EXEC [Billing].[GetUserCountryRisk] @CID = 12345
-- Returns: riskGroupByCountryByIP, riskGroupByCountryID, TotalDepositAndCompensation
```

### 8.2 Equivalent direct query

```sql
SELECT
    bcip.RiskGroupID AS riskGroupByCountryByIP,
    bcid.RiskGroupID AS riskGroupByCountryID,
    ISNULL((atd.TotalDeposit + atd.TotalCompensation), 0) AS TotalDepositAndCompensation
FROM [Customer].[Customer] cc WITH (NOLOCK)
LEFT JOIN [Dictionary].[Country] bcid WITH (NOLOCK) ON cc.CountryID = bcid.CountryID
LEFT JOIN [Dictionary].[Country] bcip WITH (NOLOCK) ON cc.CountryIDByIP = bcip.CountryID
LEFT JOIN [BackOffice].[CustomerAllTimeAggregatedData] atd WITH (NOLOCK) ON atd.CID = cc.CID
WHERE cc.CID = 12345
```

### 8.3 Find customers by risk group

```sql
-- Customers with high-risk IP country
SELECT cc.CID, bcip.RiskGroupID, bcip.Name AS IPCountry
FROM [Customer].[Customer] cc WITH (NOLOCK)
INNER JOIN [Dictionary].[Country] bcip WITH (NOLOCK) ON cc.CountryIDByIP = bcip.CountryID
WHERE bcip.RiskGroupID = 3  -- High risk
```

---

## 9. Atlassian Knowledge Sources

**Confluence**: "Billing Service Database Readonly Separation" (/spaces/MG) - references this procedure as part of the read-only billing service query layer.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 1 Confluence (Billing Service Database Readonly Separation) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetUserCountryRisk | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetUserCountryRisk.sql*
