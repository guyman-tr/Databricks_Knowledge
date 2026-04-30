# Wallet.PromotionTags

> Defines promotional campaigns tied to specific cryptocurrencies, storing the bonus amount awarded to wallets participating in promotions. Uses temporal versioning for campaign history tracking.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |
| **Temporal** | Yes - SYSTEM_VERSIONING with history table dbo.PromotionTags |

---

## 1. Business Meaning

This table defines promotional campaigns where users receive bonus cryptocurrency amounts. Each promotion is tied to a specific crypto and identified by a unique name. When a promotion is active, the system awards the specified `Amount` of that crypto to qualifying wallets. Currently only 1 promotion exists: a "web-summit" campaign from November 2018 that awarded 0.1 ETH.

The table uses temporal versioning to track the full history of promotion configuration changes, enabling auditing of when promotion amounts or parameters were modified.

Rows are inserted by operations/marketing when new campaigns are launched. The `AddPromotionToWallets` procedure applies promotions to qualifying wallets. The unique constraint on (CryptoId, Name) prevents duplicate promotions for the same crypto.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| Id | CryptoId | Name | Description | Amount | Meaning |
|---|---|---|---|---|---|
| 1 | 2 (ETH) | web-summit | web summit Nov 2018 | 0.1 | Marketing promotion tied to the Web Summit 2018 conference. Qualifying users received 0.1 ETH as a bonus. The only promotion ever configured. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency this promotion awards. FK to Wallet.CryptoTypes.CryptoID. Combined with Name for unique constraint. |
| 3 | Name | varchar(100) | NO | - | CODE-BACKED | Unique promotion identifier within a crypto (e.g., "web-summit"). Used as lookup key by Wallet.GetPromotionIdByName. |
| 4 | Description | varchar(100) | YES | - | CODE-BACKED | Human-readable description of the promotion campaign. |
| 5 | Amount | decimal(36,18) | NO | - | CODE-BACKED | The amount of crypto awarded to each qualifying wallet. Expressed in the crypto's native units (e.g., 0.1 ETH). |
| 6 | BeginDate | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioned temporal column (ROW START). Tracks when this promotion version became active. |
| 7 | EndDate | datetime2(7) | NO | 9999-12-31... | CODE-BACKED | System-versioned temporal column (ROW END). Default value indicates the promotion is currently active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Identifies which crypto the promotion awards |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddPromotionToWallets | - | Reader | Reads promotion details to apply to wallets |
| Wallet.GetPromotionIdByName | - | Reader | Looks up promotion by name |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.PromotionTags (table)
└── Wallet.CryptoTypes (table)
      └── Wallet.BlockchainCryptos (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddPromotionToWallets | Stored Procedure | Applies promotions to wallets |
| Wallet.GetPromotionIdByName | Stored Procedure | Looks up promotion by name |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PromotionTags | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_PromotionTags__CryptoId_Name | NC UNIQUE | CryptoId ASC, Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_PromotionTags__BeginDate | DEFAULT | getutcdate() |
| FK_...CryptoId__Wallet_CryptoTypes_Id | FK | CryptoId -> Wallet.CryptoTypes.CryptoID |

---

## 8. Sample Queries

### 8.1 List all promotions
```sql
SELECT pt.Id, ct.Name AS Crypto, pt.Name AS PromotionName, pt.Amount, pt.Description
FROM Wallet.PromotionTags pt WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON pt.CryptoId = ct.CryptoID
```

### 8.2 Find promotion by name
```sql
SELECT Id, CryptoId, Amount FROM Wallet.PromotionTags WITH (NOLOCK) WHERE Name = 'web-summit'
```

### 8.3 View promotion history (temporal query)
```sql
SELECT Id, Name, Amount, BeginDate, EndDate
FROM Wallet.PromotionTags FOR SYSTEM_TIME ALL
ORDER BY BeginDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.PromotionTags | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.PromotionTags.sql*
