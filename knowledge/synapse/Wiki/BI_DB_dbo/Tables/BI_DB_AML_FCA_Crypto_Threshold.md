# BI_DB_dbo.BI_DB_AML_FCA_Crypto_Threshold

> Weekly AML monitoring table identifying FCA, CySEC, and ASIC-regulated customers with settled crypto positions valued at or above eToro's crypto threshold on a given Monday monitoring date. Grain is one row per qualifying customer per monitoring date. Populated by SP_W_Mon_AML_FCA_Crypto_Threshold; data accumulates from 2021-11-28 (no rolling window, only per-date idempotent reload).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Sources** | BI_DB_dbo.BI_DB_PositionPnL, DWH_dbo.Dim_Customer, DWH_dbo.Dim_Manager, DWH_dbo.Dim_PlayerLevel, DWH_dbo.Dim_PlayerStatus, DWH_dbo.Dim_Regulation |
| **Writer SP** | `BI_DB_dbo.SP_W_Mon_AML_FCA_Crypto_Threshold` |
| **Schedule** | Weekly Monday |
| **Row Count** | ~60,931 (as of 2026-04-12) |
| **Distinct CIDs** | ~1,186 |
| **Date Range** | 2021-11-28 to 2026-04-12 (225 monitoring dates) |
| | |
| **Synapse Distribution** | `HASH (CID)` |
| **Synapse Index** | `CLUSTERED INDEX (DateID ASC)` |
| | |
| **UC Target** | `_Not_Migrated` |

---

## 1. Business Meaning

`BI_DB_AML_FCA_Crypto_Threshold` is the AML compliance team's weekly watchlist of high-value crypto holders regulated under FCA, CySEC, or ASIC. A customer appears in this table when they hold a settled (real-money, non-CFD) crypto position worth at least 80,000 (position currency units) on a Monday monitoring date, are fully KYC-verified (Level 3), and have an active eToro Money crypto wallet.

The table provides account manager attribution (`Account_Manager_Name`) alongside regulatory classification (`Regualtion` [sic]), loyalty tier (`Club`), and player status (`PlayerStatus`). This allows the AML team to identify which account managers oversee the largest crypto exposures and to ensure timely escalation for customers approaching or exceeding jurisdictional reporting thresholds.

**Name vs. scope mismatch**: Despite being named "AML_FCA_Crypto_Threshold," the table includes FCA (53.6%), CySEC (40.1%), and ASIC/ASIC+GAML (5.3%) regulated customers. The original scope was FCA-only and was later expanded by adding UNION ALL branches in the SP.

**Column typo**: The `Regualtion` column name is misspelled in both the DDL and the SP (missing 'a'). This is a permanent fixture that cannot be fixed without a DDL change and all downstream query updates.

---

## 2. Business Logic

### 2.1 Crypto Position Threshold Filter

**What**: Only customers with settled crypto positions at or above the 80,000 threshold on the monitoring date qualify.

**Columns Involved**: `CID`, `DateID`

**Rules**:
- Source: `BI_DB_dbo.BI_DB_PositionPnL` filtered by `InstrumentTypeID = 10` (Crypto) and `IsSettled = 1` (real positions, not CFD).
- Threshold: `Amount >= '80000'` — the 80,000 value is a string literal in the SP (SQL auto-casts); currency denomination is not specified but is the position's native amount.
- Deduplication: `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY DateID) = 1` ensures one position row per CID even if a CID holds multiple qualifying crypto positions on the same date.

### 2.2 Customer Eligibility Filters

**What**: Three UNION ALL branches enforce Dim_Customer filter criteria, one per regulation group.

**Rules** (all three branches require):
- `IsValidCustomer = 1` — active, non-test customer
- `IsDepositor = 1` — has made at least one real deposit
- `VerificationLevelID = 3` — fully KYC-verified (Level 3)
- `PlayerStatusID IN (1, 5)` — Normal (1) or Warning (5) only; suspended/restricted customers excluded
- `HasWallet = 1` — eToro Money crypto wallet active

