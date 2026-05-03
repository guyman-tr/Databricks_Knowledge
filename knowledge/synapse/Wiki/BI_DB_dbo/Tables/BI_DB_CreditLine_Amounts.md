# BI_DB_dbo.BI_DB_CreditLine_Amounts

> 13-row static reference table mapping credit line dollar thresholds (500–260,000) to monthly fee costs (3–165). Used as a fee schedule lookup by SP_Daily_CreditLine to populate MonthlyTableFeeCost in BI_DB_Daily_CreditLine. Manually maintained — no ETL SP writes to this table. Production Source: Unknown (dormant/manual).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — static reference data, no writer SP found. Originally hardcoded in SP_Daily_CreditLine (table variable `@Tablefee`), later externalized to this table. |
| **Refresh** | Manual / ad-hoc — no scheduled ETL populates this table |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CreditLine ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Static reference lookup |

---

## 1. Business Meaning

BI_DB_CreditLine_Amounts is a small, static fee schedule table containing 13 rows. Each row maps a specific credit line dollar amount to its associated monthly fee cost. The table serves as a lookup for SP_Daily_CreditLine, which LEFT JOINs it on `TotalCLAmount = CreditLine` to determine the `MonthlyTableFeeCost` written into BI_DB_Daily_CreditLine.

The credit line thresholds range from $500 to $260,000, with corresponding monthly costs ranging from $3 to $165. The relationship between credit line amount and cost is non-linear — lower tiers (500–1,500) share a flat $3 cost, while higher tiers scale roughly proportionally.

No stored procedure writes to this table. Historical SP code (commented-out lines 74–88 in SP_Daily_CreditLine) shows these values were originally hardcoded in a `@Tablefee` table variable, later externalized to this persistent table for easier maintenance. The `UpdateDate` column exists but is never populated (all NULL across all 13 rows).

---

## 2. Business Logic

### 2.1 Credit Line Fee Schedule

**What**: Maps credit line amount thresholds to monthly fee costs.
**Columns Involved**: CreditLine, Cost
**Rules**:
- Each CreditLine value is a discrete threshold (not a range) — the join in SP_Daily_CreditLine is an exact match (`TotalCLAmount = t.CreditLine`), not a range lookup.
- If a customer's TotalCLAmount does not exactly match a CreditLine value, the LEFT JOIN returns NULL for Cost (no fee assigned).
- The fee tiers are: 500=$3, 750=$3, 1500=$3, 3000=$5, 6000=$8, 10000=$12, 15000=$14, 30000=$22, 60000=$38, 90000=$54, 120000=$72, 180000=$108, 260000=$165.

### 2.2 UpdateDate Tracking (Unused)

**What**: Placeholder for row modification timestamps.
**Columns Involved**: UpdateDate
**Rules**:
- All 13 rows have NULL UpdateDate — the column is never written to by any known process.
- SP_Daily_CreditLine uses `GETDATE()` for UpdateDate when writing to BI_DB_Daily_CreditLine, not to this table.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — appropriate for a 13-row static table where distribution skew is irrelevant.
- **Index**: CLUSTERED INDEX on CreditLine ASC — supports the exact-match join from SP_Daily_CreditLine.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| What fee applies to a given credit line amount? | `SELECT * FROM BI_DB_dbo.BI_DB_CreditLine_Amounts WHERE CreditLine = {amount}` |
| List all fee tiers | `SELECT * FROM BI_DB_dbo.BI_DB_CreditLine_Amounts ORDER BY CreditLine` |
| What is the maximum credit line supported? | `SELECT MAX(CreditLine) FROM BI_DB_dbo.BI_DB_CreditLine_Amounts` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| BI_DB_dbo.BI_DB_Daily_CreditLine | `ON TotalCLAmount = CreditLine` | Look up monthly fee cost for a customer's credit line balance (via SP_Daily_CreditLine) |

### 3.4 Gotchas

