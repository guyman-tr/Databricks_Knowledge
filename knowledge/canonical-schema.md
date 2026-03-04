# Canonical Metadata Schema

**Version**: 1.0.0 | **Created**: 2026-03-01 | **Spec**: 001 (Integrate Trading Platform Knowledge)
**Authority**: Constitution v1.2.0, Principle V — all knowledge must conform to this schema.
**Template Source**: `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` (Phase 11 query-brain template)

---

## 1. What Is a DataObject?

A **DataObject** is a table, view, function, or stored procedure at a specific data layer (Production, Synapse, Lake, or Unity Catalog). Each layer instance is a **separate DataObject** with its own full record. Cross-layer equivalents are connected by lineage edges, not sub-records.

Example: Production `Trade.PositionTbl`, Synapse `DWH_dbo.Dim_Position`, and UC `trading.bronze_etoro_trade_positiontbl` are three distinct DataObjects linked by lineage.

---

## 2. Schema Fields

Every DataObject wiki file MUST contain the following sections and fields. The structure mirrors the Phase 11 query-brain template exactly.

### 2.1 Header

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| **Object Name** | YES | `{Schema}.{ObjectName}` — fully qualified name at this layer | `DWH_dbo.Dim_Position` |
| **One-Line Description** | YES | Single sentence: what this object represents in business terms | "Dimension table of all trading positions..." |

### 2.2 Properties Table

| Field | Required | Description | Valid Values |
|-------|----------|-------------|--------------|
| **Schema** | YES | Database schema name | `DWH_dbo`, `Trade`, `Customer` |
| **Object Type** | YES | What kind of database object | `Table`, `View`, `Stored Procedure`, `Function` |
| **Distribution** | Synapse only | Synapse distribution strategy | `HASH(column)`, `ROUND_ROBIN`, `REPLICATE`, `N/A` |
| **Index Type** | Synapse only | Primary index structure | `CLUSTERED COLUMNSTORE`, `CLUSTERED INDEX(cols)`, `HEAP`, `N/A` |
| **Production Source** | YES | Upstream production table(s) this object derives from | `Trade.PositionTbl`, `Multiple sources`, `Derived`, `N/A` |
| **Refresh** | When known | How frequently the data is updated | `Hourly`, `Daily`, `Real-time`, `Unknown` |

### 2.3 Business Meaning (Section 1)

Three paragraphs:

| Paragraph | Purpose |
|-----------|---------|
| **WHAT** | What this object represents in the business. Plain English for an analyst who knows SQL but not this dataset. |
| **WHERE FROM** | Lineage narrative: production source → lake export → Synapse ETL → this table. References upstream wiki by path. |
| **HOW FRESH** | ETL procedure name, load pattern (full/incremental/merge), refresh frequency, lag behind production. |

### 2.4 Business Logic (Section 2)

Zero or more numbered subsections (`2.1`, `2.2`, ...), each containing:

| Field | Required | Description |
|-------|----------|-------------|
| **Concept Name** | YES | Short name for the business concept |
| **What** | YES | One sentence: what business concept this represents |
| **Columns Involved** | YES | List of columns that participate in this concept |
| **Rules** | YES | Plain English rules — what values mean, how they combine |
| **Diagram** | Optional | ASCII diagram showing hierarchy, state machine, or flow |

### 2.5 Query Advisory (Section 3)

Synapse-specific section — the key differentiator from the upstream production wiki.

| Subsection | Description |
|------------|-------------|
| **3.1 Distribution Key** | Which column, what it means for query performance, partition elimination tips |
| **3.2 Common Query Patterns** | 3-5 analyst questions with recommended approaches (table format) |
| **3.3 Common JOINs** | Table: Join To, Join Condition, Purpose |
| **3.4 Gotchas** | Things that trip up analysts — unexpected values, naming confusion, performance traps |

For non-Synapse objects (production wiki, UC), write "N/A for {layer}." — do NOT remove the section.

### 2.6 Elements (Section 4)

Every column/parameter. No skipping, no grouping.

| Column | Required | Description |
|--------|----------|-------------|
| **#** | YES | Ordinal position |
| **Element** | YES | Column or parameter name |
| **Type** | YES | SQL data type |
| **Nullable** | YES | `YES` or `NO` |
| **Default** | Production only | Default constraint value (omit for Synapse/UC if not applicable) |
| **Description** | YES | Meaningful business description. For ID columns: include resolved value map with source. For amounts: include units. For dates: explain when set. For flags: explain both values. |

**Description quality rules**:
- No raw IDs left unexplained — every `*ID` column must reference its lookup table and list known values
- Enum values must include the source (e.g., "from Dictionary.SettlementTypes" or "observed in production data")
- Deprecated/legacy columns must be explicitly marked with what replaced them
- Sentinel values must be documented (e.g., "Default=1 is a sentinel meaning 'no parent'")

### 2.7 Lineage (Section 5)

Two subsections:

**5.1 Production Sources** — Column-level lineage:

