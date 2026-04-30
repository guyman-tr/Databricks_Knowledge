# Wallet.AddTravelRuleAddress

> Registers a Travel Rule beneficiary address with full identity and geographic details, returning the existing or newly created address ID for idempotent processing.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TravelRuleAddresses.Id (new or existing) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure stores beneficiary address details required by the Travel Rule. When a customer sends crypto to an address, the system must record who controls that address: whether it is a self-owned account or belongs to a third party, the hosting company (VASP), the beneficiary's name, and their geographic location. This information is exchanged with the counterparty VASP as part of Travel Rule compliance.

Without this procedure, eToro could not collect and store the beneficiary identification data mandated by the Travel Rule, blocking compliant crypto transfers.

The procedure is idempotent - it matches on all fields (WalletId + ToAddress + AddressTypeId + SelfAccount + HostingCompany + Name + Country + State + City + Address + Zipcode) using ISNULL for nullable fields. If an exact match exists, it returns the existing ID. If no match, it inserts and returns the new ID via SCOPE_IDENTITY().

---

## 2. Business Logic

### 2.1 Full-Field Idempotent Upsert

**What**: Prevents duplicate entries by matching ALL address and identity fields.

**Columns/Parameters Involved**: All 11 parameters

**Rules**:
- Uses WHERE NOT EXISTS with exact match on every field
- ISNULL wrappers handle NULL-to-NULL equality for optional fields (HostingCompany, Name, CountryAlpha3Code, State, City, Address, Zipcode)
- If INSERT produces @@ROWCOUNT = 1, returns SCOPE_IDENTITY()
- If INSERT produces @@ROWCOUNT = 0 (duplicate), queries for the existing record and returns its Id (TOP 1 ORDER BY Id DESC)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | The sender's wallet ID. Links this Travel Rule address to a specific customer wallet. |
| 2 | @ToAddress | nvarchar(512) | NO | - | CODE-BACKED | The destination blockchain address. The actual on-chain address the crypto is being sent to. |
| 3 | @TravelRuleAddressTypeId | tinyint | NO | - | CODE-BACKED | Classification of the address type for Travel Rule purposes (e.g., hosted/custodial, unhosted/non-custodial). Determines the compliance workflow. |
| 4 | @SelfAccount | bit | NO | - | CODE-BACKED | Whether the destination is the sender's own account at another VASP. 1 = self-transfer (simplified compliance), 0 = third-party transfer (full Travel Rule data required). |
| 5 | @HostingCompany | varchar(255) | NO | - | CODE-BACKED | Name of the VASP or hosting company controlling the destination address (e.g., "Coinbase", "Binance"). Empty string if unhosted wallet. |
| 6 | @Name | nvarchar(255) | NO | - | CODE-BACKED | Full name of the beneficiary (person or entity receiving the funds). Required by Travel Rule for third-party transfers. |
| 7 | @CountryAlpha3Code | varchar(3) | NO | - | CODE-BACKED | ISO 3166-1 alpha-3 country code of the beneficiary (e.g., "USA", "GBR", "DEU"). Used for sanctions screening and jurisdiction determination. |
| 8 | @State | varchar(255) | NO | - | CODE-BACKED | State/province of the beneficiary. May be empty string for countries without states. |
| 9 | @City | nvarchar(255) | NO | - | CODE-BACKED | City of the beneficiary. |
| 10 | @Address | nvarchar(255) | NO | - | CODE-BACKED | Street address of the beneficiary. May be empty string if not collected. |
| 11 | @Zipcode | nvarchar(20) | NO | - | CODE-BACKED | Postal/zip code of the beneficiary. May be empty string. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | Wallet.TravelRuleAddresses | Writer | Creates Travel Rule address record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddTravelRuleSend | @TravelRuleAddressId | Consumer | Uses the returned ID to link a send to this address |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddTravelRuleAddress (procedure)
  └── Wallet.TravelRuleAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TravelRuleAddresses | Table | INSERT target + duplicate check + lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddTravelRuleSend | Stored Procedure | Consumes the returned address ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- No explicit error handling (no TRY/CATCH)
- SCOPE_IDENTITY() used for new inserts
- Falls back to SELECT TOP 1 ORDER BY Id DESC for existing records

---

## 8. Sample Queries

### 8.1 View Travel Rule addresses for a wallet
```sql
SELECT Id, ToAddress, TravelRuleAddressTypeId, SelfAccount, HostingCompany, Name, CountryAlpha3Code
FROM Wallet.TravelRuleAddresses WITH (NOLOCK)
WHERE WalletId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
ORDER BY Id DESC
```

### 8.2 Find addresses by hosting company
```sql
SELECT Id, WalletId, ToAddress, Name, HostingCompany, CountryAlpha3Code
FROM Wallet.TravelRuleAddresses WITH (NOLOCK)
WHERE HostingCompany = 'Coinbase'
ORDER BY Id DESC
```

### 8.3 Self-transfer vs third-party breakdown
```sql
SELECT SelfAccount, COUNT(*) AS Cnt
FROM Wallet.TravelRuleAddresses WITH (NOLOCK)
GROUP BY SelfAccount
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddTravelRuleAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddTravelRuleAddress.sql*
