# Wallet.AddTravelRuleSend

> Links a crypto send operation to its Travel Rule address record, creating an idempotent association between the wallet/correlation pair and the pre-registered beneficiary address.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.TravelRuleSends |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates the link between an outgoing crypto send transaction and its Travel Rule address record. After a Travel Rule address has been registered (via AddTravelRuleAddress) with full beneficiary details, this procedure associates a specific send operation (identified by WalletId + CorrelationId) with that address. This completes the Travel Rule data chain: transaction -> send record -> address -> beneficiary identity.

Without this procedure, the system could not link outgoing transactions to their Travel Rule compliance data, breaking the audit trail required by regulators.

The procedure is idempotent - if a record already exists for the same WalletId + CorrelationId, the INSERT is silently skipped.

---

## 2. Business Logic

### 2.1 Idempotent Send-to-Address Linking

**What**: Prevents duplicate send-to-address associations.

**Columns/Parameters Involved**: `@WalletId`, `@CorrelationId`

**Rules**:
- Uses WHERE NOT EXISTS matching on WalletId + CorrelationId
- If a duplicate exists, silently skips (no error)
- TravelRuleAddressId links to the pre-registered address with full beneficiary details

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | The sender's wallet ID. Identifies which customer wallet is performing the send. |
| 2 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Correlation ID of the send transaction. Together with WalletId, uniquely identifies this send operation. |
| 3 | @TravelRuleAddressId | bigint | NO | - | CODE-BACKED | The Travel Rule address record to link to. Obtained from Wallet.AddTravelRuleAddress's return value. Contains the beneficiary's identity and geographic information. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TravelRuleAddressId | Wallet.TravelRuleAddresses | FK | Links to the beneficiary address record |
| INSERT target | Wallet.TravelRuleSends | Writer | Creates the send-to-address link |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application compliance services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddTravelRuleSend (procedure)
  └── Wallet.TravelRuleSends (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TravelRuleSends | Table | INSERT target + duplicate check |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Duplicate prevention via WHERE NOT EXISTS pattern.

---

## 8. Sample Queries

### 8.1 View Travel Rule sends for a wallet
```sql
SELECT trs.Id, trs.WalletId, trs.CorrelationId, trs.TravelRuleAddressId,
       tra.ToAddress, tra.HostingCompany, tra.Name
FROM Wallet.TravelRuleSends trs WITH (NOLOCK)
JOIN Wallet.TravelRuleAddresses tra WITH (NOLOCK) ON tra.Id = trs.TravelRuleAddressId
WHERE trs.WalletId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
ORDER BY trs.Id DESC
```

### 8.2 Find a send by correlation ID
```sql
SELECT trs.Id, trs.WalletId, tra.ToAddress, tra.HostingCompany, tra.Name, tra.CountryAlpha3Code
FROM Wallet.TravelRuleSends trs WITH (NOLOCK)
JOIN Wallet.TravelRuleAddresses tra WITH (NOLOCK) ON tra.Id = trs.TravelRuleAddressId
WHERE trs.CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

### 8.3 Recent Travel Rule sends with address details
```sql
SELECT TOP 20 trs.Id, trs.WalletId, tra.ToAddress, tra.SelfAccount, tra.HostingCompany, trs.Created
FROM Wallet.TravelRuleSends trs WITH (NOLOCK)
JOIN Wallet.TravelRuleAddresses tra WITH (NOLOCK) ON tra.Id = trs.TravelRuleAddressId
ORDER BY trs.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddTravelRuleSend | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddTravelRuleSend.sql*
