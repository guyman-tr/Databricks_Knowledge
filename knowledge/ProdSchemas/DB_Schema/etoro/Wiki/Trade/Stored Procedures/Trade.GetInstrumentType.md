# Trade.GetInstrumentType

> Returns the InstrumentID-to-InstrumentTypeID mapping for all instruments, enabling services to classify instruments by asset type (stocks, forex, crypto, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + InstrumentTypeID from Trade.GetInstrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentType returns the type classification for every instrument. InstrumentTypeID maps to Dictionary.InstrumentType and determines the asset class: stocks, currencies, commodities, indices, ETFs, crypto, futures, etc. Services use this mapping to apply type-specific business rules (fee structures, margin requirements, trading hours, settlement rules).

This procedure reads from Trade.GetInstrument (a view) ordered by InstrumentID for consistent enumeration. It provides a lightweight type-only lookup without the overhead of full instrument metadata.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct type mapping lookup.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.GetInstrument.InstrumentID | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. |
| R2 | InstrumentTypeID | int | Trade.GetInstrument.InstrumentTypeID | CODE-BACKED | Asset type classification. FK to Dictionary.InstrumentType (e.g., 1=Currencies, 4=Indices, 5=Commodities, 10=Stocks, 14=Futures). Drives type-specific fee, margin, and settlement rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.GetInstrument | Read (SELECT) | View providing instrument data including type classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD\BIadmins | VIEW DEFINITION | Permission | BI admin monitoring access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentType (procedure)
+-- Trade.GetInstrument (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | SELECT - source of InstrumentID and InstrumentTypeID |

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

### 8.1 Get all instrument types

```sql
EXEC Trade.GetInstrumentType;
```

### 8.2 Count instruments by type

```sql
SELECT  InstrumentTypeID, COUNT(*) AS InstrumentCount
FROM    Trade.GetInstrument WITH (NOLOCK)
GROUP BY InstrumentTypeID
ORDER BY InstrumentCount DESC;
```

### 8.3 Get instrument types with resolved type names

```sql
SELECT  gi.InstrumentID, gi.InstrumentTypeID, dit.InstrumentType
FROM    Trade.GetInstrument gi WITH (NOLOCK)
        INNER JOIN Dictionary.InstrumentType dit WITH (NOLOCK) ON gi.InstrumentTypeID = dit.InstrumentTypeID
ORDER BY gi.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentType | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentType.sql*
