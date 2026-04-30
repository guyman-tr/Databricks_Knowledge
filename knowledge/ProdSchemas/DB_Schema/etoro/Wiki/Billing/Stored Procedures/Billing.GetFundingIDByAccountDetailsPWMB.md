# Billing.GetFundingIDByAccountDetailsPWMB

> Looks up the FundingID for a PWMB (FundingTypeID=32) bank account by matching bank name and masked account digits for a specific customer with Active status.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BankName + @BankLast4Digits + @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

PWMB (FundingTypeID=32) is a specific bank/payment provider. When processing a PWMB-related operation, the system needs to locate the customer's existing PWMB funding record using partial account identifiers - the bank name and the masked (last 4 digits) account number. This avoids requiring full account details while still uniquely identifying the customer's bank account.

The procedure filters to CustomerFundingStatusID=1 (Active fundings only), ensuring only usable funding records are returned - not pending, rejected, or deactivated accounts.

"PWMB" likely refers to a specific payment wallet or money broker integrated into eToro's payment ecosystem (the precise abbreviation is not documented in the DDL).

---

## 2. Business Logic

### 2.1 PWMB-Specific Lookup

**What**: Matches by BankNameAsString and MaskedAccountIDAsString from the FundingData XML.

**Rules**:
- `FundingTypeID = 32` - PWMB-only search
- `FundingData.value('/Funding[1]/BankNameAsString[1]', 'VARCHAR(MAX)') = @BankName` - exact bank name match
- `FundingData.value('/Funding[1]/MaskedAccountIDAsString[1]', 'VARCHAR(MAX)') = @BankLast4Digits` - last 4 digits match
- `CustomerFundingStatusID = 1` - Active fundings only (not pending or deactivated)
- All conditions must be satisfied simultaneously

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BankName | VARCHAR(50) | NO | - | CODE-BACKED | The PWMB bank or institution name. Matched against FundingData XML BankNameAsString. Must be an exact string match. |
| 2 | @BankLast4Digits | VARCHAR(10) | NO | - | CODE-BACKED | Masked/last 4 digits of the bank account number. Matched against FundingData XML MaskedAccountIDAsString. Used instead of full account number for security. |
| 3 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Matched against Billing.CustomerToFunding.CID. Only fundings belonging to this customer are searched. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingID | INT | NO | - | CODE-BACKED | Primary key of the matched Billing.Funding record (FundingTypeID=32, PWMB). |
| R2 | FundingData | XML | YES | NULL | CODE-BACKED | Full XML content of the matched funding record. Returned so the caller can extract additional PWMB-specific details beyond the search criteria. |
| R3 | CID | INT | NO | - | CODE-BACKED | Customer ID from the CustomerToFunding record. Should match @CID; confirms ownership. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID=32 + XML fields | Billing.Funding | JOIN | PWMB fundings matching BankName + MaskedAccountID |
| @CID + CustomerFundingStatusID=1 | Billing.CustomerToFunding | JOIN | Active funding links for this customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application PWMB payment service | @BankName + @BankLast4Digits + @CID | EXEC | PWMB funding lookup before processing operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingIDByAccountDetailsPWMB (procedure)
├── Billing.Funding (table)
└── Billing.CustomerToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | INNER JOIN - FundingTypeID=32, XML field matching |
| Billing.CustomerToFunding | Table | INNER JOIN - CID filter + CustomerFundingStatusID=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from PWMB payment service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up a PWMB funding by bank name and last 4 digits

```sql
EXEC Billing.GetFundingIDByAccountDetailsPWMB
    @BankName = 'Example Bank',
    @BankLast4Digits = '1234',
    @CID = 1234567;
```

### 8.2 Find all PWMB fundings for a customer

```sql
SELECT f.FundingID,
    f.FundingData.value('/Funding[1]/BankNameAsString[1]', 'VARCHAR(MAX)') AS BankName,
    f.FundingData.value('/Funding[1]/MaskedAccountIDAsString[1]', 'VARCHAR(MAX)') AS MaskedAccount
FROM Billing.Funding f WITH (NOLOCK)
INNER JOIN Billing.CustomerToFunding ctf WITH (NOLOCK) ON f.FundingID = ctf.FundingID
WHERE f.FundingTypeID = 32 AND ctf.CID = 1234567
  AND ctf.CustomerFundingStatusID = 1;
```

### 8.3 Check all PWMB fundings in the system

```sql
SELECT COUNT(*) AS TotalPWMB
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingTypeID = 32;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingIDByAccountDetailsPWMB | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingIDByAccountDetailsPWMB.sql*
