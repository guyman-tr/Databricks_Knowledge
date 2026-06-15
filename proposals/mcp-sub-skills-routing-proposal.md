# Proposal: Sub-Skills as a Structured Schema Field for `skills_find_skills`

**Status**: Draft for review
**Author**: Data semantics team (eToro DWH skills corpus)
**Target audience**: Data engineering team owning `databricks/skills-mcp`
**Repo path of target service**: `dataplatforms/databricks/skills-mcp/`
**Date**: 2026-05-27

---

## TL;DR

We propose adding a `sub_skills:` array to the `Skill` schema in `databricks-skills-mcp/server/schema.py`, plus a two-pass scoring path in `databricks-skills-mcp/server/tools.py::find_skills`. The first pass remains unchanged — FAISS scores the user's question against every hub. The second pass, run only against the winning hub's children, scores the same prompt vector against each child's own embedding, and returns the matched child body inline alongside the hub. This preserves the hub-as-navigation-layer architecture while making topic-level routing automatic — closing the structural gap that caused the production MIMO failure documented in the appendix.

This is option 3 from a three-way comparison considered:

- Option 1 (corpus restructure only) — promote each sub-skill to a peer-level `SKILL.md` folder. No MCP change. Trade-off: hubs lose their natural job (cross-cutting glue) because children become standalone.
- Option 2 (loader walks one folder deeper) — `skills/<hub>/<sub>/SKILL.md`. Modest MCP change. Trade-off: same outcome as option 1 architecturally, just a different file layout.
- **Option 3 (this proposal)** — structured `sub_skills:` schema field + two-pass scoring. Hub stays the indexed entry point with cross-cutting context; children get auto-routed via second-pass embedding. Most code change, but the only one that delivers hub-context-plus-child-body in a single tool call.

The corpus already physically contains the sub-skill `.md` files (see `data-skills/skills/domain-payments/mimo-panel-and-ddr.md`); they are currently dropped by the loader as "supplementary reference content". This proposal makes them first-class queryable artifacts.

---

## 1. Problem statement

### 1.1 The MIMO failure (production, 2026-05-25)

A user asked Claude (via the gateway) "net MIMO last month". The agent:

1. Called `skills_find_skills(question="net MIMO last month")`.
2. Received `domain-payments` (the only payments-related skill in the FAISS corpus).
3. Read the hub's body, which explicitly contains the routing instruction *"default to mimo-panel-and-ddr FIRST for any 'how much money flowed' question"*.
4. Ignored the routing instruction. Wrote naive `Deposit - Withdraw` SQL.
5. Missed the canonical net-deposits definition (which lives in `mimo-panel-and-ddr.md` with proper handling of `IsInternalTransfer`, `IsIBANQuickTransfer`, `IsRedeem`, reversals, and crypto-to-fiat exclusions).

The agent's own postmortem: *"I had the routing instruction, ignored it, and got away with it because nothing in the tool forced a follow-up call."*

### 1.2 The structural root cause (in your code)

The agent's failure is real, but the structural cause is in the loader. We pulled the `dev` branch and read `databricks-skills-mcp/server/loader.py` (specifically the version on `feature/DEI-3745_adjust_the_mcp_skill_tools_to_work_with_the_new_hierarchy`). The relevant block:

```python
# server/loader.py, load_skills(), inside _discover paths
flat_files = sorted(skills_root.glob("*.{yaml,md}"))
folder_files = sorted(skills_root.glob("*/SKILL.{yaml,md}"))
files = flat_files + folder_files
# ...
# Inside a `<skill-id>/` folder, anything other than SKILL.* is dropped:
# "Anything else under a skill folder (PATTERNS.md, PLAYBOOK.md, 
#  source-tables.md, ...) is supplementary reference content, not a skill,
#  and is ignored on purpose."
```

`data-skills/skills/domain-payments/mimo-panel-and-ddr.md` has a complete valid frontmatter (`id: mimo-panel-and-ddr`, `description`, `required_tables`, `sample_questions`, `triggers`, 271-line body). It is treated like `PATTERNS.md` and **never reaches FAISS**. The Skills MCP physically cannot return it because it isn't indexed. No amount of routing text in the hub body can fix this; the agent ignored the routing text anyway, and even if it had complied, no follow-up tool call exists that could surface the child.

### 1.3 Why agent-discipline routing is not a path forward

Three reasons:

1. **It already failed in production.** The hub's routing instruction was clear and explicit; the agent did not follow it. We cannot rely on prompt-text contracts that the model decides whether to honor.
2. **It is not testable.** Compliance with a routing instruction is observed per-call, not per-deployment.
3. **It does not scale.** Every hub would need its own routing instruction, and the agent would need to interpret each one correctly under different question shapes.

The fix has to be structural: the tool itself surfaces the right thing, with no agent compliance required.

---

## 2. Current architecture (relevant parts only)

We read the codebase in detail. This section is for reviewers who want to confirm the proposal's claims against the actual code.

### 2.1 Fingerprint composition

[`databricks-skills-mcp/server/schema.py:131-152`](../databricks-skills-mcp/server/schema.py), method `Skill.embedding_text()`:

