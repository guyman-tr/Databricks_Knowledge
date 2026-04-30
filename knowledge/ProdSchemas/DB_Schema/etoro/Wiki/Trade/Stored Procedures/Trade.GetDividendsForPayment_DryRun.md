# Trade.GetDividendsForPayment_DryRun

> Dry-run variant of GetDividendsForPayment - atomically transitions dividends from Status=4 to Status=1 in the DryRun table, returning dividend details for test/simulation payment processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExchangeIDs (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDividendsForPayment_DryRun is the dry-run counterpart of Trade.GetDividendsForPayment. It operates on Trade.IndexDividends_DryRun instead of the production Trade.IndexDividends table, allowing the dividend payment pipeline to be tested without affecting real dividend records. The logic is identical: claim dividends by changing Status=4 to Status=1 and returning the data via OUTPUT DELETED.

This procedure exists to support dividend payment testing and validation. The dry-run table mirrors the production table structure, enabling full end-to-end testing of the payment flow.

---

## 2. Business Logic

### 2.1 Dry-Run Atomic Claim

**What**: Same atomic claim pattern as production, but on the _DryRun table.

**Columns/Parameters Involved**: `Status`, `PaymentDate`, `@ExchangeIDs`

**Rules**:
- Identical to GetDividendsForPayment but targets Trade.IndexDividends_DryRun
- Does NOT include DividendValueInCurrency or RetakeDividendID (fewer columns than production variant)
- Uses OPTION(RECOMPILE)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExchangeIDs | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Exchange IDs to process dry-run dividends for. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | Dividend being paid (dry-run). |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument paying the dividend. |
| 3 | TaxCode | varchar | YES | - | CODE-BACKED | Tax code classification. |
| 4 | BuyTax | decimal(16,8) | YES | - | CODE-BACKED | Tax rate for buy/long positions. |
| 5 | SellTax | decimal(16,8) | YES | - | CODE-BACKED | Tax rate for sell/short positions. |
| 6 | PaymentDate | date | YES | - | CODE-BACKED | Scheduled payment date. |
| 7 | CorrectionDividendID | int | YES | - | CODE-BACKED | Original dividend if this is a correction. |
| 8 | NegativeDividendAllowed | bit | YES | - | CODE-BACKED | Whether debit dividends are allowed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| * | Trade.IndexDividends_DryRun | UPDATE + OUTPUT | Dry-run dividend data |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Exchange ID resolution |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDividendsForPayment_DryRun (procedure)
+-- Trade.IndexDividends_DryRun (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends_DryRun | Table | UPDATE + OUTPUT DELETED |
| Trade.InstrumentMetaData | Table | JOIN for ExchangeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by dry-run dividend pipeline |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses OPTION(RECOMPILE).

### 7.2 Constraints

WRITER procedure (modifies _DryRun data).

---

## 8. Sample Queries

### 8.1 Claim dry-run dividends for payment

```sql
DECLARE @Exchanges Trade.IdIntList;
INSERT INTO @Exchanges (Id) VALUES (1), (2);
EXEC Trade.GetDividendsForPayment_DryRun @ExchangeIDs = @Exchanges;
```

### 8.2 Check dry-run dividend pipeline status

```sql
SELECT Status, COUNT(*) AS DividendCount
FROM   Trade.IndexDividends_DryRun WITH (NOLOCK)
GROUP BY Status ORDER BY Status;
```

### 8.3 Compare production vs dry-run

```sql
SELECT 'Production' AS Source, Status, COUNT(*) AS Cnt FROM Trade.IndexDividends WITH (NOLOCK) GROUP BY Status
UNION ALL
SELECT 'DryRun', Status, COUNT(*) FROM Trade.IndexDividends_DryRun WITH (NOLOCK) GROUP BY Status
ORDER BY Source, Status;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDividendsForPayment_DryRun | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDividendsForPayment_DryRun.sql*
