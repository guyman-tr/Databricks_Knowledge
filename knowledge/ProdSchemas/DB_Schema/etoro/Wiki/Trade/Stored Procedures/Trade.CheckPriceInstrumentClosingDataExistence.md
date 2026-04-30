# Trade.CheckPriceInstrumentClosingDataExistence

> Returns a BIT flag indicating whether closing price source data exists for a given instrument in Trade.InstrumentClosingPriceSourceData.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckPriceInstrumentClosingDataExistence is a simple existence-check procedure used to determine whether an instrument has closing price source data configured. Closing price source data is used in end-of-day settlement and overnight fee calculations. This check is typically called before instrument operations that require closing prices to be available.

---

## 2. Business Logic

### 2.1 Closing Price Data Existence Check

**What**: Returns 1 if Trade.InstrumentClosingPriceSourceData has at least one row for the given InstrumentID, 0 otherwise.

**Columns/Parameters Involved**: `@InstrumentID`, `Trade.InstrumentClosingPriceSourceData.InstrumentID`

**Rules**:
- Single EXISTS subquery, cast to BIT
- No filtering beyond InstrumentID match

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument to check for closing price source data. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | IsInstrumentClosingPriceSourceDataExists | BIT | NO | - | CODE-BACKED | 1 if closing price source data exists, 0 otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentClosingPriceSourceData | EXISTS check | Checks if instrument has closing price source data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price/instrument management | (external) | EXEC | Pre-check before operations requiring closing prices |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckPriceInstrumentClosingDataExistence (procedure)
+-- Trade.InstrumentClosingPriceSourceData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentClosingPriceSourceData | Table | EXISTS check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price management tooling | External | Closing price validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check closing price data existence

```sql
EXEC Trade.CheckPriceInstrumentClosingDataExistence @InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 4.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CheckPriceInstrumentClosingDataExistence | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CheckPriceInstrumentClosingDataExistence.sql*
