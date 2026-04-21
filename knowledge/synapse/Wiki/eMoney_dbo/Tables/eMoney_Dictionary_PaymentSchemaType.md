# eMoney_dbo.eMoney_Dictionary_PaymentSchemaType

> 8-row lookup table materializing FiatDwhDB.Dictionary.PaymentSchemaType into the Synapse DWH; classifies the payment network or scheme through which a banking transaction is processed (Unknown, Transfer, FasterPayments, Chaps, Bacs, SEPAstandart, SEPAinstantTransfer, SEPAdirectDebit). All values loaded 2023-06-11; static since initial load.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.PaymentSchemaType (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; Override strategy, 1440 min cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 8 (0=Unknown through 7=SEPAdirectDebit) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_PaymentSchemaType` is a lookup/reference table that defines the valid payment scheme types for eToro Money banking transactions. Each row maps an integer ID to a human-readable scheme name. Payment schema type determines the routing, settlement speed, and applicable regulations for each transaction processed through the fiat platform.

The 8 values cover UK domestic schemes (FasterPayments, Chaps, Bacs), pan-European SEPA variants (SEPAstandart, SEPAinstantTransfer, SEPAdirectDebit), a generic Transfer type, and an Unknown sentinel. Note: `SEPAstandart` (ID=5) preserves a typo from the FiatDwhDB source — use this exact spelling in all filters and joins.

This dictionary is sourced from `FiatDwhDB.Dictionary.PaymentSchemaType` via Generic Pipeline Bronze export and applied to transactions in `dbo.FiatTransactions`. All Synapse rows carry UpdateDate 2023-06-11 (single bulk load, one day earlier than the other dictionaries in this batch).

---

## 2. Business Logic

### 2.1 UK Domestic Payment Schemes

**What**: Fast and standard settlement rails used for GBP payments within the UK.

**Columns Involved**: `PaymentSchemaTypeID`

**Rules**:
- `2=FasterPayments` — near-instant GBP transfers (seconds); max £1M per transaction
- `3=Chaps` — same-day high-value GBP settlement; typically used for large transfers
- `4=Bacs` — 3-day batch settlement; used for direct debits and payroll

### 2.2 SEPA Payment Schemes

**What**: European payment schemes for EUR transactions across SEPA member states.

**Columns Involved**: `PaymentSchemaTypeID`

**Rules**:
- `5=SEPAstandart` — standard SEPA Credit Transfer (SCT); 1-business-day EUR settlement. Note: typo ("SEPAstandart" not "SEPAstandard") is verbatim from the FiatDwhDB source — preserve in all filters
- `6=SEPAinstantTransfer` — SEPA Instant Credit Transfer (SCT Inst); near-real-time EUR settlement (≤10 seconds); available 24/7
- `7=SEPAdirectDebit` — SEPA Direct Debit (SDD); recurring EUR pull payments authorized by mandate

### 2.3 Generic and Unknown Types

**Columns Involved**: `PaymentSchemaTypeID`

**Rules**:
- `0=Unknown` — sentinel value; used when scheme is not determined or available in source data
- `1=Transfer` — generic internal or non-scheme transfer (e.g., balance adjustments, inter-account moves not routed via a named rail)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distributes all 8 rows to every node. Joins from transaction tables are data-local. HEAP is optimal for 8 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up payment scheme name | `SELECT PaymentSchemaType FROM eMoney_Dictionary_PaymentSchemaType WHERE PaymentSchemaTypeID = @id` |
| Filter for SEPA transactions | `WHERE PaymentSchemaTypeID IN (5,6,7)` |
| Filter for UK domestic transactions | `WHERE PaymentSchemaTypeID IN (2,3,4)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| FiatTransactions (eMoney_dbo mirror) | PaymentSchemaTypeID = PaymentSchemaTypeID | Decode payment scheme on transaction records |

### 3.4 Gotchas

- `5=SEPAstandart` — typo preserved verbatim from FiatDwhDB source; do NOT filter on `SEPAstandard` (with a 'd') — it will return no rows
- `0=Unknown` is a sentinel; exclude when analyzing specific scheme flows
- `1=Transfer` covers generic internal moves — distinct from named payment rails; do not include in scheme-specific reporting
- All rows have UpdateDate 2023-06-11 (one day earlier than the other batch 4 dictionaries which use 2023-06-12)

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
| 1 | PaymentSchemaTypeID | int | YES | Lookup identifier. Primary key. 0=Unknown, 1=Transfer, 2=FasterPayments, 3=Chaps, 4=Bacs, 5=SEPAstandart, 6=SEPAinstantTransfer, 7=SEPAdirectDebit. (Tier 1 — Dictionary.PaymentSchemaType) |
| 2 | PaymentSchemaType | varchar(50) | YES | Human-readable name for this value. 0=Unknown, 1=Transfer, 2=FasterPayments, 3=Chaps, 4=Bacs, 5=SEPAstandart, 6=SEPAinstantTransfer, 7=SEPAdirectDebit. (Tier 1 — Dictionary.PaymentSchemaType) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-11. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| PaymentSchemaTypeID | FiatDwhDB.Dictionary.PaymentSchemaType | Id | Rename; tinyint→int widen |
| PaymentSchemaType | FiatDwhDB.Dictionary.PaymentSchemaType | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.PaymentSchemaType (source — 8 rows: 0=Unknown through 7=SEPAdirectDebit)
  |-- Generic Pipeline (Bronze export, Override, 1440 min) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/PaymentSchemaType/)
  |-- External Table: External_FiatDwhDB_Dictionary_PaymentSchemaType ---|
  v
