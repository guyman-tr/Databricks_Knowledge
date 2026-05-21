# BI_DB_dbo.BI_DB_FCA_Liabilities

> Monthly FCA (UK) customer liabilities report table: 264 rows (Dec 2020 – Apr 2026), 4 rows per month segmented by customer validity and depositor status. Aggregates total eToro liabilities (real-money obligations) and crypto-real liabilities from DWH_dbo.V_Liabilities, filtered to FCA-regulated customers only (DWHRegulationID=2), refreshed daily via SP_FCA_Liabilities with a DELETE-per-EOM-month + INSERT pattern.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.V_Liabilities + DWH_dbo.Fact_SnapshotCustomer via SP_FCA_Liabilities |
| **Refresh** | Daily (SB_Daily, Priority 20); DELETE WHERE EOMONTH(Date,0)=current-month EOM + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 264 rows (4 rows/month × 66 months) |
| **Date Range** | 2020-12-31 to 2026-04-12 (current month in-progress) |

---

## 1. Business Meaning

`BI_DB_FCA_Liabilities` is a monthly FCA regulatory liabilities summary table. Each month contains exactly **4 rows** representing the cross-product of two customer segment flags:
- **IsValidCustomer** (0=invalid/demo, 1=valid retail) — matches IsCreditReportValidCB in all observed data
- **IsDepositor** (0=non-depositor, 1=has made at least one real deposit)

The table aggregates, per segment, the platform's total **customer liabilities** (what eToro owes customers in real money) and **crypto-real liabilities** (the crypto real-asset component), based on `DWH_dbo.V_Liabilities`. An additional metric, `Liabilities_Crypto_Only`, isolates customers whose total liabilities consist entirely of crypto-real assets.

**FCA scope**: The SP filters `Dim_Regulation WHERE DWHRegulationID = 2`, so the `Regulation` column is always `'FCA'`. This table covers only UK-regulated customers.

**Largest segment (Apr 2026 sample)**: IsValidCustomer=1, IsCreditReportValidCB=1, IsDepositor=1 → 1,028,430 customers, £4.67B total liabilities (bigint, USD cents). The `(0,0,True)` non-valid depositor segment has 106 customers — edge-case accounts.

**Use case**: FCA regulatory reporting, monthly liability disclosures, and monitoring of crypto-real vs. non-crypto customer balance composition under UK regulation.

---

## 2. Business Logic

### 2.1 Segment Matrix (4 fixed combinations per month)

**What**: Each month has exactly 4 rows representing customer segments.
**Columns Involved**: `IsValidCustomer`, `IsCreditReportValidCB`, `IsDepositor`
**Rules**:
- `IsValidCustomer = IsCreditReportValidCB` in all observed data — they always match (both 0 or both 1)
- Segment (1, 1, True) = valid retail depositors — primary regulatory population (~1M customers, £4B+ liabilities)
- Segment (1, 1, False) = valid retail non-depositors (~10K customers, small liabilities)
- Segment (0, 0, True) = non-valid depositors (edge cases, ~100 customers)
- Segment (0, 0, False) = non-valid non-depositors (~35 customers, minimal liabilities)

### 2.2 Crypto-Only Isolation Logic

**What**: Identifies customers whose liabilities are exclusively from crypto real assets.
**Columns Involved**: `Total_CIDs_Liabilities_Crypto_Only`, `Liabilities_Crypto_Only`, `Liabilities`, `LiabilitiesCryptoReal`
**Rules**:
- A customer is "crypto-only" when `Liabilities - LiabilitiesCryptoReal = 0` (no non-crypto liabilities)
- For the primary depositor segment (Apr 2026): ~97K of 1M FCA customers are crypto-only (~9.4%)
- `Liabilities_Crypto_Only` sums their crypto balances (~£170M out of £1.5B crypto-real total)

### 2.3 Refresh Pattern

