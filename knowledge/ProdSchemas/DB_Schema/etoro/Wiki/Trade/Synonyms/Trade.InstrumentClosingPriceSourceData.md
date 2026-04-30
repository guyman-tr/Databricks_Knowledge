# Trade.InstrumentClosingPriceSourceData

> Synonym pointing to the instrument closing price source data table in the Price database (AO-PRICE-LSN-ROR linked server), providing access to closing price configurations per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AO-PRICE-LSN-ROR].[Price].[Trade].[InstrumentClosingPriceSourceData] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentClosingPriceSourceData provides local access to the InstrumentClosingPriceSourceData table in the Price database on the AO-PRICE-LSN-ROR linked server. This table stores configuration data that defines which price source should be used for determining the official closing price for each instrument - critical for end-of-day valuations, P&L snapshots, and fee calculations.

Different instruments may derive their closing price from different sources (e.g., exchange official close, last trade, VWAP, or a specific liquidity provider). This table maps each instrument to its authoritative closing price source.

Used by Trade.GetInstrumentByCreateData and Trade.CheckAllInstrumentUpload for instrument data validation, and by dbo.Delete_Instrument for cleanup.

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
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [AO-PRICE-LSN-ROR].[Price].[Trade].[InstrumentClosingPriceSourceData]. Stores closing price source configuration per instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [AO-PRICE-LSN-ROR].[Price].[Trade].[InstrumentClosingPriceSourceData] | Synonym target | Cross-database reference to Price database closing price config |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentByCreateData | FROM/JOIN | Reader | Reads closing price source config for instrument validation |
| Trade.CheckAllInstrumentUpload | FROM/JOIN | Reader | Validates closing price source exists during instrument upload |
| dbo.Delete_Instrument | FROM/JOIN | Reader/Writer | Manages closing price config during instrument deletion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentClosingPriceSourceData (synonym)
  +-- [AO-PRICE-LSN-ROR].[Price].[Trade].[InstrumentClosingPriceSourceData] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-PRICE-LSN-ROR].[Price].[Trade].[InstrumentClosingPriceSourceData] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentByCreateData | Stored Procedure | Reads closing price config |
| Trade.CheckAllInstrumentUpload | Stored Procedure | Validates closing price config |
| dbo.Delete_Instrument | Stored Procedure | Manages closing price config during deletion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query closing price sources
```sql
SELECT TOP 10 * FROM Trade.InstrumentClosingPriceSourceData WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'InstrumentClosingPriceSourceData' AND schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check connectivity
```sql
SELECT TOP 1 1 AS IsReachable FROM Trade.InstrumentClosingPriceSourceData WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentClosingPriceSourceData | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.InstrumentClosingPriceSourceData.sql*
