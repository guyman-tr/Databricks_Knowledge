# Billing.GetDepositHistoryByDate

> Returns customer deposit history for display in the Payment History API, with masked credit card numbers, funding method labels, and account identifiers formatted per payment type.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns deposit rows for @CID since @FromDate, optionally filtered to a single @DepositID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositHistoryByDate` is the backend SP for the Payment History API - the service that shows customers their deposit history in the eToro platform UI. It formats deposit data for display: computing the USD equivalent amount, deriving a human-readable funding method label, and producing a masked/formatted account identifier per payment type (masked card number for credit cards, email for PayPal/Neteller, account ID for e-wallets).

Created in July 2014 (idanfe) as part of the original Payment History API. Redesigned in May 2016 (Geri, ticket 36605) to replace older CLR-based stored procedures.

The `@CreditCard4` parameter allows the caller to provide the last 4 digits of a credit card directly (avoiding XML decryption at the DB layer). If not provided, the procedure decrypts the last 4 digits from the `Billing.Funding.FundingData` XML using `CLR.Decrypt4`.

---

## 2. Business Logic

### 2.1 Payment-Type-Specific Account Identifier Display

**What**: The `AccountId` output column shows a human-readable identifier for the payment instrument used, formatted differently per payment method type.

**Columns/Parameters Involved**: `BFUN.FundingTypeID`, `BFUN.FundingData`, `@CreditCard4`, `AccountId (output)`

**Rules**:
- **FundingTypeID=1 (CreditCard)**: `'xxxx-xxxx-xxxx-' + COALESCE(@CreditCard4, CLR.Decrypt4(FundingData.value('/Funding[1]/CardNumberAsString[1]', 'VARCHAR(MAX)')))`  -> masked display using last 4 digits
- **FundingTypeID=3 (PayPal)**: Email from `FundingData.value('/Funding[1]/EmailAsString[1]')`
- **FundingTypeID=6 (Neteller)**: Account ID if non-zero (`'Account ' + AccountIDAsDecimal`), else email
- **FundingTypeID=7,10,11,14 (MoneyBookers/Skrill and similar)**: Account ID from `AccountIDAsDecimal`
- **FundingTypeID=8**: Email from `EmailAsString`
- **FundingTypeID=19 (Internal Payment)**: Literal string `'Internal Payment'`
- **All others**: Empty string `''`

**Diagram**:
```
FundingTypeID
  |
  +-- 1 (CreditCard) -> 'xxxx-xxxx-xxxx-' + [last 4 from @CreditCard4 or CLR.Decrypt4(XML)]
  +-- 3 (PayPal)     -> Email from FundingData XML
  +-- 6 (Neteller)   -> AccountID ('Account ' + ID) or Email if ID=0
  +-- 7,10,11,14     -> AccountID from FundingData XML
  +-- 8              -> Email from FundingData XML
  +-- 19             -> 'Internal Payment' (literal)
  +-- else           -> '' (empty)
