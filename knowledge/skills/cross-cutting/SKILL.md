---
name: cross-cutting
description: "Hub for cross-cutting contracts and conventions that every domain skill must honour silently — non-domain-specific rules that apply across the entire skill corpus regardless of which hub is loaded. Currently houses the valid-users-filter-contract (the omni-filter SCD-2 walk + IsValidCustomer=1 rule + mandatory output footer that every per-customer numeric aggregate applies by default, with explicit opt-ins for the IsCreditReportValidCB regulatory variant and the unfiltered opt-out, and the present-state Dim_Customer fallback for 'today' questions). Future entries: staleness contract, scope-disclosure contract, output-format contract, etc. Load this hub when a downstream domain skill needs to reference a cross-cutting rule, when a tier-0 callout points here, or when extending the corpus with a new shared contract."
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
sub_skills:
  - valid-users-filter-contract.md
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-31"
---

# Cross-Cutting Contracts

## When to Use

Load when a domain skill's tier-0 callout points to a cross-cutting contract, when extending the corpus with a new corpus-wide rule (filter / staleness / output-format / scope-disclosure), or when reviewing whether a domain skill is honouring the silent-default contracts.

## Scope

In scope: the omni-filter contract (`valid-users-filter-contract.md`) — the silent SCD-2 walk + `IsValidCustomer=1` default applied to every per-customer numeric aggregate, plus its two explicit opt-ins (`IsCreditReportValidCB` regulatory variant, unfiltered opt-out) and present-state `Dim_Customer` fallback. Future entries when the corpus grows.
Out of scope: domain-specific filter rules (those live in their domain hub's tier-0 callout), the customer-population funnel (`customer-populations-and-lifecycle.md` under `domain-customer-and-identity`), `Dim_Customer` column dictionaries (`customer-master-record.md`), per-table pre-filter inventory.
Last verified: 2026-05-31

## Critical Warnings

1. **Tier 1 — Cross-cutting contracts are silent defaults, not optional.** The whole point of a cross-cutting contract is that every domain skill applies it without being asked. Pre-flighting "valid users or all?" at question time defeats the contract; the contract is what makes the silent default safe (mandatory output footer discloses the scope after the fact).
2. **Tier 1 — No trigger-word heuristics.** Contracts switch only on the user's literal words (e.g. "CB valid", "include non-valids"). Switching based on question topic ("regulatory" / "broker-recon" / "audit") produces silent wrong populations on every adjacent question.
3. **Tier 2 — Sibling flags are not supersets.** When a contract defines two flags (e.g. `IsValidCustomer` vs `IsCreditReportValidCB`), they intentionally diverge on edge cases. Never derive one from the other by adding `WHERE` clauses — always filter on the column directly.

## Layout

| Sub-skill | Owns |
|---|---|
| `valid-users-filter-contract.md` | Default `IsValidCustomer=1` SCD-2 walk + period-correct join + mandatory output-footer wording, with two explicit opt-ins and the present-state fallback. |

## Adding a new cross-cutting contract

1. Confirm the rule is genuinely corpus-wide, not domain-specific (if it's domain-specific, put it in the domain hub's tier-0 callout instead).
2. Add a sub-skill file to this directory with the standard frontmatter (`name: cross-cutting`, `version: 1`, `owner: "dataplatform"`).
3. Update the `sub_skills:` manifest in this hub's frontmatter.
4. Add a tier-0 callout in every domain hub that must honour the contract pointing to the new file.
5. Run `validate_skills.py` to confirm IDENTITY-005 (manifest matches on-disk) passes.
