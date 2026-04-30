# Billing.GetActiveACHBankAccount

> Returns active ACH bank account credentials (bank name, account number, routing number) filtered by depot and payment direction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepotID + @PaymentTypeID composite filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetActiveACHBankAccount` retrieves the bank account credentials stored in `Billing.ACHBankAccount` for use in ACH transaction processing. ACH (Automated Clearing House) is the US domestic bank transfer network used for low-cost fund movement between customers and eToro bank accounts.

The Routing Tool (a WinForms back-office admin application) calls this procedure to look up which bank account to use when initiating ACH transactions. Each ACH depot can have separate bank account configurations for deposits (PaymentTypeID=1) and cashouts (PaymentTypeID=2), allowing different bank accounts to receive customer money vs. fund cashouts.

`@DepotID=0` acts as a wildcard - when passed as 0, the procedure returns active ACH accounts for ALL depots for the specified payment type, useful for administrative views. When passed a specific DepotID, it returns the credentials for that single depot.

The returned `BankName` and `AccountNumber` columns have SQL Server Dynamic Data Masking (`default()`) on the underlying table - users without `UNMASK` permission see redacted values protecting PCI-sensitive bank account data. `RoutingNumber` is not masked as ABA routing numbers are public bank identifiers.

As of early 2023, the only ACH depot (DepotID=75, SilverGate Bank) became inactive in `Billing.Depot` after SilverGate Bank collapsed. However, `Billing.ACHBankAccount` records remain `IsActive=1`, meaning this procedure still returns those records.

---

## 2. Business Logic

### 2.1 Depot-Filtered Credential Retrieval

**What**: Returns ACH bank account credentials matching depot and payment direction filters.

**Columns/Parameters Involved**: `@DepotID`, `@PaymentTypeID`, `IsActive`

**Rules**:
- `WHERE (DepotID = @DepotID OR @DepotID = 0)`: dual-mode filter - specific depot when @DepotID > 0, all depots when @DepotID = 0.
- `AND PaymentTypeID = @PaymentTypeID`: required filter for payment direction. PaymentTypeID=1=Deposit, PaymentTypeID=2=Cashout.
- `AND IsActive = 1`: only returns active credentials; deactivated records are retained for audit but never returned.
- `WITH (NOLOCK)`: dirty-read for performance; credential lookups accept minor inconsistency.
- Returns ID, DepotID, PaymentTypeID, BankName (masked), AccountNumber (masked), RoutingNumber, IsActive.

### 2.2 PCI Data Masking

**What**: Sensitive bank account fields are protected at the database layer.

**Rules**:
- `BankName` and `AccountNumber` on `Billing.ACHBankAccount` are masked with `MASKED WITH (FUNCTION = 'default()')`.
- Users without `UNMASK` database permission see redacted values.
- `RoutingNumber` is NOT masked - ABA routing numbers are public.
- This is a database-layer PCI control complementing application-level security.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepotID | INT | NO | - | CODE-BACKED | Depot to filter credentials for. Pass 0 to return all depots' active accounts for the given PaymentTypeID (wildcard). Pass specific DepotID for single-depot lookup. |
| 2 | @PaymentTypeID | INT | NO | - | CODE-BACKED | Payment direction filter. 1=Deposit (credentials for receiving customer funds), 2=Cashout (credentials for sending customer funds). |

**Return columns** (from Billing.ACHBankAccount):

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | ID | INT | CODE-BACKED | PK of Billing.ACHBankAccount row. |
| R2 | DepotID | INT | CODE-BACKED | The payment depot this bank account belongs to. FK to Billing.Depot. Currently only DepotID=75 (ACH/SilverGate). |
| R3 | PaymentTypeID | INT | CODE-BACKED | Payment direction: 1=Deposit, 2=Cashout. |
| R4 | BankName | VARCHAR (masked) | CODE-BACKED | Name of the bank. Protected by Dynamic Data Masking - visible only to users with UNMASK permission. |
| R5 | AccountNumber | VARCHAR (masked) | CODE-BACKED | Bank account number. Protected by Dynamic Data Masking - visible only to users with UNMASK permission. |
| R6 | RoutingNumber | VARCHAR | CODE-BACKED | ABA routing number (public bank identifier). Not masked. Used by ACH processing to route funds to the correct bank. |
| R7 | IsActive | BIT | CODE-BACKED | Whether this account configuration is active. Always 1 in results (filter condition). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepotID, @PaymentTypeID | Billing.ACHBankAccount | Reader | SELECT all credential columns WHERE depot + payment type + active |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Routing Tool (WinForms admin app) | External | Caller | Looks up ACH bank credentials to use when initiating ACH transactions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetActiveACHBankAccount (procedure)
└── Billing.ACHBankAccount (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ACHBankAccount | Table | SELECT all columns WHERE (DepotID=@DepotID OR @DepotID=0) AND PaymentTypeID=@PaymentTypeID AND IsActive=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Routing Tool (WinForms) | External | Retrieves ACH bank credentials for transaction processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses WITH (NOLOCK). No SET NOCOUNT ON. No RETURN statement. No TRY/CATCH. @DepotID=0 wildcard pattern for multi-depot admin queries. BankName and AccountNumber are masked on the source table (PCI - Dynamic Data Masking).

---

## 8. Sample Queries

### 8.1 Get deposit credentials for a specific depot

```sql
EXEC [Billing].[GetActiveACHBankAccount]
    @DepotID = 75,
    @PaymentTypeID = 1;  -- 1=Deposit
-- Returns BankName, AccountNumber (both masked unless UNMASK granted), RoutingNumber for ACH deposit account
```

### 8.2 Get all active ACH cashout accounts

```sql
EXEC [Billing].[GetActiveACHBankAccount]
    @DepotID = 0,        -- 0 = all depots
    @PaymentTypeID = 2;  -- 2=Cashout
```

### 8.3 Check underlying ACH accounts directly

```sql
SELECT ID, DepotID, PaymentTypeID, BankName, AccountNumber, RoutingNumber, IsActive
FROM [Billing].[ACHBankAccount] WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY DepotID, PaymentTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetActiveACHBankAccount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetActiveACHBankAccount.sql*
