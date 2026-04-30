# Price.GetPriceAllocationDiscrepancy

> Returns a single COUNT of rows that differ between the template-projected rate source view (Price.GetInstrumentPriceSources) and the live routing table (Price.InstrumentRateSources) - a diagnostic audit check for the template sync system.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - diagnostic count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetPriceAllocationDiscrepancy is a health-check/audit procedure that answers: "Are the template-projected rate source allocations in sync with the live routing table?" It returns a single integer COUNT of rows that exist in one side but not the other.

The two sides being compared:
- **Price.GetInstrumentPriceSources** (view): What the template system says each instrument's rate source routing *should* be. Derived from TemplateRateSourceAllocations + InstrumentToTemplate.
- **Price.InstrumentRateSources** (table): The live routing table that the pricing engine actually uses. Currently managed via InstrumentRateSourceAdd/Edit (direct mode, not template mode).

A COUNT of 0 means the two sources are perfectly synchronized. Any non-zero count indicates discrepancy: either the template has rows not yet propagated to live routing, or live routing has rows not covered by the template.

**Current expected result**: Since Price.GetInstrumentPriceSources currently returns 0 rows (template system not populated - TemplateRateSourceAllocations and InstrumentToTemplate are both empty), calling this procedure returns COUNT = 656 (all InstrumentRateSources rows are unmatched, as there is no corresponding IPS row for any of them). This is the expected state when using direct routing management instead of the template system.

This procedure is typically called by monitoring/ops tooling to verify sync before or after running Price.UpdateInstrumentRateSources, which bulk-rebuilds InstrumentRateSources from the template view.

---

## 2. Business Logic

### 2.1 FULL OUTER JOIN Discrepancy Count

**What**: Uses FULL OUTER JOIN + WHERE IS NULL (anti-join on both sides) to identify unmatched rows.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`, `Priority`

**Rules**:
- JOIN key: `IPS.InstrumentID = IRS.InstrumentID AND IPS.AccountRateSourceID = IRS.AccountRateSourceID AND IPS.Priority = IRS.Priority`
  - Note: `IPS.InstrumentID = IRS.InstrumentID` appears TWICE in the ON clause (redundant duplicate, no effect)
- WHERE filter: `IPS.InstrumentID IS NULL OR IRS.InstrumentID IS NULL`
  - `IPS.InstrumentID IS NULL`: row exists in InstrumentRateSources but not in GetInstrumentPriceSources (live has extra rows)
  - `IRS.InstrumentID IS NULL`: row exists in GetInstrumentPriceSources but not in InstrumentRateSources (template has rows not yet propagated)
- COUNT(*): counts all unmatched rows from both sides combined
- Result: 0 = fully in sync; positive number = discrepancy count

**Interpretation**:
| COUNT result | Meaning |
|---|---|
| 0 | Template and live routing are in perfect sync |
| N (when GetInstrumentPriceSources = 0 rows) | N live routing rows exist with no template counterpart (direct management mode) |
| N (when both sides populated) | N rows differ - template needs to be re-propagated via UpdateInstrumentRateSources |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No input parameters. Returns discrepancy count between template view and live routing. |

**Result set columns** (1 column):

| # | Column | Description |
|---|--------|-------------|
| 1 | Count | Number of rows in the FULL OUTER JOIN result where one side has no match. 0 = in sync. Current expected value: 656 (all InstrumentRateSources rows unmatched since template system is not populated). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IPS | Price.GetInstrumentPriceSources | READER | Template-projected rate source rows (expected/desired state) |
| IRS | Price.InstrumentRateSources | READER | Live routing table (actual current state) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (monitoring/ops tooling) | - | CALLER | Called to verify sync state before/after UpdateInstrumentRateSources runs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetPriceAllocationDiscrepancy (procedure)
+-- Price.GetInstrumentPriceSources (view) - template-projected desired state
|   +-- Price.TemplateRateSourceAllocations (table)
|   +-- Price.InstrumentToTemplate (table)
|   +-- Trade.Instrument (table)
+-- Price.InstrumentRateSources (table) - live routing actual state
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.GetInstrumentPriceSources | View | FULL OUTER JOIN source - template-projected desired rate source allocation |
| Price.InstrumentRateSources | Table | FULL OUTER JOIN source - live instrument rate source routing table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (monitoring/ops tooling) | External | Calls to check sync between template system and live routing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON (returns row count message alongside result). No NOLOCK (inherits isolation level from view and table reads). No error handling. No transaction. The ON clause contains a duplicate join predicate (`IPS.InstrumentID = IRS.InstrumentID` appears twice) - this is harmless but indicates the code was likely written manually without review. The FULL OUTER JOIN is the correct pattern for bidirectional discrepancy detection: a LEFT JOIN would miss rows in InstrumentRateSources not in the view; a RIGHT JOIN would miss the reverse.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Price.GetPriceAllocationDiscrepancy;
-- Returns: Count = N (0 if in sync, 656 in current state with empty template system)
```

### 8.2 Equivalent manual query with breakdown

```sql
SELECT
    CASE
        WHEN IPS.InstrumentID IS NULL THEN 'In IRS but not in template'
        WHEN IRS.InstrumentID IS NULL THEN 'In template but not in IRS'
    END AS DiscrepancyType,
    COUNT(*) AS [Count]
FROM Price.GetInstrumentPriceSources IPS WITH (NOLOCK)
FULL OUTER JOIN Price.InstrumentRateSources IRS WITH (NOLOCK)
    ON IPS.InstrumentID = IRS.InstrumentID
    AND IPS.AccountRateSourceID = IRS.AccountRateSourceID
    AND IPS.Priority = IRS.Priority
WHERE IPS.InstrumentID IS NULL OR IRS.InstrumentID IS NULL
GROUP BY
    CASE
        WHEN IPS.InstrumentID IS NULL THEN 'In IRS but not in template'
        WHEN IRS.InstrumentID IS NULL THEN 'In template but not in IRS'
    END;
```

### 8.3 List the specific discrepant rows

```sql
SELECT
    COALESCE(IPS.InstrumentID, IRS.InstrumentID) AS InstrumentID,
    COALESCE(IPS.AccountRateSourceID, IRS.AccountRateSourceID) AS AccountRateSourceID,
    COALESCE(IPS.Priority, IRS.Priority) AS Priority,
    CASE WHEN IPS.InstrumentID IS NULL THEN 'In IRS only' ELSE 'In template only' END AS Source
FROM Price.GetInstrumentPriceSources IPS WITH (NOLOCK)
FULL OUTER JOIN Price.InstrumentRateSources IRS WITH (NOLOCK)
    ON IPS.InstrumentID = IRS.InstrumentID
    AND IPS.AccountRateSourceID = IRS.AccountRateSourceID
    AND IPS.Priority = IRS.Priority
WHERE IPS.InstrumentID IS NULL OR IRS.InstrumentID IS NULL
ORDER BY InstrumentID, Priority;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetPriceAllocationDiscrepancy | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetPriceAllocationDiscrepancy.sql*
