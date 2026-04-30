# Trade.GetLastPriceRateID

> Returns the maximum PriceRateID from the Trade.CurrencyPrice table via an OUTPUT parameter, providing the high-water mark for price feed tracking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT parameter: @LastPriceRateID (BIGINT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLastPriceRateID retrieves the highest PriceRateID value currently stored in Trade.CurrencyPrice. PriceRateID is an auto-incrementing identifier that tracks price update sequence across all instruments and providers. The maximum value represents the most recent price update received by the system.

This procedure exists for BI/analytics and monitoring purposes - it provides a watermark that external consumers (e.g., BI admins) can use to detect if price feeds are flowing or stalled. If the max PriceRateID hasn't changed over a monitoring interval, price feeds may be interrupted.

Called by PROD_BIadmins (BI admin application user). The procedure uses an OUTPUT parameter pattern (rather than a result set), which is typical for simple scalar lookups consumed programmatically.

---

## 2. Business Logic

### 2.1 High-Water Mark Query

**What**: Returns the maximum PriceRateID as a monotonically increasing watermark for price feed tracking.

**Columns/Parameters Involved**: `@LastPriceRateID`, `Trade.CurrencyPrice.PriceRateID`

**Rules**:
- Uses MAX(PriceRateID) with NOLOCK hint for non-blocking reads
- PriceRateID is BIGINT (identity) on Trade.CurrencyPrice - monotonically increasing
- Returns NULL if Trade.CurrencyPrice is empty (edge case - should never happen in production)
- RETURN 0 indicates successful execution

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @LastPriceRateID | bigint | OUTPUT | - | CODE-BACKED | Returns the maximum PriceRateID from Trade.CurrencyPrice - the most recent price update sequence number across all instruments and providers. Used as a high-water mark for price feed monitoring. |

### 4.2 Return Value

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | RETURN | int | CODE-BACKED | Always returns 0 (success). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MAX(PriceRateID) | Trade.CurrencyPrice | SELECT (READER) | Reads the maximum PriceRateID from the live price cache table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | GRANT EXECUTE | Application User | BI admin processes call this for price feed monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLastPriceRateID (procedure)
+-- Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | SELECT MAX(PriceRateID) to get the latest price update watermark |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Application User | Executes for price feed monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get the latest PriceRateID

```sql
DECLARE @lastId BIGINT;
EXEC Trade.GetLastPriceRateID @LastPriceRateID = @lastId OUTPUT;
SELECT @lastId AS LastPriceRateID;
```

### 8.2 Monitor price feed freshness (poll every 30 seconds)

```sql
SELECT  MAX(PriceRateID)    AS CurrentMax,
        MAX(LastUpdate)     AS MostRecentUpdate,
        DATEDIFF(SECOND, MAX(LastUpdate), GETUTCDATE()) AS SecondsSinceLastPrice
FROM    Trade.CurrencyPrice WITH (NOLOCK);
```

### 8.3 Check price rate growth over time

```sql
DECLARE @before BIGINT, @after BIGINT;
EXEC Trade.GetLastPriceRateID @LastPriceRateID = @before OUTPUT;
WAITFOR DELAY '00:00:10';
EXEC Trade.GetLastPriceRateID @LastPriceRateID = @after OUTPUT;
SELECT  @before AS Before,
        @after  AS After,
        @after - @before AS PriceUpdatesIn10Seconds;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetLastPriceRateID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetLastPriceRateID.sql*
