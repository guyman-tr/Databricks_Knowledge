# Billing.NetellerToPayment

> Legacy Neteller e-wallet payment detail store. Each row links a Neteller account (Billing.Neteller) to a Billing.Payment and stores the Neteller transaction reference, payer name, and email as returned by the Neteller gateway callback. 5,745 rows; 1,687 unique Neteller accounts. Two-step lifecycle: initial INSERT contains only NetellerID+PaymentID, then PaymentByNetellerEdit populates TransactionID, FirstName, LastName, Email on gateway callback. NONCLUSTERED PK means the table is a heap with 3 supporting NC indexes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (NetellerID, PaymentID) - PRIMARY KEY NONCLUSTERED (heap) |
| **Row Count** | 5,745 rows; 1,687 unique Netellers, 5,745 unique payments |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 NONCLUSTERED PK on (NetellerID, PaymentID); 3 NONCLUSTERED on Email, NetellerID, PaymentID (all FILLFACTOR=90) |

---

## 1. Business Meaning

`Billing.NetellerToPayment` is the Neteller-specific detail record for a legacy credit card / e-wallet payment. When a customer deposited using a Neteller account, `Billing.PaymentByNetellerAdd` atomically created:

1. **`Billing.Payment`** - the financial transaction (amount, currency, FundingTypeID=6 or 7)
2. **`Billing.Neteller`** - the Neteller account identity (AccountID + SecureID) - upserted by AccountID
3. **`Billing.NetellerToPayment`** (this table) - initially just the (NetellerID, PaymentID) link

The payer details (Email, FirstName, LastName, TransactionID) are NOT available at insert time. They are populated later via `Billing.PaymentByNetellerEdit` when the Neteller gateway callback confirms the transaction and returns the account holder's details.

**Two-step lifecycle**:
- Step 1 (PaymentByNetellerAdd): `INSERT (NetellerID, PaymentID)` - all other columns NULL
- Step 2 (PaymentByNetellerEdit): `UPDATE SET Email=..., TransactionID=..., FirstName=..., LastName=...` on gateway callback

**FundingTypeID routing**: `Billing.GetPaymentData` returns from this table for BOTH FundingTypeID=6 (Neteller) and FundingTypeID=7 (appears to be a Neteller variant - MoneyBookers/Skrill may have used same table).

**No DDM masking**: Unlike CreditCardToPayment, the name and email columns here are unmasked. This may reflect the legacy state of the table before DDM was applied to the Billing schema, or the reduced PII sensitivity of e-wallet data vs. card data.

**Legacy status**: Active with 5,745 rows; payment IDs range from 16,179 to 347,795, indicating this table was populated in the legacy payment era. No new inserts in the modern deposit flow.

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **NetellerID** | int | NOT NULL | - | Billing.Neteller(NetellerID) | [CODE-BACKED] The Neteller account used for this payment. Explicit FK. Part of composite PK. Lookup to Neteller.AccountID and Neteller.SecureID for account identity. |
| **PaymentID** | int | NOT NULL | - | Billing.Payment(PaymentID) | [CODE-BACKED] The payment this Neteller record belongs to. Explicit FK. Part of composite PK. One-to-one: each payment has one NetellerToPayment row. |
| **TransactionID** | varchar(50) | NULL | - | - | [CODE-BACKED] Neteller's transaction reference number (e.g., "269289034075865", "615289033972862"). Populated by gateway callback via PaymentByNetellerEdit. NULL until callback. 15-digit numeric string format observed in live data. |
| **FirstName** | nvarchar(50) | NULL | - | - | [CODE-BACKED] Neteller account holder first name. nvarchar (Unicode). Populated by PaymentByNetellerEdit on callback. NULL at insert. Max 50 chars. |
| **LastName** | nvarchar(50) | NULL | - | - | [CODE-BACKED] Neteller account holder last name. nvarchar (Unicode). Populated by PaymentByNetellerEdit on callback. NULL at insert. Max 50 chars. |
| **Email** | varchar(255) | NULL | - | - | [CODE-BACKED] Neteller account email address. varchar (not nvarchar). Populated by PaymentByNetellerEdit. NULL at insert. NC index BN2P_EMAIL supports email-based lookups. Max 255 chars. |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BN2P | NONCLUSTERED | (NetellerID ASC, PaymentID ASC) | FILLFACTOR=90. NONCLUSTERED PK -> table is a heap. ON [MAIN]. |
| BN2P_EMAIL | NONCLUSTERED | Email ASC | FILLFACTOR=90. Supports lookup by email (e.g., finding all payments for a Neteller email). |
| BN2P_NETELLER | NONCLUSTERED | NetellerID ASC | FILLFACTOR=90. NetellerID-first seeks (PK also starts with NetellerID, so partial overlap). |
| BN2P_PAYMENT | NONCLUSTERED | PaymentID ASC | FILLFACTOR=90. Supports PaymentID-first lookup (PK leading column is NetellerID). |

---

## 4. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.PaymentByNetellerAdd` | Step 1 writer: creates Payment (FundingTypeID=6/7) + upserts Neteller + inserts (NetellerID, PaymentID) link. No name/email at this stage. Also writes History.Payment. |
| `Billing.PaymentByNetellerEdit` | Step 2 writer: updates Email, TransactionID, FirstName, LastName on Neteller gateway callback. Also updates Payment.ExchangeRate, TotalFee, DirectAcceptFee and Neteller.SecureID. |
| `Billing.LoadNetellerToPayments` | Simple SELECT * reader; full table dump. |
| `Billing.GetPaymentData` | Routes by FundingTypeID: returns NetellerToPayment row for FundingTypeID=6 or 7. |
| `Billing.GetPaymentDetails` | Detailed payment retrieval across payment types. |
| `Billing.GetPaymentByTransaction` | Queries across payment type tables including NetellerToPayment. |
| `Billing.CustomerRemove` | Deletes NetellerToPayment rows as part of GDPR/customer data removal. |

---

## 5. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Neteller | Many-to-one | NetellerToPayment.NetellerID = Neteller.NetellerID | Explicit FK. The Neteller account (AccountID, SecureID). One Neteller account can have many payments. |
| Billing.Payment | Many-to-one | NetellerToPayment.PaymentID = Payment.PaymentID | Explicit FK. The financial transaction. One-to-one in practice. |

---

*Quality: 9.0/10 | 6 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,5,8,9,11*
