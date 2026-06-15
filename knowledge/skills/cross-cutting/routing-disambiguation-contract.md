---
name: cross-cutting
description: "DEFAULT-ON routing-disambiguation contract for the entire skill corpus. Manages the 184 trigger-overlap concepts identified by the Phase 1 routing inventory. Codifies three patterns (primary_only / qualified_wins / context_dispatch) and four explicit context-dispatch rules. Backed by the canonical ledger at tools/routing_inventory/ledger.csv (one row per overlapping concept: super_concept, primary_owner, pattern, drop_from, claiming_hubs, notes). When the matcher returns >=2 candidate hubs at competitive scores, this contract decides which hub wins by looking up the user's normalized trigger in the ledger. Tier-1 enforcement: NEVER infer ownership from semantic similarity / hub description / required-tables overlap when an explicit ledger entry exists; ALWAYS obey the ledger. Tier-1 enforcement: NEVER produce a verbose 'I'll route to A but here are also B and C in case you meant them' answer when the ledger gives a single primary owner; route to A and only mention B/C if the answer cannot be produced from A's tables. Source-of-truth: tools/routing_inventory/ledger_classification.yaml (curated). Build: python tools/routing_inventory/build_ledger.py <inventory>. Canonical hierarchy view: tools/routing_inventory/semantic_hierarchy.md."
triggers:
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
  - ledger
  - primary owner
  - qualified form
  - context dispatch
  - bare trigger
  - polysemy
  - homonym
sub_skills: []
version: 1
owner: "dataplatform"
last_validated_at: "2026-06-14"
---

# Routing Disambiguation Contract

## When to use

Load this contract when:

1. The two-pass router returns >=2 hubs at competitive scores for the same user query.
2. A skill author is about to add a new trigger and wants to know whether it's already owned.
3. The CI guard (`ROUTING-001`) flags an unmanaged overlap on a PR.
4. The agent catches itself producing the verbose "I'll route to A but maybe also B and C" answer — that's the contract-violation tell.

## Critical warnings (tier 1)

1. **Tier 1 — Obey the ledger, never infer.** When `tools/routing_inventory/ledger.csv` has an entry for a trigger, that entry decides the routing. Do NOT override based on semantic similarity, hub description tokens, required-tables overlap, or "this question feels more like X." Inference produces wrong populations silently.
2. **Tier 1 — Single primary, single answer.** When the pattern is `primary_only` or `qualified_wins`, route to the primary owner ONLY and produce the answer from that hub. Do NOT mention the dropped hubs as alternatives unless the user's tables literally aren't reachable from the primary. The "let me also flag X and Y in case" framing inverts the contract — the dropped hubs are dropped for a reason.
3. **Tier 1 — Context dispatch is intent-based, not topic-based.** For the four `context_dispatch` concepts (`audit trail`, `is_ftd`, `is_funded`, `is_internal_transfer`), the routing rule lives in §5 below and dispatches on the user's literal qualifiers. Do not dispatch on what the question "feels" about.
4. **Tier 1 — Qualified forms route to secondaries.** `qualified_wins` means `aum` → primary (`domain-aum-and-aua`), but `spaceship aum` / `moneyfarm aum` / `options aum` → niche hub. The qualifier is the signal. Do not strip qualifiers when normalizing the user's trigger.
5. **Tier 2 — Canonical phrasings are the global home.** Five concepts that historically lacked a primary-owner trigger (`apex`, `gatsby`, `isglobalftd`, `funded accounts`, `playerstatus`) now live on their primary owner per Phase 5 of the inventory rollout. A sixth (`global ftd`) was added during the same wave. Routing for these no longer needs manual intervention — the matcher will score the global home correctly.

## The three patterns

### Pattern 1: `primary_only` (172 concepts)

> Bare form belongs to ONE hub. Secondaries DROP the trigger entirely.

The dropped secondary hubs may still REFERENCE the concept in their body text or required_tables — they just don't claim it as a routing trigger. Examples:

- `apex` → `domain-cross` (canonical recon story). `domain-options` drops the bare trigger but keeps `Apex options trading`-shape qualified forms in body text.
- `walletid` → `domain-exw-wallet`. `domain-payments` drops the bare trigger — payments references wallet IDs in body text but doesn't compete on routing.
- `screeningstatus` → `domain-compliance-and-aml`. `domain-customer-and-identity` drops; identity provides the column dictionary but compliance owns the workflow.

### Pattern 2: `qualified_wins` (8 concepts)

> Bare form belongs to PRIMARY. Secondaries keep ONLY qualified forms.

The 8 concepts:

| Concept | Primary owner | Qualified-form examples for secondaries |
|---|---|---|
| `aum` | `domain-aum-and-aua` | `spaceship aum`, `moneyfarm aum`, `options aum`, `wallet aum` |
| `commission` | `domain-revenue-and-fees` | `affiliate commission`, `partner commission` (marketing) |
| `crypto` | `domain-trading` | `crypto deposit`, `crypto wallet`, `crypto withdrawal` (payments / wallet) |
| `eth` | `domain-trading` | `eth staking` (staking) |
| `ftd` | `domain-customer-and-identity` | `FTD revenue` (revenue-and-fees), `FTD deposit` (payments), `Options FTD` (options) |
| `funded accounts` | `domain-customer-and-identity` (PHASE 5) | `spaceship funded accounts` (spaceship) |
| `net deposits` | `domain-payments` | `spaceship net deposits`, `moneyfarm net deposits` |
| `reconciliation` | `domain-cross` | `trade reconciliation` (trading) |

Secondaries DROP the bare form. They keep the qualified form. Routing on the qualified form goes to the secondary, not the primary.

### Pattern 3: `context_dispatch` (4 concepts)