```python
def embedding_text(self) -> str:
    parts: list[str] = [self.description.strip()]
    if self.body_markdown:
        parts.append(self.body_markdown[:1500].strip())
    if self.triggers:
        parts.append(" ".join(self.triggers))
    if self.sample_questions:
        parts.append("\n".join(self.sample_questions))
    if self.domain_tags:
        parts.append(" ".join(self.domain_tags))
    return "\n\n".join(p for p in parts if p)
```

Note: `unity_catalog_assets` is not in the fingerprint. (See companion proposal `mcp-unity-catalog-assets-in-fingerprint.md` if/when filed.)

### 2.2 Matcher path

[`databricks-skills-mcp/server/tools.py::find_skills`](../databricks-skills-mcp/server/tools.py):

```text
question
  → embedder.embed_one(question)         # databricks-gte-large-en, L2-normalised
  → skill_index.search(query_vec, wide_k)
       wide_k = min(max(k*4, k+5), len(corpus))   # ACL-drop headroom
  → optional domain_tag post-filter
  → acl_filter(ranked_skills)            # DESCRIBE TABLE probe per asset
  → slice to k
  → return [_skill_to_dict(s, score=...) for s in top_visible]
```

[`databricks-skills-mcp/server/index.py`](../databricks-skills-mcp/server/index.py): FAISS `IndexFlatIP` over L2-normalised vectors (cosine via inner product). Atomic swap on rebuild.

### 2.3 Loader contract (DEI-3745)

[`databricks-skills-mcp/server/loader.py::load_skills`](../databricks-skills-mcp/server/loader.py):

- Discovers `skills/*.yaml`, `skills/*.yml`, `skills/*.md` (flat layout).
- Discovers `skills/*/SKILL.yaml`, `skills/*/SKILL.yml`, `skills/*/SKILL.md` (folder layout).
- Folder-layout id derivation: `_skill_name(path)` returns `path.parent.name` when `path.stem.upper() == "SKILL"`, else `path.stem`.
- All other files inside a `<skill-id>/` folder are silently ignored. The comment in the code explicitly names `PATTERNS.md`, `PLAYBOOK.md`, `source-tables.md` as the intended drops.

### 2.4 Schema (current state)

[`databricks-skills-mcp/server/schema.py`](../databricks-skills-mcp/server/schema.py):

```python
class Skill(BaseModel):
    id: str
    version: int = Field(ge=1)
    owner: str
    description: str = Field(min_length=10)
    unity_catalog_assets: list[str] = Field(default_factory=list)  # DEI-3745: default empty
    name: str | None = None
    last_validated_at: date | None = None
    domain_tags: list[str] = Field(default_factory=list)
    triggers: list[str] = Field(default_factory=list)
    sample_questions: list[str] = Field(default_factory=list)
    column_notes: dict[str, dict[str, str]] = Field(default_factory=dict)
    join_hints: list[str] = Field(default_factory=list)
    common_filters: list[str] = Field(default_factory=list)
    example_sql: str | None = None
    body_markdown: str | None = None
    genie_space_id: str | None = None
```

---

## 3. Proposed design

### 3.1 Schema additions

Add a new pydantic model `SubSkill` and a `sub_skills` field on `Skill`.

```python
# server/schema.py

class SubSkill(BaseModel):
    """One child topic under a hub Skill.

    Each SubSkill produces its own embedding vector at corpus boot, stored
    in the FAISS index alongside its parent hub but tagged with the parent's
    id for second-pass gating. The child's body lives in a sibling .md file
    under the hub's folder; the loader resolves it via `body_source`.
    """

    id: str = Field(pattern=r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
    description: str = Field(min_length=10)
    body_source: str | None = None
    # ↑ Path RELATIVE TO THE HUB FOLDER. Defaults to f"{id}.md" if omitted.
    #   Example: hub at skills/domain-payments/SKILL.md with sub_skill
    #   id="mimo-panel-and-ddr" and body_source omitted resolves to
    #   skills/domain-payments/mimo-panel-and-ddr.md.

    sample_questions: list[str] = Field(default_factory=list)
    triggers: list[str] = Field(default_factory=list)
    unity_catalog_assets: list[str] = Field(default_factory=list)
    example_sql: str | None = None
    column_notes: dict[str, dict[str, str]] = Field(default_factory=dict)
    join_hints: list[str] = Field(default_factory=list)
    common_filters: list[str] = Field(default_factory=list)

    # Populated by the loader after dereferencing body_source. Not authored.
    body_markdown: str | None = None

    @field_validator("unity_catalog_assets")
    @classmethod
    def _check_assets(cls, v: list[str]) -> list[str]:
        for asset in v:
            if not UC_ASSET_PATTERN.fullmatch(asset):
                raise ValueError(
                    f"sub_skill unity_catalog_assets entry {asset!r} must "
                    f"match {UC_ASSET_PATTERN.pattern}"
                )
        return v

    def embedding_text(self) -> str:
        """Build the fingerprint blob for this sub-skill.

        Same composition order as Skill.embedding_text() so the two embedding
        spaces are comparable. The hub's fingerprint stays distinct from any
        of its children's fingerprints (different text content).
        """
        parts: list[str] = [self.description.strip()]
        if self.body_markdown:
            parts.append(self.body_markdown[:1500].strip())
        if self.triggers:
            parts.append(" ".join(self.triggers))
        if self.sample_questions:
            parts.append("\n".join(self.sample_questions))
        return "\n\n".join(p for p in parts if p)


class Skill(BaseModel):
    # ... existing fields ...
    sub_skills: list[SubSkill] = Field(default_factory=list)

    @model_validator(mode="after")
    def _check_sub_skill_ids_unique_within_hub(self) -> Skill:
        ids = [ss.id for ss in self.sub_skills]
        if len(ids) != len(set(ids)):
            duplicates = sorted(i for i in ids if ids.count(i) > 1)
            raise ValueError(
                f"sub_skills contains duplicate id(s) within hub {self.id!r}: "
                f"{sorted(set(duplicates))}"
            )
        # Reserved: sub-skill id must not collide with any top-level hub id.
        # Cross-corpus uniqueness is enforced post-load in loader.load_skills.
        return self
```

