# Trade.GetInstrumentAssetClassMappingsByIds

> Returns InstrumentTypeID (asset class) for a batch of instrument IDs using a table-valued parameter.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (input and output key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure maps a batch of instrument IDs to their asset class (InstrumentTypeID) from Trade.InstrumentMetaData. It accepts a table-valued parameter (TVP) of type `dbo.IdIntList` containing the instrument IDs to look up, copies them into a temp table with a clustered PK for efficient joining, and returns the InstrumentID-to-InstrumentTypeID mapping.

The procedure exists to support bulk asset class resolution without needing individual lookups. Services that process multiple instruments (portfolio, risk, reporting) use this to classify instruments by type (stocks, crypto, forex, etc.) in a single call.

Data flow: caller passes @InstrumentIds TVP. The SP copies IDs to a clustered #InstrumentIds temp table, joins to Trade.InstrumentMetaData, and returns InstrumentID + InstrumentTypeID pairs.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple batch lookup. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentIds | dbo.IdIntList (TVP) | NO (READONLY) | - | CODE-BACKED | Table-valued parameter containing instrument IDs to look up. Each row has an ID column (INT). |
| 2 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Financial instrument identifier. FK to Trade.Instrument. |
| 3 | InstrumentTypeID (output) | INT | NO | - | CODE-BACKED | Asset class classification from Trade.InstrumentMetaData. Maps to Dictionary.InstrumentType (e.g., 1=Indices, 2=Commodities, 4=Currencies, 5=Stocks, 6=ETFs, 10=Crypto, 11=Futures). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentMetaData | JOIN | Source of InstrumentTypeID for each instrument |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentAssetClassMappingsByIds (procedure)
+-- Trade.InstrumentMetaData (table)
+-- dbo.IdIntList (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | JOIN - source of InstrumentTypeID |
| dbo.IdIntList | User Defined Type | TVP parameter type for @InstrumentIds |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Creates temp table #InstrumentIds with clustered PK for join efficiency.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute with TVP

```sql
DECLARE @Ids dbo.IdIntList;
INSERT INTO @Ids (ID) VALUES (1001), (1002), (1003);
EXEC Trade.GetInstrumentAssetClassMappingsByIds @InstrumentIds = @Ids;
```

### 8.2 Direct query equivalent

```sql
SELECT  InstrumentID, InstrumentTypeID
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
WHERE   InstrumentID IN (1001, 1002, 1003);
```

### 8.3 Join with instrument type names

```sql
SELECT  imd.InstrumentID, imd.InstrumentTypeID, it.InstrumentTypeName
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN    Dictionary.InstrumentType it WITH (NOLOCK) ON imd.InstrumentTypeID = it.InstrumentTypeID
WHERE   imd.InstrumentID IN (1001, 1002, 1003);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentAssetClassMappingsByIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentAssetClassMappingsByIds.sql*
