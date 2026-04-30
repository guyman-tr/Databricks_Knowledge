# Price.Templates

> Simple named template registry used by the pricing engine's template-based rate source allocation system, where each template defines a named configuration profile that can be assigned to multiple instruments.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | TemplateID (int IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Templates provides the master registry of rate source configuration profiles in the pricing engine's template system. The idea is that many instruments share the same rate source allocation setup (same data feed providers, same priority order). Rather than configuring each instrument individually, templates allow one profile to be defined once and assigned to many instruments.

The template system has three tables:
1. **Price.Templates** (this table): defines named templates (e.g., "ForexTemplate", "EquitiesUS")
2. **Price.InstrumentToTemplate**: assigns each instrument to a template (many instruments -> one template)
3. **Price.TemplateRateSourceAllocations**: defines which rate sources at which priorities belong to each template

Together these three tables feed `Price.GetInstrumentPriceSources` (a view that joins them), which is the source for `Price.UpdateInstrumentRateSources` bulk refresh - the procedure that rebuilds all instrument-rate-source mappings in `Price.InstrumentRateSources`.

Currently 0 rows - the template system is provisioned but not yet populated. The table is extremely simple: just TemplateID (IDENTITY) and Name (varchar(50)). No temporal versioning, no computed columns, no FK constraints.

---

## 2. Business Logic

### 2.1 Template Definition

**What**: A template is a named rate source configuration profile. Multiple instruments can share the same template.

**Columns/Parameters Involved**: `TemplateID`, `Name`

**Rules**:
- TemplateID is auto-incremented IDENTITY - surrogate key
- Name is varchar(50) - human-readable profile name (e.g., "ForexTemplate", "CryptoTemplate")
- No uniqueness constraint on Name in DDL (but logically should be unique for operator clarity)
- Once a template is created, it is referenced by Price.InstrumentToTemplate and Price.TemplateRateSourceAllocations

### 2.2 Template Usage via GetInstrumentPriceSources

**What**: The template system produces per-instrument rate source allocations by joining Templates -> InstrumentToTemplate -> TemplateRateSourceAllocations.

**Rules**:
- `Price.GetInstrumentPriceSources` (view): `SELECT ITT.InstrumentID, AccountRateSourceID, Priority, PriceServerID FROM TemplateRateSourceAllocations TRSA JOIN InstrumentToTemplate ITT ON TRSA.TemplateID = ITT.TemplateID JOIN Trade.Instrument TI ON ITT.InstrumentID = TI.InstrumentID`
- This view is the source for `Price.UpdateInstrumentRateSources` which bulk-rebuilds `Price.InstrumentRateSources`
- The template approach centralizes feed routing configuration: changing a template's rate source allocations automatically updates all instruments assigned to it after the next bulk refresh

---

## 3. Data Overview

The table is currently empty (0 rows). No templates are defined.

*When populated, rows would appear as:*

| TemplateID | Name | Meaning |
|---|---|---|
| 1 | ForexTemplate | Rate source profile for FX instruments: FD primary, QuantHouse secondary |
| 2 | EquitiesUSTemplate | Rate source profile for US equities: Bloomberg primary, IB secondary |
| 3 | CryptoTemplate | Rate source profile for crypto: BitStamp primary, Kraken secondary |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TemplateID | int IDENTITY(1,1) | NOT NULL | auto | VERIFIED | Primary key. Auto-incremented surrogate identifier. Referenced by Price.InstrumentToTemplate and Price.TemplateRateSourceAllocations as FK target. |
| 2 | Name | varchar(50) | NOT NULL | - | VERIFIED | Human-readable name for this template. Identifies the rate source configuration profile (e.g., "ForexTemplate"). No uniqueness constraint in DDL but should be unique for operational clarity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

None. Templates is a root table with no FK dependencies.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.InstrumentToTemplate | TemplateID | FK | Maps instruments to this template (many instruments per template) |
| Price.TemplateRateSourceAllocations | TemplateID | FK | Defines which rate sources and priorities belong to this template |
| Price.GetInstrumentPriceSources | TemplateID | JOIN (via InstrumentToTemplate) | View that joins templates with instruments and rate source allocations to produce per-instrument source routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.Templates (table - leaf, no FK dependencies)
```

### 6.1 Objects This Depends On

None. Templates has no FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentToTemplate | Table | FK target - TemplateID must reference a valid template |
| Price.TemplateRateSourceAllocations | Table | FK target - TemplateID must reference a valid template |
| Price.GetInstrumentPriceSources | View | Joined via InstrumentToTemplate to build per-instrument rate source list |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Price_Templates | CLUSTERED PK | TemplateID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Price_Templates | PRIMARY KEY | One row per template (TemplateID IDENTITY) |

No temporal versioning, no computed columns, no audit triggers.

---

## 8. Sample Queries

### 8.1 View all templates

```sql
SELECT TemplateID, Name
FROM Price.Templates WITH (NOLOCK)
ORDER BY TemplateID;
```

### 8.2 View instruments assigned to each template

```sql
SELECT
    T.TemplateID,
    T.Name AS TemplateName,
    COUNT(ITT.InstrumentID) AS InstrumentCount
FROM Price.Templates T WITH (NOLOCK)
LEFT JOIN Price.InstrumentToTemplate ITT WITH (NOLOCK)
    ON ITT.TemplateID = T.TemplateID
GROUP BY T.TemplateID, T.Name
ORDER BY T.TemplateID;
```

### 8.3 View rate source allocations per template

```sql
SELECT
    T.TemplateID,
    T.Name AS TemplateName,
    TRSA.AccountRateSourceID,
    TRSA.Priority
FROM Price.Templates T WITH (NOLOCK)
JOIN Price.TemplateRateSourceAllocations TRSA WITH (NOLOCK)
    ON TRSA.TemplateID = T.TemplateID
ORDER BY T.TemplateID, TRSA.Priority;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 4, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.Templates | Type: Table | Source: etoro/etoro/Price/Tables/Price.Templates.sql*
