# BI_DB_dbo.BI_DB_VAT_Transactions

> 101K-row monthly VAT transaction count aggregation table tracking position open and close events by regulation, country, and settlement status from 2019-01 to present. Used for regulatory VAT reporting across 14 regulation codes and ~130 countries. DELETE+INSERT by Month via SP_VAT_Transaction.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + Fact_CustomerAction + Fact_SnapshotCustomer + Dim_Range + Dim_Regulation + Dim_Country via `SP_VAT_Transaction` |
| **Refresh** | Daily (DELETE WHERE Month=@EndMonth + INSERT — overwrites current month) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Month ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | — |
| **Row Count** | ~101,495 (as of 2026-04-27) |

---

## 1. Business Meaning

`BI_DB_VAT_Transactions` is a monthly aggregation table counting trading positions opened and closed by regulation entity, country, and settlement status for VAT (Value Added Tax) reporting purposes.

Each row represents a unique combination of Month + IsSettled + Regulation + Country, with a Transactions count of positions opened or closed in that month. The SP builds two subqueries:
1. **Open positions**: Dim_Position WHERE OpenDateID >= @StartMonthID, joined with Fact_CustomerAction (ActionTypeID IN (1,2,3,39)) on PositionID and OpenDateID
2. **Close positions**: Dim_Position WHERE CloseDateID >= @StartMonthID, same CustomerAction join on CloseDateID

Both subqueries filter to customers with IsCreditReportValidCB=1 in Fact_SnapshotCustomer and validate position dates against Dim_Range (DateRangeID mapping). The UNION ALL result is then grouped by IsSettled, Regulation (from Dim_Regulation.Name), and Country (from Dim_Country.Name).

ActionTypeID filter values: 1=Open Position, 2=Close Position, 3=Partial Close, 39 (likely a specialized action type). Partial close children (IsPartialCloseChild=1) are excluded from open position counts.

As of 2026-04-27: 101K rows spanning 2019-01 to 2026-04. 14 regulation codes (CySEC 24%, FCA 21%, ASIC & GAML 21%). IsSettled distribution: 1 (settled) 50%, 0 (unsettled) 49%, -1 (other) 1%.

---

## 2. Business Logic

### 2.1 Transaction Counting

**What**: Counts position open and close events separately and unions them into a single transaction count.
**Columns Involved**: `Transactions`
**Rules**:
- Open positions: COUNT(PositionID) WHERE OpenDateID >= @StartMonthID AND IsPartialCloseChild=0
- Close positions: COUNT(PositionID) WHERE CloseDateID >= @StartMonthID
- Both filtered by ActionTypeID IN (1,2,3,39) and IsCreditReportValidCB=1
- Final Transactions = SUM of both counts, grouped by IsSettled + Regulation + Country

### 2.2 Credit Report Validation

**What**: Only customers with valid credit report status are included.
**Columns Involved**: All (filter applied globally)
**Rules**:
- Fact_SnapshotCustomer.IsCreditReportValidCB=1 — must be a valid credit report customer
- Date range validation: position dates must fall within Dim_Range.FromDateID to ToDateID for the customer's DateRangeID

### 2.3 Settlement Status

**What**: Classifies transactions by settlement status.
**Columns Involved**: `IsSettled`
**Rules**:
- From Fact_CustomerAction.IsSettled
- 1 = settled (50% of rows), 0 = unsettled (49%), -1 = other/unknown (1%)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Month — efficient for monthly reporting queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly VAT transactions by regulation | `SELECT Month, Regulation, SUM(Transactions) GROUP BY Month, Regulation ORDER BY Month DESC` |
| Settled vs unsettled by country | `SELECT Country, IsSettled, SUM(Transactions) GROUP BY Country, IsSettled` |
| Year-over-year comparison | `WHERE YEAR(Month) IN (2025, 2026) GROUP BY YEAR(Month), Regulation` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Regulation | `Regulation = Name` | Regulation details |
| DWH_dbo.Dim_Country | `Country = Name` | Country details and additional geography |

### 3.4 Gotchas

