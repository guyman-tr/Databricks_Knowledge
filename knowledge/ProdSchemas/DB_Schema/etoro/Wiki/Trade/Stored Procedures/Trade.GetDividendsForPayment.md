# Trade.GetDividendsForPayment

> Atomically transitions dividends from snapshot-ready (Status=4) to processing (Status=1) for exchanges whose payment date has arrived, returning the dividend details for payment execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExchangeIDs (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDividendsForPayment is a WRITER procedure that atomically claims dividends for payment processing. It finds all dividends in Trade.IndexDividends with Status=4 (snapshot ready) where the PaymentDate has arrived or passed, filtered to specific exchanges via the @ExchangeIDs TVP. It updates their Status to 1 (processing) and uses OUTPUT DELETED to return the dividend details to the caller in one atomic operation.

This procedure exists because the dividend payment pipeline needs to claim dividends for processing without race conditions. The UPDATE...OUTPUT pattern ensures that only one service instance can claim each dividend - once Status changes from 4 to 1, another service calling the same procedure won't see those dividends.

Data flows: UPDATE Trade.IndexDividends SET Status=1 WHERE Status=4 AND PaymentDate <= today AND exchange matches; OUTPUT returns the DELETED (pre-update) row values including tax codes and correction data.

---

## 2. Business Logic

### 2.1 Atomic Claim Pattern

**What**: Claims dividends for payment by atomically changing Status=4 to Status=1 and returning the data.

**Columns/Parameters Involved**: `Status`, `PaymentDate`, `@ExchangeIDs`

**Rules**:
- Status=4: snapshot ready (eligible for payment)
- Status=1: being processed (claimed)
- PaymentDate <= GETUTCDATE(): payment date has arrived
- @ExchangeIDs filters to specific exchanges via InstrumentMetaData.ExchangeID
- Uses OPTION(RECOMPILE) to avoid plan caching issues with TVP

### 2.2 Tax and Correction Data

**What**: Returns tax codes and correction dividend references needed for payment calculation.

**Columns/Parameters Involved**: `TaxCode`, `BuyTax`, `SellTax`, `CorrectionDividendID`, `NegativeDividendAllowed`, `RetakeDividendID`

**Rules**:
- BuyTax and SellTax are cast to decimal(16,8) for precision
- CorrectionDividendID links to a previous dividend being corrected
- NegativeDividendAllowed: whether this dividend can result in a debit to the customer
- RetakeDividendID: links to a dividend that needs to be retaken
- DividendValueInCurrency: the dividend amount in the instrument's currency

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExchangeIDs | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Exchange IDs to process dividends for. Filters via InstrumentMetaData.ExchangeID. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | Dividend being paid. FK to Trade.IndexDividends. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument paying the dividend. |
| 3 | TaxCode | varchar | YES | - | CODE-BACKED | Tax code for the dividend (e.g., withholding tax classification). |
| 4 | BuyTax | decimal(16,8) | YES | - | CODE-BACKED | Tax rate for buy/long positions. Cast from original type. |
| 5 | SellTax | decimal(16,8) | YES | - | CODE-BACKED | Tax rate for sell/short positions. Cast from original type. |
| 6 | PaymentDate | date | YES | - | CODE-BACKED | Scheduled payment date for this dividend. |
| 7 | CorrectionDividendID | int | YES | - | CODE-BACKED | If this is a correction, the original dividend ID. |
| 8 | NegativeDividendAllowed | bit | YES | - | CODE-BACKED | Whether this dividend can result in a customer debit. |
| 9 | DividendValueInCurrency | decimal | YES | - | CODE-BACKED | Dividend amount per unit in the instrument's currency. |
| 10 | RetakeDividendID | int | YES | - | CODE-BACKED | Dividend ID that needs to be retaken/reprocessed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DividendID | Trade.IndexDividends | UPDATE + OUTPUT | Dividend status transition and data return |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Exchange ID resolution |
| ExchangeID | @ExchangeIDs TVP | JOIN | Exchange filter |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDividendsForPayment (procedure)
+-- Trade.IndexDividends (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | UPDATE SET Status=1 + OUTPUT DELETED |
| Trade.InstrumentMetaData | Table | JOIN for ExchangeID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by dividend payment service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses OPTION(RECOMPILE).

### 7.2 Constraints

None. This is a WRITER procedure (modifies data).

---

## 8. Sample Queries

### 8.1 Claim dividends for payment for specific exchanges

```sql
DECLARE @Exchanges Trade.IdIntList;
INSERT INTO @Exchanges (Id) VALUES (1), (2), (3);
EXEC Trade.GetDividendsForPayment @ExchangeIDs = @Exchanges;
```

### 8.2 Check dividends ready for payment without claiming

```sql
SELECT  ID.DividendID, ID.InstrumentID, ID.PaymentDate, ID.Status
FROM    Trade.IndexDividends ID WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData IM WITH (NOLOCK) ON ID.InstrumentID = IM.InstrumentID
WHERE   ID.Status = 4
        AND ID.PaymentDate <= CAST(GETUTCDATE() AS DATE);
```

### 8.3 Check dividend processing pipeline status

```sql
SELECT  Status, COUNT(*) AS DividendCount
FROM    Trade.IndexDividends WITH (NOLOCK)
GROUP BY Status
ORDER BY Status;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDividendsForPayment | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDividendsForPayment.sql*
