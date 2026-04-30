# Trade.FunGetFirmAggregationHWM

> Returns firm aggregation high-water mark (HWM) exposure data per customer for a given trade day, filtered by Apex account and regulation — used for risk and allocation reporting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with TradeDate, CID, ApexID, HWM, Name (regulation) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunGetFirmAggregationHWM retrieves the high-water mark (HWM) exposure for customers from the allocation daily exposure data. HWM represents the peak exposure level reached by a customer on a given trade day — a key metric for risk aggregation and firm-level position limits. The function filters by customer, Apex account ID (provider account), and regulation to support per-entity reporting.

This function exists to provide a unified, filtered view of firm aggregation exposure for BI, risk dashboards, and compliance reporting. Without it, consumers would need to query SyneToroAllocationDailyExposure directly and join to Customer, BackOffice, and Regulation tables themselves. The function simplifies access for BIReader and downstream reporting tools.

Data flows: the function is invoked with @CID, @ApexAccountID, @CurrentTradeDay, and @RegulationID. All parameters are optional filters (NULL = no filter). Returns one row per customer with positive HWM that matches the filters.

---

## 2. Business Logic

### 2.1 HWM Calculation

**What**: HWM is the maximum exposure for a customer on the trade date, floored at zero.

**Columns/Parameters Involved**: `Exposure`, `TradeDate`, `CID`

**Rules**:
- Source: `dbo.SyneToroAllocationDailyExposure` — allocation date must match @CurrentTradeDay (or today if NULL)
- HWM = IIF(MAX(Exposure) >= 0, MAX(Exposure), 0) — negative exposure is treated as 0
- GROUP BY CID — one HWM per customer per trade date
- Only rows with HWM > 0 are returned

### 2.2 Filter Logic

**What**: Optional filters narrow results by Apex account and regulation.

**Columns/Parameters Involved**: `@CID`, `@ApexAccountID`, `@RegulationID`

**Rules**:
- @CID NULL = all customers; @CID = value = single customer
- @ApexAccountID NULL = all Apex accounts; @ApexAccountID = value = single Apex account (CustomerStatic.ApexID)
- @RegulationID NULL = all regulations; @RegulationID = value = single regulation (BackOffice.Customer.RegulationID)
- INNER JOIN Customer.CustomerStatic requires ApexID IS NOT NULL — excludes customers without Apex linkage
- INNER JOIN BackOffice.Customer and Dictionary.Regulation — Name returned for regulation display

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | - | - | CODE-BACKED | Customer ID filter. NULL = all customers; value = single customer. |
| 2 | @ApexAccountID | VARCHAR(50) | - | - | CODE-BACKED | Apex (liquidity provider) account ID filter. NULL = all; value = single account. |
| 3 | @CurrentTradeDay | DATE | - | - | CODE-BACKED | Trade date for exposure. NULL = today (CAST(GETDATE() AS DATE)). |
| 4 | @RegulationID | INT | - | - | CODE-BACKED | Regulation filter. NULL = all; value = single regulation (e.g., CySEC, FCA). See [Regulation](_glossary.md#regulation). |
| 5 | TradeDate (return) | DATE | NO | - | CODE-BACKED | The trade date for the exposure snapshot. |
| 6 | CID (return) | INT | NO | - | CODE-BACKED | Customer ID. |
| 7 | ApexID (return) | VARCHAR | YES | - | CODE-BACKED | Apex account identifier from Customer.CustomerStatic. |
| 8 | HWM (return) | decimal | NO | - | CODE-BACKED | High-water mark exposure (max exposure, floored at 0) for the customer on TradeDate. |
| 9 | Name (return) | NVARCHAR | YES | - | CODE-BACKED | Regulation name from Dictionary.Regulation (e.g., CySEC, FCA). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SyneToroAllocationDailyExposure | dbo.SyneToroAllocationDailyExposure | FROM | Source of allocation exposure |
| CustomerStatic | Customer.CustomerStatic | INNER JOIN | Links CID to ApexID |
| Customer | BackOffice.Customer | INNER JOIN | RegulationID for filter and display |
| Regulation | Dictionary.Regulation | INNER JOIN | Regulation name (Name) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BIReader | GRANT SELECT | Permission | BI/ reporting role has SELECT access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunGetFirmAggregationHWM (function)
├── dbo.SyneToroAllocationDailyExposure (table)
├── Customer.CustomerStatic (table)
├── BackOffice.Customer (table)
└── Dictionary.Regulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SyneToroAllocationDailyExposure | Table | CTE source for HWM aggregation |
| Customer.CustomerStatic | Table | INNER JOIN for ApexID, filter |
| BackOffice.Customer | Table | INNER JOIN for RegulationID filter |
| Dictionary.Regulation | Table | INNER JOIN for regulation name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BIReader | Role | GRANT SELECT — BI reporting access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning 5 columns |
| HWM > 0 | Filter | Only positive HWM rows returned |
| ApexID IS NOT NULL | Filter | Excludes customers without Apex linkage |

---

## 8. Sample Queries

### 8.1 Get HWM for all customers on a trade day

```sql
SELECT  TradeDate, CID, ApexID, HWM, Name
FROM    Trade.FunGetFirmAggregationHWM(NULL, NULL, '2026-03-14', NULL);
```

### 8.2 Get HWM for a specific customer and Apex account

```sql
SELECT  TradeDate, CID, ApexID, HWM, Name
FROM    Trade.FunGetFirmAggregationHWM(9263423, 'APEX123', NULL, NULL);
```

### 8.3 Get HWM filtered by regulation

```sql
SELECT  TradeDate, CID, ApexID, HWM, Name
FROM    Trade.FunGetFirmAggregationHWM(NULL, NULL, CAST(GETDATE() AS DATE), 1)
ORDER BY HWM DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Code analysis*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | Dependencies: SyneToroAllocationDailyExposure, Customer, Regulation | Corrections: 0 applied*
*Object: Trade.FunGetFirmAggregationHWM | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FunGetFirmAggregationHWM.sql*
