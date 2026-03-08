# DWH Semantic Documentation Pipeline

## Overview

An AI-driven pipeline that produces analyst-ready documentation for Synapse DWH objects. The pipeline reads code, queries data, searches Atlassian, and generates wiki documentation — then a human domain expert reviews and corrects the output interactively.

**Demonstrated on**: `DWH_dbo.Fact_CustomerAction` — an 11-billion-row fact table with 71 columns, 6 production sources, and 8 ETL stored procedures.

---

## Pipeline Block Schema

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AUTOMATED PHASES                             │
│                     (AI agent, no human input)                      │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Phase 1  │→ │ Phase 2  │→ │ Phase 3  │→ │ Phase 4  │           │
│  │Structure │  │  Data    │  │ Distrib. │  │ Lookup   │           │
│  │Analysis  │  │ Sampling │  │ Analysis │  │Resolution│           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
│       ↓                                         ↓                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Phase 5  │→ │ Phase 6  │→ │ Phase 7  │→ │ Phase 8  │           │
│  │  JOIN    │  │ Business │  │  View    │  │Procedure │           │
│  │ Analysis │  │  Logic   │  │  Deps    │  │  Scan    │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
│       ↓                                         ↓                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Phase 9  │→ │Phase 9B  │→ │Phase 10  │→ │Phase 11  │           │
│  │ SP Logic │  │ETL Orch. │  │Atlassian │  │ Generate │           │
│  │Extraction│  │ Analysis │  │  Scan    │  │   Docs   │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
│                                                  ↓                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │Phase 12  │→ │Phase 13  │→ │Phase 14  │  │  Review  │           │
│  │Cross-Obj │  │ Lineage  │  │  Query   │  │ Sidecar  │           │
│  │Enrichment│  │ Mapping  │  │ Advisory │  │(auto-gen)│           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
                          TWO FILES PRODUCED
                     ┌──────────────────────────┐
                     │  Wiki Doc (.md)           │
                     │  Review Sidecar (.md)     │
                     └──────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      INTERACTIVE PHASE                               │
│                   (Human expert + AI assistant)                      │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  Conversational Review                                    │       │
│  │  • AI presents one item at a time                        │       │
│  │  • Expert says: correct / approve / skip / dismiss        │       │
│  │  • AI immediately updates wiki + sidecar + glossary       │       │
│  │  • Corrections persist across future pipeline reruns      │       │
│  └──────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Sources Used

| Source | What It Provides | Access Method |
|--------|-----------------|---------------|
| **Dataplatform Repo** (SSDT project) | SP definitions, view definitions, table DDL, function code | Local file read (Glob/Grep/Read) |
| **DB_Schema Repo** (production SSDT) | Upstream production DDL, Dictionary tables, upstream Wiki docs | Local file read |
| **Synapse SQL Pool** | Live data samples, value distributions, row counts | MCP / pyodbc query |
| **Atlassian** (Confluence + Jira) | Business context, design decisions, incident history | Atlassian API (Rovo Search, CQL, JQL) |
| **Domain Glossary** | Expert-confirmed term definitions, value maps | Local file read |
| **Existing Wiki Docs** | Cross-object enrichment (e.g., Dim_Position descriptions) | Local file read |

---

## Phase Breakdown with Examples

### Phase 1: Structure Analysis
**What it does**: Extracts the complete column schema — names, types, nullability, distribution strategy, indexes, and row count from Synapse metadata.

**Automated**: Yes — queries `INFORMATION_SCHEMA.COLUMNS`, `sys.pdw_column_distribution_properties`, index metadata.

**FCA Output**:
> 71 columns discovered. HASH distributed on `RealCID`. CLUSTERED COLUMNSTORE index + 4 nonclustered indexes. ~11 billion rows.

---

### Phase 2: Live Data Sampling
**What it does**: Pulls a small sample of actual rows (TOP 10) to see what the data looks like in practice — real values, NULLs, patterns.

**Automated**: Yes — `SELECT TOP 10 * FROM DWH_dbo.Fact_CustomerAction`.

