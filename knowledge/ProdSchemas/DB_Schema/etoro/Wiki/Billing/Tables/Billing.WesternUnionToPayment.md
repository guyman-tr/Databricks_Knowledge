# Billing.WesternUnionToPayment

> Bridge table linking Western Union deposit payments to the Billing.Payment record, storing the WU Money Transfer Control Number (MTCN) and the sender's country and city.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | WesternUnionID (INT, IDENTITY, NONCLUSTERED PK) |
| **Partition** | No ([MAIN] filegroup) |
| **Indexes** | 4 (PK + 3 NCI including 1 UNIQUE on MTCN) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.WesternUnionToPayment is the bridge table that stores Western Union-specific metadata for customer deposits made via the Western Union money transfer network. When a customer sends money to eToro via Western Union, the payment is recorded in Billing.Payment (FundingTypeID=5) and the WU-specific details - MTCN, originating country, and city - are stored here.

The MTCN (Money Transfer Control Number) is the unique 15-character identifier assigned by Western Union to each transfer. eToro's back office uses this number to match the incoming wire to the customer's deposit request and verify the transfer. The uniqueness constraint on MTCN prevents duplicate processing of the same Western Union transfer.

**8,003 rows** across the table's history - Western Union deposits were historically accepted but volume suggests this is a legacy/low-volume channel. Compare to WireTransferToPayment (18,298 rows) and the complete absence of WesternUnionToCashout rows (0).

---

## 2. Business Logic

### 2.1 Western Union Deposit Add

**Written by**: `Billing.PaymentByWesternUnionAdd`

**Flow**:
1. Generates a unique internal TransactionID using `Billing.GetTransactionID()` (6-char code, unique per customer)
2. INSERTs into `Billing.Payment` with FundingTypeID=5 (Western Union hardcoded)
3. INSERTs into `Billing.WesternUnionToPayment` with PaymentID, CountryID, MTCN, City
4. INSERTs initial status into `History.Payment`
5. All steps in a single transaction; rolls back on any error

```sql
-- From Billing.PaymentByWesternUnionAdd
INSERT INTO Billing.Payment (CurrencyID, CID, ..., FundingTypeID, ...)
VALUES (..., 5, ...) -- 5 = Western Union

INSERT INTO Billing.WesternUnionToPayment (PaymentID, CountryID, MTCN, City)
VALUES (@PaymentID, @CountryID, @MTCN, @City)
```

### 2.2 Western Union Edit

**Written by**: `Billing.WesternUnionEdit`

Updates the WU details (CountryID, MTCN, City) on an existing record by WesternUnionID. Used by back office to correct WU payment details after initial entry.

---

## 3. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WesternUnionID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-incremented. NOT FOR REPLICATION - identity range managed by publisher in replication topology. |
| 2 | PaymentID | INT | NO | - | CODE-BACKED | FK to Billing.Payment(PaymentID). The deposit transaction this WU transfer corresponds to. Payment will have FundingTypeID=5. Indexed via BW2P_PAYMENT for reverse lookup. |
| 3 | CountryID | INT | NO | - | CODE-BACKED | FK to Dictionary.Country(CountryID). The country from which the customer initiated the Western Union transfer (sender's location). Indexed via BW2P_COUNTRY. |
| 4 | MTCN | VARCHAR(15) | NO | - | CODE-BACKED | Money Transfer Control Number - the unique WU transaction identifier assigned by Western Union to each money transfer. 15-character string. UNIQUE index (BW2P_MTCN) prevents duplicate processing. |
| 5 | City | NVARCHAR(50) | NO | - | CODE-BACKED | City from which the customer sent the Western Union transfer. Unicode (NVARCHAR) to support international city names. |

---

## 4. Relationships

### 4.1 References To

| Element | Related Object | Relationship Type |
|---------|---------------|-------------------|
| PaymentID | Billing.Payment | FK (FK_BPMT_BW2P) |
| CountryID | Dictionary.Country | FK (FK_DCNR_BW2P) |

### 4.2 Referenced By

| Source Object | Relationship |
|--------------|-------------|
| Billing.PaymentByWesternUnionAdd | WRITER - creates row atomically with the Payment record |
| Billing.WesternUnionEdit | UPDATER - corrects WU details (MTCN, country, city) by WesternUnionID |
| Billing.GetPaymentByTransaction | READER - retrieves WU payment by TransactionID |
| Billing.GetPaymentData | READER - retrieves WU metadata in payment data responses |
| Billing.GetPaymentDetails | READER - retrieves WU details for back-office payment detail lookup |
| Billing.CustomerRemove | DELETER - removes WU payment records when customer account is deleted |

---

## 5. Technical Details

### 5.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_BW2P | NONCLUSTERED PK | WesternUnionID ASC | Active |
| BW2P_COUNTRY | NCI | CountryID ASC | Active |
| BW2P_MTCN | UNIQUE NCI | MTCN ASC | Active |
| BW2P_PAYMENT | NCI | PaymentID ASC | Active |

Note: PK is NONCLUSTERED - table is stored as a heap. FILLFACTOR=90 on PK and MTCN index. BW2P_PAYMENT NCI supports the JOIN in payment detail queries. UNIQUE on MTCN is the deduplication guard preventing the same WU transfer from being deposited twice.

---

## 6. Sample Query

```sql
-- Get Western Union deposit details for a customer
SELECT p.PaymentID, p.Amount, p.CurrencyID, p.PaymentDate,
       wu.MTCN, wu.City, c.CountryName
FROM Billing.Payment p WITH (NOLOCK)
INNER JOIN Billing.WesternUnionToPayment wu WITH (NOLOCK) ON wu.PaymentID = p.PaymentID
INNER JOIN Dictionary.Country c WITH (NOLOCK) ON c.CountryID = wu.CountryID
WHERE p.CID = @CID
ORDER BY p.PaymentDate DESC
```

---

*Generated: 2026-03-17 | Quality: 8.2/10 | Phases: 8/11 | CODE-BACKED: 5 | Sources: 0*
*Object: Billing.WesternUnionToPayment | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WesternUnionToPayment.sql*
