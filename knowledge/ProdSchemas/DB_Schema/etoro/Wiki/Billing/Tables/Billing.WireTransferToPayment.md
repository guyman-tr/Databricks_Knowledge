# Billing.WireTransferToPayment

> Bridge table linking wire transfer deposit payments to Billing.Payment records, storing the provider-assigned transaction reference for each inbound wire transfer deposit.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (WireTransferID, PaymentID) (INT composite, NONCLUSTERED PK) |
| **Partition** | No ([MAIN] filegroup) |
| **Indexes** | 3 (PK + 2 NCI including 1 UNIQUE on TransactionID) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.WireTransferToPayment is the bridge table that links an inbound wire transfer (bank-to-bank deposit) to the corresponding Billing.Payment record. When a customer deposits via bank wire transfer, two rows are created atomically: a Billing.Payment record (FundingTypeID=2) and a WireTransferToPayment row that stores the external wire reference (TransactionID) from the bank or payment processor.

The unique TransactionID prevents duplicate processing of the same wire transfer - a critical guard since wire transfers from banks can arrive with the same reference if not properly deduplicated.

**18,298 rows** - wire transfer is a significant deposit channel at eToro, primarily used for large deposits and institutional customers who prefer or require bank wire over card/e-wallet methods.

---

## 2. Business Logic

### 2.1 Wire Transfer Deposit Add

**Written by**: `Billing.PaymentByWireTransferAdd`

```sql
-- From Billing.PaymentByWireTransferAdd
INSERT INTO Billing.Payment
(CurrencyID, CID, PaymentStatusID, PaymentTypeID, FundingTypeID, TerminalID,
 Amount, ExchangeRate, PaymentDate, TransactionID, IPAddress)
VALUES (..., 2, ...)  -- FundingTypeID=2 = Wire Transfer

SET @PaymentID = SCOPE_IDENTITY()

INSERT INTO WireTransferToPayment (PaymentID, TransactionID)
VALUES (@PaymentID, @TransactionID)
```

Note: The INSERT into `WireTransferToPayment` uses the unqualified table name (`WireTransferToPayment` not `Billing.WireTransferToPayment`) in the DDL - relies on default schema resolution.

Both inserts are wrapped in a transaction. An internal eToro TransactionID (6-char) is also generated via `Billing.GetTransactionID()` for the Payment record, separate from the wire's external TransactionID stored here.

### 2.2 Wire Transfer Edit

**Updated by**: `Billing.WireTransferEdit` - allows back-office correction of the TransactionID on an existing wire payment record.

### 2.3 Transaction Lookup

**Read by**: `Billing.GetPaymentByTransaction` - looks up a payment by the external wire TransactionID, enabling back-office to find the deposit associated with a bank confirmation reference.

---

## 3. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WireTransferID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate identifier for this wire transfer deposit record. Auto-incremented. NOT FOR REPLICATION - identity managed at publisher in replication topology. Part of composite PK. |
| 2 | PaymentID | INT | NO | - | CODE-BACKED | FK to Billing.Payment(PaymentID). The deposit transaction this wire transfer corresponds to. The Payment will have FundingTypeID=2 (Wire Transfer). Indexed via BT2P_PAYMENT. Part of composite PK. |
| 3 | TransactionID | VARCHAR(20) | NO | - | CODE-BACKED | The external wire transfer reference number from the bank or payment processor. UNIQUE across all rows (BT2P_MTCN index). Used for duplicate prevention and back-office transaction lookup. |

---

## 4. Relationships

### 4.1 References To

| Element | Related Object | Relationship Type |
|---------|---------------|-------------------|
| PaymentID | Billing.Payment | FK (BPMT_BT2P) |

### 4.2 Referenced By

| Source Object | Relationship |
|--------------|-------------|
| Billing.PaymentByWireTransferAdd | WRITER - creates row atomically with the Payment record (FundingTypeID=2) |
| Billing.WireTransferEdit | UPDATER - corrects TransactionID on existing record |
| Billing.GetPaymentByTransaction | READER - looks up payment by external TransactionID |
| Billing.GetPaymentData | READER - retrieves wire transfer metadata in payment data responses |
| Billing.GetPaymentDetails | READER - retrieves wire details for back-office payment detail lookup |
| Billing.CustomerRemove | DELETER - removes wire payment records when customer is deleted |

---

## 5. Technical Details

### 5.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| BT2P_PK | NONCLUSTERED PK | WireTransferID ASC, PaymentID ASC | Active |
| BT2P_MTCN | UNIQUE NCI | TransactionID ASC | Active |
| BT2P_PAYMENT | NCI | PaymentID ASC | Active |

Note: PK is NONCLUSTERED - table is stored as a heap. BT2P_PAYMENT NCI supports the JOIN in payment detail queries. UNIQUE on TransactionID enforces deduplication of incoming wire transfers. Index name `BT2P_MTCN` reuses the "MTCN" pattern from Western Union tables - these bridge tables share a common design template. FILLFACTOR=90 on PK and TransactionID index.

---

## 6. Comparison: Wire Transfer Bridge Tables

| Property | WireTransferToPayment | WireTransferToCashout |
|----------|----------------------|----------------------|
| Direction | Inbound (deposit) | Outbound (withdrawal) |
| Rows | 18,298 | 24 |
| FK | Billing.Payment | Billing.Cashout |
| PK type | NONCLUSTERED | CLUSTERED |
| ExternalRef column | TransactionID (VARCHAR 20) | TransactionID (VARCHAR 20) |
| FundingTypeID in Payment | 2 (Wire Transfer) | N/A (cashout-side) |

---

*Generated: 2026-03-17 | Quality: 8.4/10 | Phases: 8/11 | CODE-BACKED: 3 | Sources: 0*
*Object: Billing.WireTransferToPayment | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WireTransferToPayment.sql*