- **Month is end-of-month date**: Always the last day of the month (e.g., 2026-04-30), not the first. Use EOMONTH() for joins.
- **IsSettled has 3 values**: 1, 0, and -1. The -1 value is rare (1% of rows) — verify its meaning with the business team.
- **Transactions can be very large**: Total across all rows exceeds 21 billion. Individual rows can have millions of transactions.
- **Overwrites current month daily**: Each run deletes and re-inserts the current month's data. Only the most recent run is authoritative for the current month.
- **Grain**: One row per Month + IsSettled + Regulation + Country combination. Not per-position.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Month | date | YES | Reporting month end date. EOMONTH(@Date) — always the last day of the month (e.g., 2026-04-30). Clustered index key. (Tier 2 — SP_VAT_Transaction) |
| 2 | IsSettled | int | YES | Settlement status from Fact_CustomerAction. 1=settled, 0=unsettled, -1=other/unknown. Indicates whether the trading position was settled at the time of the action. (Tier 2 — SP_VAT_Transaction) |
| 3 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation. 14 distinct values: CySEC, FCA, ASIC & GAML, ASIC, FSA Seychelles, BVI, FSRA, FinCEN, None, eToroUS, FinCEN+FINRA, MAS, NYDFS+FINRA, NFA. (Tier 1 — Dictionary.Regulation) |
| 4 | Transactions | int | YES | Count of position open and close events for this Month + Regulation + Country + IsSettled combination. SUM of COUNT(PositionID) across open positions (OpenDateID in month) and close positions (CloseDateID in month) from Dim_Position. Excludes partial close children. (Tier 2 — SP_VAT_Transaction) |
| 5 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |
| 6 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Month | — | — | ETL-computed: EOMONTH(@Date) |
| IsSettled | DWH_dbo.Fact_CustomerAction | IsSettled | Passthrough (filtered to ActionTypeID IN (1,2,3,39)) |
| Regulation | etoro.Dictionary.Regulation | Name | Dim-lookup via Dim_Regulation on RegulationID |
| Transactions | DWH_dbo.Dim_Position | PositionID | SUM(COUNT) across open + close events |
| UpdateDate | — | — | ETL-computed (GETDATE()) |
| Country | etoro.Dictionary.Country | Name | Dim-lookup via Dim_Country on CountryID |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (positions opened + closed in @Month)
  + Fact_SnapshotCustomer (IsCreditReportValidCB=1, RegulationID, CountryID)
  + Dim_Range (date range validation)
  + Fact_CustomerAction (ActionTypeID IN (1,2,3,39), IsSettled)
  |
  UNION ALL (open + close position counts)
  |
  + Dim_Regulation (RegulationID → Name)
  + Dim_Country (CountryID → Name)
  |
  GROUP BY IsSettled, Regulation, Country
  |
  |-- SP_VAT_Transaction @Date ---|
  |-- DELETE WHERE Month = EOMONTH(@Date) + INSERT ---|
  v
BI_DB_dbo.BI_DB_VAT_Transactions (~101K rows, monthly grain)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Regulation | DWH_dbo.Dim_Regulation.Name | Regulation entity name |
| Country | DWH_dbo.Dim_Country.Name | Country name |

### 6.2 Referenced By (other objects point to this)

No known consumer tables or views reference this table directly.

---

## 7. Sample Queries

### 7.1 Monthly VAT Summary by Regulation

```sql
SELECT
    Month,
    Regulation,
    IsSettled,
    SUM(Transactions) AS total_transactions
FROM [BI_DB_dbo].[BI_DB_VAT_Transactions]
WHERE Month >= '2026-01-31'
GROUP BY Month, Regulation, IsSettled
ORDER BY Month DESC, total_transactions DESC
```

### 7.2 Top Countries by Transaction Volume

```sql
SELECT
    Country,
    SUM(CAST(Transactions AS BIGINT)) AS total_transactions,
    COUNT(DISTINCT Month) AS months_active
FROM [BI_DB_dbo].[BI_DB_VAT_Transactions]
WHERE YEAR(Month) = 2025
GROUP BY Country
ORDER BY total_transactions DESC
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4, 1 T5 | Elements: 6/6, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_VAT_Transactions | Type: Table | Production Source: Dim_Position + Fact_CustomerAction via SP_VAT_Transaction*
