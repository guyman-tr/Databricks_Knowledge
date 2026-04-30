# Trade.InterestDaily

> Synonym pointing to the InterestDaily table in the Interest database (InterestAzure linked server), providing access to daily interest/overnight fee rate data for trading positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [InterestAzure].[Interest].[Trade].[InterestDaily] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InterestDaily provides local access to the InterestDaily table in the Interest database on InterestAzure. This table stores daily interest rate data (also known as overnight fees or swap rates) that are applied to trading positions held overnight. These fees are a core revenue component of the trading platform.

Overnight/weekend fees are charged to customers who hold leveraged positions past the market close. The rates vary by instrument, direction (buy/sell), and leverage level. This synonym enables the Trade schema to access the centralized interest rate data without cross-database four-part naming.

No direct consumers found in the SSDT codebase - the synonym is likely used by fee calculation jobs or reporting processes.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 3.

---

## 3. Data Overview

N/A for synonym.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [InterestAzure].[Interest].[Trade].[InterestDaily]. Stores daily overnight/swap fee rates per instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [InterestAzure].[Interest].[Trade].[InterestDaily] | Synonym target | Cross-database reference to Interest database daily rates |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely consumed by fee calculation processes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InterestDaily (synonym)
  +-- [InterestAzure].[Interest].[Trade].[InterestDaily] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [InterestAzure].[Interest].[Trade].[InterestDaily] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query recent daily interest rates
```sql
SELECT TOP 10 * FROM Trade.InterestDaily WITH (NOLOCK) ORDER BY 1 DESC
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'InterestDaily' AND schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check connectivity
```sql
SELECT TOP 1 1 AS IsReachable FROM Trade.InterestDaily WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InterestDaily | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.InterestDaily.sql*
