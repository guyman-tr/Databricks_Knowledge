---
name: instruments
description: "TOMBSTONE — superseded on 2026-05-28 / DA-72. This skill's content was deeply incorporated into and fully superseded by domain-trading/instruments-and-asset-classes.md (v2, rebuilt 2026-05-11). Instrument identification (the two-part Symbol/Name + InstrumentTypeID filter pattern, the one-asset-many-IDs problem like Tesla's 8 InstrumentIDs, suffix meanings, ETH collision across 5 type-IDs), the Tradable-vs-Tradeable distinction (3,005-row delta), enriched-view flags, per-asset-class query patterns, and the broker-dealer ProviderID bridge all live there. Load the Trading & Markets hub or the sub-skill directly for any instrument / ticker / asset-class / dim_instrument question. This redirect-only file remains for ~30 days to allow the MCP embedding corpus to re-train; after that the folder is hard-deleted."
triggers:
  - instrument
  - InstrumentID
  - InstrumentTypeID
  - dim_instrument
  - v_dim_instrument_enriched
  - by instrument
  - by asset class
  - by ticker
  - by symbol
  - real stocks
  - real crypto
required_tables:
  - main.etoro_kpi_prep.v_dim_instrument_enriched
version: 3
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# instruments (TOMBSTONE — superseded)

> **TOMBSTONE — superseded.** Fully incorporated 2026-05-28 / DA-72 into the Trading & Markets super-domain at `domain-trading/instruments-and-asset-classes.md` (v2, rebuilt 2026-05-11 with seven additional knowledge sources surfaced during the rebuild). Load that sub-skill — or the `domain-trading/SKILL.md` hub — for any instrument-identification question. This file is a redirect-only stub kept for ~30 days while the MCP embedding corpus re-trains.

## When to Use

**Do not load this skill directly.** It is a tombstone.

If the MCP routed here for an instrument / ticker / asset-class question — load `domain-trading/instruments-and-asset-classes.md`. The new home is a strict superset of this legacy skill and adds: the `Tradable` vs `Tradeable` distinction (3,005-row delta), UC comment health caveats on the enriched view, the `IsTicketFeePercentInstrument` content gap, `Symbol` non-uniqueness vs `SymbolFull`, the `DollarRatio` column, `IsMajor`/`IsMajorID` and corrected `Is_245_Instrument` semantics, the Broker-Dealer framing (`ProviderID` as the broker→dealer bridge), live-catalogue refresh notes (+602 instruments since the v1 wiki snapshot), and Ethereum-adjacent traps (`ETC` / `ENS` / `ETHFI` / `ETHA`-cross-pair vs `ETHA.US` ETF).

## Scope

In scope: redirect-only. The full live scope lives at the new home.
Out of scope: everything substantive — load `domain-trading/instruments-and-asset-classes.md`.
Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 — Do not write SQL against this skill's content.** It has none. If you find yourself reading filter rules from this file, stop and load `domain-trading/instruments-and-asset-classes.md`. The two-part filter pattern (Symbol/Name + InstrumentTypeID) and all sub-rules are owned there.
2. **Tier 2 — Do not re-derive content here.** Any net-new instrument knowledge (new asset class, new suffix convention, new flag semantics) must land in `domain-trading/instruments-and-asset-classes.md`, not in this tombstone. This file is frozen.
3. **Tier 3 — Hard-delete is scheduled.** This folder is slated for `git rm -rf` ~30 days after 2026-05-28 (~2026-06-27) once the MCP embedding corpus has re-trained against the sub-skill's description and triggers. Track the deletion via DA-72 follow-up.

## Skill provenance

Tombstoned 2026-05-28. The instrument-identification skill was originally a workspace-root DataPlatform skill (`instruments`, v2 from 2026-05-07). Its content was rebuilt and deeply extended on 2026-05-11 into `domain-trading/instruments-and-asset-classes.md` (the Trading & Markets hub sub-skill) per `/speckit.skill` Phase 2.5; that rebuild added seven additional knowledge sources (wikis, lineage files, live UC schema, distinct-value verifications) on top of the legacy content. From 2026-05-11 to 2026-05-28 the legacy workspace skill ran in parallel with the new sub-skill. On DA-72 (2026-05-28) the parallel-run period ended and the legacy skill was tombstoned; the hub `domain-trading/SKILL.md` provenance now reflects this status. Hard-delete deferred ~30 days for embedding re-train.
