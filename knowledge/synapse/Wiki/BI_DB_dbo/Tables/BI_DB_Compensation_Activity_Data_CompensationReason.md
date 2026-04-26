# BI_DB_dbo.BI_DB_Compensation_Activity_Data_CompensationReason

> 916-row previous-month compensation extract for FCA-regulated customers who received technical problem refunds or satisfaction bonuses — powers compensation activity reporting for the FCA regulatory entity.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction + Dim_CompensationReason via SP_Compensation_Activity_Data |
| **Refresh** | Monthly — TRUNCATE + INSERT; scope = previous calendar month (computed from GETDATE()) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Lior Ben Dor (2021-07-12) |

---

## 1. Business Meaning

This table is a **previous-month compensation activity extract** scoped to FCA-regulated customers. Each row represents one compensation event — a credit or debit applied to an FCA customer's account for a specific reason such as a technical problem refund or satisfaction gesture. The table is populated once per ETL run by `SP_Compensation_Activity_Data`, which truncates and reloads data for the previous calendar month (e.g., a run on any date in April 2026 populates March 2026 events).

The table covers only a subset of compensation reason IDs (3, 26, 125, 126, 127, 128) representing technical problems and satisfaction bonuses — not all compensation types. It excludes non-FCA regulations entirely.

As of 2026-04-13 (covering March 2026): **916 rows** across 4 reason types. CompensationReason distribution: Technical Problems Crypto 80.5% (737), Technical Problems Non Crypto 13.2% (121), Satisfaction Bonus Non Crypto 5.7% (52), Satisfaction Bonus Crypto 0.7% (6). Amount range: −$8,062 to $8,062; average $54.82.

---

## 2. Business Logic

### 2.1 FCA Population Filter

**What**: Only FCA-regulated active customers are included — all other regulations are excluded.
**Columns Involved**: `RealCID`
**Rules**:
- Source: `DWH_dbo.Fact_CustomerAction` JOIN `DWH_dbo.Dim_Customer`
- Filter: `Dim_Customer.RegulationID = 2` (FCA) AND `Dim_Customer.IsValidCustomer = 1`
- Filters applied in the SP's `#FCA_Customers` temp table before compensation event join

### 2.2 Compensation Reason Subset Filter

**What**: Only events with specific CompensationReasonIDs are included — not all compensation types.
**Columns Involved**: `CompensationReason`
**Rules**:
- Filter: `Fact_CustomerAction.CompensationReasonID IN (3, 26, 125, 126, 127, 128)`
- The 6 IDs correspond to: technical problem and satisfaction bonus reason categories
- As of March 2026, only 4 distinct names are observed in the data (some IDs may have zero events in any given month)
- Name decoded via `JOIN DWH_dbo.Dim_CompensationReason ON CompensationReasonID`

### 2.3 Previous-Month Scope

