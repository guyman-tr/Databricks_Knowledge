# DWH_dbo.Dim_CardType

> Frozen lookup of credit/debit card brands (Visa, MasterCard, Diners, etc.) used to classify deposit and withdrawal transactions by card network. Migrated from legacy DWH with no active ETL.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) — **FROZEN** |
| **Key Identifier** | CardTypeID (int, CLUSTERED INDEX) |
| **Row Count** | 18 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on CardTypeID ASC |

---

## 1. Business Meaning

`Dim_CardType` classifies credit and debit card brands for deposit and withdrawal analytics. It maps CardTypeID values to card network names (Visa, MasterCard, Diners, Amex, etc.).

**Current State**: Only 3 card types are active (None, Visa, MasterCard). The remaining 15 are legacy/decommissioned brands. The table was migrated from the Legacy DWH SQL Server in September 2024 and has **no active ETL** — all `UpdateDate` values are frozen at `2019-06-30`.

**Note**: The column `CarTypeName` contains a typo (missing "d" — should be `CardTypeName`). This is carried forward from the legacy DWH.

Despite being frozen, this table has **active consumers** — multiple BI_DB stored procedures (SP_AllDeposits, SP_H_Deposits, SP_DepositWithdrawFee, etc.) JOIN to it for card type resolution.

---

## 2. Business Logic

### 2.1 Card Brand Classification

**What**: Maps card type IDs to payment card network names.

**Columns Involved**: `CardTypeID`, `CarTypeName`

**Rules**:
- ID 0 = "None" (no card / non-card payment)
- Active: Visa (1), Master Card (2), Diners (3)
- Legacy: Amex, Fire Pay, JCB, American Express, Maestro, Laser, Switch, UK Local Credit Card, Discover, Local Card, China Union Pay, Solo, Cirrus, GE Capital

---

## 3. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Original Source** | Legacy DWH SQL Server |
| **Migration** | `DWH_Migration.Dim_CardType` (Sept 2024) |
| **Status** | **FROZEN** — no active ETL, not in SP_Dictionaries |
| **Last Updated** | 2019-06-30 (pre-migration timestamp) |

---

## 4. Query Advisory

| Aspect | Detail |
|--------|--------|
| **Distribution** | REPLICATE |
| **Clustered Index** | CardTypeID ASC |
| **Typical JOINs** | Deposit/withdrawal fact tables JOIN on CardTypeID |
| **Known Consumers** | SP_AllDeposits, SP_H_Deposits, SP_DepositWithdrawFee, SP_EY_Audit_Deposit_Cashouts, SP_Deposit_Reversals_PIPs |

---

## 5. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CardTypeID | int | YES | Tier 2 | Card brand identifier. 0 = None, 1 = Visa, 2 = MasterCard, 3 = Diners. IDs 4–17 are legacy inactive brands. |
| 2 | CarTypeName | varchar(50) | YES | Tier 2 | Card network name. Column name has a typo (missing "d"). Contains brand names like "Visa", "Master Card", "Diners". |
| 3 | IsActive | int | YES | Tier 2 | Whether this card type is currently used. 1 = Active (None, Visa, MasterCard, Diners), 0 = Legacy/inactive. Stored as int rather than bit. |
| 4 | UpdateDate | datetime | YES | Tier 3 | Timestamp frozen at 2019-06-30 — reflects the last update in the legacy DWH before migration. Not refreshed. |

---

## 6. Sample Data

| CardTypeID | CarTypeName | IsActive |
|------------|-------------|----------|
| 0 | None | 1 |
| 1 | Visa | 1 |
| 2 | Master Card | 1 |
| 3 | Diners | 1 |
| 4 | Amex | 0 |
| 7 | American Express | 0 |
| 8 | Maestro | 0 |

---

*Generated: 2026-03-18 | Quality: 7.4/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 Tier 1, 3 Tier 2, 1 Tier 3, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,8,11*
*Frozen Table: Migrated from Legacy DWH (Sept 2024), no active ETL*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CardType.sql*
