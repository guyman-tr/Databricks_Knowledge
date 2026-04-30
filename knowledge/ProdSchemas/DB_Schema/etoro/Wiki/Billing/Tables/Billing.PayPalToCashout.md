# Billing.PayPalToCashout

> Legacy PayPal-to-cashout junction table. Each row links one PayPal account record (Billing.PayPal) to one cashout record (Billing.Cashout), recording which PayPal account processed the cashout. 214 rows total. Part of the legacy Cashout system, superseded by Billing.WithdrawToFunding.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (PayPalID, CashoutID) - COMPOSITE PRIMARY KEY CLUSTERED |
| **Row Count** | 214 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 CLUSTERED composite PK; 2 NC indexes (CashoutID, PayPalID) |

---

## 1. Business Meaning

`Billing.PayPalToCashout` is the PayPal-specific payment leg of the legacy cashout system. When a cashout was processed via PayPal, `Billing.CashoutProcessToPayPal` recorded the cashout event in `Billing.Cashout` (cashout type=3), then inserted a row here linking the PayPal account to the cashout.

214 rows represents historical PayPal cashouts. The modern equivalent is `Billing.WithdrawToFunding`.

---

## 2. Business Logic

### 2.1 Cashout Processing - Transactional Insert

**Procedure**: `Billing.CashoutProcessToPayPal(@CashoutID, @ManagerID, @ProcessCurrencyID, @CashoutActionStatusID, @PayPalID, @ExchangeRate, @Description)`

**Flow** (within a single transaction):
1. Calls `Billing.CashoutProcess` with cashout type=3 (PayPal)
2. If `CashoutProcess` returns non-zero, exits
3. INSERTs (PayPalID, CashoutID) into `Billing.PayPalToCashout`
4. COMMITs

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **PayPalID** | int | NOT NULL | - | Billing.PayPal(PayPalID) | [CODE-BACKED] PayPal account ID; part of composite PK. References legacy Billing.PayPal table. |
| **CashoutID** | int | NOT NULL | - | Billing.Cashout(CashoutID) | [CODE-BACKED] Cashout event ID; part of composite PK. References legacy Billing.Cashout table. |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BP2C | CLUSTERED | (PayPalID ASC, CashoutID ASC) | FILLFACTOR=90. |
| BP2C_CASHOUT | NONCLUSTERED | CashoutID ASC | FILLFACTOR=90. Lookup by cashout. |
| BP2C_PAYPAL | NONCLUSTERED | PayPalID ASC | FILLFACTOR=90. Lookup by PayPal account. |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.CashoutProcessToPayPal` | Single writer: calls CashoutProcess (type=3) then INSERTs; transactional |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.PayPal | Many-to-one | PayPalToCashout.PayPalID = PayPal.PayPalID | Explicit FK. Legacy PayPal account table. |
| Billing.Cashout | Many-to-one | PayPalToCashout.CashoutID = Cashout.CashoutID | Explicit FK. Legacy cashout event table. |

---

*Quality: 8.8/10 | 2 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,5,8,9,11 | Legacy table - 214 rows; superseded by Billing.WithdrawToFunding*
