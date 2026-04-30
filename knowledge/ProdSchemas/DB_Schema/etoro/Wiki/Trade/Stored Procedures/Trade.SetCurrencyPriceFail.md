# Trade.SetCurrencyPriceFail

> Records a failed price feed event into History.CurrencyPriceFail with the instrument, provider, bid/ask, source timestamp, and failure reason for monitoring and diagnostics.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID + @ProviderID + @Reason - identifies the failed price event |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When the price feed system receives a price tick that cannot be applied to `Trade.CurrencyPrice` (due to validation failure, stale price, out-of-bounds value, or other rejection), this procedure logs the rejected tick to `History.CurrencyPriceFail` for monitoring and post-mortem analysis.

The procedure is a pure audit trail writer - it only performs an INSERT with no conditional logic. The caller decides whether to invoke it; this procedure simply persists the failure record. The `Reason` field captures a human-readable or system-generated description of why the price tick was rejected.

This serves as the error-path counterpart to `Trade.SetCurrencyPrice` (the success-path writer) and `Trade.SetCurrencyPriceHistoryInsert_New` (the main price update procedure).

---

## 2. Business Logic

### 2.1 Failed Price Event Logging

**What**: Inserts a single record capturing the rejected price tick details.

**Columns/Parameters Involved**: `History.CurrencyPriceFail` all columns

**Rules**:
- Simple INSERT with no validation logic
- RETURN @@ERROR (legacy pattern - returns 0 on success, error number on failure)
- No transaction; single INSERT is atomic

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | The instrument for which the price tick was rejected. |
| 2 | @ProviderID | INTEGER | NO | - | CODE-BACKED | The liquidity provider that sent the rejected price tick. |
| 3 | @Bid | dtPrice | NO | - | CODE-BACKED | The bid price from the rejected tick (custom dtPrice type). Stored for diagnostic purposes. |
| 4 | @Ask | dtPrice | NO | - | CODE-BACKED | The ask price from the rejected tick. Stored for diagnostic purposes. |
| 5 | @OccurredOnServer | DATETIME | NO | - | CODE-BACKED | Timestamp from the source price server when the rejected tick was generated. |
| 6 | @Reason | VARCHAR(255) | NO | - | CODE-BACKED | Human-readable or system description of why this price tick was rejected/failed. Used for monitoring and alerting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | History.CurrencyPriceFail | Writer | Appends the failed price event record to the history table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called by price feed ingestion service on rejection/validation failure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetCurrencyPriceFail (procedure)
|- History.CurrencyPriceFail (table - insert target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CurrencyPriceFail | Table | INSERT target for failed price tick audit records |

### 6.2 Objects That Depend On This

No dependents found - called by price feed service on failure path.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Legacy error return | Pattern | RETURN @@ERROR - legacy pattern; modern equivalent uses THROW. Returns 0 on success. |

---

## 8. Sample Queries

### 8.1 Log a failed price event

```sql
EXEC Trade.SetCurrencyPriceFail
    @InstrumentID = 1234,
    @ProviderID = 5,
    @Bid = 0.0,
    @Ask = 0.0,
    @OccurredOnServer = '2026-03-17 10:30:00',
    @Reason = 'Bid/Ask is zero - rejected'
```

### 8.2 Review recent price feed failures

```sql
SELECT TOP 100 InstrumentID, ProviderID, Bid, Ask, OccurredOnServer, Reason
FROM History.CurrencyPriceFail WITH (NOLOCK)
ORDER BY OccurredOnServer DESC
```

### 8.3 Failure frequency by instrument and reason

```sql
SELECT InstrumentID, ProviderID, Reason, COUNT(*) AS FailureCount
FROM History.CurrencyPriceFail WITH (NOLOCK)
WHERE OccurredOnServer >= DATEADD(HOUR, -24, GETUTCDATE())
GROUP BY InstrumentID, ProviderID, Reason
ORDER BY FailureCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetCurrencyPriceFail | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetCurrencyPriceFail.sql*
