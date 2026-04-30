# Tribe.SettlementsTransactions_SettlementTransaction-637239

> Primary child table storing detailed settlement transaction records from Tribe, containing amounts, currencies, merchant data, and clearing details.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

SettlementTransaction is the primary data child table for settlement files. Contains settlement/clearing details: amounts in multiple currencies, merchant info, transaction codes, FX rates. Raw Tribe data complement to dbo.FiatTransactionsStatuses for settled transactions. Parent: SettlementsTransactions-333243.

---

## 2. Business Logic

### 2.1 Multi-Currency Settlement Record

Similar column groups to AccountsActivities_AccountActivity: holder, transaction, billing, settlement amounts and currencies, merchant data, fee details.

---

## 3. Data Overview

N/A - raw provider settlement data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @SettlementsTransactions@Id-333243 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

(50+ additional nvarchar(max) columns for settlement details)

---

## 5. Relationships

Parent: SettlementsTransactions-333243.

---

## 6. Dependencies

Depends on: SettlementsTransactions-333243.

---

## 7. Technical Details

Standard Tribe child indexes.

---

## 8. Sample Queries

### 8.1 Recent settlements
```sql
SELECT TOP 10 * FROM Tribe.[SettlementsTransactions_SettlementTransaction-637239] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with parent
```sql
SELECT TOP 5 p.[@FileName], c.* FROM Tribe.[SettlementsTransactions-333243] p WITH (NOLOCK)
JOIN Tribe.[SettlementsTransactions_SettlementTransaction-637239] c WITH (NOLOCK) ON c.[@SettlementsTransactions@Id-333243] = p.[@Id] ORDER BY c.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[SettlementsTransactions_SettlementTransaction-637239] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.SettlementsTransactions_SettlementTransaction-637239 | Type: Table*
