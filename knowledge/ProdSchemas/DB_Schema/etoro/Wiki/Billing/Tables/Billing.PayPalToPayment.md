# Billing.PayPalToPayment

> Legacy PayPal payment detail store. Each row links a PayPal account (Billing.PayPal) to a Billing.Payment and holds the payer email, PayerID, name, country, token, and transaction reference returned by the PayPal gateway callback. Currently 0 rows - legacy table, no longer populated in the modern deposit flow. Two-step lifecycle: initial INSERT has only PayPalID+PaymentID; PayPalToPaymentEdit populates payer details on IPN/callback. NONCLUSTERED PK (heap) with 3 supporting NC indexes. PayerFirstName and PayerLastName are DDM-masked.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (PayPalID, PaymentID) - PRIMARY KEY NONCLUSTERED (heap) |
| **Row Count** | 0 rows (empty - legacy, not populated) |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 NONCLUSTERED PK on (PayPalID, PaymentID); 3 NONCLUSTERED on CountryID, PaymentID, PayPalID (all FILLFACTOR=90) |

---

## 1. Business Meaning

`Billing.PayPalToPayment` is the PayPal-specific detail record for a legacy payment. When a customer deposited via PayPal, `Billing.PaymentByPayPalAdd` atomically created:

1. **`Billing.Payment`** - the financial transaction (FundingTypeID=3 hardcoded for PayPal)
2. **`Billing.PayPal`** - the PayPal account identity (PayPalEmailAccount) - upserted by email
3. **`Billing.PayPalToPayment`** (this table) - initially only the (PayPalID, PaymentID) link

After the PayPal IPN/callback, `Billing.PayPalToPaymentEdit` populates all payer details: email (`Payer`), country (`CountryID` resolved from ISO abbreviation via `Dictionary.Country`), `PayerFirstName`, `PayerLastName`, `Token`, and `TransactionID`.

**Two-step lifecycle**:
- Step 1 (PaymentByPayPalAdd): `INSERT (PayPalID, PaymentID)` - all other columns NULL
- Step 2 (PayPalToPaymentEdit): `UPDATE SET Payer, CountryID, PayerFirstName, PayerLastName, Token, TransactionID` on IPN callback

**CountryID resolution**: `PayPalToPaymentEdit` takes @PayerCountry as a 3-char ISO abbreviation (`CHAR(3)`) and resolves it to `Dictionary.Country.CountryID` via `WHERE Abbreviation = @PayerCountry`. This is the only place in this table where country is set.

**DDM masking**: PayerFirstName and PayerLastName carry `MASKED WITH (FUNCTION = 'default()')`. Non-privileged users see empty strings. Payer (email) and PayerID are NOT masked.

**FundingTypeID routing**: `Billing.GetPaymentData(@PaymentID, @FundingTypeID=3)` returns from this table. `Billing.GetPaymentByTransaction` also queries PayPalToPayment.

**Legacy status**: 0 rows. Modern PayPal deposits route through Billing.Deposit + Billing.Funding.

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **PayPalID** | int | NOT NULL | - | Billing.PayPal(PayPalID) | [CODE-BACKED] The PayPal account used. Explicit FK. Part of composite PK. Lookup to PayPal.PayPalEmailAccount for the account email. |
| **PaymentID** | int | NOT NULL | - | Billing.Payment(PaymentID) | [CODE-BACKED] The financial transaction. Explicit FK. Part of composite PK. One-to-one: each payment has one PayPalToPayment row. |
| **CountryID** | int | NULL | - | Dictionary.Country(CountryID) | [CODE-BACKED] Payer's country as reported by PayPal. Explicit FK. NULL at insert; populated by PayPalToPaymentEdit via ISO abbreviation lookup. |
| **Payer** | varchar(150) | NULL | - | - | [CODE-BACKED] PayPal payer email address as returned by gateway (not the PayPal account email from Billing.PayPal - may differ). NULL at insert. Max 150 chars. |
| **PayerID** | varchar(10) | NULL | - | - | [CODE-BACKED] PayPal's internal payer identifier (short alphanumeric, e.g., "ABCDE12345"). NULL at insert; populated on callback. Max 10 chars. |
| **PayerFirstName** | varchar(150) | NULL | - | - | [CODE-BACKED] [DDM MASKED] Payer first name from PayPal. Masked with `default()`. NULL at insert; populated by PayPalToPaymentEdit. Max 150 chars. |
| **PayerLastName** | varchar(150) | NULL | - | - | [CODE-BACKED] [DDM MASKED] Payer last name from PayPal. Masked with `default()`. NULL at insert; populated by PayPalToPaymentEdit. Max 150 chars. |
| **Token** | varchar(50) | NULL | - | - | [CODE-BACKED] PayPal checkout token from the session (IPN token). NULL at insert; populated on callback. Max 50 chars. |
| **TransactionID** | varchar(50) | NULL | - | - | [CODE-BACKED] PayPal transaction reference number from gateway. NULL at insert; populated on callback. Max 50 chars. |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BPPP | NONCLUSTERED | (PayPalID ASC, PaymentID ASC) | FILLFACTOR=90. NONCLUSTERED PK -> table is a heap. ON [MAIN]. |
| BPPP_COUNTRY | NONCLUSTERED | CountryID ASC | FILLFACTOR=90. Supports country-level reporting. |
| BPPP_PAYMENT | NONCLUSTERED | PaymentID ASC | FILLFACTOR=90. Enables PaymentID-first seeks (PK leading column is PayPalID). |
| BPPP_PAYPAL | NONCLUSTERED | PayPalID ASC | FILLFACTOR=90. PayPalID-first seeks (partially overlaps PK). |

---

## 4. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.PaymentByPayPalAdd` | Step 1 writer: creates Payment (FundingTypeID=3) + upserts PayPal account + inserts (PayPalID, PaymentID). Also writes History.Payment. |
| `Billing.PayPalToPaymentEdit` | Step 2 writer: updates Payer, CountryID (from ISO abbreviation), PayerFirstName, PayerLastName, Token, TransactionID on IPN/gateway callback. |
| `Billing.LoadPayPalToPayment` | Simple SELECT * reader; full table dump. |
| `Billing.GetPaymentData` | Routes by FundingTypeID: returns PayPalToPayment row for FundingTypeID=3. |
| `Billing.GetPaymentDetails` | Detailed payment retrieval across payment types. |
| `Billing.GetPaymentByTransaction` | Queries across payment-type tables including PayPalToPayment. |
| `Billing.CustomerRemove` | Deletes PayPalToPayment rows as part of GDPR/customer data removal. |

---

## 5. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.PayPal | Many-to-one | PayPalToPayment.PayPalID = PayPal.PayPalID | Explicit FK. The PayPal account identity (PayPalEmailAccount). One account can have many payments. |
| Billing.Payment | Many-to-one | PayPalToPayment.PaymentID = Payment.PaymentID | Explicit FK. The financial transaction. One-to-one in practice. |
| Dictionary.Country | Many-to-one | PayPalToPayment.CountryID = Country.CountryID | Explicit FK. Payer country resolved from ISO abbreviation on callback. |

---

*Quality: 9.0/10 | 9 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,5,8,9,11 | Legacy table - 0 rows in production*
