# Billing.BankToDepot

> Bank-to-depot routing table. Each row maps an acquiring bank (Dictionary.Bank) to a payment depot (Billing.Depot) with a priority for routing preference. 36 entries. Modern equivalent of Billing.BankToTerminal - used in the depot-based payment routing system.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (BankID, DepotID) - PRIMARY KEY CLUSTERED |
| **Row Count** | 36 rows |
| **Partition** | N/A - filegroup PRIMARY |
| **Indexes** | 1 CLUSTERED composite PK |

---

## 1. Business Meaning

`Billing.BankToDepot` routes transactions from acquiring banks to their corresponding payment depots, with Priority defining preference when multiple depots are available for the same bank. This is the modern replacement for `Billing.BankToTerminal`, using the Depot abstraction instead of the legacy Terminal system.

Priority values range from 50-100 in live data, where higher values indicate higher priority. BankID=1 maps to multiple depots (DepotIDs 13, 15, 33, 34) with varying priorities.

**No FK constraints** - BankID and DepotID are referenced implicitly. There is no explicit FK to Dictionary.Bank or Billing.Depot.

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **BankID** | int | NOT NULL | - | Dictionary.Bank(BankID) [implicit] | [CODE-BACKED] Acquiring bank; part of composite PK. No explicit FK constraint. |
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) [implicit] | [CODE-BACKED] Payment depot for this bank; part of composite PK. No explicit FK constraint. |
| **Priority** | int | NULL | - | - | [CODE-BACKED] Routing priority. Higher value = higher priority (50=lower, 100=highest observed). NULL allowed. |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_Billing_BankToDepot | CLUSTERED | (BankID ASC, DepotID ASC) | No FILLFACTOR specified. |

---

## 4. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Dictionary.Bank | Many-to-one | BankToDepot.BankID = Bank.BankID | Implicit (no FK). |
| Billing.Depot | Many-to-one | BankToDepot.DepotID = Depot.DepotID | Implicit (no FK). |

---

*Quality: 8.8/10 | 3 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,11*
