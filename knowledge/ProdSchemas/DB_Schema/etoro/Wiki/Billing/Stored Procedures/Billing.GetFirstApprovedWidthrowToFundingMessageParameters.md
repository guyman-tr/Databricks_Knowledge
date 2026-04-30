# Billing.GetFirstApprovedWidthrowToFundingMessageParameters

> Retrieves message parameters (payment method name, country, and bank name) for a specific WithdrawToFunding record, used to compose outbound withdrawal approval notification messages.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WtfID (WithdrawToFunding.ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a withdrawal (cashout) is linked to a specific funding method and approved for processing, the system sends a notification message to the customer. This procedure retrieves the human-readable parameters needed to compose that message: the payment method name (Mop = Method of Payment), the country name, and the bank name.

The procedure is specifically designed for the withdrawal-to-funding notification flow introduced in PAYIL-5322. It handles the complexity of resolving a human-readable bank name across three funding type scenarios:
- Credit cards (FundingTypeID=1): bank name comes from Dictionary.CountryBin.IssuingBank (card issuer from BIN lookup)
- FundingTypeID=22: bank name is NULL (not applicable for this payment type)
- All other types: bank name comes from the BankNameAsString field in the funding XML

Country resolution is also funding-type-aware: for credit cards (FundingTypeID=3), country comes from the deposit's payment data XML; for others, it falls back to CountryBin or the customer's country.

Note: "Widthrow" in the name is a spelling error in the original implementation ("Withdraw" is the correct form).

---

## 2. Business Logic

### 2.1 Bank Name Resolution by Funding Type

**What**: Different funding types require different logic to produce a displayable bank name.

**Columns/Parameters Involved**: `BankName`, `FundingTypeID`

**Rules**:
- FundingTypeID=1 (Credit card): `BankName = Dictionary.CountryBin.IssuingBank` (the bank that issued the card, identified from the card's BIN code)
- FundingTypeID=22: `BankName = NULL` (payment method has no meaningful bank name)
- All other types: `BankName = FundingData.value('Funding[1]/BankNameAsString[1]', 'VarChar(Max)')` (explicitly provided in the XML)

**Diagram**:
```
CASE F.FundingTypeID
  WHEN 1  -> CountryBin.IssuingBank (card issuer from BIN code)
  WHEN 22 -> NULL
  ELSE    -> FundingData XML BankNameAsString
END AS BankName
```

### 2.2 Country Resolution

**What**: Resolves the payment country from multiple possible sources.

**Columns/Parameters Involved**: `MopCountry`

**Rules**:
- For FundingTypeID=3 (another credit card type) AND deposit CountryIDAsString > 0: use the country from the deposit's PaymentData XML
- Otherwise: use COALESCE(CountryBin.CountryID, @CustomerCountryID) - fall back to card BIN country, then customer's registered country
- The resolved CountryID must be > 0 (valid country)
- Result: Dictionary.Country.Name aliased as MopCountry

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WtfID | INT | NO | - | CODE-BACKED | Primary key of Billing.WithdrawToFunding (WithdrawToFunding.ID). Identifies the specific withdrawal-to-funding record for which message parameters are needed. |
| 2 | @CustomerCountryID | INT | NO | - | CODE-BACKED | Customer's registered country ID. Used as the final fallback when country cannot be determined from the funding data or card BIN. Lookup: Dictionary.Country. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | Mop | VARCHAR | YES | NULL | CODE-BACKED | Method of Payment name. Dictionary.FundingType.Name for the funding type associated with this withdrawal. Human-readable payment method label for the notification message (e.g., "Credit Card", "Wire Transfer"). |
| R2 | MopCountry | NVARCHAR | YES | NULL | CODE-BACKED | Human-readable country name. Resolved from deposit payment data XML (FundingTypeID=3), card BIN country, or customer country. Dictionary.Country.Name. Used in the notification to indicate payment country. |
| R3 | BankName | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Bank or card issuer name. For credit cards (FundingTypeID=1): CountryBin.IssuingBank. For FundingTypeID=22: NULL. For others: FundingData XML BankNameAsString. Included in notification to identify the specific financial institution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WtfID | Billing.WithdrawToFunding | JOIN | Primary lookup - the withdrawal-to-funding record |
| FundingID | Billing.Funding | JOIN (via CTE) | Funding details and XML data |
| FundingTypeID | Dictionary.FundingType | JOIN | Mop (payment method name) |
| BinCodeAsString (from XML) | Dictionary.CountryBin | LEFT JOIN | Card BIN -> IssuingBank + CountryID |
| FundingID (first deposit) | Billing.Deposit | OUTER APPLY TOP 1 | First deposit for this funding (earliest DepositID) |
| Resolved CountryID | Dictionary.Country | LEFT JOIN | MopCountry (country name) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application withdrawal notification service | @WtfID | EXEC | Called when composing approval notification messages for processed withdrawals |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFirstApprovedWidthrowToFundingMessageParameters (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
├── Dictionary.CountryBin (table)
├── Billing.Deposit (table)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Main JOIN on ID = @WtfID |
| Billing.Funding | Table | FundingData XML + FundingTypeID (via CTE FundingData) |
| Dictionary.FundingType | Table | FundingType.Name -> Mop column |
| Dictionary.CountryBin | Table | LEFT JOIN on BinCodeAsString -> IssuingBank + CountryID |
| Billing.Deposit | Table | OUTER APPLY TOP 1 to get first deposit (earliest DepositID) for the funding |
| Dictionary.Country | Table | LEFT JOIN on resolved CountryID -> Country.Name (MopCountry) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from withdrawal notification service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get message parameters for a specific withdrawal-to-funding

```sql
EXEC Billing.GetFirstApprovedWidthrowToFundingMessageParameters
    @WtfID = 98765,
    @CustomerCountryID = 103;
```

### 8.2 Check the WithdrawToFunding record directly

```sql
SELECT wtf.ID, wtf.WithdrawID, wtf.FundingID, wtf.CashoutStatusID,
       ft.Name AS FundingTypeName
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
INNER JOIN Billing.Funding f WITH (NOLOCK) ON wtf.FundingID = f.FundingID
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK) ON f.FundingTypeID = ft.FundingTypeID
WHERE wtf.ID = 98765;
```

### 8.3 Inspect CountryBin for a BIN code

```sql
SELECT BinCode, IssuingBank, CountryID
FROM Dictionary.CountryBin WITH (NOLOCK)
WHERE BinCode = '411111';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFirstApprovedWidthrowToFundingMessageParameters | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFirstApprovedWidthrowToFundingMessageParameters.sql*
