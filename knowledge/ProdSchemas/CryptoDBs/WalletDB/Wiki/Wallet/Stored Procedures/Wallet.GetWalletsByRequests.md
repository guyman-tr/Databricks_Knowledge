# Wallet.GetWalletsByRequests

> Returns the latest wallet creation request status per cryptocurrency for a customer, used by AML, back-office, balance, and conversion services to check wallet provisioning state.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns latest CreateWallet request status per CryptoId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks the wallet creation request status for a customer across specified cryptocurrencies. For each CryptoId in the TVP, it finds the most recent CreateWallet request (RequestTypeId=0) and returns whether it succeeded (StatusId=1) or failed (StatusId=2). Only returns results for cryptos where both a wallet AND a creation request exist.

Four services consume this: AML, back-office API, balance, and conversion - all needing to verify wallet provisioning state before operations.

---

## 2. Business Logic

### 2.1 Latest Request Status Resolution

**What**: Returns the most recent CreateWallet request status per crypto.

**Columns/Parameters Involved**: `@Gcid`, `@CryptoIds`, `Requests.RequestTypeId=0`, `RequestStatuses`

**Rules**:
- ROW_NUMBER() OVER (PARTITION BY CryptoId ORDER BY r.Timestamp DESC, rs.Timestamp DESC)
- Only CreateWallet requests (RequestTypeId=0)
- Status mapping: RequestStatusId=2 -> StatusId=2 (failed), otherwise -> StatusId=1 (success/pending)
- JOINs to CustomerWalletsView to confirm wallet exists

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer ID. |
| 2 | @CryptoIds | Wallet.CryptoIds | NO | - | VERIFIED | TVP of CryptoIds to check. |
| 3 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency checked. |
| 4 | StatusId (output) | int | NO | - | VERIFIED | 1=success/pending, 2=failed. Simplified from request status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid + @CryptoIds | Wallet.CustomerWalletsView | JOIN | Confirms wallet existence |
| @Gcid + RequestTypeId=0 | Wallet.Requests | JOIN | CreateWallet requests |
| RequestId | Wallet.RequestStatuses | JOIN | Latest status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser, BackApiUser, BalanceUser, ConversionUser | - | EXECUTE | Wallet provisioning status check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsByRequests (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Wallet existence check |
| Wallet.Requests | Table | CreateWallet request lookup |
| Wallet.RequestStatuses | Table | Latest request status |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser, BackApiUser, BalanceUser, ConversionUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check wallet creation status
```sql
DECLARE @cryptos Wallet.CryptoIds;
INSERT INTO @cryptos VALUES (1), (19), (107);
EXEC Wallet.GetWalletsByRequests @Gcid = 30351701, @CryptoIds = @cryptos;
```

### 8.2 Direct equivalent
```sql
SELECT CryptoId, CASE RequestStatusId WHEN 2 THEN 2 ELSE 1 END StatusId
FROM (
    SELECT r.CryptoId, rs.RequestStatusId,
        ROW_NUMBER() OVER (PARTITION BY r.CryptoId ORDER BY r.Timestamp DESC, rs.Timestamp DESC) rn
    FROM Wallet.Requests r WITH (NOLOCK)
        JOIN Wallet.RequestStatuses rs WITH (NOLOCK) ON rs.RequestId = r.Id
    WHERE r.RequestTypeId = 0 AND r.Gcid = 30351701 AND r.CryptoId = 1
) x WHERE rn = 1;
```

### 8.3 Check if a specific wallet creation failed
```sql
DECLARE @cryptos Wallet.CryptoIds;
INSERT INTO @cryptos VALUES (107);
EXEC Wallet.GetWalletsByRequests @Gcid = 30351701, @CryptoIds = @cryptos;
-- StatusId=2 means the creation failed
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsByRequests | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsByRequests.sql*
