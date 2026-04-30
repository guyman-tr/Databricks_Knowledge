# Billing.WireTransferToCashout

> Bridge table linking wire transfer cashout (withdrawal) payments to Billing.Cashout records, storing the provider-assigned transaction identifier for each wire transfer withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (WireTransferID, CashoutID) (INT composite, CLUSTERED PK) |
| **Partition** | No ([MAIN] filegroup) |
| **Indexes** | 3 (PK + 2 NCI including 1 UNIQUE on TransactionID) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.WireTransferToCashout is the bridge table that links a wire transfer cashout (outbound withdrawal to a customer's bank account) to the corresponding Billing.Cashout record. It stores the bank's transaction reference (TransactionID) for the wire transfer, which is eToro's confirmation that the money was sent.

Unlike the deposit-side counterpart (WireTransferToPayment with 18,298 rows), this table has only **24 rows** - wire transfer withdrawals are rare or processed differently in the current operational model.

---

## 2. Business Logic

### 2.1 Wire Transfer Cashout Process

**Written by**: `Billing.CashoutProcessToWireTransfer`

Follows the same two-step pattern as the Western Union cashout:
1. Calls `Billing.CashoutProcess` to record the cashout action (FundingTypeID=2 for wire transfer)
2. Inserts into `WireTransferToCashout` with the CashoutID and wire TransactionID

### 2.2 Unique TransactionID

The UNIQUE index (BW2C_MTCN) on TransactionID prevents duplicate wire transfer cashout records. Note the index name `BW2C_MTCN` - it reuses the "MTCN" naming pattern from the Western Union tables, suggesting these bridge tables share a common design template.

---

## 3. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WireTransferID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate identifier for this wire transfer cashout record. Auto-incremented. NOT FOR REPLICATION - identity managed at publisher in replication topology. Part of composite PK. |
| 2 | CashoutID | INT | NO | - | CODE-BACKED | FK to Billing.Cashout(CashoutID). The withdrawal transaction this wire transfer corresponds to. Indexed via BW2C_CASHOUT for reverse lookup. Part of composite PK. |
| 3 | TransactionID | VARCHAR(20) | NO | - | CODE-BACKED | The wire transfer reference number assigned by the bank or payment processor. UNIQUE across all rows (BW2C_MTCN index). Used by GetPaymentByTransaction to look up the payment from the external reference. |

---

## 4. Relationships

### 4.1 References To

| Element | Related Object | Relationship Type |
|---------|---------------|-------------------|
| CashoutID | Billing.Cashout | FK (FK_BCSH_BW2C) |

### 4.2 Referenced By

| Source Object | Relationship |
|--------------|-------------|
| Billing.CashoutProcessToWireTransfer | WRITER - inserts row when processing wire transfer cashout |
| Billing.GetPaymentByTransaction | READER - looks up cashout by TransactionID |
| Billing.GetPaymentData | READER - retrieves wire transfer details in payment data responses |
| Billing.GetPaymentDetails | READER - retrieves wire details for back-office cashout detail lookup |
| Billing.CustomerRemove | DELETER - removes wire cashout records when customer is deleted |

---

## 5. Technical Details

### 5.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_BW2C | CLUSTERED PK | WireTransferID ASC, CashoutID ASC | Active |
| BW2C_CASHOUT | NCI | CashoutID ASC | Active |
| BW2C_MTCN | UNIQUE NCI | TransactionID ASC | Active |

Note: PK is CLUSTERED and composite (WireTransferID + CashoutID) - the CashoutID FK column is embedded in the PK ordering, which is unusual. BW2C_CASHOUT provides a separate NCI for CashoutID-only lookups. FILLFACTOR=90 on all indexes.

---

*Generated: 2026-03-17 | Quality: 7.8/10 | Phases: 7/11 | CODE-BACKED: 3 | Sources: 0*
*Object: Billing.WireTransferToCashout | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WireTransferToCashout.sql*
