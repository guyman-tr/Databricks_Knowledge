# Price.ExchangeNameToProvider

> Lookup table that stores provider-specific exchange name overrides, allowing each liquidity provider to use its own naming convention for a physical exchange when building ticker information for feed routing.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (ExchangeID, ProviderID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

ExchangeNameToProvider maps a standard exchange (Price.Exchange) to a liquidity provider (Trade.LiquidityProviderType)-specific name for that exchange. Different liquidity providers may refer to the same physical exchange by different names - for example, Interactive Brokers (IB) calls NASDAQ's electronic matching venue "ISLAND" (the original name of the Island ECN, which was acquired by and became NASDAQ's core trading platform).

Without this table, all providers would receive the standard exchange name from Price.Exchange. With it, the `Price.GetTickerInfo` procedure applies per-provider overrides using `isnull(petp.Name, pe.Name) AS PrimaryExch` - meaning the standard exchange name is used unless an override exists for that specific provider.

The table has only 1 active row currently (NASDAQ/ISLAND for IB), indicating this override mechanism is used sparingly for cases where a provider's naming convention differs significantly from the standard. It is a pure configuration table with no temporal auditing or computed columns - changes are tracked via standard DML only.

---

## 2. Business Logic

### 2.1 Provider-Specific Exchange Name Override

**What**: Liquidity providers may use legacy or internal names for exchanges that differ from the ISO standard names. This table stores those aliases so ticker output matches what each provider expects.

**Columns/Parameters Involved**: `ExchangeID`, `ProviderID`, `Name`

**Rules**:
- Price.GetTickerInfo uses: `isnull(petp.Name, pe.Name) AS PrimaryExch` - the override is applied when a row exists for the (ExchangeID, ProviderID) combination, otherwise the standard Price.Exchange.Name is used
- The composite PK ensures at most one name override per (exchange, provider) pair
- A provider with no override in this table simply receives the standard exchange name from Price.Exchange
- Current only row: ExchangeID=4 (NASDAQ, MIC=XNAS), ProviderID=11 (IB/Interactive Brokers), Name="ISLAND"

**Diagram**:
```
Price.GetTickerInfo lookup:
                               Row exists in ExchangeNameToProvider?
  ExchangeID + ProviderID --> YES: use ExchangeNameToProvider.Name ("ISLAND")
                           --> NO:  use Price.Exchange.Name ("NASDAQ")
                                                |
                                          PrimaryExch output field
```

---

## 3. Data Overview