**What**: Monthly DELETE-per-EOM + INSERT, refreshed daily.
**Columns Involved**: `EOM`, `Date`, `UpdateDate`
**Rules**:
- SP accepts @Date parameter and computes EOM = EOMONTH(@Date, 0)
- DELETE removes all rows WHERE EOMONTH(Date,0) = current month's EOM before re-inserting
- This allows intra-month updates — the table always reflects the latest day of the current month
- End-of-month rows capture the final monthly figures (one EOM row per month from prior months)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on DateID. With only 264 rows total (4/month), this is a tiny reference table — no performance concerns. DateID ordering enables efficient range scans by month.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| End-of-month liabilities for all FCA customers | `WHERE IsValidCustomer=1 AND DateID = EOMONTH(date, 0)` |
| Valid depositor liabilities only | `WHERE IsValidCustomer=1 AND IsDepositor=1` |
| Crypto-only customer count by month | `SELECT Date, Total_CIDs_Liabilities_Crypto_Only WHERE IsValidCustomer=1 AND IsDepositor=1` |
| Trend of total FCA liabilities | `SELECT Date, SUM(Liabilities) GROUP BY Date ORDER BY Date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Regulation | `Regulation = dr.Name` | Validate regulation name (always 'FCA') |
| BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | `DateID` | Cross-reference with broader balance aggregate |

### 3.4 Gotchas

- **Regulation always 'FCA'**: The SP hard-filters `DWHRegulationID = 2`. Do not expect multi-regulation data — use V_Liabilities directly for other regulations.
- **IsValidCustomer = IsCreditReportValidCB always**: In all 264 rows, these two flags are identical. Filtering on either one is sufficient.
- **Liabilities are bigint (USD cents?)**: V_Liabilities values are large integers. Validate the unit before reporting (total for valid depositors is ~4.7 billion, which suggests USD or pence-level precision).
- **Current-month Date ≠ EOM**: The `Date` column for the current month is the most recent run date (e.g., 2026-04-12), while `EOM` is 2026-04-30. Prior months have Date = EOM.
- **Table has no CID column**: This is a pre-aggregated summary — no customer-level detail. Use V_Liabilities directly for CID-level queries.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream DWH_dbo wiki (canonical source) |
| Tier 2 | Description derived from SP code, DDL, or ETL logic (high confidence) |
| Tier 3 | Description inferred from column name, data patterns (medium confidence) |
| Tier 4 | Description speculative — needs business SME review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | EOM | date | YES | End-of-month date for the reporting period. EOMONTH(@Date, 0) computed at ETL run time. For completed months, Date = EOM; for the current month, EOM = month end while Date = last run date. (Tier 2 — SP_FCA_Liabilities) |
| 2 | Date | date | YES | The ETL run date (@Date parameter). For prior months, equals EOM. For the current month, equals the most recent daily run date. Used in the DELETE WHERE EOMONTH(Date,0) = current-month pattern. (Tier 2 — SP_FCA_Liabilities) |
| 3 | DateID | int | YES | Integer representation of Date in YYYYMMDD format. Cluster key. Used for range scans and joins to date dimension. (Tier 2 — SP_FCA_Liabilities) |
| 4 | Regulation | varchar(50) | YES | FCA regulatory jurisdiction name from Dim_Regulation. Always 'FCA' — SP filters Dim_Regulation WHERE DWHRegulationID = 2 (UK FCA). (Tier 2 — SP_FCA_Liabilities) |
| 5 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 6 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 7 | IsDepositor | bit | YES | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 8 | Total_CIDs | bigint | YES | Count of distinct FCA customers in this segment for the given date. Computed as COUNT(vl.CID) from V_Liabilities WHERE Liabilities <> 0. (Tier 2 — SP_FCA_Liabilities) |
| 9 | Liabilities | bigint | YES | Sum of total customer liabilities (real-money obligations eToro owes customers) for this segment. SUM(ISNULL(vl.Liabilities, 0)) from DWH_dbo.V_Liabilities. Excludes customers with zero liabilities. Formula: InProcessCashouts + MAX(NetEquity - BonusCredit, 0). (Tier 2 — SP_FCA_Liabilities) |
| 10 | LiabilitiesCryptoReal | bigint | YES | Sum of crypto real-asset liabilities for this segment. SUM(ISNULL(vl.LiabilitiesCryptoReal, 0)) from V_Liabilities. Formula: PositionPnLCryptoReal + TotalRealCrypto. Represents the real (non-CFD) crypto portion of total liabilities. (Tier 2 — SP_FCA_Liabilities) |
| 11 | Total_CIDs_Liabilities_Crypto_Only | bigint | YES | Count of customers in this segment whose liabilities are entirely composed of crypto-real assets — i.e., Liabilities - LiabilitiesCryptoReal = 0. Identifies customers with zero non-crypto liability exposure. (Tier 2 — SP_FCA_Liabilities) |
| 12 | Liabilities_Crypto_Only | bigint | YES | Sum of LiabilitiesCryptoReal for customers who are crypto-only (Liabilities - LiabilitiesCryptoReal = 0). Represents total crypto-real liabilities of pure-crypto customers within this segment. (Tier 2 — SP_FCA_Liabilities) |
| 13 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 — SP_FCA_Liabilities) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | GROUP BY passthrough |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | GROUP BY passthrough |
| IsDepositor | DWH_dbo.Fact_SnapshotCustomer | IsDepositor | GROUP BY passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | WHERE DWHRegulationID=2 (always 'FCA') |
| Liabilities | DWH_dbo.V_Liabilities | Liabilities | SUM per segment |
| LiabilitiesCryptoReal | DWH_dbo.V_Liabilities | LiabilitiesCryptoReal | SUM per segment |
| Total_CIDs | DWH_dbo.V_Liabilities | CID | COUNT per segment |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer, IsCreditReportValidCB, IsDepositor, RegulationID)
  + DWH_dbo.Dim_Range (SCD2 bridge: @DateID BETWEEN FromDateID AND ToDateID)
  + DWH_dbo.Dim_Regulation (DWHRegulationID=2 → 'FCA' name)
  + DWH_dbo.V_Liabilities (Liabilities, LiabilitiesCryptoReal per CID per DateID)
    |-- SP_FCA_Liabilities @Date (daily SB_Daily Priority 20) ---|
    |   DELETE WHERE EOMONTH(Date,0) = EOMONTH(@Date,0)          |
    |   INSERT 4-row segment aggregate                            |
    v
BI_DB_dbo.BI_DB_FCA_Liabilities
  (264 rows, 4 rows/month, Dec 2020 – Apr 2026)
  UC Target: Not Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Regulation | DWH_dbo.Dim_Regulation | UK FCA regulation name (DWHRegulationID=2) |
| IsValidCustomer, IsCreditReportValidCB, IsDepositor | DWH_dbo.Fact_SnapshotCustomer | Customer segment dimensions |
| Liabilities, LiabilitiesCryptoReal | DWH_dbo.V_Liabilities | Aggregated from daily CID-level liabilities view |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in OpsDB dependency scan. This table appears to be a terminal regulatory reporting artifact consumed directly by FCA reporting processes.

---

## 7. Sample Queries

### Monthly FCA Liabilities Trend (Valid Depositors)

```sql
SELECT Date, EOM,
       Total_CIDs,
       Liabilities,
       LiabilitiesCryptoReal,
       CAST(LiabilitiesCryptoReal AS float) / NULLIF(Liabilities, 0) AS CryptoRealPct,
       Total_CIDs_Liabilities_Crypto_Only,
       Liabilities_Crypto_Only
