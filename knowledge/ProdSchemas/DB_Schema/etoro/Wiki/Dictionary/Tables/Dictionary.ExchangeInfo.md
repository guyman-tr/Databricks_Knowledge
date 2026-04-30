# Dictionary.ExchangeInfo

## 1. Business Meaning

### What It Is
A lookup table cataloging all stock exchanges and market venues where instruments traded on the eToro platform are listed.

### Why It Exists
Each tradable instrument (stock, ETF, crypto, index) belongs to a specific exchange. This table provides the canonical exchange registry used for instrument classification, market hours determination, settlement rules, and regulatory reporting.

### How It's Used
Referenced by `Trade.InstrumentMetaData.ExchangeID` which links each instrument to its exchange. Used extensively by trading procedures including `Trade.InsertInstrumentTradingData`, `Trade.InsertInstrumentRealTable`, `Trade.GetAllInstrumentData`, `Trade.GetOrdersForExecutionReportDrillDown`, and instrument configuration procedures. The `Price.ExchangeIDList` user-defined type accepts lists of ExchangeIDs for batch operations.

---

## 2. Business Logic

### Exchange Categories

**Traditional Asset Classes (IDs 1-3)**
| ID | Exchange | Asset Type |
|----|----------|-----------|
| 1 | FX | Foreign exchange currency pairs |
| 2 | Commodity | Commodities (gold, oil, etc.) |
| 3 | CFD | Contracts for Difference (indices, etc.) |

**Major Global Exchanges (IDs 4-56)**
| ID | Exchange | Region |
|----|----------|--------|
| 4 | Nasdaq | US |
| 5 | NYSE | US |
| 6 | FRA (Frankfurt) | Germany |
| 7 | LSE (London) | UK |
| 8 | Digital Currency | Crypto |
| 9 | Euronext Paris | France |
| 10 | Bolsa De Madrid | Spain |
| 11 | Borsa Italiana | Italy |
| 12 | SIX | Switzerland |
| 13 | TYO (Tokyo) | Japan |
| 14-17 | Nordic Exchanges | Norway, Sweden, Denmark, Finland |
| 18 | Toronto Stock Exchange | Canada |
| 20 | CBOE | US Options |
| 21 | Hong Kong Exchanges | Hong Kong |
| 22-23 | Euronext (Lisbon, Brussels) | Europe |
| 24 | Tadawul | Saudi Arabia |
| 30-46+ | Additional exchanges | Amsterdam, Sydney, Vienna, Dublin, etc. |

**Test/Internal (IDs 99+)**
| ID | Exchange | Notes |
|----|----------|-------|
| 99+ | Timbuktu, Muxosransk, Gili, Test*, etc. | QA/test exchanges, not production |

---

## 3. Data Overview

62 rows total. Representative production exchanges:

| ExchangeID | ExchangeDescription |
|-----------|-------------------|
| 1 | FX |
| 4 | Nasdaq |
| 5 | NYSE |
| 7 | LSE |
| 8 | Digital Currency |
| 18 | Toronto Stock Exchange |
| 21 | Hong Kong Exchanges |
| 40 | CME |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **ExchangeID** | `int` | NO | Primary key. Exchange identifier. Production values 1-56; test values 99+. | `MCP` |
| **ExchangeDescription** | `varchar(50)` | NO | Exchange name or abbreviation. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | Relationship |
|-------|--------|-------------|
| Trade.InstrumentMetaData | ExchangeID | Implicit FK — which exchange an instrument is listed on |
| Trade.LiquidityProviderExchanges | ExchangeID | Implicit FK — liquidity provider exchange coverage |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `Trade.InstrumentMetaData` — instrument-to-exchange mapping
- `Trade.LiquidityProviderExchanges` — provider exchange coverage
- `Trade.InsertInstrumentTradingData` / `Trade.InsertInstrumentRealTable` — instrument creation
- `Trade.GetAllInstrumentData` — reads exchange info for instrument display
- `Trade.GetOrdersForExecutionReportDrillDown` — execution reports by exchange
- `Trade.InsertCopyTradeSettlementRestrictions` — settlement rules per exchange
- `Trade.GetInterestRateOverrides_TRDOPS` / `Trade.UpdateInterestRateOverride_TRDOPS` — interest rates per exchange
- `Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds` — price thresholds per exchange
- `Trade.UpdateIsSettledValidation` — settlement validation per exchange
- `Price.ExchangeIDList` — UDT for batch exchange operations
- `dbo.AccountStatement_GetDividends_v2` — dividend reporting by exchange

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `ExchangeID` (clustered, PK_DictionaryExchangeInfo) |
| **Filegroup** | PRIMARY (not DICTIONARY — legacy placement) |
| **Row Count** | 62 |
| **Identity** | No — manually assigned with gaps |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all production exchanges (exclude test)
SELECT  ExchangeID,
        ExchangeDescription
FROM    Dictionary.ExchangeInfo WITH (NOLOCK)
WHERE   ExchangeID < 99
ORDER BY ExchangeID;

-- Count instruments per exchange
SELECT  ei.ExchangeDescription  AS Exchange,
        COUNT(*)                AS InstrumentCount
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN    Dictionary.ExchangeInfo ei WITH (NOLOCK)
        ON imd.ExchangeID = ei.ExchangeID
GROUP BY ei.ExchangeDescription
ORDER BY InstrumentCount DESC;

-- Get exchange info for a specific instrument
SELECT  ei.ExchangeDescription
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN    Dictionary.ExchangeInfo ei WITH (NOLOCK)
        ON imd.ExchangeID = ei.ExchangeID
WHERE   imd.InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
