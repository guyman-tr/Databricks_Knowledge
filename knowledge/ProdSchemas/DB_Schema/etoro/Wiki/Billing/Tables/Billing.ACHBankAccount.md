# Billing.ACHBankAccount

> Configuration table storing the ACH (Automated Clearing House) bank account credentials used to process US domestic ACH deposits and cashouts per depot.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR 95) |

---

## 1. Business Meaning

`Billing.ACHBankAccount` stores the bank account details (bank name, account number, routing number) for each ACH-enabled depot, split by payment direction (deposit vs cashout). ACH is the US domestic bank transfer network used for slower but low-cost fund movement between customers and eToro accounts.

This table exists because ACH transactions require precise bank routing credentials that must be versioned by depot and payment type. The `IsActive` flag allows credentials to be deactivated without deletion when a banking relationship ends (e.g., bank closure). `BankName` and `AccountNumber` are protected with SQL Server dynamic data masking (`default()`) - users without `UNMASK` permission see redacted values, reflecting the PCI-sensitive nature of bank account data.

Currently only 2 rows exist, both referencing DepotID=75 ("ACH(Silvergate)" - SilverGate Bank, FundingTypeID=29/ACH). That depot is inactive in `Billing.Depot` (SilverGate Bank collapsed in 2023), but both ACHBankAccount rows remain `IsActive=true` in this table. The Routing Tool (WinForms admin application) manages these records via `Billing.GetActiveACHBankAccount`.

---

## 2. Business Logic

### 2.1 Credential Lookup by Direction

**What**: Each ACH depot has separate account configurations for deposits vs cashouts.

**Columns/Parameters Involved**: `DepotID`, `PaymentTypeID`, `IsActive`

**Rules**:
- A single depot can have up to two rows: one for deposits (PaymentTypeID=1) and one for cashouts (PaymentTypeID=2).
- `Billing.GetActiveACHBankAccount` filters to `IsActive=1` only - deactivated rows are retained for audit but never returned.
- `@DepotID=0` in the lookup procedure acts as a wildcard returning all depots' accounts for the given PaymentTypeID.

**Diagram**:
```
GetActiveACHBankAccount(@DepotID, @PaymentTypeID)
        |
        +-- @DepotID=0  -> return ALL depots, filter by PaymentTypeID + IsActive=1
        |
        +-- @DepotID=N  -> return specific depot, filter by PaymentTypeID + IsActive=1
                |
                v
        ACHBankAccount row: BankName, AccountNumber, RoutingNumber
```

### 2.2 PCI Data Masking

**What**: Bank account details are protected by SQL Server Dynamic Data Masking.

**Columns/Parameters Involved**: `BankName`, `AccountNumber`

**Rules**:
- Both columns have `MASKED WITH (FUNCTION = 'default()')` - users without explicit `UNMASK` permission see redacted values (e.g., `xxxx` for varchar).
- `RoutingNumber` is NOT masked - routing numbers are public bank identifiers (ABA numbers) and not considered sensitive PCI data.
- The masking enforces least-privilege access at the database layer, complementing application-level PCI controls.

---

## 3. Data Overview

