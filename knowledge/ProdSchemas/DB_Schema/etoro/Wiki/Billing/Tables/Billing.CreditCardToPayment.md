# Billing.CreditCardToPayment

> Legacy credit card payment detail store. Each row holds the billing address and cardholder contact information captured at the moment a credit card payment was made in the legacy Billing.Payment system. Currently 0 rows - the table is structurally intact but no longer populated (modern deposits use Billing.Deposit + Billing.Funding). Five PII columns are masked with Dynamic Data Masking. Part of the legacy three-table CC pattern: CreditCard (card number) + Payment (amount/status) + CreditCardToPayment (billing details).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CardID, PaymentID) - PRIMARY KEY CLUSTERED |
| **Row Count** | 0 rows (empty - legacy, not populated) |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 CLUSTERED PK on (CardID, PaymentID); 5 NONCLUSTERED on BankID, CardID, CountryID, PaymentID, StateID (all FILLFACTOR=90) |

---

## 1. Business Meaning

`Billing.CreditCardToPayment` is the billing address detail record for a legacy credit card payment. When a customer made a deposit using a credit card, `Billing.PaymentByCreditCardAdd` atomically created three records:

1. **`Billing.Payment`** - the financial transaction (amount, currency, status, FundingTypeID=1)
2. **`Billing.CreditCard`** - the card identity (card number, CVV, card type) - upserted by card number
3. **`Billing.CreditCardToPayment`** (this table) - the billing contact snapshot (name, email, phone, address, country, state, bank)

This separation allowed the same card (same CreditCard row) to be used in multiple payments while keeping a distinct billing address/cardholder contact snapshot per transaction. The cardholder details here reflect what was submitted at the time of the specific payment and may differ across payments from the same card.

**Legacy status**: The table has 0 rows. The modern deposit flow uses `Billing.Deposit`, `Billing.Funding`, and `Billing.WithdrawToFunding` - none of which store cardholder contact details in this format. The legacy Billing.Payment flow (and this table) has been retired from active use.

**PII protection**: Five columns carry Dynamic Data Masking (`MASKED WITH (FUNCTION = 'default()')`): CardHolderFirstName, CardHolderLastName, CardHolderEmail, CardHolderPhoneNumber, ZipCode. Users without UNMASK permission see blank values for these columns.

