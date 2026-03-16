# DWH Semantic Documentation Pipeline
## From POC to Production — Brainstorming Brief

---

## 1. Pipeline Flow (Vertical Block Diagram)

```
 LEGEND:
   ┌─────┐  Automated step (no human, no new privilege)
   ╔═════╗  Pipeline boundary (start / end)
   ┌ ─ ─ ┐  Needs repo / system access (existing creds OK)
   ░░░░░░░  🔑 NEW PRIVILEGE REQUIRED — won't work without setup
   ┌─ ! ─┐  ⚠️  FRAGILE — known reliability concern
   (No blocking human gates — review is offline)


╔══════════════════════════════════════════════════════════════╗
║                        TRIGGER                               ║
║  Input: table name (e.g., "DWH_dbo.Dim_Position")           ║
║  Mode:  single table │ batch (schema scan) │ re-run          ║
╚════════════════════════════╤═════════════════════════════════╝
                             │
                             ▼
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░  PRE-FLIGHT CHECKS                            🔑 NEW PRIVS  ░
░                                                              ░
░  ☐ Synapse connectivity      🔑 Service Principal needed    ░
░  ☐ Databricks connectivity   🔑 Service Principal needed    ░
░  ☐ UC permissions             🔑 BROWSE/SELECT on UC        ░
░  ☐ Dataplatform repo          🔑 Deploy key / PAT           ░
░  ☐ Upstream wiki repo         🔑 Deploy key / PAT           ░
░  ☐ Atlassian API              🔑 Service account token      ░
░  ☐ Glossary loaded                                           ░
░  ☐ Config loaded                                             ░
░                                                              ░
░  → FAIL FAST if Synapse or Databricks unreachable            ░
░  → WARN + continue if upstream wiki or Atlassian unavailable ░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░┬░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
                               │
              ┌────────────────┴────────────────┐
              │     PHASE GROUP A: DISCOVERY     │
              │     (automated, no human input)  │
              └────────────────┬────────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 1: Structure Analysis   │
               │  ● Synapse metadata via MCP    │
               │  ● Columns, types, PKs, dist   │
               │  OUT: column inventory         │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 2: Live Data Sampling   │
               │  ● Sample rows, NULLs, ranges  │
               │  ● Synapse MCP (read-only)     │
               │  OUT: data profile             │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 3: Distribution Analysis│
               │  ● Value distributions, enums  │
               │  ● Flag/boolean detection      │
               │  OUT: enum maps, flag list     │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 4: Lookup Resolution    │
               │  ● FK reference + upstream wiki│
               │  ● Dim_* table value maps      │
               │  OUT: resolved ID→name maps    │
               └───────────────┬───────────────┘
                               │
              ┌────────────────┴────────────────┐
              │   PHASE GROUP B: RELATIONSHIPS   │
              │   (automated, repo access needed)│
              └────────────────┬────────────────┘
                               │
                               ▼
               ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
                 Phase 5: JOIN Analysis
               │ ● Implicit FK from SP JOINs   │
                 ● Dataplatform repo grep
               │ ● NEEDS: repo clone access    │
                 OUT: relationship graph
               └ ─ ─ ─ ─ ─ ─ ┬ ─ ─ ─ ─ ─ ─ ─ ┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 6: Business Logic       │
               │  ● Column groups, hierarchies  │
               │  ● Lifecycle pairs, clusters   │
               │  OUT: business concept map     │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
                 Phase 7: View Dependency Scan
               │ ● Downstream views from repo  │
                 ● NEEDS: repo clone access
               │ OUT: view tree                │
               └ ─ ─ ─ ─ ─ ─ ┬ ─ ─ ─ ─ ─ ─ ─ ┘
                               │
                               ▼
               ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
                 Phase 8: Procedure Ref Scan
               │ ● All SPs touching this table │
                 ● NEEDS: repo clone access
               │ OUT: categorized SP list      │
               └ ─ ─ ─ ─ ─ ─ ┬ ─ ─ ─ ─ ─ ─ ─ ┘
                               │
              ┌────────────────┴────────────────┐
              │    PHASE GROUP C: DEEP ANALYSIS   │
              │    (automated, heavy reads)       │
              └────────────────┬────────────────┘
                               │
                               ▼
               ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
                 Phase 9: Procedure Logic
               │ ● Read top-10 SP source code  │
                 ● NEEDS: repo clone access
               │ OUT: source→target map        │
               └ ─ ─ ─ ─ ─ ─ ┬ ─ ─ ─ ─ ─ ─ ─ ┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 9B: ETL Orchestration   │
               │  ● Refresh schedule, order     │
               │  ● Dependencies between SPs    │
               │  OUT: ETL dependency graph     │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌─ ! ──────────────────────── ! ┐
               │  Phase 10: Atlassian Scan  ⚠️ │
               │  ● Jira + Confluence search    │
               │  ● MANDATORY — never skip      │
               │  ⚠️  Rate limits possible      │
               │  ⚠️  Auth token may expire     │
               │  OUT: business annotations     │
               └───────────────┬───────────────┘
                               │
              ┌────────────────┴────────────────┐
              │    PHASE GROUP D: GENERATION      │
              │    (automated, end-to-end)         │
              └────────────────┬────────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 12: Cross-Object Enrich │
               │  ● Read existing wiki docs     │
               │  ● Absorb related knowledge    │
               │  OUT: enriched context         │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌─ ! ──────────────────────── ! ┐
               │  Phase 11: Generate Docs   ⚠️ │
               │  ● Query-brain wiki template   │
               │  ● Tier 1–5 confidence tagging │
               │  ● Glossary enforcement        │
               │  ⚠️  NEEDS LLM (Cursor or API) │
               │                                │
               │  OUT: 4 files per table:       │
               │    {Table}.md                  │
               │    {Table}.review-needed.md    │
               │    {Table}.alter.sql           │
               │    {Table}.downstream.alter.sql     │
               └───────────────┬───────────────┘
                               │
                               │  (no review gate — pipeline continues)
                               │
              ┌────────────────┴────────────────┐
              │    PHASE GROUP E: LINEAGE         │
              │    (automated, UC access needed)   │
              └────────────────┬────────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 13: Production Lineage  │
               │  ● Generic Pipeline mapping    │
               │  ● Column-level source tracing │
               │  OUT: {Table}.lineage.md       │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 14: Query Advisory      │
               │  ● Distribution key guidance   │
               │  ● Performance notes, freshness│
               │  OUT: advisory in wiki doc     │
               └───────────────┬───────────────┘
                               │
              ┌────────────────┴────────────────┐
              │    PHASE GROUP F: DEPLOYMENT      │
              └────────────────┬────────────────┘
                               │
                               ▼
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░  Deploy: Table ALTER                         🔑 NEW PRIV    ░
░  ● Execute .alter.sql                                        ░
░  ● Table comment + tags + column comments                    ░
░  🔑 REQUIRES: MODIFY on UC table                            ░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░┬░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
                               │
                               ▼
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░  Deploy: View Propagation                    🔑 NEW PRIV    ░
░  ● Execute .downstream.alter.sql                                  ░
░  ● COMMENT ON COLUMN for downstream views                    ░
░  🔑 REQUIRES: MODIFY on every downstream UC view            ░
░  ⚠️  May be denied on some views (skip + report)             ░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░┬░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
                               │
                               ▼
               ┌───────────────────────────────┐
               │  Phase 15: UC Lineage (OFFLINE)│
               │  ● .lineage.py GENERATED only  │
               │  ● NOT executed automatically   │
               │  ● Deploy separately when ready │
               │  🔑 CREATE EXTERNAL METADATA   │
               └───────────────┬───────────────┘
                               │
                               ▼
╔══════════════════════════════════════════════════════════════╗
║                     PIPELINE COMPLETE                        ║
║                                                              ║
║  Outputs per table (6 files):                                ║
║    {Table}.md               — wiki doc                       ║
║    {Table}.review-needed.md — review sidecar (offline)       ║
║    {Table}.alter.sql        — table/column ALTERs            ║
║    {Table}.downstream.alter.sql  — downstream column comments║
║    {Table}.lineage.md       — upstream column lineage        ║
║    {Table}.lineage.py       — lineage injection (not run)    ║
║                                                              ║
║  UC metadata DEPLOYED (automatic):                           ║
║    ✓ Table + column comments                                 ║
║    ✓ Table tags                                              ║
║    ✓ Downstream column comments (tables + views)             ║
║    ○ External lineage — PENDING (run .lineage.py offline)    ║
║                                                              ║
║  Review: OFFLINE — domain experts review at own pace         ║
║    → corrections trigger review-rerun (Phase 11 + re-deploy) ║
╚══════════════════════════════════════════════════════════════╝


                    OFFLINE REVIEW-RERUN FLOW
                    ═════════════════════════

               ┌───────────────────────────────┐
               │  Domain expert reviews         │
               │  .review-needed.md files       │
               │  (at any time, any pace)       │
               │                                │
               │  Methods:                      │
               │  ● wiki-review skill (chat)    │
               │  ● Edit .review-needed.md      │
               │  → Adds rows to Corrections    │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  User triggers review-rerun    │
               │  (table or batch scope)        │
               │                                │
               │  Skips Phases 1–10             │
               │  Re-runs Phase 11 with Tier 5  │
               │  Re-deploys ALTERs to UC       │
               │  ~2-3 min per table            │
               └───────────────────────────────┘


PRIVILEGE SUMMARY — what needs to be granted before go-live:
═══════════════════════════════════════════════════════════════
  🔑 Synapse:    Service Principal with SELECT on DWH tables
  🔑 Databricks: Service Principal with:
                   BROWSE/SELECT  on UC tables (all schemas)
                   MODIFY         on UC tables + views
                   CREATE EXTERNAL METADATA on metastore
  🔑 Atlassian:  Service account with API read access
  🔑 Git repos:  Deploy keys for Dataplatform + DB_Schema
  🔑 LLM:       Azure OpenAI API key (if headless mode)
═══════════════════════════════════════════════════════════════
```

