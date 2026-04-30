# Price.GetNonExpiredFutures

> Returns all futures instruments whose ExpirationDateTime has not yet passed (>= GETUTCDATE()), providing the pricing engine with the current set of active futures contracts that still require live price feeds.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - time-based filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetNonExpiredFutures returns the list of futures contracts that are still active (not yet expired) as of the current UTC time. Futures instruments have a fixed `ExpirationDateTime` - after that date, the contract is settled and no longer requires live price data. This procedure identifies which futures contracts the pricing engine should still be feeding prices for.

This procedure exists so the pricing infrastructure can dynamically determine which futures instruments need active price feeds. By calling GetNonExpiredFutures, the pricing engine knows exactly which futures to include in its feed routing configuration. Expired futures can safely be ignored/delisted.

The data comes from `Trade.FuturesMetaData` which stores the per-contract expiration timestamp. Only rows where ExpirationDateTime >= GETUTCDATE() (current UTC time) are returned.

---

## 2. Business Logic

### 2.1 Time-Based Active Contract Filter

**What**: The WHERE clause uses GETUTCDATE() to determine which contracts are still active.

**Columns/Parameters Involved**: `ExpirationDateTime`

**Rules**:
- `WHERE ExpirationDateTime >= GETUTCDATE()` - uses UTC time (consistent with eToro's UTC-based timestamps)
- Contracts that expire exactly at GETUTCDATE() (same second) are still included (>= not >)
- Contracts where ExpirationDateTime < GETUTCDATE() are expired and excluded
- NULL ExpirationDateTime rows: FuturesMetaData requires ExpirationDateTime NOT NULL - no null filtering needed
- Uses (NOLOCK) - no locking required for this read

### 2.2 Minimal Output

**What**: Returns only InstrumentID and ExpirationDateTime - the minimum needed by the pricing engine.

**Rules**:
- InstrumentID: used by the pricing engine to match against instrument routing tables
- ExpirationDateTime: included so the caller can also schedule when to deactivate each feed

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No input parameters. Returns all non-expired futures as of current UTC time. |

**Result set columns** (2 columns):

| # | Column | Description |
|---|--------|-------------|
| 1 | InstrumentID | eToro instrument identifier for the futures contract. FK to Trade.Instrument. |
| 2 | ExpirationDateTime | UTC timestamp when this futures contract expires. The pricing engine uses this to schedule feed deactivation when the contract expires. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.FuturesMetaData | READER | Source of futures contract expiration data; filtered by ExpirationDateTime >= GETUTCDATE() |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing engine) | - | CALLER | Called at startup/refresh to determine which futures contracts need active price feeds |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetNonExpiredFutures (procedure)
+-- Trade.FuturesMetaData (table) - active futures contracts
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FuturesMetaData | Table | FROM source - futures instruments filtered by ExpirationDateTime |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing engine) | External | Calls to get the current set of active (non-expired) futures contracts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON. No error handling. Uses (NOLOCK) without WITH keyword syntax (older style but valid). The result changes over time as contracts expire - the same call on different days produces different results. No ORDER BY - result order is nondeterministic.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Price.GetNonExpiredFutures;
```

### 8.2 Equivalent manual query

```sql
SELECT InstrumentID, ExpirationDateTime
FROM Trade.FuturesMetaData WITH (NOLOCK)
WHERE ExpirationDateTime >= GETUTCDATE()
ORDER BY ExpirationDateTime ASC;
```

### 8.3 Count of active vs expired futures

```sql
SELECT
    CASE WHEN ExpirationDateTime >= GETUTCDATE() THEN 'Active' ELSE 'Expired' END AS Status,
    COUNT(*) AS Count
FROM Trade.FuturesMetaData WITH (NOLOCK)
GROUP BY CASE WHEN ExpirationDateTime >= GETUTCDATE() THEN 'Active' ELSE 'Expired' END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetNonExpiredFutures | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetNonExpiredFutures.sql*
