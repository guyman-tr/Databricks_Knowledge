# Price.UpdateInstrumentRateSources

> Performs a full atomic rebuild of the Price.InstrumentRateSources routing table by deleting all existing rows and repopulating from the Price.GetInstrumentPriceSources template view, synchronizing the live feed routing configuration with the template system.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; no return value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.UpdateInstrumentRateSources is the bulk configuration refresh procedure for the instrument rate source routing table. `Price.InstrumentRateSources` defines which market data feeds each instrument uses and in what priority order - it is the central routing table of the pricing engine. This procedure completely rebuilds that table from scratch by reading the template-based view `Price.GetInstrumentPriceSources`.

The motivation for this bulk approach is the template architecture: when a pricing template's rate source allocations change (in `Price.TemplateRateSourceAllocations`), the change needs to propagate to all instruments assigned to that template. Rather than updating each instrument row individually, this procedure atomically replaces the entire routing table with the view's current output, which already contains the template fan-out logic.

The operation is transactional: DELETE and INSERT are wrapped in BEGIN/COMMIT TRAN with a CATCH/ROLLBACK block. If the INSERT fails for any reason, the DELETE is rolled back, leaving InstrumentRateSources unchanged. This prevents a partial rebuild that would leave instruments without price source routing.

Note: Because this rebuilds via the template system (`GetInstrumentPriceSources`), and that view currently returns 0 rows (both `Price.TemplateRateSourceAllocations` and `Price.InstrumentToTemplate` are empty), calling this procedure in the current environment would delete all 656 existing InstrumentRateSources rows and insert nothing, effectively disabling all feed routing. The current InstrumentRateSources data was populated via `Price.InstrumentRateSourceAdd` directly, not via templates.

---

## 2. Business Logic

### 2.1 Atomic Full-Rebuild Pattern

**What**: Replaces all InstrumentRateSources rows in one transaction by deleting first, then inserting from the template view.

**Columns/Parameters Involved**: None (operates on InstrumentRateSources and GetInstrumentPriceSources directly)

**Rules**:
- BEGIN TRAN -> DELETE FROM Price.InstrumentRateSources (all rows) -> INSERT INTO ... SELECT from Price.GetInstrumentPriceSources
- On success: COMMIT TRAN
- On any error in TRY block: CATCH -> ROLLBACK TRAN if @@TRANCOUNT > 0
- After rollback, InstrumentRateSources is unchanged (full atomicity)
- After successful rebuild, all previous InstrumentRateSourceIDs are gone (IDENTITY resets from where it left off)
- The INSERT populates: InstrumentID, AccountRateSourceID, Priority (from view); PriceServerID is also provided by the view from Trade.Instrument

**Template pipeline flow**:
```
Price.TemplateRateSourceAllocations   <- source of rate source assignments per template
     |
Price.InstrumentToTemplate            <- which instruments use which template
     |
Price.GetInstrumentPriceSources       <- view: expands to per-instrument rows
     |
Price.UpdateInstrumentRateSources     <- THIS procedure: DELETE old, INSERT new
     |
Price.InstrumentRateSources           <- live routing table (refreshed result)
```

### 2.2 WARNING - Template System Must Be Populated Before Use

**What**: Calling this procedure when the template system is empty will delete all live routing data.

**Columns/Parameters Involved**: N/A

**Rules**:
- Price.GetInstrumentPriceSources returns 0 rows when TemplateRateSourceAllocations and InstrumentToTemplate are empty
- Running this procedure against an empty template system = DELETE all 656 rows + INSERT 0 rows
- Always verify Price.GetInstrumentPriceSources has data before calling this in a live environment
- Safe to call only after the template system is populated OR in a staging/rebuild scenario

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No parameters. Operates entirely on static table/view references. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all rows) | Price.InstrumentRateSources | DELETER + WRITER | Deletes all rows; re-inserts from GetInstrumentPriceSources |
| (SELECT source) | Price.GetInstrumentPriceSources | READER | View that expands template configuration into per-instrument rows |

### 5.2 Referenced By (other objects point to this)

No SQL callers found in the etoro SSDT repo. Called externally by pricing configuration management services or scripts during template reconfiguration.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.UpdateInstrumentRateSources (procedure)
├── Price.InstrumentRateSources (table - DELETE all + INSERT target)
└── Price.GetInstrumentPriceSources (view - INSERT source)
      ├── Price.TemplateRateSourceAllocations (table)
      ├── Price.InstrumentToTemplate (table)
      └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSources | Table | DELETE all rows; INSERT new rows from view |
| Price.GetInstrumentPriceSources | View | SELECT source - expanded template-to-instrument rate source rows |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Full atomicity | Transaction | BEGIN TRAN / COMMIT TRAN with CATCH ROLLBACK - InstrumentRateSources is all-or-nothing |
| Template prerequisite | Warning | GetInstrumentPriceSources must return rows before calling; empty template = DELETE all live routing data |
| IDENTITY gap | Side effect | After rebuild, InstrumentRateSourceID values are different (DELETE + re-INSERT increments IDENTITY sequence) |

---

## 8. Sample Queries

### 8.1 Verify template system has data before running

```sql
-- Check row counts in template tables before triggering rebuild
SELECT
    (SELECT COUNT(*) FROM Price.TemplateRateSourceAllocations WITH (NOLOCK)) AS TemplateAllocations,
    (SELECT COUNT(*) FROM Price.InstrumentToTemplate WITH (NOLOCK)) AS InstrumentMappings,
    (SELECT COUNT(*) FROM Price.GetInstrumentPriceSources WITH (NOLOCK)) AS ViewOutputRows,
    (SELECT COUNT(*) FROM Price.InstrumentRateSources WITH (NOLOCK)) AS CurrentRoutingRows;
-- Only run UpdateInstrumentRateSources if ViewOutputRows > 0
```

### 8.2 Execute the full routing table rebuild

```sql
EXEC Price.UpdateInstrumentRateSources;
-- No return value; check InstrumentRateSources after
```

### 8.3 Verify routing table after rebuild

```sql
SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT InstrumentID) AS UniqueInstruments,
    MIN(Priority) AS MinPriority,
    MAX(Priority) AS MaxPriority
FROM Price.InstrumentRateSources WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 8/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Price.UpdateInstrumentRateSources | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.UpdateInstrumentRateSources.sql*
