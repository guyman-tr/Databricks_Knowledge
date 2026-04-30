# Wallet.GetPromotionIdByName

> Stored procedure that looks up a promotion tag ID by its name and cryptocurrency.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns PromotionTags.Id |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetPromotionIdByName resolves a promotion tag's internal ID from its name and associated cryptocurrency. Promotion tags are used to mark wallet operations (sends, receives, conversions) that are part of a promotional campaign or special offer. The application uses this procedure to resolve the tag by name before associating it with a transaction.

---

## 2. Business Logic

No complex business logic. Simple SELECT of Id from Wallet.PromotionTags WHERE Name = @PromotionName AND CryptoId = @CryptoId.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PromotionName | nvarchar(30) | NO | - | CODE-BACKED | Name of the promotion tag to look up. Must match Wallet.PromotionTags.Name exactly. |
| 2 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency ID (FK to Wallet.CryptoTypes). Promotions are crypto-specific. |
| 3 | Id (result) | int | YES | - | CODE-BACKED | The promotion tag ID if found, or empty result set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PromotionName, @CryptoId | Wallet.PromotionTags | FROM | Name + crypto lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Promotion services | - | EXEC | Tag resolution before transaction tagging |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPromotionIdByName (procedure)
+-- Wallet.PromotionTags (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.PromotionTags | Table | FROM - name + crypto lookup |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up a promotion by name for BTC
```sql
EXEC Wallet.GetPromotionIdByName @PromotionName = 'Welcome', @CryptoId = 1
```

### 8.2 List all promotion tags
```sql
SELECT Id, Name, CryptoId FROM Wallet.PromotionTags WITH (NOLOCK) ORDER BY CryptoId, Name
```

### 8.3 Find promotions with crypto names
```sql
SELECT pt.Id, pt.Name, ct.Name AS CryptoName
FROM Wallet.PromotionTags pt WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoId = pt.CryptoId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPromotionIdByName | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPromotionIdByName.sql*
