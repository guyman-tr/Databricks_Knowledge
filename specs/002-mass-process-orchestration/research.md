# Research: Pipeline Decomposition — Wiki Build + Write Objects

**Branch**: `002-mass-process-orchestration` | **Date**: 2026-03-16

---

## R1: Why Is the Current Pipeline Too Slow?

### Evidence

| Metric | Current State | Impact |
|--------|--------------|--------|
| Phases per object | 14 + ALTER generation + downstream propagation + deployment | ~25 min/object |
| Batch size | 5 objects | Context saturation after 5 heavy objects |
| Total objects | 281 (259 tables, 22 views) | 281 / 5 = ~56 batches |
| Batches per session | 1 (then manual resume) | 56 manual chat restarts |
| Objects documented so far | 8 (Batch 1 + 3 pre-existing) | 2% coverage |
| Estimated total time (serial) | 56 batches × 125 min = ~117 hours | **~3-4 weeks** at 6h/day |

### Comparison: DB_Schema Throughput (Bonnie)

| Metric | DB_Schema (actual) | DWH (current) | Gap |
|--------|-------------------|---------------|-----|
| Batch size | 25 | 5 | 5x |
| Batches per day | 5+ (Batches 25-29 all on 2026-03-16) | ~2-3 | 2x |
| Per-object time | ~3-4 min (SPs, 6 phases) | ~25 min (tables, 14 phases + deploy) | 7x |
| Object types | SPs (simple, local file reads) | Tables (MCP queries, complex ETL) | Different profile |
| Parallel subagents | Prohibited (quality: serial 9-10 vs parallel 6-7) | Not attempted | See R3 |

### Root Cause Analysis

1. **Phase 11 is monolithic**: Wiki + ALTER + UC resolution + tags + PII + downstream propagation + execution — all in one pass. This is ~50% of per-object context and time.

2. **All objects processed serially**: Even independent leaf tables at depth 0 wait in a serial queue. No parallelism exploited.

3. **MCP queries per object**: Structure (Synapse), data (Synapse), distribution (Synapse), Atlassian, plus Databricks for UC. ~8-12 MCP round trips per object. With Constitution IX (Repo First), this drops to ~3-5 (Phases 2-3 live data only + Atlassian).

4. **Context accumulation**: After 5 objects × 14 phases, the agent's context is saturated.

### Decision

**Two-part fix**: (1) Split pipeline into wiki build + write-objects, and (2) **parallelize independent objects** using subagents within each depth level.

---

## R2: Which Phases Belong Where?

### Phase-to-Command Assignment

| Phase | Wiki Build | Write Objects | Rationale |
|-------|-----------|--------------|-----------|
| Pre-flight: Synapse MCP | ✅ Mandatory | ⬜ Optional (PII queries) | Wiki build queries Synapse for structure/data |
| Pre-flight: Atlassian MCP | ✅ Mandatory | ⬜ Not needed | Business context is for wiki, not ALTER scripts |
| Pre-flight: Databricks MCP | ⬜ Not needed | ✅ Mandatory | ALTER execution requires UC connection |
| Pre-flight: Upstream wiki | ✅ Advisory | ⬜ Not needed | Lineage tracing for wiki content |
| Phase 1: Structure Analysis | ✅ | ⬜ | Synapse metadata for wiki |
| Phase 2: Live Data Sampling | ✅ | ⬜ | Data patterns for wiki |
| Phase 3: Distribution Analysis | ✅ | ⬜ | Enum/flag discovery for wiki |
| Phase 4: Lookup Resolution | ✅ | ⬜ | Value maps for wiki |
| Phase 5: JOIN Analysis | ✅ | ⬜ | Relationships for wiki |
| Phase 6: Business Logic Discovery | ✅ | ⬜ | Concepts for wiki |
| Phase 7: View Dependency Scan | ✅ | ⬜ | Dependencies for wiki |
| Phase 8: Procedure Reference Scan | ✅ | ⬜ | SP references for wiki |
| Phase 9: Procedure Logic Extraction | ✅ | ⬜ | ETL logic for wiki |
| Phase 9B: ETL Orchestration Analysis | ✅ | ⬜ | Schedule/order for wiki |
| Phase 10: Atlassian Knowledge Scan | ✅ | ⬜ | Business annotations for wiki |
| Phase 11: Generate Documentation | ✅ SLIM | ⬜ | Wiki `.md` + sidecar + lineage only |
| Phase 12: Cross-Object Pre-Read | ✅ | ⬜ | Consistency across wiki docs |
| Phase 10A/10B: Production Lineage Mapping | ✅ PARTIAL | ✅ PARTIAL | See R2b below |
| Phase 14: Query Advisory | ✅ | ⬜ | Advisory content for wiki |
| UC Object Resolution | ⬜ | ✅ | Requires Databricks |
| UC Table Metadata Discovery | ⬜ | ✅ | Requires Databricks |
| ALTER script generation | ⬜ | ✅ | Reads from wiki `.md` |
| Table tags generation | ⬜ | ✅ | Reads from wiki + mapping view |
| Column PII tags | ⬜ | ✅ | Reads from GDPR sources + wiki |
| Downstream propagation | ⬜ | ✅ | Deep lineage BFS in UC |
| ALTER execution | ⬜ | ✅ | Executes against UC |
| Deploy report | ⬜ | ✅ | Summarizes deployment |

