# Billing.GetWireTransferBankDetails

> Returns complete bank account details for a wire transfer bank configuration (BankID + CurrencyID, optionally filtered by RegulationID): the full set of fields a customer needs to initiate a wire transfer deposit (SWIFT, IBAN, account number, routing number, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BankID + @CurrencyID (+ optional @RegulationID); returns TOP 1 row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetWireTransferBankDetails retrieves the complete banking details that must be shown to a customer to initiate a wire transfer deposit. When a customer selects wire transfer as their deposit method, the billing service calls this procedure to get the beneficiary bank account details (bank name, account number, SWIFT/BIC code, IBAN, routing number, etc.) to display or send to the customer.

The `TOP 1 ... ORDER BY wti.ID` pattern ensures deterministic single-row output when multiple configurations match (BankID + CurrencyID may have records across multiple regulations).

`@RegulationID` is optional (default NULL = match any regulation), giving callers flexibility to retrieve the regulation-specific bank details or the first available configuration.

EXECUTE permission is granted to `WireTransferUser` (see DDL comment), indicating this is part of a dedicated wire transfer service account.

---

## 2. Business Logic

### 2.1 Bank Details Retrieval

**What**: Fetches all wire transfer banking fields for the specified bank, currency, and optionally regulation.

**Columns/Parameters Involved**: `@BankID`, `@CurrencyID`, `@RegulationID`, all WireTransferBankInfo columns, `Billing.WireTransferBanks.DepotID`

**Rules**:
- `WHERE wt.ID = @BankID AND wti.CurrencyID = @CurrencyID`
- `AND (@RegulationID IS NULL OR wti.RegulationID = @RegulationID)` - regulation filter is optional
- `TOP 1 ... ORDER BY wti.ID` - returns the lowest-ID matching configuration if multiple exist
- Joins WireTransferBanks (depot mapping) to WireTransferBankInfo (bank details) on BankID

### 2.2 International Banking Fields

**What**: Returns the full set of international wire transfer identifiers needed for different banking systems.

**Rules**:
- `SwiftCode` / `BIK`: SWIFT/BIC for international wires; BIK is the Russian bank routing code equivalent
- `IBANCode`: International Bank Account Number (EU/SEPA wire transfers)
- `RoutingNumber`: US ACH/wire routing number
- `BSB`: Bank-State-Branch code (Australian wire transfers)
- `SortCode`: UK bank sort code
- `INNCode`: Russian tax identification number for beneficiary
- `CorrespondentAccount`: Russian correspondent account number for inter-bank routing
- `AccountNumber`: Generic account number (used when IBAN not applicable)
- `Beneficiary`, `BeneficiaryAddress`: Legal name and address of the receiving entity
- `BankFullName`, `BranchName`, `BankAddress`: Bank identification details

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BankID | INT | NO | - | CODE-BACKED | Bank identifier. Maps to Billing.WireTransferBanks.ID. Selects which bank's details to retrieve. |
| 2 | @CurrencyID | INT | NO | - | CODE-BACKED | Currency identifier. Filters WireTransferBankInfo to the currency-specific bank configuration (same bank may have different details for USD vs EUR). |
| 3 | @RegulationID | INT | YES | NULL | CODE-BACKED | Optional regulatory jurisdiction filter. If NULL, returns the first matching config regardless of regulation. If specified, restricts to that regulation's bank configuration. |
| - | BankID | INT | NO | - | CODE-BACKED | Echo of @BankID from WireTransferBankInfo. |
| - | CurrencyID | INT | NO | - | CODE-BACKED | Currency for this bank configuration. |
| - | RegulationID | INT | YES | - | CODE-BACKED | Regulatory jurisdiction for this bank configuration. |
| - | BankFullName | NVARCHAR | YES | - | CODE-BACKED | Full legal name of the beneficiary bank. Displayed to the customer for wire transfer instructions. |
| - | SortCode | VARCHAR | YES | - | CODE-BACKED | UK bank sort code (6 digits, format XX-XX-XX). Used for GBP wire transfers to UK banks. |
| - | Beneficiary | NVARCHAR | YES | - | CODE-BACKED | Legal name of the beneficiary (eToro entity receiving the wire). Required on all wire transfer instructions. |
| - | BeneficiaryAddress | NVARCHAR | YES | - | CODE-BACKED | Registered address of the beneficiary entity. Required by many banks for wire compliance. |
| - | AccountNumber | VARCHAR | YES | - | CODE-BACKED | Bank account number. Used when IBAN is not applicable (e.g., US, Australia). |
| - | SwiftCode | VARCHAR | YES | - | CODE-BACKED | SWIFT/BIC code of the beneficiary bank. Required for all international wire transfers. |
| - | IBANCode | VARCHAR | YES | - | CODE-BACKED | International Bank Account Number. Required for SEPA/EU wire transfers. |
| - | BranchName | NVARCHAR | YES | - | CODE-BACKED | Name of the bank branch. Supplementary identification for some wire systems. |
| - | BankAddress | NVARCHAR | YES | - | CODE-BACKED | Physical address of the bank or branch. Required by some payment systems. |
| - | BSB | VARCHAR | YES | - | CODE-BACKED | Bank-State-Branch code (Australia). Required for AUD wire transfers to Australian banks. |
| - | INNCode | VARCHAR | YES | - | CODE-BACKED | Russian taxpayer identification number (INN) of the beneficiary. Required for RUB wires. |
| - | BIK | VARCHAR | YES | - | CODE-BACKED | Russian Bank Identification Code (BIK). Equivalent to SWIFT for Russian domestic wires. |
| - | CorrespondentAccount | VARCHAR | YES | - | CODE-BACKED | Correspondent bank account for Russian inter-bank routing. Required for RUB wires. |
| - | RoutingNumber | VARCHAR | YES | - | CODE-BACKED | US ABA routing number. Required for USD wire transfers via US banking system. |
| - | DepotID | INT | YES | - | CODE-BACKED | Payment terminal/MID from Billing.WireTransferBanks. Used internally for routing the deposit to the correct processing endpoint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BankID, DepotID | Billing.WireTransferBanks | SELECT (anchor) | Maps BankID to DepotID |
| BankID, CurrencyID, RegulationID, all bank detail fields | Billing.WireTransferBankInfo | INNER JOIN | Source of all bank account details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wire transfer deposit service (WireTransferUser) | @BankID, @CurrencyID | EXEC | Retrieves bank details to display to customer for wire transfer instructions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWireTransferBankDetails (procedure)
+-- Billing.WireTransferBanks (table) [BankID -> DepotID]
+-- Billing.WireTransferBankInfo (table) [bank account details by currency/regulation]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WireTransferBanks | Table | Anchor join; provides DepotID for the bank |
| Billing.WireTransferBankInfo | Table | Source of all banking details (SWIFT, IBAN, account, etc.) filtered by BankID + CurrencyID + RegulationID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| WireTransferUser service account | External | Wire transfer service that displays bank details to depositing customers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 1 ORDER BY wti.ID | Design | Deterministic single-row output; lowest-ID matching record returned when multiple configs exist |
| @RegulationID optional | Flexibility | NULL = any regulation; callers without regulation context can still retrieve bank details |
| WireTransferUser grant | Security | EXECUTE permission granted to a dedicated wire transfer service account (DDL comment) |
| NOLOCK | Concurrency | Both tables read with NOLOCK - configuration data; acceptable for display purposes |

---

## 8. Sample Queries

### 8.1 Get bank details for a specific bank and currency

```sql
EXEC [Billing].[GetWireTransferBankDetails]
    @BankID = 5,
    @CurrencyID = 1,       -- USD
    @RegulationID = NULL   -- any regulation
-- Returns: full bank details including SWIFT, IBAN, AccountNumber, DepotID
```

### 8.2 Get regulation-specific bank details

```sql
EXEC [Billing].[GetWireTransferBankDetails]
    @BankID = 5,
    @CurrencyID = 2,   -- EUR
    @RegulationID = 1  -- CySEC
```

### 8.3 Browse all wire bank configurations

```sql
SELECT wt.ID AS BankID, wti.CurrencyID, wti.RegulationID,
       wti.BankFullName, wti.SwiftCode, wti.IBANCode, wt.DepotID
FROM [Billing].[WireTransferBanks] wt WITH (NOLOCK)
INNER JOIN [Billing].[WireTransferBankInfo] wti WITH (NOLOCK) ON wt.ID = wti.BankID
ORDER BY wt.ID, wti.CurrencyID, wti.RegulationID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object directly. Related wire transfer architecture documented in "Wire Transfer Re-Architecture Proposal" and "Wire MIDs - LLD" (/spaces/MG).

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetWireTransferBankDetails | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetWireTransferBankDetails.sql*