**What**: Each ETL run loads exactly one month of events — the calendar month prior to the run date.
**Columns Involved**: `Date`
**Rules**:
- No input date parameter; window computed internally: `DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)` to `DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) - 1` (first and last day of previous month)
- `Date` is sourced from `Fact_CustomerAction.Occurred` — UTC timestamp of the compensation event
- Running the SP multiple times in the same month overwrites with the same scope (TRUNCATE + INSERT)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN / HEAP — no distribution key. Suitable for small export workloads (916 rows). Any JOIN to large HASH-distributed tables (Fact_CustomerAction, Dim_Customer) will broadcast this table, which is efficient at this row count.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Total compensation amount by reason | `SELECT CompensationReason, SUM(Amount) FROM ... GROUP BY CompensationReason` |
| Customers receiving technical problem credits | `SELECT RealCID, Amount WHERE CompensationReason LIKE 'Technical Problems%'` |
| High-value individual compensations | `SELECT * ORDER BY ABS(Amount) DESC` |
| Monthly count by reason type | `SELECT CompensationReason, COUNT(*) AS events GROUP BY CompensationReason` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = Dim_Customer.RealCID` | Enrich with country, KYC, account status |
| DWH_dbo.Fact_CustomerAction | `RealCID = fca.RealCID AND Date = fca.Occurred` | Trace back to original action record |

### 3.4 Gotchas

- **Previous month only**: Table always holds exactly one previous month's data. Do not use for current-month or historical trend analysis.
- **FCA only**: Non-FCA compensation events are not included. For other regulations, see the sister table `BI_DB_Compensation_Activity_Data_Regulation`.
- **Reason subset**: Only CompensationReasonIDs 3, 26, 125, 126, 127, 128 are included. Marketing bonuses, dividends, and other compensation types are absent.
- **Negative amounts**: Amount can be negative (debit corrections). Do not assume all rows are credits.
- **UpdateDate precision**: GETDATE() at ETL run time — all rows share the same UpdateDate.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (no transformation) |
| Tier 2 | Derived from ETL SP code, DWH wiki, or staging DDL |
| Tier 3 | Inferred from column name, data pattern, or business context |
| Tier 4 | Best available — no source traceable |
| Propagation | ETL infrastructure column (GETDATE(), row metadata) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Scoped to FCA-regulated, IsValidCustomer=1 customers only. (Tier 1 — Customer.CustomerStatic) |
| 2 | Date | datetime | YES | UTC timestamp of the compensation event. Sourced from Fact_CustomerAction.Occurred — when the credit or debit was recorded. All rows are within the previous calendar month. (Tier 2 — Fact_CustomerAction wiki) |
| 3 | Amount | decimal(11,2) | YES | Compensation amount in USD. Positive = credit to customer account; negative = debit correction. Range: −$8,062 to $8,062 in current data; average $54.82. Sourced from Fact_CustomerAction.Amount for compensation events (CompensationReasonID IN 3,26,125,126,127,128). (Tier 2 — Fact_CustomerAction wiki) |
| 4 | CompensationReason | varchar(250) | YES | Human-readable compensation reason label from Dim_CompensationReason.Name. Observed values: 'Technical Problems Crypto', 'Technical Problems Non Crypto', 'Satisfaction Bonus Crypto', 'Satisfaction Bonus Non Crypto'. (Tier 1 — Dim_CompensationReason wiki, BackOffice.CompensationReason) |
| 5 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough; FCA + IsValidCustomer filter via Dim_Customer |
| Date | DWH_dbo.Fact_CustomerAction | Occurred | Rename |
| Amount | DWH_dbo.Fact_CustomerAction | Amount | Passthrough; filtered to CompensationReasonID IN (3,26,125,126,127,128) |
| CompensationReason | DWH_dbo.Dim_CompensationReason | Name | JOIN on CompensationReasonID |
| UpdateDate | ETL | GETDATE() | Runtime timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction
  + DWH_dbo.Dim_Customer (RegulationID=2, IsValidCustomer=1)
    → #FCA_Customers (CID filter)
      + DWH_dbo.Dim_CompensationReason (CompensationReasonID IN 3,26,125,126,127,128)
        |-- SP_Compensation_Activity_Data (GETDATE() previous month) TRUNCATE+INSERT ---|
        v
BI_DB_dbo.BI_DB_Compensation_Activity_Data_CompensationReason (916 rows, March 2026)
    |-- UC: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Fact_CustomerAction | Primary source for compensation events |
| RealCID | DWH_dbo.Dim_Customer | FCA + IsValidCustomer filter |
| CompensationReason | DWH_dbo.Dim_CompensationReason | Reason name lookup (Name column) |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in SSDT (reporting export table).

---

## 7. Sample Queries

### Total compensation by reason type for the current loaded month

```sql
SELECT CompensationReason,
       COUNT(*) AS event_count,
       SUM(Amount) AS total_amount,
       AVG(Amount) AS avg_amount
FROM [BI_DB_dbo].[BI_DB_Compensation_Activity_Data_CompensationReason]
GROUP BY CompensationReason
ORDER BY total_amount DESC;
```

### High-value individual compensations (top 20)

```sql
SELECT TOP 20
       RealCID,
       Date,
       Amount,
       CompensationReason
FROM [BI_DB_dbo].[BI_DB_Compensation_Activity_Data_CompensationReason]
ORDER BY ABS(Amount) DESC;
```

### Customers receiving multiple compensations in the period

```sql
SELECT RealCID,
       COUNT(*) AS compensation_events,
       SUM(Amount) AS total_received
FROM [BI_DB_dbo].[BI_DB_Compensation_Activity_Data_CompensationReason]
GROUP BY RealCID
HAVING COUNT(*) > 1
ORDER BY compensation_events DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this object. SP comment: table populated by SP_Compensation_Activity_Data (Lior Ben Dor, 2021-07-12).

---

*Generated: 2026-04-23 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 2 T1, 2 T2, 0 T3, 0 T4, 1 Propagation | Elements: 5/5, Logic: 8/10*
*Object: BI_DB_dbo.BI_DB_Compensation_Activity_Data_CompensationReason | Type: Table | Production Source: SP_Compensation_Activity_Data*
