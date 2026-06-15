"""Load and validate case YAMLs from a directory tree.

Usage:
    cases = load_cases('tools/eval_suite/cases')               # whole tree
    cases = load_cases('tools/eval_suite/cases/ddr')           # one subtree
    cases = load_cases('tools/eval_suite/cases', tags=['ddr']) # filter
"""
from __future__ import annotations

import glob
import os

import yaml

from .schema import CaseV1


def _looks_like_v1(d: dict) -> bool:
    """Quick triage: does this YAML have the v1 shape?

    Used to skip files from the legacy seed_cases.py corpus without raising.
    A v1 case needs at minimum these keys; if any are missing, we treat the
    file as 'not for this loader' and skip silently.
    """
    return all(k in d for k in ("id", "natural_language_question", "ground_truth", "uc_equivalent"))


def load_cases(
    root: str,
    *,
    include_drafts: bool = False,
    tags_any: list[str] | None = None,
    case_ids: list[str] | None = None,
    strict: bool = False,
) -> list[CaseV1]:
    """Walk a cases/ directory and return validated CaseV1 objects.

    Args:
        root: Path to cases root or a subdirectory.
        include_drafts: If False (default), drop status != 'live' cases.
        tags_any: If set, keep only cases that match ANY of these tags.
        case_ids: If set, keep only cases whose id is in this list.
        strict: If True, raise on ANY parse failure. If False (default), skip
            files that are clearly NOT v1 cases (legacy schemas, partial drafts)
            and only raise when a v1-shaped file fails its detailed validation.
    """
    if not os.path.isdir(root):
        raise FileNotFoundError(f"cases root does not exist: {root}")

    paths = sorted(glob.glob(os.path.join(root, "**", "*.yaml"), recursive=True))
    cases: list[CaseV1] = []
    errors: list[str] = []
    skipped_non_v1 = 0

    for p in paths:
        try:
            with open(p, "r", encoding="utf-8") as f:
                d = yaml.safe_load(f)
            if not isinstance(d, dict):
                if strict:
                    raise ValueError(f"YAML did not parse to a dict")
                skipped_non_v1 += 1
                continue
            if not _looks_like_v1(d):
                if strict:
                    raise ValueError("missing required v1 keys")
                skipped_non_v1 += 1
                continue
            case = CaseV1.from_dict(d, source_path=p)
        except Exception as e:
            errors.append(f"{p}: {e}")
            continue
        if not include_drafts and not case.is_live():
            continue
        if tags_any and not (set(case.tags) & set(tags_any)):
            continue
        if case_ids and case.case_id not in case_ids:
            continue
        cases.append(case)

    if errors:
        raise ValueError(
            "Failed to load one or more cases:\n  - " + "\n  - ".join(errors)
        )
    if skipped_non_v1 and not strict:
        print(f"  (loader: skipped {skipped_non_v1} non-v1-shaped YAML file(s) under {root})")
    return cases