**FundingTypeID routing**: `Billing.GetPaymentData(@PaymentID, @FundingTypeID=1)` returns from this table. FundingTypeID=2 -> WireTransferToPayment; FundingTypeID=3 -> PayPalToPayment; FundingTypeID=6/7 -> NetellerToPayment.

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **CardID** | int | NOT NULL | - | Billing.CreditCard(CardID) | [CODE-BACKED] The credit card used. FK to CreditCard (card number + CVV). Part of composite PK. Lookup to CreditCard.CardNumber for the actual card digits. |
| **PaymentID** | int | NOT NULL | - | Billing.Payment(PaymentID) | [CODE-BACKED] The payment this billing record belongs to. FK to Payment. Part of composite PK. One-to-one: each payment has exactly one CreditCardToPayment row. |
| **CountryID** | int | NOT NULL | - | Dictionary.Country(CountryID) | [CODE-BACKED] Customer's billing country at time of payment. Explicit FK. Used in NC index BC2P_COUNTRY. |
| **StateID** | int | NOT NULL | - | Dictionary.State(StateID) | [CODE-BACKED] Customer's billing state/region at time of payment. Explicit FK. Used in NC index BC2P_STATE. Required even for non-US countries (default/unknown state). |
| **BankID** | int | NOT NULL | - | Dictionary.Bank(BankID) | [CODE-BACKED] Acquiring/issuing bank for the card. Explicit FK. Used in NC index BC2P_BANK. BankID=0 = UNKNOWN in legacy data (per BankToDepot/BankToTerminal context). |
| **ExpirationDate** | char(10) | NOT NULL | - | - | [CODE-BACKED] Card expiration date as submitted. Fixed 10-char format (e.g., "MM/YY" or "MM/YYYY" padded). Not stored in CreditCard table itself. |
| **CardHolderAddress** | varchar(250) | NOT NULL | - | - | [CODE-BACKED] Street address of cardholder as submitted at payment time. Not masked. Max 250 chars. |
| **CardHolderFirstName** | varchar(100) | NOT NULL | - | - | [CODE-BACKED] [DDM MASKED] Cardholder first name. Masked with `default()` - non-privileged users see empty string. Max 100 chars. |
| **CardHolderLastName** | varchar(100) | NOT NULL | - | - | [CODE-BACKED] [DDM MASKED] Cardholder last name. Masked with `default()`. Max 100 chars. |
| **CardHolderEmail** | varchar(50) | NOT NULL | - | - | [CODE-BACKED] [DDM MASKED] Cardholder contact email. Masked with `default()`. Max 50 chars. |
| **CardHolderPhoneNumber** | varchar(50) | NOT NULL | - | - | [CODE-BACKED] [DDM MASKED] Cardholder phone number. Masked with `default()`. Max 50 chars. |
| **City** | nvarchar(50) | NOT NULL | - | - | [CODE-BACKED] Billing city. nvarchar (supports Unicode) unlike varchar address fields. Max 50 chars. |
| **ZipCode** | nvarchar(50) | NOT NULL | - | - | [CODE-BACKED] [DDM MASKED] Billing postal code. nvarchar. Masked with `default()`. Max 50 chars. |
| **ProcessingTerminal** | int | NULL | - | - | [CODE-BACKED] Terminal used to process this payment. NULL allowed. Corresponds to @ProcessingTerminal in PaymentByCreditCardAdd (distinct from TerminalID on Payment row itself). |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BC2P | CLUSTERED | (CardID ASC, PaymentID ASC) | FILLFACTOR=90. ON [MAIN]. Natural composite key - finds all payments for a card. |
| BC2P_BANK | NONCLUSTERED | BankID ASC | FILLFACTOR=90. Supports bank-level reporting/lookup. |
| BC2P_CARD | NONCLUSTERED | CardID ASC | FILLFACTOR=90. Redundant with PK leading column but may be used for CardID-only seeks. |
| BC2P_COUNTRY | NONCLUSTERED | CountryID ASC | FILLFACTOR=90. Supports country-level reporting. |
| BC2P_PAYMENT | NONCLUSTERED | PaymentID ASC | FILLFACTOR=90. Enables PaymentID-first lookup (the PK leading column is CardID). |
| BC2P_STATE | NONCLUSTERED | StateID ASC | FILLFACTOR=90. Supports state-level reporting. |

---

## 4. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.PaymentByCreditCardAdd` | Only writer: atomically creates Payment + upserts CreditCard + inserts CreditCardToPayment with all billing details. Also writes History.Payment. |
| `Billing.LoadCreditCardToPayment` | Simple SELECT * reader; full table dump. |
| `Billing.GetPaymentData` | Routes by FundingTypeID: returns CreditCardToPayment rows when FundingTypeID=1. |
| `Billing.GetPaymentByTransaction` | Queries payment details across payment types including CC. |
| `Billing.GetPaymentDetails` | Detailed payment retrieval; joins multiple payment-type tables. |
| `Billing.CheckFundingTypeLimitByCCNumber` | Uses CreditCardToPayment in card number limit checks. |
| `Billing.CustomerRemove` | Deletes CreditCardToPayment rows as part of GDPR/customer data removal. |

---

## 5. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.CreditCard | Many-to-one | CreditCardToPayment.CardID = CreditCard.CardID | Explicit FK. The card identity (number, type, CVV). One card can have multiple payment rows. |
| Billing.Payment | Many-to-one | CreditCardToPayment.PaymentID = Payment.PaymentID | Explicit FK. The financial transaction. One-to-one in practice (each payment has one CC detail row). |
| Dictionary.Bank | Many-to-one | CreditCardToPayment.BankID = Bank.BankID | Explicit FK. The issuing/acquiring bank for the card. |
| Dictionary.Country | Many-to-one | CreditCardToPayment.CountryID = Country.CountryID | Explicit FK. Billing country. |
| Dictionary.State | Many-to-one | CreditCardToPayment.StateID = State.StateID | Explicit FK. Billing state/region. |

---

*Quality: 9.0/10 | 14 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,5,8,9,11 | Legacy table - 0 rows in production*
