# History.OrdersMarketFail

> Synonym aliasing the DB_Logs database table that stores orders that failed specifically due to market-side conditions (price moves, market closed, liquidity unavailable), distinct from system or validation failures.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DB_Logs].[History].[OrdersMarketFail] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.OrdersMarketFail` is a synonym pointing to `[DB_Logs].[History].[OrdersMarketFail]` in the `DB_Logs` database. The target table stores orders that failed due to market-side conditions - as opposed to system failures, validation errors, or internal rejections captured in `History.OrdersFail`.

Market-side failures include: the requested price moved outside the acceptable range before execution (slippage), the market was closed when the order was processed, insufficient liquidity was available at the requested price, or the instrument was in a halt state. These failure types are distinguished from non-market failures because they require different remediation: market failures may be automatically retried when conditions improve, while system failures require investigation.

The separation of `OrdersFail` (all failures) and `OrdersMarketFail` (market-condition-specific failures) supports targeted monitoring: alerts on `OrdersMarketFail` spikes indicate market volatility or provider issues, while alerts on `OrdersFail` indicate system or configuration problems.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See `[DB_Logs].[History].[OrdersMarketFail]` for the market failure event structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[DB_Logs].[History].[OrdersMarketFail]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table `[DB_Logs].[History].[OrdersMarketFail]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DB_Logs].[History].[OrdersMarketFail] | Synonym | Points to the market-condition order failure log in DB_Logs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OrdersMarketFail (synonym)
+-- [DB_Logs].[History].[OrdersMarketFail] (external table - DB_Logs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DB_Logs].[History].[OrdersMarketFail] | External Table | Target of this synonym |

### 6.2 Objects That Depend On This

No dependents found in local schema analysis.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query market-condition order failures

```sql
SELECT TOP 10 *
FROM History.OrdersMarketFail WITH (NOLOCK)
```

### 8.2 Proportion of market vs total failures

```sql
SELECT
    (SELECT COUNT(*) FROM History.OrdersMarketFail WITH (NOLOCK)) AS MarketFails,
    (SELECT COUNT(*) FROM History.OrdersFail WITH (NOLOCK)) AS TotalFails
```

### 8.3 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'OrdersMarketFail'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrdersMarketFail | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.OrdersMarketFail.sql*
