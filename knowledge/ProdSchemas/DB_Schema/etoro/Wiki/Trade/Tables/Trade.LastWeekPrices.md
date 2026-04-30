# Trade.LastWeekPrices

> Stores last-week closing bid and ask prices per instrument and provider. Used for profit/loss calculations and pip-value estimation when real-time quotes are unavailable.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key** | InstrumentID + ProviderID (no PK) |
| **Indexes** | 0 |

---

## 1. Business Meaning

Trade.LastWeekPrices holds historical (last-week) bid and ask prices for instruments by provider. It is used when calculating unrealized P&L or pip values for positions when real-time market data is not available. The table acts as a fallback price source for closed-week calculations in History.GetNetProfitForDealing and History.GetOnePipValueDollarForDealing.

---

## 2. Business Logic

### 2.1 Price Source Fallback

**What**: When computing net profit or pip value for a position, the system uses LastWeekPrices when no current quote exists.

**Columns/Parameters Involved**: `InstrumentID`, `Bid`, `Ask`, `ProviderID`

**Rules**:
- One row per InstrumentID + ProviderID (logically; no unique constraint enforced)
- Bid and Ask are used in P&L formulas; NULLs are handled via ISNULL in consuming functions
- ProviderID defaults to 1

### 2.2 Join Semantics

**What**: Consumed via LEFT JOIN on InstrumentID; provider may be matched from the position.

**Rules**:
- History.GetNetProfitForDealing joins on InstrumentID only
- History.GetOnePipValueDollarForDealing may join on InstrumentID; ProviderID passed separately

---

## 3. Data Overview

| InstrumentID | Bid | Ask | ProviderID |
|--------------|-----|-----|------------|
| 1 | 1.3908 | 1.3908 | 1 |
| 2 | 1.6636 | 1.6636 | 1 |
| 3 | 0.8532 | 0.8532 | 1 |
| 4 | 1.1098 | 1.1098 | 1 |
| 1042 | 73.87 | 82.75 | 1 |
| 1046 | 220.66 | 220.89 | 1 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | VERIFIED | Instrument. References Trade.Instrument.InstrumentID |
| 2 | Bid | dtPrice | YES | - | VERIFIED | Last-week bid price |
| 3 | Ask | dtPrice | YES | - | VERIFIED | Last-week ask price |
| 4 | ProviderID | int | NO | 1 | VERIFIED | Price provider. References Trade.Provider |

---

## 5. Relationships

### 5.1 References To

| Referenced Table | Column | Relationship |
|------------------|--------|--------------|
| Trade.Instrument | InstrumentID | Implicit |
| Trade.Provider | ProviderID | Implicit |

### 5.2 Referenced By

| Referencing Object | Column | Type |
|--------------------|--------|------|
| History.GetNetProfitForDealing | LastWeekPrices | LEFT JOIN on InstrumentID for P&L |
| History.GetOnePipValueDollarForDealing | LastWeekPrices | Price lookup for pip value |

---

## 6. Dependencies

### 6.1 Depends On

| Object | Purpose |
|--------|---------|
| Trade.Instrument | InstrumentID domain |
| Trade.Provider | ProviderID domain |

### 6.2 Depended On By

| Object | Purpose |
|--------|---------|
| History.GetNetProfitForDealing | Fallback price for unrealized P&L |
| History.GetOnePipValueDollarForDealing | Fallback price for pip value in USD |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Notes |
|------------|------|-------------|-------|
| (none) | - | - | No indexes; consider (InstrumentID, ProviderID) for lookups |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| DF_TradeLastWeekPrices_ProviderID | DEFAULT | ProviderID = 1 |

---

## 8. Sample Queries

```sql
SELECT InstrumentID, Bid, Ask, ProviderID
FROM Trade.LastWeekPrices WITH (NOLOCK)
WHERE InstrumentID = 1;

SELECT lwp.InstrumentID, lwp.Bid, lwp.Ask, i.InstrumentName
FROM Trade.LastWeekPrices lwp WITH (NOLOCK)
JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = lwp.InstrumentID
WHERE lwp.ProviderID = 1
ORDER BY lwp.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

- No Jira/Confluence references found in this documentation pass.

---

*Generated: 2026-03-14 | Quality: 7.5/10*