### 3.2 Loader changes

The loader needs to:

1. Parse the hub's `sub_skills:` array normally via pydantic.
2. For each sub-skill, dereference `body_source` (default: `f"{id}.md"`) relative to the hub folder.
3. Read the referenced file. If it has YAML frontmatter, MERGE that frontmatter into the SubSkill (frontmatter fields override the inline hub frontmatter; this lets the child file be authoritative for its own description/sample_questions/triggers).
4. Set `sub_skill.body_markdown` to the file body (post-frontmatter, if any).
5. Validate the merged SubSkill against the pydantic model.
6. Cross-corpus uniqueness check: every `sub_skill.id` must be globally unique across all hubs and not collide with any top-level Skill id.

Skeleton:

```python
# server/loader.py, inside load_skills() after the existing hub validation:

def _resolve_sub_skill_body(hub_path: Path, sub: SubSkill) -> tuple[SubSkill, str | None]:
    """Resolve body_source for one sub-skill. Returns (sub_with_body, error_or_none)."""
    source = sub.body_source or f"{sub.id}.md"
    body_path = hub_path.parent / source
    if not body_path.is_file():
        return sub, f"sub_skill {sub.id!r}: body_source {source!r} does not exist"

    text = body_path.read_text()

    # If the child file has its own frontmatter, parse it and merge.
    # Frontmatter fields are authoritative for the child; the hub's inline
    # SubSkill entry provides defaults (typically only `id`).
    suffix = body_path.suffix.lower()
    if suffix == ".md":
        meta, body, fail_reason = _parse_skill_md(text)
        if fail_reason is None:
            # Drop fields not part of SubSkill schema (e.g., 'version',
            # 'owner', 'name', 'genie_space_id'). These are hub-only.
            allowed = {
                "id", "description", "body_source", "sample_questions",
                "triggers", "unity_catalog_assets", "example_sql",
                "column_notes", "join_hints", "common_filters",
            }
            merged = {**sub.model_dump(exclude_none=True), **{k: v for k, v in meta.items() if k in allowed}}
            merged["body_markdown"] = body or None
            try:
                sub = SubSkill.model_validate(merged)
            except ValidationError as e:
                return sub, f"sub_skill {sub.id!r}: merged validation failed: {e.errors()[0]['msg']}"
        else:
            # No frontmatter in child file; treat entire text as body.
            sub = sub.model_copy(update={"body_markdown": text.strip() or None})
    else:
        sub = sub.model_copy(update={"body_markdown": text.strip() or None})

    if sub.body_markdown is None and sub.example_sql is None:
        return sub, f"sub_skill {sub.id!r}: needs body_markdown OR example_sql"
    return sub, None


# Inside load_skills(), after the per-hub Skill is validated:
resolved_subs: list[SubSkill] = []
for sub in skill.sub_skills:
    resolved, err = _resolve_sub_skill_body(path, sub)
    if err is not None:
        errors.append(f"{rel}: {err}")
        continue
    resolved_subs.append(resolved)
skill = skill.model_copy(update={"sub_skills": resolved_subs})

# After all hubs loaded, enforce cross-corpus uniqueness:
all_ids: set[str] = set()
for s in skills:
    if s.id in all_ids:
        errors.append(f"duplicate id across corpus: {s.id!r}")
    all_ids.add(s.id)
    for sub in s.sub_skills:
        if sub.id in all_ids:
            errors.append(
                f"sub_skill id {sub.id!r} (under hub {s.id!r}) collides "
                f"with another skill or sub_skill in the corpus"
            )
        all_ids.add(sub.id)
```

### 3.3 Index changes

The FAISS index stores one vector per entity (hub OR sub-skill). Each row carries metadata indicating whether it's a hub or a child, and if a child, its parent hub id.

