# Billing.WesternUnionToCashout

> Bridge table linking Western Union cashout (withdrawal) payments to the Billing.Cashout record, storing the WU Money Transfer Control Number (MTCN) and the sender's country and city.

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

Billing.WesternUnionToCashout is the bridge table that records Western Union details for customer withdrawals processed via the Western Union payment network. When eToro processes a cashout (withdrawal) via Western Union, the transaction is recorded in Billing.Cashout for the financial record, and the Western Union-specific metadata (MTCN, country, city) is stored here.

The MTCN (Money Transfer Control Number) is the unique 15-digit identifier issued by Western Union for each money transfer. The customer presents this number at any Western Union agent location worldwide to collect their cash payout.

**0 rows** - this table is currently empty. Western Union cashouts have been either discontinued or never executed in the current data lifetime. The counterpart table `WesternUnionToPayment` (deposits) has 8,003 rows, indicating Western Union was primarily used for inbound deposits rather than outbound cashouts.

---

## 2. Business Logic

### 2.1 Western Union Cashout Process

**Written by**: `Billing.CashoutProcessToWesternUnion`

**Flow**:
1. Calls `Billing.CashoutProcess` with FundingTypeID=5 (WesternUnion) to update the Cashout record
2. Inserts a row into `WesternUnionToCashout` with the MTCN and location details
3. Both steps are wrapped in a single transaction - rollback if either fails

```sql
-- From Billing.CashoutProcessToWesternUnion
EXECUTE @Answer = Billing.CashoutProcess
    @CashoutID, @ManagerID, @ProcessCurrencyID, @CashoutActionStatusID,
    5, -- WesternUnion FundingTypeID
    @ExchangeRate, @Description
-- Then:
INSERT INTO Billing.WesternUnionToCashout (CashoutID, CountryID, MTCN, City)
VALUES (@CashoutID, @CountryID, @MTCN, @City)
```

---

## 3. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WesternUnionID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-incremented. NOT FOR REPLICATION - participates in SQL Server replication topology without consuming identity on subscriber. |
| 2 | CashoutID | INT | NO | - | CODE-BACKED | FK to Billing.Cashout(CashoutID). The withdrawal transaction this Western Union transfer corresponds to. Indexed for reverse lookup. |
| 3 | CountryID | INT | NO | - | CODE-BACKED | FK to Dictionary.Country(CountryID). The country of the Western Union agent location where the customer will collect the funds. |
| 4 | MTCN | VARCHAR(15) | NO | - | CODE-BACKED | Money Transfer Control Number - the unique WU transaction identifier. 15-char string, globally unique per WU transfer. UNIQUE index enforces no duplicates. Customer uses this to collect cash at WU agent. |
| 5 | City | NVARCHAR(50) | NO | - | CODE-BACKED | City of the Western Union agent location where the customer will collect funds. Unicode (NVARCHAR) to support international city names. |

---

## 4. Relationships

### 4.1 References To

| Element | Related Object | Relationship Type |
|---------|---------------|-------------------|
| CashoutID | Billing.Cashout | FK (FK_BCSH_BU2C) |
| CountryID | Dictionary.Country | FK (FK_DCNR_BU2P) - note: constraint name references BU2P, a copy-paste from the Payment table |

### 4.2 Referenced By

| Source Object | Relationship |
|--------------|-------------|
| Billing.CashoutProcessToWesternUnion | WRITER - inserts row when processing WU cashout |
| Billing.CustomerRemove | DELETER - removes WU cashout records when customer is deleted |
| Billing.GetPaymentData | READER - retrieves WU details for payment data queries |
| Billing.GetPaymentDetails | READER - retrieves WU details for payment detail lookup |

---

## 5. Technical Details

### 5.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_BU2C | NONCLUSTERED PK | WesternUnionID ASC | Active |
| BU2C_CASHOUT | NCI | CashoutID ASC | Active |
| BU2C_COUNTRY | NCI | CountryID ASC | Active |
| BU2C_MTCN | UNIQUE NCI | MTCN ASC | Active |

Note: PK is NONCLUSTERED (unusual). No clustered index is defined, meaning rows are stored in a heap. The BU2C_CASHOUT NCI is the primary lookup path. FILLFACTOR=90 on all indexes.

---

## 6. Notes

- FK constraint `FK_DCNR_BU2P` (on CountryID) has a name suffix `BU2P` instead of `BU2C` - this is a copy-paste artifact from the structurally identical `WesternUnionToPayment` table.
- 0 rows currently - Western Union cashouts appear unused or discontinued.
- IDENTITY NOT FOR REPLICATION is consistent with other bridge tables (WesternUnionToPayment, WireTransferToPayment) indicating the Billing schema participates in SQL Server replication.

---

*Generated: 2026-03-17 | Quality: 7.8/10 | Phases: 7/11 | CODE-BACKED: 5 | Sources: 0*
*Object: Billing.WesternUnionToCashout | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WesternUnionToCashout.sql*
