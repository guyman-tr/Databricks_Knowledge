# Trade.GetForexRates

> Returns forex rates (Name, Bid, Ask) by joining current price, provider-to-instrument mapping, instrument, and spread group data. No parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Name, Bid, Ask per instrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides forex rates for display or downstream processing. It returns instrument name plus Bid and Ask prices. The rates are derived from Trade.GetCurrentPrice combined with spread group logic. SpreadGroupID=0 is used for default spread when no specific spread group applies.

The procedure exists to centralize forex rate retrieval for API consumers and internal services. Without it, each consumer would need to replicate the price-plus-spread logic.

Data flows from Trade.GetCurrentPrice (base price), Trade.GetProviderToInstrument, Trade.GetInstrument, and Trade.GetSpreadGroup. These may be synonyms or views rather than base tables. Bid and Ask are calculated by applying spread to the base price with precision handling.

---

## 2. Business Logic

### 2.1 Bid and Ask Calculation from Base Price

**What**: Bid and Ask are computed by adding or subtracting spread from the base price.

**Columns/Parameters Involved**: `Bid`, `Ask`, base price, spread

**Rules**:
- Base price comes from Trade.GetCurrentPrice
- Spread comes from Trade.GetSpreadGroup (SpreadGroupID=0 for default)
- Bid and Ask formulas apply spread with appropriate precision handling
- The procedure ensures decimal precision is preserved for financial display

### 2.2 Default Spread Group

**What**: SpreadGroupID=0 is used for the default spread when no instrument-specific spread group exists.

**Columns/Parameters Involved**: `SpreadGroupID`

**Rules**:
- When SpreadGroupID=0, the default spread group is applied
- Ensures every instrument has a fallback spread for Bid/Ask calculation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Name | VARCHAR | NO | - | CODE-BACKED | Instrument display name from Trade.GetInstrument. |
| 2 | Bid | DECIMAL | NO | - | CODE-BACKED | Bid price. Base price minus half-spread (or equivalent formula). |
| 3 | Ask | DECIMAL | NO | - | CODE-BACKED | Ask price. Base price plus half-spread (or equivalent formula). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.GetCurrentPrice | JOIN/CALL | Base price source |
| (body) | Trade.GetProviderToInstrument | JOIN | Provider-instrument mapping |
| (body) | Trade.GetInstrument | JOIN | Instrument details including Name |
| (body) | Trade.GetSpreadGroup | JOIN | Spread for Bid/Ask calculation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetForexRates (procedure)
+-- Trade.GetCurrentPrice (view/function)
+-- Trade.GetProviderToInstrument (view/table)
+-- Trade.GetInstrument (view/table)
+-- Trade.GetSpreadGroup (view/table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCurrentPrice | View/Function | Base price for rate calculation |
| Trade.GetProviderToInstrument | View/Table | Provider-to-instrument mapping |
| Trade.GetInstrument | View/Table | Instrument Name and metadata |
| Trade.GetSpreadGroup | View/Table | Spread for Bid/Ask (SpreadGroupID=0 default) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Trade.GetForexRates;
```

### 8.2 Capture results and compute mid-rate

```sql
DECLARE @Rates TABLE (Name VARCHAR(100), Bid DECIMAL(28,8), Ask DECIMAL(28,8));
INSERT INTO @Rates EXEC Trade.GetForexRates;

SELECT  Name, Bid, Ask, (Bid + Ask) / 2 AS MidRate
FROM    @Rates;
```

### 8.3 Query via OPENQUERY or table variable if needed

```sql
DECLARE @Rates TABLE (Name VARCHAR(100), Bid DECIMAL(28,8), Ask DECIMAL(28,8));
INSERT INTO @Rates EXEC Trade.GetForexRates;
SELECT * FROM @Rates WITH (NOLOCK) WHERE Name LIKE 'EUR%';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetForexRates | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetForexRates.sql*
