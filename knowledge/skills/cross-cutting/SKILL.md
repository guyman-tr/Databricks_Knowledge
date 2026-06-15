---
name: cross-cutting
description: "Hub for cross-cutting contracts and conventions that every domain skill must honour SILENTLY — non-domain-specific rules that apply across the entire skill corpus regardless of which hub is loaded. POLARITY IS DEFAULT-ON across every contract here: the user must explicitly opt OUT to disable any contract — they do NOT opt IN to enable it. Producing the un-contracted answer first and then offering 'let me know if you want the contract-compliant version' inverts the polarity and is a contract violation. Currently houses three contracts: (1) valid-users-filter-contract — DEFAULT-ON omni-filter applied via SCD-2 walk on V_Fact_SnapshotCustomer_FromDateID joined with IsValidCustomer=1 and DateID BETWEEN snap.FromDateID AND snap.ToDateID, with two literal-phrase overrides (CB valid → switch to IsCreditReportValidCB; include non-valids/internals/etorians/test → drop the join). (2) data-latency-and-rollforward — DEFAULT-ON roll-forward for point-in-time / snapshot facts (AUM, balance, equity, NOP, position-PnL-as-balance) when the requested date is missing, partial (FX-null), or behind a known per-platform lag (Apex weekend plateau, Spaceship Super/Voyager source-system gaps, MoneyFarm same-day FX-null). 3-day lookback default, 7-day escalation with explicit staleness warning, NEVER applied to flow facts (deposits, withdrawals, fees, MIMO). Effective-date shown only when it differs from requested. (3) routing-disambiguation-contract — DEFAULT-ON corpus-wide routing arbiter backed by the curated ledger at tools/routing_inventory/ledger.csv (184 trigger-overlap concepts in 16 super-concept families). Codifies three patterns (primary_only / qualified_wins / context_dispatch) plus four explicit context-dispatch rules (audit trail, is_ftd, is_funded, is_internal_transfer). Routes the bare form to the primary owner and prevents the verbose 'let me also flag B and C' answer that produces wrong populations. Load this hub when a downstream domain skill needs to reference a cross-cutting rule, when a tier-0 callout points here, when the two-pass router returns >=2 hubs at competitive scores, or when extending the corpus with a new shared contract."
triggers:
  - cross-cutting
  - shared contract
  - filter contract
  - valid users
  - valid customers
  - IsValidCustomer
  - IsValidUser
  - IsCreditReportValidCB
  - test accounts
  - internal accounts
  - etorians
  - CB valid
  - Client Balance valid
  - credit-report valid
  - period-correct
  - scope footer
  - SCD-2 walk
  - omni-filter
  - data latency
  - data freshness
  - roll forward
  - rollforward
  - latest available
  - effective date
  - as-of date
  - stale data
  - same-day FX
  - FX null
  - weekend lag
  - Apex lag
  - Spaceship gap
  - MoneyFarm same-day
  - routing
  - disambiguation
  - trigger overlap
  - which hub
  - which skill
  - ambiguous routing
  - skill conflict
  - hub conflict
  - routing contract
  - disambiguation contract
  - primary owner
  - qualified form
  - context dispatch
  - bare trigger
  - polysemy
sub_skills:
  - valid-users-filter-contract.md
  - data-latency-and-rollforward.md
  - routing-disambiguation-contract.md
version: 3
owner: "dataplatform"
last_validated_at: "2026-06-14"
---

# Cross-Cutting Contracts

## When to Use

Load when a domain skill's tier-0 callout points to a cross-cutting contract, when extending the corpus with a new corpus-wide rule (filter / staleness / output-format / scope-disclosure), or when reviewing whether a domain skill is honouring the silent-default contracts.

## Scope

