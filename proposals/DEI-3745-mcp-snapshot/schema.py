"""Skill schema (mirror of ``data-skills/scripts/validate_skills.py``).

This file is a *deliberate copy* of the canonical pydantic model so the Skills
MCP doesn't need a build-time path dependency on the ``data-skills`` repo.

Keep it in sync. The CI in ``data-skills`` validates incoming PRs against the
canonical model; this copy only loads files that already passed that gate.

Two on-disk skill formats are supported and both produce the same canonical
:class:`Skill`:

1. **Pure YAML** (``*.yaml``) Γאפ concise, one analytical question per file.
2. **SKILL.md** (``*.md`` with ``---`` YAML frontmatter) Γאפ frontmatter
   carries structured fields; the markdown body becomes ``body_markdown``.

Skill identity Γאפ the canonical slug used for deduplication, embedding keys,
and MCP routing Γאפ is derived entirely from the on-disk stem:

* Folder layout  ``skills/<stem>/SKILL.md``  Γזע  stem = directory name
* Flat layout    ``skills/<stem>.md``        Γזע  stem = filename without ext

The ``id`` field is **no longer a frontmatter input**. Authors must omit
``id:`` from new skills; legacy ``id:`` lines in existing files are silently
ignored (``extra="ignore"`` drops the unknown key, and the loader overwrites
``id`` from the path stem before pydantic validation either way).

Divergence from the canonical: the canonical model in ``data-skills`` drops
the ``id`` field entirely. This MCP keeps ``id`` as an in-memory attribute
because :mod:`server.tools`, :mod:`server.acl`, and the gateway audit row
read it on every call. The loader sets it from the path stem; downstream
code is unaware of the convention change.
"""

from __future__ import annotations

import re
from datetime import date

from pydantic import BaseModel, Field, field_validator, model_validator

STEM_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
UC_ASSET_PATTERN = re.compile(r"^[a-z0-9_]+\.[a-z0-9_]+\.[a-z0-9_]+$")


