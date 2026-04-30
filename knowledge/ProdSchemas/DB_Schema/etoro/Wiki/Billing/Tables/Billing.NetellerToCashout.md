# Billing.NetellerToCashout

> Legacy Neteller-to-cashout junction table. Each row links one Neteller account record (Billing.Neteller) to one cashout record (Billing.Cashout), recording which e-wallet account processed the cashout. 6 rows total. Part of the legacy Cashout system, superseded by Billing.WithdrawToFunding.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (NetellerID, CashoutID) - COMPOSITE PRIMARY KEY NONCLUSTERED (heap) |
| **Row Count** | 6 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 NONCLUSTERED PK; 2 NC indexes (CashoutID, NetellerID) |

---

## 1. Business Meaning

`Billing.NetellerToCashout` is the Neteller-specific payment leg of the legacy cashout system. When a cashout was processed via Neteller, `Billing.CashoutProcessToNeteller` recorded the cashout event in `Billing.Cashout` (cashout type=6), then inserted a row here linking the Neteller account to the cashout.

This is a legacy table with only 6 rows. The modern equivalent is `Billing.WithdrawToFunding`, which handles all payment method types uniformly.

**Note**: PK is NONCLUSTERED, leaving the table as a heap. This is atypical and may reflect the original creation before proper index strategy was established.

---

## 2. Business Logic

### 2.1 Cashout Processing - Transactional Insert

**Procedure**: `Billing.CashoutProcessToNeteller(@CashoutID, @ManagerID, @ProcessCurrencyID, @CashoutActionStatusID, @NetellerID, @ExchangeRate, @Description)`

**Flow** (within a single transaction):
1. Calls `Billing.CashoutProcess` with cashout type=6 (Neteller)
2. If `CashoutProcess` returns non-zero, exits (no rollback in procedure but transaction is open)
3. INSERTs (NetellerID, CashoutID) into `Billing.NetellerToCashout`
4. COMMITs

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **NetellerID** | int | NOT NULL | - | Billing.Neteller(NetellerID) | [CODE-BACKED] Neteller account ID; part of composite PK. References legacy Billing.Neteller table. |
| **CashoutID** | int | NOT NULL | - | Billing.Cashout(CashoutID) | [CODE-BACKED] Cashout event ID; part of composite PK. References legacy Billing.Cashout table. |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BN2C | NONCLUSTERED | (NetellerID ASC, CashoutID ASC) | FILLFACTOR=90. Heap table (no clustered index). |
| BN2C_CASHOUT | NONCLUSTERED | CashoutID ASC | FILLFACTOR=90. Lookup by cashout. |
| BN2C_NETELLER | NONCLUSTERED | NetellerID ASC | FILLFACTOR=90. Lookup by Neteller account. |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.CashoutProcessToNeteller` | Single writer: calls CashoutProcess (type=6) then INSERTs; transactional |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Neteller | Many-to-one | NetellerToCashout.NetellerID = Neteller.NetellerID | Explicit FK. Legacy Neteller account table. |
| Billing.Cashout | Many-to-one | NetellerToCashout.CashoutID = Cashout.CashoutID | Explicit FK. Legacy cashout event table. |

---

*Quality: 8.8/10 | 2 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,5,8,9,11 | Legacy table - 6 rows; superseded by Billing.WithdrawToFunding*