In scope: the omni-filter contract (`valid-users-filter-contract.md`) — the silent SCD-2 walk + `IsValidCustomer=1` default applied to every per-customer numeric aggregate, plus its two explicit overrides (`IsCreditReportValidCB` regulatory variant requires "CB valid"; unfiltered opt-out requires "unfiltered" / "include non-valids" / etc.) and the present-state `Dim_Customer` fallback for "today" questions. Future entries when the corpus grows.
Out of scope: domain-specific filter rules (those live in their domain hub's tier-0 callout), the customer-population funnel (`customer-populations-and-lifecycle.md` under `domain-customer-and-identity`), `Dim_Customer` column dictionaries (`customer-master-record.md`), per-table pre-filter inventory.
Last verified: 2026-06-08

## Critical Warnings

1. **Tier 1 — Polarity is DEFAULT-ON, never DEFAULT-OFF.** Every cross-cutting contract here is a silent default — the user opts OUT to disable it (literal phrase required), never opts IN to enable it. Producing the unfiltered / undefaulted answer first and then offering *"let me know if you want the contract-compliant version"* / *"I'd apply it for executive reporting — let me know"* inverts the polarity and is a contract violation. The compliant answer IS the answer.
2. **Tier 1 — Silent enforcement + footer, NO pre-flight.** Never ask "valid users or all?" / "default scope or override?" before answering. Apply the rule, disclose the scope in the mandatory output footer. The footer is what makes the silent default safe — it gives the user the information they need to ask for an override on the next turn if the default isn't what they wanted.
3. **Tier 1 — No trigger-word heuristics.** Contracts switch only on the user's literal words (e.g. "CB valid", "include non-valids"). Switching based on question topic ("regulatory" / "broker-recon" / "audit" / "executive reporting") produces silent wrong populations on every adjacent question.
4. **Tier 2 — Sibling flags are not supersets.** When a contract defines two flags (e.g. `IsValidCustomer` vs `IsCreditReportValidCB`), they intentionally diverge on edge cases. Never derive one from the other by adding `WHERE` clauses — always filter on the column directly.

## Layout

| Sub-skill | Owns |
|---|---|
| `valid-users-filter-contract.md` | Default `IsValidCustomer=1` SCD-2 walk + period-correct join + mandatory output-footer wording. DEFAULT-ON polarity (user opts OUT, never opts IN). Two explicit overrides on literal user phrases (CB-valid switch, unfiltered drop) and the present-state `Dim_Customer` fallback for "today" questions. |
| `data-latency-and-rollforward.md` | Default 3-day roll-forward for snapshot facts (AUM, balance, equity, NOP, position-PnL-as-balance) when the requested date is missing, partial (FX-null), or behind a known per-platform lag. DEFAULT-ON polarity. Per-column not per-table (MoneyFarm GBP can be T-0 while USD is T-1). Effective date shown only when it differs from requested. 7-day escalation with explicit staleness warning. **Does NOT apply to flow facts** (deposits, withdrawals, fees, MIMO). |
| `routing-disambiguation-contract.md` | Corpus-wide routing arbiter backed by the canonical ledger at `tools/routing_inventory/ledger.csv` (184 trigger-overlap concepts in 16 super-concept families). Three patterns: `primary_only` (172 concepts — bare form belongs to ONE hub, secondaries drop), `qualified_wins` (8 concepts — bare to primary, secondaries keep ONLY qualified forms), `context_dispatch` (4 concepts — `audit trail` / `is_ftd` / `is_funded` / `is_internal_transfer`, intent-based routing). DEFAULT-ON: obey the ledger, never infer ownership from semantic similarity. Source: `tools/routing_inventory/ledger_classification.yaml`. |

## Adding a new cross-cutting contract

1. Confirm the rule is genuinely corpus-wide, not domain-specific (if it's domain-specific, put it in the domain hub's tier-0 callout instead).
2. Add a sub-skill file to this directory with the standard frontmatter (`name: cross-cutting`, `version: 1`, `owner: "dataplatform"`).
3. Update the `sub_skills:` manifest in this hub's frontmatter.
4. Add a tier-0 callout in every domain hub that must honour the contract pointing to the new file.
5. Run `validate_skills.py` to confirm IDENTITY-005 (manifest matches on-disk) passes.
