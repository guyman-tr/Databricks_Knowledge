# Dealing_dbo.Dealing_Islamic_Units_Per_Contract

> Commodity contract size reference — units per contract for Islamic administrative fee calculation on commodity instruments.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (reference/config) |
| **Production Source** | Manual configuration |
| **Refresh** | Manual |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on instrument_id |

---

## 1. Business Meaning

This reference table defines the contract size (units per contract) for commodity instruments. Used exclusively by `SP_Islamic_Administrative_Fee` to calculate the Islamic fee for commodities: `(ABS(Units) / units_per_contract) × admin_fee_usd × Days_To_Charge`.

Contains ~5 commodity instruments (XTI/USD=1000, XAU/USD=100, XAG/USD=5000, XNG/USD=10000, XPT/USD=50).

---

## 2. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | instrument_id | int | YES | Instrument identifier. FK to DWH_dbo.Dim_Instrument. E.g., 17=XTI/USD, 18=XAU/USD. (Tier 3 — live data) |
| 2 | name | nvarchar(4000) | YES | Instrument name. E.g., "XTI/USD" (Crude Oil), "XAU/USD" (Gold). (Tier 3 — live data) |
| 3 | units_per_contract | int | YES | Number of instrument units in one standard contract. Used as divisor in commodity fee calculation. E.g., XTI=1000 barrels, XAG=5000 ounces. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 4 | instrument_type_id | int | YES | Asset class. Always 2 (Commodities) for this table. (Tier 3 — live data) |

---

## 3. Relationships

### 3.1 Referenced By

| Source Object | Description |
|--------------|-------------|
| SP_Islamic_Administrative_Fee | LEFT JOIN on instrument_id for contract size lookup |

---

*Generated: 2026-03-21 | Quality: 6.5/10 (★★★☆☆) | Phases: 5/14*
*Tiers: 0 T1, 1 T2, 3 T3, 0 T4, 0 T5 | Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10*
*Object: Dealing_dbo.Dealing_Islamic_Units_Per_Contract | Type: Table (reference)*
