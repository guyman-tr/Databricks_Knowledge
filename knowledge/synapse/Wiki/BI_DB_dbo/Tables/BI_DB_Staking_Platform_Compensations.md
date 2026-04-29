# BI_DB_dbo.BI_DB_Staking_Platform_Compensations

> 548K-row staking compensation ledger tracking every cash-equivalent payment made to customers for crypto staking rewards. Filtered to CreditTypeID=6 (Compensation), MoveMoneyReasonID=3 (Staking), CompensationReasonID=3 (Technical Problems). Built by SP_Staking_Platform_Compensations from External_etoro_History_Credit, enriched with Dim_CreditType and Dim_CompensationReason. Data from April 2021 to June 2025 (daily incremental DELETE+INSERT by CreditID).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_Staking_Platform_Compensations (BI_DB_dbo) |
| **Refresh** | Daily — DELETE+INSERT by CreditID (idempotent upsert) |
| **Synapse Distribution** | HASH([CID]) |
| **Synapse Index** | CLUSTERED INDEX ([CreditID] ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_staking_platform_compensations` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

This table records every staking compensation payment made by the platform to customers as cash equivalents for their crypto staking rewards. When customers hold staking-eligible crypto assets (ADA, TRX), they earn staking rewards that are paid as compensation credits rather than direct token distributions.

Each row is one compensation credit event identified by CreditID. The filters are fixed: CreditTypeID=6 (Compensation), MoveMoneyReasonID=3 (Staking), and CompensationReasonID=3 (Technical Problems — the operational classification used for staking payouts). Credits from before April 2021 are excluded (Occurred >= '20210401').

The SP uses an external table pattern: it first calls SP_Create_External_etoro_History_Credit to create/refresh a dynamic external table for the date, then filters and enriches the data. The DELETE is by CreditID (not date), making it idempotent for re-runs.

Typical CreditDescription values follow the pattern "Staking {Month} {Year} Cash Equivalent" (e.g., "Staking May 2025 Cash Equivalent"). Payments are small per-customer amounts (median ~$2-5).

---

## 2. Business Logic

### 2.1 Staking Credit Filter

**What**: Isolates staking-specific compensation credits from the broader credit history.
**Columns Involved**: CreditTypeID, MoveMoneyReasonID, CompensationReasonID
**Rules**:
- CreditTypeID = 6 (Compensation)
- MoveMoneyReasonID = 3 (Staking)
- CompensationReasonID = 3 (Technical Problems)
- Occurred >= '20210401' (April 2021 onward)
- CAST(Occurred AS DATE) = @Date (daily incremental)

### 2.2 Idempotent Upsert

**What**: Re-runnable by CreditID rather than date.
**Columns Involved**: CreditID
**Rules**:
- DELETE WHERE CreditID IN (SELECT CreditID FROM new data)
- INSERT new data — same CreditID won't duplicate

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH([CID]) with CLUSTERED INDEX on [CreditID]. CID-based queries are collocated. CreditID lookups use the clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly staking payouts | `GROUP BY FORMAT(CreditDate, 'yyyy-MM')` |
| Staking by customer | `WHERE CID = X ORDER BY CreditDate` |
| Total staking cost per month | `SELECT SUM(Payment) ... GROUP BY YEAR(CreditDate), MONTH(CreditDate)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer attributes |

### 3.4 Gotchas

- **CompensationReason is always "Technical Problems"**: This is the operational category for staking, not an actual technical issue
- **CreditTypeName has trailing spaces**: char(50) — use RTRIM for string comparisons
- **Data stops at June 2025**: Verify if the SP is still scheduled or if staking payments have been restructured
- **Payment amounts are in account currency**: Not normalized to USD

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest |
| Tier 2 | SP code analysis | High |
| Tier 5 | ETL metadata | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NOT NULL | Customer ID receiving the staking compensation. HASH distribution key. (Tier 2 — SP_Staking_Platform_Compensations) |
| 2 | CreditID | bigint | YES | Unique credit transaction identifier from etoro.History.Credit. Clustered index key. Used for idempotent DELETE+INSERT. (Tier 2 — SP_Staking_Platform_Compensations) |
| 3 | CreditTypeID | tinyint | YES | Financial operation type. Always 6 (Compensation) in this table. FK to Dictionary.CreditType. (Tier 1 — Dictionary.CreditType) |
| 4 | CreditTypeName | char(50) | YES | Human-readable operation name. Always "Compensation" (with trailing spaces — char(50)). RTRIM for display. Passthrough from Dim_CreditType. (Tier 1 — Dictionary.CreditType) |
| 5 | CreditDateTime | datetime | NOT NULL | Exact timestamp of the compensation credit. CAST from History.Credit.Occurred. (Tier 2 — SP_Staking_Platform_Compensations) |
| 6 | CreditDate | date | YES | Date-only portion of CreditDateTime. Used for daily filtering. (Tier 2 — SP_Staking_Platform_Compensations) |
| 7 | Payment | money | YES | Compensation amount in account currency. Typically small staking rewards ($1-$10 range). From History.Credit.Payment. (Tier 2 — SP_Staking_Platform_Compensations) |
| 8 | CompensationReasonID | int | YES | Compensation reason. Always 3 (Technical Problems) for staking payouts. FK to BackOffice.CompensationReason. (Tier 1 — BackOffice.CompensationReason) |
| 9 | CompensationReason | varchar(100) | YES | Human-readable reason label. Always "Technical Problems" in this table. Passthrough from Dim_CompensationReason.Name. (Tier 1 — BackOffice.CompensationReason) |
| 10 | MoveMoneyReasonID | int | YES | Money movement classification. Always 3 (Staking) in this table. FK to etoro.Dictionary.MoveMoneyReason. (Tier 2 — SP_Staking_Platform_Compensations) |
| 11 | MoveMoneyReason | varchar(30) | YES | Human-readable money movement label. Always "Staking". Passthrough from External_etoro_Dictionary_MoveMoneyReason. (Tier 2 — SP_Staking_Platform_Compensations) |
| 12 | CreditDescription | varchar(255) | YES | Free-text description of the compensation. Typically "Staking {Month} {Year} Cash Equivalent". From History.Credit.Description. (Tier 2 — SP_Staking_Platform_Compensations) |
| 13 | UpdateDate | datetime | NOT NULL | ETL metadata: row insert timestamp (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID, CreditID, Payment, CreditDescription | etoro.History.Credit | CID, CreditID, Payment, Description | Passthrough via external table |
| CreditTypeID | etoro.History.Credit | CreditTypeID | Filter = 6 |
| CreditTypeName | Dictionary.CreditType | CreditTypeName | Dim-lookup |
| CompensationReasonID | etoro.History.Credit | CompensationReasonID | Filter = 3 |
| CompensationReason | BackOffice.CompensationReason | Name | Dim-lookup |
| MoveMoneyReasonID | etoro.History.Credit | MoveMoneyReasonID | Filter = 3 |
| MoveMoneyReason | etoro.Dictionary.MoveMoneyReason | MoveMoneyReason | Passthrough |

### 5.2 ETL Pipeline

```
etoro.History.Credit (production credit ledger)
  |-- SP_Create_External_etoro_History_Credit (dynamic external table) ---|
  v
BI_DB_dbo.External_etoro_History_Credit_Yesterday
  |-- SP_Staking_Platform_Compensations @Date ---|
  |   + Dim_CompensationReason (reason name)
  |   + Dim_CreditType (credit type name)
  |   + External_etoro_Dictionary_MoveMoneyReason (move reason name)
  v
BI_DB_dbo.BI_DB_Staking_Platform_Compensations (548K rows)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_staking_platform_compensations
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |
| CreditTypeID | DWH_dbo.Dim_CreditType | Credit type lookup |
| CompensationReasonID | DWH_dbo.Dim_CompensationReason | Reason lookup |

### 6.2 Referenced By (other objects point to this)

No known consumers in the documented wiki set.

---

## 7. Sample Queries

### 7.1 Monthly Staking Compensation Totals

```sql
SELECT YEAR(CreditDate) AS yr, MONTH(CreditDate) AS mo,
       COUNT(*) AS payments, SUM(Payment) AS total_paid, COUNT(DISTINCT CID) AS unique_customers
FROM BI_DB_dbo.BI_DB_Staking_Platform_Compensations
GROUP BY YEAR(CreditDate), MONTH(CreditDate)
ORDER BY yr DESC, mo DESC
```

### 7.2 Customer Staking History

```sql
SELECT CreditDate, Payment, CreditDescription
FROM BI_DB_dbo.BI_DB_Staking_Platform_Compensations
WHERE CID = 43551279
ORDER BY CreditDate DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 4 T1, 8 T2, 0 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Staking_Platform_Compensations | Type: Table | Production Source: SP_Staking_Platform_Compensations*