**Regulation branches**:
- Branch 1: `RegulationID = 2` → FCA customers
- Branch 2: `RegulationID = 1` → CySEC customers
- Branch 3: `RegulationID IN (4, 10)` → ASIC and ASIC+GAML customers

### 2.3 Load Pattern (Idempotent Per-Date)

**What**: SP deletes all rows for the target DateID then re-inserts, creating an idempotent per-date reload. Historical dates are never purged.

**Rules**:
- `DELETE WHERE DateID = @DateID` — removes only the target date's rows
- `INSERT FROM #final` — reloads the qualifying set for that date
- No rolling-window delete: rows from 2021-11-28 onward are retained permanently
- SP is rerunnable for the same date without duplication

### 2.4 Weekly Monday Schedule

**What**: SP_W_Mon (Weekly Monday) runs once per week, not daily.

**Impact**: DateID gaps between weekly runs are expected. The table has 225 distinct dates across 4.5 years — averaging approximately once per week. Queries checking "what dates are covered" should use `SELECT DISTINCT DateID` rather than assuming daily granularity.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**Distribution**: `HASH(CID)` — queries filtering or joining on CID will be well-distributed. Cross-CID aggregations (e.g., GROUP BY Regualtion) may cause data movement.

**Clustered Index**: `DateID ASC` — range queries on DateID benefit from the clustered index. The combination of HASH(CID) distribution and CLUSTERED INDEX(DateID) means CID-based and date-based queries are both supported efficiently.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Who are the high-value crypto customers this week? | `WHERE DateID = [latest]` + filter by Regualtion |
| How many qualifying customers by regulation? | `GROUP BY Regualtion` — note NULL Regualtion rows exist (~660 rows) |
| Which account managers handle the most high-value crypto customers? | `GROUP BY Account_Manager_Name ORDER BY COUNT(*) DESC` |
| Trend of qualifying customer count over time? | `GROUP BY DateID` — weekly steps, not daily |
| Are Warning-status customers flagged for escalation? | `WHERE PlayerStatus LIKE 'Warning%'` (trailing spaces — use RTRIM) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON t.CID = dc.RealCID | Join back to full customer dimension |
| BI_DB_dbo.BI_DB_PositionPnL | ON t.CID = p.CID AND t.DateID = p.DateID | Retrieve position details for qualifying customers |

### 3.4 Gotchas

