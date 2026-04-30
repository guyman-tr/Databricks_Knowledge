# Trade.LiquidityProviderExchanges

> Junction table mapping liquidity provider types to the exchanges they support. Each row associates a provider type (e.g., Binance, FXCM) with an exchange (e.g., Nasdaq, NYSE) to indicate which venues a provider can execute on. Currently empty - prepared for future liquidity provider exchange coverage configuration.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | LiquidityProviderTypeID, ExchangeID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

**WHAT**: Trade.LiquidityProviderExchanges is a junction table that maps liquidity provider types (from Trade.LiquidityProviderType) to exchanges (from Dictionary.ExchangeInfo). Each row represents that a given provider type can execute trades on a given exchange. For example: Binance (LiquidityProviderTypeID=30) might be mapped to Digital Currency (ExchangeID=8), FXCM (LiquidityProviderTypeID=2) to FX (ExchangeID=1).

**WHY**: The platform routes orders to multiple external venues - forex brokers, crypto exchanges, market makers. When a provider type (e.g., Interactive Brokers) supports multiple exchanges (Nasdaq, NYSE, LSE), this table defines which exchanges each provider type can use. Enables routing logic to filter providers by exchange availability and avoid sending orders to providers that don't support the target venue.

**HOW**: Rows would be inserted when configuring liquidity provider coverage. Referenced by Dictionary.ExchangeInfo as the inverse relationship (ExchangeInfo documents that LiquidityProviderExchanges.ExchangeID points to it). Trade.LiquidityProviderType is the parent for LiquidityProviderTypeID. The table is currently empty (0 rows) — structure exists for future use. No views or procedures in the Trade schema directly query this table; it is referenced from Trade.LiquidityProviderType and Dictionary.ExchangeInfo documentation.

---

## 2. Business Logic

### 2.1 Provider-to-Exchange Mapping

**What**: Each (LiquidityProviderTypeID, ExchangeID) pair indicates that the provider type supports that exchange.

**Columns/Parameters Involved**: `LiquidityProviderTypeID`, `ExchangeID`, `ExchangeName`

**Rules**:
- LiquidityProviderTypeID references Trade.LiquidityProviderType (e.g., 0=eToro, 2=FXCM, 15=Kraken, 30=Binance).
- ExchangeID references Dictionary.ExchangeInfo (e.g., 1=FX, 4=Nasdaq, 5=NYSE, 8=Digital Currency).
- ExchangeName stores a human-readable exchange name — may duplicate or supplement Dictionary.ExchangeInfo for display.
- Composite PK ensures one row per (LiquidityProviderTypeID, ExchangeID).

### 2.2 Empty Table Status

**What**: Table has 0 rows in production.

**Rules**: Structure is in place for future configuration. No insert/update logic found in Trade views or procedures. No views or stored procedures directly reference this table.

---

## 3. Data Overview

| LiquidityProviderTypeID | ExchangeID | ExchangeName | Meaning |
|---|---|---|---|
| — | — | — | *Table is currently empty (0 rows). Structure ready for mapping liquidity provider types to exchanges. Example: LiquidityProviderTypeID=30 (Binance) → ExchangeID=8 (Digital Currency).* |

**Selection criteria**: No rows exist. The table is prepared for future use when exchange coverage per provider type is configured.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderTypeID | int | NO | - | CODE-BACKED | FK → Trade.LiquidityProviderType. Provider type identifier. Values 0–44 for physical providers (e.g., 2=FXCM, 30=Binance), 9999+ for system types. See [Trade.LiquidityProviderType](Trade.LiquidityProviderType.md). |
| 2 | ExchangeID | int | NO | - | CODE-BACKED | Implicit FK → Dictionary.ExchangeInfo. Exchange identifier. 1=FX, 4=Nasdaq, 5=NYSE, 8=Digital Currency. See [Dictionary.ExchangeInfo](../../Dictionary/Tables/Dictionary.ExchangeInfo.md). |
| 3 | ExchangeName | varchar(100) | NO | - | CODE-BACKED | Human-readable exchange name. May duplicate Dictionary.ExchangeInfo for display purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderTypeID | Trade.LiquidityProviderType | FK (FK_LPCEProviderTypeID_LPTProviderID) | Provider type (e.g., Binance, FXCM) |
| ExchangeID | Dictionary.ExchangeInfo | Implicit | Exchange (e.g., Nasdaq, Digital Currency) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityProviderType | LiquidityProviderTypeID | FK | Parent table for provider type; documented in Trade.LiquidityProviderType.md |
| Dictionary.ExchangeInfo | ExchangeID | Implicit | Documents ExchangeID references in Dictionary.ExchangeInfo.md |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.LiquidityProviderExchanges (table)
```

This object has no code-level dependencies. It is a leaf table. FK targets belong in Section 5 (Relationships).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderType | Table | FK LiquidityProviderTypeID (explicit FK) |

### 6.2 Objects That Depend On This

No dependents found. No views or procedures in the Trade schema directly reference this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomInstrumentsConfiguration | CLUSTERED PK | LiquidityProviderTypeID ASC, ExchangeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomInstrumentsConfiguration | PRIMARY KEY | Unique (LiquidityProviderTypeID, ExchangeID) |
| FK_LPCEProviderTypeID_LPTProviderID | FOREIGN KEY | LiquidityProviderTypeID → Trade.LiquidityProviderType.LiquidityProviderTypeID |

---

## 8. Sample Queries

### 8.1 List all provider-exchange mappings (when populated)
```sql
SELECT  lpe.LiquidityProviderTypeID, lpt.Name AS ProviderTypeName,
        lpe.ExchangeID, lpe.ExchangeName
FROM    Trade.LiquidityProviderExchanges lpe WITH (NOLOCK)
JOIN    Trade.LiquidityProviderType lpt WITH (NOLOCK) ON lpt.LiquidityProviderTypeID = lpe.LiquidityProviderTypeID
ORDER BY lpt.Name, lpe.ExchangeName;
```

### 8.2 Exchanges supported by a provider type (e.g., Binance = 30)
```sql
SELECT  lpe.ExchangeID, lpe.ExchangeName
FROM    Trade.LiquidityProviderExchanges lpe WITH (NOLOCK)
WHERE   lpe.LiquidityProviderTypeID = 30
ORDER BY lpe.ExchangeName;
```

### 8.3 Provider types supporting an exchange (e.g., Digital Currency = 8)
```sql
SELECT  lpe.LiquidityProviderTypeID, lpt.Name AS ProviderTypeName
FROM    Trade.LiquidityProviderExchanges lpe WITH (NOLOCK)
JOIN    Trade.LiquidityProviderType lpt WITH (NOLOCK) ON lpt.LiquidityProviderTypeID = lpe.LiquidityProviderTypeID
WHERE   lpe.ExchangeID = 8
ORDER BY lpt.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.LiquidityProviderExchanges | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.LiquidityProviderExchanges.sql*
