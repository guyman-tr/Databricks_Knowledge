# Price.GetInstrumentPriceSources

> Template-based view that expands pricing templates into per-instrument rate source allocations - the source data used by Price.UpdateInstrumentRateSources to bulk-rebuild the live InstrumentRateSources routing table.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + AccountRateSourceID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetInstrumentPriceSources answers: "Based on the template system, what rate sources and priorities should each instrument use?" It joins three tables to expand template-level rate source allocations into per-instrument rows in the same format as Price.InstrumentRateSources (InstrumentID, AccountRateSourceID, Priority, PriceServerID).

The view is the bridge between the template configuration layer (TemplateRateSourceAllocations + InstrumentToTemplate) and the live routing table (InstrumentRateSources). Price.UpdateInstrumentRateSources reads this view and bulk-replaces all rows in InstrumentRateSources from it. The template model enables batch reconfiguration: updating one template's rate source allocations propagates to all assigned instruments on the next UpdateInstrumentRateSources run, without per-instrument edits.

Current state: the view returns 0 rows because both Price.TemplateRateSourceAllocations (0 rows) and Price.InstrumentToTemplate (0 rows) are provisioned but not populated. The template system is an alternative/future path to managing InstrumentRateSources; the current live routing (656 rows in InstrumentRateSources) is managed directly via Price.InstrumentRateSourceAdd and Price.InstrumentRateSourceEdit.

---

## 2. Business Logic

### 2.1 Template Fan-Out to Per-Instrument Rows

**What**: Each template row in TemplateRateSourceAllocations multiplies across all instruments assigned to that template, producing one row per (instrument, source) combination.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`, `Priority`

**Rules**:
- 1 template with N rate source rows + M instruments assigned -> view produces N x M rows
- Priority values follow the same convention as InstrumentRateSources: 10=primary, 20=secondary, 30=tertiary, 40=quaternary
- Each instrument appears multiple times (once per template source row)
- The INNER JOIN to Trade.Instrument validates instrument existence; instruments not in Trade.Instrument are excluded

**Template system pipeline**:
```
Price.Templates                        (template definitions)
       |
Price.TemplateRateSourceAllocations    (rate sources per template)
       |
Price.InstrumentToTemplate             (instrument -> template assignment)
       |
Price.GetInstrumentPriceSources        (this view: per-instrument source rows)
       |
Price.UpdateInstrumentRateSources      (proc: bulk-rebuilds InstrumentRateSources)
       |
Price.InstrumentRateSources            (live routing table)
```

### 2.2 PriceServerID from Trade.Instrument

**What**: The PriceServerID column is carried from Trade.Instrument (not from the template tables), providing the price server identifier alongside the source allocation.

**Columns/Parameters Involved**: `PriceServerID`, `InstrumentID`

**Rules**:
- PriceServerID is read from Trade.Instrument (TI alias in the JOIN)
- It is not a property of the template or rate source; it is an instrument-level attribute
- Included in the output so UpdateInstrumentRateSources can populate PriceServerID in InstrumentRateSources (if that column exists there)

---

## 3. Data Overview

*The view currently returns 0 rows - Price.TemplateRateSourceAllocations and Price.InstrumentToTemplate are both empty. The template system is provisioned but not in active use.*

*When populated, rows would appear as:*

| InstrumentID | AccountRateSourceID | Priority | PriceServerID | Meaning |
|---|---|---|---|---|
| 1 | 21 | 10 | (from Trade.Instrument) | EUR/USD assigned to ForexTemplate: primary source is ARS=21 (ZBFX) |
| 1 | 300 | 20 | (from Trade.Instrument) | EUR/USD secondary source ARS=300 via ForexTemplate |
| 2 | 21 | 10 | (from Trade.Instrument) | GBP/USD inherits same template -> same primary source |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. From Price.InstrumentToTemplate (ITT alias). Must exist in Trade.Instrument (JOIN validates). One instrument per template row - an instrument appears N times (once per rate source in its assigned template). |
| 2 | AccountRateSourceID | int | NO | - | CODE-BACKED | Rate source identifier from Price.TemplateRateSourceAllocations. FK to Price.AccountRateSource. The named feed provider assigned to this instrument's template at this priority tier. |
| 3 | Priority | int | NO | - | CODE-BACKED | Priority order for this rate source within the instrument's template: 10=primary (queried first), 20=secondary, 30=tertiary, 40=quaternary. Inherited from TemplateRateSourceAllocations. Same convention as Price.InstrumentRateSources. |
| 4 | PriceServerID | int/other | YES | - | CODE-BACKED | Price server identifier from Trade.Instrument. An instrument-level attribute carried through the join; not part of the template definition itself. Identifies which price server instance handles this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TemplateID (internal) | Price.TemplateRateSourceAllocations | JOIN source | Rate source allocations per template |
| InstrumentID | Price.InstrumentToTemplate | JOIN source | Instrument-to-template assignment |
| InstrumentID | Trade.Instrument | JOIN validation | Ensures instrument exists |
| AccountRateSourceID | Price.AccountRateSource | Lookup (via TemplateRateSourceAllocations) | Named rate source feed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.UpdateInstrumentRateSources | Stored Procedure | SELECT source | Bulk-rebuilds InstrumentRateSources from this view on each configuration refresh |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetInstrumentPriceSources (view)
├── Price.TemplateRateSourceAllocations (table)
├── Price.InstrumentToTemplate (table)
└── Trade.Instrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.TemplateRateSourceAllocations | Table | FROM (TRSA alias) - provides AccountRateSourceID and Priority per template |
| Price.InstrumentToTemplate | Table | JOIN on TemplateID - maps instruments to templates |
| Trade.Instrument | Table | JOIN on InstrumentID - validates instruments and provides PriceServerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.UpdateInstrumentRateSources | Stored Procedure | SELECT from this view to bulk-rebuild InstrumentRateSources |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. All INNER JOINs - instruments without a template assignment or missing from Trade.Instrument are excluded. Currently returns 0 rows (template system not populated).

---

## 8. Sample Queries

### 8.1 Get projected rate sources for a specific instrument (when populated)

```sql
SELECT InstrumentID, AccountRateSourceID, Priority, PriceServerID
FROM Price.GetInstrumentPriceSources WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Priority;
```

### 8.2 Count instruments per rate source template allocation

```sql
SELECT AccountRateSourceID, Priority, COUNT(DISTINCT InstrumentID) AS InstrumentCount
FROM Price.GetInstrumentPriceSources WITH (NOLOCK)
GROUP BY AccountRateSourceID, Priority
ORDER BY Priority, InstrumentCount DESC;
```

### 8.3 Join to AccountRateSource for human-readable source names

```sql
SELECT
    GIPS.InstrumentID,
    GIPS.Priority,
    ARS.Name AS RateSourceName,
    GIPS.PriceServerID
FROM Price.GetInstrumentPriceSources GIPS WITH (NOLOCK)
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = GIPS.AccountRateSourceID
ORDER BY GIPS.InstrumentID, GIPS.Priority;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetInstrumentPriceSources | Type: View | Source: etoro/etoro/Price/Views/Price.GetInstrumentPriceSources.sql*
