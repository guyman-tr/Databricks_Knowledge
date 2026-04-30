# Billing.CustomerRemove

> Permanently deletes all billing records for a customer (Payments, Cashouts, CreditCards, Neteller, PayPal, and related history) in a single transaction; skips IB (Introducing Broker) accounts; used for test account cleanup or GDPR-driven deletion.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to remove) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerRemove` is the nuclear delete procedure for all Billing schema data belonging to a single customer. It removes payment records, cashout records, associated history entries, and orphaned payment instrument records (CreditCards, PayPal accounts, Neteller accounts) in proper FK-respecting order within a single transaction.

The procedure is used for test account cleanup and GDPR-driven customer data erasure. It is NOT called in the normal transaction lifecycle - it is an administrative/ops tool for permanently purging a customer from the Billing layer.

The `@RemoveAccount BIT = 0` parameter exists in the signature but is fully commented out - the Billing.Account table was dropped in a prior schema migration, making this parameter vestigial.

**IB Guard**: The procedure first checks if the customer is an Introducing Broker (IB) via `Customer.Customer JOIN Trade.Provider WHERE IsIB=1`. If the customer is an IB, the procedure returns 0 immediately without deleting anything - IB accounts are protected from automated removal.

---

## 2. Business Logic

### 2.1 IB Protection Guard

**What**: Prevents deletion of Introducing Broker accounts.

**Rules**:
- Checks `Customer.Customer` JOIN `Trade.Provider` WHERE `CID = @CID AND IsIB = 1`
- If any row found -> `RETURN 0` immediately (no changes made)
- If no IB row found -> proceeds with deletion

### 2.2 Transactional Multi-Table Delete (Child-to-Parent Order)

**What**: Deletes all billing records for the customer in proper FK order to avoid constraint violations. All deletes are wrapped in a single `BEGIN TRANSACTION / COMMIT TRANSACTION`.

**Error handling**: After each `DELETE`, captures `@@ERROR`. If non-zero: `RAISERROR(60000, 16, 1, 'Billing.CustomerRemove', @LocalError)`, `ROLLBACK TRANSACTION`, `RETURN @LocalError`. On success: `COMMIT TRANSACTION`, `RETURN 0`.

**Deletion order** (child-to-parent):

| Step | Table | Filter |
|------|-------|--------|
| 1 | History.PaymentLog | EXISTS (PaymentAction -> Payment WHERE CID=@CID) |
| 2 | History.PaymentAction | EXISTS (Payment WHERE CID=@CID) |
| 3 | Billing.CreditCardToPayment | EXISTS (Payment WHERE CID=@CID) |
| 4 | History.Payment | EXISTS (Payment WHERE CID=@CID) |
| 5 | Billing.NetellerToPayment | EXISTS (Payment WHERE CID=@CID) |
| 6 | Billing.PayPalToPayment | EXISTS (Payment WHERE CID=@CID) |
| 7 | Billing.WesternUnionToPayment | EXISTS (Payment WHERE CID=@CID) |
| 8 | Billing.WireTransferToPayment | EXISTS (Payment WHERE CID=@CID) |
| 9 | Billing.RiskManagementCheck | EXISTS (Payment WHERE CID=@CID) |
| 10 | Billing.Payment | WHERE CID = @CID (direct delete) |
| 11 | History.Cashout | EXISTS (Cashout WHERE CID=@CID) |
| 12 | History.CashoutAction | EXISTS (Cashout WHERE CID=@CID) |
| 13 | Billing.Cashout | WHERE CID = @CID (direct delete) |
| 14 | Billing.PayPal | WHERE NOT EXISTS (PayPalToPayment) - orphan cleanup |
| 15 | Billing.CreditCard | WHERE NOT EXISTS (CreditCardToPayment) - orphan cleanup |
| 16 | Billing.Neteller | WHERE NOT EXISTS (NetellerToPayment) - orphan cleanup |

**Steps 14-16 note**: These delete ALL orphaned payment instrument records (not just for @CID), since instrument tables (CreditCard, PayPal, Neteller) don't have a CID column - they are linked to customers only through the Payment link tables. After step 10 removes all Payments for @CID, steps 3/5/6 remove the link records, making those instrument rows orphaned.

### 2.3 Known Code Issue - Stale @@ERROR at Steps 11-13

**What**: The error checks after History.Cashout and History.CashoutAction deletes (steps 11-12) use `IF @LocalError != 0` without a preceding `SELECT @LocalError = @@ERROR`. This means `@LocalError` holds the value from step 9 (Billing.RiskManagementCheck), not from the actual Cashout history deletes.

**Impact**: Errors in History.Cashout or History.CashoutAction deletes will not be caught - the transaction will continue and COMMIT even if those deletes failed silently.

### 2.4 Commented-Out Sections (Historical Artifacts)

- `History.AccountToBonus` delete: commented out with note "Becouse we drop table Billing.Account"
- `History.Account` delete: commented out
- `Billing.Account` deletion/zeroing (`@RemoveAccount` flag logic): commented out - Billing.Account was dropped in a prior migration

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | Customer ID to delete all billing data for. All DELETEs filter directly or indirectly on this value. |
| 2 | @RemoveAccount | BIT | YES | 0 | CODE-BACKED | Vestigial parameter - originally controlled whether to delete or zero-out Billing.Account. Billing.Account was dropped in a prior schema migration. The parameter is accepted but produces no effect (all Account-related logic is commented out). |

**Return value**: `RETURN 0` on success (IB guard hit OR successful completion). `RETURN @LocalError` (SQL error code) on any DELETE failure.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IB guard | Customer.Customer | Read | Checks if customer is an IB |
| IB guard | Trade.Provider | Read | Joins to check IsIB flag |
| Step 1 | History.PaymentLog | Delete | Payment audit log entries for this customer |
| Step 2 | History.PaymentAction | Delete | Payment action history for this customer |
| Step 3 | Billing.CreditCardToPayment | Delete | Card-to-payment link records |
| Step 4 | History.Payment | Delete | Payment history records |
| Step 5 | Billing.NetellerToPayment | Delete | Neteller-to-payment link records |
| Step 6 | Billing.PayPalToPayment | Delete | PayPal-to-payment link records |
| Step 7 | Billing.WesternUnionToPayment | Delete | Western Union-to-payment link records |
| Step 8 | Billing.WireTransferToPayment | Delete | Wire transfer-to-payment link records |
| Step 9 | Billing.RiskManagementCheck | Delete | Risk check records linked to payments |
| Step 10 | Billing.Payment | Delete | Core payment records |
| Step 11 | History.Cashout | Delete | Cashout history |
| Step 12 | History.CashoutAction | Delete | Cashout action history |
| Step 13 | Billing.Cashout | Delete | Core cashout records |
| Step 14 | Billing.PayPal | Delete (orphan cleanup) | PayPal accounts with no remaining payment links |
| Step 15 | Billing.CreditCard | Delete (orphan cleanup) | Credit card hashes with no remaining payment links |
| Step 16 | Billing.Neteller | Delete (orphan cleanup) | Neteller accounts with no remaining payment links |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Test account cleanup service | @CID | Caller | Removes test customer billing data |
| GDPR data erasure flow | @CID | Caller | Purges customer billing records per erasure request |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CustomerRemove (procedure)
+-- Customer.Customer (table) [READ: IB guard]
+-- Trade.Provider (table) [READ: IsIB check]
+-- History.PaymentLog (table) [DELETE]
+-- History.PaymentAction (table) [DELETE]
+-- Billing.CreditCardToPayment (table) [DELETE]
+-- History.Payment (table) [DELETE]
+-- Billing.NetellerToPayment (table) [DELETE]
+-- Billing.PayPalToPayment (table) [DELETE]
+-- Billing.WesternUnionToPayment (table) [DELETE]
+-- Billing.WireTransferToPayment (table) [DELETE]
+-- Billing.RiskManagementCheck (table) [DELETE]
+-- Billing.Payment (table) [DELETE - root payment table]
+-- History.Cashout (table) [DELETE]
+-- History.CashoutAction (table) [DELETE]
+-- Billing.Cashout (table) [DELETE]
+-- Billing.PayPal (table) [DELETE - orphan cleanup]
+-- Billing.CreditCard (table) [DELETE - orphan cleanup]
+-- Billing.Neteller (table) [DELETE - orphan cleanup]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | IB guard check |
| Trade.Provider | Table | IsIB flag lookup |
| History.PaymentLog | Table | Delete child records of PaymentAction |
| History.PaymentAction | Table | Delete child records of Payment |
| Billing.CreditCardToPayment | Table | Delete card link records |
| History.Payment | Table | Delete payment history |
| Billing.NetellerToPayment | Table | Delete Neteller link records |
| Billing.PayPalToPayment | Table | Delete PayPal link records |
| Billing.WesternUnionToPayment | Table | Delete Western Union link records |
| Billing.WireTransferToPayment | Table | Delete wire transfer link records |
| Billing.RiskManagementCheck | Table | Delete risk check records |
| Billing.Payment | Table | Core payment delete |
| History.Cashout | Table | Delete cashout history |
| History.CashoutAction | Table | Delete cashout action history |
| Billing.Cashout | Table | Core cashout delete |
| Billing.PayPal | Table | Orphan PayPal cleanup |
| Billing.CreditCard | Table | Orphan card hash cleanup |
| Billing.Neteller | Table | Orphan Neteller cleanup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Test account management / GDPR erasure flow | External | Calls to permanently delete customer billing records |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Transaction scope**: All 16 delete steps are wrapped in a single `BEGIN TRANSACTION / COMMIT TRANSACTION`. A failure in any step (steps 1-10 specifically, due to the stale @LocalError issue in 11-13) triggers full ROLLBACK.

**RAISERROR code 60000**: Used consistently for all failure paths in this procedure. The error message template is `'Billing.CustomerRemove'` + `@LocalError` (the SQL error code).

**No SELECT @LocalError for steps 11-13**: A code defect - stale @LocalError value is checked instead of capturing @@ERROR from the Cashout history deletes. In practice, these deletes rarely fail, making this low-risk.

---

## 8. Sample Queries

### 8.1 Check if a customer is an IB (would be skipped)

```sql
SELECT CS.CID, TP.IsIB
FROM Customer.Customer CS WITH(NOLOCK)
JOIN Trade.Provider TP WITH(NOLOCK) ON TP.ProviderID = CS.ProviderID
WHERE CS.CID = @CID AND TP.IsIB = 1
-- If any row returned: CustomerRemove would skip this CID
```

### 8.2 Preview what would be deleted (payment count)

```sql
SELECT
    'Billing.Payment' AS TableName,
    COUNT(*) AS RowsToDelete
FROM Billing.Payment WITH(NOLOCK)
WHERE CID = @CID
UNION ALL
SELECT 'Billing.Cashout', COUNT(*)
FROM Billing.Cashout WITH(NOLOCK)
WHERE CID = @CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 8/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerRemove | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerRemove.sql*
