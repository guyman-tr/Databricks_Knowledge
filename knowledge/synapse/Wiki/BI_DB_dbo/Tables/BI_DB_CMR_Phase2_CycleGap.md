# BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap

## 1. Business Meaning

Daily cycle gap summary for client money reconciliation, split by regulation group (ASIC vs. EU) and gap category (standard cycle gap vs. outlier gap). Each row represents the net daily balance cycle gap for one GapCategory x Regulation group on a given date.

A "cycle gap" is the difference between a customer's closing balance and the expected closing balance derived from all balance movement components (OpeningBalance + all inflows + all adjustments - outflows). Non-zero gaps indicate reconciliation discrepancies. This table is a Finance exception tracking tool -- it only contains rows for dates and regulation groups where a non-zero gap exists.

The table summarizes data from `BI_DB_CB_CycleGap_Categorization` (CBCGC), which stores the individual CID-level gaps. The CMR Phase2 CycleGap table aggregates these to the regulation-group level for reporting.

- **1,209 rows** across **927 dates** (2022-01-03 to 2026-04-10)
- **All rows have non-zero Gap** -- this is an exception table; zero-gap dates produce no rows
- **2 GapCategories**: 'As per Cycle Gap' (standard reconciliation), 'As per Outliers' (outlier transitions)
- **2 Regulations**: 'ASIC' (covers ASIC and ASIC & GAML), 'EU' (covers CySEC, BVI, NFA, None)
- Outlier gaps are significantly larger in magnitude (avg $2M ASIC, $14.6M EU) vs. cycle gaps (avg $600 ASIC, $1.8K EU)
- UC Target: _Not_Migrated

---

## 2. Business Logic

### Source
`BI_DB_CB_CycleGap_Categorization` (CBCGC) stores customer-level (CID) daily balance cycle gap data. The SP self-joins CBCGC on `CID WHERE a.DailyCBGap = -b.DailyCBGap` to identify customers whose gap on one date is offset by a gap of equal magnitude on another date (OutlierTransition flag).

### Gap Calculation
```
Cycle Gap (per CID) = CASE
    WHEN OutlierCycleCalculation <> 0 THEN OutlierCycleCalculation
    ELSE ClosingBalance - CycleCalculation
  END

Gap (stored) = SUM(Cycle Gap per CID) for the regulation group
```

### GapCategory Split
| GapCategory | Filter | Meaning |
|------------|--------|---------|
| 'As per Cycle Gap' | OutlierTransition = '0' AND IsCreditReportValidCB = 1 | Standard cycle gap for credit-valid customers; no outlier transition |
| 'As per Outliers' | OutlierTransition <> '0' | Customers with an offsetting gap on another date (entering or exiting a gap) |

### Regulation Groups
| Stored Regulation | Source Regulations |
|-------------------|--------------------|
| 'ASIC' | 'ASIC', 'ASIC & GAML' |
| 'EU' | 'CySEC', 'BVI', 'NFA', 'None' |

Note: These are not the same Regulation values as used in other CMR Phase2 tables. The CycleGap table uses broader groupings rather than the individual regulation entity names.

---

## 3. Query Advisory

### Distribution
- ROUND_ROBIN distribution; no skew risk.
- CLUSTERED INDEX on `DateID ASC` -- use DateID in WHERE predicates.
- Small table (1,209 rows total); full scans are acceptable.

### Typical Access Patterns
- JOIN to other CMR Phase2 tables on Date (not Regulation -- the Regulation groupings differ).
- Query by DateID range to trend gaps over time.
- Filter GapCategory to separate standard from outlier contributions.

### Known Gotchas
1. **Regulation labels are aggregation groups, not entity names.** 'ASIC' covers both 'ASIC' and 'ASIC & GAML' source customers. 'EU' covers 'CySEC', 'BVI', 'NFA', and 'None'. These do NOT match the Regulation values in BI_DB_CMR_Phase2_ClientBalance.
2. **No rows = zero gap.** Dates without a gap row for a given Regulation/GapCategory have Gap = 0. The table only stores non-zero exceptions.
3. **IsCreditReportValidCB filter applies only to 'As per Cycle Gap'.** The 'As per Outliers' branch does not filter on IsCreditReportValidCB. Customers without a valid credit report only appear in the Outlier category.
4. **'As per Outliers' rows have much larger magnitudes.** Outlier gaps represent customers with an offsetting gap on another date -- these can be large even if the standard cycle gap is small.
5. **Sparsely populated.** At ~1.3 rows per date on average, most days have only 1-3 rows.