---

## 2. What Works Today (POC State)

| Capability | Status | How |
|-----------|--------|-----|
| Synapse metadata queries | ✅ Working | MCP server (pyodbc + Azure AD interactive) |
| Databricks UC queries | ✅ Working | MCP server (SDK + OAuth CLI profile) |
| Upstream wiki lookup | ✅ Working | Local file read from cloned repo |
| Atlassian search | ✅ Working | MCP (Jira + Confluence) |
| SP source code read | ✅ Working | Local file read from Dataplatform repo |
| UC ALTER execution | ✅ Working | MCP execute_sql |
| Downstream comment propagation | ✅ Working | Generated SQL, manual execution |
| Lineage injection | 🧪 Testing | Python script, pending DE test |
| Human review cycle | ✅ Working | .review-needed.md + glossary corrections (offline) |
| End-to-end automation | ✅ Working | Phases 1–14 + ALTER deploy, no review gate |
| Review-rerun mode | ✅ Working | Phase 11 re-gen + ALTER re-deploy after corrections |
| Full pipeline orchestration | ❌ Manual | Human triggers phases via Cursor chat |

---

## 3. Productionization Gaps

### 3.1 Authentication & Service Principals

| System | POC Auth | Production Target | Gap |
|--------|----------|-------------------|-----|
| **Synapse** | Azure AD Interactive (browser popup) | Service Principal (client_id + secret) | New SP needed, firewall rule for IP |
| **Databricks** | OAuth U2M via CLI profile (`guyman`) | Service Principal or M2M OAuth | New SP in Databricks, scoped to workspace |
| **Atlassian** | Personal API token (Cursor plugin) | Service account API token | Dedicated service account with read-only access |
| **Git repos** | Local clones on Guy's machine | Git clone via deploy key or HTTPS token | CI runner needs repo access |

