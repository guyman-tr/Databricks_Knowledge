# Review Needed: BI_DB_dbo.BI_DB_InactivityFees

> Sidecar to `BI_DB_InactivityFees.md`. Items requiring domain expert validation.

---

## Tier Attribution Questions

| Column | Question |
|--------|----------|
| `Liabilities` / `Credit` | Sourced from `DWH_dbo.V_Liabilities` — a view. The view definition was not read during documentation. Confirm the view aggregates positions correctly and that `Liabilities` is the net balance (not gross), and `Credit` is not double-counting the same balance. |
| `Club` | Maps to `Dim_PlayerLevel.Name`. Confirm this is the "VIP tier" label (Bronze/Silver/Gold/Platinum/Diamond/Popular Investor) and not a different hierarchy. |

---

## SP Logic Concerns

### LastLogin Cutoff Buffer
The inactivity cutoff is `DATEADD(DAY, 1, DATEADD(year, -1, @Date))` — adding 1 day creates a window where a customer who logged in **exactly** 365 days ago still qualifies. Confirm this +1 day is intentional (regulatory-safe) and not an off-by-one error.

### Partially Blocked Players Included
`PlayerStatusID NOT IN (2, 4)` excludes "Blocked Upon Request" and "Blocked" but leaves in `Block Deposit & Trading` (2.2%), `Trade & MIMO Blocked` (0.7%), `Deposit Blocked` (0.4%). The SP comment says "there are 3 more blocked that [are] not considered." Confirm this is intentional — can inactivity fees be collected from partially-blocked accounts?

---

## Data Quality Questions

| Observation | Question |
|-------------|----------|
| AccountStatusName = 'N/A' (0.3%, ~190 rows) | What does 'N/A' mean here? Is this a valid account status for fee collection, or a data gap? |
| IsAffiliate stored as binary(1) | Why is this `binary(1)` instead of `bit`? This is inconsistent with similar flags elsewhere. Check if downstream consumers are handling the cast correctly. |
| 63,530 rows — no obvious spike/dip analysis | This is a full-truncate snapshot. No SLA or expected row count is documented. Confirm expected range and alert thresholds for operations monitoring. |

---

## Not Migrated to UC

Before UC migration:
- `DWH_dbo.V_Liabilities` — confirm UC equivalent view or replacement
- `DWH_dbo.Fact_CustomerAction` with `ActionTypeID=14` — confirm ActionTypeID registry is stable in UC
- `DWH_dbo.Dim_Affiliate` — confirm UC path for affiliate dimension

---

*Generated: 2026-04-22 | Batch 27 | Reviewer: pending*
