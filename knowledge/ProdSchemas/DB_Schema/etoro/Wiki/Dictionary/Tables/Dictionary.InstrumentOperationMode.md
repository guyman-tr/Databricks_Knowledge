# Dictionary.InstrumentOperationMode

> Lookup table defining whether an instrument is managed (active trading operations) or unmanaged (no platform-driven operations) by the trading engine.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK NONCLUSTERED) |
| **Partition** | MAIN filegroup |
| **Indexes** | 1 active (PK nonclustered) |

---

## 1. Business Meaning

Dictionary.InstrumentOperationMode classifies instruments into two operational states that determine how the trading engine interacts with them. A "Managed" instrument receives full platform operations — price updates, overnight fee calculations, margin adjustments, and risk management. An "Unmanaged" instrument is present in the system but does not receive automated trading operations.

This flag allows the platform to list instruments for informational purposes (e.g., showing price data, letting users watch them) without enabling full trading operations. It can also be used to gracefully decommission instruments — setting them to Unmanaged stops all automated processing while preserving existing positions.

The InstrumentOperationModeID is stored on instrument configuration tables and checked by the trading engine before performing any automated operation on an instrument.

---

## 2. Business Logic

### 2.1 Instrument Operational State

**What**: Determines whether the trading engine performs automated operations on an instrument.

**Columns/Parameters Involved**: `ID`, `Description`

**Rules**:
- **ManagedInstrument (0)**: Full trading operations — price feeds, overnight fees, margin calculations, risk checks, and automated close operations all active.
- **UnmanagedInstrument (1)**: No automated operations — instrument exists in the system but the trading engine skips it for overnight fees, margin adjustments, etc. Existing positions remain but receive no automated maintenance.

**Diagram**:
```
Instrument Configuration
        │
        ├── ID=0 (ManagedInstrument)
        │   → Price updates: YES
        │   → Overnight fees: YES
        │   → Margin calcs: YES
        │   → Risk checks: YES
        │
        └── ID=1 (UnmanagedInstrument)
            → Price updates: Limited/None
            → Overnight fees: SKIPPED
            → Margin calcs: SKIPPED
            → Risk checks: SKIPPED
```

---

## 3. Data Overview

| ID | Description | Meaning |
|---|---|---|
| 0 | ManagedInstrument | Fully managed by the trading engine — receives all automated operations including price feeds, overnight fee calculations, margin monitoring, and risk management. Standard state for all actively traded instruments. |
| 1 | UnmanagedInstrument | Not managed by the trading engine — instrument exists in the system but automated operations are skipped. Used for decommissioned instruments, informational-only listings, or instruments pending full activation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Operation mode: **0**=ManagedInstrument (full automated operations), **1**=UnmanagedInstrument (no automated operations). Referenced by instrument configuration tables to control trading engine behavior. |
| 2 | Description | varchar(500) | YES | - | CODE-BACKED | Mode label: "ManagedInstrument" or "UnmanagedInstrument". Despite varchar(500) allocation, values are short descriptive labels. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Instrument configuration tables | InstrumentOperationModeID | Implicit | Determines whether the trading engine performs operations on the instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.InstrumentOperationMode (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instrument configuration tables | Tables | Reference InstrumentOperationModeID |
| Trading engine | Service | Checks mode before performing automated operations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InstrumentOperationMode | NONCLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InstrumentOperationMode | PRIMARY KEY (NONCLUSTERED) | Unique operation mode, FILLFACTOR 90, DATA_COMPRESSION PAGE, MAIN filegroup. Note: PK is NONCLUSTERED (unusual) — no clustered index on this table. |

---

## 8. Sample Queries

### 8.1 List all instrument operation modes
```sql
SELECT  ID, Description
FROM    Dictionary.InstrumentOperationMode WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Resolve operation mode ID to label
```sql
SELECT  Description
FROM    Dictionary.InstrumentOperationMode WITH (NOLOCK)
WHERE   ID = 0; -- ManagedInstrument
```

### 8.3 Find instruments by operation mode (conceptual)
```sql
SELECT  iom.Description     AS OperationMode
FROM    Dictionary.InstrumentOperationMode iom WITH (NOLOCK)
ORDER BY iom.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.InstrumentOperationMode | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.InstrumentOperationMode.sql*
