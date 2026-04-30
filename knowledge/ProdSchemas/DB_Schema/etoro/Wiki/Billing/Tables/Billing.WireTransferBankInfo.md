# Billing.WireTransferBankInfo

> eToro's wire transfer receiving bank account details - stores the full banking coordinates (SWIFT, IBAN, sort code, BSB, routing number, etc.) for each eToro entity account per bank, currency, and regulatory jurisdiction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No ([PRIMARY] filegroup) |
| **Indexes** | 1 (PK only) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.WireTransferBankInfo stores the complete banking coordinates for eToro's receiving bank accounts used for wire transfer deposits. When a customer wants to deposit via wire transfer, the system provides them with eToro's bank account details - the beneficiary name, account number, SWIFT/BIC code, IBAN, and any country-specific codes (SortCode for UK, BSB for Australia, RoutingNumber for USA, INN/BIK/CorrespondentAccount for Russia). The customer then instructs their own bank to send a wire to these coordinates.

Each row represents eToro's account at a specific bank (BankID), in a specific currency (CurrencyID), potentially for a specific regulatory jurisdiction (RegulationID). Multiple rows per bank cover multiple currencies.

**87 rows** across **15 banks** and **18 currencies** and **12 regulation IDs**:

| BankID | Bank | Rows | Primary Use |
|--------|------|------|-------------|
| 1 | Barclays Bank | 6 | eToro (Europe) Ltd. - legacy UK bank |
| 2 | Wirecard | 2 | Legacy (Wirecard collapsed 2020) |
| 3 | Sberbank | 3 | Russian market (now likely discontinued) |
| 4 | Westpac | 6 | Australian market (AUD deposits) |
| 5 | Zotopay-Cashu | 1 | Zotapay cash payment channel |
| 6 | Zotopay-Cup | 1 | Zotapay UnionPay channel |
| 7 | Coutts | 15 | Premium/private banking (UK) |
| 8 | National Australia Bank | 8 | Australian market |
| 9 | Silvergate | 2 | US crypto-friendly bank (closed 2023) |
| 10 | Banking Circle | 4 | EU payment institution |
| 12 | JPMorgan | 32 | Primary global bank - most currencies/regulations |
| 13 | Deutsche Bank | 4 | EU/German market |
| 14 | Customers Bank | 1 | US market |
| 15 | Marsheq | 1 | Israeli market |
| 16 | DBS bank Singapore | 1 | Singapore/APAC market |

JPMorgan (32 rows) is the dominant bank, covering most currency and regulation combinations.

**Beneficiary is always an eToro entity** - these are eToro's own receiving accounts (e.g., "eToro (Europe) Ltd.", "eToro AUS Capital Limited"), not customer accounts.

---

## 2. Business Logic

### 2.1 Bank Detail Lookup

**Read by**: `Billing.GetWireTransferBankDetails`

```sql
-- Primary consumer
SELECT TOP 1
   wti.BankID, wti.CurrencyID, wti.RegulationID,
   wti.BankFullName, wti.SortCode, wti.Beneficiary, wti.BeneficiaryAddress,
   wti.AccountNumber, wti.SwiftCode, wti.IBANCode, wti.BranchName,
   wti.BankAddress, wti.BSB, wti.INNCode, wti.BIK, wti.CorrespondentAccount,
   wti.RoutingNumber, wt.DepotID
FROM Billing.WireTransferBanks AS wt WITH (NOLOCK)
INNER JOIN Billing.WireTransferBankInfo AS wti WITH (NOLOCK) ON wt.ID = wti.BankID
WHERE wt.ID = @BankID AND wti.CurrencyID = @CurrencyID
AND (@RegulationID IS NULL OR wti.RegulationID = @RegulationID)
ORDER BY wti.ID
```

Note `SELECT TOP 1` - if multiple rows match (e.g., RegulationID IS NULL with multiple jurisdictions), the lowest ID row is returned.

### 2.2 Regulation-Currency Routing

**Read by**: `Billing.GetWireDepotIdsByRegulationAndCurrency` and `Billing.GetDepotIdByWireTransferBankInfo` - used to determine the DepotID for a wire transfer deposit, joining BankInfo with WireTransferBanks to resolve the eToro internal depot/account.

---

