# Price.GetAllLiquidityProviderPriceSource

> Returns all liquidity provider-to-price-source mappings with human-readable names joined from Trade.LiquidityProviders and Dictionary.PriceSourceName - the read half of the LP price source CRUD API.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetAllLiquidityProviderPriceSource is the read procedure for the `Price.LiquidityProviderPriceSource` table. It returns all configured LP-to-price-source mappings enriched with the LiquidityProviderName from `Trade.LiquidityProviders` and the PriceSourceName from `Dictionary.PriceSourceName`, making the result immediately human-readable without requiring the caller to join those lookup tables.

This procedure exists as the read half of a four-procedure CRUD API (Insert / Get / Update / Delete) for LP price source configuration. The configuration UI or pricing admin tools call this to display the current mapping between brokers/LPs and the exchanges that provide their market data.

Currently, `Price.LiquidityProviderPriceSource` holds 0 rows - so this procedure returns an empty result set. When rows are present, each row shows which exchange (e.g., NASDAQ, CBOE) is the authoritative price source for a given LP.

---

## 2. Business Logic

### 2.1 Full Table Read with Name Resolution

**What**: Returns all rows from LiquidityProviderPriceSource, joining in display names from both FK-target tables.

**Columns/Parameters Involved**: No parameters.

**Rules**:
- INNER JOINs on both Trade.LiquidityProviders and Dictionary.PriceSourceName - if a row in LiquidityProviderPriceSource has an invalid FK (orphaned LiquidityProviderID or PriceSourceID), it would be excluded from results
- SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED - reads without shared locks, consistent with READ UNCOMMITTED / NOLOCK pattern used across Price schema
- SET NOCOUNT ON - suppresses row-count messages
- ORDER BY lp.LiquidityProviderID - results ordered for deterministic display
- No pagination, no filters - always returns the full table

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No input parameters. Returns full contents of Price.LiquidityProviderPriceSource with names joined. |

**Result set columns** (4 columns):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | LiquidityProviderID | lp.LiquidityProviderID | The LP identifier. PK of LiquidityProviderPriceSource. FK to Trade.LiquidityProviders. |
| 2 | PriceSourceID | lp.PriceSourceID | The exchange/venue identifier. FK to Dictionary.PriceSourceName. Values: 0=eToro, 1=Xignite, 2=CME, 3=NASDAQ, 4=Chi-Ex, 5=LSE PLC, 6=Xetra, 7=Euronext, etc. |
| 3 | LiquidityProviderName | lprov.LiquidityProviderName | Human-readable LP name from Trade.LiquidityProviders (e.g., "Interactive Brokers", "Goldman Sachs") |
| 4 | PriceSourceName | psn.Name | Human-readable exchange name from Dictionary.PriceSourceName (e.g., "NASDAQ", "CBOE Europe") |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderID | Price.LiquidityProviderPriceSource | READER | Primary source table |
| LiquidityProviderID | Trade.LiquidityProviders | INNER JOIN | Resolves LiquidityProviderID to LiquidityProviderName |
| PriceSourceID | Dictionary.PriceSourceName | INNER JOIN | Resolves PriceSourceID to price source display name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing configuration UI / API) | - | CALLER | Called to display the full LP-to-price-source configuration list |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetAllLiquidityProviderPriceSource (procedure)
+-- Price.LiquidityProviderPriceSource (table) - primary source
+-- Trade.LiquidityProviders (table) - JOIN for LP name
+-- Dictionary.PriceSourceName (table) - JOIN for price source name
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityProviderPriceSource | Table | FROM source - all LP-to-source mappings |
| Trade.LiquidityProviders | Table | INNER JOIN - resolves LiquidityProviderID to name |
| Dictionary.PriceSourceName | Table | INNER JOIN - resolves PriceSourceID to name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing configuration API) | External | Calls to retrieve all LP price source mappings with display names |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED applied at session level (not via NOLOCK hints). This means all reads in this session use READ UNCOMMITTED. No pagination, no parameters. Currently returns empty result set (0 rows in Price.LiquidityProviderPriceSource). The companion CRUD procedures are InsertLiquidityProviderPriceSource, UpdateLiquidityProviderPriceSource, and DeleteLiquidityProviderPriceSource.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Price.GetAllLiquidityProviderPriceSource;
```

### 8.2 Equivalent manual query

```sql
SELECT
    lp.LiquidityProviderID,
    lp.PriceSourceID,
    lprov.LiquidityProviderName,
    psn.Name AS PriceSourceName
FROM Price.LiquidityProviderPriceSource lp WITH (NOLOCK)
INNER JOIN Trade.LiquidityProviders lprov WITH (NOLOCK)
    ON lp.LiquidityProviderID = lprov.LiquidityProviderID
INNER JOIN Dictionary.PriceSourceName psn WITH (NOLOCK)
    ON lp.PriceSourceID = psn.PriceSourceID
ORDER BY lp.LiquidityProviderID;
```

### 8.3 Check if any mappings currently exist

```sql
SELECT COUNT(*) AS MappingCount FROM Price.LiquidityProviderPriceSource WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetAllLiquidityProviderPriceSource | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetAllLiquidityProviderPriceSource.sql*
