# Hedge.GetInstrumentMinOrderSizeForHBC

> Targeted read: returns the minimum order size floor for HBC execution per instrument. Single-column read from Hedge.InstrumentConfiguration with NOLOCK. No parameters; all 10,468 instruments returned. The HBC subsystem uses this to skip execution of hedge orders below the minimum threshold.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters, returns all instrument rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetInstrumentMinOrderSizeForHBC returns the per-instrument minimum order size for HBC (Hedge Bot Controller) execution. When the hedge engine computes a net exposure to hedge for a given instrument, it checks this minimum before dispatching an order: if the computed hedge quantity is below `MinOrderSizeForExecutionInEToroUnits`, the order is not sent. This prevents the provider from receiving tiny, uneconomical orders that would result in high commission-to-trade-size ratios.

The procedure is a deliberately narrow read - just InstrumentID + MinOrderSizeForExecutionInEToroUnits - returning exactly what the HBC routing subsystem needs without loading the full InstrumentConfiguration row (see GetAllInstrumentConfigurations or GetInstrumentConfiguration for wider reads).

Note: this is complementary to GetInstrumentConfiguration (which returns deal size thresholds for order validation) and GetCircuitBreakerInstrumentThresholds (which returns circuit breaker limits). Each procedure serves a specific subsystem's startup data needs.

---

## 2. Business Logic

### 2.1 Minimum Order Size Floor

**What**: MinOrderSizeForExecutionInEToroUnits defines the smallest hedge order the HBC will dispatch to a provider for each instrument.

**Columns/Parameters Involved**: `InstrumentID`, `MinOrderSizeForExecutionInEToroUnits`

**Rules**:
- Orders with computed hedge quantity < MinOrderSizeForExecutionInEToroUnits are not sent (too small).
- Expressed in eToro units (the platform's internal monetary denomination).
- Configured at the instrument level: different instruments may have different minimum sizes depending on provider lot sizes and market conventions.
- Used by HBC to filter out micro-orders before they reach the execution layer.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (2 columns from Hedge.InstrumentConfiguration):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. PK of InstrumentConfiguration. All 10,468 configured instruments returned. |
| 2 | MinOrderSizeForExecutionInEToroUnits | decimal | YES | - | CODE-BACKED | Minimum hedge order size in eToro units. Orders computed below this threshold are skipped by HBC. NULL or 0 = no minimum enforced for this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| 2-column read | Hedge.InstrumentConfiguration | Lookup / Read | InstrumentID + MinOrderSizeForExecutionInEToroUnits. NOLOCK. All rows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HBC subsystem (external) | Result set | Caller | Loads minimum order size thresholds at startup to filter micro-orders. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetInstrumentMinOrderSizeForHBC (procedure)
└── Hedge.InstrumentConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentConfiguration | Table | 2 columns: InstrumentID, MinOrderSizeForExecutionInEToroUnits. NOLOCK. All rows. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HBC subsystem (external) | Application | Startup load of minimum order size floors for execution filtering. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

NOLOCK hint. No temp tables. No parameters. Simplest possible read: 2 columns, no filter, no join. For more InstrumentConfiguration columns use: GetInstrumentConfiguration (HBC thresholds), GetCircuitBreakerInstrumentThresholds (circuit breakers), GetAllInstrumentConfigurations (full row).

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetInstrumentMinOrderSizeForHBC;
```

### 8.2 Find instruments with large minimum order sizes

```sql
SELECT InstrumentID, MinOrderSizeForExecutionInEToroUnits
FROM   Hedge.InstrumentConfiguration WITH (NOLOCK)
WHERE  MinOrderSizeForExecutionInEToroUnits > 10000
ORDER BY MinOrderSizeForExecutionInEToroUnits DESC;
```

### 8.3 Find instruments with no minimum configured

```sql
SELECT COUNT(*) AS NoMinimum
FROM   Hedge.InstrumentConfiguration WITH (NOLOCK)
WHERE  MinOrderSizeForExecutionInEToroUnits IS NULL OR MinOrderSizeForExecutionInEToroUnits = 0;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | HBC minimum order size enforcement to avoid micro-orders at liquidity providers. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetInstrumentMinOrderSizeForHBC | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetInstrumentMinOrderSizeForHBC.sql*