**Action items:**
- [ ] Create Azure AD Service Principal for Synapse read-only access
- [ ] Create Databricks Service Principal with UC privileges
- [ ] Create Atlassian service account (read-only)
- [ ] Set up deploy keys or PATs for Dataplatform + upstream wiki repos

### 3.2 Permissions Matrix

| Action | Required Privilege | Who Grants | POC Status |
|--------|-------------------|------------|------------|
| Read Synapse metadata | `SELECT` on sys views | Synapse admin | ✅ |
| Read Synapse data (sampling) | `SELECT` on DWH tables | Synapse admin | ✅ |
| Read SP source code | Git clone of Dataplatform | Repo admin | ✅ (local) |
| Read upstream wiki | Git clone of DB_Schema | Repo admin | ✅ (local) |
| `DESCRIBE TABLE` in UC | `SELECT` or `BROWSE` | UC admin | ✅ |
| `ALTER TABLE ... COMMENT` | `MODIFY` on UC tables | UC admin | ✅ |
| `ALTER TABLE ... SET TAGS` | `MODIFY` on UC tables | UC admin | ✅ |
| `COMMENT ON COLUMN` (views) | `MODIFY` on UC views | UC admin | ⚠️ Partial |
| `CREATE EXTERNAL METADATA` | Metastore privilege | Metastore admin | 🧪 Testing |
| External lineage write | `MODIFY` on ext metadata | Metastore admin | 🧪 Testing |
| Search Jira/Confluence | API read access | Atlassian admin | ✅ |

