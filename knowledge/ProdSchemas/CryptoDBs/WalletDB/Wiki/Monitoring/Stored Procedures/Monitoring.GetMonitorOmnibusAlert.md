# Monitoring.GetMonitorOmnibusAlert

> Retrieves omnibus wallet alert data from the pre-computed dbo.Monitor_Omnibus_Alert table, providing a snapshot of platform-level wallet balances organized by wallet type and crypto.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns omnibus wallet monitoring data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetMonitorOmnibusAlert is a simple wrapper that reads from the pre-computed dbo.Monitor_Omnibus_Alert table. Omnibus wallets (Gcid=0) are platform-level wallets that hold pooled customer funds. Monitoring their balances is critical for ensuring the platform has sufficient liquidity to process customer transactions.

Without this procedure, monitoring tools would need to query the complex wallet balance tables directly. The pre-computed table simplifies access and ensures consistent monitoring data.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This procedure is a direct read from a pre-computed monitoring table ordered by WalletTypeId and CryptoId.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OmnibusType | NVARCHAR | YES | - | NAME-INFERRED | Type classification of the omnibus wallet. |
| 2 | Address | NVARCHAR | YES | - | NAME-INFERRED | Blockchain address of the omnibus wallet. |
| 3 | Id | INT | NO | - | CODE-BACKED | Wallet identifier. |
| 4 | CryptoID | INT | NO | - | CODE-BACKED | Cryptocurrency identifier. |
| 5 | CryptoName | NVARCHAR | YES | - | NAME-INFERRED | Human-readable crypto name. |
| 6 | Balance | DECIMAL | YES | - | CODE-BACKED | Current balance in the omnibus wallet for this crypto. |
| 7 | LastUpdated | DATETIME | YES | - | CODE-BACKED | When the balance was last computed/updated. |
| 8 | WalletTypeId | INT | NO | - | CODE-BACKED | Type of wallet (e.g., Redeem, Customer). Determines ordering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | dbo.Monitor_Omnibus_Alert | FROM (read) | Pre-computed omnibus monitoring data |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetMonitorOmnibusAlert (procedure)
  └── dbo.Monitor_Omnibus_Alert (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Monitor_Omnibus_Alert | Table | FROM - pre-computed monitoring data |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run the alert check
```sql
EXEC Monitoring.GetMonitorOmnibusAlert;
```

### 8.2 Check the raw monitoring table
```sql
SELECT * FROM dbo.Monitor_Omnibus_Alert WITH (NOLOCK) ORDER BY WalletTypeId, CryptoId;
```

### 8.3 Find wallets with low balances
```sql
SELECT * FROM dbo.Monitor_Omnibus_Alert WITH (NOLOCK)
WHERE Balance < 1 ORDER BY WalletTypeId, CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 8/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetMonitorOmnibusAlert | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetMonitorOmnibusAlert.sql*
