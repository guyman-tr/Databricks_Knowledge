# Trade.GetInstrumentsForSevision

> Returns externally visible instruments with display name, symbol, type, exchange, and tradability status for the Dealing Front (Sevision) trading platform interface.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns instrument display data from Trade.GetInstrumentDataDealing view |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsForSevision is a parameterless getter procedure that returns the instrument catalog for the Dealing Front (Sevision) platform - an internal dealing/surveillance UI used by trading operations. It reads from the Trade.GetInstrumentDataDealing view, which is a pre-built denormalized view of instrument data including display names, symbols, types, exchanges, and tradability status.

This procedure exists because the Dealing Front needs a filtered instrument list that excludes internal-only instruments (VisibleInternallyOnly=0) and synthetic/test instruments (InstrumentID < 1000000). This two-condition filter ensures dealers see only real, externally tradable instruments.

Called by PROD\SQL_Dealing-Front service account. "Sevision" is a legacy name for the dealing/surveillance front-end tool.

---

## 2. Business Logic

### 2.1 External Instrument Filtering

**What**: Filters the full instrument catalog to show only externally visible, non-synthetic instruments.

**Columns/Parameters Involved**: `VisibleInternallyOnly`, `InstrumentID`

**Rules**:
- VisibleInternallyOnly=0 excludes instruments flagged as internal-only (ops/test instruments that real clients cannot see)
- InstrumentID < 1000000 excludes synthetic or auto-generated instruments with IDs in the million+ range
- Both filters applied together ensure dealers see the same instrument universe as external clients

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.GetInstrumentDataDealing.InstrumentID | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. |
| R2 | InstrumentDisplayName | nvarchar | Trade.GetInstrumentDataDealing.InstrumentDisplayName | CODE-BACKED | Human-readable display name (e.g., "Apple Inc.", "Bitcoin"). Shown in the Dealing Front instrument picker. |
| R3 | Symbol | nvarchar | Trade.GetInstrumentDataDealing.Symbol | CODE-BACKED | Trading symbol (e.g., "AAPL", "BTC"). Used for quick instrument identification by dealers. |
| R4 | InstrumentType | nvarchar | Trade.GetInstrumentDataDealing.InstrumentType | CODE-BACKED | Resolved instrument type name (e.g., "Stocks", "Currencies", "Crypto"). From Dictionary.InstrumentType via the view. |
| R5 | Exchange | nvarchar | Trade.GetInstrumentDataDealing.Exchange | CODE-BACKED | Exchange name where the instrument is listed (e.g., "NASDAQ", "NYSE"). From the exchange lookup via the view. |
| R6 | Tradable | bit | Trade.GetInstrumentDataDealing.Tradable | CODE-BACKED | Whether the instrument is currently tradable. 1 = active and open for trading; 0 = suspended/halted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.GetInstrumentDataDealing | Read (SELECT) | Denormalized view providing instrument display data with type and exchange names resolved |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD\SQL_Dealing-Front | EXECUTE | Permission | Dealing Front (Sevision) surveillance platform |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsForSevision (procedure)
+-- Trade.GetInstrumentDataDealing (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentDataDealing | View | SELECT with WHERE filters - source of all return columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD\SQL_Dealing-Front | DB User | EXECUTE permission for Dealing Front instrument catalog |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all Sevision instruments

```sql
EXEC Trade.GetInstrumentsForSevision;
```

### 8.2 Check instruments excluded by the internal-only filter

```sql
SELECT  InstrumentID, InstrumentDisplayName, VisibleInternallyOnly
FROM    Trade.GetInstrumentDataDealing WITH (NOLOCK)
WHERE   VisibleInternallyOnly = 1
ORDER BY InstrumentDisplayName;
```

### 8.3 Check instruments excluded by the high-ID filter

```sql
SELECT  InstrumentID, InstrumentDisplayName, InstrumentType
FROM    Trade.GetInstrumentDataDealing WITH (NOLOCK)
WHERE   InstrumentID >= 1000000
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.1/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsForSevision | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsForSevision.sql*