### 3.3 Repository Strategy

```
CURRENT (POC):
  c:\Users\guyman\Documents\github\Databricks_Knowledge\   ← standalone repo
  c:\Users\guyman\Documents\github\DB_Schema\              ← upstream wiki (read)
  c:\Users\guyman\Documents\github\Dataplatform\           ← SP source code (read)

TARGET (Production):
  Dataplatform/                              ← existing team repo
  ├── knowledge/
  │   ├── synapse/Wiki/DWH_dbo/Tables/       ← pipeline outputs go here
  │   ├── glossary.md
  │   └── ...
  ├── pipeline/
  │   ├── dwh-semantic-doc/                  ← pipeline rules + scripts
  │   │   ├── phases/                        ← phase rule files
  │   │   ├── config.json
  │   │   └── run.py                         ← orchestrator
  │   └── lineage/
  │       └── *.lineage.py                   ← generated lineage scripts
  └── .cursor/rules/                         ← Cursor rules (if IDE-driven)
```

**Migration tasks:**
- [ ] Move pipeline rules + config to Dataplatform repo
- [ ] Move generated outputs (wiki, alter, lineage) to Dataplatform repo
- [ ] Establish branch strategy: `feature/semantic-doc-{table}` → PR → `dev` → `main`
- [ ] CI check: lint ALTER scripts, validate UC target names
- [ ] Decide: pipeline runs as Cursor chat (human-in-loop) vs. headless Python orchestrator

### 3.4 Execution Model Options

```
OPTION A: Cursor-Driven (Current)
══════════════════════════════════
  Human triggers via Cursor chat
  AI agent executes phases 1–15
  Human reviews .review-needed.md
  AI re-runs with corrections
  Human approves → deploy

  ✅ Rich AI reasoning per phase
  ✅ Human-in-loop built in
  ❌ One table at a time
  ❌ Depends on Cursor session
  ❌ Not schedulable

OPTION B: Headless Python Orchestrator
══════════════════════════════════════
  Python script orchestrates phases
  Calls Synapse/Databricks directly (SDK)
  Calls LLM API for generation (Phase 11)
  Outputs files → PR → human review
  Separate deploy step

  ✅ Batch: run N tables overnight
  ✅ Schedulable (cron, Airflow, ADF)
  ✅ CI/CD integration
  ❌ Needs LLM API access (Azure OpenAI?)
  ❌ Significant development effort
  ❌ Loses Cursor's repo-aware reasoning

OPTION C: Hybrid
════════════════
  Phases 1–10, 13: headless Python (data gathering)
  Phases 11, 14: LLM API call (generation)
  Phase 12: automated cross-reference
  Phase 15: headless Python (lineage injection)
  Review + deploy: human via PR

  ✅ Best of both worlds
  ✅ Data gathering is fully automatable
  ✅ Only generation needs LLM
  ❌ Still needs LLM API
  ❌ Medium development effort
```

