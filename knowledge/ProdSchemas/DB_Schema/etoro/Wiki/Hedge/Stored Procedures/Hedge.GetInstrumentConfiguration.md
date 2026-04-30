# Hedge.GetInstrumentConfiguration

> Targeted read: returns only the HBC deal size alert and reject thresholds from Hedge.InstrumentConfiguration - the two columns used by HBC (Hedge Bot Controller) for order size validation. No parameters; full-table read of 3 columns. Distinct from GetAllInstrumentConfigurations (which returns all 10+ columns) and GetInstrumentMinOrderSizeForHBC (which returns the minimum size).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters, returns all 10,468 instrument rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetInstrumentConfiguration returns the per-instrument HBC deal size thresholds: the warning level (`HBCDealSizeThresholdAlertInEToroUnits`) and the hard reject level (`HBCMaxDealSizeThresholdRejectInEToroUnits`). The HBC (Hedge Bot Controller) applies these two-level checks to every outgoing hedge order to prevent oversized executions.

**Why this specific 3-column subset?** The hedge engine has multiple subsystems. HBC needs only the deal size thresholds (to validate order sizes). Circuit breaker logic uses a different procedure (GetCircuitBreakerInstrumentThresholds). Minimum order routing uses GetInstrumentMinOrderSizeForHBC. Full configuration load uses GetAllInstrumentConfigurations. Each subsystem gets exactly the columns it needs.

The procedure contains no NOLOCK hint, no ORDER BY, no parameters. For 10,468 rows this is a startup read that the HBC subsystem caches in memory.

---

## 2. Business Logic

### 2.1 Two-Level HBC Order Size Validation

**What**: HBC validates each outgoing hedge order against a two-level threshold: alert (warning) and max (hard reject).

**Columns/Parameters Involved**: `HBCDealSizeThresholdAlertInEToroUnits`, `HBCMaxDealSizeThresholdRejectInEToroUnits`

**Rules**:
- Both thresholds are in eToro units (the platform's internal monetary denomination).
- Alert threshold: order >= this value triggers a warning log but execution proceeds.
- Reject threshold: order >= this value causes HBC to refuse the order entirely; no hedge execution occurs.
- Typical configuration: most equities have alert = reject = 2,000,000 eToro units (alert is also the hard reject).
- DEFAULT in DDL = 30,000,000 for both columns; most instruments have per-instrument overrides.

**Decision flow**:
```
HBC receives order of size X for InstrumentID Y:
  X < Alert threshold   -> execute normally
  X >= Alert threshold  -> log warning + execute (if alert < reject)
  X >= Reject threshold -> HARD REJECT, order not sent to provider
```

### 2.2 3-Column Targeted Read

**What**: Returns only InstrumentID + the two HBC threshold columns, not the full InstrumentConfiguration row.

**Rules**:
- `SELECT InstrumentID, HBCDealSizeThresholdAlertInEToroUnits, HBCMaxDealSizeThresholdRejectInEToroUnits FROM Hedge.InstrumentConfiguration`
- Does NOT return: MinOrderSizeForExecutionInEToroUnits, ManualMaxDealSizeInEToroUnits, CircuitBreakerLimit, CircuitBreakerWarningLimit, SpreadReturnFactor, RestrictManualActions, LotSizeForView.
- These other columns are served by dedicated procedures for their respective subsystems.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (3 of 10+ Hedge.InstrumentConfiguration columns):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. PK of Hedge.InstrumentConfiguration. 10,468 rows total. |
| 2 | HBCDealSizeThresholdAlertInEToroUnits | decimal | NO | 30,000,000 | CODE-BACKED | Warning threshold. Orders >= this size log a warning but still execute (unless also >= reject threshold). In eToro units. Most equities = 2,000,000. |
| 3 | HBCMaxDealSizeThresholdRejectInEToroUnits | decimal | NO | 30,000,000 | CODE-BACKED | Hard reject threshold. Orders >= this size are refused by HBC without execution. In eToro units. Most equities = 2,000,000 (equal to alert = both alert and reject). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Full table read | Hedge.InstrumentConfiguration | Lookup / Read | 3 columns: InstrumentID + 2 HBC thresholds. All 10,468 rows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HBC subsystem (external) | Result set | Caller | Loads HBC deal size validation thresholds at startup. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetInstrumentConfiguration (procedure)
└── Hedge.InstrumentConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentConfiguration | Table | 3 columns selected: InstrumentID, HBCDealSizeThresholdAlertInEToroUnits, HBCMaxDealSizeThresholdRejectInEToroUnits. All rows. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HBC subsystem / HedgeAlertService (external) | Application | Startup load of HBC order size validation thresholds. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No NOLOCK. No temp tables. No parameters. Minimal SELECT - 3 of 10+ available columns. For the full InstrumentConfiguration row, use Hedge.GetAllInstrumentConfigurations.

**Related procedures for Hedge.InstrumentConfiguration**:

| Procedure | Columns Returned | Purpose |
|-----------|-----------------|---------|
| GetInstrumentConfiguration | InstrumentID, Alert threshold, Reject threshold | HBC deal size validation |
| GetInstrumentMinOrderSizeForHBC | InstrumentID, MinOrderSizeForExecutionInEToroUnits | Minimum order routing |
| GetCircuitBreakerInstrumentThresholds | InstrumentID, CircuitBreakerLimit, CircuitBreakerWarningLimit | Circuit breaker monitoring |
| GetAllInstrumentConfigurations | All columns | Full startup config load |

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetInstrumentConfiguration;
```

### 8.2 Find instruments with very low reject thresholds

```sql
SELECT InstrumentID, HBCDealSizeThresholdAlertInEToroUnits, HBCMaxDealSizeThresholdRejectInEToroUnits
FROM   Hedge.InstrumentConfiguration
WHERE  HBCMaxDealSizeThresholdRejectInEToroUnits < 1000000
ORDER BY HBCMaxDealSizeThresholdRejectInEToroUnits;
```

### 8.3 Find instruments where alert != reject (two-level check active)

```sql
SELECT InstrumentID, HBCDealSizeThresholdAlertInEToroUnits, HBCMaxDealSizeThresholdRejectInEToroUnits
FROM   Hedge.InstrumentConfiguration
WHERE  HBCDealSizeThresholdAlertInEToroUnits <> HBCMaxDealSizeThresholdRejectInEToroUnits;
-- These instruments have a genuine warning range before hard reject
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | HBC deal size threshold validation; two-level alert/reject pattern. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetInstrumentConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetInstrumentConfiguration.sql*