```python
# server/index.py

@dataclass(frozen=True)
class IndexRow:
    """One vector in the FAISS index — either a hub or a sub-skill."""
    kind: Literal["hub", "sub_skill"]
    hub_id: str                      # Always the parent hub's id (or self for hubs)
    sub_skill_id: str | None = None  # Set iff kind == "sub_skill"


@dataclass(frozen=True)
class SearchHit:
    row: IndexRow
    score: float


class SkillIndex:
    def __init__(self) -> None:
        self._lock = threading.RLock()
        self._index: faiss.Index | None = None
        self._rows: list[IndexRow] = []
        self._skills_by_id: dict[str, Skill] = {}
        self._sub_skills_by_id: dict[str, SubSkill] = {}  # global child lookup

    def build(self, skills: list[Skill], hub_vectors: np.ndarray, 
              sub_skill_vectors: dict[str, np.ndarray]) -> None:
        """Build with hub vectors + (hub_id -> child vectors stacked)."""
        rows: list[IndexRow] = []
        all_vectors: list[np.ndarray] = []
        skills_by_id: dict[str, Skill] = {}
        sub_skills_by_id: dict[str, SubSkill] = {}

        for i, skill in enumerate(skills):
            rows.append(IndexRow(kind="hub", hub_id=skill.id))
            all_vectors.append(hub_vectors[i:i+1])
            skills_by_id[skill.id] = skill

            child_vecs = sub_skill_vectors.get(skill.id)
            if child_vecs is not None and len(skill.sub_skills) > 0:
                for j, sub in enumerate(skill.sub_skills):
                    rows.append(IndexRow(
                        kind="sub_skill",
                        hub_id=skill.id,
                        sub_skill_id=sub.id,
                    ))
                    all_vectors.append(child_vecs[j:j+1])
                    sub_skills_by_id[sub.id] = sub

        stacked = np.vstack(all_vectors).astype(np.float32, copy=False)
        new_index = faiss.IndexFlatIP(stacked.shape[1])
        new_index.add(stacked)

        with self._lock:
            self._index = new_index
            self._rows = rows
            self._skills_by_id = skills_by_id
            self._sub_skills_by_id = sub_skills_by_id

    def search_hubs(self, query_vector: np.ndarray, k: int) -> list[SearchHit]:
        """First pass — score against hubs only.

        Internally still searches the full index (one FAISS call) and then
        filters to `kind == 'hub'` rows. This is cheaper than maintaining a
        separate hub-only index because IndexFlatIP scans are already O(N)
        and N stays under ~5k.
        """
        hits = self._raw_search(query_vector, k=k * 4)  # widen for filter
        return [h for h in hits if h.row.kind == "hub"][:k]

    def search_sub_skills_under(
        self, query_vector: np.ndarray, hub_id: str, k: int
    ) -> list[SearchHit]:
        """Second pass — score against children of one hub."""
        hits = self._raw_search(query_vector, k=len(self._rows))
        return [
            h for h in hits
            if h.row.kind == "sub_skill" and h.row.hub_id == hub_id
        ][:k]
```

### 3.4 `find_skills` — two-pass routing

```python
# server/tools.py, modified find_skills

@mcp_server.tool
def find_skills(
    question: str,
    k: int = 5,
    domain_tag: str | None = None,
    sub_k: int = 1,
) -> dict:
    """Find the top-K hub skills + matched sub-skill body for each.

    Two-pass routing:
      1. Score `question` against every hub (existing behaviour).
      2. For each returned hub that has sub_skills, score the same question
         vector against that hub's children and attach the top `sub_k`
         matches as `matched_sub_skills` on the hub's response entry.

    Args:
        question: NL question.
        k: Max hubs to return (default 5, clamped [1, 25]).
        domain_tag: Optional hub-level domain filter.
        sub_k: Max sub-skills per hub (default 1, max 3).

    Returns:
        {
          "skills": [
            {
              "id": "domain-payments",
              "score": 0.61,
              "match_quality_hint": "above_floor",
              "description": "...",
              "body_markdown": "...",
              "unity_catalog_assets": [...],
              "matched_sub_skills": [
                {
                  "id": "mimo-panel-and-ddr",
                  "score": 0.78,
                  "match_quality_hint": "above_floor",
                  "description": "...",
                  "body_markdown": "...",
                  "sample_questions": [...],
                  "unity_catalog_assets": [...],
                  "example_sql": "..."
                }
              ]
            }
          ],
          "filtered_count": 0,
          "advisory": "..."
        }
    """
    if not question or not question.strip():
        return {"skills": [], "filtered_count": 0, "advisory": _ADVISORY}

    k = max(_MIN_K, min(_MAX_K, k))
    sub_k = max(0, min(3, sub_k))

    query_vec = embedder.embed_one(question)

    # First pass — hubs
    hub_hits = skill_index.search_hubs(query_vec, k=k * 4)  # widen for ACL drops

    # Domain tag filter (post-search)
    if domain_tag:
        hub_hits = [
            h for h in hub_hits
            if domain_tag in skill_index.get_skill(h.row.hub_id).domain_tags
        ]

    # ACL filter (hubs only — sub-skill UC assets are also checked but
    # they should be a subset of the hub's anchors in normal authoring)
    visible_hubs = acl_filter([
        skill_index.get_skill(h.row.hub_id) for h in hub_hits
    ])
    visible_hub_ids = {s.id for s in visible_hubs}
    hub_hits = [h for h in hub_hits if h.row.hub_id in visible_hub_ids][:k]

    # Second pass — for each visible hub, score its children
    skill_dicts: list[dict] = []
    for hub_hit in hub_hits:
        hub = skill_index.get_skill(hub_hit.row.hub_id)
        hub_dict = _skill_to_dict(hub, score=hub_hit.score, policy=policy)

        if sub_k > 0 and hub.sub_skills:
            sub_hits = skill_index.search_sub_skills_under(
                query_vec, hub_id=hub.id, k=sub_k,
            )
            hub_dict["matched_sub_skills"] = [
                _sub_skill_to_dict(
                    skill_index.get_sub_skill(h.row.sub_skill_id),
                    score=h.score,
                    policy=policy,
                )
                for h in sub_hits
            ]
        else:
            hub_dict["matched_sub_skills"] = []

        skill_dicts.append(hub_dict)

    return {
        "skills": skill_dicts,
        "filtered_count": len(visible_hubs) - len(hub_hits),
        "advisory": _ADVISORY,
    }
```