### R2b: Phase 10A/10B Split (formerly Phase 13)

**Wiki build**: SP code lineage (Steps 2-6) — produces `.lineage.md` from repo analysis.
**Write-objects**: Generic Pipeline mapping query (Steps 1, 1b) — UC query for refresh_frequency, SLA, source_system, PII. Feeds tag generation.

---

## R3: Parallel Subagent Architecture (THE KEY INSIGHT)

### Why Bonnie Prohibits Parallelism — And Why It Doesn't Apply Here

Bonnie's prohibition stems from **dependent objects**: when SP `GetEstimatedTreeUnitsByCID` calls `GetMinCopyPositonAmountMaintenanceFeatureValues`, the documenting agent needs the callee's context in memory to write a rich description. Parallel subagents each start with ZERO context → 6-7 quality instead of 9-10.

**This concern does NOT apply to objects at the same depth level.** By definition:
- Depth 0 objects have NO dependencies on any other depth-0 object
- Depth 1 objects depend on depth-0 (already documented as files), NOT on each other
- Within any depth level, objects are fully independent

For independent objects, there is no context to inherit from peers. A subagent documenting `Dim_ActionType` gains nothing from having `Dim_CardType` in context — they're unrelated dimension tables.

### Parallel Execution Model

```
For each depth level (0, 1, 2, ...):
  1. Collect all pending objects at this depth
  2. Group into clusters of 3 (tables) or 5 (views) — per Rule B1
  3. Dispatch up to 4 subagents in parallel, one cluster each
  4. Wait for all subagents to complete
  5. Parent agent validates output (Rule B7 spot-check)
  6. Update _index.md with results
  7. Accumulate context for _batch_context.json
  8. Next round of subagents until depth level exhausted
  9. Move to next depth level
```

### Subagent Configuration

| Setting | Value | Rationale |
|---------|-------|-----------|
| Max concurrent subagents | 4 | Tool limitation |
| Tables per subagent | 3 | Rule B1 |
| Views per subagent | 5 | Rule B1 |
| Objects per round | 12 (tables) or 20 (views) | 4 × 3 or 4 × 5 |
| Subagent prompt | Full phase pipeline instructions + glossary from `_batch_context.json` | Each subagent runs Phases 1-11 slim independently |

### What Subagents Receive

Each subagent gets:
1. The object names to document (3 tables or 5 views)
2. Phase 11 rule reference (`11-generate-documentation.mdc`)
3. MCP access (Synapse + Atlassian)
4. Glossary from `_batch_context.json` (accumulated from prior depth levels)
5. Existing wiki docs for dependency objects (already written to disk)

### What Subagents Do NOT Get

- Context from peer objects at the same depth level (not needed — independent)
- Direct agent context inheritance (each subagent starts fresh — but this is fine for independent objects)

### Quality Safeguards

