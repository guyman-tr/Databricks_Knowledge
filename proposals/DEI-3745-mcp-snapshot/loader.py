"""Load and validate the data-skills corpus from a local checkout.

Used at app startup and on every ``POST /admin/refresh``. The validator's job
is *defence in depth* Γאפ the corpus has already passed CI in the data-skills
repo, but we revalidate at runtime so a malformed file can never reach the
embedding step or the index.

Two on-disk formats are supported, in two layouts:

- Pure YAML (``*.yaml`` / ``*.yml``): the canonical shape, all fields in the
  YAML mapping. Best for short parameterised skills.
- SKILL.md (``*.md``): YAML frontmatter between ``---`` fences plus a
  markdown body that becomes ``Skill.body_markdown``. Best for canonical
  business glossaries.

Layouts:

- **Flat** Γאפ ``skills/<stem>.yaml`` / ``skills/<stem>.md``: the filename
  stem is the canonical skill slug.
- **Folder** Γאפ ``skills/<stem>/SKILL.yaml`` / ``skills/<stem>/SKILL.md``:
  the parent folder name is the canonical skill slug. Only the ``SKILL.*``
  entry-point file is picked up; supplementary files inside the folder
  (e.g. ``PATTERNS.md``, ``PLAYBOOK.md``, ``source-tables.md``) are
  intentionally ignored Γאפ they're reference content next to the skill,
  not skills themselves.

Identity convention (mirrors ``data-skills/scripts/validate_skills.py``):
the path stem is the canonical slug. There is no ``id:`` frontmatter
input Γאפ the loader injects ``id`` from the path before pydantic
validation, and any legacy ``id:`` line in existing files is silently
ignored by :class:`Skill`'s ``extra="ignore"`` config. The path is the
single source of truth.

The discovery and id-derivation logic is deliberately a small copy of
``data-skills/scripts/validate_skills.py`` so the MCP doesn't need a
build-time path dependency on the data-skills repo. Keep them in sync.
"""

from __future__ import annotations

import logging
from collections import Counter
from pathlib import Path

import yaml
from pydantic import ValidationError

from .schema import STEM_PATTERN, Skill

logger = logging.getLogger(__name__)


class SkillLoadError(RuntimeError):
    """Raised when one or more skills fail to validate at runtime."""


# Sub-skill identity is the on-disk filename stem, just like a hub. The
# reserved word ``SKILL`` is excluded because that's the hub
# entry-point's filename; a sibling file called ``SKILL.md`` would
# collide with the hub's slug ambiguously (folder name == file stem
# both resolve to the same key) and is rejected to keep the
# convention airtight.
_RESERVED_SUB_STEMS = frozenset({"skill"})


_FRONTMATTER_FENCE = "---"


def _parse_skill_md(text: str) -> tuple[dict, str, str | None]:
    """Split a SKILL.md file into ``(frontmatter_dict, body_str, fail_reason)``.

    Frontmatter is the YAML mapping between the first two ``---`` fences at
    the very start of the file.

    On success, returns ``(meta_dict, body_str, None)``. On any structural
    failure, returns ``({}, "", reason)`` where ``reason`` is one of:

    - ``"missing_opening_fence"`` Γאפ the file does not start with ``---``.
    - ``"missing_closing_fence"`` Γאפ there is an opening ``---`` but no
      matching closing fence anywhere in the file.
    - ``"malformed_yaml: <yaml.YAMLError msg>"`` Γאפ the frontmatter block
      exists and is delimited correctly, but its YAML body did not parse.
    - ``"frontmatter_not_a_mapping: got <type>"`` Γאפ the YAML parsed, but
      to something other than a mapping (e.g. a list, scalar, ``null``).

    The caller (``_read_skill_file``) translates each ``reason`` into a
    tailored, author-facing error. We keep this contract instead of
    returning ``({}, text)`` and letting pydantic emit five "field
    required" errors per malformed file Γאפ the structural error is what
    the author actually needs to fix.
    """
    s = text.lstrip("\ufeff").replace("\r\n", "\n").replace("\r", "\n")
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
        # Empty frontmatter block (`---\n---`) is structurally a mapping
        # of zero entries; treat it as such and let pydantic enumerate
        # the missing required fields. That's the one case where the
        # original "let pydantic do it" comment was correct.
        meta = {}
    if not isinstance(meta, dict):
        return {}, "", f"frontmatter_not_a_mapping: got {type(meta).__name__}"
    return meta, body, None


