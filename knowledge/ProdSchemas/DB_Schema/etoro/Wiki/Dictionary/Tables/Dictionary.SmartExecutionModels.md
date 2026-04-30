# Dictionary.SmartExecutionModels

## 1. Business Meaning

**What it is**: A lookup table defining the execution pricing models available for smart order execution in the hedge/dealing system. Each model specifies how the execution price is determined relative to the bid/ask spread.

**Why it exists**: When the hedge server executes orders using the "Smart" execution strategy (see `Dictionary.HedgeServerExecutionStrategy` ID 2), it needs to determine the target execution price. This table defines the available pricing models — whether to use the bid price, the mid-price, the ask price, or market price (immediate fill).

**How it works**: The smart execution engine selects a model from this table based on instrument configuration and market conditions. The model determines the limit price for the order: LimitBid fills at the bid, LimitMid at the midpoint, LimitAsk at the ask, and Market executes immediately at the current market price without a limit.

---

## 2. Business Logic

### Execution Models
| ID | Model | Execution Strategy |
|----|-------|-------------------|
| 1 | LimitBid | Place limit order at bid price — best price for buys, wait for fill |
| 2 | LimitMid | Place limit order at mid-price (midpoint of bid-ask spread) — balanced approach |
| 3 | LimitAsk | Place limit order at ask price — best price for sells, guaranteed near-term fill |
| 4 | Market | Execute at market price immediately — no limit, instant fill, highest slippage risk |

### Spread Position Spectrum
```
Bid ← LimitBid (1) ← LimitMid (2) ← LimitAsk (3) → Market (4) → Ask
[Best price, slow fill]          [Balanced]          [Fast fill, higher cost]
```

---

## 3. Data Overview

| ModelID | ModelName | Business Meaning |
|---------|-----------|------------------|
| 1 | LimitBid | Limit at bid price (patient fill) |
| 2 | LimitMid | Limit at mid-price (balanced) |
| 3 | LimitAsk | Limit at ask price (aggressive fill) |
| 4 | Market | Immediate market execution |

*4 rows — complete smart execution pricing model enumeration*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **ModelID** | smallint | NOT NULL | — | Primary key. Execution model: 1=LimitBid, 2=LimitMid, 3=LimitAsk, 4=Market. Ordered from most patient (lowest cost) to most aggressive (fastest fill). | `MCP` |
| **ModelName** | varchar(50) | NULL | — | Human-readable model name. Convention: `Limit{PricePoint}` for limit orders, `Market` for immediate execution. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
*No direct SQL FK consumers found in SSDT — consumed by the hedge server smart execution engine at the application layer.*

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- Hedge server smart execution engine (application-level consumer)

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `ModelID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | DICTIONARY |
| Fill Factor | 100% |
| Row Count | 4 |

---

## 8. Sample Queries

```sql
-- Get all execution models
SELECT  ModelID, ModelName
FROM    Dictionary.SmartExecutionModels WITH (NOLOCK)
ORDER BY ModelID;

-- Compare limit vs market models
SELECT  ModelID, ModelName,
        CASE WHEN ModelName LIKE 'Limit%' THEN 'Limit Order' ELSE 'Market Order' END AS OrderType
FROM    Dictionary.SmartExecutionModels WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Smart execution models are a dealing desk/hedge server infrastructure feature.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.0 — MCP verified (4 rows), execution pricing spectrum documented, related to HedgeServerExecutionStrategy*
