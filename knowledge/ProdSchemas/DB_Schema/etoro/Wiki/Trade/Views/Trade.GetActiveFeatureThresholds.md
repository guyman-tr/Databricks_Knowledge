# Trade.GetActiveFeatureThresholds

> Pivots Trade.ActiveFeatureThreshold rows into one row per instrument with Feature1 through Feature6 columns, so consumers can read threshold IDs without JOINs or PIVOT logic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetActiveFeatureThresholds transforms the normalized (InstrumentID, FeatureID, ActiveThresholdID) rows in Trade.ActiveFeatureThreshold into a **wide format**: one row per InstrumentID with Feature1, Feature2, Feature3, Feature4, Feature5, Feature6. Each FeatureN column holds the ActiveThresholdID for that feature (0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum). Features 1-6 correspond to Price Filter (MS), Execution Delay (MS), Rate Volatility (Pip), Inactivity Timeout (MS), Limit Execution (Pip), and Rate Volatility (Percentage).

This view exists because order matching, validation, and instrument configuration code need per-instrument threshold levels in a flat structure. Without it, every consumer would need to PIVOT or run 6 lookups. Trade.CheckValidInstruments and Trade.InsertInstrumentRealTable work with the base table; this view serves application layers that prefer columnar access.

Data flows: Read-only. Trade.ActiveFeatureThreshold is the source. PIVOT MAX(ActiveThresholdID) FOR FeatureID IN (1,2,3,4,5,6). ISNULL(..., 0) handles missing features. Consumers SELECT InstrumentID, Feature1, ..., Feature6 for threshold lookup.

---

## 2. Business Logic

### 2.1 PIVOT Transformation

**What**: One row per (InstrumentID, FeatureID) becomes one row per InstrumentID with 6 columns.

**Columns/Parameters Involved**: InstrumentID, FeatureID, ActiveThresholdID, Feature1..Feature6

**Rules**:
- FeatureID 1 -> Feature1, 2 -> Feature2, etc.
- MAX(ActiveThresholdID) per (InstrumentID, FeatureID) - typically one row per pair.
- ISNULL([N], 0) : missing feature defaults to 0 (Minimum).

### 2.2 Feature-to-Column Mapping

**What**: Dictionary.Feature IDs 1-6 map to view columns.

**Columns/Parameters Involved**: Feature1..Feature6

**Rules**:
- Feature1: Price Filter (MS)
- Feature2: Execution Delay (MS)
- Feature3: Rate Volatility (Pip)
- Feature4: Inactivity Timeout (MS)
- Feature5: Limit Execution (Pip)
- Feature6: Rate Volatility (Percentage)
- Feature 7 (Price Stale timeout) is NOT in the pivot.

---

## 3. Data Overview

| InstrumentID | Feature1 | Feature2 | Feature3 | Feature4 | Feature5 | Feature6 | Meaning |
|--------------|----------|----------|----------|----------|----------|----------|---------|
| 0 | 0 | 0 | 0 | 0 | 5 | 0 | System placeholder instrument. Most features at Minimum (0); Feature5 (Limit Execution) at Low (5). |
| 1 | 15 | 15 | 15 | 15 | 10 | 15 | EUR/USD - High (15) for most features, Medium (10) for Limit Execution. |
| 2 | 15 | 15 | 15 | 15 | 15 | 15 | GBP - All High/Maximum. |
| 3 | 15 | 15 | 15 | 15 | 15 | 15 | Commodity/index - strict thresholds. |
| 4 | 15 | 15 | 15 | 15 | 15 | 15 | CAD - same pattern. |

**Selection criteria**: Live data TOP 5. InstrumentID 0 is system placeholder; 1-4 are forex. Threshold IDs: 0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The tradeable instrument. From Trade.ActiveFeatureThreshold. |
| 2 | Feature1 | int | NO | - | CODE-BACKED | ActiveThresholdID for FeatureID 1 (Price Filter MS). 0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum. ISNULL(..., 0). |
| 3 | Feature2 | int | NO | - | CODE-BACKED | ActiveThresholdID for FeatureID 2 (Execution Delay MS). Same value map. |
| 4 | Feature3 | int | NO | - | CODE-BACKED | ActiveThresholdID for FeatureID 3 (Rate Volatility Pip). Same value map. |
| 5 | Feature4 | int | NO | - | CODE-BACKED | ActiveThresholdID for FeatureID 4 (Inactivity Timeout MS). Same value map. |
| 6 | Feature5 | int | NO | - | CODE-BACKED | ActiveThresholdID for FeatureID 5 (Limit Execution Pip). Same value map. |
| 7 | Feature6 | int | NO | - | CODE-BACKED | ActiveThresholdID for FeatureID 6 (Rate Volatility Percentage). Same value map. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Via Trade.ActiveFeatureThreshold |
| Feature1..6 | Dictionary.FeatureThreshold | Implicit | ActiveThresholdID values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckValidInstruments | (base table) | - | Validates via base table |
| Trade.ActiveFeatureThreshold doc | - | FROM | View pivots base table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetActiveFeatureThresholds (view)
└── Trade.ActiveFeatureThreshold (table)
      ├── Trade.Instrument (table)
      └── Dictionary.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActiveFeatureThreshold | Table | FROM, PIVOT source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application/config consumers | - | SELECT Feature1..Feature6 for threshold lookup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get thresholds for an instrument
```sql
SELECT InstrumentID, Feature1, Feature2, Feature3, Feature4, Feature5, Feature6
  FROM Trade.GetActiveFeatureThresholds WITH (NOLOCK)
 WHERE InstrumentID = 1006;
```

### 8.2 Instruments with strictest Rate Volatility (Feature3 = 20)
```sql
SELECT InstrumentID, Feature1, Feature2, Feature3, Feature4, Feature5, Feature6
  FROM Trade.GetActiveFeatureThresholds WITH (NOLOCK)
 WHERE Feature3 = 20
 ORDER BY InstrumentID;
```

### 8.3 Resolve threshold names
```sql
SELECT g.InstrumentID, g.Feature1, ft1.Name AS Feature1Name,
       g.Feature2, ft2.Name AS Feature2Name
  FROM Trade.GetActiveFeatureThresholds g WITH (NOLOCK)
  LEFT JOIN Dictionary.FeatureThreshold ft1 WITH (NOLOCK) ON ft1.ThresholdID = g.Feature1
  LEFT JOIN Dictionary.FeatureThreshold ft2 WITH (NOLOCK) ON ft2.ThresholdID = g.Feature2
 WHERE g.InstrumentID IN (1, 1006);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.6/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetActiveFeatureThresholds | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetActiveFeatureThresholds.sql*
