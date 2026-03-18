# Review Sidecar — DWH_dbo.Dim_BonusType

## Unverified Columns (Tier 4)

_None._

## Open Questions

### Structural
1. **DWHBonusTypeID usage** — Always equals BonusTypeID. Is this referenced by any downstream consumer, or can it be considered dead?
2. **StatusID usage** — Hardcoded to 1. Is this used by any fact table filter, or is it a dead column?
3. **Hierarchy flattening** — Production has a ParentID hierarchy (9 root categories → child types). Should the DWH copy include this for departmental grouping in reports?

### Clarification
4. **IsWithdrawable** — All 66 rows show `False`. Is this because no bonus types are currently withdrawable, or is this column no longer maintained?

---

*Generated: 2026-03-18*
