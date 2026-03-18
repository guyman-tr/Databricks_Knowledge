# DWH_dbo.Dim_BonusType

> Flat catalog of bonus categories used to classify credit adjustments issued to customers — covers sales promotions, retention incentives, accounting adjustments, platform transfers, and operational fees.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | BonusTypeID (smallint, CLUSTERED INDEX) |
| **Row Count** | ~66 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on BonusTypeID ASC |

---

## 1. Business Meaning

`Dim_BonusType` is a DWH replica of the production `BackOffice.BonusType` table — the master catalog of bonus categories. Every credit adjustment (bonus) issued to a customer references a BonusTypeID to classify what kind of promotion or operational adjustment it represents.

Categories span multiple departments:
- **Sales** — first deposit bonuses, promotion codes, deposit bonuses
- **Retention** — loyalty incentives, rebates, club bonuses
- **Accounting/Ops** — fee refunds, wire adjustments, dormant fees, foreclosure
- **Marketing/IB** — affiliate payments, registration bonuses
- **R&D** — internal test credits
- **ACT/MT4** — platform fund transfers
- **Custom** — ad-hoc bonuses

**Column Pruning**: The DWH copy flattens the production table's two-level hierarchy (production has `ParentID` for departmental grouping, `DisplayName` for customer-facing labels, `HideFromAffwiz` for affiliate portal visibility). Only the core fields needed for analytics are retained.

**N/A Placeholder**: Row with `BonusTypeID = 0` (Name = "N/A") is inserted by the ETL as a default for fact rows with no bonus type.

---

## 2. Business Logic

### 2.1 Bonus Category Classification

**What**: Each BonusTypeID represents a specific type of credit adjustment, grouped by department.

**Columns Involved**: `BonusTypeID`, `Name`

**Rules**:
- IDs are manually assigned (no IDENTITY in DWH)
- Names describe the bonus purpose (e.g., "First Registration Bonus", "Dormant Fee", "Foreclosure")
- IDs range from 0–71 with gaps (IDs 60–65 missing)

### 2.2 Withdrawable Flag

**What**: `IsWithdrawable` indicates whether credited bonus funds can be withdrawn.

**Columns Involved**: `IsWithdrawable`

**Rules**:
- All 66 rows currently have `IsWithdrawable = 0` (False) — no bonus types are withdrawable in this data snapshot

### 2.3 Active/Inactive Status

**What**: `IsActive` controls whether the bonus type is available for new bonus issuance.

**Columns Involved**: `IsActive`

**Rules**:
- Most types are Active (1); a few legacy types are Inactive (0)
- Inactive types (e.g., "Refill - Negative Balance", "Championship Winner Demo") are retained for historical reference

### 2.4 DWH Redundant Columns

**What**: `DWHBonusTypeID` and `StatusID` are ETL artifacts.

**Columns Involved**: `DWHBonusTypeID`, `StatusID`

**Rules**:
- `DWHBonusTypeID` = copy of `BonusTypeID` (always equal, redundant)
- `StatusID` = hardcoded `1` for all rows

---

## 3. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.BackOffice.BonusType` (etoroDB-REAL) |
| **Generic Pipeline ID** | 1147 |
| **Copy Strategy** | Override (daily, every 1440 min) |
| **Staging Table** | `DWH_staging.etoro_BackOffice_BonusType` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) + N/A placeholder row |
| **Column Mapping** | 4 passthrough, 1 redundant copy (`DWHBonusTypeID`), 3 ETL-generated (`StatusID`, `UpdateDate`, `InsertDate`) |

---

## 4. Query Advisory

| Aspect | Detail |
|--------|--------|
| **Distribution** | REPLICATE — broadcast to all compute nodes |
| **Clustered Index** | BonusTypeID ASC — efficient single-row lookups |
| **Typical JOINs** | `Fact_*.BonusTypeID = Dim_BonusType.BonusTypeID` |
| **Best Practice** | Filter `IsActive = 1` for current types; use BonusTypeID = 0 awareness for N/A rows |

---

## 5. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | BonusTypeID | smallint | YES | Tier 1 | Primary identifier for the bonus category. Manually assigned IDs ranging 0–71 with gaps. ID 0 is the DWH N/A placeholder. Referenced by bonus fact tables. |
| 2 | Name | varchar(50) | NO | Tier 1 | Internal classification name describing the bonus type (e.g., "First Registration Bonus", "Dormant Fee"). Used in reports and dashboards for grouping bonus activity. |
| 3 | IsWithdrawable | bit | NO | Tier 1 | Whether credited bonus funds can be withdrawn by the customer. Currently `0` (False) for all rows. |
| 4 | IsActive | bit | NO | Tier 1 | Whether this bonus type is available for new bonus issuance. `1` = Active, `0` = Legacy/deprecated. |
| 5 | DWHBonusTypeID | smallint | NO | Tier 2b | Redundant copy of BonusTypeID — set to `BonusTypeID AS DWHBonusTypeID` by ETL. Always equals BonusTypeID. Legacy DWH artifact. |
| 6 | StatusID | int | YES | Tier 2b | Hardcoded to `1` by ETL for all rows. DWH-internal status flag with no observed variation. |
| 7 | UpdateDate | datetime | YES | Tier 2 | ETL load timestamp — set to `GETDATE()` by SP_Dictionaries_DL_To_Synapse. Does not reflect source modification time. |
| 8 | InsertDate | datetime | YES | Tier 2 | ETL load timestamp — set to `GETDATE()` by SP_Dictionaries_DL_To_Synapse. Resets on each truncate-and-reload. |

---

## 6. Sample Data

| BonusTypeID | Name | IsWithdrawable | IsActive |
|-------------|------|----------------|----------|
| 0 | N/A | 0 | 0 |
| 1 | First Registration Bonus | 0 | 1 |
| 5 | Retention Deposit Bonus | 0 | 1 |
| 20 | Over Weekend Fee Refund | 0 | 1 |
| 50 | Dormant Fee | 0 | 1 |
| 66 | Foreclosure | 0 | 1 |

---

*Generated: 2026-03-18 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 9/10)*
*Confidence: 4 Tier 1, 2 Tier 2, 2 Tier 2b, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,4,8,9b,10.5,11*
*Upstream Wiki: BackOffice.BonusType — 4 of 4 passthrough columns inherited*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_BonusType.sql*