**FCA Output**:
> Sampled 10 rows. Discovered: most columns are NULL/0 for non-position events. ActionTypeID drives which columns are populated. DemoCID always 0. IsReal always 1.

---

### Phase 3: Distribution Analysis
**What it does**: Runs `GROUP BY` aggregations on key columns to discover enums, flags, value distributions, and identify columns that behave like lookups.

**Automated**: Yes — `SELECT ActionTypeID, COUNT_BIG(*) FROM ... GROUP BY ...` for each candidate column.

**FCA Output**:
> ActionTypeID: 45 distinct values. StatusID: 99.99% = 1, ~2M NULL. IsFeeDividend: values 1-4 for ActionTypeID=35 only. Description: "Over night fee", "Weekend fee", "Payment caused by dividend" patterns.

---

### Phase 4: Lookup Resolution
**What it does**: Resolves every `*ID` column to its human-readable lookup table. Searches the Dataplatform repo for `Dim_*` tables, the upstream wiki for Dictionary tables, and the domain glossary for expert-confirmed value maps.

**Automated**: Yes — Glob for `DWH_dbo.Dim_*.sql`, Read DDL, match by column name.

**FCA Output**:
> Resolved 10 dimension lookups:
> - ActionTypeID → Dim_ActionType (Name, Category)
> - PlatformID → Dim_Product (badly named FK — actually ProductID)
> - FundingTypeID → Dim_FundingType
> - BonusTypeID → Dim_BonusType
> - CampaignID → Dim_Campaign
> - PaymentStatusID → Dim_PaymentStatus
> - CountryIDByIP → Dim_Country
> - InstrumentID → Dim_Instrument
> - RegulationIDOnOpen → Dim_Regulation
> - SettlementTypeID → value map from glossary (0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE)

---

### Phase 5: JOIN Analysis
**What it does**: Searches all SP, view, and function code for JOIN conditions that reference the target table. Extracts implicit relationships, CASE/IIF value mappings, and code comments that reveal column meanings.

**Automated**: Yes — Grep across the Dataplatform repo for the table name, then Read each referencing file.

**FCA Output**:
> 33 columns shared with Dim_Position confirmed from ETL SP JOIN analysis. Position-derived columns (InstrumentID, Leverage, Commission, IsBuy, etc.) are populated independently at ETL time from the same upstream sources.

---

### Phase 6: Business Logic Discovery
**What it does**: Analyzes column groups, hierarchies, flag combinations, and derivation patterns to extract business rules.

**Automated**: Yes — pattern analysis of column relationships.

**FCA Output**:
> 6 business rules discovered:
> 1. ActionTypeID event classification (45 types from 5 sources)
> 2. IsFeeDividend sub-classification (1=overnight, 2=dividend, 3=SDRT, 4=tickets)
> 3. Position-derived column pattern (33 columns shared with Dim_Position)
> 4. PlatformID product resolution via Dim_Product
> 5. Reopen commission adjustment logic
> 6. Login platform detection from STS

---

### Phase 7: View Dependency Scan
**What it does**: Finds all views that reference the table, reads their definitions, classifies them, and traces which procedures consume each view.

**Automated**: Yes — Grep across `**/Views/*.sql`, then trace consumers.

**FCA Output**:
> 5 views found referencing Fact_CustomerAction:
> - V_FCA_NumOfLogins_mean_1q (AGGREGATE — average login count)
> - V_C2P_Positions (JOIN — CRM-to-position mapping)
> Plus 12 functions (revenue calculations, population definitions)

---

### Phase 8: Procedure Reference Scan
**What it does**: Finds ALL stored procedures that read from, write to, or modify the table. Categorizes as WRITER/MODIFIER/READER and ranks by importance.

**Automated**: Yes — Grep across `**/Stored Procedures/*.sql` and `**/Functions/*.sql`.

**FCA Output**:
> 8 SPs found:
> - WRITERS: SP_Fact_CustomerAction_DL_To_Synapse (staging extract), SP_Fact_CustomerAction (transform+load), SP_Fact_CustomerAction_SWITCH (partition swap)
> - POST-LOAD: SP_Fact_CustomerAction_IsParitalCloseParent (flag update)
> - HELPERS: CheckExistPartition, Create_SWITCH_SINGLE
> - DOWNSTREAM: SP_Fact_FirstCustomerAction