| Safeguard | How |
|-----------|-----|
| Rule B1: batch size limits | 3 tables/subagent, 5 views/subagent |
| Rule B2: all 8 section headers | Subagent validates before reporting success |
| Rule B3: minimum line counts | Tables 100+, Views 80+ |
| Rule B4: individual element rows | Every column listed individually |
| Rule B6: post-write validation gate | 6-point check after each object |
| Rule B7: parent spot-check | Parent reads 1 random doc per subagent, verifies quality |

### When to Fall Back to Serial

- Objects with cross-depth dependencies within the same batch (e.g., depth 0 + depth 1 in one batch) → serial within the batch
- Objects where Phase 12 pre-read reveals heavy cross-references → serial
- If any subagent fails quality checks → re-run that cluster serially in parent agent

#### Post-Implementation Outcome

Parallel subagent dispatch was **abandoned** during implementation. The serial inline model was adopted instead.

**Why it was abandoned:**

1. **Quality degradation**: Each subagent starts with zero context about peer objects. Despite objects being at the same dependency depth (theoretically independent), shared domain context — glossary terms, naming patterns, common source tables — significantly improved quality when processed serially. The DB_Schema quality data (serial 9-10 vs parallel 6-7) predicted this correctly.

2. **GATE enforcement complexity**: Subagents could not reliably follow the lineage-first contract (Phase 10B before Phase 11) or load the mandatory spec files before generation. The GATE-lineage-contract and GATE-wiki-generation rule files only work with serial inline processing where the parent agent controls execution order.

3. **Cursor subagent limitations**: Subagents could not receive the full phase pipeline context (14 rule files + 3 GATE files + execution card) within their context window while also processing multiple objects. Context window budget: ~200K tokens. Phase rules alone consume ~50K.

**Measured outcome (serial inline):**
- DWH_dbo: 130 objects, 15 batches, avg quality 8.0 (range 4.5-9.4), 0 failed
- Dealing_dbo: 231 objects, 20 batches, avg quality 7.8
- BI_DB_dbo: 30 objects, 6 batches, avg quality 9.1

Serial inline processing with phase-skip optimization achieves sufficient throughput without quality trade-offs.

---

## R4: Revised Batch Size and Timing

### Per-Object Time Estimates (Wiki-Only Build)

| Object Profile | Phases | MCP Queries | Analysis Time | Wiki Gen | Total |
|---------------|--------|-------------|--------------|----------|-------|
| Dim/lookup table (≤15 cols) | 12 | ~5 (Synapse) | ~2 min | ~2 min | ~5 min |
| External/staging table | 8 | ~3 (minimal data) | ~1 min | ~1 min | ~3 min |
| Medium table (15-40 cols) | 12 | ~8 | ~5 min | ~3 min | ~10 min |
| Large fact table (40+ cols) | 12 | ~10 | ~8 min | ~5 min | ~15 min |
| View | 8 | ~3 | ~2 min | ~2 min | ~5 min |

### Parallel Throughput (4 subagents × 3 tables/subagent)

| Depth Level | Objects | Rounds | Time/Round | Total |
|-------------|---------|--------|-----------|-------|
| Depth 0 (leaves — dim/ext tables) | ~160 | ~14 | ~8 min | ~2h |
| Depth 1 (mid-level) | ~50 | ~5 | ~12 min | ~1h |
| Depth 2+ (fact tables) | ~50 | ~5 | ~15 min | ~1.5h |
| Views | 22 | ~2 | ~10 min | ~20 min |
| **Total wiki build** | **281** | **~26** | — | **~5h** |

### Comparison with Bonnie's Throughput

| Metric | Bonnie (DB_Schema) | DWH wiki build (parallel) | DWH wiki build (serial) |
|--------|-------------------|--------------------------|------------------------|
| Objects per day | ~125 | ~281 (full schema in 1 day) | ~50-60 |
| Per-object effective time | ~3-4 min | ~1 min effective (parallel) | ~5-10 min |
| Total for 281 objects | N/A | **~5-7 hours** | ~25-35 hours |

### Decision

**Default batch size: 25 (same as Bonnie)**. Within each batch, parallelize by depth level using subagents. A single batch of 25 objects at depth 0 can complete in ~20-30 minutes with 4 parallel subagents.

**Adopt Bonnie's Plan/Execute two-session model**: Plan session reads dependency graph and queues 25 objects in `_index.md`. Execute session documents them. Auto-detect mode from `_index.md` state. This eliminates planning overhead from execution context.

