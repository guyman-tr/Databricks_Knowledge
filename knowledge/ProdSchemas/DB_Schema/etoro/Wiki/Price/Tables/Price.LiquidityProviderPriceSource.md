# Price.LiquidityProviderPriceSource

> Configuration table that maps each liquidity provider to the exchange or price source that provides its market data, enabling attribution of price origins per broker/LP for display and regulatory purposes.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | LiquidityProviderID (int, CLUSTERED PK) |
| **Partition** | Yes - MAIN partition scheme on LiquidityProviderID |
| **Indexes** | 2 (PK clustered + NC on PriceSourceID) |

---

## 1. Business Meaning

LiquidityProviderPriceSource defines which exchange or price source is the authoritative origin of market data for each liquidity provider. A "liquidity provider" (Trade.LiquidityProviders) is a brokerage or trading entity whose prices eToro accepts; the "price source" (Dictionary.PriceSourceName) is the exchange or data venue that provides those prices. This one-to-one mapping (each LP has at most one price source, enforced by the PK on LiquidityProviderID) enables systems to report the origin exchange when displaying prices from a specific LP.

Without this mapping, it would be impossible to attribute prices to their originating exchange for display or compliance purposes. For example, an LP sourcing from NASDAQ (PriceSourceID=3) would have that declared here, allowing UIs to show "Powered by NASDAQ" or equivalent.

Currently the table holds 0 rows - no LP-to-price-source mappings are active. It has a complete CRUD API: `Price.InsertLiquidityProviderPriceSource`, `Price.UpdateLiquidityProviderPriceSource`, `Price.DeleteLiquidityProviderPriceSource`, and `Price.GetAllLiquidityProviderPriceSource`. System versioning tracks all changes in History.LiquidityProviderPriceSource.

---

## 2. Business Logic

### 2.1 One-to-One LP to Price Source Mapping

**What**: Each liquidity provider is mapped to exactly one price source. Attempting to insert a second mapping for the same LP is rejected by the insert procedure.

**Columns/Parameters Involved**: `LiquidityProviderID`, `PriceSourceID`

**Rules**:
- PK on LiquidityProviderID enforces the one-to-one constraint at the DB level
- `InsertLiquidityProviderPriceSource` additionally validates: (1) LiquidityProviderID exists in Trade.LiquidityProviders, (2) PriceSourceID exists in Dictionary.PriceSourceName, (3) LiquidityProviderID not already in this table - raises descriptive errors on any violation
- To change an LP's price source: use `Price.UpdateLiquidityProviderPriceSource` (not insert)
- The NC index on PriceSourceID allows fast lookup of all LPs using a given price source

---

## 3. Data Overview

The table is currently empty (0 rows). No LP-to-price-source mappings are configured.

*When populated, rows would appear as:*