---

### Phase 9: Procedure Logic Extraction
**What it does**: Deep-reads the top ETL stored procedures to extract column assignments, source-to-target mappings, transformation logic, and CASE/IIF patterns.

**Automated**: Yes — Read SP file from Dataplatform repo, parse SQL logic.

**FCA Output**:
> SP_Fact_CustomerAction analyzed (1,800+ lines):
> - ActionTypeID derived from CreditTypeID via 30-branch CASE statement
> - IsSettled fallback logic: `IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) → 1`
> - CommissionOnClose reopen adjustment: `new - original`
> - 6 independent INSERT blocks for 6 source types (credits, opens, closes, logins, cashier logins, registrations)

---

### Phase 9B: ETL Orchestration Analysis
**What it does**: Maps the ETL execution chain, refresh frequency, partition strategy, and upstream dependencies.

**Automated**: Yes — traces EXEC calls in SP code, reads staging table patterns.

**FCA Output**:
> Daily load at midnight via 3-stage pipeline:
> 1. SP_Fact_CustomerAction_DL_To_Synapse → extracts from lake staging into Ext_FCA_* tables
> 2. SP_Fact_CustomerAction → transforms and loads into Ext_FCA_Fact_CustomerAction
> 3. SP_Fact_CustomerAction_SWITCH → SWITCH partition into production table
> Post-load: SP_Fact_CustomerAction_IsParitalCloseParent marks partial-close flags

---

### Phase 10: Atlassian Knowledge Scan
**What it does**: Searches Confluence and Jira for business context, design decisions, historical incidents, and feature requests related to the table and its columns.

**Automated**: Yes — Rovo Search, CQL queries, JQL queries via Atlassian API.

**FCA Output**:
> 5 Confluence pages found:
> - BI Dictionary: "Foundation layer — raw data storage capturing all data"
> - STS Audit_Loggin: Login data flow documentation
> - DLT Test Plan: DLTOpen/DLTClose column addition
> - Synapse Performance: FCA query optimization
> - DWH Daily Process Failure: Postmortem for FCA ETL failure
>
> 7 Jira tickets found:
> - DSM-1463 (Done): IsFeeDividend logic (1=fee, 2=dividend, 3=SDRT, 4=tickets)
> - DSM-1771 (To Do): Add InstrumentID for ActionType 35
> - DSM-1769 (To Do): Add PositionID+RedeemID for ActionTypes 30, 8

---

### Phase 11: Generate Documentation
**What it does**: Produces two files — the wiki document and the review sidecar. The wiki follows a strict "query-brain" template with 8 sections. The sidecar lists every unverified item, clarification question, and structural concern.

**Automated**: Yes — template-driven generation from all prior phase results.

**FCA Output**:
> **Wiki file** (398 lines): 8 sections covering business meaning, business logic (6 rules), query advisory (7 patterns + 10 gotchas), 71 elements with descriptions, 15 relationships, ETL pipeline diagram, column lineage table, 12 Atlassian sources.
>
> **Review sidecar** (82 lines): 1 Tier 4 column, 8 clarification questions, 5 structural questions, 7 DimPos cross-applied corrections.

---

### Phase 12: Cross-Object Enrichment
**What it does**: Reads existing wiki documentation for related objects and inherits knowledge for shared columns.

**Automated**: Yes — reads `Dim_Position.md` and applies descriptions to shared columns.

**FCA Output**:
> 33 columns cross-referenced with Dim_Position wiki. Descriptions inherited for: Commission ("eToro markup/spread"), FullCommission ("market spread + eToro markup"), IsAirDrop ("position created by eToro on behalf of customer"), DLTOpen/DLTClose ("German crypto broker"), SettlementTypeID (0-5 value map), RedeemStatus (crypto wallet redemption).

---

### Phases 13-14: Lineage Mapping & Query Advisory
**What they do**: Phase 13 traces each column back to its production source via the Generic Pipeline. Phase 14 captures distribution keys, recommended query patterns, and performance notes.

**Automated**: Yes — synthesized from all prior phases.