- **Column typo — "Regualtion"**: Always spelled this way in DDL and SP. All queries must use this misspelling. `SELECT Regualtion` — never "Regulation".
- **Table name vs. scope**: Despite the name "FCA_Crypto_Threshold," the table includes FCA, CySEC, and ASIC-regulated customers. Do not assume FCA-only.
- **NULL Regualtion rows (~660)**: Approximately 660 rows have a NULL Regualtion value despite INNER JOINs in the SP. Source is unknown — possibly from historical runs before the third UNION branch was added, or from Dim_Regulation.Name being NULL for some regulation IDs. Exclude NULLs (`WHERE Regualtion IS NOT NULL`) if regulation-segmented reporting is required.
- **HasWallet is always 1**: The SP filters `dc.HasWallet = 1`, so every row has HasWallet=1. This column carries no discriminating information within this table.
- **PlayerStatus trailing spaces**: Live data shows "Warning" with trailing spaces. Apply `RTRIM(PlayerStatus)` for string comparisons.
- **Weekly cadence**: DateIDs have weekly gaps. Do not use this table for daily trend analysis.
- **Amount threshold currency**: The 80,000 threshold in the SP has no explicit currency label. It is applied to `BI_DB_PositionPnL.Amount` — confirm the currency denomination for cross-regulation threshold accuracy.
- **High-tier skew**: 99.2% of rows are Diamond (56.9%) or Platinum Plus (42.3%). Platinum and below are edge cases.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — upstream wiki verbatim | `(Tier 1 — ...)` |
| ★★★ | Tier 2 — SP code / ETL | `(Tier 2 — SP_W_Mon_AML_FCA_Crypto_Threshold)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Unique real customer identifier. Matches Dim_Customer.RealCID. Excludes test accounts and internal users. Derived from BI_DB_PositionPnL.CID confirmed via INNER JOIN ON ppnl.CID = dc.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | DateID | int | YES | Monitoring date as YYYYMMDD integer (e.g., 20260412 = 2026-04-12). Equals CONVERT(CHAR(8),@Date,112) from the SP's @Date parameter. Weekly Monday values only — daily gaps are expected. (Tier 2 — SP_W_Mon_AML_FCA_Crypto_Threshold) |
| 3 | PlayerStatus | varchar(50) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Values in this table: Normal, Warning. (Tier 1 — Dictionary.PlayerStatus) |
| 4 | Club | varchar(50) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. In this table, predominantly Diamond (56.9%) and Platinum Plus (42.3%) due to the high-value position filter. (Tier 1 — Dictionary.PlayerLevel) |
| 5 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. In this table always 1 — the SP requires dc.HasWallet = 1 as an eligibility criterion. (Tier 1 — BackOffice.Customer) |
| 6 | Account_Manager_Name | varchar(100) | YES | Full name of the assigned account manager. Computed as Dim_Manager.FirstName + ' ' + Dim_Manager.LastName. Reflects the manager assigned at the time of the weekly ETL run. (Tier 1 — BackOffice.Manager) |
| 7 | UpdateDate | datetime | NOT NULL | SP execution timestamp. Set to GETDATE() at the time SP_W_Mon_AML_FCA_Crypto_Threshold runs. Reflects ETL run time, not a business event date. (Tier 2 — SP_W_Mon_AML_FCA_Crypto_Threshold) |
| 8 | Regualtion [sic] | varchar(50) | YES | Short code for the regulation under which the customer is licensed. Used in V_Dim_Customer and analytics dashboards. CAUTION: column name is misspelled in DDL (missing 'a'). Values in this table: FCA, CySEC, ASIC, ASIC & GAML, and ~660 NULL rows. (Tier 1 — Dictionary.Regulation) |

---

## 5. Lineage

### 5.1 Column-Level Lineage

| Column | Source Object | Source Column | Transform |
|--------|---------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Passthrough; BI_DB_PositionPnL.CID ↔ Dim_Customer.RealCID via INNER JOIN |
| DateID | BI_DB_dbo.BI_DB_PositionPnL | DateID | Passthrough; equals SP @Date parameter as YYYYMMDD |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN: Dim_Customer.PlayerStatusID → Dim_PlayerStatus.Name |
| Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN: Dim_Customer.PlayerLevelID → Dim_PlayerLevel.Name |
| HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough; always 1 due to eligibility filter |
| Account_Manager_Name | DWH_dbo.Dim_Manager | FirstName, LastName | COMPUTED: `FirstName + ' ' + LastName` |
| UpdateDate | ETL | N/A | GETDATE() at SP execution |
| Regualtion [sic] | DWH_dbo.Dim_Regulation | Name | JOIN: Dim_Customer.RegulationID → Dim_Regulation.DWHRegulationID → Dim_Regulation.Name |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL
  [InstrumentTypeID=10 (Crypto), Amount>=80000, IsSettled=1, DateID=@DateID]
  ROW_NUMBER() OVER (PARTITION BY CID ORDER BY DateID) = 1  [deduplicate per CID]
    --> #cidpopulation

DWH_dbo.Dim_Customer  [IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3,
                        PlayerStatusID IN (1,5), HasWallet=1]
  UNION ALL three branches:
    RegulationID=2  (FCA)
    RegulationID=1  (CySEC)
    RegulationID IN (4,10)  (ASIC, ASIC+GAML)
DWH_dbo.Dim_Manager   --> Account_Manager_Name
DWH_dbo.Dim_PlayerLevel --> Club
DWH_dbo.Dim_PlayerStatus --> PlayerStatus
DWH_dbo.Dim_Regulation   --> Regualtion [sic]
    --> #final

  |-- SP_W_Mon_AML_FCA_Crypto_Threshold (@Date, weekly Monday) ---|
  |   Load: DELETE WHERE DateID=@DateID + INSERT FROM #final      |
  |   No rolling window — historical dates retained permanently   |
  v
BI_DB_dbo.BI_DB_AML_FCA_Crypto_Threshold
  60.9K rows | 1,186 distinct CIDs | 225 monitoring dates
  Date range: 2021-11-28 to 2026-04-12
  Regulation: FCA 53.6%, CySEC 40.1%, ASIC+GAML 5.1%, ASIC 0.2%
  Club: Diamond 56.9%, Platinum Plus 42.3%
```

