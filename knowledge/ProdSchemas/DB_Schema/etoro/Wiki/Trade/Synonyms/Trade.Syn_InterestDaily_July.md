# Trade.Syn_InterestDaily_July

> Synonym pointing to the InterestDaily_July table in the InterestAzure database, enabling the Trade schema to access daily interest rate data for the July calculation period.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [InterestAzure].[Interest].[Trade].[InterestDaily_July] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.Syn_InterestDaily_July is a synonym that provides local access to the InterestDaily_July table in the InterestAzure database. This table stores daily interest rate calculations specific to the July billing period, used in the overnight interest/swap fee computation for trading positions.

The synonym exists because interest rate calculations are offloaded to a dedicated Azure database (InterestAzure) for scalability. The Trade schema needs to read interest data for fee computations and reporting, and this synonym eliminates four-part naming in consuming procedures.

Trade.GetInterestDaily_for_Azure is the primary consumer, reading interest rate data through this synonym for Azure-based interest calculations.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Business logic resides in the interest calculation procedures in the InterestAzure database.

---

## 3. Data Overview

N/A for synonym (targets a table in an external database).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [InterestAzure].[Interest].[Trade].[InterestDaily_July]. A table storing daily interest rate data for the July calculation period, used in overnight swap/interest fee processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [InterestAzure].[Interest].[Trade].[InterestDaily_July] | Synonym target | Cross-database reference to the July interest rate data in the InterestAzure database |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInterestDaily_for_Azure | SELECT | Reader | Reads daily interest rate data through this synonym for Azure-based interest calculations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Syn_InterestDaily_July (synonym)
  +-- [InterestAzure].[Interest].[Trade].[InterestDaily_July] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [InterestAzure].[Interest].[Trade].[InterestDaily_July] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInterestDaily_for_Azure | Stored Procedure | Reads interest rate data for Azure-based calculations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

N/A for synonym.

---

## 8. Sample Queries

### 8.1 Verify synonym target
```sql
SELECT name, base_object_name
FROM   sys.synonyms WITH (NOLOCK)
WHERE  name = 'Syn_InterestDaily_July'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.Syn_InterestDaily_July') AS ObjectID
```

### 8.3 Preview interest data (if accessible)
```sql
SELECT TOP 10 *
FROM   Trade.Syn_InterestDaily_July WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Syn_InterestDaily_July | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.Syn_InterestDaily_July.sql*