**FCA Output**:
> **Lineage**: 6 production sources → Generic Pipeline → DWH staging → 3-stage ETL → Fact_CustomerAction
>
> **Query Advisory**: HASH(RealCID) — always include RealCID. 7 common query patterns documented. 10 gotchas including: "HistoryID is NOT unique", "Leverage=0 means non-position event", "PlatformID is a FK to Dim_Product, not a standalone enum".

---

## Interactive Review Phase

**What it does**: After the automated pipeline produces the wiki and sidecar, a human domain expert reviews flagged items through a conversational interface. The AI presents one item at a time, the expert provides corrections, and the AI immediately propagates changes to the wiki, sidecar, and glossary.

**Interactive**: Yes — human expert drives, AI writes.

### Review Session Example (FCA)

```
AI:   Column: IsPlug
      Tier: 4 (UNVERIFIED)
      Current: "Plug/adjustment flag. Always NULL."
      Question: What is a "plug"? Is this column deprecated?

User: dismiss

AI:   IsPlug dismissed. Updated wiki + sidecar.
      Next: HistoryID...

AI:   Column: HistoryID
      Current: "Composite unique identifier encoding ActionTypeID + GCID"
      Question: Is this the actual encoding scheme?

User: this is supposed to be some key but its rubbish and has
      duplications so make explanation to never use it for anything

AI:   HistoryID corrected. Updated wiki (element + gotcha added +
      encoding section removed) + sidecar.
      Next: PlatformID...

AI:   Column: PlatformID
      Current: "Derived login platform (101-126 for specific apps)"
      Question: Is the 101-126 mapping current?

User: important! bad naming conventions. allows to know which
      platform action is from using this join:
      SELECT dp.Product, dp.Platform, dp.SubPlatform, fca.*
      FROM Fact_CustomerAction fca
      JOIN Dim_Product dp ON fca.PlatformID = dp.ProductID

AI:   PlatformID corrected. Updated wiki (element, business logic,
      common JOINs, relationships, gotcha) + sidecar.
```

### Review Results (FCA)

| Category | Items | Resolved | Skipped |
|----------|-------|----------|---------|
| Tier 4 (unverified columns) | 1 | 1 | 0 |
| Clarification questions | 8 | 7 | 1 |
| Structural questions | 5 | 5 | 0 |
| DimPos cross-applied | 7 | 7 | 0 |
| **Total** | **21** | **20** | **1** |

---

## Key Design Principles

1. **Code is King** — when sources conflict, the hierarchy is: domain glossary > upstream wiki > Synapse code > live data > metadata > Confluence/Jira.

2. **Confidence Tiers** — every element description is tagged with its source: Tier 1 (upstream wiki), Tier 2 (Synapse SP code), Tier 3 (live data), Tier 4 (name inference — flagged UNVERIFIED), Tier 5 (domain expert — highest authority).

3. **Repo over DB** — SP and view definitions are read from the Dataplatform Git repo (more current, no connection overhead, full git history) with Synapse queries as fallback only.

4. **Corrections survive reruns** — expert corrections are stored in the sidecar and glossary as Tier 5 overrides. When the pipeline reruns on the same object, it reads the sidecar first and preserves all corrections.

5. **Cross-object learning** — when documenting Fact_CustomerAction, the pipeline reads the existing Dim_Position wiki and inherits descriptions for 33 shared columns. Corrections flow both ways via the glossary.

6. **Two mandatory outputs** — every run produces both the wiki document AND the review sidecar. The sidecar is not optional.

---

## Output Artifacts

| Artifact | Purpose | Example |
|----------|---------|---------|
| `{Table}.md` | Analyst-facing wiki documentation | `Fact_CustomerAction.md` (398 lines, 8 sections) |
| `{Table}.review-needed.md` | Review tracker + correction log | `Fact_CustomerAction.review-needed.md` (82 lines, 21 items) |
| `knowledge/glossary.md` | Cross-object domain terminology | 10 terms, 6 value maps (shared across all documented objects) |
| Phase rule files (`.mdc`) | Pipeline configuration | 14 phase rules in `.cursor/rules/dwh-semantic-doc/` |