---

## 6. Relationships

### 6.1 References To (upstream sources)

| Source Object | Join Condition | Columns Consumed |
|--------------|---------------|-----------------|
| BI_DB_dbo.BI_DB_PositionPnL | CID, DateID, InstrumentTypeID, Amount, IsSettled | CID, DateID (position base) |
| DWH_dbo.Dim_Instrument | InstrumentID | InstrumentTypeID=10 (Crypto filter) |
| DWH_dbo.Dim_Customer | RealCID | HasWallet, RegulationID, PlayerStatusID, PlayerLevelID, AccountManagerID, VerificationLevelID |
| DWH_dbo.Dim_Manager | ManagerID | FirstName, LastName → Account_Manager_Name |
| DWH_dbo.Dim_PlayerLevel | PlayerLevelID | Name → Club |
| DWH_dbo.Dim_PlayerStatus | PlayerStatusID | Name → PlayerStatus |
| DWH_dbo.Dim_Regulation | DWHRegulationID | Name → Regualtion [sic] |

### 6.2 Referenced By (known consumers)

No downstream BI_DB tables or SPs found in the SSDT repo that directly JOIN to this table. Primary consumers are AML compliance reports and dashboards.

---

## 7. Sample Queries

### 7.1 Latest monitoring date — all qualifying customers

```sql
SELECT
    t.CID,
    t.Regualtion,          -- note: misspelled in DDL
    t.Club,
    RTRIM(t.PlayerStatus)  AS PlayerStatus,
    t.Account_Manager_Name,
    t.HasWallet
FROM [BI_DB_dbo].[BI_DB_AML_FCA_Crypto_Threshold] t
WHERE t.DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_AML_FCA_Crypto_Threshold])
  AND t.Regualtion IS NOT NULL   -- exclude ~660 NULL Regulation rows
ORDER BY t.Club DESC, t.CID;
```

### 7.2 Count by regulation and tier on a specific monitoring date

```sql
SELECT
    RTRIM(t.Regualtion)        AS Regulation,
    t.Club,
    COUNT(*)                   AS CustomerCount
FROM [BI_DB_dbo].[BI_DB_AML_FCA_Crypto_Threshold] t
WHERE t.DateID = 20260412
  AND t.Regualtion IS NOT NULL
GROUP BY t.Regualtion, t.Club
ORDER BY Regulation, Club;
```

### 7.3 Weekly trend of qualifying customer count

```sql
SELECT
    t.DateID,
    COUNT(*)                   AS QualifyingCustomers,
    COUNT(DISTINCT t.Regualtion) AS RegulationCount
FROM [BI_DB_dbo].[BI_DB_AML_FCA_Crypto_Threshold] t
WHERE t.Regualtion IS NOT NULL
GROUP BY t.DateID
ORDER BY t.DateID DESC;
```

### 7.4 Account managers with most high-value crypto customers (latest date)

```sql
SELECT
    t.Account_Manager_Name,
    COUNT(DISTINCT t.CID) AS UniqueCustomers,
    t.Regualtion
FROM [BI_DB_dbo].[BI_DB_AML_FCA_Crypto_Threshold] t
WHERE t.DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_AML_FCA_Crypto_Threshold])
  AND t.Regualtion IS NOT NULL
GROUP BY t.Account_Manager_Name, t.Regualtion
ORDER BY UniqueCustomers DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-21 | Quality: 8.5/10 (★★★★☆) | Phases: 1–11, 16*
*Tiers: 6 T1, 2 T2, 0 T3, 0 T4 | Elements: 8/8 | UC Target: _Not_Migrated*
*Object: BI_DB_dbo.BI_DB_AML_FCA_Crypto_Threshold | Type: Table | Writer: SP_W_Mon_AML_FCA_Crypto_Threshold*
