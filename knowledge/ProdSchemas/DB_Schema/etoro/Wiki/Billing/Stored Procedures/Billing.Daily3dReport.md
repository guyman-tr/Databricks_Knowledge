# Billing.Daily3dReport

> Returns a date-range report of credit card deposits with their 3DS authentication details: BIN data, enrollment status, authentication code, ECI flag, 3DS version, and Cardinal transaction ID; used by ops/risk teams to monitor 3DS coverage and outcomes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate + @EndDate (date range filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.Daily3dReport` is an operational reporting procedure that produces a detailed view of credit card deposits with their full 3DS authentication context for a given date range. It is called by ops and risk teams (and by `Billing.Daily3dReportHTML` for email delivery) to monitor:
- Which deposits triggered 3DS enrollment and authentication
- 3DS authentication outcomes (PAResStatus: Y=Success, N=Fail, A=Attempted, U=Unable)
- 3DS version used (1.0 vs 2.0)
- ECI (Electronic Commerce Indicator) flag values indicating liability shift status
- BIN-level 3DS minimums and card country of issue
- Whether the deposit completed the full 3DS process

The procedure joins `Billing.Trace` (which stores Cardinal SDK event messages as JSON) to `Billing.Deposit` by DepositID, aggregating EventType=1 (enrollment) and EventType=2 (authentication) events per deposit using MAX().

---

## 2. Business Logic

### 2.1 CTE: Per-Deposit 3DS Event Extraction

**What**: Joins deposit, customer, BIN, and trace data. The CTE produces one row per deposit-per-trace-event (a deposit with both enrollment and authentication events produces 2 CTE rows).

**Key JOIN**: `Billing.Trace BT ON BT.TransactionId = D.DepositID`

**JSON extractions from Billing.Trace.Message**:
| Field | EventType | JSON Path | Meaning |
|-------|-----------|-----------|---------|
| Enrollment | 1 | `$.Enrolled` | Y=Enrolled (card supports 3DS), N=Not enrolled |
| AuthenticationCode | 2 | `$.Payload.Payment.ExtendedData.PAResStatus` | Y=Success, N=Failed, A=Attempted, U=Unable, R=Rejected |
| Ecikey | 2 | `$.Payload.Payment.ExtendedData.ECIFlag` | ECI value indicating liability shift: 05/02=full shift, 06/01=attempted, 07/00=no shift |
| 3dsVersion | 2 | `$.Payload.Payment.ExtendedData.ThreeDSVersion` | "1.0" or "2.0" - protocol version used |
| CardinalTransactionId | 2 | `$.ReferenceId` | Cardinal Commerce transaction reference ID |

**Finished3dsProcess**: `IIF(D.PaymentData.value('(Deposit/ThreeDsAsJson)[1]', 'varchar(2000)') IS NULL, 0, 1)` - 1 if the deposit's PaymentData XML contains 3DS payload, 0 if not.

### 2.2 Aggregation: One Row Per Deposit

**What**: The outer SELECT uses `MAX()` on all event-specific fields and `GROUP BY` on all metadata fields to collapse the 2 CTE rows (enrollment + authentication) into a single output row per deposit.

**Rules**:
- `MAX(Enrollment)`: populated from EventType=1 row; empty string from EventType=2 row -> MAX preserves the non-empty value
- `MAX(AuthenticationCode)`, `MAX(Ecikey)`, `MAX([3dsVersion])`, `MAX(CardinalTransactionId)`: same pattern for EventType=2 fields
- `MAX(Finished3dsProcess)`: always 0 or 1 (same for both event rows)
- `ORDER BY CID, DepositID`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATE | NO | - | VERIFIED | Start of date range (inclusive): `PaymentDate >= @StartDate`. |
| 2 | @EndDate | DATE | NO | - | VERIFIED | End of date range (exclusive): `PaymentDate < @EndDate`. Example from DDL comments: `'20190901'` to `'20190902'` returns one day. |

**Result set** (21 columns per deposit):

| # | Column | Description |
|---|--------|-------------|
| 1 | CID | Customer ID |
| 2 | DepositID | Deposit ID |
| 3 | PaymentDate | UTC datetime of deposit (formatted as varchar: YYYY-MM-DD HH:MM:SS.mmm) |
| 4 | FundingID | Payment instrument (card) used |
| 5 | Amount | Deposit amount |
| 6 | OriginalCurrencyUsed | Currency abbreviation (e.g., 'USD', 'EUR') from Dictionary.Currency |
| 7 | TransactionalFinalStatus | Payment status name from Dictionary.PaymentStatus |
| 8 | UserRegulation | Customer's designated regulation name from Dictionary.Regulation (e.g., 'CySEC', 'FCA') |
| 9 | UserCountryByReg | Customer's country name from Customer.CustomerStatic CountryID |
| 10 | Provider | Depot/processor name from Billing.Depot |
| 11 | IsFTD | 1 if this was the customer's first-time deposit, 0 otherwise |
| 12 | BinCode | Card BIN code from Billing.Funding XML |
| 13 | BinCountry | Country name of the BIN issuer from Dictionary.CountryBin -> Dictionary.Country |
| 14 | CardBrand | Card type name (e.g., 'Visa', 'Mastercard') from Dictionary.CardType |
| 15 | MinAmountFor3ds | Minimum deposit amount that triggers 3DS for this BIN, from Dictionary.CountryBin |
| 16 | Enrollment | 3DS enrollment result from Cardinal EventType=1 (Y=enrolled, N=not enrolled, empty if no event) |
| 17 | AuthenticationCode | PARes status from Cardinal EventType=2 (Y/N/A/U/R or empty) |
| 18 | Ecikey | ECI flag from EventType=2 (05=full shift, 06=attempted, 07=no shift) |
| 19 | 3dsVersion | 3DS protocol version from EventType=2 ('1.0' or '2.0', or empty) |
| 20 | CardinalTransactionId | Cardinal Commerce reference ID from EventType=2 |
| 21 | Finished3dsProcess | 1 if deposit's PaymentData contains ThreeDsAsJson, 0 otherwise |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (primary) | Billing.Deposit | Read | Deposits in the date range |
| (join) | Dictionary.Currency | Read | Currency abbreviation for deposit |
| (join) | BackOffice.Customer | Read | Customer regulation assignment |
| (join) | Customer.CustomerStatic | Read | Customer country |
| (join) | Dictionary.Country (x2) | Read | User country + BIN issuer country |
| (join) | Billing.Depot | Read | Processor/depot name |
| (join) | Billing.Funding | Read | Card XML data (BIN, CardType, BinCountry) |
| (join) | Dictionary.CountryBin | Read | BIN details including MinAmountFor3ds |
| (join) | Dictionary.CardType | Read | Card brand name |
| (join) | Billing.Trace | Read | 3DS event messages (JSON) per DepositID |
| (join) | Dictionary.PaymentStatus | Read | Payment status name |
| (left join) | Dictionary.Regulation | Read | Customer regulation name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Daily3dReportHTML | Same params | Caller | Uses the same CTE logic to generate HTML email report |
| Ops/risk team tooling | @StartDate, @EndDate | Caller | Direct execution for ad-hoc 3DS analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Daily3dReport (procedure)
+-- Billing.Deposit (table) [READ: date-range CC deposits]
+-- Billing.Funding (table) [READ: card XML BIN/CardType data]
+-- Billing.Trace (table) [READ: 3DS JSON event messages by DepositID]
+-- Billing.Depot (table) [READ: processor name]
+-- BackOffice.Customer (table) [READ: regulation]
+-- Customer.CustomerStatic (table) [READ: country]
+-- Dictionary.Currency (table) [READ: currency abbreviation]
+-- Dictionary.Country (table x2) [READ: user country + BIN country]
+-- Dictionary.CountryBin (table/view) [READ: BIN details + MinAmountFor3ds]
+-- Dictionary.CardType (table) [READ: card brand name]
+-- Dictionary.PaymentStatus (table) [READ: status name]
+-- Dictionary.Regulation (table) [READ: regulation name]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary date-range filtered source |
| Billing.Funding | Table | Card XML data |
| Billing.Trace | Table | 3DS event JSON messages |
| Billing.Depot | Table | Processor name |
| BackOffice.Customer | Table | Customer regulation |
| Customer.CustomerStatic | Table | Customer country |
| Dictionary.Currency | Table | Currency abbreviation |
| Dictionary.Country | Table | Country names (used twice) |
| Dictionary.CountryBin | View | BIN details and MinAmountFor3ds |
| Dictionary.CardType | Table | Card brand |
| Dictionary.PaymentStatus | Table | Payment status name |
| Dictionary.Regulation | Table | Regulation name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Daily3dReportHTML | Stored Procedure | Replicates the same CTE logic for HTML email delivery |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**INNER JOIN on Billing.Trace**: Uses INNER JOIN (not LEFT JOIN), meaning deposits with no trace records at all are excluded from the report. Deposits that had 3DS triggered but no Cardinal events logged would also be excluded.

**PaymentData XML query**: `D.PaymentData.value('(Deposit/ThreeDsAsJson)[1]', 'varchar(2000)')` checks for the ThreeDsAsJson node in the deposit's payment data XML. This may be performance-sensitive if PaymentData XML column lacks an XML index.

**Date range boundary**: `@StartDate <= PaymentDate < @EndDate` - standard half-open interval. For a single day, pass the same date as @StartDate and @StartDate+1 as @EndDate.

**Commented fields**: `--D.PaymentData`, `--BT.Message` are commented out in the SELECT with notes "should remove" - these large XML/JSON columns were deliberately excluded from the output.

---

## 8. Sample Queries

### 8.1 Get 3DS report for a single day

```sql
EXEC Billing.Daily3dReport
    @StartDate = '2026-03-17',
    @EndDate = '2026-03-18'
```

### 8.2 Check 3DS success rate for a date range

```sql
-- After running the report, summarize authentication outcomes
SELECT
    AuthenticationCode,
    COUNT(*) AS Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(10,2)) AS Pct
FROM (
    EXEC Billing.Daily3dReport '2026-03-01', '2026-03-18'
) -- Note: Cannot directly query SP results; use the equivalent direct query instead
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.Daily3dReport | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.Daily3dReport.sql*