def _md_fail_message(reason: str) -> str:
    """Translate a ``_parse_skill_md`` reason code into an author-facing error.

    Kept as a plain switch rather than a dict so the malformed-YAML branch
    can interpolate the upstream parse error verbatim.
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
    # Defensive default: if we ever add a new reason and forget to extend
    # this switch, surface the raw code rather than a generic message so
    # the operator can grep it.
    return f"SKILL.md frontmatter is invalid: {reason}"


def _normalise_skill_dict(raw: dict, body: str | None) -> dict:
    """Map frontmatter aliases onto canonical field names.

    Accepts ``required_tables`` as a frontmatter alias for
    ``unity_catalog_assets`` (the SKILL.md / "agent skills" convention).
    Both being present is an authoring error and is surfaced explicitly.
    """
    out = dict(raw)
    if "required_tables" in out:
        if "unity_catalog_assets" in out:
            raise ValueError(
                "skill defines both `unity_catalog_assets` and "
                "`required_tables`; use only one"
            )
        out["unity_catalog_assets"] = out.pop("required_tables")
    if body:
        out["body_markdown"] = body
    return out


def _skill_name(path: Path) -> str:
    """Return the canonical skill name for a skill file path.

    Mirrors ``data-skills/scripts/validate_skills.py::_skill_name`` Γאפ keep
    in sync.

    Folder format  ``skills/revenue-business-logic/SKILL.md``  Γזע  ``revenue-business-logic``
    Flat format    ``skills/revenue-business-logic.md``        Γזע  ``revenue-business-logic``
    """
    if path.stem.upper() == "SKILL":
        return path.parent.name
    return path.stem


def _resolve_sub_skills(
    hub_path: Path,
    raw_sub_skills: object,
) -> tuple[list[dict], list[str]]:
    """Resolve a hub's ``sub_skills:`` frontmatter list into SubSkill dicts.

    Inputs:
        hub_path: the hub's ``SKILL.{yaml,md}`` path (siblings live next
            to it).
        raw_sub_skills: whatever the hub's frontmatter put under
            ``sub_skills:`` Γאפ expected to be a list of filename strings
            (e.g. ``["mimo-panel-and-ddr.md", "deposits-and-withdrawals.md"]``).
            Anything else is a structural authoring error.

    Returns:
        ``(resolved_dicts, errors)`` where ``resolved_dicts`` is suitable
        for ``Skill.model_validate(...)`` (pydantic builds the
        :class:`SubSkill` instances), and ``errors`` is a list of
        human-readable strings Γאפ never raises so the caller can keep
        collecting issues across the rest of the corpus.

    Hard rules (all enforced here, mirrored on the data-skills CI side):

    * Sub-skill paths must be **bare filenames** (no ``/``, no ``..``,
      no absolute paths, no parent traversal). Siblings only Γאפ the
      file layout discipline keeps the loader sandboxed and matches
      the ┬º8.5 decision in the original proposal.
    * Sub-skill files must be ``.md`` for v1. YAML sub-skills are not
      supported until there's a concrete authoring need.
    * Sub-skill filename stems are kebab-case (``STEM_PATTERN``) and
      must not collide with the reserved ``SKILL`` slug.
    * The child file must have a valid SKILL.md frontmatter Γאפ same
      ``---`` fence contract as the hub.
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

        # Path safety: bare filename only. Reject any separators or
        # parent-traversal tokens so we can't escape the hub folder.
        # ``os.sep`` checks would let through forward slashes on
        # Windows; we explicitly reject both.
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
            text = sub_path.read_text()
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

        # Loader injects ``id`` from the filename stem (same convention
        # as the hub). The schema's ``extra="ignore"`` config drops
        # any legacy ``id:`` line from the frontmatter; the explicit
        # assignment here makes the filename the single source of truth.
        normalised["id"] = sub_stem
        resolved.append(normalised)

    return resolved, errors


def _read_skill_file(path: Path) -> tuple[dict | None, str | None]:
    """Read+parse one skill file. Returns (data_or_none, error_or_none)."""
    suffix = path.suffix.lower()
    try:
        text = path.read_text()
    except OSError as e:
        return None, f"could not read file: {e}"

    if suffix in {".yaml", ".yml"}:
        try:
            raw = yaml.safe_load(text)
        except yaml.YAMLError as e:
            return None, f"YAML parse error: {e}"
        if raw is None:
            return None, "file is empty"
        if not isinstance(raw, dict):
            return None, f"top level must be a mapping, got {type(raw).__name__}"
        try:
            return _normalise_skill_dict(raw, body=None), None
        except ValueError as e:
            return None, str(e)

    if suffix == ".md":
        meta, body, fail_reason = _parse_skill_md(text)
        if fail_reason is not None:
            return None, _md_fail_message(fail_reason)
        try:
            return _normalise_skill_dict(meta, body=body or None), None
        except ValueError as e:
            return None, str(e)

    return None, f"unsupported file extension {suffix!r}"


