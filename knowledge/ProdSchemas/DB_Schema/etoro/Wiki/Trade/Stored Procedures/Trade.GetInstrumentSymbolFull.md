# Trade.GetInstrumentSymbolFull

> Returns the InstrumentID-to-SymbolFull mapping for all instruments, providing the universal instrument symbol lookup table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + SymbolFull from Trade.InstrumentMetaData |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentSymbolFull is a parameterless bulk-read procedure that returns the full trading symbol for every instrument. SymbolFull is the canonical symbol representation (e.g., "AAPL", "EURUSD", "BTC") used across all platform displays, reports, and integrations.

This procedure exists as a lightweight ID-to-symbol resolver. Services that only need symbol names (not display names, types, or other metadata) call this instead of the heavier GetInstrumentsData. BI admins have VIEW DEFINITION access for monitoring.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct single-table read.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.InstrumentMetaData.InstrumentID | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. |
| R2 | SymbolFull | nvarchar | Trade.InstrumentMetaData.SymbolFull | CODE-BACKED | Full trading symbol (e.g., "AAPL", "EURUSD", "BTC"). The canonical human-readable identifier for each instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.InstrumentMetaData | Read (SELECT) | Source of instrument symbols |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD\BIadmins | VIEW DEFINITION | Permission | BI admin monitoring access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentSymbolFull (procedure)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | SELECT - source of InstrumentID and SymbolFull |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD\BIadmins | DB User | VIEW DEFINITION permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all instrument symbols

```sql
EXEC Trade.GetInstrumentSymbolFull;
```

### 8.2 Find a specific instrument by symbol

```sql
SELECT  InstrumentID, SymbolFull
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
WHERE   SymbolFull LIKE '%AAPL%';
```

### 8.3 Count instruments by symbol prefix

```sql
SELECT  LEFT(SymbolFull, 3) AS SymbolPrefix, COUNT(*) AS InstrumentCount
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
GROUP BY LEFT(SymbolFull, 3)
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentSymbolFull | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentSymbolFull.sql*