---

---

## What's Next: Downstream Steps

The 14-phase pipeline + interactive review produces wiki documentation for individual objects. The broader Data Knowledge Platform has 6 additional stages that consume this output and push it into production systems.

### Stage A: Scale Pipeline (Next Immediate Step)

**What**: Run the same 14-phase pipeline on more DWH objects — dimensions, facts, and BI views.

**Target objects**:
- 5 additional dimensions: Dim_Customer, Dim_Instrument, Dim_Country, Dim_Campaign, Dim_Manager
- 3 fact tables: Fact_Trades, Fact_Deposits, Fact_Withdrawals (in addition to FCA)
- 3 BI_DB views/tables: BI_DB_CIDFirstDates, BI_DB_LTV_BI_Actual, etc.

**Result**: ~15+ Synapse objects documented with cross-object enrichment applied across all of them (Phase 12 becomes more powerful with each new object — knowledge compounds).

```
Today:  Dim_Position ←→ Fact_CustomerAction (33 shared columns)
Next:   15+ objects cross-referencing each other's wikis
        → glossary grows, corrections propagate, gaps shrink
```

---

### Stage B: Map Additional Business Units

**What**: The upstream production wiki (in DB_Schema) currently covers the Trading platform. Extend to additional business unit schemas: eMoney, Billing, BackOffice, etc.

**Why**: The Synapse DWH pipeline inherits from upstream wikis as Tier 1 authority. More upstream wikis = fewer Tier 4 (unverified) columns = less human review needed.

**Process**: Run the production sql-semantic-doc pipeline (separate pipeline, same methodology) on each BU's SSDT project in DB_Schema.

```
Current upstream:  Trading (Trade.*, Customer.*, Dictionary.*)
Next:              eMoney (Billing.*, eMoney.*)
                   BackOffice (BackOffice.*)
                   History (History.*)
```

---

### Stage C: Audit Lake Coverage

**What**: Map which production objects flow through the Generic Pipeline to the Azure Data Lake and which are registered in Databricks Unity Catalog.

**How**:
1. Query the Generic Pipeline mapping view in Synapse → list all exported objects
2. Query Unity Catalog via Databricks MCP → list all registered tables/views
3. Cross-reference → produce a coverage matrix

**Output**: `knowledge/coverage/coverage-matrix.md` — triple-purpose document:
- **Gap analysis**: what's in production but not in the lake/UC
- **Target map**: which UC tables will receive metadata descriptions
- **Scope map**: what the Databricks documentation layer will cover

```
┌──────────────┐     ┌──────────┐     ┌────────────┐     ┌──────────┐
│  Production  │ →?→ │  Lake    │ →?→ │  Synapse   │ →?→ │  Unity   │
│  (DB_Schema) │     │  (ADLS)  │     │  (DWH)     │     │  Catalog │
└──────────────┘     └──────────┘     └────────────┘     └──────────┘
     known              audit            documented         audit
```

---

### Stage D: Resolve Column Metadata Across Layers

**What**: Match columns across all four layers (production → lake → Synapse → Unity Catalog) and generate consistent descriptions.

**Process**:
1. For each documented Synapse object, use lineage to find production, lake, and UC equivalents
2. Match columns by exact name → fuzzy match → type comparison
3. Generate base descriptions following authority hierarchy
4. Enforce 1024-character limit for Unity Catalog descriptions
5. Produce clash file: compare generated vs existing UC descriptions

**Output**:
- `knowledge/columns/mappings/column-mappings.md` — cross-layer column identity map
- `knowledge/columns/descriptions/descriptions-only.md` — base descriptions for all columns
- `knowledge/columns/descriptions/clashes.md` — conflicts between generated and existing UC descriptions

```
Example: Dim_Position.IsSettled
  Production:  Trade.PositionTbl.IsSettled → "Legacy real-ownership indicator"
  Synapse:     DWH_dbo.Dim_Position.IsSettled → "1=owns asset, 0=CFD"
  UC:          trading.dim_position.is_settled → (currently empty)
  Generated:   "Real ownership flag: 1=customer owns actual shares, 0=CFD.
                Source: Trade.PositionTbl via Generic Pipeline."
```