#### Actual Results

| Metric | DWH_dbo | Dealing_dbo | BI_DB_dbo |
|--------|---------|-------------|-----------|
| Total objects | 130 | 231 | 30 (of 1204 active) |
| Total batches | 15 | 20 | 6 |
| Avg batch size | ~9 | ~12 | ~5 |
| Quality range | 4.5-9.4 | TBD | TBD |
| Quality average | 8.0 | 7.8 | 9.1 |
| Failed objects | 0 | TBD | TBD |

**Key findings:**
- Batch size 10-15 is the sweet spot. Larger batches (15+) showed no measurable quality drop for well-structured tables, but complex tables (multiple SPs, cross-schema dependencies) benefit from smaller batches.
- The Simple Dictionary Fast-Path (Phases 1→2→8→4→10A→10B→11) significantly accelerates simple lookup tables, allowing larger effective batch sizes.
- BI_DB_dbo's higher quality (9.1) reflects its OpsDB-based discovery which provides better dependency ordering and ETL priority information than the dependency-graph fallback used for DWH_dbo.

---

## R5: How Write-Objects Reads From Wiki Files

### Decision

The write-objects command reads existing wiki `.md` files and generates ALTER scripts. It does **not** re-run any data gathering phases.

### Reading Algorithm

For each wiki file, the write-objects command:

1. **Parse wiki header table**: Extract `Schema`, `Object Type`, `Production Source`, `Refresh`, `Synapse Distribution`, `Synapse Index`
2. **Parse Elements table** (Section 4): Extract `Column`, `Data Type`, `Nullable`, `Description`, `Confidence` → ALTER COLUMN COMMENT statements
3. **Parse Business Meaning** (Section 1): First paragraph → table comment (compressed to ≤1024 chars)
4. **Parse Lineage** (Section 5): Production source → `source_system` tag
5. **Read `.lineage.md`** (if exists): Extract lineage metadata for tags
6. **Query UC**: Resolve actual UC target, get format/partitioning, validate columns
7. **Query Generic Pipeline mapping**: Get `FrequencyMinute`, `ServerName`, PII data for tags
8. **Generate**: `.alter.sql`, `.downstream.alter.sql`, `.deploy-report.md`
9. **Execute**: Run ALTER scripts against UC

Write-objects can also parallelize aggressively — each wiki file is self-contained. 4 subagents × 5-8 objects each = 20-32 per round.

---

## R6: Index and Progress Tracking Architecture

### Decision

Two separate tracking files per schema, same directory:

| File | Command | Tracks |
|------|---------|--------|
| `_index.md` | `build-wiki-dwh` | Wiki documentation status |
| `_deploy-index.md` | `generate-alter-dwh` / `deploy-alter-dwh` | Deployment status |

### Integration

`_deploy-index.md` reads `_index.md` to discover which objects have wiki docs (status = Done) and are eligible for deployment.

### Context Handoff

- `_batch_context.json` used by wiki build only (cross-depth glossary, relationships)
- `generate-alter-dwh` / `deploy-alter-dwh` read wiki files directly — no context handoff needed

---

## R7: Command Naming

### Decision

| Command | Name |
|---------|------|
| Wiki Build | `build-wiki-dwh` |
| ALTER Generation | `generate-alter-dwh` |
| ALTER Deployment | `deploy-alter-dwh` |

### Deprecation

| Existing Command | Fate |
|-----------------|------|
| `build-semantic-layer-dwh` | Deprecated → replaced by `build-wiki-dwh` |
| `build-semantic-layer-dwh-no-propagation` | Removed — redundant |

---

## R8: Plan/Execute Two-Session Model (from DB_Schema)

### Decision

Adopt Bonnie's two-session architecture for wiki build:

**Plan session** (context used for dependency analysis):
1. Read `_dependency_order.json` + Synapse metadata
2. Identify pending objects, build dependency graph
3. Select next 25 objects (respecting depth ordering)
4. Write `## Next Batch` section to `_index.md`
5. **STOP** — print plan summary, instruct operator to start new chat

