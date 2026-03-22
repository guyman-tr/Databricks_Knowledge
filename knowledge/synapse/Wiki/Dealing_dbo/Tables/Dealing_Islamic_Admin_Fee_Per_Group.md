# Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group

> Islamic account administrative fee schedule — USD fee rates per instrument group and asset class, with grace period configuration.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (reference/config) |
| **Production Source** | Manual configuration |
| **Refresh** | Manual (12 rows, rarely changes) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on instrument_type_id |

---

## 1. Business Meaning

This is a reference table defining the administrative fee rates charged to Islamic (swap-free) accounts in lieu of overnight swap fees. Islamic accounts don't pay traditional rollover fees due to Sharia compliance; instead, they pay a flat administrative fee per instrument group after a grace period.

Contains 12 rows covering all asset classes (Currencies, Commodities, Indices, Stocks, ETF, Crypto), each subdivided into fee groups (1-4) with different USD rates. The grace period is uniformly 7 days — no fee is charged for the first 7 trading days a position is open.

Used by `SP_Islamic_Administrative_Fee` to calculate daily fees: `Admin_Fee_USD × Days_To_Charge × (units_formula_per_asset_class)`.

---

## 2. Business Logic

### 2.1 Fee Formula Per Asset Class

**Rules** (from SP_Islamic_Administrative_Fee):
- **Currencies (1)**: `(ABS(Units)/100000) × admin_fee_usd × Days_To_Charge`
- **Commodities (2)**: `(ABS(Units)/units_per_contract) × admin_fee_usd × Days_To_Charge`
- **Indices (4)**: `ABS(Units) × admin_fee_usd × Days_To_Charge`
- **Stocks/ETF (5,6)**: `((ABS(Units) × USD_Price)/10000) × admin_fee_usd × Days_To_Charge`
- **Crypto (10)**: `((ABS(Units) × USD_Price)/10000) × admin_fee_usd × Days_To_Charge`

### 2.2 Grace Period

All groups have `grace_period = 7`. Fee starts on day 8 of holding the position.

---

## 3. Query Advisory

### 3.1 Gotchas

- **Only 12 rows**: This is a small reference table. Full table scan is fine.
- **Joined via composite key**: `(instrument_group, instrument_type_id)` — both columns needed.
- **Rates are per unit formula, not per position**: The actual fee depends on position size and the asset class formula.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | instrument_group | int | YES | Fee tier group within an asset class. Groups 1-4 with different rates. Instruments are assigned to groups via `Dealing_Islamic_Instruments_Groups`. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 2 | admin_fee_usd | float | YES | Administrative fee amount in USD. Applied per unit/contract/10K-USD-value depending on asset class. Ranges: $0.10 (Index group 3) to $80.00 (Currency group 4). (Tier 2 — SP_Islamic_Administrative_Fee) |
| 3 | grace_period | int | YES | Number of trading days before fee starts. Currently 7 for all groups. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 4 | currency | nvarchar(4000) | YES | Fee denomination currency. Always 'USD'. (Tier 3 — live data) |
| 5 | instrument_type_id | int | YES | Asset class identifier: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. (Tier 2 — SP_Islamic_Administrative_Fee) |

---

## 5. Relationships

### 5.1 Referenced By

| Source Object | Description |
|--------------|-------------|
| SP_Islamic_Administrative_Fee | Joins on `(instrument_group, instrument_type_id)` for fee lookup |
| Dealing_Islamic_Instruments_Groups | Provides instrument_group mapping for the join |

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 7/14*
*Tiers: 0 T1, 4 T2, 1 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group | Type: Table (reference)*