| Column | Required | Description |
|--------|----------|-------------|
| **Synapse Column** | YES | Column name in this object |
| **Production Source** | YES | `{Schema}.{Table}` in production |
| **Source Column** | YES | Column name in production |
| **Transform** | YES | `None` (passthrough), expression, or `CASE mapping` |

Plus a link to the upstream wiki file path.

**5.2 ETL Pipeline** — Object-level lineage chain:

| Step | Required Fields |
|------|----------------|
| Source | Production table + description |
| Lake | Lake path + export frequency |
| Staging | Staging table name |
| ETL | SP name + transformations applied |
| Target | This table |

### 2.8 Relationships (Section 6)

Two subsections:

**6.1 References To** (this object points to):

| Column | Required | Description |
|--------|----------|-------------|
| **Element** | YES | Column in this object |
| **Related Object** | YES | Target `{Schema}.{Object}` |
| **Relationship Type** | Production only | `Explicit FK`, `Implicit (no FK)`, `Implicit JOIN`, `Self-Reference`, `Lookup` |
| **Description** | YES | Business meaning of the relationship |

**6.2 Referenced By** (other objects point to this):

| Column | Required | Description |
|--------|----------|-------------|
| **Source Object** | YES | `{Schema}.{Object}` that references this one |
| **Source Element** | YES | Column or context |
| **Relationship Type** | Production only | Same categories as 6.1 |
| **Description** | YES | Business meaning |

### 2.9 Sample Queries (Section 7)

At least 3 practical queries answering real business questions. Each has:
- A business question as the subsection title
- A working SQL query
- At least one query should resolve IDs to human-readable names via JOINs

### 2.10 Atlassian Knowledge Sources (Section 8)

| Column | Required | Description |
|--------|----------|-------------|
| **Source** | YES | Linked page title or ticket key |
| **Type** | YES | `Confluence` or `Jira` |
| **Key Knowledge Extracted** | YES | One-sentence summary of what was learned |

If Phase 10 found nothing: "No Atlassian sources found for this object."

### 2.11 Footer Metadata

Single line at the bottom:

```
*Generated: {YYYY-MM-DD} | Object: {Schema}.{ObjectName} | Type: {Object Type} | Phases: {N}/{Total}*
*Production Source: {Production table path or "N/A"}*
```

### 2.12 Review Sidecar (`.review-needed.md`)

Every wiki file MUST have a companion sidecar at `{Schema}.{ObjectName}.review-needed.md` in the same directory. The sidecar serves two purposes:

**Outbound (pipeline → reviewer):**
- Lists all Tier 4 (UNVERIFIED) columns with questions for domain experts
- Lists columns with conflicting/ambiguous evidence regardless of tier
- Lists structural or design questions unanswerable from code alone

**Inbound (reviewer → pipeline):**
- Contains a `## Reviewer Corrections` section where domain experts record corrections
- Each correction row specifies: Column/Topic, Current (wrong) value, Correction, Scope, Reviewer, Date
- Corrections are Tier 5 authority (overrides all other tiers)
- Corrections with `Scope = glossary` should also appear in `knowledge/glossary.md`

**Rerun behavior:**
- Pipeline reads `## Reviewer Corrections` FIRST before regenerating
- Applies all corrections as Tier 5 overrides in the new wiki
- Carries resolved corrections forward with `[RESOLVED]` prefix
- Removes resolved items from Tier 4 / Clarification sections

### 2.13 Domain Glossary (`knowledge/glossary.md`)

A single shared file containing domain-wide terms, acronym expansions, and value maps confirmed by domain experts. All entries are **Tier 5** authority.

**Sections:**
- `## Acronyms & Terms` — Term, Expansion, Context, Added By, Date
- `## Value Maps` — Table.Column, Value, Meaning, Added By, Date

**Pipeline consumption:**
- Phase 4 (Lookup Resolution): Read before any other resolution step
- Phase 11 (Generate Documentation): Read before generating element descriptions
- Glossary entries override any pipeline-inferred expansions

---

## 3. Layer-Specific Variations

The canonical schema accommodates all four data layers. Some fields are layer-specific:

| Field | Production | Synapse | Lake | Unity Catalog |
|-------|------------|---------|------|---------------|
| Distribution | N/A | Required | N/A | N/A |
| Index Type | Full index table | Required | N/A | N/A |
| Query Advisory (Section 3) | N/A | Required | N/A | N/A |
| Default values in Elements | Required | Optional | N/A | N/A |
| Relationship Type column | Required | Optional | N/A | N/A |
| Technical Details (indexes, constraints) | Full section | Optional | N/A | N/A |
| UC Description (1024-char) | N/A | N/A | N/A | Required |

**Production wiki objects** follow the `sql-semantic-doc` pipeline template, which includes additional sections:
- **Section 3: Data Overview** (representative rows) — maps to Business Logic context
- **Section 7: Technical Details** (indexes, constraints) — operational, not carried to canonical unless query-relevant
- **Section 9: Atlassian Knowledge Sources** — same as canonical Section 8