**Execute session** (100% context for documentation):
1. Read `## Next Batch` from `_index.md`
2. Group objects by depth level
3. For each depth level: dispatch parallel subagents (3 tables each, up to 4 concurrent)
4. Validate subagent output (Rule B7)
5. Update `_index.md` status
6. Write `_batch_context.json`
7. Print end-of-batch banner

**Auto-detect**: If `_index.md` has a `## Next Batch` section → Execute mode. Otherwise → Plan mode.

This means the operator just runs the same command every time:
```
/build-wiki-dwh DWH_dbo   → plans 25 objects, STOPS
/build-wiki-dwh DWH_dbo   → executes (parallel), STOPS
/build-wiki-dwh DWH_dbo   → plans next 25, STOPS
/build-wiki-dwh DWH_dbo   → executes (parallel), STOPS
... repeat until schema complete
```

#### Post-Implementation Outcome

The Plan/Execute two-session model was **replaced with a single continuous flow** during implementation.

**Why it was replaced:**

The Plan/Execute model required operators to run the command twice per batch — once to plan (write `## Next Batch` to `_index.md` with Queued objects), then start a new chat to execute. In practice:

1. **No quality benefit**: Planning and execution share the same context (phase rules, GATE files, batch context). Splitting them adds a manual step with no improvement.
2. **Resume already handles interruption**: If a batch is interrupted mid-execution, the system auto-detects `Queued` objects in `_index.md` and resumes from the first Queued object. This makes explicit planning-then-execution redundant.
3. **Operator friction**: The DWH documentation campaign involves 15-20 batches per schema. Adding a manual restart between plan and execute doubles the operator interactions per schema from ~15 to ~30.

**Single continuous flow** (current model): Load state → Plan batch → Execute serial → Finalize → Banner → Stop. Operator starts a new chat for the next batch. One interaction per batch instead of two.

---

## R9: Revised Timeline Projection (Post-Pivot with Parallelism)

### Wiki Build Phase

| Step | Objects | Parallel Rounds | Time | Sessions |
|------|---------|----------------|------|----------|
| Depth 0 (leaf tables) | ~160 | ~14 rounds × 4 subagents × 3 | ~2h | ~7 plan/execute pairs |
| Depth 1 (mid tables) | ~50 | ~5 rounds | ~1h | ~2 pairs |
| Depth 2+ (fact tables) | ~50 | ~5 rounds | ~1.5h | ~2 pairs |
| Views | 22 | ~2 rounds | ~20 min | 1 pair |
| **Total wiki build** | **281** | **~26 rounds** | **~5-7h** | **~12 pairs** |

At 6-8 productive hours/day: **1-2 days** for full wiki coverage.

### Deployment Phase (Write-Objects)

| Step | Objects | Method | Time |
|------|---------|--------|------|
| All documented objects | 281 | Parallel subagents (4 × 5-8 each) | ~3-5h |
| Downstream propagation | 281 | Bottom-up, parallel where safe | ~2-3h |
| **Total deployment** | **281** | — | **~5-8h** |

At 6-8 productive hours/day: **~1 day** for full deployment.

### Total: ~2-3 days (down from 3-4 weeks)

| Approach | Time | Speedup |
|----------|------|---------|
| Current (serial, full pipeline, batch 5) | ~3-4 weeks | baseline |
| Plan v1 (serial, wiki-only, batch 15) | ~8-9 days | 3x |
| **Plan v2 (parallel subagents, wiki-only, batch 25)** | **~2-3 days** | **10x** |

#### Actual Results

| Schema | Objects | Batches | Calendar time | Status |
|--------|---------|---------|---------------|--------|
| DWH_dbo | 130 | 15 | ~3 weeks | ✅ Complete |
| Dealing_dbo | 231 | 20 | ~4 weeks | ✅ Complete |
| BI_DB_dbo | 30/1204 | 6 | Ongoing | 🟡 In progress |

**Timeline analysis:**
- Wiki build throughput: ~1-2 batches per operator day (depends on object complexity and operator availability)
- ALTER generation + deployment: Separate workflow, can run independently after wiki batches complete
- Total pipeline: Wiki build is the bottleneck; ALTER generation/deployment is fast (~5 min per batch of 25)
- Projected BI_DB_dbo completion at current pace: ~60 additional batches needed (~30 operator-days)