| ExchangeID | ProviderID | Name | Meaning |
|---|---|---|---|
| 4 (NASDAQ) | 11 (IB) | ISLAND | Interactive Brokers uses the name "ISLAND" for NASDAQ's electronic matching venue - a legacy reference to Island ECN, the electronic communication network acquired by NASDAQ in 2002 that became its core trading platform. IB retained this legacy identifier in its routing system. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. References the exchange in Price.Exchange for which this provider-specific name applies. Only exchanges that a liquidity provider names differently need a row here. (Price.Exchange) |
| 2 | ProviderID | int | NOT NULL | - | VERIFIED | Part 2 of composite PK. References the liquidity provider type in Trade.LiquidityProviderType that uses the non-standard exchange name. Values: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 4=CNX, 5=XIGNITE, 6=MT_GOX, 7=GFT, 8=BitStamp, 9=GoldmanSachs, 10=BTC-e, 11=IB, 12=IG Execution, 13=Exante, 15=Kraken, 16=GDAX, 17=Poloniex, 18=IEX, 19=Bittrex, 20=Gemini. Currently only IB (11) has an override. (Trade.LiquidityProviderType) |
| 3 | Name | varchar(150) | NOT NULL | - | VERIFIED | The provider-specific name for this exchange. Used by Price.GetTickerInfo as `isnull(ExchangeNameToProvider.Name, Exchange.Name)` - overrides the standard exchange name when building ticker output for the specified provider. Current value: "ISLAND" (IB's name for NASDAQ). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExchangeID | Price.Exchange | FK (FK_PRICE_EXCHANGE_EXCHANGE) | The exchange for which a provider-specific name is configured. Only exchanges with naming discrepancies per provider need a row here. |
| ProviderID | Trade.LiquidityProviderType | FK (FK_PRICE_EXCHANGE_PROVIDER) via LiquidityProviderTypeID | The liquidity provider that uses a non-standard exchange name. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetTickerInfo | ExchangeID, ProviderID | LEFT JOIN | Applies provider-specific exchange name override in ticker info output via `isnull(ExchangeNameToProvider.Name, Exchange.Name)` |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.ExchangeNameToProvider (table)
|- Price.Exchange (table, FK target - leaf)
|- Trade.LiquidityProviderType (table, FK target - leaf)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.Exchange | Table | FK target - ExchangeID must reference a valid exchange |
| Trade.LiquidityProviderType | Table | FK target - ProviderID must reference a valid liquidity provider type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetTickerInfo | Stored Procedure | LEFT JOIN on (ExchangeID, ProviderID) to apply provider-specific exchange name overrides in ticker output |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ECHANGE_PROVIDER | CLUSTERED PK | ExchangeID ASC, ProviderID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ECHANGE_PROVIDER | PRIMARY KEY | Composite PK - one name override per (exchange, provider) pair |
| FK_PRICE_EXCHANGE_EXCHANGE | FK | ExchangeID -> Price.Exchange(ExchangeID) |
| FK_PRICE_EXCHANGE_PROVIDER | FK | ProviderID -> Trade.LiquidityProviderType(LiquidityProviderTypeID) |

---

## 8. Sample Queries

### 8.1 View all provider-specific exchange name overrides

```sql
SELECT
    ENP.ExchangeID,
    E.Name AS StandardExchangeName,
    E.Mic,
    ENP.ProviderID,
    LPT.Name AS ProviderName,
    ENP.Name AS ProviderSpecificName
FROM Price.ExchangeNameToProvider ENP WITH (NOLOCK)
JOIN Price.Exchange E WITH (NOLOCK) ON E.ExchangeID = ENP.ExchangeID
JOIN Trade.LiquidityProviderType LPT WITH (NOLOCK) ON LPT.LiquidityProviderTypeID = ENP.ProviderID
ORDER BY ENP.ProviderID, ENP.ExchangeID;
```

### 8.2 Simulate how GetTickerInfo resolves exchange names for a provider

```sql
SELECT
    lpc.InstrumentID,
    lpc.Ticker,
    isnull(petp.Name, pe.Name) AS PrimaryExch,
    pe.Mic,
    pe.Ric
FROM Trade.LiquidityProviderContracts lpc WITH (NOLOCK)
JOIN Price.Exchange pe WITH (NOLOCK) ON lpc.ExchangeID = pe.ExchangeID
LEFT JOIN Price.ExchangeNameToProvider petp WITH (NOLOCK)
    ON petp.ExchangeID = pe.ExchangeID
    AND petp.ProviderID = lpc.LiquidityProviderID
WHERE lpc.LiquidityProviderID = 11  -- IB
ORDER BY lpc.InstrumentID;
```

### 8.3 Check if a specific exchange has any provider name overrides

```sql
SELECT
    ENP.ExchangeID,
    E.Name AS StandardName,
    ENP.ProviderID,
    LPT.Name AS ProviderName,
    ENP.Name AS Override
FROM Price.ExchangeNameToProvider ENP WITH (NOLOCK)
JOIN Price.Exchange E WITH (NOLOCK) ON E.ExchangeID = ENP.ExchangeID
JOIN Trade.LiquidityProviderType LPT WITH (NOLOCK) ON LPT.LiquidityProviderTypeID = ENP.ProviderID
WHERE ENP.ExchangeID = 4;  -- NASDAQ
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.ExchangeNameToProvider | Type: Table | Source: etoro/etoro/Price/Tables/Price.ExchangeNameToProvider.sql*
