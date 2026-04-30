# Trade.FutureInstruments

> Synonym pointing to the FutureInstruments table in the DividendsAzure linked server, providing access to future instrument definitions used in dividend calculations for futures/forward contracts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [DividendsAzure].[Dividends].[Trade].[FutureInstruments] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FutureInstruments provides local access to the FutureInstruments table in the Dividends database on DividendsAzure. This table stores definitions of future/forward contract instruments that are relevant to dividend processing - such as index futures where dividend adjustments affect contract pricing.

The synonym is consumed by Trade.GetMarketCloseTimeByExDate (the production version), which needs to look up future instrument details when calculating market close times for ex-dividend date processing of futures contracts.

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
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [DividendsAzure].[Dividends].[Trade].[FutureInstruments]. Stores future/forward contract instrument definitions relevant to dividend processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [DividendsAzure].[Dividends].[Trade].[FutureInstruments] | Synonym target | Cross-database reference to futures instrument definitions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetMarketCloseTimeByExDate | FROM/JOIN | Reader | Looks up future instrument details for ex-date processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FutureInstruments (synonym)
  +-- [DividendsAzure].[Dividends].[Trade].[FutureInstruments] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DividendsAzure].[Dividends].[Trade].[FutureInstruments] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMarketCloseTimeByExDate | Function | Reads future instrument data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query future instruments
```sql
SELECT TOP 10 * FROM Trade.FutureInstruments WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'FutureInstruments' AND schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check connectivity
```sql
SELECT TOP 1 1 AS IsReachable FROM Trade.FutureInstruments WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FutureInstruments | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.FutureInstruments.sql*
