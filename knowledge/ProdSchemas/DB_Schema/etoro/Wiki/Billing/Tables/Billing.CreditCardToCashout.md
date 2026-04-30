# Billing.CreditCardToCashout

> Legacy credit-card-to-cashout junction table. Each row links one credit card record (Billing.CreditCard) to one cashout record (Billing.Cashout), recording which card was used to process the cashout and through which bank. 484 rows; all have BankID=0 (UNKNOWN). Part of the legacy Cashout system, superseded by Billing.WithdrawToFunding.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CardID, CashoutID) - COMPOSITE PRIMARY KEY CLUSTERED |
| **Row Count** | 484 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 CLUSTERED composite PK; 3 NC indexes (BankID, CardID, CashoutID) |

---

## 1. Business Meaning

`Billing.CreditCardToCashout` is the payment-instrument leg of the legacy cashout processing system. When a cashout was processed via credit card, `Billing.CashoutProcessToCreditCard` first recorded the cashout event in `Billing.Cashout`, then added a row here to associate the card used (from `Billing.CreditCard`) with the cashout, plus the bank through which routing was performed.

This is a legacy table - the modern equivalent is `Billing.WithdrawToFunding`. The 484 rows represent historical credit card cashouts from the old system. All rows have BankID=0 (UNKNOWN), indicating bank routing information was not captured or was always unknown in this legacy flow.

---

## 2. Business Logic

### 2.1 Cashout Processing - Transactional Insert

**Procedure**: `Billing.CashoutProcessToCreditCard(@CashoutID, @ManagerID, @ProcessCurrencyID, @CashoutActionStatusID, @CardID, @BankID, @ExchangeRate, @Description)`

**Flow** (within a single transaction):
1. Calls `Billing.CashoutProcess` with cashout type = 1 (credit card)
2. If `CashoutProcess` returns non-zero, rolls back and returns error
3. INSERTs into `Billing.CreditCardToCashout` (CardID, CashoutID, BankID)
4. COMMITs

**Note**: The @BankID parameter is always passed as 0 in practice (all 484 rows have BankID=0).

### 2.2 BankID - Unused Routing Field

All 484 rows have BankID=0 (Dictionary.Bank: Name="UNKNOWN", IsActive=false). The bank routing field was included in the schema to record which acquiring bank processed the CC cashout, but this was never populated with actual bank data.

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **CardID** | int | NOT NULL | - | Billing.CreditCard(CardID) | [CODE-BACKED] Credit card record ID; part of composite PK. References the legacy Billing.CreditCard table. Small IDs (66-257 range in sample) indicate old legacy records. |
| **CashoutID** | int | NOT NULL | - | Billing.Cashout(CashoutID) | [CODE-BACKED] Cashout event ID; part of composite PK. References the legacy Billing.Cashout table. |
| **BankID** | int | NOT NULL | - | Dictionary.Bank(BankID) | [CODE-BACKED] Acquiring bank for this cashout routing. In all 484 live rows, BankID=0 (UNKNOWN). Was intended to track which bank processed the CC reversal. |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BC2C | CLUSTERED | (CardID ASC, CashoutID ASC) | FILLFACTOR=90. Primary lookup by card + cashout. |
| BC2C_BANK | NONCLUSTERED | BankID ASC | FILLFACTOR=90. Lookup by bank (effectively all point to BankID=0). |
| BC2C_CARD | NONCLUSTERED | CardID ASC | FILLFACTOR=90. Lookup by card (which cashouts used this card). |
| BC2C_CASHOUT | NONCLUSTERED | CashoutID ASC | FILLFACTOR=90. Lookup by cashout (which card was used). |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.CashoutProcessToCreditCard` | Single writer: calls CashoutProcess then INSERTs row into this table; transactional |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.CreditCard | Many-to-one | CreditCardToCashout.CardID = CreditCard.CardID | Explicit FK. Legacy credit card instrument table. |
| Billing.Cashout | Many-to-one | CreditCardToCashout.CashoutID = Cashout.CashoutID | Explicit FK. Legacy cashout event table. |
| Dictionary.Bank | Many-to-one | CreditCardToCashout.BankID = Bank.BankID | Explicit FK. Always BankID=0 (UNKNOWN) in live data. |

---

*Quality: 8.9/10 | 3 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,5,8,9,11 | Legacy table - superseded by Billing.WithdrawToFunding*
