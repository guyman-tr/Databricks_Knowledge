# Dealing_dbo.Dealing_Boundary_Cost_H_Indices — Review Needed

> Items flagged for domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **UpdateDate** — Assumed ETL last-update timestamp (`GETDATE()` or equivalent); confirm if historical loads rewrote rows in place.

## Columns Needing Clarification

- **`IsSettled`** — Does **1** mean a **hedge trade was executed**, **accounting settlement**, or **boundary state cleared**?
- **`UnitsBuy` vs `VolumeBuy`** (and sell pair) — Same metric at different scale, or **units vs USD volume**?
- **`VariableSpread` vs `StdSpreadPercent`** — How they combine in reporting vs raw **`Mid`**.

## Structural Questions

- **Indices-only scope**: Confirm the table contains **only index instruments**, not a misnamed historical dump of all types.
- **Why `_H_Indices` vs `Dealing_Boundary_Cost`**: Different SP version, regulatory carve-out, or one-off historical snapshot?
- **Decommissioning**: Formal sign-off date / ticket for stopping loads (**Mar 2023**) if available for audit trail.
