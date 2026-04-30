# Price.TemplateRateSourceAllocations

> Configuration table that defines which rate source accounts and priorities belong to each pricing template, forming the rate source allocation rows that are inherited by all instruments assigned to that template.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | None (HEAP - no PK or clustered index) |
| **Partition** | No |
| **Indexes** | 0 (no indexes) |

---

## 1. Business Meaning

TemplateRateSourceAllocations is the detail side of the template-based rate source configuration system. Each row assigns a specific `AccountRateSourceID` at a specific `Priority` to a `TemplateID`. All instruments assigned to that template (via `Price.InstrumentToTemplate`) inherit these allocations.

This table is the equivalent of `Price.InstrumentRateSources` at the template level: just as InstrumentRateSources stores per-instrument rate source priorities, TemplateRateSourceAllocations stores per-template rate source priorities. The template approach allows centralized management: one row change here affects all instruments in that template after the next bulk refresh.

The primary consumer is `Price.GetInstrumentPriceSources` (view):
```sql
SELECT ITT.InstrumentID, AccountRateSourceID, Priority, PriceServerID
FROM TemplateRateSourceAllocations TRSA
JOIN InstrumentToTemplate ITT ON TRSA.TemplateID = ITT.TemplateID
JOIN Trade.Instrument TI ON ITT.InstrumentID = TI.InstrumentID
```
This view is the source data for `Price.UpdateInstrumentRateSources`, which bulk-rebuilds `Price.InstrumentRateSources` from it.

Notable: This table is a **HEAP** with no primary key, no clustered index, and no non-clustered indexes. This is unusual for a configuration table but acceptable given the small expected size and the bulk-copy access pattern (full table scan via the view).

Currently 0 rows. The template system is provisioned but not yet populated.

---

## 2. Business Logic

### 2.1 Template Rate Source Allocation

**What**: Each row assigns one AccountRateSource at one priority level to a template. Multiple rows per template create the multi-source priority ordering.

**Columns/Parameters Involved**: `TemplateID`, `AccountRateSourceID`, `Priority`

**Rules**:
- No PK - duplicate (TemplateID, AccountRateSourceID, Priority) combinations are technically possible
- Priority uses the same convention as InstrumentRateSources: 10=primary, 20=secondary, 30=tertiary, 40=quaternary
- AccountRateSourceID FK -> Price.AccountRateSource
- TemplateID FK -> Price.Templates
- Multiple rows per TemplateID (one per source) produce the full priority-ordered source list for that template

### 2.2 Template-to-Instrument Rate Source Expansion

**What**: The view GetInstrumentPriceSources joins this table with InstrumentToTemplate to produce per-instrument source allocations that mirror the format of InstrumentRateSources.

**Rules**:
- One template with 3 rate source rows + 100 instruments assigned -> GetInstrumentPriceSources produces 300 rows (100 instruments x 3 sources each)
- PriceServerID added from Trade.Instrument (not stored in this table)
- The output is then consumed by Price.UpdateInstrumentRateSources for bulk refresh of InstrumentRateSources

---

## 3. Data Overview

The table is currently empty (0 rows). No template rate source allocations are configured.

*When populated, rows would appear as:*

| TemplateID | AccountRateSourceID | Priority | Meaning |
|---|---|---|---|
| 1 (ForexTemplate) | 21 (FD/EtoroAll) | 10 | ForexTemplate primary source is FD |
| 1 (ForexTemplate) | 300 (QuantHouse MBL) | 20 | ForexTemplate secondary source is QuantHouse MBL |
| 1 (ForexTemplate) | 301 (QuantHouse NDF) | 30 | ForexTemplate tertiary source is QuantHouse NDF |
| 2 (EquitiesUS) | 102 (QuantHouse MBO) | 10 | US equities template primary source is QuantHouse MBO |
| 2 (EquitiesUS) | 21 (FD) | 20 | US equities template secondary source is FD |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TemplateID | int | NOT NULL | - | VERIFIED | FK to Price.Templates. The template this rate source allocation belongs to. Multiple rows per TemplateID define the full ordered source list for that template. (Price.Templates) |
| 2 | AccountRateSourceID | int | NOT NULL | - | VERIFIED | FK to Price.AccountRateSource. The rate source (market data feed) assigned to this template at this priority. Identifies the feed provider and account. (Price.AccountRateSource) |
| 3 | Priority | int | NOT NULL | - | VERIFIED | The priority order for this source within the template. Same convention as Price.InstrumentRateSources: 10=primary (queried first), 20=secondary, 30=tertiary, 40=quaternary. Lower value = higher precedence. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TemplateID | Price.Templates | FK (FK_Price_TemplateRateSourceAllocations_TemplateID) | The template this allocation row belongs to |
| AccountRateSourceID | Price.AccountRateSource | FK (FK_Price_TemplateRateSourceAllocations_ARSID) | The rate source feed assigned at this priority |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetInstrumentPriceSources | TemplateID, AccountRateSourceID, Priority | JOIN with InstrumentToTemplate | Expands template allocations to per-instrument rate source rows for bulk refresh |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.TemplateRateSourceAllocations (table)
|- Price.Templates (table, FK target - leaf)
|- Price.AccountRateSource (table, FK target - leaf)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.Templates | Table | FK target - TemplateID must reference a valid template |
| Price.AccountRateSource | Table | FK target - AccountRateSourceID must reference a valid rate source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetInstrumentPriceSources | View | JOIN source - expands to per-instrument rate source rows |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. This table is a HEAP.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_Price_TemplateRateSourceAllocations_TemplateID | FK | TemplateID -> Price.Templates(TemplateID) |
| FK_Price_TemplateRateSourceAllocations_ARSID | FK | AccountRateSourceID -> Price.AccountRateSource(AccountRateSourceID) |

No PK, no clustered index, no temporal versioning, no computed columns, no audit triggers.

---

## 8. Sample Queries

### 8.1 View all template rate source allocations ordered by template and priority

```sql
SELECT
    TRSA.TemplateID,
    T.Name AS TemplateName,
    TRSA.AccountRateSourceID,
    ARS.Name AS SourceName,
    TRSA.Priority
FROM Price.TemplateRateSourceAllocations TRSA WITH (NOLOCK)
JOIN Price.Templates T WITH (NOLOCK)
    ON T.TemplateID = TRSA.TemplateID
JOIN Price.AccountRateSource ARS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = TRSA.AccountRateSourceID
ORDER BY TRSA.TemplateID, TRSA.Priority;
```

### 8.2 Preview what GetInstrumentPriceSources would return when populated

```sql
SELECT
    ITT.InstrumentID,
    TRSA.AccountRateSourceID,
    TRSA.Priority,
    TI.PriceServerID
FROM Price.TemplateRateSourceAllocations TRSA WITH (NOLOCK)
JOIN Price.InstrumentToTemplate ITT WITH (NOLOCK)
    ON ITT.TemplateID = TRSA.TemplateID
JOIN Trade.Instrument TI WITH (NOLOCK)
    ON TI.InstrumentID = ITT.InstrumentID
ORDER BY ITT.InstrumentID, TRSA.Priority;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.TemplateRateSourceAllocations | Type: Table | Source: etoro/etoro/Price/Tables/Price.TemplateRateSourceAllocations.sql*