> Bare form has multiple legitimate owners. Contract rules below decide based on user intent.

See §5 below. These four concepts cannot be reduced to a single primary owner because they're genuinely two-or-more flows under the same name.

## Context-dispatch rules (the 4 special cases)

### 1. `audit trail`

| User intent signal | Route to |
|---|---|
| `audit trail for [transaction\|emoney\|broker recon\|eMoney IBAN\|provider]` | `domain-cross` (tribe-emoney-audit story) |
| `audit trail for [customer\|accountid\|history\|player\|activity]` | `domain-customer-and-identity` (per-customer action audit) |
| `audit trail` bare with no qualifier | `domain-cross` (more cross-cutting in scope) + emit a footer noting both options |

### 2. `is_ftd`

| User intent signal | Route to |
|---|---|
| `is_ftd spaceship\|SPS\|Spaceship` | `domain-spaceship` |
| `is_ftd moneyfarm\|MF\|Moneyfarm` | `domain-moneyfarm` |
| `is_ftd` bare | Route by required_tables match: if MF tables, MF; if SPS tables, SPS; else flag as ambiguous and ask once |

### 3. `is_funded`

Same dispatch as `is_ftd`. Niche-platform flag column shared by Spaceship and MoneyFarm sub-account models. Route by platform qualifier; bare form needs disambiguation.

### 4. `is_internal_transfer`

| User intent signal | Route to |
|---|---|
| `is_internal_transfer options\|US options` | `domain-options` |
| `is_internal_transfer spaceship\|Spaceship\|SPS` | `domain-spaceship` |
| Bare or no platform | `domain-options` (more common in user queries; emit footer noting both) |

## The 16 super-concept families

Browse the full classification at `tools/routing_inventory/semantic_hierarchy.md`. Summary:

| Family | Count | Primary owner(s) |
|---|---:|---|
| `aum_aua` | 10 | `domain-aum-and-aua` (+ niche-platform views to niche hubs) |
| `broker_provider_identity` | 12 | `domain-cross` for Apex/Gatsby/USABroker/SOD; `domain-payments` for MID/Treezor; `domain-exw-wallet` for Tangany |
| `compliance_aml` | 4 | `domain-compliance-and-aml` (+ `appropriateness test` to identity) |
| `cross_cutting_utilities` | 4 | `cross-cutting` (IsValidCustomer, IsCreditReportValidCB, latency); `domain-cross` for `reconciliation` |
| `customer_identity_columns` | 14 | `domain-customer-and-identity` (+ `screeningstatus` / `verificationlevelid` to compliance; `moneyfarmuserid` to moneyfarm) |
| `customer_lifecycle_populations` | 8 | `domain-customer-and-identity` (+ `onboarding funnel` to ops; `audit trail` context-dispatch) |
| `fees_revenue` | 27 | `domain-revenue-and-fees` (+ niche-platform views to niche hubs) |
| `marketing` | 2 | `domain-marketing-and-acquisition` |
| `money_flow_crypto` | 14 | `domain-cross` for C2F E2E; `domain-payments` for C2P; `domain-exw-wallet` for on-chain mechanics |
| `money_flow_fiat` | 13 | `domain-cross` for refund-chargeback chain; `domain-customer-and-identity` for FTD; `domain-payments` for card-level columns |
| `niche_platform_moneyfarm` | 10 | `domain-moneyfarm` |
| `niche_platform_options` | 2 | `domain-options` |
| `niche_platform_spaceship` | 11 | `domain-spaceship` (+ 3 context-dispatch `is_*` flags) |
| `niche_platform_staking` | 4 | `domain-staking` |
| `trading_concepts` | 31 | `domain-trading` (+ `bi_db_first5actions` to identity) |
| `wallet_infrastructure` | 18 | `domain-exw-wallet` |

## How to revise

The ledger is curated in `tools/routing_inventory/ledger_classification.yaml`. To revise:

1. Edit the YAML (add/move/remove an entry).
2. Run `python tools/routing_inventory/build_ledger.py audits/_routing_inventory_<latest-ts>`.
3. Validator confirms: 0 errors (every overlap classified, no typos, no inconsistent drop_from).
4. Validator regenerates `tools/routing_inventory/ledger.csv` + `tools/routing_inventory/semantic_hierarchy.md`.
5. Bump `version:` in this file's frontmatter.

## Refresh cadence

Re-run the inventory + ledger rebuild whenever:

- A new domain hub is added.
- An existing hub adds >5 triggers in a single PR.
- The CI guard (`ROUTING-001`) flags >3 unmanaged overlaps in a week.
- Quarterly drift sweep (target: Q1 / Q2 / Q3 / Q4 first Monday).

## Out of scope

- `required_tables` overlaps (81 cases). Multiple hubs CAN reference the same Unity Catalog table — that's a feature, not a routing problem. The matcher uses triggers, not required_tables. Required_tables overlaps are intentionally left alone.
- Single-claimant concepts (4,140 cases). They have a sole owner by construction.
- Cross-cutting filter contracts (`valid-users-filter-contract.md`, `data-latency-and-rollforward.md`). Those are silent defaults applied AFTER routing; this contract decides BEFORE routing.

## Tier-0 callout for domain hubs

Hubs whose triggers were modified by Phase 4 cleanup should add a tier-0 callout pointing here:

```
> Routing: this hub honours the cross-cutting routing-disambiguation contract.
> If you reached this hub via a bare trigger that maps to a different primary
> owner in the ledger, the contract overrides; re-route per
> cross-cutting/routing-disambiguation-contract.md §3.
```

This is the same tier-0-callout shape used by the valid-users-filter-contract — silent default with an override path documented at the entry point.