---

## 4. Human-in-the-Loop — Offline Review Model

The pipeline runs **end-to-end without stopping**. Human review is decoupled from the automation flow.

### What Changed

| Before (POC) | After (Production) |
|-------------|-------------------|
| Pipeline BLOCKS after Phase 11 for review | Pipeline runs Phases 1–14 + ALTER deploy continuously |
| Review is synchronous (pipeline waits) | Review is asynchronous (offline, any pace) |
| Corrections require full re-run | Corrections trigger lightweight review-rerun (Phase 11 only) |
| Phase 15 executed inline | Phase 15 generates `.lineage.py` but does NOT execute (offline deploy) |
| Deploy approval gate | ALTERs deploy automatically; idempotent and safe to re-run |

### Remaining Human Touchpoints

| Touchpoint | When | Frequency | Impact on Pipeline |
|-----------|------|-----------|-------------------|
| **Domain review** | Anytime after pipeline completes | Per-table, at reviewer's pace | None — pipeline is already done. Review-rerun picks up corrections |
| **Tier 4 corrections** | Offline via wiki-review skill or sidecar edit | ~30% of columns on first table, ~5% by 50th | Triggers review-rerun (Phase 11 + ALTER re-deploy, ~2-3 min/table) |
| **UC permission grants** | Before first pipeline run | One-time setup | Blocking only on first run |
| **Lineage injection** | Separate deployment step | Per-table, when ready | Run `.lineage.py` manually or via separate automation |
| **New schema onboarding** | When adding a new Synapse schema | Rare | Config update + FK reference update |
| **Glossary updates** | When a correction is domain-wide | Grows over time | Triggers batch review-rerun for all affected tables |

---

## 5. Error Handling & Recovery

### 5.1 Failure Modes & Recovery

| Failure | Impact | Recovery |
|---------|--------|----------|
| **Synapse connection drop** | Phases 1-3 stall | MCP server has keepalive + auto-reconnect. Retry phase from start |
| **Databricks token expired** | UC queries fail | SDK auto-refreshes. If fully expired: `databricks auth login --profile`. SP token never expires |
| **Atlassian API rate limit** | Phase 10 partial | Retry with backoff. Phase 10 results are additive — partial is OK |
| **SP source code not found** | Phase 9 incomplete | Skip missing SPs, document gap in review sidecar |
| **UC table doesn't exist** | ALTER script invalid | Phase 11 writes `-- UNVALIDATED UC TARGET` header. Human resolves |
| **MODIFY permission denied on downstream object** | .downstream.alter.sql partial | Skip denied objects with comment. Report in summary |
| **CREATE EXTERNAL METADATA denied** | Phase 15 blocked | Skip lineage injection. All other outputs still valid |
| **Mid-pipeline crash** | Partial outputs | Each phase writes results to files. Re-run resumes from last complete phase |

### 5.2 Resumability Design

```
Pipeline State File: {Table}.pipeline-state.json
{
  "table": "Dim_Position",
  "started": "2026-03-09T10:00:00Z",
  "phases": {
    "1":  {"status": "complete", "completed_at": "..."},
    "2":  {"status": "complete", "completed_at": "..."},
    "3":  {"status": "failed",  "error": "connection timeout", "retry_count": 1},
    "4":  {"status": "pending"},
    ...
  },
  "pre_flight": {
    "synapse": true,
    "databricks": true,
    "atlassian": true,
    "dataplatform_repo": "/path/to/repo"
  }
}

On restart:
  1. Read state file
  2. Skip completed phases
  3. Retry failed phases (with backoff)
  4. Continue from first pending phase
```