## 3. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-incremented. NOT FOR REPLICATION. PK name "PK_WireTranferBanks" has a typo (missing 's'). |
| 2 | BankID | INT | NO | - | CODE-BACKED | FK to Billing.WireTransferBanks(ID). Identifies the bank holding eToro's receiving account. 15 distinct banks: JPMorgan (12), Coutts (7), Barclays (1), NAB (8), Westpac (4), etc. |
| 3 | CurrencyID | INT | NO | - | CODE-BACKED | The account currency. Implicit FK to Dictionary.Currency(CurrencyID). 18 distinct currencies covered. Barclays BankID=1 has accounts for CurrencyIDs 1-6 (USD, EUR, GBP, and others). |
| 4 | BankFullName | NVARCHAR(50) | YES | - | CODE-BACKED | Full legal name of the receiving bank. Example: "Barclays Bank". Redundant with WireTransferBanks.BankName but allows per-account variations. |
| 5 | Beneficiary | NVARCHAR(50) | YES | - | CODE-BACKED | The account holder name - always an eToro legal entity. Examples: "eToro (Europe) Ltd.", "eToro AUS Capital Limited". Shown to the customer as the wire recipient. |
| 6 | AccountNumber | NVARCHAR(50) | YES | - | CODE-BACKED | Traditional bank account number. Used where IBAN is not applicable (e.g., some non-EU accounts). |
| 7 | SwiftCode | NVARCHAR(50) | YES | - | CODE-BACKED | SWIFT/BIC code of the receiving bank. 8 or 11 characters. Examples: "BARCGB22" (Barclays UK), "CHASUS33" (JPMorgan US). Required for all international wires. |
| 8 | IBANCode | NVARCHAR(50) | YES | - | CODE-BACKED | IBAN (International Bank Account Number). Used in SEPA/EU wire transfers. Format varies by country: GB* for UK (e.g., "GB93BARC20199072639299"), DE* for Germany, etc. |
| 9 | BranchName | NVARCHAR(100) | YES | - | CODE-BACKED | Name of the bank branch. Optional additional routing detail for the paying bank. |
| 10 | BankAddress | NVARCHAR(100) | YES | - | CODE-BACKED | Physical address of the receiving bank branch. Shown to customers for manual wire instructions. |
| 11 | SortCode | NVARCHAR(20) | YES | - | CODE-BACKED | UK sort code (format: XX-XX-XX). Used for UK domestic transfers. Barclays: "20-19-90". Null for non-UK banks. |
| 12 | BSB | NVARCHAR(20) | YES | - | CODE-BACKED | BSB (Bank State Branch) code - Australian bank routing number. Used for AUD transfers to Westpac/NAB. Null for non-Australian accounts. |
| 13 | INNCode | NVARCHAR(20) | YES | - | CODE-BACKED | INN (Taxpayer Identification Number) - Russian tax ID for the receiving entity. Used for transfers to Sberbank accounts. Null for non-Russian banks. |
| 14 | BIK | NVARCHAR(20) | YES | - | CODE-BACKED | BIK (Bank Identification Code) - Russian bank routing code (9 digits). Required for RUB wire transfers to Sberbank. Null for non-Russian banks. |
| 15 | CorrespondentAccount | NVARCHAR(50) | YES | - | CODE-BACKED | Russian correspondent account number (korschet). Used alongside BIK for Russian domestic wire instructions. Null for non-Russian banks. |
| 16 | RegulationID | INT | NO | DEFAULT(0) | CODE-BACKED | Regulatory jurisdiction this account is associated with. DEFAULT=0 (no specific regulation / global). Implicit FK to regulation configuration. 12 distinct values across rows. When 0, the account is not regulation-specific. |
| 17 | RoutingNumber | VARCHAR(20) | YES | - | CODE-BACKED | ABA routing number for US domestic wire transfers (9-digit number). Used for USD transfers via ACH/FEDWIRE to US banks (JPMorgan, Silvergate, Customers Bank, Banking Circle). |
| 18 | BeneficiaryAddress | NVARCHAR(150) | YES | - | CODE-BACKED | Physical address of the eToro entity receiving the wire. Longer field (150 chars) to accommodate full legal address. Shown to customers completing wire instructions. |

---

## 4. Relationships

### 4.1 References To

| Element | Related Object | Relationship Type |
|---------|---------------|-------------------|
| BankID | Billing.WireTransferBanks | FK (FK_WireTransferBankInfo_WireTransferBanks) - references WireTransferBanks.ID |

### 4.2 Referenced By

| Source Object | Relationship |
|--------------|-------------|
| Billing.GetWireTransferBankDetails | READER - primary read path, fetches all bank coordinates by BankID + CurrencyID + optional RegulationID |
| Billing.WireTransferBankDetailsGet | READER - alternate wire bank details lookup |
| Billing.GetWireDepotIdsByRegulationAndCurrency | READER - resolves DepotID by regulation + currency for deposit routing |
| Billing.GetDepotIdByWireTransferBankInfo | READER - point lookup for DepotID by bank info |
| Billing.GetBankIDByRegulation | READER - returns BankID for a regulation |
| Billing.GetCustomerDepositInfo | READER - retrieves bank details for a customer's deposit context |

---

## 5. Technical Details

### 5.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_WireTranferBanks | CLUSTERED PK | ID ASC | Active |

Single clustered PK only. Lookups by BankID+CurrencyID+RegulationID do table scans (87 rows - acceptable for a small config table). PK name has typo "Tranfer" (missing 's').

---

## 6. Sample Query

```sql
-- Get wire transfer bank details for customer deposit instructions
SELECT wti.BankFullName, wti.Beneficiary, wti.BeneficiaryAddress,
       wti.SwiftCode, wti.IBANCode, wti.AccountNumber,
       wti.SortCode, wti.BSB, wti.RoutingNumber,
       wti.BankAddress, wti.BranchName
FROM Billing.WireTransferBankInfo wti WITH (NOLOCK)
INNER JOIN Billing.WireTransferBanks wt WITH (NOLOCK) ON wt.ID = wti.BankID
WHERE wti.BankID = @BankID AND wti.CurrencyID = @CurrencyID
ORDER BY wti.ID
```

---

*Generated: 2026-03-17 | Quality: 8.8/10 | Phases: 9/11 | CODE-BACKED: 18 | Sources: 0*
*Object: Billing.WireTransferBankInfo | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WireTransferBankInfo.sql*
