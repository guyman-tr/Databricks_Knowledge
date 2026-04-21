# eMoney_dbo.eMoney_Dictionary_PaymentSpecificationType

> 2-row lookup table materializing FiatDwhDB.Dictionary.PaymentSpecificationTypes into the Synapse DWH; classifies the type of recurring or automated payment instruction set up on a currency balance (Unknown, DirectDebit). All values loaded 2023-06-12; static since initial load.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.PaymentSpecificationTypes (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; Override strategy, 1440 min cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 2 (0=Unknown, 1=DirectDebit) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_PaymentSpecificationType` is a lookup/reference table that defines the valid types of payment specification — that is, the type of recurring or automated payment instruction set up on an eToro Money currency balance. Each row maps an integer ID to a human-readable name.

With only 2 values, this dictionary is minimal: `Unknown (0)` is the sentinel for undetermined type, and `DirectDebit (1)` identifies a pull-payment mandate where a third-party creditor is authorized to debit the balance on a scheduled or recurring basis. Payment specifications are sourced from `dbo.PaymentSpecifications` in FiatDwhDB.

This dictionary is sourced from `FiatDwhDB.Dictionary.PaymentSpecificationTypes` via Generic Pipeline Bronze export. All Synapse rows carry UpdateDate 2023-06-12 (single bulk load).

---

## 2. Business Logic

### 2.1 Payment Specification Types

**What**: Classifies the authorization mechanism for automated payment instructions on a currency balance.

**Columns Involved**: `PaymentSpecificationTypeID`

**Rules**:
- `0=Unknown` — sentinel value; type not determined or not yet mapped
- `1=DirectDebit` — a SEPA or local direct debit mandate: the creditor has authorization to pull funds from the balance. Governed by mandate reference in `dbo.PaymentSpecifications`

### 2.2 Mandate Lifecycle Context

**What**: DirectDebit specifications follow a mandate authorization lifecycle in the source system.

**Columns Involved**: `PaymentSpecificationTypeID`

**Rules**:
- `DirectDebit (1)` specifications in `dbo.PaymentSpecifications` (FiatDwhDB) track mandate status, creditor reference, and recurrence schedule
- Only SEPA direct debit mandates (SEPAdirectDebit scheme) are expected to carry `PaymentSpecificationTypeID = 1`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distributes both rows to every node. Joins from payment specification tables are data-local. HEAP is optimal for 2 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up payment specification type name | `SELECT PaymentSpecificationType FROM eMoney_Dictionary_PaymentSpecificationType WHERE PaymentSpecificationTypeID = @id` |
| Filter for direct debit mandates | `WHERE PaymentSpecificationTypeID = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| PaymentSpecifications (eMoney_dbo mirror) | PaymentSpecificationTypeID = PaymentSpecificationTypeID | Decode type on payment specification records |

### 3.4 Gotchas

- Only 2 rows — any query returning more than 2 rows from this table indicates a data quality issue
- `0=Unknown` is the sentinel; in practice virtually all mandates in production are `1=DirectDebit`
- Table currently has no values beyond DirectDebit — future payment specification types (e.g., StandingOrder) would require a FiatDwhDB upstream refresh to appear

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB) |
| Tier 2 | Derived from ETL SP code or DWH logic |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Glossary-sourced |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentSpecificationTypeID | int | YES | Lookup identifier. Primary key. 0=Unknown, 1=DirectDebit. (Tier 1 — Dictionary.PaymentSpecificationTypes) |
| 2 | PaymentSpecificationType | varchar(50) | YES | Human-readable name for this value. 0=Unknown, 1=DirectDebit. (Tier 1 — Dictionary.PaymentSpecificationTypes) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| PaymentSpecificationTypeID | FiatDwhDB.Dictionary.PaymentSpecificationTypes | Id | Rename; tinyint→int widen |
| PaymentSpecificationType | FiatDwhDB.Dictionary.PaymentSpecificationTypes | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.PaymentSpecificationTypes (source — 2 rows: 0=Unknown, 1=DirectDebit)
  |-- Generic Pipeline (Bronze export, Override, 1440 min) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/PaymentSpecificationTypes/)
  |-- External Table: External_FiatDwhDB_Dictionary_PaymentSpecificationTypes ---|
  v
eMoney_dbo.eMoney_Dictionary_PaymentSpecificationType (2 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| PaymentSpecifications (eMoney_dbo mirror) | PaymentSpecificationTypeID | Payment specification records decode type via this dictionary |

---

## 7. Sample Queries

### 7.1 View all payment specification type values
```sql
SELECT PaymentSpecificationTypeID, PaymentSpecificationType, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_PaymentSpecificationType]
ORDER BY PaymentSpecificationTypeID;
```

### 7.2 Count payment specifications by type
```sql
SELECT pst.PaymentSpecificationType, COUNT(*) AS SpecCount
FROM [eMoney_dbo].[eMoney_PaymentSpecifications] ps
JOIN [eMoney_dbo].[eMoney_Dictionary_PaymentSpecificationType] pst
    ON ps.PaymentSpecificationTypeID = pst.PaymentSpecificationTypeID
GROUP BY pst.PaymentSpecificationType
ORDER BY SpecCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Dictionary values are documented in the FiatDwhDB upstream wiki and business glossary.

---

PHASE GATE CHECK — eMoney_Dictionary_PaymentSpecificationType [SIMPLE-DICT]:
  [x] P1 DDL   [x] P2 Sample   [-] P3 Dist   [x] P4 Lookup
  [-] P5 JOIN  [-] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Dictionary_PaymentSpecificationType [SIMPLE-DICT]:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

T1 COPY VERIFICATION:
  PaymentSpecificationTypeID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Unknown, 1=DirectDebit." — IDENTICAL (values added from live MCP)
  PaymentSpecificationType: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Unknown, 1=DirectDebit." — IDENTICAL

*Generated: 2026-04-21 | Quality: 9.2/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_PaymentSpecificationType | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.PaymentSpecificationTypes*
