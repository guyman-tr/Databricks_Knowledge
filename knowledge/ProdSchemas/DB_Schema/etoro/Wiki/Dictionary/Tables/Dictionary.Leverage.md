# Dictionary.Leverage

> Lookup table defining the available leverage multiplier values (1x to 400x) for trading positions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LeverageID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK clustered + unique on Value) |

---

## 1. Business Meaning

Dictionary.Leverage defines the 10 discrete leverage multiplier values available on the eToro platform. Leverage determines the ratio between a position's market exposure and the margin (cash) required to open it. A leverage of 10x means $100 of margin controls $1,000 of market exposure.

This table is fundamental to eToro's trading engine. Leverage affects margin calculations, risk exposure, PnL magnitude, overnight fee amounts, and regulatory compliance. ESMA regulations cap retail leverage (30x forex, 20x indices, 10x commodities, 5x stocks, 2x crypto), and different jurisdictions apply different limits. A leverage of 1x (no leverage) enables real asset ownership (SettlementType=REAL).

LeverageID is stored with every position in Trade.PositionTbl. It is referenced by Trade procedures for margin calculations, by the order validation pipeline to enforce regulatory limits, and by instrument configuration to define which leverage values are available per instrument/regulation combination.

---

## 2. Business Logic

### 2.1 Leverage and Settlement Type Relationship

**What**: Leverage value determines whether a position can be REAL (asset ownership) or must be CFD.

**Columns/Parameters Involved**: `LeverageID`, `Value`

**Rules**:
- Leverage 1 (Value=1, ID=1) → eligible for SettlementType=REAL (if instrument supports it)
- Leverage > 1 (any other value) → forced to SettlementType=CFD
- ESMA retail caps: Forex=30x, Major Indices=20x, Commodities/Minor Indices=10x, Stocks/ETFs=5x, Crypto=2x
- Professional clients may access up to 400x on forex

**Diagram**:
```
Leverage Values:
  1x  ──► REAL ownership (stocks, ETF, crypto) or CFD
  2x  ──► CFD only (max retail for crypto under ESMA)
  5x  ──► CFD only (max retail for stocks under ESMA)
  10x ──► CFD only (max retail for commodities under ESMA)
  20x ──► CFD only (max retail for major indices under ESMA)
  30x ──► CFD only (max retail for major forex under ESMA)
  50x ──► CFD only (professional clients)
  100x ──► CFD only (professional clients)
  200x ──► CFD only (professional clients)
  400x ──► CFD only (professional clients, highest available)
```

---

## 3. Data Overview

| LeverageID | Value | Meaning |
|---|---|---|
| 1 | 1 | No leverage (1:1). Full cash position. The only leverage that enables REAL asset ownership (stocks, ETF, crypto). $100 margin = $100 exposure. |
| 9 | 2 | 2x leverage. ESMA maximum for retail crypto trading. $100 margin = $200 exposure. Doubles both potential gains and losses. |
| 10 | 30 | 30x leverage. ESMA maximum for retail major forex pairs. $100 margin = $3,000 exposure. Standard for EUR/USD, GBP/USD. |
| 7 | 200 | 200x leverage. Available to professional/elective professional clients only. $100 margin = $20,000 exposure. High risk. |
| 8 | 400 | 400x leverage. Highest available. Restricted to professional clients in permissive jurisdictions. $100 margin = $40,000 exposure. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LeverageID | int | NO | - | CODE-BACKED | Primary key — internal identifier for the leverage tier. Note: LeverageID does NOT equal the leverage Value (e.g., LeverageID=9 has Value=2, LeverageID=10 has Value=30). Always use Value for business logic. See [Leverage](_glossary.md#leverage). (Dictionary.Leverage) |
| 2 | Value | int | NO | - | CODE-BACKED | The actual leverage multiplier. UNIQUE constraint. Values: 1, 2, 5, 10, 20, 30, 50, 100, 200, 400. Stored in Trade.PositionTbl.Leverage. Used in margin calculations: RequiredMargin = PositionAmount / LeverageValue. Determines PnL multiplier and overnight fee scaling. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionTbl | Leverage | Implicit Lookup | Every position has a leverage value |
| Instrument leverage configuration | LeverageID | Implicit Lookup | Available leverage per instrument/regulation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Stores Leverage value per position |
| Instrument configuration tables | Table | Define available leverage per instrument |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DLVG | CLUSTERED PK | LeverageID ASC | - | - | Active |
| DLVG_VALUE | NC UNIQUE | Value ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DLVG | PRIMARY KEY | Unique leverage tier identifier |
| DLVG_VALUE | UNIQUE | Each leverage multiplier value is unique |

---

## 8. Sample Queries

### 8.1 List all leverage values
```sql
SELECT LeverageID, Value FROM [Dictionary].[Leverage] WITH (NOLOCK) ORDER BY Value;
```

### 8.2 Count open positions by leverage
```sql
SELECT l.Value AS Leverage, COUNT(*) AS PositionCount
FROM [Trade].[PositionTbl] tp WITH (NOLOCK)
JOIN [Dictionary].[Leverage] l WITH (NOLOCK) ON tp.Leverage = l.Value
WHERE tp.IsClosed = 0 GROUP BY l.Value ORDER BY PositionCount DESC;
```

### 8.3 Find positions with high leverage (professional clients)
```sql
SELECT tp.PositionID, tp.CID, tp.Leverage, tp.Amount, tp.OpenDateTime
FROM [Trade].[PositionTbl] tp WITH (NOLOCK)
WHERE tp.IsClosed = 0 AND tp.Leverage >= 50 ORDER BY tp.Leverage DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.Leverage.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Leverage | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Leverage.sql*