- **Exact match only**: The join is on exact CreditLine value, not a range. Credit line amounts not in this table yield NULL cost.
- **UpdateDate is always NULL**: Do not filter or sort by UpdateDate — it contains no data.
- **Manual maintenance**: Changes to fee tiers require manual INSERT/UPDATE/DELETE — there is no automated refresh.
- **No 260,000+ tier**: The highest tier is 260,000. Credit lines above this amount have no fee mapping.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | No upstream source traceable — grounded in DDL + SP analysis |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CreditLine | int | YES | Credit line dollar amount threshold used as a lookup key. Discrete values (500, 750, 1500, 3000, 6000, 10000, 15000, 30000, 60000, 90000, 120000, 180000, 260000) joined by SP_Daily_CreditLine on exact match to TotalCLAmount. Static reference data — no SP populates this table. (Tier 3 — no upstream; static manual reference) |
| 2 | Cost | int | YES | Monthly fee cost in dollars associated with the credit line tier. Ranges from 3 (for credit lines 500–1,500) to 165 (for 260,000). Read by SP_Daily_CreditLine as MonthlyTableFeeCost and written to BI_DB_Daily_CreditLine. Static reference data — no SP populates this table. (Tier 3 — no upstream; static manual reference) |
| 3 | UpdateDate | datetime | YES | Timestamp placeholder for row modification date. Currently NULL across all 13 rows — never written by any known process. SP_Daily_CreditLine uses GETDATE() for BI_DB_Daily_CreditLine.UpdateDate, not for this table. (Tier 3 — no upstream; static manual reference) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| CreditLine | Unknown (manual) | — | Static reference data, originally hardcoded in SP_Daily_CreditLine |
| Cost | Unknown (manual) | — | Static reference data, originally hardcoded in SP_Daily_CreditLine |
| UpdateDate | Unknown (manual) | — | Placeholder, never populated |

### 5.2 ETL Pipeline

```
[Manual / ad-hoc data entry]
  |
  v
BI_DB_dbo.BI_DB_CreditLine_Amounts (13 rows, static lookup)
  |-- SP_Daily_CreditLine LEFT JOIN on CreditLine = TotalCLAmount ---|
  v
BI_DB_dbo.BI_DB_Daily_CreditLine (receives Cost AS MonthlyTableFeeCost)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

_None — this is a standalone static reference table._

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|----------------|-------------|
| CreditLine | BI_DB_dbo.SP_Daily_CreditLine | LEFT JOIN on `TotalCLAmount = CreditLine` to look up monthly fee cost |
| Cost | BI_DB_dbo.BI_DB_Daily_CreditLine | Written as `MonthlyTableFeeCost` column via SP_Daily_CreditLine |

---

## 7. Sample Queries

### 7.1 View the Complete Fee Schedule

```sql
SELECT CreditLine, Cost
FROM BI_DB_dbo.BI_DB_CreditLine_Amounts
ORDER BY CreditLine;
```

### 7.2 Find the Fee for a Specific Credit Line Amount

```sql
SELECT Cost AS MonthlyFeeCost
FROM BI_DB_dbo.BI_DB_CreditLine_Amounts
WHERE CreditLine = 10000;
```

### 7.3 Join to Daily Credit Line to See Fee Assignments

```sql
SELECT d.RealCID, d.TotalCLAmount, t.Cost AS MonthlyTableFeeCost, d.Date
FROM BI_DB_dbo.BI_DB_Daily_CreditLine d
LEFT JOIN BI_DB_dbo.BI_DB_CreditLine_Amounts t
  ON d.TotalCLAmount = t.CreditLine
WHERE d.DateID = 20260429
ORDER BY d.TotalCLAmount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this static reference table.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 3 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 6/10, Lineage: 6/10*
*Object: BI_DB_dbo.BI_DB_CreditLine_Amounts | Type: Table | Production Source: Unknown (dormant/manual)*