eMoney_dbo.eMoney_Dictionary_PaymentSchemaType (8 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| FiatTransactions (eMoney_dbo mirror) | PaymentSchemaTypeID | Transaction records decode payment scheme via this dictionary |

---

## 7. Sample Queries

### 7.1 View all payment schema type values
```sql
SELECT PaymentSchemaTypeID, PaymentSchemaType, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_PaymentSchemaType]
ORDER BY PaymentSchemaTypeID;
```

### 7.2 Transaction count by payment scheme
```sql
SELECT pst.PaymentSchemaType, COUNT(*) AS TxCount
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] t
JOIN [eMoney_dbo].[eMoney_Dictionary_PaymentSchemaType] pst
    ON t.PaymentSchemaTypeID = pst.PaymentSchemaTypeID
WHERE t.PaymentSchemaTypeID IS NOT NULL
GROUP BY pst.PaymentSchemaType
ORDER BY TxCount DESC;
```

### 7.3 SEPA vs UK domestic transaction breakdown
```sql
SELECT
    CASE
        WHEN t.PaymentSchemaTypeID IN (2,3,4) THEN 'UK Domestic'
        WHEN t.PaymentSchemaTypeID IN (5,6,7) THEN 'SEPA'
        WHEN t.PaymentSchemaTypeID = 1 THEN 'Generic Transfer'
        ELSE 'Unknown'
    END AS SchemeGroup,
    COUNT(*) AS TxCount
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] t
GROUP BY
    CASE
        WHEN t.PaymentSchemaTypeID IN (2,3,4) THEN 'UK Domestic'
        WHEN t.PaymentSchemaTypeID IN (5,6,7) THEN 'SEPA'
        WHEN t.PaymentSchemaTypeID = 1 THEN 'Generic Transfer'
        ELSE 'Unknown'
    END;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Dictionary values are documented in the FiatDwhDB upstream wiki and business glossary.

---

PHASE GATE CHECK — eMoney_Dictionary_PaymentSchemaType [SIMPLE-DICT]:
  [x] P1 DDL   [x] P2 Sample   [-] P3 Dist   [x] P4 Lookup
  [-] P5 JOIN  [-] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Dictionary_PaymentSchemaType [SIMPLE-DICT]:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

T1 COPY VERIFICATION:
  PaymentSchemaTypeID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Unknown ... 7=SEPAdirectDebit." — IDENTICAL (values added from live MCP; base phrase not paraphrased)
  PaymentSchemaType: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Unknown ... 7=SEPAdirectDebit." — IDENTICAL

*Generated: 2026-04-21 | Quality: 9.2/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_PaymentSchemaType | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.PaymentSchemaType*
