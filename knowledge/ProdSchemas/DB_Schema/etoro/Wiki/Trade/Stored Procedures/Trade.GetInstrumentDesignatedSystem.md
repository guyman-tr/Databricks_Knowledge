# Trade.GetInstrumentDesignatedSystem

> Returns the designated execution system for every instrument - used to route orders to the correct execution venue.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the designated execution system assignment for all instruments with InstrumentID > 0. The DesignatedExecutionSystem determines which execution venue (internal matching, external broker, etc.) handles orders for each instrument. This is a regulatory requirement under MiFID II for best execution reporting.

The procedure exists to provide execution routing configuration to the trading engine. When an order arrives, the system needs to know which execution venue to route it to based on the instrument.

Data flow: no parameters. Returns InstrumentID and DesignatedExecutionSystem from Trade.ProviderToInstrument for all valid instruments (InstrumentID > 0).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple full-table read with InstrumentID > 0 filter. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Financial instrument identifier. Filtered to > 0 to exclude placeholder/system rows. |
| 2 | DesignatedExecutionSystem (output) | VARCHAR | YES | - | CODE-BACKED | Execution venue assignment for this instrument. Determines order routing under MiFID II best execution requirements. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.ProviderToInstrument | FROM | Source of DesignatedExecutionSystem per instrument |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentDesignatedSystem (procedure)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - reads InstrumentID and DesignatedExecutionSystem |

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

### 8.1 Execute to get all mappings

```sql
EXEC Trade.GetInstrumentDesignatedSystem;
```

### 8.2 Check specific instrument

```sql
SELECT  InstrumentID, DesignatedExecutionSystem
FROM    Trade.ProviderToInstrument WITH (NOLOCK)
WHERE   InstrumentID = 1001;
```

### 8.3 Group by execution system

```sql
SELECT  DesignatedExecutionSystem, COUNT(*) AS InstrumentCount
FROM    Trade.ProviderToInstrument WITH (NOLOCK)
WHERE   InstrumentID > 0
GROUP BY DesignatedExecutionSystem;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentDesignatedSystem | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentDesignatedSystem.sql*