Tool description (the docstring above) must be updated to teach the LLM the new shape — that `matched_sub_skills` is the canonical place for topic-level grounding and that the agent should prefer the matched sub-skill's `body_markdown` / `example_sql` over the hub's when both are present.

### 3.5 `get_skill` — resolve sub-skill ids

```python
@mcp_server.tool
def get_skill(id: str) -> dict:
    """Fetch one skill OR sub-skill by id.

    Sub-skill ids are globally unique across the corpus (loader enforces),
    so a single id parameter unambiguously identifies the right artifact.

    Returns the canonical record:
      - For a hub: as today, plus `sub_skills` array (without bodies)
      - For a sub-skill: the SubSkill record fully resolved, plus a
        `parent_id` pointing to the hub for context.
    """
    skill = skill_index.get_skill(id)
    if skill is not None:
        out = skill.model_dump(mode="json")
        out["sub_skills"] = [
            {"id": s.id, "description": s.description}
            for s in skill.sub_skills
        ]
        return out

    sub = skill_index.get_sub_skill(id)
    if sub is not None:
        out = sub.model_dump(mode="json")
        out["parent_id"] = skill_index.get_parent_id(id)
        return out

    return {"error": "not_found", "id": id}
```

### 3.6 Gateway audit middleware

[`databricks-mcp-gateway/server/middleware.py::AuditMiddleware`](../databricks-mcp-gateway/server/middleware.py) currently logs: ts, user_email, mcp_client_name, tool, args_hash, args_preview, upstream_prefix, latency_ms, status.

For `skills_find_skills` calls, additionally log (parse from the tool result, NOT from args):

| Field | Type | Definition |
|---|---|---|
| `returned_hub_ids` | `list[str]` | `[s.id for s in result.skills]` |
| `triggering_sub_skill_ids` | `list[str]` | flatten `s.matched_sub_skills[*].id` across all returned hubs |
| `hub_top_score` | `float` | `result.skills[0].score` (or null if empty) |
| `sub_skill_top_score` | `float` | max over all `matched_sub_skills[*].score`, or null |
| `hub_below_floor` | `bool` | all returned hubs have `match_quality_hint == "below_floor"` |
| `sub_skill_below_floor` | `bool` | analogous for sub-skills |
| `had_matched_sub_skills` | `bool` | any returned hub has non-empty `matched_sub_skills` |

These pair with the v6.1 audit fields already proposed (`skills_top_score`, `skills_match_quality_hint`, `skills_all_below_floor`) so downstream analytics can cleanly join hub-level retrieval quality with sub-skill-level retrieval quality.

### 3.7 Settings / configuration

Add to [`databricks-skills-mcp/server/settings.py`](../databricks-skills-mcp/server/settings.py):

| Env var | Default | Purpose |
|---|---|---|
| `SKILLS_SUB_PASS_ENABLED` | `true` | Kill switch. If `false`, `find_skills` returns hubs with `matched_sub_skills: []` regardless of corpus contents. Operational rollback path. |
| `SKILLS_SUB_K_DEFAULT` | `1` | Default value for the tool's `sub_k` parameter. Tool's max stays 3. |
| `SKILLS_SUB_MIN_SCORE` | (unset) | Optional labelling floor for sub-skill matches; same "label, don't drop" semantics as the hub-level `SKILLS_MIN_SCORE` from the v6.1 work. |

---

## 4. Authoring conventions (corpus side)

The corpus side of this proposal is what our team (data semantics) commits to deliver in parallel. We document it here so the contract between corpus and MCP is unambiguous.

### 4.1 File layout

```
data-skills/
  skills/
    domain-payments/
      SKILL.md                       # hub frontmatter + body
      mimo-panel-and-ddr.md          # sub-skill body file (its own frontmatter)
      deposits-and-withdrawals.md
      crypto-wallet.md
      emoney-accounts-and-cards.md
      finance-recon-and-balances.md
    domain-customer-and-identity/
      SKILL.md
      customer-master-record.md
      ...
    ...
```

The hub's `SKILL.md` lists its children by id in `sub_skills:`. The children sit as siblings (the loader was previously dropping them; now it dereferences them via `sub_skills.body_source`).

### 4.2 Hub frontmatter example

