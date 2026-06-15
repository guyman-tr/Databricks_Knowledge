"""Validate the data-skills corpus (YAML + SKILL.md formats).

Reused by:
- The GitHub Actions CI in this repo (run on every PR touching `skills/`).
- The Skills MCP loader (`databricks-skills-mcp/server/loader.py`) at startup
  and on `/admin/refresh`. The MCP loader carries a *deliberate copy* of the
  pydantic model below to avoid a build-time path dependency on this repo;
  keep the two in sync.

Two on-disk formats are supported and both produce the same canonical
:class:`Skill`:

1. **Pure YAML** (``*.yaml`` / ``*.yml``) Γאפ concise, one analytical question
   per file. All structured fields live in the YAML mapping. Best for
   parameterised query templates like ``sales-pipeline-by-region.yaml``.

2. **SKILL.md** (``*.md`` with ``---`` YAML frontmatter) Γאפ frontmatter
   carries structured fields (``version``, ``owner``, ``description``,
   ``required_tables``, ``triggers``, ``name``); the markdown body becomes
   ``body_markdown``. Best for canonical business glossaries (multi-section
   reference docs that the LLM grounds against). Frontmatter accepts
   ``required_tables`` as an alias for ``unity_catalog_assets`` to match
   the Anthropic/Cursor "agent skills" convention.

Skill identity Γאפ the canonical slug used for deduplication, embedding keys,
and MCP routing Γאפ is derived entirely from the **on-disk stem**:

* Folder layout  ``skills/<stem>/SKILL.md``  Γזע  stem = directory name
* Flat layout    ``skills/<stem>.md``          Γזע  stem = filename without extension

The ``id`` field is **no longer used**. Any ``id:`` key present in existing
frontmatter is silently ignored during validation (Pydantic drops unknown
fields).  Authors should omit ``id`` from new skills and remove it
incrementally from legacy files.

The validator deliberately *warns* (not errors) when sqlglot cannot fully
resolve a column reference back to a documented ``column_notes`` entry:
keeping authors moving while still surfacing drift is more valuable than a
hard fail at the rare false-positive cost.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from datetime import date
from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel, Field, ValidationError, field_validator, model_validator

try:
    import sqlglot
    from sqlglot import expressions as sqlglot_exp
except ImportError:  # pragma: no cover - optional, validator falls back to a regex
    sqlglot = None
    sqlglot_exp = None


STEM_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
UC_ASSET_PATTERN = re.compile(r"^[a-z0-9_]+\.[a-z0-9_]+\.[a-z0-9_]+$")


class Skill(BaseModel):
    """Pydantic model for one skill (YAML or SKILL.md).

    The model is the source of truth Γאפ ``schema/skill_schema.md`` is its
    mirror, and ``databricks-skills-mcp/server/schema.py`` carries a
    deliberate copy.

    The skill's canonical identity (slug) is derived from the on-disk stem Γאפ
    the directory name for folder-layout skills, or the filename stem for
    flat-layout skills.  There is no ``id`` field; identity is never
    duplicated in the frontmatter.

    Required fields (every skill, both formats):
        ``version``, ``owner``, ``description``, ``unity_catalog_assets``.

    At least one of ``example_sql`` or ``body_markdown`` must be present so
    the LLM always has *some* concrete grounding to copy-paste-adapt.

    Other structured fields are optional: a SKILL.md skill typically
    expresses column gotchas, joins, and filters as prose inside
    ``body_markdown`` rather than as the structured ``column_notes`` /
    ``join_hints`` / ``common_filters`` lists used by short YAML skills.
    """

    model_config = {"extra": "ignore"}

    version: int = Field(ge=1)
    owner: str
    description: str = Field(min_length=10)
    unity_catalog_assets: list[str] = Field(default_factory=list)

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

    # Child topics resolved by ``_resolve_sub_skills`` from sibling
    # ``.md`` files listed in the hub's frontmatter. Empty by default Γאפ
    # only hubs with an explicit ``sub_skills: [...]`` declaration get
    # children attached. See :class:`SubSkill` below and the
    # corresponding section in the Skills MCP for runtime behaviour.
    # The forward reference resolves via ``Skill.model_rebuild()`` at
    # module end.
    sub_skills: list[SubSkill] = Field(default_factory=list)

    genie_space_id: str | None = None

    @field_validator("unity_catalog_assets")
    @classmethod
    def _check_assets(cls, v: list[str]) -> list[str]:
        for asset in v:
            if not UC_ASSET_PATTERN.fullmatch(asset):
                raise ValueError(
                    f"unity_catalog_assets entry {asset!r} must match three-level "
                    f"UC name pattern {UC_ASSET_PATTERN.pattern}"
                )
        return v

    @field_validator("example_sql")
    @classmethod
    def _check_example_sql_length(cls, v: str | None) -> str | None:
        if v is None:
            return None
        if len(v.strip()) < 10:
            raise ValueError(
                f"example_sql must be at least 10 chars when set, got {len(v.strip())}"
            )
        return v

    @field_validator("body_markdown")
    @classmethod
    def _normalise_body(cls, v: str | None) -> str | None:
        if v is None:
            return None
        stripped = v.strip()
        if not stripped:
            return None
        if len(stripped) < 50:
            raise ValueError(
                "body_markdown must be at least 50 chars when set "
                "(empty / near-empty bodies should be omitted entirely)"
            )
        return stripped

    @field_validator("genie_space_id")
    @classmethod
    def _reject_genie_for_now(cls, v: str | None) -> str | None:
        if v is not None:
            raise ValueError(
                "genie_space_id is reserved for v2; remove it and use "
                "unity_catalog_assets for the MVP/v1 path"
            )
        return v

    @model_validator(mode="after")
    def _check_column_notes_keys(self) -> Skill:
        unknown = set(self.column_notes) - set(self.unity_catalog_assets)
        if unknown:
            raise ValueError(
                "column_notes references assets not present in unity_catalog_assets: "
                f"{sorted(unknown)}"
            )
        return self

    @model_validator(mode="after")
    def _check_grounding_present(self) -> Skill:
        # Every skill must give the LLM at least one concrete artefact to
        # ground against Γאפ either a structured example_sql or a markdown
        # body. A skill that has neither is just a list of asset names with
        # no business logic attached, which the LLM cannot use safely.
        if not self.example_sql and not self.body_markdown:
            raise ValueError(
                "skill must have either `example_sql` (structured) or "
                "`body_markdown` (prose body, typically from a SKILL.md "
                "file) so the LLM has a grounded artefact to start from"
            )
        return self

    def embedding_text(self) -> str:
        """Build the text fed into the embedding endpoint.

        Order matters: description first (anchored intent), then a truncated
        body excerpt (rich context for SKILL.md skills), then triggers /
        sample questions / domain tags (recall boosters). The first ~200
        tokens are weighted most heavily by GTE/BGE-class encoders, so the
        most semantically loaded fragment goes first.
        """
        parts: list[str] = [self.description.strip()]
        if self.body_markdown:
            # Truncate well within the 512-token input limit of
            # databricks-gte-large-en. ~1500 chars Γיט 350-400 tokens which
            # leaves headroom for the rest of the signal.
            parts.append(self.body_markdown[:1500].strip())
        if self.triggers:
            parts.append(" ".join(self.triggers))
        if self.sample_questions:
            parts.append("\n".join(self.sample_questions))
        if self.domain_tags:
            parts.append(" ".join(self.domain_tags))
        return "\n\n".join(p for p in parts if p)


class SubSkill(BaseModel):
    """One child topic under a hub :class:`Skill`.

    Each :class:`SubSkill` is a free-standing ``.md`` file sitting next
    to the hub's ``SKILL.md`` and listed explicitly in the hub's
    ``sub_skills:`` frontmatter. The CI validates them inline with the
    hub so authoring errors fail at PR time rather than at MCP boot.

    The model mirrors the one in ``databricks-skills-mcp/server/schema.py``
    Γאפ keep the two in sync (same pattern, same intent as the :class:`Skill`
    mirror above).

    Identity (``id``) is the on-disk filename stem of the sub-skill's
    ``.md`` file. The CI injects it during ``_resolve_sub_skills`` Γאפ
    authors do not write it in frontmatter. ``model_config = {"extra":
    "ignore"}`` drops any legacy ``id:`` line for the same reason as
    :class:`Skill`.

    Hub-only fields deliberately omitted:

    * ``version`` Γאפ sub-skills inherit the hub's recompute lifecycle.
    * ``owner`` Γאפ inherited from the hub.
    * ``domain_tags`` Γאפ domain tags are a hub-level routing concept.
    * ``genie_space_id`` Γאפ reserved for v2 (matches :class:`Skill`).
    * ``last_validated_at`` Γאפ inherited from the hub.
    """

    model_config = {"extra": "ignore"}

    id: str
    description: str = Field(min_length=10)
    triggers: list[str] = Field(default_factory=list)
    sample_questions: list[str] = Field(default_factory=list)
    unity_catalog_assets: list[str] = Field(default_factory=list)
    column_notes: dict[str, dict[str, str]] = Field(default_factory=dict)
    join_hints: list[str] = Field(default_factory=list)
    common_filters: list[str] = Field(default_factory=list)
    example_sql: str | None = None
    body_markdown: str | None = None

    @field_validator("unity_catalog_assets")
    @classmethod
    def _check_assets(cls, v: list[str]) -> list[str]:
        for asset in v:
            if not UC_ASSET_PATTERN.fullmatch(asset):
                raise ValueError(
                    f"sub_skill unity_catalog_assets entry {asset!r} must "
                    f"match three-level UC name pattern {UC_ASSET_PATTERN.pattern}"
                )
        return v

    @field_validator("example_sql")
    @classmethod
    def _check_example_sql_length(cls, v: str | None) -> str | None:
        if v is None:
            return None
        if len(v.strip()) < 10:
            raise ValueError(
                f"sub_skill example_sql must be at least 10 chars when set, "
                f"got {len(v.strip())}"
            )
        return v

    @field_validator("body_markdown")
    @classmethod
    def _normalise_body(cls, v: str | None) -> str | None:
        if v is None:
            return None
        stripped = v.strip()
        if not stripped:
            return None
        if len(stripped) < 50:
            raise ValueError(
                "sub_skill body_markdown must be at least 50 chars when set "
                "(empty / near-empty bodies should be omitted entirely)"
            )
        return stripped

    @model_validator(mode="after")
    def _check_column_notes_keys(self) -> SubSkill:
        unknown = set(self.column_notes) - set(self.unity_catalog_assets)
        if unknown:
            raise ValueError(
                "sub_skill column_notes references assets not present in "
                f"unity_catalog_assets: {sorted(unknown)}"
            )
        return self

    @model_validator(mode="after")
    def _check_grounding_present(self) -> SubSkill:
        if not self.example_sql and not self.body_markdown:
            raise ValueError(
                "sub_skill must have either `example_sql` or "
                "`body_markdown` so the LLM has a grounded artefact"
            )
        return self

    def embedding_text(self) -> str:
        """Same composition order as :meth:`Skill.embedding_text`.

        Maintains hub-vs-child cosine comparability for the MCP's
        second-pass scoring step (see ``server.tools.find_skills``).
        ``domain_tags`` is intentionally absent Γאפ domain tags live on
        the hub.
        """
        parts: list[str] = [self.description.strip()]
        if self.body_markdown:
            parts.append(self.body_markdown[:1500].strip())
        if self.triggers:
            parts.append(" ".join(self.triggers))
        if self.sample_questions:
            parts.append("\n".join(self.sample_questions))
        return "\n\n".join(p for p in parts if p)


# Resolve the ``sub_skills: list[SubSkill]`` forward reference on
# :class:`Skill`. Same rationale as the MCP-side mirror Γאפ declare hub
# first so the docstrings read top-down, then wire the relationship.
Skill.model_rebuild()


def _columns_referenced_in_sql(sql: str) -> set[str]:
    """Best-effort extraction of bare column names from `example_sql`.

    Returns a set of column names. We intentionally do *not* try to resolve
    table aliases Γאפ keeping the rule simple ("every column name appearing in
    the SQL must be documented in *some* table's column_notes") gets us 95%
    of the value of full schema resolution at 5% of the implementation cost.
    """
    if sqlglot is None:
        # Conservative fallback: word-tokens that look like identifiers and
        # weren't SQL keywords. Good enough to catch obvious typos.
        keywords = {
            "select", "from", "where", "group", "by", "order", "having",
            "join", "on", "as", "and", "or", "not", "in", "is", "null",
            "asc", "desc", "limit", "case", "when", "then", "else", "end",
            "left", "right", "outer", "inner", "full", "cross", "lateral",
            "with", "union", "all", "distinct", "current_date", "date_trunc",
            "sum", "count", "avg", "min", "max",
        }
        tokens = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", sql.lower()))
        return tokens - keywords
    try:
        tree = sqlglot.parse_one(sql, dialect="databricks")
    except Exception:
        return set()
    cols: set[str] = set()
    for column in tree.find_all(sqlglot_exp.Column):
        name = column.name
        if name:
            cols.add(name.lower())
    return cols


def _check_sql_columns(skill: Skill) -> list[str]:
    """Warn if ``example_sql`` references a column not in ``column_notes``.

    Returns a list of human-readable warnings (not errors). Skills without
    an ``example_sql`` (typical for SKILL.md format, where SQL examples
    live in the markdown body) skip this check entirely Γאפ column gotchas
    are documented as prose in those cases and we don't try to parse them.
    """
    if not skill.example_sql:
        return []
    documented: set[str] = set()
    for cols in skill.column_notes.values():
        documented.update(c.lower() for c in cols)
    referenced = _columns_referenced_in_sql(skill.example_sql)

    # Strip out names that look like aliases (single-letter table aliases like `o`,
    # `r`) and very short tokens that are unlikely to be real columns.
    candidates = {c for c in referenced if len(c) > 1}
    undocumented = sorted(c for c in candidates if c not in documented)

    warnings: list[str] = []
    # Heuristic: only flag tokens that look like real column names Γאפ i.e. they
    # appear right after a `.` in the SQL (`o.amount`, `r.region_name`). This
    # halves false positives for aggregate aliases like `weighted_pipeline_usd`.
    qualified = set(re.findall(r"\.([A-Za-z_][A-Za-z0-9_]*)", skill.example_sql.lower()))
    flagged = sorted(set(undocumented) & qualified)
    if flagged:
        warnings.append(
            f"example_sql references columns not documented in column_notes: {flagged}"
        )
    return warnings


def _parse_yaml(path: Path) -> Any:
    with path.open() as f:
        return yaml.safe_load(f)


_FRONTMATTER_FENCE = "---"


def _parse_skill_md(text: str) -> tuple[dict, str, str | None]:
    """Split a SKILL.md file into ``(frontmatter_dict, body_str, fail_reason)``.

    Frontmatter is the YAML mapping between the first two ``---`` fences at
    the very start of the file.

    On success, returns ``(meta_dict, body_str, None)``. On any structural
    failure, returns ``({}, "", reason)`` where ``reason`` is one of:

    - ``"missing_opening_fence"`` Γאפ the file does not start with ``---``.
    - ``"missing_closing_fence"`` Γאפ opening ``---`` found, no matching
      closing fence anywhere in the file.
    - ``"malformed_yaml: <yaml.YAMLError msg>"`` Γאפ frontmatter delimited
      correctly but the YAML body did not parse.
    - ``"frontmatter_not_a_mapping: got <type>"`` Γאפ YAML parsed, but to
      something other than a mapping (a list, scalar, etc.).

    Both Unix and Windows line endings are tolerated, as is a leading BOM.

    The caller (``_read_skill_file``) translates each ``reason`` into a
    tailored, author-facing error.
    """
    s = text.lstrip("\ufeff")
    s = s.replace("\r\n", "\n").replace("\r", "\n")
    if not s.startswith(_FRONTMATTER_FENCE):
        return {}, "", "missing_opening_fence"
    lines = s.split("\n")
    if not lines or lines[0].strip() != _FRONTMATTER_FENCE:
        return {}, "", "missing_opening_fence"
    end_idx: int | None = None
    for i in range(1, len(lines)):
        if lines[i].strip() == _FRONTMATTER_FENCE:
            end_idx = i
            break
    if end_idx is None:
        return {}, "", "missing_closing_fence"
    fm_text = "\n".join(lines[1:end_idx])
    body = "\n".join(lines[end_idx + 1 :]).strip("\n")
    try:
        meta = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        return {}, "", f"malformed_yaml: {e}"
    if meta is None:
        # Empty frontmatter block (`---\n---`) is structurally an empty
        # mapping. Let pydantic enumerate the required fields Γאפ that's
        # the one case where the "let pydantic do it" path is correct.
        meta = {}
    if not isinstance(meta, dict):
        return {}, "", f"frontmatter_not_a_mapping: got {type(meta).__name__}"
    return meta, body, None


def _md_fail_message(reason: str) -> str:
    """Translate a ``_parse_skill_md`` reason code into an author-facing error.

    Mirrors ``databricks-skills-mcp/server/loader._md_fail_message`` Γאפ
    keep the two in sync (same reason codes, same messages).
    """
    if reason == "missing_opening_fence":
        return (
            "SKILL.md must start with a YAML frontmatter block delimited "
            "by `---` fences (no opening `---` found)"
        )
    if reason == "missing_closing_fence":
        return (
            "SKILL.md frontmatter has an opening `---` fence but no "
            "matching closing `---` fence"
        )
    if reason.startswith("malformed_yaml: "):
        detail = reason[len("malformed_yaml: ") :]
        return f"SKILL.md frontmatter YAML is malformed: {detail}"
    if reason.startswith("frontmatter_not_a_mapping: "):
        got = reason[len("frontmatter_not_a_mapping: ") :]
        return (
            "SKILL.md frontmatter must be a YAML mapping with skill "
            f"fields, but parsed to {got}"
        )
    return f"SKILL.md frontmatter is invalid: {reason}"


def _normalise_skill_dict(raw: dict, body: str | None) -> dict:
    """Normalise a parsed skill mapping into the canonical ``Skill`` shape.

    - Accept ``required_tables`` as a frontmatter alias for
      ``unity_catalog_assets`` (the SKILL.md / "agent skills" convention).
    - Inject ``body_markdown`` when a non-empty markdown body was captured.
    - Pass everything else through unchanged so unknown keys still produce
      a clear pydantic error rather than being silently dropped.
    """
    out = dict(raw)
    if "required_tables" in out and "unity_catalog_assets" not in out:
        out["unity_catalog_assets"] = out.pop("required_tables")
    elif "required_tables" in out and "unity_catalog_assets" in out:
        # Both supplied Γאפ that's almost certainly an authoring mistake.
        # Surface it explicitly rather than picking one silently.
        raise ValueError(
            "skill defines both `unity_catalog_assets` and `required_tables`; "
            "use only one (frontmatter prefers `required_tables`, YAML prefers "
            "`unity_catalog_assets`)"
        )
    if body:
        out["body_markdown"] = body
    return out


def _read_skill_file(path: Path) -> tuple[dict | None, str | None, str | None]:
    """Read a skill file, dispatching on extension.

    Returns ``(normalised_dict, body_or_none, error_or_none)``. When an
    error is returned the dict is None and the caller should report it.
    """
    suffix = path.suffix.lower()
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        return None, None, f"could not read file: {e}"

    if suffix in {".yaml", ".yml"}:
        try:
            raw = yaml.safe_load(text)
        except yaml.YAMLError as e:
            return None, None, f"YAML parse error: {e}"
        if raw is None:
            return None, None, "file is empty"
        if not isinstance(raw, dict):
            return None, None, (
                f"top level must be a mapping, got {type(raw).__name__}"
            )
        try:
            return _normalise_skill_dict(raw, body=None), None, None
        except ValueError as e:
            return None, None, str(e)

    if suffix == ".md":
        meta, body, fail_reason = _parse_skill_md(text)
        if fail_reason is not None:
            return None, None, _md_fail_message(fail_reason)
        try:
            return _normalise_skill_dict(meta, body=body or None), body, None
        except ValueError as e:
            return None, None, str(e)

    return None, None, f"unsupported file extension {suffix!r}"


def _skill_name(path: Path) -> str:
    """Return the canonical skill name for a skill file path.

    Folder format  ``skills/revenue-business-logic/SKILL.md``  Γזע  ``revenue-business-logic``
    Flat format    ``skills/revenue-business-logic.md``         Γזע  ``revenue-business-logic``
    """
    if path.stem.upper() == "SKILL":
        return path.parent.name
    return path.stem


# Sub-skill identity is the on-disk filename stem, just like a hub. The
# reserved word ``SKILL`` is excluded because that's the hub
# entry-point's filename; a sibling file called ``SKILL.md`` would
# collide with the hub's slug ambiguously and is rejected to keep the
# convention airtight.
_RESERVED_SUB_STEMS = frozenset({"skill"})


def _resolve_sub_skills(
    hub_path: Path,
    raw_sub_skills: object,
) -> tuple[list[dict], list[str]]:
    """Resolve a hub's ``sub_skills:`` frontmatter list into SubSkill dicts.

    Mirror of ``databricks-skills-mcp/server/loader._resolve_sub_skills``
    Γאפ keep the two in sync. Runs at PR-CI time so authoring errors
    (path traversal, missing file, duplicate stems, etc.) fail the PR
    rather than failing the MCP at boot.

    Returns ``(resolved_dicts, errors)``. ``resolved_dicts`` is suitable
    for ``Skill.model_validate(...)``; pydantic builds the
    :class:`SubSkill` instances from them. ``errors`` is a list of
    human-readable strings Γאפ never raises so the caller can keep
    collecting issues across the rest of the corpus.

    Hard rules (all enforced here, mirrored on the MCP loader side):

    * Sub-skill paths must be **bare filenames** (no ``/``, no ``..``,
      no absolute paths, no parent traversal). Siblings only.
    * Sub-skill files must be ``.md`` for v1.
    * Sub-skill filename stems are kebab-case (``STEM_PATTERN``) and
      must not collide with the reserved ``SKILL`` slug.
    * The child file must have a valid SKILL.md frontmatter.
    """
    errors: list[str] = []
    resolved: list[dict] = []

    if raw_sub_skills is None:
        return resolved, errors
    if not isinstance(raw_sub_skills, list):
        errors.append(
            f"sub_skills must be a list of filename strings, got "
            f"{type(raw_sub_skills).__name__}"
        )
        return resolved, errors

    seen_stems: set[str] = set()
    for entry in raw_sub_skills:
        if not isinstance(entry, str):
            errors.append(
                f"sub_skills entry {entry!r} must be a filename string "
                f"(got {type(entry).__name__})"
            )
            continue

        filename = entry.strip()
        if not filename:
            errors.append("sub_skills entry must not be empty")
            continue

        if (
            "/" in filename
            or "\\" in filename
            or filename.startswith(".")
            or filename in {".", ".."}
        ):
            errors.append(
                f"sub_skills entry {filename!r}: must be a bare filename in "
                f"the hub folder (no path separators, no parent traversal, "
                f"no leading dot)"
            )
            continue

        sub_path = hub_path.parent / filename
        if sub_path.suffix.lower() != ".md":
            errors.append(
                f"sub_skills entry {filename!r}: must be a `.md` file "
                f"(YAML sub-skills are not supported in v1)"
            )
            continue
        if not sub_path.is_file():
            errors.append(
                f"sub_skills entry {filename!r}: file does not exist next "
                f"to hub at {sub_path}"
            )
            continue

        sub_stem = sub_path.stem
        if sub_stem.lower() in _RESERVED_SUB_STEMS:
            errors.append(
                f"sub_skills entry {filename!r}: filename stem "
                f"{sub_stem!r} is reserved (collides with the hub entry-point name)"
            )
            continue
        if not STEM_PATTERN.fullmatch(sub_stem):
            errors.append(
                f"sub_skills entry {filename!r}: stem {sub_stem!r} must be "
                f"kebab-case (pattern: {STEM_PATTERN.pattern})"
            )
            continue
        if sub_stem in seen_stems:
            errors.append(
                f"sub_skills entry {filename!r}: duplicate sub-skill stem "
                f"{sub_stem!r} within the same hub"
            )
            continue
        seen_stems.add(sub_stem)

        try:
            text = sub_path.read_text(encoding="utf-8")
        except OSError as e:
            errors.append(f"sub_skills entry {filename!r}: could not read file: {e}")
            continue

        meta, body, fail_reason = _parse_skill_md(text)
        if fail_reason is not None:
            errors.append(
                f"sub_skills entry {filename!r}: {_md_fail_message(fail_reason)}"
            )
            continue

        try:
            normalised = _normalise_skill_dict(meta, body=body or None)
        except ValueError as e:
            errors.append(f"sub_skills entry {filename!r}: {e}")
            continue

        # Inject the sub-skill stem as ``id``. ``extra="ignore"`` on
        # :class:`SubSkill` drops any legacy ``id:`` line that survived
        # in the dict, and this explicit assignment makes the filename
        # the single source of truth.
        normalised["id"] = sub_stem
        resolved.append(normalised)

    return resolved, errors


def validate_file(path: Path) -> tuple[Skill | None, list[str], list[str]]:
    """Validate one skill file (YAML or SKILL.md).

    Returns ``(skill_or_none, errors, warnings)``.

    The skill's canonical identity (slug) is the on-disk stem derived by
    ``_skill_name(path)``.  The stem must be valid kebab-case; no ``id``
    field in the frontmatter is required or checked.
    """
    errors: list[str] = []
    warnings: list[str] = []

    stem = _skill_name(path)
    if not STEM_PATTERN.fullmatch(stem):
        errors.append(
            f"directory/filename stem {stem!r} must be kebab-case "
            f"(pattern: {STEM_PATTERN.pattern})"
        )

    raw, _body, read_err = _read_skill_file(path)
    if read_err is not None:
        errors.append(read_err)
        return None, errors, warnings
    assert raw is not None  # for type-checkers

    # Resolve any ``sub_skills:`` declaration into pre-validated dicts
    # so pydantic builds the children when it validates the hub. The
    # data-skills CI ALWAYS validates sub-skills strictly Γאפ there is
    # no kill switch here. The MCP runtime kill switch
    # (``SKILLS_SUB_PASS_ENABLED``) is an independent operational
    # rollback knob; it must not bypass authoring validation.
    raw_subs = raw.pop("sub_skills", None)
    if raw_subs is not None:
        resolved_subs, sub_errors = _resolve_sub_skills(path, raw_subs)
        errors.extend(sub_errors)
        if sub_errors:
            return None, errors, warnings
        if resolved_subs:
            raw["sub_skills"] = resolved_subs

    try:
        skill = Skill.model_validate(raw)
    except ValidationError as e:
        for err in e.errors():
            loc = ".".join(str(p) for p in err["loc"])
            errors.append(f"{loc}: {err['msg']}")
        return None, errors, warnings

    if sqlglot is not None and skill.example_sql:
        try:
            sqlglot.parse_one(skill.example_sql, dialect="databricks")
        except Exception as e:
            errors.append(f"example_sql failed to parse with sqlglot: {e}")

    warnings.extend(_check_sql_columns(skill))

    return skill, errors, warnings


def validate_dir(skills_dir: Path) -> tuple[list[Skill], list[str], list[str]]:
    """Validate all skill entry-point files under ``skills_dir``.

    Supports two layouts:

    * **Flat** (legacy) Γאפ ``skills/*.yaml``, ``skills/*.yml``, ``skills/*.md``
    * **Folder** (new) Γאפ ``skills/<name>/SKILL.yaml`` / ``skills/<name>/SKILL.md``
      (only the ``SKILL.*`` entry point is validated; supplementary files such as
      ``reference.md`` and ``examples.md`` are intentionally ignored).
    """
    flat_files = (
        sorted(f for f in skills_dir.glob("*.yaml") if f.is_file())
        + sorted(f for f in skills_dir.glob("*.yml") if f.is_file())
        + sorted(f for f in skills_dir.glob("*.md") if f.is_file())
    )
    folder_files = (
        sorted(skills_dir.glob("*/SKILL.yaml"))
        + sorted(skills_dir.glob("*/SKILL.yml"))
        + sorted(skills_dir.glob("*/SKILL.md"))
    )
    files = flat_files + folder_files
    skills: list[Skill] = []
    stems: list[str] = []  # parallel list: stem for each successfully parsed skill
    all_errors: list[str] = []
    all_warnings: list[str] = []

    for path in files:
        skill, errors, warnings = validate_file(path)
        rel = path.relative_to(skills_dir)
        for err in errors:
            all_errors.append(f"{rel}: {err}")
        for warn in warnings:
            all_warnings.append(f"{rel}: {warn}")
        if skill is not None:
            skills.append(skill)
            stems.append(_skill_name(path))
            # Sub-skill stems share the hub keyspace because
            # ``get_skill`` resolves either by slug Γאפ track them in
            # the same parallel list so the duplicate check below
            # catches hub-vs-child and child-vs-child collisions in
            # one pass.
            for sub in skill.sub_skills:
                stems.append(sub.id)

    stem_counts = Counter(stems)
    duplicates = sorted(s for s, c in stem_counts.items() if c > 1)
    for dup in duplicates:
        all_errors.append(
            f"duplicate stem across corpus (hub + sub-skill union): {dup!r}"
        )

    return skills, all_errors, all_warnings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "skills_dir",
        type=Path,
        nargs="?",
        default=Path("skills"),
        help="Directory containing skill YAMLs (default: ./skills)",
    )
    parser.add_argument(
        "--strict-warnings",
        action="store_true",
        help="Treat warnings as errors (used by the nightly drift job).",
    )
    args = parser.parse_args(argv)

    if not args.skills_dir.is_dir():
        print(f"error: {args.skills_dir} is not a directory", file=sys.stderr)
        return 2

    skills, errors, warnings = validate_dir(args.skills_dir)

    for warn in warnings:
        print(f"WARN  {warn}", file=sys.stderr)
    for err in errors:
        print(f"ERROR {err}", file=sys.stderr)

    print(
        f"validated {len(skills)} skill(s), "
        f"{len(errors)} error(s), {len(warnings)} warning(s)",
        file=sys.stderr,
    )

    if errors:
        return 1
    if args.strict_warnings and warnings:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
