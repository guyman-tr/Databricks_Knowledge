# Billing.BI_Deposit_PIPS_Report

> BI reporting procedure that returns approved deposit records with provider fee (PIPsInUSD) and fee percentage calculations for a date window, combining both archived (History.Deposit) and current (Billing.Deposit) approved deposits into a single UNION ALL resultset.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset (CID, DepositID, FundingID, DepotID, Amount, CurrencyID, AmountUSD, CardType, CardCategory, PIPsInUSD, FeeInPercentage, MID, MIDName, ...) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BI_Deposit_PIPS_Report` provides the BI team with deposit-level fee analysis. For each approved deposit in the date window, it returns the raw amounts alongside the provider interchange fee (PIPs in USD) and the fee as a percentage of the deposit amount. This enables analysis of payment provider profitability, cost-per-deposit trends, and MID-level fee comparison.

The procedure covers two data sources: the historical archive (`History.Deposit`) and the current active table (`Billing.Deposit`). The UNION ALL ensures approved deposits are not missed regardless of which table holds the active record. Deposits are only included if their final status is Approved (PaymentStatusID=2, checked via a self-join on History.Deposit to get the confirmed final state) and they have a real processing depot (DepotID <> 0).

Card metadata (type and category/product class) is extracted from the XML FundingData field of the Billing.Funding record.

---

## 2. Business Logic

### 2.1 Dual-Source UNION ALL (Active + Historical)

**What**: The report covers both current and archived deposit records to ensure complete coverage.

**Parameters/Columns Involved**: `@StartPoint`, `@EndPoint`, `History.Deposit`, `Billing.Deposit`

**Rules**:
- Part 1 (archived): `FROM History.Deposit as HD` with `INNER JOIN History.Deposit HD2 ON HD.DepositID = HD2.DepositID`.
  - Filter: `HD.ModificationDate >= @StartPoint AND HD.ModificationDate < @EndPoint AND HD2.PaymentStatusID = 2 AND HD.Occurred >= HD2.Occurred AND HD.DepotID <> 0`.
  - The HD2 self-join provides the final PaymentStatusID=2 (Approved) check: this ensures only ultimately-approved deposits are included even if an intermediate record has a different status.
  - `HD.Occurred >= HD2.Occurred`: takes the most recent or concurrent event record.
- Part 2 (current): `FROM Billing.Deposit as HD` with `INNER JOIN History.Deposit HD2 ON HD.DepositID = HD2.DepositID`.
  - Filter: `HD.ModificationDate >= @StartPoint AND HD.ModificationDate < @EndPoint AND HD2.PaymentStatusID = 2 AND HD.DepotID <> 0`.
  - Uses History.Deposit (HD2) as the final-status validator for current Billing.Deposit records.
- @EndPoint defaults to GETUTCDATE() if NULL.

### 2.2 Card Metadata from XML FundingData

**What**: Card type and card category are extracted from the XML-structured FundingData column on Billing.Funding.

**Parameters/Columns Involved**: `Billing.Funding.FundingData`, `Dictionary.CardType`, `Dictionary.CountryBin`

**Rules**:
- `CardTypeID = BF.FundingData.value('Funding[1]/CardTypeIDAsInteger[1]','INT')` -> LEFT JOIN Dictionary.CardType.
- `BinCode = BF.FundingData.value('Funding[1]/BinCodeAsString[1]','INT')` -> LEFT JOIN Dictionary.CountryBin.
- `COALESCE(DCT.Name, 'N/A')` as CardType: 'N/A' for non-card payment methods.
- `COALESCE(DCB.ProductType, 'N/A')` as CardCategory: product class (e.g., 'Debit', 'Prepaid', 'Credit', 'Business').

### 2.3 PIPsInUSD and FeeInPercentage

**What**: Provider fee calculated via scalar UDF, with percentage representation.

**Rules**:
- `PIPsInUSD = ISNULL(Billing.CalculateDepositPIPsUSD(HD.DepositID), 0)`.
- `FeeInPercentage = (PIPsInUSD / (HD.Amount * HD.ExchangeRate)) * 100`.
- Note: FeeInPercentage will produce a division-by-zero error if Amount*ExchangeRate=0. No guard exists in the code.

### 2.4 MID and MIDName

**What**: Merchant ID and description per deposit via table-valued function.

**Rules**:
- `(SELECT [MID] FROM Billing.GetMIDDescription(HD.DepositID, @DepositActionID=1)) as MID`
- `(SELECT [Description] FROM Billing.GetMIDDescription(HD.DepositID, @DepositActionID=1)) as MIDName`
- @DepositActionID=1 identifies this as a deposit (vs 2=cashout) context.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartPoint | DATETIME | NO | - | VERIFIED | Start of date window (inclusive). Filters History/Billing.Deposit.ModificationDate >= @StartPoint. |
| 2 | @EndPoint | DATETIME | YES | GETUTCDATE() | VERIFIED | End of date window (exclusive). Defaults to current UTC time if NULL. Filters ModificationDate < @EndPoint. |

**Result set columns** (same structure for both UNION parts):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | Deposit.CID | Customer ID. |
| 2 | DepositID | Deposit.DepositID | Deposit record primary key. |
| 3 | FundingID | Deposit.FundingID | Payment instrument ID. |
| 4 | DepotID | Deposit.DepotID | Processing depot / provider ID. Only non-zero values included. |
| 5 | PaymentStatusID | Deposit.PaymentStatusID | Deposit payment status (=2 Approved for all rows). |
| 6 | Amount | Deposit.Amount | Deposit amount in deposit currency. |
| 7 | CurrencyID | Deposit.CurrencyID | Currency of the deposit amount. |
| 8 | AmountUSD | Amount * ExchangeRate | USD equivalent of the deposit. |
| 9 | CardType | Dictionary.CardType.Name | Card network (e.g., Visa, Mastercard). 'N/A' for non-card instruments. |
| 10 | CardCategory | Dictionary.CountryBin.ProductType | Card product class (e.g., Debit, Credit, Prepaid). 'N/A' if not found. |
| 11 | BaseExchangeRate | Deposit.BaseExchangeRate | Provider base FX rate. |
| 12 | ExchangeFee | Deposit.ExchangeFee | Provider exchange fee amount. |
| 13 | ExchangeRate | Deposit.ExchangeRate | Effective exchange rate. |
| 14 | ExTransactionID | Deposit.ExTransactionID | External transaction ID from the payment provider. |
| 15 | ModificationDate | Deposit.ModificationDate | Last modification timestamp. |
| 16 | ProtocolMIDSettingsID | Deposit.ProtocolMIDSettingsID | Protocol MID settings configuration ID. |
| 17 | MerchantAccountID | Deposit.MerchantAccountID | Merchant account identifier. |
| 18 | PIPsInUSD | Billing.CalculateDepositPIPsUSD | Provider interchange fee in USD (0 if NULL). |
| 19 | FeeInPercentage | PIPsInUSD / AmountUSD * 100 | Fee as percentage of USD deposit amount. |
| 20 | MID | Billing.GetMIDDescription | Merchant ID code. |
| 21 | MIDName | Billing.GetMIDDescription | Human-readable merchant account name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HD (archived) | History.Deposit | READER | Source of archived approved deposit records. |
| HD (current) | Billing.Deposit | READER | Source of current approved deposit records. |
| HD2 (both parts) | History.Deposit | READER | Self-join to validate PaymentStatusID=2 (Approved). |
| HD.FundingID | Billing.Funding | READER | Payment instrument for XML card data extraction. |
| BF.FundingData (XML) | Dictionary.CardType | READER (LEFT JOIN) | Card type resolution from XML BIN code. |
| BF.FundingData (XML) | Dictionary.CountryBin | READER (LEFT JOIN) | Card product type from BIN range. |
| (func) | Billing.CalculateDepositPIPsUSD | EXEC (UDF) | Provider fee in USD per deposit. |
| (func) | Billing.GetMIDDescription | EXEC (TVF) | MID and merchant name per deposit. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from BI reporting systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_Deposit_PIPS_Report (procedure)
|- History.Deposit (table)                [SELECT + self-JOIN (status validator)]
|- Billing.Deposit (table)                [SELECT (current records)]
|- Billing.Funding (table)                [JOIN - XML card data extraction]
|- Dictionary.CardType (table)            [LEFT JOIN - card type name]
|- Dictionary.CountryBin (table)          [LEFT JOIN - card product class]
|- Billing.CalculateDepositPIPsUSD (func) [EXEC UDF - provider fee]
+- Billing.GetMIDDescription (func/TVF)   [EXEC - MID and description]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Deposit | Table | Archived deposit records (source) + status validator (self-join) |
| Billing.Deposit | Table | Current deposit records source |
| Billing.Funding | Table | XML-based card type and BIN code extraction |
| Dictionary.CardType | Table | Card network name from CardTypeID in FundingData XML |
| Dictionary.CountryBin | Table | Card product type from BIN code in FundingData XML |
| Billing.CalculateDepositPIPsUSD | Function | Provider interchange fee calculation per deposit |
| Billing.GetMIDDescription | Function/TVF | Merchant ID and name per deposit |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from BI reporting systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **XML data extraction**: CardTypeID and BinCode are stored inside the FundingData XML column. This is a performance consideration - XML parsing in a JOIN condition does not use standard column indexes.
- **Potential division by zero**: FeeInPercentage divides by `(HD.Amount * HD.ExchangeRate)`. If Amount=0 or ExchangeRate=0, this would produce a division-by-zero error. The filter `DepotID <> 0` does not protect against zero-amount deposits.
- **SELECT DISTINCT**: Both UNION parts use DISTINCT to handle cases where History.Deposit has multiple snapshot records for the same DepositID.
- **UNION ALL (not UNION)**: Allows duplicates between the two parts (History.Deposit and Billing.Deposit may both contain the same DepositID in transition periods). Callers may see duplicates for deposits that appear in both tables.

---

## 8. Sample Queries

### 8.1 Run PIPs report for a specific date range
```sql
EXEC Billing.BI_Deposit_PIPS_Report
    @StartPoint = '2026-03-01',
    @EndPoint   = '2026-03-17';
```

### 8.2 Run PIPs report from a date to now
```sql
EXEC Billing.BI_Deposit_PIPS_Report
    @StartPoint = '2026-03-01';  -- @EndPoint defaults to GETUTCDATE()
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BI_Deposit_PIPS_Report | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BI_Deposit_PIPS_Report.sql*