---

## R10: Repo-First Data Access (Constitution IX)

### Decision

**Codified as Constitution IX (NON-NEGOTIABLE) and shared Cursor rule `repo-first-access.mdc`.**

This is NOT an optimization or insight — it is a binding principle. The Dataplatform SSDT repo contains the complete DDL for every DWH_dbo object:

| Object Type | Count | Repo Path |
|-------------|-------|-----------|
| Tables | 343 | `Dataplatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Tables\` |
| Stored Procedures | 126 | `...\Stored Procedures\` |
| Views | 22 | `...\Views\` |

Each `.sql` file contains the full `CREATE TABLE/VIEW/PROCEDURE` statement with columns, types, distribution strategy, index type, and code body.

### What This Changes

| Phase | Before (MCP) | After (Repo) | Queries Eliminated |
|-------|-------------|-------------|-------------------|
| 1 — Structure | 3-4 Synapse queries | 1 file read | 3-4 per object |
| 4 — Lookup Resolution | Synapse + DB_Schema queries | Repo file reads | 2-3 per object |
| 5 — JOIN Analysis | `sys.sql_modules` query | Repo file read | 1 per object |
| 7 — View Dependency | `sys.sql_modules` query | Repo file read | 1 per object |
| 8 — Procedure Scan | `sys.sql_modules` search | Repo Grep | 1 per object |
| 9 — Procedure Logic | `sys.sql_modules` query | Repo file read | 1 per object |
| 9B — ETL Orchestration | `sys.sql_modules` query | Repo file read | 1 per object |
| **Total eliminated** | — | — | **~10-12 MCP queries per object** |

For 25 objects in a batch: **~250-300 MCP round trips eliminated** → saves 15-25 minutes of network latency per batch.

### Only Synapse MCP Queries Remaining

- Phase 2: `SELECT TOP N FROM {table}` (sampling)
- Phase 3: `SELECT {col}, COUNT(*) FROM {table} GROUP BY {col}` (distribution)

~3-5 queries per object, totaling ~75-125 for a batch of 25.

### Enforcement

Codified in three places:
1. **Constitution IX** — principle-level authority
2. **`.cursor/rules/semantic-layer-core/repo-first-access.mdc`** — full enforcement table, repo paths, phase-by-phase source assignment
3. **`01-structure-analysis.mdc`** — Phase 1 rule corrected (previously MANDATED MCP, now MANDATES repo)

Any agent or rule that queries `INFORMATION_SCHEMA`, `sys.columns`, `sys.tables`, `sys.indexes`, `sys.sql_modules`, or `sp_helptext` for structural/code information is in violation.

---

## R11: Constitution Compliance

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Agent-First Knowledge | ✅ | ALTER script still ultimate deliverable — produced by write-objects from wiki |
| II. Code Is King | ✅ | Source hierarchy unchanged |
| III. Accuracy Over Coverage | ✅ | Parallel only for independent objects; serial for dependent chains |
| IV. Incremental Delivery | ✅ IMPROVED | Wiki and deployment independently deliverable |
| V. Canonical Metadata Schema | ✅ | Same output format for all files across both commands |
| VI. Lineage Is First-Class | ✅ | `.lineage.md` produced during wiki build; `.lineage.py` during write-objects |
| VII. Domain Boundaries | ✅ | Unchanged — domain tagging preserved in write-objects |
| VIII. Don't Rebuild What Exists | ✅ | Upstream wikis consumed as-is; staleness detection skips fresh docs |
| IX. Repo First, MCP Second | ✅ ENFORCED | NEW — all structural/code reads from Dataplatform repo. MCP only for Phases 2-3 live data |
| Quality Gates (v1.8.0) | ✅ | Four files per object across pipeline (wiki + sidecar + lineage from build, ALTER from deploy). Rules B1-B7 enforce quality in subagents |
| Phase 10 mandatory | ✅ | Each subagent runs Phase 10 |

**No violations.** Parallel subagents for independent objects is architecturally sound because the quality prohibition in DB_Schema was about dependent objects losing context inheritance — which doesn't apply to same-depth-level objects. Constitution IX (Repo First) is now a binding constraint with its own shared rule file and enforcement table.
