# Billing.GetDeposit

> Returns core deposit transaction data for a single deposit ID, with Amount converted to integer cents (x100), used primarily by the SecurePay payment gateway integration.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from Billing.Deposit keyed by DepositID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDeposit` is a focused lookup procedure that retrieves the core transaction attributes for a single deposit by its primary key. It is used by the `SQL_SecurePay` database user, indicating it is called by the SecurePay payment gateway integration service when it needs to retrieve deposit details - for example, during payment processing, callback handling, or reconciliation.

The procedure selects a minimal but essential set of 10 columns from `Billing.Deposit`, specifically the fields needed to identify the transaction (IDs), route it (FundingID, ProtocolMIDSettingsID), and process the amount (Amount in cents, CurrencyID, ExchangeRate). Notably, the procedure returns `Amount` multiplied by 100 and cast to INTEGER, converting from the money-stored dollars to integer cents.

Without this procedure, the payment gateway service would need ad-hoc SELECT access to the full `Billing.Deposit` table. The SP encapsulates the projection and ensures consistent column exposure.

---

## 2. Business Logic

### 2.1 Amount Unit Conversion: Dollars to Cents

**What**: The `Amount` column in `Billing.Deposit` is stored as MONEY (dollars), but this procedure returns it as INTEGER cents.

**Columns/Parameters Involved**: `Billing.Deposit.Amount`, `Amount (output)`

**Rules**:
- `CAST(BDEP.Amount * 100 AS INTEGER) AS Amount`
- `Billing.Deposit.Amount` stores values in USD (e.g., 100.00 = $100)
- This procedure returns 10000 for a $100 deposit (cents representation)
- The conversion implies the calling system (SecurePay integration) works in integer cents, a common pattern in payment gateway APIs to avoid floating point issues
- RETURN 0 signals successful execution with no error

**Diagram**:
```
Input: @DepositID
  |
  v
Billing.Deposit WHERE DepositID = @DepositID
  |
  +-- Amount (MONEY, dollars) -> Amount * 100 -> CAST AS INTEGER (cents)
  |
  v
Output: 10 columns with Amount in integer cents
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | CODE-BACKED | The primary key of the deposit to retrieve. Maps to Billing.Deposit.DepositID (IDENTITY PK). |
| 2 | DepositID (output) | INT | NO | - | CODE-BACKED | Primary key of the deposit row. Inherited from Billing.Deposit: IDENTITY(1,1) surrogate key for the deposit transaction. |
| 3 | CID (output) | INT | NO | - | CODE-BACKED | Customer ID of the depositing customer. References Customer.CustomerStatic.CID / Customer.Customer.CID. |
| 4 | FundingID (output) | INT | NO | - | CODE-BACKED | The payment instrument used for this deposit. References Billing.Funding.FundingID (credit card, bank account, e-wallet record). |
| 5 | CurrencyID (output) | INT | NO | - | CODE-BACKED | Currency of the deposit amount. References Dictionary.Currency (e.g., 1=USD, 2=EUR). |
| 6 | PaymentStatusID (output) | INT | NO | - | CODE-BACKED | Current processing status of the deposit. References Dictionary.PaymentStatus (e.g., 1=New, 2=Approved, 3=Declined). See Billing.Deposit Section 2.1 for full state machine. |
| 7 | Amount (output) | INTEGER | NO | - | CODE-BACKED | Deposit amount in INTEGER CENTS (not dollars). Computed: CAST(Billing.Deposit.Amount * 100 AS INTEGER). A $100 deposit returns 10000. The calling system (SecurePay) expects cents-based integer amounts. |
| 8 | ExchangeRate (output) | FLOAT/DECIMAL | YES | - | CODE-BACKED | Exchange rate applied at deposit time to convert from deposit currency to USD. From Billing.Deposit.ExchangeRate. |
| 9 | PaymentDate (output) | DATETIME | YES | - | CODE-BACKED | The timestamp when the deposit was approved/processed. From Billing.Deposit.PaymentDate. |
| 10 | TransactionID (output) | CHAR(6) | NO | - | CODE-BACKED | Short alphanumeric transaction reference code. From Billing.Deposit.TransactionID. Used for provider-side cross-reference. |
| 11 | ProtocolMIDSettingsID (output) | INT | YES | - | CODE-BACKED | The MID (Merchant ID) settings configuration used to process this deposit. References Billing.ProtocolMIDSettings. Identifies the specific merchant account and routing configuration that handled this transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit.DepositID | Lookup | Primary key lookup - retrieves one deposit row |
| FundingID | Billing.Funding.FundingID | Implicit | References the payment instrument used |
| CurrencyID | Dictionary.Currency | Implicit | References deposit currency |
| PaymentStatusID | Dictionary.PaymentStatus | Implicit | References deposit status |
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | Implicit | References merchant account routing config |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay | GRANT EXECUTE | Permission | Called by the SecurePay payment gateway integration to retrieve deposit data during processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDeposit (procedure)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT NOLOCK - retrieves 10 columns by DepositID PK lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay (SecurePay integration service) | DB User | Calls this SP to read deposit details during payment gateway processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN 0 | Return code | Explicit success return code (0) after successful execution |
| SET NOCOUNT ON | Setting | Suppresses row-count messages |
| Amount * 100 | Transformation | Converts money (dollars) to integer cents for gateway compatibility |

---

## 8. Sample Queries

### 8.1 Retrieve deposit details by ID

```sql
EXEC Billing.GetDeposit @DepositID = 987654;
```

### 8.2 Inline equivalent with dollar amount

```sql
SELECT
    DepositID, CID, FundingID, CurrencyID, PaymentStatusID,
    Amount,                                  -- original dollars
    CAST(Amount * 100 AS INTEGER) AS AmountCents,  -- cents (what SP returns)
    ExchangeRate, PaymentDate, TransactionID, ProtocolMIDSettingsID
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 987654;
```

### 8.3 Find deposits with their status labels

```sql
SELECT
    d.DepositID,
    d.CID,
    CAST(d.Amount * 100 AS INTEGER) AS AmountCents,
    d.CurrencyID,
    ps.PaymentStatus AS StatusName
FROM Billing.Deposit d WITH (NOLOCK)
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK)
    ON d.PaymentStatusID = ps.PaymentStatusID
WHERE d.DepositID = 987654;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers (SQL_SecurePay service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDeposit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDeposit.sql*
