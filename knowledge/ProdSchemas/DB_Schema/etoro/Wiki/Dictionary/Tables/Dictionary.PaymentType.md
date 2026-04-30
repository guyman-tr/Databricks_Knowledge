# Dictionary.PaymentType

> Lookup table defining the 3 high-level payment categories — Deposit, Cashout, and Refund — classifying every payment transaction by its financial direction and purpose.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PaymentTypeID (INT, PK NONCLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 3 (MCP verified) |
| **Indexes** | 2 active (PK nonclustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.PaymentType is a top-level classification that categorizes every payment transaction into one of three fundamental types: Deposit (money in), Cashout (money out), or Refund (money returned). This is distinct from Dictionary.FundingType (which classifies the payment *method* — credit card, wire transfer, PayPal, etc.) and Dictionary.PaymentActionType (which classifies the specific *operation* within a transaction).

PaymentTypeID is referenced extensively across the Billing schema — it drives payment routing via Billing.Depot (depot configuration per payment type), payment recording in Billing.Payment, terminal configuration in Billing.Terminal, and volume tracking in Billing.Volume. All four have explicit FK constraints to this table. Additionally, Billing.ACHBankAccount and Billing.MerchantAccountRouting use PaymentTypeID for method-specific routing without explicit FKs.

The most common usage pattern is filtering by PaymentTypeID=1 (Deposit) in procedures like Billing.DepositAdd, Billing.CheckFundingTypeLimit, and Billing.CheckMemberLimit — since deposits are the most frequent and regulated payment type.

---

## 2. Business Logic

### 2.1 Payment Type Classification

**What**: The three fundamental payment categories and their financial meaning.

**Columns/Parameters Involved**: `PaymentTypeID`, `Name`

**Rules**:
- **Deposit (1)**: Inbound funds from customer to eToro. Customer adds money to their trading account. Subject to funding limits, anti-fraud checks, AML verification. The most common PaymentTypeID — hard-coded as 1 throughout deposit procedures. Drives depot lookup (Billing.Depot), terminal selection, and merchant account routing.
- **Cashout (2)**: Outbound funds from eToro to customer. Customer withdraws money from their trading account. Subject to cashout policies, KYC verification, and approval workflows.
- **Refund (3)**: Return of previously deposited funds to the customer's original payment method. Differs from Cashout in that a Refund is linked to a specific prior Deposit transaction and may be mandated by dispute resolution, chargeback processing, or regulatory requirements.

**Diagram**:
```
Money Flow by Payment Type:

  Customer ──── Deposit (1) ────► eToro Account
  Customer ◄──── Cashout (2) ──── eToro Account
  Customer ◄──── Refund (3) ───── eToro Account
                                   (tied to specific deposit)
```

### 2.2 Payment Routing Architecture

**What**: How PaymentTypeID drives the payment processing infrastructure.

**Columns/Parameters Involved**: `PaymentTypeID`

**Rules**:
- **Billing.Depot** (FK): Each depot (payment processing configuration) is scoped to a payment type. A depot for deposits has different merchant/terminal/protocol configuration than one for cashouts.
- **Billing.Terminal** (FK): Payment terminals are configured per payment type — deposit terminals process charges, cashout terminals process payouts.
- **Billing.Payment** (FK): Every payment record is classified by type for reporting and reconciliation.
- **Billing.Volume** (FK): Volume tracking and limit enforcement is segmented by payment type.
- **Billing.MerchantAccountRouting**: Merchant account selection considers PaymentTypeID alongside country, currency, and card type.
- **Billing.ACHBankAccount / ACHBanks**: ACH bank configurations are scoped by payment type.

---

## 3. Data Overview

| PaymentTypeID | Name | Meaning |
|---|---|---|
| 1 | Deposit | Inbound payment — customer funds their eToro trading account. Subject to funding type limits, AML checks, and fraud screening. The primary payment type with the most extensive routing configuration. Hard-coded as PaymentTypeID=1 in DepositAdd, CheckFundingTypeLimit, CheckFundingTypeLimitByCCNumber, and CheckMemberLimit. |
| 2 | Cashout | Outbound payment — customer withdraws funds from their eToro account to their external payment method. Subject to cashout policies, verification requirements, and approval workflows. |
| 3 | Refund | Return payment — previously deposited funds are sent back to the customer's original payment method. Tied to a specific prior deposit transaction. May be triggered by chargeback, dispute resolution, or regulatory requirement. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentTypeID | int | NO | - | VERIFIED | Primary key identifying the payment category. 1=Deposit (money in), 2=Cashout (money out), 3=Refund (money returned). Referenced by 4 tables with explicit FKs: Billing.Depot, Billing.Payment, Billing.Terminal, Billing.Volume. Also used in Billing.ACHBankAccount, Billing.ACHBanks, Billing.MerchantAccountRouting. Hard-coded value 1 appears in multiple deposit procedures for PaymentTypeID=Deposit filtering. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable payment category name. Unique constraint prevents duplicates. Values: 'Deposit', 'Cashout', 'Refund'. Used in payment reporting, filtering, and UI display. Referenced by Billing.DepositAdd (SELECT Name WHERE PaymentTypeID=1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Depot | PaymentTypeID | Explicit FK (FK_DPMT_BDPT) | Depot configuration scoped by payment type |
| Billing.Payment | PaymentTypeID | Explicit FK (FK_DPMT_BPAY) | Every payment record classified by type |
| Billing.Terminal | PaymentTypeID | Explicit FK (FK_DPMT_BTER) | Terminal configuration per payment type |
| Billing.Volume | PaymentTypeID | Explicit FK (FK_DPMT_BVOL) | Volume tracking segmented by payment type |
| Billing.ACHBankAccount | PaymentTypeID | Implicit | ACH bank accounts scoped by payment type |
| Billing.ACHBanks | PaymentTypeID | Implicit | ACH bank configuration per payment type |
| Billing.MerchantAccountRouting | PaymentTypeID | Implicit | Merchant routing considers payment type |
| Billing.GetDepotInfo | PaymentTypeID | View SELECT | Depot info view exposes payment type |
| Billing.LoadPaymentTypes | - | SELECT * | Loads all types for application caching |
| Billing.DepositAdd | PaymentTypeID | WHERE = 1 | Filters depot by Deposit type |
| Billing.PaymentByCreditCardAdd | @PaymentTypeID | Parameter INSERT | Credit card payment records type |
| Billing.PaymentByPayPalAdd | @PaymentTypeID | Parameter INSERT | PayPal payment records type |
| Billing.PaymentByNetellerAdd | @PaymentTypeID | Parameter INSERT | Neteller payment records type |
| Billing.PaymentByWireTransferAdd | @PaymentTypeID | Parameter INSERT | Wire transfer payment records type |
| Billing.PaymentByWesternUnionAdd | @PaymentTypeID | Parameter INSERT | Western Union payment records type |
| Billing.TerminalEdit | @PaymentTypeID | Parameter | Terminal configuration by type |
| Billing.GetCustomerLastPayment | @PaymentTypeID | WHERE filter | Customer payment lookup by type |
| Billing.GetMerchantValues | @PaymentTypeID | WHERE filter | Merchant lookup by payment type |
| Billing.GetMerchantValues_V2 | @PaymentTypeID | WHERE filter | Merchant lookup V2 by payment type |
| Billing.GetPaymentsBy | @PaymentType | Dynamic WHERE | Payment search by type |
| Billing.CheckFundingTypeLimit | PaymentTypeID | WHERE = 1 | Funding limit check for deposits |
| Billing.CheckFundingTypeLimitByCCNumber | PaymentTypeID | WHERE = 1 | CC funding limit check for deposits |
| Billing.CheckMemberLimit | PaymentTypeID | WHERE = 1 | Member limit check for deposits |
| BackOffice.GetCashActivities | PaymentTypeID | TVP JOIN/WHERE | Cash activity report by payment types |
| BackOffice.PaymentTypesAndActivityPeriod | PaymentTypeID | UDT column | Table-valued parameter for cash activities |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PaymentType (table)
  └── referenced by Billing.Depot (FK_DPMT_BDPT)
  └── referenced by Billing.Payment (FK_DPMT_BPAY)
  └── referenced by Billing.Terminal (FK_DPMT_BTER)
  └── referenced by Billing.Volume (FK_DPMT_BVOL)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Depot | Table | FK — depot config per payment type |
| Billing.Payment | Table | FK — payment records classified by type |
| Billing.Terminal | Table | FK — terminal config per payment type |
| Billing.Volume | Table | FK — volume tracking per type |
| Billing.ACHBankAccount | Table | ACH config per payment type |
| Billing.ACHBanks | Table | ACH banks per payment type |
| Billing.MerchantAccountRouting | Table | Merchant routing per type |
| Billing.GetDepotInfo | View | Exposes PaymentTypeID |
| Billing.LoadPaymentTypes | Stored Procedure | Caches all payment types |
| Billing.DepositAdd | Stored Procedure | Filters by Deposit (1) |
| Billing.PaymentByCreditCardAdd | Stored Procedure | Records payment type |
| Billing.PaymentByPayPalAdd | Stored Procedure | Records payment type |
| Billing.PaymentByNetellerAdd | Stored Procedure | Records payment type |
| Billing.PaymentByWireTransferAdd | Stored Procedure | Records payment type |
| Billing.GetMerchantValues | Stored Procedure | Merchant lookup by type |
| Billing.CheckFundingTypeLimit | Stored Procedure | Limit check for deposits |
| BackOffice.GetCashActivities | Stored Procedure | Cash report by types |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPAT | NONCLUSTERED PK | PaymentTypeID ASC | - | - | Active |
| DPAT_NAME | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPAT | PRIMARY KEY | Unique payment type identifier, FILLFACTOR 90, DICTIONARY filegroup |
| DPAT_NAME | UNIQUE INDEX | Ensures no duplicate payment type names, FILLFACTOR 90 |

---

## 8. Sample Queries

### 8.1 List all payment types
```sql
SELECT  PaymentTypeID,
        Name
FROM    Dictionary.PaymentType WITH (NOLOCK)
ORDER BY PaymentTypeID;
```

### 8.2 Count payments by type
```sql
SELECT  dpt.Name            AS PaymentType,
        COUNT(*)            AS PaymentCount
FROM    Billing.Payment bp WITH (NOLOCK)
JOIN    Dictionary.PaymentType dpt WITH (NOLOCK)
        ON bp.PaymentTypeID = dpt.PaymentTypeID
GROUP BY dpt.Name
ORDER BY PaymentCount DESC;
```

### 8.3 Find depot configuration for deposits
```sql
SELECT  bd.DepotID,
        bd.Name             AS DepotName,
        dpt.Name            AS PaymentType
FROM    Billing.Depot bd WITH (NOLOCK)
JOIN    Dictionary.PaymentType dpt WITH (NOLOCK)
        ON bd.PaymentTypeID = dpt.PaymentTypeID
WHERE   bd.PaymentTypeID = 1  -- Deposit
ORDER BY bd.DepotID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and extensive codebase analysis across 25+ Billing schema procedures and 4 FK-constrained tables.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 25 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PaymentType.sql*
