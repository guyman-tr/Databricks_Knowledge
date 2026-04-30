# Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds

> Returns the pip difference threshold for instruments, optionally filtered by exchange IDs, enabling the Dealing Front to monitor price feed deviations per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + PipDifferenceThreshold from Trade.GetInstrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds returns the pip difference threshold for instruments, used to detect when price feeds from different sources diverge beyond acceptable limits. The PipDifferenceThreshold defines the maximum allowed pip spread between primary and secondary price feeds before an alert is triggered.

This procedure exists because the Dealing Front (surveillance platform) needs to monitor price feed integrity per instrument. Different exchanges and instrument types have different acceptable deviation thresholds. The optional exchange filter allows dealers to focus on instruments from specific exchanges.

When @Exchanges is NULL, all instruments are returned. When provided as a comma-separated list, only instruments on those exchanges are returned. Called by PROD\SQL_Dealing-Front.

---

## 2. Business Logic

### 2.1 Optional Exchange Filtering with Temp Table Optimization

**What**: Supports both all-instruments and exchange-filtered queries using conditional branching.

**Columns/Parameters Involved**: `@Exchanges`, `Trade.GetInstrument.ExchangeID`, `Trade.GetInstrument.PipDifferenceThreshold`

**Rules**:
- @Exchanges = NULL: returns ALL instruments and their PipDifferenceThreshold from Trade.GetInstrument (view)
- @Exchanges = "1,5,12": parses via STRING_SPLIT, creates a #ExchangeIds temp table with PK, then JOINs to filter
- Temp table with PRIMARY KEY ensures efficient JOIN performance for large exchange sets
- DROP TABLE IF EXISTS provides re-runnability within a session

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Exchanges | nvarchar(MAX) | YES | NULL | CODE-BACKED | Optional comma-separated list of exchange IDs (e.g., "1,5,12"). When NULL, returns all instruments. When provided, filters to instruments on specified exchanges. Parsed via STRING_SPLIT. |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.GetInstrument.InstrumentID | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. |
| R2 | PipDifferenceThreshold | decimal | Trade.GetInstrument.PipDifferenceThreshold | CODE-BACKED | Maximum allowed pip difference between primary and secondary price feeds before a price discrepancy alert fires. Higher values allow more deviation (volatile instruments); lower values trigger alerts sooner (stable instruments). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.GetInstrument | Read (SELECT) | View providing instrument data including PipDifferenceThreshold and ExchangeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD\SQL_Dealing-Front | EXECUTE | Permission | Dealing Front surveillance platform for price feed monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds (procedure)
+-- Trade.GetInstrument (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | SELECT - source of InstrumentID, PipDifferenceThreshold, ExchangeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD\SQL_Dealing-Front | DB User | EXECUTE permission for price feed monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get thresholds for all instruments

```sql
EXEC Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds;
```

### 8.2 Get thresholds for specific exchanges

```sql
EXEC Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds @Exchanges = '1,5,12';
```

### 8.3 Find instruments with tight thresholds

```sql
SELECT  InstrumentID, PipDifferenceThreshold
FROM    Trade.GetInstrument WITH (NOLOCK)
WHERE   PipDifferenceThreshold < 5
ORDER BY PipDifferenceThreshold;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.1/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsPipDifferenceThresholdByExchangeIds.sql*
