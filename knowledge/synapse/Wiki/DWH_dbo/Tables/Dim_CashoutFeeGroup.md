# DWH_dbo.Dim_CashoutFeeGroup

> Three-value lookup classifying withdrawal fee tiers: Default (standard fees), Exempt (no fees), and Discount (reduced fees).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | CashoutFeeGroupID (int, CLUSTERED INDEX) |
| **Row Count** | 3 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on CashoutFeeGroupID ASC |

---

## 1. Business Meaning

`Dim_CashoutFeeGroup` classifies customer withdrawal fee tiers. Each customer account is assigned to a fee group that determines how withdrawal fees are applied:

- **Default** (1) — Standard withdrawal fee schedule
- **Exempt** (2) — No withdrawal fees (e.g., VIP customers, promotional exemptions)
- **Discount** (3) — Reduced withdrawal fees

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Dictionary.CashoutFeeGroup` (etoroDB-REAL) |
| **Staging Table** | `DWH_staging.etoro_Dictionary_CashoutFeeGroup` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | 2 passthrough (1 renamed: `Name` → `CashoutFeeGroupName`), 1 ETL-generated (`UpdateDate`) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CashoutFeeGroupID | int | YES | Tier 2 | Fee group identifier: 1=Default, 2=Exempt, 3=Discount. |
| 2 | CashoutFeeGroupName | varchar(50) | YES | Tier 2 | Fee group name. Renamed from source `Name`. |
| 3 | UpdateDate | datetime | YES | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

*Generated: 2026-03-18 | Quality: 7.5/10 (Elements: 7/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10)*
*Confidence: 0 Tier 1, 3 Tier 2, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CashoutFeeGroup.sql*