---

## 4. Elements

| # | Column | Type | Nullable | PK | Description | Tier |
|---|--------|------|----------|----|-------------|------|
| 1 | DateID | int | YES | -- | Integer date key (YYYYMMDD). Clustered index key. Passthrough from BI_DB_CB_CycleGap_Categorization. | Tier 2 |
| 2 | Date | date | YES | -- | Calendar date. Derived as CONVERT(date, convert(varchar(10), DateID)). Matches @date SP parameter. | Tier 2 |
| 3 | GapCategory | varchar(200) | YES | -- | Gap classification: 'As per Cycle Gap' (standard reconciliation, OutlierTransition = 0) or 'As per Outliers' (offsetting gap transition, OutlierTransition <> 0). Hardcoded in SP. | Tier 2 |
| 4 | Regulation | varchar(200) | YES | -- | Regulatory group: 'ASIC' (covers ASIC and ASIC & GAML source records) or 'EU' (covers CySEC, BVI, NFA, None source records). Hardcoded in SP -- different from Regulation values in other CMR tables. | Tier 2 |
| 5 | Gap | decimal(38,8) | YES | -- | Net cycle gap for this date x GapCategory x Regulation group. SUM(OutlierCycleCalculation OR ClosingBalance - CycleCalculation) from CBCGC. Non-zero in all stored rows. Can be negative. | Tier 2 |
| 6 | UpdateDate | datetime | YES | -- | ETL load timestamp. GETDATE() at INSERT time. | Propagation |

---

## 5. Lineage

See: [BI_DB_CMR_Phase2_CycleGap.lineage.md](BI_DB_CMR_Phase2_CycleGap.lineage.md)

**Writer SP**: `BI_DB_dbo.SP_CMR_Phase2_CycleGap`
**Refresh**: Daily (OpsDB Priority 15)
**Load Pattern**: DELETE WHERE Date = @date + INSERT

### Source Objects
| Source | Role |
|--------|------|
| `BI_DB_dbo.BI_DB_CB_CycleGap_Categorization` | Sole source; CID-level cycle gap, outlier classification, closing balance |

### Pipeline
```
BI_DB_dbo.BI_DB_CB_CycleGap_Categorization (DateID = @dateID)
  SELF-JOIN on CID where DailyCBGap = -DailyCBGap (offsetting gap detection)
  4 UNION branches: ASIC/EU x As per Cycle Gap/As per Outliers
  SUM(Cycle Gap) per regulation group

SP_CMR_Phase2_CycleGap(@date)
  DELETE FROM BI_DB_CMR_Phase2_CycleGap WHERE Date = @date
  INSERT INTO BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap
```

---

## 6. Relationships

| Related Object | Relationship | Notes |
|---------------|-------------|-------|
| `BI_DB_dbo.BI_DB_CB_CycleGap_Categorization` | Source (sole upstream) | CID-level daily cycle gap data |
| `BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance` | Sibling (same CMR suite) | ClientBalance vertical metrics; Regulation values differ (entity names vs. groups) |
| `BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers` | Sibling (same CMR suite) | EU-specific outlier movement metrics |
| `BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap` | Sibling (same CMR suite) | FINRA-specific gap metrics |
| `BI_DB_dbo.BI_DB_CycleGap` | Upstream aggregate | Broader cycle gap table (likely predecessor or related control table) |

---

## 7. Sample Queries

### Trend of total gap by regulation group (last 90 days)
```sql
SELECT
    Date,
    Regulation,
    GapCategory,
    Gap
FROM BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap
WHERE Date >= DATEADD(day, -90, GETDATE())
ORDER BY Date DESC, Regulation, GapCategory;
```

### Days with outlier gaps exceeding $1M (EU)
```sql
SELECT
    Date,
    Regulation,
    GapCategory,
    Gap
FROM BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap
WHERE GapCategory = 'As per Outliers'
  AND Regulation = 'EU'
  AND ABS(Gap) > 1000000
ORDER BY ABS(Gap) DESC;
```

### Total gap exposure by month (all categories combined)
```sql
SELECT
    DATEFROMPARTS(YEAR(Date), MONTH(Date), 1) AS MonthStart,
    Regulation,
    SUM(Gap) AS TotalGap
FROM BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap
GROUP BY DATEFROMPARTS(YEAR(Date), MONTH(Date), 1), Regulation
ORDER BY MonthStart DESC, Regulation;
```

---

## 8. Atlassian Knowledge

No Confluence or Jira sources found for this table. Business context derived from SP code analysis and data sampling.
