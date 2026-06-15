"""Strongly-typed, validated case schema.

A case YAML is the contract between the authoring side (Cursor + Synapse) and
the runtime side (Databricks notebook). The harness must reject malformed YAML
loudly rather than silently mis-scoring.

Schema version 1 — matches the 15 DDR cases authored on 2026-06-11.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class GroundTruth:
    source_db: str          # 'synapse_prod' (only one supported in v1)
    routine: str            # e.g. 'BI_DB_dbo.Function_DDR_Aggregation_Yesterday'
    sql: str                # the literal Synapse SQL used to pin the value
    value: float            # the pinned scalar
    pinned_at: str          # ISO-8601 UTC timestamp
    notes: str | None = None

    @classmethod
    def from_dict(cls, d: dict) -> "GroundTruth":
        return cls(
            source_db=str(d["source_db"]),
            routine=str(d["routine"]),
            sql=str(d["sql"]),
            value=float(d["value"]),
            pinned_at=str(d["pinned_at"]),
            notes=d.get("notes"),
        )


@dataclass
class UcEquivalent:
    status: str             # 'live' / 'draft' / 'broken'
    sql: str
    value: float
    pinned_at: str

    @classmethod
    def from_dict(cls, d: dict) -> "UcEquivalent":
        return cls(
            status=str(d["status"]),
            sql=str(d["sql"]),
            value=float(d["value"]),
            pinned_at=str(d["pinned_at"]),
        )


@dataclass
class Parity:
    diff_abs: float
    diff_pct: float
    threshold_pct: float
    passed: bool
    finding: str | None = None

    @classmethod
    def from_dict(cls, d: dict) -> "Parity":
        return cls(
            diff_abs=float(d["diff_abs"]),
            diff_pct=float(d["diff_pct"]),
            threshold_pct=float(d["threshold_pct"]),
            passed=bool(d["passed"]),
            finding=d.get("finding"),
        )


@dataclass
class SkillCoverage:
    matched_skills: list[str] = field(default_factory=list)
    contract_used: str | None = None
    fqns_referenced: list[str] = field(default_factory=list)
    expected_coverage_assertion: str | None = None

    @classmethod
    def from_dict(cls, d: dict | None) -> "SkillCoverage":
        if not d:
            return cls()
        return cls(
            matched_skills=list(d.get("matched_skills") or []),
            contract_used=d.get("contract_used"),
            fqns_referenced=list(d.get("fqns_referenced") or []),
            expected_coverage_assertion=d.get("expected_coverage_assertion"),
        )


@dataclass
class ScoringConfig:
    numeric_tolerance_pct: float = 0.5
    parity_diff_pct_threshold: float = 0.05
    judge_signal_secondary: str | None = None  # 'llm' | None

    @classmethod
    def from_dict(cls, d: dict | None) -> "ScoringConfig":
        if not d:
            return cls()
        return cls(
            numeric_tolerance_pct=float(d.get("numeric_tolerance_pct", 0.5)),
            parity_diff_pct_threshold=float(d.get("parity_diff_pct_threshold", 0.05)),
            judge_signal_secondary=d.get("judge_signal_secondary"),
        )


@dataclass
class CaseV1:
    case_id: str
    status: str                 # 'live' | 'draft' | 'disabled'
    source_kind: str            # 'tableau' | 'genie_baseline' | 'manual'
    asof: str                   # 'YYYY-MM-DD'
    natural_language_question: str
    ground_truth: GroundTruth
    uc_equivalent: UcEquivalent
    parity: Parity
    skill_coverage: SkillCoverage
    scoring: ScoringConfig
    tags: list[str] = field(default_factory=list)
    provenance: dict[str, Any] = field(default_factory=dict)
    schema_version: int = 1

    @classmethod
    def from_dict(cls, d: dict, *, source_path: str | None = None) -> "CaseV1":
        try:
            return cls(
                case_id=str(d["id"]),
                status=str(d.get("status", "live")),
                source_kind=str(d.get("source_kind", "manual")),
                asof=str(d["asof"]),
                natural_language_question=str(d["natural_language_question"]).strip(),
                ground_truth=GroundTruth.from_dict(d["ground_truth"]),
                uc_equivalent=UcEquivalent.from_dict(d["uc_equivalent"]),
                parity=Parity.from_dict(d["parity"]),
                skill_coverage=SkillCoverage.from_dict(d.get("skill_coverage")),
                scoring=ScoringConfig.from_dict(d.get("scoring")),
                tags=list(d.get("tags") or []),
                provenance=dict(d.get("provenance") or {}),
                schema_version=int(d.get("schema_version", 1)),
            )
        except KeyError as e:
            where = f" (in {source_path})" if source_path else ""
            raise ValueError(f"Case missing required field {e}{where}") from e
        except (TypeError, ValueError) as e:
            where = f" (in {source_path})" if source_path else ""
            raise ValueError(f"Case malformed{where}: {e}") from e

    def is_live(self) -> bool:
        return self.status == "live"

    def is_numeric(self) -> bool:
        """Numeric scoring path applies. v1: every case is numeric."""
        return True
