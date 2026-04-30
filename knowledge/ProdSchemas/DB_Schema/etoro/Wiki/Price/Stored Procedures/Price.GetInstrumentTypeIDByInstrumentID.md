# Price.GetInstrumentTypeIDByInstrumentID

> Single-value lookup that returns the InstrumentTypeID for a given InstrumentID from Trade.InstrumentMetaData - a focused helper for instrument type resolution in the pricing pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetInstrumentTypeIDByInstrumentID is a minimal lookup procedure that resolves an instrument's type from its ID. When the pricing engine or configuration service has an InstrumentID and needs to know its type category (forex, stock, crypto, etc.), it calls this procedure rather than joining InstrumentMetaData directly.

This procedure exists to encapsulate the instrument type lookup behind a named interface, enabling the pricing service to use a consistent API call for type resolution without embedding the join logic.

The result (InstrumentTypeID) determines downstream behavior: different instrument types are priced differently (forex uses mid-price, stocks use last trade, etc.), and the type governs which pricing algorithm applies.

---

## 2. Business Logic

### 2.1 Simple Type Lookup

**What**: Returns the single InstrumentTypeID column for the specified instrument.

**Rules**:
- No error handling - if @InstrumentID does not exist in Trade.InstrumentMetaData, returns empty result set (0 rows)
- WITH (NOLOCK) - no locking; consistent with Price schema read pattern
- Returns 0 or 1 rows (1 row if InstrumentID exists, 0 if not)
- No transaction, no SET NOCOUNT ON (unlike most Price SPs)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The instrument to look up. Matched against Trade.InstrumentMetaData.InstrumentID. No validation performed - non-existent ID returns empty result set. |

**Result set** (1 column):

| Column | Description |
|--------|-------------|
| InstrumentTypeID | The instrument type classification. Common values: 1=Currency pairs (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETFs, 10=Crypto. Sourced from Trade.InstrumentMetaData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentMetaData | READER | Single-row lookup by InstrumentID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing engine / configuration service) | @InstrumentID | CALLER | Called to resolve instrument type for routing/pricing logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetInstrumentTypeIDByInstrumentID (procedure)
+-- Trade.InstrumentMetaData (table) - type lookup
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | SELECT source - returns InstrumentTypeID for the given InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing engine) | External | Calls to resolve instrument type from ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON (unlike most Price SPs - returns row count message). No error handling. No transaction. One of the simplest procedures in the Price schema - a pure single-column lookup.

---

## 8. Sample Queries

### 8.1 Get instrument type for a specific instrument

```sql
EXEC Price.GetInstrumentTypeIDByInstrumentID @InstrumentID = 1;
-- Returns: InstrumentTypeID = 1 (Currency pair / forex)
```

### 8.2 Equivalent manual query

```sql
SELECT imd.InstrumentTypeID
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
WHERE imd.InstrumentID = 1;
```

### 8.3 Batch resolve instrument types (for multiple instruments)

```sql
SELECT InstrumentID, InstrumentTypeID
FROM Trade.InstrumentMetaData WITH (NOLOCK)
WHERE InstrumentID IN (1, 2, 3, 4, 5)
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetInstrumentTypeIDByInstrumentID | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetInstrumentTypeIDByInstrumentID.sql*
