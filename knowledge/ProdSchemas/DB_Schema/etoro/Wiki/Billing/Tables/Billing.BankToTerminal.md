# Billing.BankToTerminal

> Legacy bank-to-terminal routing table. Each row maps an acquiring bank (Dictionary.Bank) to a processing terminal (Billing.Terminal) with a priority for failover/load balancing. 40 entries. Part of the legacy Terminal-based payment routing system, predating the Depot-based system.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (BankID, TerminalID) - PRIMARY KEY CLUSTERED |
| **Row Count** | 40 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 CLUSTERED composite PK; 1 NC on TerminalID |

---

## 1. Business Meaning

`Billing.BankToTerminal` is the routing table for the legacy terminal-based payment system. It defines which terminals a specific acquiring bank can process through, with Priority controlling preference order when multiple terminals are available for a bank.

This table belongs to the legacy payment flow (used by `Billing.Payment`, `Billing.Terminal`). The modern equivalent is `Billing.BankToDepot` which maps banks to depots. Banks in this context are acquiring banks (e.g., BankID=3, BankID=4 are represented with multiple terminal assignments).

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **BankID** | int | NOT NULL | - | Dictionary.Bank(BankID) | [CODE-BACKED] Acquiring bank; part of composite PK. |
| **TerminalID** | int | NOT NULL | - | Billing.Terminal(TerminalID) | [CODE-BACKED] Processing terminal for this bank; part of composite PK. Also NC index key for reverse lookup. |
| **Priority** | int | NOT NULL | - | - | [CODE-BACKED] Routing priority. Lower value = higher priority. All observed values are 1 (equal priority). |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BB2T | CLUSTERED | (BankID ASC, TerminalID ASC) | FILLFACTOR=90. |
| BB2T_TERMINAL | NONCLUSTERED | TerminalID ASC | FILLFACTOR=90. Reverse lookup: which banks use a terminal. |

---

## 4. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Dictionary.Bank | Many-to-one | BankToTerminal.BankID = Bank.BankID | Explicit FK. Acquiring bank lookup. |
| Billing.Terminal | Many-to-one | BankToTerminal.TerminalID = Terminal.TerminalID | Explicit FK. Legacy terminal table. |

---

*Quality: 8.8/10 | 3 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,11 | Legacy routing table*
