# Price.InstrumentToTemplate

> Assignment table that maps each trading instrument to exactly one rate source configuration template, enabling the template-based bulk pricing configuration system to route instruments to their designated feed providers.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

InstrumentToTemplate is the instrument-template assignment bridge in the pricing engine's template-based rate source allocation system. Each instrument is assigned to exactly one template (enforced by the single-column PK on InstrumentID), and that template defines which rate sources and priorities the instrument uses for price sourcing.

The template system pipeline:
1. **Price.Templates**: Defines named templates (e.g., "ForexTemplate")
2. **Price.TemplateRateSourceAllocations**: Defines rate sources and priorities for each template
3. **Price.InstrumentToTemplate** (this table): Assigns each instrument to a template
4. **Price.GetInstrumentPriceSources** (view): Joins all three to produce per-instrument rate source allocations
5. **Price.UpdateInstrumentRateSources** (proc): Bulk-rebuilds Price.InstrumentRateSources from GetInstrumentPriceSources

The practical benefit: changing a template's rate source allocations (in TemplateRateSourceAllocations) updates pricing for all instruments assigned to that template in the next bulk refresh, without per-instrument updates.

The table is currently empty (0 rows). No temporal versioning or computed columns - it is a simple, lean assignment table.

---

## 2. Business Logic

### 2.1 One Template per Instrument

**What**: Each instrument belongs to exactly one template. Changing a template's rate source allocations affects all instruments in that template.

**Columns/Parameters Involved**: `InstrumentID`, `TemplateID`

**Rules**:
- PK on InstrumentID enforces one template per instrument
- TemplateID FK -> Price.Templates
- InstrumentID FK -> Trade.Instrument
- No temporal versioning - template assignment changes are not tracked at DB level
- Changing an instrument's template requires an UPDATE to this row, then a bulk refresh via Price.UpdateInstrumentRateSources

### 2.2 Role in GetInstrumentPriceSources

**What**: The view joins InstrumentToTemplate with TemplateRateSourceAllocations to expand template-level configuration to per-instrument rows.

**Rules**:
- `SELECT ITT.InstrumentID, AccountRateSourceID, Priority, PriceServerID FROM TemplateRateSourceAllocations TRSA JOIN InstrumentToTemplate ITT ON TRSA.TemplateID = ITT.TemplateID JOIN Trade.Instrument TI ON ITT.InstrumentID = TI.InstrumentID`
- Each instrument inherits ALL of its template's rate source rows (one row per priority level)
- PriceServerID comes from Trade.Instrument (not stored here)

---

## 3. Data Overview

The table is currently empty (0 rows). No instrument-to-template assignments are configured.

*When populated, rows would appear as:*

| InstrumentID | TemplateID | Meaning |
|---|---|---|
| 1 (EUR/USD) | 1 (ForexTemplate) | EUR/USD inherits ForexTemplate's rate source allocations (FD primary, QuantHouse secondary) |
| 100 | 2 (EquitiesUSTemplate) | Instrument 100 uses the US equities template (Bloomberg primary, IB secondary) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Primary key. FK to Trade.Instrument. The instrument being assigned to a template. One template per instrument enforced by single-column PK. (Trade.Instrument) |
| 2 | TemplateID | int | NOT NULL | - | VERIFIED | FK to Price.Templates. The rate source configuration template this instrument belongs to. All instruments sharing the same TemplateID inherit identical rate source allocations and priorities. (Price.Templates) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_Price_InstrumentTemplate_InstrumentID) | The instrument being assigned |
| TemplateID | Price.Templates | FK (FK_Price_InstrumentTemplate_TemplateID) | The rate source configuration template |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetInstrumentPriceSources | InstrumentID, TemplateID | JOIN | Joins with TemplateRateSourceAllocations to expand template config to per-instrument rate source rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InstrumentToTemplate (table)
|- Trade.Instrument (table, FK target - leaf)
|- Price.Templates (table, FK target - leaf)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target - InstrumentID must reference a valid instrument |
| Price.Templates | Table | FK target - TemplateID must reference a valid template |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetInstrumentPriceSources | View | JOIN source - expands template assignments to per-instrument rate source allocations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PriceInstrumentToTemplate | CLUSTERED PK | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PriceInstrumentToTemplate | PRIMARY KEY | One template per instrument (InstrumentID) |
| FK_Price_InstrumentTemplate_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_Price_InstrumentTemplate_TemplateID | FK | TemplateID -> Price.Templates(TemplateID) |

No temporal versioning, no computed columns.

---

## 8. Sample Queries

### 8.1 View all instrument-template assignments

```sql
SELECT
    ITT.InstrumentID,
    ITT.TemplateID,
    T.Name AS TemplateName
FROM Price.InstrumentToTemplate ITT WITH (NOLOCK)
JOIN Price.Templates T WITH (NOLOCK)
    ON T.TemplateID = ITT.TemplateID
ORDER BY ITT.InstrumentID;
```

### 8.2 View instruments per template with rate source count

```sql
SELECT
    T.TemplateID,
    T.Name AS TemplateName,
    COUNT(DISTINCT ITT.InstrumentID) AS InstrumentCount,
    COUNT(DISTINCT TRSA.AccountRateSourceID) AS RateSourceCount
FROM Price.Templates T WITH (NOLOCK)
LEFT JOIN Price.InstrumentToTemplate ITT WITH (NOLOCK)
    ON ITT.TemplateID = T.TemplateID
LEFT JOIN Price.TemplateRateSourceAllocations TRSA WITH (NOLOCK)
    ON TRSA.TemplateID = T.TemplateID
GROUP BY T.TemplateID, T.Name
ORDER BY T.TemplateID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InstrumentToTemplate | Type: Table | Source: etoro/etoro/Price/Tables/Price.InstrumentToTemplate.sql*
