# Billing.ACHBanks

> Legacy duplicate of Billing.ACHBankAccount - stores identical ACH bank credentials for depot 75 (SilverGate Bank) but is no longer referenced by any stored procedure.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR 95) |

---

## 1. Business Meaning

`Billing.ACHBanks` has an identical structure and data to `Billing.ACHBankAccount`. Both tables contain exactly 2 rows representing the deposit and cashout bank account credentials for DepotID=75 ("ACH(Silvergate)" - SilverGate Bank). The rows are byte-for-byte duplicates: same BankName, AccountNumber, RoutingNumber, and IsActive values.

Unlike `Billing.ACHBankAccount`, no stored procedure in the codebase currently references `Billing.ACHBanks`. The active lookup path uses `Billing.GetActiveACHBankAccount` which queries `Billing.ACHBankAccount`. This table appears to be the older or alternative version that was replaced by (or co-created with) `Billing.ACHBankAccount` and subsequently abandoned.

Both columns `BankName` and `AccountNumber` carry PCI data masking (`MASKED WITH (FUNCTION = 'default()')`) consistent with `Billing.ACHBankAccount`.

---

## 2. Business Logic

### 2.1 Relationship to ACHBankAccount

**What**: This table is a structural and data duplicate of Billing.ACHBankAccount with no active consumers.

**Columns/Parameters Involved**: All columns (identical to ACHBankAccount)

**Rules**:
- Structure: identical DDL schema to `Billing.ACHBankAccount` (same column names, types, nullability, masking).
- Data: identical 2 rows (DepotID=75, PaymentTypeID=1 and 2, SilverGate Bank).
- No stored procedures, views, or functions reference this table in the SSDT repo.
- `Billing.GetActiveACHBankAccount` queries `Billing.ACHBankAccount`, NOT this table.

**Diagram**:
```
Billing.ACHBankAccount   <-- Active, queried by Billing.GetActiveACHBankAccount
Billing.ACHBanks         <-- Inactive duplicate, no code consumers
  (identical structure and data - possible original version or parallel migration artifact)
```

---

## 3. Data Overview

| ID | DepotID | PaymentTypeID | BankName | RoutingNumber | IsActive | Meaning |
|----|---------|--------------|----------|---------------|---------|---------|
| 1 | 75 | 1 | SilverGate Bank | 322286803 | true | ACH deposit credentials for SilverGate Bank - identical to Billing.ACHBankAccount row 1. Depot 75 is inactive. |
| 2 | 75 | 2 | SilverGate Bank | 322286803 | true | ACH cashout credentials for SilverGate Bank - identical to Billing.ACHBankAccount row 2. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key, auto-incremented. Same semantics as Billing.ACHBankAccount.ID. |
| 2 | DepotID | int | NO | - | CODE-BACKED | References the payment depot in `Billing.Depot`. Value 75 = "ACH(Silvergate)". Same meaning as Billing.ACHBankAccount.DepotID. |
| 3 | PaymentTypeID | int | NO | - | CODE-BACKED | Payment direction: 1=Deposit, 2=Cashout. Same meaning as Billing.ACHBankAccount.PaymentTypeID. |
| 4 | BankName | varchar(30) | YES | - | CODE-BACKED | Bank name. MASKED WITH (FUNCTION = 'default()') - PCI data masking. Current value: "SilverGate Bank". Same as Billing.ACHBankAccount.BankName. |
| 5 | AccountNumber | varchar(30) | YES | - | CODE-BACKED | Bank account number. MASKED WITH (FUNCTION = 'default()') - PCI data masking. Same as Billing.ACHBankAccount.AccountNumber. |
| 6 | RoutingNumber | varchar(30) | NO | - | CODE-BACKED | ABA routing number identifying the bank. Not masked. Value "322286803" = SilverGate Bank. Same as Billing.ACHBankAccount.RoutingNumber. |
| 7 | IsActive | bit | NO | - | CODE-BACKED | Whether this account configuration is active: 1=Active, 0=Inactive. Both rows are currently 1 (active) despite the depot being decommissioned. Same semantics as Billing.ACHBankAccount.IsActive. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepotID | Billing.Depot | Implicit FK | Identifies the payment depot. Same relationship as Billing.ACHBankAccount.DepotID. |

### 5.2 Referenced By (other objects point to this)

No dependents found. No stored procedures, views, or functions reference this table in the SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingACHBanks | CLUSTERED PK | ID ASC | - | - | Active |

FILLFACTOR=95 applied. Stored on PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingACHBanks | PRIMARY KEY | ID - unique row identifier |
| BankName MASKED | Dynamic Data Mask | FUNCTION = 'default()' - PCI protection |
| AccountNumber MASKED | Dynamic Data Mask | FUNCTION = 'default()' - PCI protection |

---

## 8. Sample Queries

### 8.1 View all records (unmasked - requires UNMASK permission)

```sql
SELECT ID, DepotID, PaymentTypeID, BankName, AccountNumber, RoutingNumber, IsActive
FROM [Billing].[ACHBanks] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Compare with ACHBankAccount to confirm they are identical

```sql
SELECT a.ID, a.DepotID, a.PaymentTypeID, a.RoutingNumber, a.IsActive,
       b.ID AS ABAcc_ID, b.RoutingNumber AS ABAcc_Routing
FROM [Billing].[ACHBanks] a WITH (NOLOCK)
FULL OUTER JOIN [Billing].[ACHBankAccount] b WITH (NOLOCK)
  ON a.DepotID = b.DepotID AND a.PaymentTypeID = b.PaymentTypeID;
```

### 8.3 Active bank accounts per depot (active equivalent)

```sql
SELECT n.ID, n.DepotID, d.Name AS DepotName, n.PaymentTypeID, n.RoutingNumber, n.IsActive
FROM [Billing].[ACHBanks] n WITH (NOLOCK)
LEFT JOIN [Billing].[Depot] d WITH (NOLOCK) ON n.DepotID = d.DepotID
WHERE n.IsActive = 1
ORDER BY n.DepotID, n.PaymentTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHBanks | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ACHBanks.sql*