```

### 2.2 FundingMethod Display Label

**What**: The `FundingMethod` output shows the display name of the payment method - card type for credit cards, or funding type name for others.

**Columns/Parameters Involved**: `BFUN.FundingTypeID`, `DCTY.Name`, `DFTY.Name`, `FundingMethod (output)`

**Rules**:
- `IIF(FundingTypeID=1, DCTY.Name, DFTY.Name)`
- FundingTypeID=1 (CreditCard): uses the specific card brand name from `Dictionary.CardType` (e.g., "Visa", "Mastercard") - resolved via `FundingData.value('Funding[1]/CardTypeIDAsInteger[1]', 'INT')` -> LEFT JOIN to `Dictionary.CardType`
- All other types: uses `Dictionary.FundingType.Name` (e.g., "Wire Transfer", "PayPal")

### 2.3 Optional Date Range + Deposit Filter

**What**: The WHERE clause supports flexible filtering: all deposits since @FromDate, or a single specific deposit if @DepositID is provided.

**Columns/Parameters Involved**: `@FromDate`, `@DepositID`

**Rules**:
- `BDEP.PaymentDate > @FromDate` - mandatory date lower bound
- `AND (ISNULL(@DepositID, 0) = 0 OR BDEP.DepositID = @DepositID)` - if @DepositID provided, restricts to that single deposit; if NULL/0, returns all deposits after @FromDate
- `OPTION (RECOMPILE)` - forces per-execution plan recompilation; prevents a cached plan optimized for NULL @DepositID from being used when a specific DepositID is provided (dramatically different data volume)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters deposits to this customer via Billing.Deposit.CID. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Inclusive lower bound for PaymentDate. Returns deposits where PaymentDate > @FromDate. Used to implement pagination by date for the Payment History API. |
| 3 | @DepositID | INT | YES | NULL | CODE-BACKED | Optional filter to a single deposit. NULL = return all deposits since @FromDate. Non-null = return only this deposit (used for single-deposit detail lookups). |
| 4 | @CreditCard4 | VARCHAR(4) | YES | NULL | CODE-BACKED | Optional last 4 digits of a credit card. If provided, used directly in the masked AccountId display instead of decrypting from FundingData XML via CLR.Decrypt4. Optimization for callers that already have the last 4 digits cached. |
| 5 | DepositID (output) | INT | NO | - | CODE-BACKED | Primary key of the deposit. From Billing.Deposit.DepositID. |
| 6 | Amount (output) | MONEY | NO | - | CODE-BACKED | Deposit amount in deposit currency (CurrencyID). Stored in dollars. |
| 7 | Currency (output) | VARCHAR | NO | - | CODE-BACKED | Currency abbreviation (e.g., 'USD', 'EUR', 'GBP'). From Dictionary.Currency.Abbreviation. Human-readable currency label for display. |
| 8 | ExchangeRate (output) | dbo.dtPrice | YES | - | CODE-BACKED | Exchange rate from deposit currency to USD at processing time. |
| 9 | PaymentStatusID (output) | INT | NO | - | CODE-BACKED | Deposit processing status. References Dictionary.PaymentStatus. Joined but status name not exposed - caller resolves status name. |
| 10 | OperationType (output) | VARCHAR(7) | NO | - | CODE-BACKED | Literal constant 'Deposit'. Identifies this row as a deposit operation in the Payment History API result set (which may include other operation types in other queries). |
| 11 | PaymentDate (output) | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the deposit record was created (submission time). |
| 12 | amountInUsd (output) | MONEY | NO | - | CODE-BACKED | Computed: Amount * ExchangeRate. Approximate USD equivalent of the deposit amount. Used for display and reporting purposes. |
| 13 | FundingTypeName (output) | NVARCHAR | NO | - | CODE-BACKED | Name of the funding type from Dictionary.FundingType.Name (e.g., 'Credit Card', 'Wire Transfer', 'PayPal'). |
| 14 | FundingMethod (output) | NVARCHAR | NO | - | CODE-BACKED | Payment method display label. For CreditCard (FundingTypeID=1): the specific card brand name from Dictionary.CardType (e.g., 'Visa', 'MasterCard'). For all other types: same as FundingTypeName. |
| 15 | AccountId (output) | VARCHAR/NVARCHAR | YES | - | CODE-BACKED | Masked/formatted payment instrument identifier for display. Format varies by FundingTypeID: CreditCard='xxxx-xxxx-xxxx-{last4}', PayPal/Neteller(no ID)=email, Neteller(with ID)='Account {ID}', MoneyBookers/similar=AccountID, InternalPayment='Internal Payment', others=''. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit.CID | Lookup | Filters deposits to the specified customer |
| FundingID | Billing.Funding.FundingID | INNER JOIN | Retrieves payment instrument details and FundingData XML |
| FundingTypeID | Dictionary.FundingType | INNER JOIN | Retrieves FundingTypeName for display |
| CardTypeIDAsInteger (from XML) | Dictionary.CardType | LEFT JOIN | Retrieves card brand name (Visa, Mastercard) for FundingMethod display |
| CurrencyID | Dictionary.Currency | INNER JOIN | Retrieves currency abbreviation for display |
| PaymentStatusID | Dictionary.PaymentStatus | INNER JOIN | Joined but not exposed in output (status name not returned) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin users have access (may be used for ad-hoc customer deposit history queries) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositHistoryByDate (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
├── Dictionary.CardType (table)
├── Dictionary.Currency (table)
└── Dictionary.PaymentStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ NOLOCK - primary source for deposit data; filtered by CID and PaymentDate |
| Billing.Funding | Table | READ NOLOCK - INNER JOIN for FundingData XML and FundingTypeID |
| Dictionary.FundingType | Table | READ NOLOCK - INNER JOIN for FundingTypeName |
| Dictionary.CardType | Table | READ NOLOCK - LEFT JOIN for card brand name (FundingMethod for credit cards) |
| Dictionary.Currency | Table | READ NOLOCK - INNER JOIN for Currency abbreviation |
| Dictionary.PaymentStatus | Table | READ NOLOCK - INNER JOIN (status name not exposed in output) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins (BI admin service) | DB User | Ad-hoc deposit history queries |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | Forces plan recompilation per execution. Prevents plan caching issues caused by the conditional @DepositID filter, which changes the effective query shape dramatically (all deposits vs. single deposit). |
| CLR.Decrypt4 | Security | CLR function decrypts the last 4 digits of a credit card from the encrypted XML in FundingData.CardNumberAsString. Only called when @CreditCard4 is not provided by the caller. |
| XML value() calls | Design | Multiple `FundingData.value(...)` XQuery expressions extract fields from the FundingData XML column; performance dependent on primary/secondary XML indexes on Billing.Funding. |

---

## 8. Sample Queries

### 8.1 Get deposit history for a customer since a date

```sql
EXEC Billing.GetDepositHistoryByDate
    @CID = 12345,
    @FromDate = '2024-01-01';
```

### 8.2 Get a single deposit's history record

```sql
EXEC Billing.GetDepositHistoryByDate
    @CID = 12345,
    @FromDate = '2000-01-01',  -- far past to ensure deposit is included
    @DepositID = 987654;
```

### 8.3 Get deposit history with known last 4 card digits (avoid CLR decryption)

```sql
EXEC Billing.GetDepositHistoryByDate
    @CID = 12345,
    @FromDate = '2024-01-01',
    @CreditCard4 = '1234';  -- pre-known last 4 digits, skips CLR.Decrypt4
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers (PROD_BIadmins) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositHistoryByDate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositHistoryByDate.sql*