### 5.3 Idempotency Guarantees

| Operation | Idempotent? | How |
|-----------|-------------|-----|
| Phase 1–10 queries | ✅ Yes | Read-only, can re-run freely |
| Phase 11 file generation | ✅ Yes | Overwrites previous files |
| .alter.sql execution | ✅ Yes | ALTER COLUMN COMMENT is a SET, not append |
| .downstream.alter.sql execution | ✅ Yes | COMMENT ON COLUMN / ALTER COLUMN COMMENT are both SETs |
| .lineage.py execution | ✅ Yes | Checks existence before create, handles ALREADY_EXISTS |
| ALTER TABLE SET TAGS | ✅ Yes | SET replaces, doesn't append |

---

## 6. Scale & Scope

### 6.1 Object Inventory (estimated)

| Schema | Tables | Views | SPs | Priority |
|--------|--------|-------|-----|----------|
| DWH_dbo | ~100 | ~50 | ~300 | 🔴 High — core analytics |
| Dealing_dbo | ~40 | ~20 | ~100 | 🟡 Medium |
| BI_DB_dbo | ~30 | ~40 | ~80 | 🟡 Medium |
| EXW_dbo | ~20 | ~10 | ~50 | 🟢 Low |
| eMoney_dbo | ~15 | ~5 | ~30 | 🟢 Low |
| **Total** | **~205** | **~125** | **~560** | |

### 6.2 Time Estimates (per table)

| Phase Group | Duration | Bottleneck |
|------------|----------|------------|
| A: Discovery (1-4) | ~5 min | Synapse queries |
| B: Relationships (5-8) | ~3 min | Repo grep |
| C: Deep Analysis (9-10) | ~10 min | SP reads + Atlassian |
| D: Generation (11-14) | ~5 min | LLM generation |
| E: ALTER Deployment | ~2 min | UC API calls |
| **Total (end-to-end)** | **~25 min/table** | No human gate |
| Review-rerun (after corrections) | ~2-3 min/table | Phase 11 + ALTER only |
| Lineage injection (offline) | ~1 min/table | Separate step |

### 6.3 Batch Strategy

```
Phase 1: Document the "big 20" tables          (~20 tables, ~8 hours automated)
  Dim_Position ✅, Fact_CustomerAction ✅, Fact_BillingDeposit ✅
  Dim_Customer, Dim_Instrument, Dim_Mirror,
  Fact_Deposit, Fact_Withdrawal, Dim_Currency,
  Dim_Country, Dim_Regulation, ...

  → Review happens offline in parallel with Phase 2
  → Review-rerun picks up corrections as they come in

Phase 2: Document remaining DWH_dbo tables     (~80 tables, ~33 hours automated)

Phase 3: Document Dealing + BI_DB schemas      (~110 tables, ~46 hours automated)

Phase 4: Document remaining schemas            (~remaining, ~16 hours automated)

Phase 5: Maintenance mode                      (re-run on schema changes)

Timeline with continuous processing (no review gate):
  Phase 1: ~2 days (batch, no waiting)
  Phase 2: ~1 week
  Phase 3: ~1.5 weeks
  Phase 4: ~0.5 week
  Total: ~4 weeks for full coverage (vs. ~26 weeks with review gates)
```

---

## 7. Quirks & Edge Cases to Account For