| ID | DepotID | PaymentTypeID | BankName | RoutingNumber | IsActive | Meaning |
|----|---------|--------------|----------|---------------|---------|---------|
| 1 | 75 | 1 | SilverGate Bank | 322286803 | true | ACH deposit account at SilverGate Bank (DepotID=75 "ACH(Silvergate)"). Depot is currently inactive in Billing.Depot following SilverGate Bank's 2023 closure. Used for incoming ACH deposits. |
| 2 | 75 | 2 | SilverGate Bank | 322286803 | true | ACH cashout account at SilverGate Bank - same routing number, used for outgoing ACH cashout transactions. Retained for historical reference. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key, auto-incremented. Used as the stable row identifier in admin tooling. |
| 2 | DepotID | int | NO | - | CODE-BACKED | References the payment gateway endpoint in `Billing.Depot`. Determines which gateway's account credentials are stored. FK to Billing.Depot.DepotID. Value 75 = "ACH(Silvergate)". The `GetActiveACHBankAccount` procedure accepts DepotID=0 as a wildcard to retrieve all depot accounts. |
| 3 | PaymentTypeID | int | NO | - | CODE-BACKED | Direction of the payment flow: 1=Deposit (customer funds coming in), 2=Cashout (funds going out to customer). Allows the same banking relationship to store separate credentials per direction. Matches the PaymentTypeID dimension in `Billing.Depot`. |
| 4 | BankName | varchar(30) | YES | - | CODE-BACKED | Name of the bank holding the ACH account. MASKED WITH (FUNCTION = 'default()') - PCI data masking applied; users without UNMASK permission see a redacted value. Current value: "SilverGate Bank". |
| 5 | AccountNumber | varchar(30) | YES | - | CODE-BACKED | Bank account number for ACH transactions at this depot. MASKED WITH (FUNCTION = 'default()') - PCI data masking applied. This is the destination/source account number for ACH files sent to the banking network. |
| 6 | RoutingNumber | varchar(30) | NO | - | CODE-BACKED | ABA routing transit number identifying the bank and branch for ACH transaction routing. Not masked (routing numbers are public identifiers). Value "322286803" = SilverGate Bank (Pacific Coast). |
| 7 | IsActive | bit | NO | - | CODE-BACKED | Whether this bank account configuration is currently active: 1=Active (returned by GetActiveACHBankAccount), 0=Inactive (excluded from lookups, retained for audit). The READER procedure filters `IsActive=1` only. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepotID | Billing.Depot | Implicit FK | Identifies the payment depot whose ACH account credentials are stored. No explicit FK constraint - enforced by application. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetActiveACHBankAccount | @DepotID, @PaymentTypeID | READER | Returns active ACH bank account credentials for a depot + payment type combination. The only read path for this table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetActiveACHBankAccount | Stored Procedure | READER - returns active account credentials filtered by DepotID and PaymentTypeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingACHBankAccount | CLUSTERED PK | ID ASC | - | - | Active |

FILLFACTOR=95 applied. Stored on PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingACHBankAccount | PRIMARY KEY | ID - ensures each bank account record is uniquely identifiable |
| BankName MASKED | Dynamic Data Mask | FUNCTION = 'default()' - redacts bank name for users without UNMASK permission |
| AccountNumber MASKED | Dynamic Data Mask | FUNCTION = 'default()' - redacts account number for users without UNMASK permission |

---

## 8. Sample Queries

### 8.1 Get active ACH deposit account for a specific depot

```sql
SELECT ID, DepotID, PaymentTypeID, BankName, AccountNumber, RoutingNumber, IsActive
FROM [Billing].[ACHBankAccount] WITH (NOLOCK)
WHERE DepotID = 75
  AND PaymentTypeID = 1  -- Deposit
  AND IsActive = 1;
```

### 8.2 List all active ACH accounts across all depots

```sql
SELECT a.ID, a.DepotID, d.Name AS DepotName, a.PaymentTypeID,
       a.BankName, a.RoutingNumber, a.IsActive
FROM [Billing].[ACHBankAccount] a WITH (NOLOCK)
INNER JOIN [Billing].[Depot] d WITH (NOLOCK) ON a.DepotID = d.DepotID
WHERE a.IsActive = 1
ORDER BY a.DepotID, a.PaymentTypeID;
```

### 8.3 Check all configurations including inactive (audit view)

```sql
SELECT a.ID, a.DepotID, d.Name AS DepotName, d.IsActive AS DepotActive,
       a.PaymentTypeID, a.BankName, a.RoutingNumber, a.IsActive AS AccountActive
FROM [Billing].[ACHBankAccount] a WITH (NOLOCK)
LEFT JOIN [Billing].[Depot] d WITH (NOLOCK) ON a.DepotID = d.DepotID
ORDER BY a.DepotID, a.PaymentTypeID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Routing Tool Mapping](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13998850143/Routing+Tool+Mapping) | Confluence | Confirms ACHBankAccount is managed via the Routing Tool (WinForms application) - a payment operations admin tool. Page not fully accessible. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.9/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHBankAccount | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ACHBankAccount.sql*