class Skill(BaseModel):
    """One curated data skill. See ``data-skills/schema/skill_schema.md``.

    Required for every skill: ``version``, ``owner``, ``description``,
    ``unity_catalog_assets``, plus at least one of ``example_sql`` or
    ``body_markdown`` so the LLM always has a concrete grounded artefact.

    ``id`` is **loader-injected** from the on-disk stem; it is not an
    authoring field. See the module docstring for the divergence note vs
    the canonical data-skills model.
    """

    # ``extra="ignore"`` silently drops legacy ``id:`` lines (and any other
    # unknown frontmatter key) so existing skills load cleanly during the
    # corpus migration to stem-based identity. The loader still sets
    # ``id`` itself from the path stem; pydantic's last-writer-wins
    # semantics in ``model_validate`` mean the path always wins over any
    # ``id`` value that survived the dict.
    model_config = {"extra": "ignore"}

    id: str
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

    # Child topics resolved by the loader from sibling ``.md`` files in
    # the hub's folder (folder layout only). Empty by default Γאפ a Skill
    # without children is the v0 shape and is preserved byte-for-byte
    # by :mod:`server.tools` when ``SKILLS_SUB_PASS_ENABLED`` is off.
    # See :class:`SubSkill` below for the child contract; forward
    # reference resolved by ``Skill.model_rebuild()`` at module end.
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
            # ~1500 chars Γיט 350-400 tokens; well under the 512-token input
            # limit of databricks-gte-large-en, leaving headroom for the
            # rest of the signal.
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

    Each :class:`SubSkill` is a free-standing ``.md`` file sitting as a
    sibling of the hub's ``SKILL.md`` inside the hub's folder, e.g.
    ``skills/domain-payments/mimo-panel-and-ddr.md``. The hub's
    frontmatter must list it explicitly in ``sub_skills:`` for the
    loader to pick it up Γאפ sibling files that are not listed are
    silently ignored (the same "supplementary reference content"
    treatment they get today). Auto-discovery is intentionally NOT
    implemented; ``sub_skills:`` is the opt-in signal.

    The model mirrors :class:`Skill`'s "structured fields plus body"
    shape minus the hub-level concepts that don't apply to a child:

    - No ``version`` Γאפ sub-skills inherit the hub's recompute lifecycle.
      When a sub-skill body changes, the author bumps the hub's
      ``version`` to trigger embedding-recomputation.
    - No ``owner`` Γאפ inherited from the hub.
    - No ``domain_tags`` Γאפ domain tags are a hub-level routing concept
      used by the existing ``domain_tag`` pre-filter on ``find_skills``;
      sub-skills are reached via the hub-first second pass, so a
      separate per-child tag would be redundant.
    - No ``genie_space_id`` Γאפ out of scope for v1 (matches :class:`Skill`).
    - No ``last_validated_at`` Γאפ inherited from the hub.

    Identity (``id``) is the on-disk filename stem of the sub-skill's
    ``.md`` file (e.g. ``mimo-panel-and-ddr.md`` Γזע
    ``mimo-panel-and-ddr``). The loader injects it; ``model_config =
    {"extra": "ignore"}`` drops any frontmatter ``id:`` line for the
    same reason it does on :class:`Skill`.
    """

    # Same authoring rule as :class:`Skill` Γאפ ``id:`` is path-derived,
    # never a frontmatter input.
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
        # Same rule as :class:`Skill`: every sub-skill must give the LLM
        # at least one concrete artefact to ground against. A child
        # entry that is just a description and triggers has no
        # adaptable SQL or prose body and is unsafe to surface.
        if not self.example_sql and not self.body_markdown:
            raise ValueError(
                "sub_skill must have either `example_sql` or "
                "`body_markdown` so the LLM has a grounded artefact"
            )
        return self

    def embedding_text(self) -> str:
        """Build the fingerprint fed into the embedding endpoint.

        Same composition order as :meth:`Skill.embedding_text` so the
        hub and child vectors are directly comparable as cosine scores
        in the index Γאפ the second-pass scoring in
        :mod:`server.tools` relies on this comparability when it
        computes ``effective_score = max(hub_score, best_child_score)``.

        ``domain_tags`` is intentionally absent (sub-skills do not
        carry their own; the hub provides domain routing).
        """
        parts: list[str] = [self.description.strip()]
        if self.body_markdown:
            parts.append(self.body_markdown[:1500].strip())
        if self.triggers:
            parts.append(" ".join(self.triggers))
        if self.sample_questions:
            parts.append("\n".join(self.sample_questions))
        return "\n\n".join(p for p in parts if p)


class SkillSummary(BaseModel):
    """Lightweight projection used by ``list_skills``.

    Excludes ``body_markdown``, ``example_sql``, and ``column_notes`` Γאפ
    those can be ~kilobytes per skill and are only needed by callers that
    asked for a specific skill via ``find_skills`` or ``get_skill``.
    """

    id: str
    name: str | None
    description: str
    domain_tags: list[str]
    triggers: list[str]
    last_validated_at: date | None
    unity_catalog_assets: list[str]

    @classmethod
    def from_skill(cls, skill: Skill) -> SkillSummary:
        return cls(
            id=skill.id,
            name=skill.name,
            description=skill.description,
            domain_tags=skill.domain_tags,
            triggers=skill.triggers,
            last_validated_at=skill.last_validated_at,
            unity_catalog_assets=skill.unity_catalog_assets,
        )


# Resolve the ``sub_skills: list[SubSkill]`` forward reference on
# :class:`Skill`. ``SubSkill`` is declared after :class:`Skill` because
# the conceptual reading order is "hub model first, child model
# second" Γאפ pydantic's ``model_rebuild`` is the canonical way to wire
# the two together without flipping the file's narrative.
Skill.model_rebuild()
