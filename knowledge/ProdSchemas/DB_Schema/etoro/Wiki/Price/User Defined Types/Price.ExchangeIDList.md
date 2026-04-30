# Price.ExchangeIDList

> Single-column table-valued parameter (TVP) for passing a batch of exchange IDs to stored procedures, enabling set-based filtering of OMPD threshold data by exchange.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | ExchangeID (the sole column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the input contract for `Price.GetInstrumentsOMPDThresholdByExchangeIds`. It allows callers to pass a set of exchange IDs (e.g., NYSE, NASDAQ, LSE) in a single parameter, so the procedure can return OMPD (Order Margin Price Deviation) threshold data for all instruments belonging to those exchanges in one call.

Without this type, callers would need to either pass a comma-delimited string (requiring parsing) or call the procedure once per exchange ID. The TVP enables a clean, type-safe, set-based operation.

Data flows from the calling application -> this TVP (@Exchanges parameter) -> `GetInstrumentsOMPDThresholdByExchangeIds` -> result set of OMPD thresholds filtered to the specified exchanges.

---

## 2. Business Logic

### 2.1 Set-Based Exchange Filtering

**What**: Enables filtering OMPD threshold queries by a caller-supplied set of exchange identifiers.

**Columns/Parameters Involved**: `ExchangeID`

**Rules**:
- ExchangeID values must correspond to valid entries in Price.Exchange (validated implicitly by JOIN in the consuming SP)
- The TVP accepts any number of rows (from 1 to all exchanges)
- Duplicate ExchangeID values in the TVP are handled by the consuming SP's JOIN logic

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NOT NULL | - | CODE-BACKED | Identifier of a trading exchange (e.g., NYSE, NASDAQ, LSE). NOT NULL - every row must represent a valid exchange. References Price.Exchange.ExchangeID implicitly via the consuming SP's JOIN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetInstrumentsOMPDThresholdByExchangeIds | @Exchanges | TVP Parameter | Filters OMPD threshold result set to instruments belonging to the provided exchange IDs |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetInstrumentsOMPDThresholdByExchangeIds | Stored Procedure | Declares @Exchanges as this type READONLY; JOINs to filter OMPD thresholds by exchange |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ExchangeID NOT NULL | NOT NULL | Exchange identification is required; null exchange IDs are not valid filter criteria |

---

## 8. Sample Queries

### 8.1 Get OMPD thresholds for a set of exchanges

```sql
DECLARE @Exchanges Price.ExchangeIDList;
INSERT INTO @Exchanges (ExchangeID) VALUES (1), (2), (5);
EXEC Price.GetInstrumentsOMPDThresholdByExchangeIds @Exchanges = @Exchanges;
```

### 8.2 Get all exchange IDs available

```sql
SELECT ExchangeID, ExchangeName
FROM Price.Exchange WITH (NOLOCK)
ORDER BY ExchangeID;
```

### 8.3 Use TVP for a single exchange lookup

```sql
DECLARE @Exchanges Price.ExchangeIDList;
INSERT INTO @Exchanges VALUES (3);
EXEC Price.GetInstrumentsOMPDThresholdByExchangeIds @Exchanges = @Exchanges;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.ExchangeIDList | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.ExchangeIDList.sql*