---

### Stage E: Build Lineage Descriptions

**What**: For each column, assemble a lineage narrative showing the full transformation chain from production source to final destination.

**Process**:
1. Trace each column back through ETL SPs (from Phase 9 data)
2. Handle multi-source columns (COALESCE/CASE patterns)
3. Handle derived columns (GETDATE(), hardcoded values, calculations)
4. Generate "full-with-lineage" descriptions = base description + lineage context

**Output**: `knowledge/columns/lineage/full-with-lineage.md`

```
Example: Fact_CustomerAction.CommissionByUnits
  Base:     "Commission prorated by units"
  Lineage:  "Computed in SP_Fact_CustomerAction as
             (AmountInUnitsDecimal / InitialUnits) * Commission.
             Source columns from Trade.OpenPositionEndOfDay via
             Generic Pipeline → DWH_staging → ETL SP."
  Full:     "Commission prorated by units: (AmountInUnitsDecimal /
             InitialUnits) * Commission. Computed at ETL time from
             Trade.OpenPositionEndOfDay position data."
```

---

### Stage F: Package Agent Domains + Push to Unity Catalog

**What**: Organize all documented objects into domain packages with routing metadata, then push descriptions and tags into Databricks Unity Catalog.

**Domain packaging**:
- Assign every documented object to domains (many-to-many: Trading, Payments, Risk, etc.)
- Generate domain index files with routing keywords for AI agent consumption
- Create test questions per domain for validation

**Unity Catalog tags** (following Confluence standard):
- `owner` — team that owns the table
- `domain` — business domain(s)
- `layer` — raw / staging / curated / gold
- `refresh_frequency` — hourly / daily / weekly
- `source_system` — production source
- `sla` — service level (to be filled manually)
- `certified` — data quality certification (to be filled manually)

**PII inference** at column level:
- `direct` — column IS PII (name, email, IP, etc.)
- `indirect` — column JOINs to direct PII via GCID/CID
- `none` — no PII relationship

```
Final state:
  Unity Catalog tables have:
  ✓ Column descriptions (from wiki pipeline)
  ✓ Table descriptions (from wiki pipeline)
  ✓ Domain tags (from domain packaging)
  ✓ PII tags (from inference)
  ✓ Lineage metadata (from lineage descriptions)
  ✓ Owner/SLA tags (manual)
```

---

## End-to-End Vision

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     DATA KNOWLEDGE PLATFORM                             │
│                                                                         │
│  ┌──────────┐   ┌──────────────┐   ┌─────────────┐   ┌──────────────┐ │
│  │Production │   │  Synapse DWH │   │   Azure     │   │  Databricks  │ │
│  │  (SSDT)   │──→│  (Pipeline)  │──→│ Data Lake   │──→│Unity Catalog │ │
│  └──────────┘   └──────────────┘   └─────────────┘   └──────────────┘ │
│       ↓               ↓                   ↓                  ↓         │
│  ┌──────────┐   ┌──────────────┐   ┌─────────────┐   ┌──────────────┐ │
│  │ Upstream  │   │  DWH Wiki    │   │  Coverage   │   │  UC Tags +   │ │
│  │   Wiki    │──→│  (this       │──→│   Matrix    │──→│ Descriptions │ │
│  │(DB_Schema)│   │  pipeline)   │   │             │   │   (pushed)   │ │
│  └──────────┘   └──────────────┘   └─────────────┘   └──────────────┘ │
│                        ↓                                     ↓         │
│                  ┌─────────────┐                    ┌──────────────┐   │
│                  │  Domain     │                    │  AI Agents   │   │
│                  │  Glossary   │───────────────────→│  (consumers) │   │
│                  └─────────────┘                    └──────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

**Current status**: Stages A-F are planned. The 14-phase DWH pipeline (center column) is proven on 2 objects (Dim_Position + Fact_CustomerAction). Next: scale to 15+ objects, then flow downstream.

---

*Pipeline version: DWH Semantic Documentation v2 | Demonstrated: 2026-03-03 | Object: DWH_dbo.Fact_CustomerAction*