| Quirk | Description | Mitigation |
|-------|-------------|------------|
| **UC naming inconsistency** | Some gold tables have `gold_sql_dp_prod_we_dwh_dbo_` prefix, others don't | Phase 11 resolves dynamically via UC query — never infer |
| **Object type syntax** | Views need `COMMENT ON COLUMN`; tables need `ALTER TABLE ... ALTER COLUMN COMMENT` | .downstream.alter.sql uses correct syntax per object type |
| **1024 char limit** | UC column comments max 1024 characters | Phase 11 enforces; truncates with `[truncated]` marker |
| **PriceLog sharding** | PriceLog is partitioned/sharded — no single mapping entry | lineage.py handles gracefully (skip with warning) |
| **Column name typos** | Production columns have typos (e.g., `OpenMarketCoversionRate`) | Document typo in description, don't "fix" the name |
| **Dead columns** | Some columns always NULL or deprecated | Flag in description ("Deprecated/unused column. Always NULL.") |
| **Shared columns across tables** | Same column (e.g., PositionID) appears in many tables | Each table's .downstream.alter.sql emits independently — idempotent |
| **Synapse connection drops** | Long-running sessions drop | MCP server has keepalive thread + reconnect |
| **Databricks token expiry** | OAuth tokens expire after 1hr | SDK auto-refreshes; SP tokens don't expire |
| **Atlassian rate limits** | Heavy search can hit limits | Backoff + partial results OK |
| **SP code not in repo** | Some SPs may be generated or missing | Skip + flag in review sidecar |
| **Cross-schema FKs** | Table in DWH_dbo references Dealing_dbo | FK lookup reference handles cross-schema |
| **Materialized views** | Some downstream objects are MVs, not views | COMMENT ON COLUMN works for MVs too |
| **Schema evolution** | Columns added/removed between runs | DESCRIBE TABLE at runtime; skip missing columns |

---

## 8. Proposed Architecture (Production)

```
┌─────────────────────────────────────────────────────────┐
│                    Orchestrator                          │
│            (Airflow DAG / ADF Pipeline / cron)           │
│                                                         │
│  for each table in priority_queue:                      │
│    1. Data Gathering    (Python, direct SDK calls)      │
│    2. LLM Generation    (Azure OpenAI API call)         │
│    3. Output to branch  (git commit to feature branch)  │
│    4. Create PR         (gh pr create)                  │
│    5. Notify reviewers  (Slack/Teams/email)             │
│    6. Wait for approval (webhook or poll)               │
│    7. Deploy ALTERs     (Databricks SDK)                │
│    8. Deploy lineage    (Databricks SDK)                │
│    9. Merge PR          (gh pr merge)                   │
└─────────────────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
    ┌─────────┐   ┌──────────┐   ┌──────────┐
    │ Synapse │   │Databricks│   │ Atlassian│
    │   SQL   │   │  UC API  │   │   API    │
    │ (pyodbc)│   │  (SDK)   │   │  (REST)  │
    └─────────┘   └──────────┘   └──────────┘

Auth: All via Service Principals
      Secrets in Azure Key Vault
      Rotated automatically
```

---

## 9. Decision Points for Brainstorming

1. **Execution model**: Cursor-driven (A) vs. headless (B) vs. hybrid (C)?
2. **LLM provider**: Azure OpenAI (GPT-4) vs. Anthropic API vs. keep Cursor?
3. **Repo home**: Standalone repo vs. subfolder in Dataplatform?
4. **Branch strategy**: One branch per table vs. batch branches?
5. ~~**Review workflow**: PR-based vs. dedicated review UI vs. Slack bot?~~ → **DECIDED**: Offline review via `.review-needed.md` + wiki-review skill. Review-rerun mode for corrections.
6. ~~**Deploy authority**: Auto-deploy after approval vs. manual deploy step?~~ → **DECIDED**: Auto-deploy (ALTERs are idempotent). Lineage injection remains manual/offline.
7. **Scheduling**: On-demand vs. nightly batch vs. triggered by schema changes?
8. **Priority**: Which 20 tables first? By query frequency? By analyst requests?
9. ~~**Lineage injection**: Run per-table or batch all at end?~~ → **DECIDED**: Generate `.lineage.py` per table, execute separately (offline).
10. **Maintenance trigger**: How to detect schema changes and re-run?