**Synapse wiki objects** follow the `dwh-semantic-doc` pipeline template (Phase 11), which IS the canonical template.

**Unity Catalog objects** use the canonical template with descriptions compressed to 1024 characters per the UC limit.

---

## 4. Source Attribution Convention

> Full convention detailed in [Section 6](#6-source-attribution) below. Summary here for quick reference.

Every metadata element in a wiki file has an implicit or explicit **source** — which knowledge source contributed it and at what authority tier. The authority hierarchy (Constitution v1.2.0, Principle II):

| Tier | Source | Wins For |
|------|--------|----------|
| 1 | Upstream semantic wiki | Everything it covers — already validated through full code-is-king pipeline |
| 2 | Live code (Synapse SPs, views, functions) | DWH-specific transformations, derived columns, ETL logic |
| 3 | Live data (sampling, actual values) | Empirical evidence — undocumented enum values, NULL patterns |
| 4 | Metadata views (INFORMATION_SCHEMA, sys.*) | Structural truth — types, nullability, distribution |
| 5 | Confluence / Jira | Business intent and context (frequently stale) |
| 6 | Human descriptions | Lowest weight |

---

## 5. Domain and Tag Fields

DataObjects belong to one or more **Domains** (many-to-many). Domain assignment is tracked at the object level:

| Field | Description |
|-------|-------------|
| **Domain** | Logical grouping: `Trading`, `Payments`, `Risk`, `Revenue`, `Customer`, etc. |
| **Source Schema → BusinessUnit** | The production source schema implies BU ownership (e.g., `Trade` schema → Trading BU) |

**UC Tags** (Spec 007, generated separately):

| Tag | Source | Description |
|-----|--------|-------------|
| `owner` | Inferred from source schema BU | Team/BU responsible |
| `domain` | Domain assignment | Routing tag for agent |
| `layer` | Object layer | `production`, `synapse`, `lake`, `uc` |
| `refresh_frequency` | Phase 9b / Phase 14 | `hourly`, `daily`, `real-time`, `unknown` |
| `source_system` | Lineage | Production database name |
| `sla` | Manual | Left blank until defined |
| `certified` | Manual | Left blank until certified |
| `pii` | Column-level (Spec 007) | `direct`, `indirect`, `none` |

---

## 6. Source Attribution

### 6.1 Attribution Model

Each metadata element in a wiki file carries an **implied source tier** based on the pipeline phase that produced it:

| Pipeline Phase | Produces | Default Source Tier |
|----------------|----------|-------------------|
| Pre-read (upstream wiki) | Business meaning, element descriptions, relationships, business logic, enum values | Tier 1 (upstream wiki) |
| Phase 1 (Structure) | Column names, types, nullability, distribution | Tier 4 (metadata) |
| Phase 2 (Sampling) | Data patterns, NULL rates, representative values | Tier 3 (live data) |
| Phase 3 (Distribution) | Enum values, flag patterns, value distributions | Tier 3 (live data) |
| Phase 4 (Lookup Resolution) | ID→name mappings from Dictionary tables | Tier 1 (upstream wiki) or Tier 3 (live data) |
| Phase 5 (JOIN Analysis) | Implicit relationships, JOIN patterns | Tier 2 (live code) |
| Phase 6 (Business Logic) | Column groups, hierarchies, state machines | Tier 2 (live code) + Tier 3 (live data) |
| Phase 7 (View Dependencies) | View chains, dependency graphs | Tier 2 (live code) |
| Phase 8 (Procedure Scan) | SP references, read/write classification | Tier 2 (live code) |
| Phase 9 (Procedure Logic) | Column assignments, transformation rules, business logic | Tier 2 (live code) |
| Phase 9b (ETL Orchestration) | Refresh schedule, SP execution order | Tier 2 (live code) |
| Phase 10 (Atlassian) | Business context, intent, historical notes | Tier 5 (Confluence/Jira) |
| Phase 11 (Documentation) | Final assembly — no new facts, only synthesis | Inherits from inputs |
| Phase 12 (Cross-Object) | Consistency checks, gap filling from sibling objects | Inherits from source object |
| Phase 13 (Lineage Mapping) | Production→Lake→Synapse chain | Tier 2 (live code) + Tier 4 (metadata) |
| Phase 14 (Query Advisory) | Distribution tips, recommended patterns | Tier 2 (live code) + Tier 3 (live data) |

### 6.2 Inline Attribution

When sources conflict, the winning source is cited inline in the description:

```markdown
Position state: 1=Open, 2=Being Closed (from upstream wiki: Trade.PositionTbl §2.1, confirmed by Synapse SP DWH_dbo.Load_Dim_Position)
```

When an undocumented value is discovered:

```markdown
SettlementTypeID: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE (from upstream wiki). Value 6 observed in 12 Synapse rows — undocumented, flagged for investigation.
```

When Atlassian context supplements but doesn't override:

```markdown
Business context: "Position P&L includes overnight fees" (Confluence: Trading Architecture, 2024-11. Note: upstream wiki and SP code confirm fee accumulation in EndOfWeekFee column).
```

### 6.3 Collision Resolution Rules

1. **Same fact, multiple tiers**: Higher tier wins. Document the override if the lower-tier source said something different.
2. **Same tier, different dates**: Newer wins (recency tiebreaker from Constitution v1.2.0).
3. **Complementary facts, no conflict**: Merge from all sources. Attribute each.
4. **Upstream wiki + new DWH-only evidence**: Both are valid. The wiki provides the production baseline; Synapse evidence adds DWH-specific context.
5. **Undocumented values**: Include them, flag them. Never silently drop evidence.

---

## 7. Template Compliance Validation

A wiki file is **schema-compliant** when:

- [ ] Header has `{Schema}.{ObjectName}` title and one-line description
- [ ] Properties table has all required fields for the object's layer
- [ ] Section 1 (Business Meaning) has WHAT, WHERE FROM, and HOW FRESH paragraphs
- [ ] Section 2 (Business Logic) has at least one concept OR states "No business logic discovered"
- [ ] Section 3 (Query Advisory) is populated for Synapse objects or marked N/A for other layers
- [ ] Section 4 (Elements) lists EVERY column/parameter with meaningful descriptions
- [ ] Every `*ID` column in Section 4 has its lookup values resolved
- [ ] Section 5 (Lineage) traces to production source(s) or states derivation
- [ ] Section 6 (Relationships) lists both directions (references to + referenced by)
- [ ] Section 7 (Sample Queries) has at least 3 queries, one with ID-resolving JOINs
- [ ] Section 8 (Atlassian Sources) is populated or explicitly states "none found"
- [ ] Footer metadata is present with generation date and phase count
- [ ] All descriptions fit within 1024 characters when targeting UC (Spec 005-006)
- [ ] Source attribution follows the hierarchy — no tier-5 source overriding a tier-1 source

---

## 8. Schema Versioning

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-03-01 | Initial canonical schema extracted from Phase 11 template. Fields: object identity, properties, business meaning, business logic, query advisory, elements, lineage, relationships, sample queries, Atlassian sources, footer metadata. Source attribution convention defined. |

Amendments must be backward-compatible: new optional fields may be added; existing required fields may not be removed without a major version bump.

---

## Appendix A: Upstream Wiki Compatibility Verification

**Date**: 2026-03-01 | **Task**: T007

Verified 3 upstream wiki files from `DB_Schema/etoro/Wiki/` parse into canonical schema fields:

### A.1 Objects Tested

| Object | Type | Columns | Sections |
|--------|------|---------|----------|
| `Trade.PositionTbl` | Table | 117 | 9 sections (Meaning, Logic, Data Overview, Elements, Relationships, Dependencies, Technical, Queries, Atlassian) |
| `Trade.Mirror` | Table | 20 | 9 sections (same structure) |
| `Trade.PositionClose` | Stored Procedure | 48 params | 9 sections (params as elements, no Data Overview) |

### A.2 Field Mapping: Upstream Wiki → Canonical Schema

| Canonical Field | Upstream Wiki Field | Status | Notes |
|----------------|--------------------|---------| ------|
| Object Name | `# {Schema}.{ObjectName}` | ✅ Direct | Identical format |
| One-Line Description | `> {description}` | ✅ Direct | Blockquote format matches |
| Schema | Properties table "Schema" | ✅ Direct | |
| Object Type | Properties table "Type" | ✅ Direct | |
| Distribution | N/A | ✅ Expected | Production objects have no distribution strategy |
| Index Type | Properties table "Indexes" | ⚠️ Adaptation | Upstream lists count; canonical needs type. Available in Technical Details section |
| Production Source | N/A | ✅ Expected | Upstream wiki IS the production source |
| Refresh | N/A | ✅ Expected | Not applicable at production layer |
| Business Meaning (§1) | Section 1: 3 paragraphs | ✅ Direct | WHAT/WHY/HOW maps to WHAT/WHERE FROM/HOW FRESH |
| Business Logic (§2) | Section 2: numbered concepts | ✅ Direct | Same structure: concept, columns, rules, diagrams |
| Query Advisory (§3) | N/A (§3 = Data Overview) | ✅ Expected | Query advisory is Synapse-specific; production uses Data Overview |
| Elements (§4) | Section 4: full column table | ✅ Direct | All columns listed with descriptions, types, nullability, defaults |
| Lineage (§5) | Section 5 = Relationships | ⚠️ Reinterpret | Upstream has relationships in §5; canonical uses §5 for lineage. Cross-layer lineage traced at Synapse layer. |
| Relationships (§6) | Section 5: References To/By | ✅ Direct | Same "References To" + "Referenced By" structure |
| Sample Queries (§7) | Section 8: Queries | ✅ Direct | 3+ queries with business questions |
| Atlassian Sources (§8) | Section 9: Atlassian | ✅ Direct | Source, Type, Key Knowledge format matches |
| Footer Metadata | Footer line | ✅ Direct | Date, object, type, phases |

### A.3 Semantic Metadata Preservation

All semantic metadata from the upstream wiki maps without loss:

- **Column descriptions**: ✅ Full descriptions with enum values, sentinels, lifecycle notes
- **Enum/lookup values**: ✅ Resolved with source tables (e.g., "Dictionary.SettlementTypes: 0=CFD, 1=REAL...")
- **Relationships (explicit + derived)**: ✅ Both "References To" and "Referenced By" with relationship type classification
- **Business logic concepts**: ✅ Concepts with rules, involved columns, and ASCII diagrams
- **Sample queries**: ✅ Practical queries with business context
- **Atlassian context**: ✅ Confluence pages and Jira tickets with extracted knowledge

### A.4 Section Numbering Difference

The upstream wiki (sql-semantic-doc template) uses a different section numbering than the canonical (dwh-semantic-doc template):

| Upstream Wiki (Production) | Canonical (Synapse/DWH) |
|---------------------------|------------------------|
| §3 Data Overview | §3 Query Advisory |
| §5 Relationships | §5 Lineage |
| §6 Dependencies | §6 Relationships |
| §7 Technical Details | (operational — not in canonical) |
| §8 Sample Queries | §7 Sample Queries |
| §9 Atlassian Sources | §8 Atlassian Sources |

This difference is by design — each template is optimized for its layer. The canonical schema (Section 3) documents these as "Layer-Specific Variations." When consuming upstream wiki content during Phase 11 generation, the pipeline maps sections by semantic meaning, not by number.

### A.5 Conclusion

All 3 upstream wiki files parse cleanly into canonical schema fields. No semantic metadata loss. Section numbering differs between templates but the content is structurally compatible. The canonical schema correctly accommodates both production and Synapse layers through the layer-specific variations documented in Section 3.

---

## Appendix B: 5-Object Mapping Verification

**Date**: 2026-03-01 | **Task**: T008

Mapped 5 trading platform objects from upstream wiki to canonical schema. Tested across object types (large table, mid-size table, dictionary lookup, customer master, pending order table) and schemas (Trade, Customer, Dictionary).

### B.1 Objects Mapped

| # | Object | Schema | Type | Columns | Wiki Sections | Result |
|---|--------|--------|------|---------|---------------|--------|
| 1 | `Trade.PositionTbl` | Trade | Table | 117 | 9 | ✅ Full fit |
| 2 | `Trade.Mirror` | Trade | Table | 20 | 9 | ✅ Full fit |
| 3 | `Trade.Orders` | Trade | Table | 33 | 9 | ✅ Full fit |
| 4 | `Dictionary.SettlementTypes` | Dictionary | Table (lookup) | 2 | 9 | ✅ Full fit |
| 5 | `Customer.CustomerStatic` | Customer | Table | 70+ | 9 | ✅ Full fit |

### B.2 Canonical Schema Mapping Per Object

#### Trade.PositionTbl (117 columns, 6 business logic concepts)

| Canonical Section | Populated | Quality |
|------------------|-----------|---------|
| Header + one-line | ✅ | Rich business description |
| Properties | ✅ | Key Identifier, Partition, Indexes (layer-adapted) |
| Business Meaning (§1) | ✅ | 3 paragraphs: what/lineage/lifecycle |
| Business Logic (§2) | ✅ | 6 concepts: Lifecycle, Settlement, Copy Tree, Partial Close, NFT Redeem, Hedge Control |
| Elements (§4) | ✅ | All 117 columns with descriptions, enums, sentinels, deprecation notes |
| Relationships (§5/6) | ✅ | 15 "References To" + 17 "Referenced By" with relationship types |
| Sample Queries (§7/8) | ✅ | 3 queries with JOINs resolving IDs |
| Atlassian (§8/9) | ✅ | 2 Confluence pages |
| Footer | ✅ | Generated/enriched dates, phases |

#### Trade.Mirror (20 columns, copy trading)

| Canonical Section | Populated | Quality |
|------------------|-----------|---------|
| Header + one-line | ✅ | Clear copy-trading description |
| Properties | ✅ | Includes IDENTITY PK, trigger note |
| Business Meaning (§1) | ✅ | WHAT/WHY/HOW paragraphs |
| Business Logic (§2) | ✅ | 5 concepts: Lifecycle, Balance, StopLoss, CopyTypes, Reopen |
| Elements (§4) | ✅ | All 20 columns + BIT consequence table with code evidence |
| Relationships (§5/6) | ✅ | 7 "References To" + 3 "Referenced By" + cross-reference section |
| Sample Queries | ✅ | 3 queries |
| Atlassian | ✅ | 13 sources (10 Confluence + 3 Jira) |
| Footer | ✅ | |

#### Trade.Orders (33 columns, pending orders)

| Canonical Section | Populated | Quality |
|------------------|-----------|---------|
| Header + one-line | ✅ | Distinguishes from market orders |
| Properties | ✅ | |
| Business Meaning (§1) | ✅ | Lifecycle + distinction from other order tables |
| Business Logic (§2) | ✅ | 6 concepts: Lifecycle, Validations, StockSplit, Copy+, Settlement, TSL |
| Elements (§4) | ✅ | All columns with constraints noted |
| Relationships | ✅ | References To + Referenced By |
| Sample Queries | ✅ | 3 queries |
| Atlassian | ✅ | |
| Footer | ✅ | |

#### Dictionary.SettlementTypes (2 columns, lookup)

| Canonical Section | Populated | Quality |
|------------------|-----------|---------|
| Header + one-line | ✅ | Concise lookup description |
| Properties | ✅ | |
| Business Meaning (§1) | ✅ | Short — appropriate for lookup table |
| Business Logic (§2) | ✅ | 1 concept: Settlement Type Enumeration with all 6 values |
| Elements (§4) | ✅ | 2 columns (ID + Name), enum values inline |
| Relationships | ✅ | No outgoing; 4 inbound references |
| Sample Queries | ✅ | 3 queries including JOIN to PositionTbl |
| Atlassian | ✅ | "No sources found" — explicit, not omitted |
| Footer | ✅ | |

#### Customer.CustomerStatic (70+ columns, customer master)

| Canonical Section | Populated | Quality |
|------------------|-----------|---------|
| Header + one-line | ✅ | Customer profile master |
| Properties | ✅ | |
| Business Meaning (§1) | ✅ | WHAT/WHY/HOW including vertical split explanation |
| Business Logic (§2) | ✅ | 4 concepts: Hedging, History Versioning, Linked Account, Email Tracking |
| Elements (§4) | ✅ | All columns including computed columns |
| Relationships | ✅ | Rich — 20+ references |
| Sample Queries | ✅ | 3 queries |
| Atlassian | ✅ | |
| Footer | ✅ | |

### B.3 Gaps Identified

| # | Gap | Severity | Resolution |
|---|-----|----------|------------|
| 1 | **Properties table fields vary**: Upstream uses "Key Identifier", "Partition", "Row Count", "Date Range" vs. canonical's "Distribution", "Index Type", "Production Source", "Refresh" | Low | By design — layer-specific. No change needed. Consuming pipeline maps by semantic meaning. |
| 2 | **Section 3 differs**: Upstream = "Data Overview" (sample rows), Canonical = "Query Advisory" (Synapse performance) | Low | By design — Query Advisory is Synapse-specific value-add. Data Overview samples are consumed during Phase 2-3, not carried to canonical output. |
| 3 | **Technical Details section** (indexes, constraints, triggers): Present in upstream wiki but absent from canonical template | Low | Intentional. Canonical is "query brain" for analysts, not DBA reference. Index info is carried only in Query Advisory §3.1 (distribution key) when query-relevant. |
| 4 | **Dependencies section** (§6 in upstream): Lists "Depends On" and "Depended On By" with procedure counts | Low | Merged into Relationships (§6) in canonical. Procedure references are captured but operational counts (how many SPs) are trimmed. |
| 5 | **Row Count / Date Range**: Present in upstream properties, not in canonical | None | Operational metadata — excluded per constitution (Principle III: no environment-specific statistics in wiki files). |
| 6 | **BIT consequence table** (Trade.Mirror): Extra subsection showing business consequence of flag values with code evidence | None | Valuable enrichment. Absorbed into Element descriptions in canonical. Not a gap — just a formatting difference. |

### B.4 Conclusion

All 5 objects map to the canonical schema without semantic data loss. The 6 gaps identified are all **by design** (layer-specific variations) or **intentional exclusions** (operational metadata). No schema amendments required.

The canonical schema successfully accommodates:
- Large tables (117 columns) — PositionTbl
- Mid-size tables (20 columns) — Mirror
- Lookup/dictionary tables (2 columns) — SettlementTypes
- Customer master tables (70+ columns with computed columns) — CustomerStatic
- Order lifecycle tables (33 columns) — Orders

---

## Appendix C: Cross-Layer Validation — 3 Synapse DWH Objects

**Date**: 2026-03-01 | **Task**: T009

Validated the canonical schema against 3 `DWH_dbo` Synapse objects, covering three distinct archetypes: large dimension, large fact, and small replicated lookup. Metadata obtained via Synapse `INFORMATION_SCHEMA.COLUMNS`, `sys.pdw_table_distribution_properties`, `sys.pdw_column_distribution_properties`, `sys.indexes`, and `sys.dm_pdw_nodes_db_partition_stats`.

### C.1 Objects Tested

| # | Object | Archetype | Columns | Distribution | Index | Approx Rows |
|---|--------|-----------|---------|--------------|-------|-------------|
| 1 | `DWH_dbo.Dim_Customer` | Large dimension | 107 | HASH(RealCID) | CLUSTERED | ~45.8M |
| 2 | `DWH_dbo.Fact_BillingDeposit` | Large fact | 136 | HASH(DepositID) | CLUSTERED | ~71.8M |
| 3 | `DWH_dbo.Dim_Country` | Small replicated lookup | 19 | REPLICATE | HEAP | 251 |

### C.2 Canonical Schema Fit Per Object

#### DWH_dbo.Dim_Customer (107 columns — customer master dimension)

| Canonical Section | Fit | Notes |
|------------------|-----|-------|
| Header (Object Name) | ✅ | `DWH_dbo.Dim_Customer` — fully qualified |
| Properties (Schema, Type, Distribution, Index) | ✅ | Schema=DWH_dbo, Type=Table, Distribution=HASH(RealCID), Index=CLUSTERED |
| Production Source | ✅ mappable | Inferred: `Customer.CustomerStatic` (upstream wiki exists, mapped in Appendix B) |
| Business Meaning (§1) | ✅ | WHAT: customer master. WHERE FROM: Customer schema → lake → Synapse ETL. HOW FRESH: determinable via SP scan |
| Business Logic (§2) | ✅ | Rich candidate: verification levels, risk status, regulation, copy trading metrics, funnel tracking |
| Query Advisory (§3) | ✅ | HASH on RealCID means co-located JOINs with any fact on CID. CLUSTERED enables efficient range scans |
| Elements (§4) | ✅ | All 107 columns mappable. 40+ `*ID` columns need lookup resolution. Flags (IsDepositor, IsCopyBlocked, IsEDD) need business descriptions |
| Lineage (§5) | ✅ | Column-level: most columns pass through from `Customer.CustomerStatic`. ETL pipeline traceable |
| Relationships (§6) | ✅ | Heavy referencing: CountryID→Dim_Country, CampaignID→Dim_Campaign, RegulationID→lookup, etc. Referenced by fact tables on CID/GCID |
| Sample Queries (§7) | ✅ | Natural: "Depositors by country", "Customers by regulation", "Copy trading guru stats" |
| Atlassian Sources (§8) | ✅ | Customer/KYC/compliance topics likely in Confluence |
| Footer | ✅ | Standard format |

**ID columns requiring resolution** (sample): PlayerStatusID, RiskStatusID, RiskClassificationID, AccountTypeID, RegulationID, PlayerLevelID, AccountStatusID, VerificationLevelID, GuruStatusID, FunnelID, SuitabilityTestStatusID, MifidCategorizationID, ScreeningStatusID, DocumentStatusID, WorldCheckID, TanganyStatusID, DltStatusID, StocksLendingStatusID, CashoutFeeGroupID.

#### DWH_dbo.Fact_BillingDeposit (136 columns — financial deposit fact)

| Canonical Section | Fit | Notes |
|------------------|-----|-------|
| Header (Object Name) | ✅ | `DWH_dbo.Fact_BillingDeposit` — fully qualified |
| Properties (Schema, Type, Distribution, Index) | ✅ | Schema=DWH_dbo, Type=Table, Distribution=HASH(DepositID), Index=CLUSTERED |
| Production Source | ✅ mappable | Inferred: `Billing.Deposit` or similar payment/billing schema |
| Business Meaning (§1) | ✅ | WHAT: deposit transactions. WHERE FROM: billing system → lake → Synapse. HOW FRESH: determinable |
| Business Logic (§2) | ✅ | Concepts: payment lifecycle (Approved, PaymentStatusID), FTD tracking (IsFTD), bonus flow (BonusStatusID, BonusAmount), risk management (RiskManagementStatusID), AFT processing |
| Query Advisory (§3) | ✅ | HASH on DepositID — unique per transaction. Queries filtering by CID will cause data movement. Recommend pre-filtering via Dim_Customer |
| Elements (§4) | ✅ | All 136 columns mappable. ~60 `nvarchar(-1)` columns suggest denormalized payment provider response fields (e.g., CardNumberAsString, BankAccountAsString). These need "PII/sensitive" flags |
| Lineage (§5) | ✅ | Column-level mapping needed. Many `*AsString`/`*AsDecimal`/`*AsInteger` columns suggest XML/JSON shredding from payment provider responses |
| Relationships (§6) | ✅ | CID→Dim_Customer, CurrencyID→Dim_Currency, FundingID→lookup, ManagerID→Dim_Manager, CountryIDAsInteger→Dim_Country |
| Sample Queries (§7) | ✅ | "Total deposits by country", "FTD conversion by campaign", "Deposit amounts by funding type" |
| Atlassian Sources (§8) | ✅ | Billing/payments topics expected |
| Footer | ✅ | Standard format |

**Observation**: The large number of `nvarchar(max)` columns (60+) with naming pattern `*AsString`, `*AsDecimal`, `*AsInteger` suggests these were shredded from a payment processor API response. The canonical schema handles this via Element descriptions — each needs a note explaining "Denormalized from payment provider response. Original type: {x}."

#### DWH_dbo.Dim_Country (19 columns — replicated country lookup)

| Canonical Section | Fit | Notes |
|------------------|-----|-------|
| Header (Object Name) | ✅ | `DWH_dbo.Dim_Country` — fully qualified |
| Properties (Schema, Type, Distribution, Index) | ✅ | Schema=DWH_dbo, Type=Table, Distribution=REPLICATE, Index=HEAP |
| Production Source | ✅ mappable | Inferred: `Dictionary.Country` or `Customer.Country` |
| Business Meaning (§1) | ✅ | WHAT: country reference/lookup. WHERE FROM: production dictionary. HOW FRESH: infrequent updates |
| Business Logic (§2) | ✅ | Concepts: risk classification (IsHighRiskCountry, RiskGroupID), regulatory mapping (RegulationID), regional grouping (Region, MarketingRegionID, IsEuropeanCountry), eligibility rules (IsEligibleForRAFBonusCountry) |
| Query Advisory (§3) | ✅ | REPLICATE distribution = available on every node, zero data movement for JOINs. HEAP index = no ordering. Small table — full scan is fine |
| Elements (§4) | ✅ | All 19 columns. ID columns: StatusID, RegulationID, MarketingRegionID, RiskGroupID, DWHCountryID, CFKey need resolution |
| Lineage (§5) | ✅ | Simple passthrough from production dictionary |
| Relationships (§6) | ✅ | Heavily referenced BY: Dim_Customer.CountryID, Dim_Customer.CountryIDByIP, Dim_Customer.CitizenshipCountryID, Fact_BillingDeposit.CountryIDAsInteger, etc. |
| Sample Queries (§7) | ✅ | "Countries by regulation", "High-risk country list", "European country lookup" |
| Atlassian Sources (§8) | ✅ | Regulatory country classification likely documented |
| Footer | ✅ | Standard format |

### C.3 Synapse-Specific Schema Fields Validation

The three objects exercise all Synapse-specific canonical fields:

| Synapse Field | Dim_Customer | Fact_BillingDeposit | Dim_Country | Coverage |
|---------------|-------------|---------------------|-------------|----------|
| Distribution type | HASH | HASH | REPLICATE | 2 of 3 strategies (ROUND_ROBIN not seen here but schema supports it) |
| Distribution column | RealCID | DepositID | N/A (replicated) | ✅ Present when HASH |
| Index type | CLUSTERED | CLUSTERED | HEAP | 2 of 3 types (CLUSTERED COLUMNSTORE not seen) |
| Query Advisory needed | Yes — co-location | Yes — data movement warning | Yes — replicate benefits | ✅ All need distinct advisory |

### C.4 Cross-Object Relationship Validation

The 3 objects form a natural star-schema relationship that validates the Relationships section (§6):

```
Dim_Customer (dimension)
    ├── CountryID → Dim_Country.CountryID
    ├── CountryIDByIP → Dim_Country.CountryID
    └── CitizenshipCountryID → Dim_Country.CountryID

Fact_BillingDeposit (fact)
    ├── CID → Dim_Customer.RealCID (co-located: both HASH on CID/RealCID)
    └── CountryIDAsInteger → Dim_Country.CountryID (broadcast JOIN — replicated)
```

This confirms the canonical schema's "References To" and "Referenced By" sections can capture star-schema relationships with JOIN performance notes in Query Advisory.

### C.5 Findings & Compatibility

| # | Finding | Impact | Resolution |
|---|---------|--------|------------|
| 1 | All 3 objects fit the canonical template with zero structural gaps | None | Schema is compatible across dimension, fact, and lookup archetypes |
| 2 | Synapse-specific fields (Distribution, Index Type) are essential — all 3 objects have distinct strategies that affect query patterns | None | Schema already requires these for Synapse layer |
| 3 | `Fact_BillingDeposit` has 60+ denormalized `nvarchar(max)` columns from payment API shredding | Low | Handled via Element descriptions + PII tagging convention. No schema change needed |
| 4 | `Dim_Customer` has 40+ ID columns needing resolution — the most of any object tested | Low | Existing Element quality rules require all `*ID` columns to be resolved. Scale confirmed manageable |
| 5 | `Dim_Country` with REPLICATE/HEAP validates that the schema handles small lookup tables without redundant sections | None | Query Advisory §3.1 notes "replicate — no distribution key" naturally |
| 6 | The 3 objects form star-schema JOINs — validates Relationships section captures cross-object links | None | Both directions (References To / Referenced By) confirmed |

### C.6 Conclusion

All 3 Synapse DWH objects fit the canonical schema without modification. The schema handles:
- **Large dimensions** (107 cols, HASH distributed) — Dim_Customer
- **Large fact tables** (136 cols, HASH distributed, denormalized API responses) — Fact_BillingDeposit
- **Small replicated lookups** (19 cols, REPLICATE) — Dim_Country
- **Star-schema relationships** between them (FK references, co-located JOINs, broadcast JOINs)
- **Synapse-specific metadata** (distribution strategy, index type, query advisory) all exercised

No schema amendments required. The canonical schema (v1.0.0) is validated across all three Synapse DWH archetypes.

---

*Canonical schema for the Data Knowledge Platform. Governs all wiki files under `knowledge/`. Source template: `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc`.*