def load_skills(repo_dir: Path, *, sub_pass_enabled: bool = False) -> list[Skill]:
    """Load every skill file under ``repo_dir/skills/**``.

    Walks ``*.yaml``, ``*.yml``, and ``*.md``. For each file:

    1. Derive the canonical slug from the path stem (folder name for
       ``<stem>/SKILL.*``; filename stem for flat ``<stem>.{yaml,md}``).
    2. Verify the stem matches kebab-case (``STEM_PATTERN``).
    3. Read + parse the file body.
    4. If the hub declares ``sub_skills:`` and ``sub_pass_enabled`` is
       ``True``, resolve each entry as a sibling ``.md`` file via
       :func:`_resolve_sub_skills`. When the switch is off,
       ``sub_skills`` is dropped from the parsed dict Γאפ same silent
       treatment as today's "supplementary reference content" Γאפ so
       toggling the switch is a true zero-corpus rollback.
    5. Inject ``id = stem`` into the parsed mapping; pydantic validates
       the merged dict (hub + resolved children).

    Globally unique stems are then asserted across the **union** of
    hub stems and sub-skill stems Γאפ the two namespaces share a single
    keyspace, since :func:`server.tools.get_skill` resolves either by
    slug. Raises :class:`SkillLoadError` listing every problem at once
    Γאפ the operator gets all the bad files in one error rather than
    discovering them one PR at a time.

    Legacy frontmatter ``id:`` lines in existing skills are silently
    ignored (``extra="ignore"`` on :class:`Skill` / :class:`SubSkill`);
    the path is the only source of identity.
    """
    skills_root = repo_dir / "skills"
    if not skills_root.is_dir():
        raise SkillLoadError(
            f"expected `skills/` directory under {repo_dir} (the data-skills "
            f"repo layout); not found"
        )

    # Mirror data-skills/scripts/validate_skills.py::validate_dir: pick up
    # flat entry-point files at the root of ``skills/`` plus the ``SKILL.*``
    # entry-point inside each ``skills/<skill-id>/`` folder. Anything else
    # under a skill folder (PATTERNS.md, PLAYBOOK.md, source-tables.md, Γאª)
    # is supplementary reference content, not a skill, and is ignored on
    # purpose. Deeper nesting is also intentionally not discovered Γאפ keep
    # the layout flat or one-level-folder, same as the validator.
    flat_files = (
        sorted(f for f in skills_root.glob("*.yaml") if f.is_file())
        + sorted(f for f in skills_root.glob("*.yml") if f.is_file())
        + sorted(f for f in skills_root.glob("*.md") if f.is_file())
    )
    folder_files = (
        sorted(skills_root.glob("*/SKILL.yaml"))
        + sorted(skills_root.glob("*/SKILL.yml"))
        + sorted(skills_root.glob("*/SKILL.md"))
    )
    files = flat_files + folder_files
    skills: list[Skill] = []
    errors: list[str] = []

    for path in files:
        rel = path.relative_to(repo_dir)

        stem = _skill_name(path)
        if not STEM_PATTERN.fullmatch(stem):
            errors.append(
                f"{rel}: directory/filename stem {stem!r} must be kebab-case "
                f"(pattern: {STEM_PATTERN.pattern})"
            )
            continue

        data, read_err = _read_skill_file(path)
        if read_err is not None:
            errors.append(f"{rel}: {read_err}")
            continue
        assert data is not None  # for type-checkers

        # Inject the path-derived stem as ``id``. The schema's
        # ``extra="ignore"`` config drops any legacy ``id:`` line from
        # the frontmatter, and the explicit assignment here makes the
        # path the single source of truth Γאפ there is no scenario in
        # which a frontmatter ``id:`` can disagree with the slug the
        # rest of the system uses.
        data["id"] = stem

        # Sub-skill resolution. When the kill switch is off we simply
        # drop the ``sub_skills`` key Γאפ siblings remain ignored
        # exactly like today's "supplementary reference content" rule,
        # which is the contract that lets ops flip ``SKILLS_SUB_PASS_ENABLED``
        # back to ``false`` as a clean rollback with zero corpus churn.
        if sub_pass_enabled:
            raw_subs = data.pop("sub_skills", None)
            resolved, sub_errors = _resolve_sub_skills(path, raw_subs)
            for err in sub_errors:
                errors.append(f"{rel}: {err}")
            if sub_errors:
                # Skip the hub entirely Γאפ a hub whose sub_skills are
                # partially broken is in an inconsistent state and we
                # don't want to silently surface a half-loaded corpus.
                continue
            if resolved:
                data["sub_skills"] = resolved
        else:
            data.pop("sub_skills", None)

        try:
            skill = Skill.model_validate(data)
        except ValidationError as e:
            for err in e.errors():
                loc = ".".join(str(p) for p in err["loc"])
                errors.append(f"{rel}: {loc}: {err['msg']}")
            continue

        skills.append(skill)

    # Cross-corpus uniqueness on the **union** of hub stems and
    # sub-skill stems. Both namespaces share a single keyspace because
    # :func:`server.tools.get_skill` resolves either by slug Γאפ a child
    # whose stem collides with a hub (or another hub's child) would
    # make ``get_skill`` ambiguous.
    all_stems: list[str] = []
    for s in skills:
        all_stems.append(s.id)
        for sub in s.sub_skills:
            all_stems.append(sub.id)
    counts = Counter(all_stems)
    duplicates = sorted(i for i, c in counts.items() if c > 1)
    for dup in duplicates:
        errors.append(
            f"duplicate stem across corpus (hub + sub-skill union): {dup!r}"
        )

    if errors:
        raise SkillLoadError(
            "skill corpus failed validation:\n  " + "\n  ".join(errors)
        )

    logger.info("loaded %d skill(s) from %s", len(skills), skills_root)
    return skills