| LiquidityProviderID | PriceSourceID | Meaning |
|---|---|---|
| (LP for IB/Interactive Brokers) | 3 (NASDAQ) | IB's price feed is sourced from NASDAQ - instruments priced via IB are NASDAQ-originated prices |
| (LP for Goldman Sachs) | 0 (eToro) | Goldman Sachs LP uses eToro's internal pricing rather than an external exchange |
| (LP for a CBOE LP) | 17 (CBOE EU) | This LP sources prices from CBOE Europe |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderID | int | NOT NULL | - | VERIFIED | Primary key and FK to Trade.LiquidityProviders. The specific liquidity provider instance (a broker/trading entity with credentials, accounts, and connections). Each LP can have at most one price source mapping. (Trade.LiquidityProviders) |
| 2 | PriceSourceID | int | NOT NULL | - | VERIFIED | FK to Dictionary.PriceSourceName. The exchange or data venue that provides prices for this LP: 0=eToro, 1=Xignite, 2=CME, 3=NASDAQ, 4=Chi-Ex, 5=LSE PLC, 6=Xetra, 7=Euronext, 8=DFM, 9=HKEX, 10=TMX, 11=ADX, 12=BME, 13=Nasdaq Nordic, 14=CBOE Japan, 15=SGX, 16=TWSE, 17=CBOE EU, 18=CBOE AUS, 19=Wiener Borse, 20=Prague SE, 21=Warsaw SE, 22=Budapest SE, 27=NSE, 28=Nasdaq Baltic, 29=KRX, 30=Blue Ocean. (Dictionary.PriceSourceName) |
| 3 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set on DML. |
| 4 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). InsertLiquidityProviderPriceSource accepts @AppLoginName parameter and sets CONTEXT_INFO before DML to populate this column. |
| 5 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 6 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical row versions in History.LiquidityProviderPriceSource. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderID | Trade.LiquidityProviders | FK (FK_LiquidityProviderPriceSource_LiquidityProvider) | The liquidity provider whose price source is being configured |
| PriceSourceID | Dictionary.PriceSourceName | FK (FK_LiquidityProviderPriceSource_PriceSource) | The exchange/venue that is the origin of this LP's prices |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetAllLiquidityProviderPriceSource | LiquidityProviderID | READER | Returns all mappings with LiquidityProviderName and PriceSourceName joined |
| Price.InsertLiquidityProviderPriceSource | LiquidityProviderID | WRITER | Inserts a new LP-to-price-source mapping with validation |
| Price.UpdateLiquidityProviderPriceSource | LiquidityProviderID | MODIFIER | Updates PriceSourceID for an existing LP mapping |
| Price.DeleteLiquidityProviderPriceSource | LiquidityProviderID | DELETER | Removes a mapping |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.LiquidityProviderPriceSource (table)
|- Trade.LiquidityProviders (table, FK target - leaf)
|- Dictionary.PriceSourceName (table, FK target - leaf)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviders | Table | FK target - LiquidityProviderID must reference a valid LP |
| Dictionary.PriceSourceName | Table | FK target - PriceSourceID must reference a valid price source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetAllLiquidityProviderPriceSource | Stored Procedure | READER - returns all mappings enriched with names |
| Price.InsertLiquidityProviderPriceSource | Stored Procedure | WRITER - inserts new LP-source mapping |
| Price.UpdateLiquidityProviderPriceSource | Stored Procedure | MODIFIER - changes PriceSourceID for an LP |
| Price.DeleteLiquidityProviderPriceSource | Stored Procedure | DELETER - removes LP-source mapping |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LiquidityProviderPriceSource | CLUSTERED PK | LiquidityProviderID ASC | - | - | Active |
| IX_LiquidityProviderPriceSource_PriceSourceID | NONCLUSTERED | PriceSourceID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_LiquidityProviderPriceSource | PRIMARY KEY | One price source per liquidity provider (LiquidityProviderID) |
| FK_LiquidityProviderPriceSource_LiquidityProvider | FK | LiquidityProviderID -> Trade.LiquidityProviders(LiquidityProviderID) |
| FK_LiquidityProviderPriceSource_PriceSource | FK | PriceSourceID -> Dictionary.PriceSourceName(PriceSourceID) |
| DF_LiquidityProviderPriceSource_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_LiquidityProviderPriceSource_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.LiquidityProviderPriceSource |

---

## 8. Sample Queries

### 8.1 View all LP-to-price-source mappings with names

```sql
SELECT
    lp.LiquidityProviderID,
    lprov.LiquidityProviderName,
    lp.PriceSourceID,
    psn.Name AS PriceSourceName,
    lp.SysStartTime AS ConfiguredSince
FROM Price.LiquidityProviderPriceSource lp WITH (NOLOCK)
JOIN Trade.LiquidityProviders lprov WITH (NOLOCK)
    ON lprov.LiquidityProviderID = lp.LiquidityProviderID
JOIN Dictionary.PriceSourceName psn WITH (NOLOCK)
    ON psn.PriceSourceID = lp.PriceSourceID
ORDER BY lp.LiquidityProviderID;
```

### 8.2 Find all LPs using a specific price source

```sql
SELECT
    lp.LiquidityProviderID,
    lprov.LiquidityProviderName,
    psn.Name AS PriceSourceName
FROM Price.LiquidityProviderPriceSource lp WITH (NOLOCK)
JOIN Trade.LiquidityProviders lprov WITH (NOLOCK)
    ON lprov.LiquidityProviderID = lp.LiquidityProviderID
JOIN Dictionary.PriceSourceName psn WITH (NOLOCK)
    ON psn.PriceSourceID = lp.PriceSourceID
WHERE lp.PriceSourceID = 3  -- NASDAQ
ORDER BY lp.LiquidityProviderID;
```

### 8.3 View change history for LP-source mappings (temporal)

```sql
SELECT
    LiquidityProviderID,
    PriceSourceID,
    DbLoginName,
    AppLoginName,
    SysStartTime,
    SysEndTime
FROM Price.LiquidityProviderPriceSource
FOR SYSTEM_TIME ALL
ORDER BY LiquidityProviderID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.LiquidityProviderPriceSource | Type: Table | Source: etoro/etoro/Price/Tables/Price.LiquidityProviderPriceSource.sql*