FROM [BI_DB_dbo].[BI_DB_FCA_Liabilities]
WHERE IsValidCustomer = 1
  AND IsDepositor = 1
ORDER BY DateID DESC;
```

### End-of-Month Snapshots Only

```sql
SELECT EOM, Date, Regulation,
       SUM(Total_CIDs) AS Total_Customers,
       SUM(Liabilities) AS Total_Liabilities,
       SUM(LiabilitiesCryptoReal) AS Total_Crypto_Liabilities
FROM [BI_DB_dbo].[BI_DB_FCA_Liabilities]
WHERE Date = EOM  -- end-of-month rows only
GROUP BY EOM, Date, Regulation
ORDER BY EOM DESC;
```

### Crypto-Only Customer Tracking

```sql
SELECT Date,
       Total_CIDs_Liabilities_Crypto_Only AS CryptoOnlyCIDs,
       Liabilities_Crypto_Only AS CryptoOnlyLiabilities,
       CAST(Total_CIDs_Liabilities_Crypto_Only AS float) / NULLIF(Total_CIDs, 0) AS CryptoOnlyPct
FROM [BI_DB_dbo].[BI_DB_FCA_Liabilities]
WHERE IsValidCustomer = 1 AND IsDepositor = 1
ORDER BY DateID DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this table. FCA regulatory context is documented in the V_Liabilities wiki (DWH_dbo) and Confluence "Summary of V-Liabilities" article.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 3 T1, 10 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 8/10, Evidence: 9/10*
*Object: BI_DB_dbo.BI_DB_FCA_Liabilities | Type: Table | Production Source: SP_FCA_Liabilities via DWH_dbo.V_Liabilities*
