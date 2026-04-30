# Wallet.GetTravelRuleAddress

> Retrieves the most recently saved travel rule address information for a specific wallet and destination address combination, including beneficiary details required for FATF travel rule compliance.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns latest TravelRuleAddresses row by WalletId + ToAddress |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the travel rule beneficiary information associated with a specific wallet and destination blockchain address. When a customer sends crypto to an external address, travel rule regulations may require the sender to provide information about the destination (beneficiary name, country, hosting company, etc.). This data is stored in `Wallet.TravelRuleAddresses` and retrieved by this procedure when preparing subsequent sends to the same address.

Three services consume this: the back-office API (reviewing travel rule compliance data), the monitor service (compliance monitoring), and Splunk (audit logging). The procedure returns the most recent record (TOP 1 ORDER BY Id DESC), which handles the case where a customer updates their travel rule information for the same destination.

---

## 2. Business Logic

### 2.1 Most-Recent Record Selection

**What**: Returns only the latest travel rule record for a wallet+address pair.

**Columns/Parameters Involved**: `@WalletId`, `@ToAddress`, `Id`

**Rules**:
- Multiple records may exist for the same WalletId + ToAddress (user updated their info)
- TOP 1 ORDER BY Id DESC selects the most recent entry
- This ensures callers always get the latest beneficiary information

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | The sender's wallet ID. |
| 2 | @ToAddress | nvarchar(512) | NO | - | VERIFIED | The destination blockchain address to look up travel rule data for. |
| 3 | Id (output) | bigint | NO | - | CODE-BACKED | Travel rule address record ID. |
| 4 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Echo of the sender's wallet. |
| 5 | ToAddress (output) | nvarchar(512) | NO | - | CODE-BACKED | Echo of the destination address. |
| 6 | TravelRuleAddressTypeId (output) | tinyint | YES | - | VERIFIED | Type of the destination address (e.g., exchange, self-hosted, personal). FK to Dictionary.TravelRuleAddressTypes. |
| 7 | SelfAccount (output) | bit | YES | - | CODE-BACKED | Whether the destination is the customer's own account on another platform. 1=self, 0=third-party. |
| 8 | HostingCompany (output) | nvarchar | YES | - | CODE-BACKED | Name of the company hosting the destination wallet (e.g., Binance, Coinbase). |
| 9 | Name (output) | nvarchar | YES | - | CODE-BACKED | Beneficiary name as declared by the sender for travel rule compliance. |
| 10 | CountryAlpha3Code (output) | varchar | YES | - | CODE-BACKED | ISO 3166-1 alpha-3 country code of the beneficiary (e.g., USA, GBR, ISR). |
| 11 | State (output) | nvarchar | YES | - | CODE-BACKED | State/province of the beneficiary. |
| 12 | City (output) | nvarchar | YES | - | CODE-BACKED | City of the beneficiary. |
| 13 | Address (output) | nvarchar | YES | - | CODE-BACKED | Physical street address of the beneficiary. |
| 14 | Zipcode (output) | nvarchar | YES | - | CODE-BACKED | Postal/zip code of the beneficiary. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId + @ToAddress | Wallet.TravelRuleAddresses | Lookup | Travel rule beneficiary data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Compliance review |
| MonitorUser | - | EXECUTE | Compliance monitoring |
| SplunkUser | - | EXECUTE | Audit logging |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetTravelRuleAddress (procedure)
+-- Wallet.TravelRuleAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TravelRuleAddresses | Table | Lookup by WalletId + ToAddress |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser | Service Account | EXECUTE grant |
| MonitorUser | Service Account | EXECUTE grant |
| SplunkUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get travel rule info for a wallet-address pair
```sql
EXEC Wallet.GetTravelRuleAddress
    @WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678',
    @ToAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
```

### 8.2 Direct query equivalent
```sql
SELECT TOP 1 Id, WalletId, ToAddress, TravelRuleAddressTypeId, SelfAccount,
    HostingCompany, Name, CountryAlpha3Code, State, City, Address, Zipcode
FROM Wallet.TravelRuleAddresses WITH (NOLOCK)
WHERE WalletId = 'C0D5EF83-...' AND ToAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'
ORDER BY Id DESC;
```

### 8.3 Find all travel rule records for a wallet
```sql
SELECT * FROM Wallet.TravelRuleAddresses WITH (NOLOCK)
WHERE WalletId = 'C0D5EF83-...'
ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetTravelRuleAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetTravelRuleAddress.sql*