```yaml
---
id: domain-payments
name: "Payments Super-Domain"
version: 1
owner: dwh-semantics@example.com
description: >
  Routes inside the Payments super-domain. Use when a question is about
  money flow into or out of an eToro customer wallet — fiat deposits and
  withdrawals, eMoney IBAN and cards, crypto wallet movements, the
  cross-platform MIMO panel, customer balance state, or Finance
  external-partner reconciliation.
domain_tags: [payments]
triggers: [payments, deposit, withdrawal, mimo, balance, finance recon]
sample_questions:
  - "what tables cover payments overall?"
  - "where do I look for MIMO vs raw billing?"
sub_skills:
  - id: mimo-panel-and-ddr
  - id: deposits-and-withdrawals
  - id: crypto-wallet
  - id: emoney-accounts-and-cards
  - id: finance-recon-and-balances
unity_catalog_assets: []   # hubs may have none; children carry the anchors
---

# Payments super-domain

(navigation map body, cross-cutting warnings, valid-user filter contract,
currency rules — none of which belong on individual children)
```

### 4.3 Sub-skill file example

```yaml
---
id: mimo-panel-and-ddr
description: >
  Cross-platform Money-In / Money-Out (MIMO) panel and the new Daily Data
  Report (DDR) framework. Default skill for any "how much money flowed",
  "FTD count", "deposit/withdrawal volumes" question. Anchored on
  bi_db_ddr_fact_mimo_allplatforms.
sample_questions:
  - "net MIMO last month"
  - "deposits minus withdrawals by country last week"
  - "FTD count for emoney platform"
triggers:
  - net mimo
  - net deposits
  - mimo allplatforms
  - bi_db_ddr_fact_mimo_allplatforms
  - daily customer status
unity_catalog_assets:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
  - main.etoro_kpi_prep.v_mimo_tradingplatform
  - main.etoro_kpi_prep.v_mimo_emoneyplatform
example_sql: |
  SELECT ...
---

# MIMO Panel and DDR

(canonical body explaining the table, the columns, the gotchas)
```

The child file has frontmatter that the loader merges with the hub's inline `sub_skill` entry. In the common case the hub's entry is just `{id: <child-id>}` and the child file is the source of truth for everything else.

### 4.4 Linting rules (corpus side, our responsibility)

We will update `tools/skills/lint_skill.py` to enforce:

- Every file inside a `<hub>/` folder other than `SKILL.md` must be referenced by exactly one `sub_skill.body_source` in that hub.
- Every `sub_skill.id` must be globally unique across all hubs.
- Sub-skill frontmatter `id` must match the entry's `id` in the parent hub.
- `unity_catalog_assets` on the sub-skill must be a subset of (or disjoint from with explicit ACL coverage in) the hub's UC assets — TBD with you.

---

## 5. Backward compatibility & migration

### 5.1 Skills with no `sub_skills`

A skill with no `sub_skills:` field (or an empty array) behaves identically to today. The tool returns it with `matched_sub_skills: []`. No corpus author is forced to migrate.

### 5.2 Skills currently authored with sibling `.md` files

These exist already (see `data-skills/skills/domain-payments/` on `dev`). Today's loader drops them. After this change they remain dropped UNTIL the hub's frontmatter is updated to reference them via `sub_skills:`. This is a deliberate choice — adding `sub_skills:` is an opt-in signal that the author wants the child indexed.

### 5.3 Operational rollback

`SKILLS_SUB_PASS_ENABLED=false` kills the second pass without touching the corpus. The tool returns hubs with `matched_sub_skills: []`, identical to the no-children path.

### 5.4 Pre-deploy validation

The loader's existing `SkillLoadError` mechanism collects all errors and raises one combined exception at startup. This stays. A misauthored `sub_skills:` array (missing body file, duplicate id, invalid frontmatter) fails the boot loudly — same as today's malformed-hub behaviour.

---

## 6. Testing strategy

### 6.1 Unit tests (new and modified)

| Test file | What to cover |
|---|---|
| `tests/test_schema.py` (new or extended) | `SubSkill` pydantic validators — id pattern, description min length, UC asset pattern, body_markdown / example_sql at least one |
| `tests/test_loader.py` | Sub-skill body_source resolution (default and explicit path), frontmatter merge precedence, missing body file → error, duplicate sub_skill id within hub → error, sub_skill id colliding with another hub id → error, sub_skill id colliding with another sub_skill id (different hubs) → error |
| `tests/test_index.py` | Hub + child vectors both in index, `search_hubs` returns only hubs, `search_sub_skills_under` returns only children of the right parent, atomic-swap behaviour under build during search |
| `tests/test_tools.py` | `find_skills` returns hubs with non-empty `matched_sub_skills`, `sub_k=0` suppresses children, `sub_k=3` returns up to 3, hub-only corpus still works, ACL filter still applied to hubs only, `domain_tag` filter still applied to hubs only |
| `tests/test_tools.py::get_skill` | Sub-skill id resolves to SubSkill record with `parent_id`, hub id still resolves to Skill with `sub_skills` summary |
| `tests/test_acl.py` | Hub ACL is the gate (current behaviour); document explicitly that sub-skill UC assets are NOT separately ACL-probed in v1 |
| Gateway `tests/test_middleware.py` | Audit row carries the new `triggering_sub_skill_ids`, `sub_skill_top_score`, `had_matched_sub_skills` fields when the tool was `skills_find_skills` |

### 6.2 Smoke test (recommended)

Reproduce the MIMO failure as a regression test:

```python
# tests/test_smoke.py

@pytest.mark.asyncio
async def test_mimo_question_returns_matched_sub_skill(mcp_with_real_corpus):
    result = await _call(server, "find_skills", {"question": "net MIMO last month"})
    
    top_hub = result["skills"][0]
    assert top_hub["id"] == "domain-payments"
    
    matched = top_hub["matched_sub_skills"]
    assert len(matched) >= 1
    assert matched[0]["id"] == "mimo-panel-and-ddr"
    assert "IsInternalTransfer" in matched[0]["body_markdown"]
```

This locks the failure mode out of regression-by-corpus-drift.

### 6.3 Calibration test

After deploy, replay the last 7 days of `mcp_gateway` prompts through the upgraded `find_skills` and confirm:

- ≥ 95% of prompts that historically matched a hub now ALSO get a `matched_sub_skill` populated (where the hub has children).
- The `sub_skill_top_score` distribution is sensible (cluster around the same range as `hub_top_score`).

---

## 7. Rollout phases

### Phase 0 — Corpus restructure (our side, pre-MCP)

We restructure `knowledge/skills/` and `data-skills/skills/` so every domain hub has its `sub_skills:` array populated and every referenced child file exists. Timeline: 1-2 weeks. This is non-disruptive to current MCP behaviour because the new field is ignored until the MCP is upgraded.

### Phase 1 — MCP schema + loader (your side, behind kill switch)

Land the schema additions, loader changes, and index changes. Keep `SKILLS_SUB_PASS_ENABLED=false` initially. Validate that loading our restructured corpus succeeds and the hub-only path is unchanged.

### Phase 2 — Two-pass routing (your side, kill switch flipped)

Land the `find_skills` and `get_skill` changes plus the gateway audit changes. Flip `SKILLS_SUB_PASS_ENABLED=true` in `dev`. Smoke test the MIMO question end-to-end through the gateway. Watch the audit table for the new fields.

### Phase 3 — Production deploy

Promote to production after the dev environment runs cleanly for ~1 week. The kill switch stays as an operational rollback for ~3 months before being retired.

### Phase 4 — Drop the v1 ignore-list

After Phase 3 is stable, optionally tighten the loader: instead of silently ignoring un-referenced `.md` files inside a hub folder, log a warning. This catches dangling author errors. Out of scope for this PR; tracked separately.

---

## 8. Open questions / decisions for the DE team

These are points where we have a default recommendation but recognise you may have stronger context.

### 8.1 Should sub-skills be ACL-probed independently?

Our default: NO. The hub's `unity_catalog_assets` is the gate; if the user lacks permission on the hub, the child never surfaces. If a child anchors on assets the hub doesn't list, those go un-checked at v1.

Alternative: probe the union of hub + matched children. More correct but adds latency per call.

### 8.2 Where does the cross-corpus id uniqueness check live?

Our default: in `loader.load_skills` after all hubs are validated, before the index is built. Errors collected into the existing `SkillLoadError`.

Alternative: separate validation module called from both the MCP and the data-skills CI.

### 8.3 Do sub-skill vectors share the FAISS index with hubs?

Our default: YES — one global `IndexFlatIP` with metadata tagging. Simpler. Hub-only search becomes a filtered slice.

Alternative: per-hub mini-indexes. Slightly cleaner conceptually but more state to manage and atomic-swap on rebuild.

### 8.4 What should `find_skills` do when a question matches a sub-skill more strongly than any hub?

Our default: still gate by hub-first. Hub wins → second pass surfaces the child. If the question's best hub score is 0.42 (below floor) but the child it would have routed to scored 0.81 — we lose that signal under hub-first gating.

Alternative: allow children to compete with hubs in the first pass (ungated), with a metadata tag so the tool can still attach the parent's body for context. More powerful, more complex.

Recommendation: ship hub-gated v1 to match the designer's original Option 2 shape. If audit data shows hub-gating loses real signal, revisit in v1.1.

### 8.5 Should `sub_skills.body_source` allow paths outside the hub folder?

Our default: NO. `body_source` is resolved relative to the hub folder; absolute paths and `..` traversal are rejected. Keeps the file layout disciplined and the loader sandboxed.

### 8.6 Sub-skill ranking score normalisation

Hub and sub-skill cosine scores are both produced by the same encoder on the same prompt — they're directly comparable as numbers. Should the response present them on the same scale, or should sub-skill scores be re-normalised within their parent hub (so the top child of each hub is always 1.0)?

Our default: same scale, raw cosine. The agent can reason about both. Renormalisation hides information.

### 8.7 Migration path for hubs that DON'T currently have sibling sub-skill files

Some hubs (e.g. domain-cross) may not have children. They author no `sub_skills:` and behave as today. No migration required for them.

---

## 9. Estimated effort

Rough sizing, by file in `databricks/skills-mcp/databricks-skills-mcp/`:

| File | Lines added | Lines modified |
|---|---|---|
| `server/schema.py` | ~80 (SubSkill class + Skill field + validators) | ~5 |
| `server/loader.py` | ~70 (_resolve_sub_skill_body + integration) | ~20 |
| `server/index.py` | ~60 (IndexRow + search variants) | ~40 |
| `server/tools.py` | ~70 (two-pass find_skills + get_skill resolver) | ~30 |
| `server/settings.py` | ~15 (three new env vars) | 0 |
| `tests/test_*.py` | ~300 (new cases across 5 files) | ~20 |
| Gateway `server/middleware.py` | ~30 (audit field extraction for skills_find_skills) | ~10 |
| Gateway `tests/test_middleware.py` | ~80 (audit assertions) | ~10 |
| **Total** | **~705** | **~135** |

This excludes:

- Corpus authoring on our side (~51 sub-skill files plus 12 thinned hubs)
- Audit-log Delta schema migration if `Monitoring_mcp_logs_mcp_gateway` is strictly typed (we don't have visibility into this — please confirm)

---

## 10. Appendix A — Before / after on the MIMO call

### Before

```text
caller: skills_find_skills("net MIMO last month")
response: {
  "skills": [
    {
      "id": "domain-payments",
      "score": 0.61,
      "description": "Routes inside the Payments super-domain ... 3000 chars ...",
      "body_markdown": "# Payments super-domain\n\n... 225 lines ...",
      "unity_catalog_assets": [...],
      "triggers": ["deposit", "mimo", ...],
      "sample_questions": [...]
    }
  ]
}
```

Agent reads hub body. The phrase "default to mimo-panel-and-ddr FIRST" appears at line 47 of the body but is also a hub-only routing instruction with no enforcement. Agent ignores it. Writes naive SQL.

### After

```text
caller: skills_find_skills("net MIMO last month")
response: {
  "skills": [
    {
      "id": "domain-payments",
      "score": 0.61,
      "match_quality_hint": "above_floor",
      "description": "Routes inside the Payments super-domain ...",
      "body_markdown": "# Payments super-domain\n\nNavigation map ...",  # now thinner
      "unity_catalog_assets": [],
      "matched_sub_skills": [
        {
          "id": "mimo-panel-and-ddr",
          "score": 0.78,
          "match_quality_hint": "above_floor",
          "description": "Cross-platform Money-In / Money-Out panel and DDR ...",
          "body_markdown": "# MIMO Panel and DDR\n\n... full sub-skill body ...",
          "unity_catalog_assets": [
            "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms",
            ...
          ],
          "sample_questions": ["net MIMO last month", ...],
          "triggers": ["net mimo", "net deposits", ...],
          "example_sql": "SELECT ..."
        }
      ]
    }
  ],
  "filtered_count": 0,
  "advisory": "..."
}
```

Agent now has BOTH the hub context (cross-cutting payments warnings) AND the specific MIMO sub-skill (with the canonical net-deposits definition and the right table). No routing instruction text required. The matched sub-skill arrives via the tool, not via prose.

---

## 11. Appendix B — Affected file inventory

### New files in `databricks/skills-mcp/databricks-skills-mcp/`

- (none — all changes are extensions to existing files)

### Modified files in `databricks/skills-mcp/databricks-skills-mcp/`

- `server/schema.py` — add `SubSkill` model, add `sub_skills` field on `Skill`, add validators
- `server/loader.py` — add `_resolve_sub_skill_body`, integrate into `load_skills`, add cross-corpus uniqueness pass
- `server/index.py` — add `IndexRow`, refactor `build` / `search`, add `search_hubs` and `search_sub_skills_under`
- `server/tools.py` — add second-pass loop in `find_skills`, add sub-skill lookup in `get_skill`, update tool docstrings (which become the LLM-facing tool descriptions)
- `server/settings.py` — add `SKILLS_SUB_PASS_ENABLED`, `SKILLS_SUB_K_DEFAULT`, `SKILLS_SUB_MIN_SCORE`

### Modified files in `databricks/skills-mcp/databricks-mcp-gateway/`

- `server/middleware.py::AuditMiddleware` — extract sub-skill audit fields from `skills_find_skills` results

### Modified files in `databricks/data-skills/`

- `scripts/validate_skills.py` — mirror the schema additions so CI catches authoring errors before they reach the MCP runtime

### Test additions

- `databricks-skills-mcp/tests/test_schema.py` — SubSkill validators
- `databricks-skills-mcp/tests/test_loader.py` — body_source resolution, frontmatter merge, uniqueness errors
- `databricks-skills-mcp/tests/test_index.py` — hub-only search, child-only search
- `databricks-skills-mcp/tests/test_tools.py` — two-pass routing, sub_k variations, get_skill on sub-skill id
- `databricks-skills-mcp/tests/test_smoke.py` — MIMO regression test
- `databricks-mcp-gateway/tests/test_middleware.py` — audit field assertions

---

## 12. References

- MIMO failure transcript (production, 2026-05-25) — available on request
- MCP designer's three-option analysis in the broader skills routing discussion
- Skills MCP `dev` branch at commit `e03fed49b` (2026-05-26)
- Loader implementation on `feature/DEI-3745_adjust_the_mcp_skill_tools_to_work_with_the_new_hierarchy`
- v6.1 labelling floor / audit fields commit `c3858d7a2` (Eliezer Zeiger, 2026-05-25)
- Internal: `c:\Users\guyman\.cursor\plans\deterministic_skill_routing_183c75f1.plan.md`

---

## 13. Sign-off block

| Role | Name | Status |
|---|---|---|
| Author (corpus) | — | — |
| Reviewer (skills-mcp owner) | — | — |
| Reviewer (gateway owner) | — | — |
| Reviewer (data-skills CI owner) | — | — |
| Approved for Phase 1 | — | — |
