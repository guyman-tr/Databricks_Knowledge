# BackOffice.GetCurrentRates

> Returns the current bid/ask and discounted bid/ask rates for a single instrument from the live price feed, used to display instrument prices in the BackOffice manual-close trade workflow.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - returns one row per instrument from Trade.CurrencyPrice |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure fetches the current market rates for a specific trading instrument directly from the live price table (`Trade.CurrencyPrice`). It returns four price points: the standard Bid/Ask spread and the discounted Bid/Ask spread applicable to specific account types or promotions.

The procedure was created in September 2020 (MIMOPS-2247) as part of the "Adjustment to close trade option from BackOffice" feature (parent: MIMOPSA-2104 / OPS01140). When a BackOffice agent manually closes a customer trade, the UI needs to display the current market price for the instrument so the agent can see the rate at which the close will execute. This SP is that price-lookup call.

It is intentionally minimal - no filtering by customer, no historical data, no aggregation. The single-instrument lookup is the complete requirement.

---

## 2. Business Logic

### 2.1 Live Price Lookup - No History

**What**: Reads directly from Trade.CurrencyPrice, which holds the current (last-updated) price for each instrument.

**Columns/Parameters Involved**: `@InstrumentID`, `Trade.CurrencyPrice`

**Rules**:
- Returns the row from Trade.CurrencyPrice matching @InstrumentID
- Trade.CurrencyPrice stores the latest price snapshot; it is not a historical table
- If @InstrumentID has no matching row (instrument not priced), returns zero rows

### 2.2 Standard vs Discounted Rates

**What**: Two bid/ask pairs are returned - standard and discounted.

**Columns/Parameters Involved**: `Bid`, `Ask`, `BidDiscounted`, `AskDiscounted`

**Rules**:
- `Bid`/`Ask`: The standard market rates at which trades are executed for regular accounts
- `BidDiscounted`/`AskDiscounted`: Reduced spread rates applied to specific account tiers or promotional configurations
- The discounted rates represent a tighter spread (lower cost to trade) for eligible customers

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The unique identifier of the trading instrument to price. FK to Trade.CurrencyPrice.InstrumentID. Returns zero rows if the instrument has no current price record. |
| **Output Columns** | | | | | | |
| 2 | Bid | DECIMAL | YES | - | CODE-BACKED | The current bid price for the instrument (price at which customers can sell). From Trade.CurrencyPrice.Bid. Standard (non-discounted) rate. |
| 3 | Ask | DECIMAL | YES | - | CODE-BACKED | The current ask price for the instrument (price at which customers can buy). From Trade.CurrencyPrice.Ask. Standard (non-discounted) rate. |
| 4 | BidDiscounted | DECIMAL | YES | - | CODE-BACKED | The discounted bid price for the instrument. From Trade.CurrencyPrice.BidDiscounted. Applied to accounts with tighter spread eligibility. |
| 5 | AskDiscounted | DECIMAL | YES | - | CODE-BACKED | The discounted ask price for the instrument. From Trade.CurrencyPrice.AskDiscounted. Applied to accounts with tighter spread eligibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.CurrencyPrice | Direct READ | Primary and only source - live price snapshot for the instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Called by BackOffice UI to display current instrument price when an agent initiates a manual trade close (MIMOPS-2247 / OPS01140) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCurrentRates (procedure)
+-- Trade.CurrencyPrice (table - live instrument prices)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | Only source - provides Bid, Ask, BidDiscounted, AskDiscounted for @InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Reads current rates for display in manual-close trade workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get current rates for a specific instrument

```sql
-- Get current rates for EURUSD (InstrumentID example)
EXEC BackOffice.GetCurrentRates @InstrumentID = 1;
```

### 8.2 Direct source query

```sql
SELECT Bid, Ask, BidDiscounted, AskDiscounted
FROM Trade.CurrencyPrice WITH (NOLOCK)
WHERE InstrumentID = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-2247 - DB work | Jira (Sub-Dev task) | Created by Shay Oren, Sep 2020. Sub-task of MIMOPSA-2104 (OPS01140 - Adjustment to close trade option from BO). Confirms this SP was built specifically to support the BackOffice manual trade close feature. Status: Done. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCurrentRates | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCurrentRates.sql*
