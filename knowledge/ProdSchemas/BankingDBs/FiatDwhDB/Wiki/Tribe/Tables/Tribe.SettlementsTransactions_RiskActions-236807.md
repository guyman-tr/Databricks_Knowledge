# Tribe.SettlementsTransactions_RiskActions-236807

> Child table storing risk action records from Tribe settlement transaction files. Parent: SettlementsTransactions-333243.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Risk actions from settlement transaction processing. Same pattern as AccountsActivities/Authorizes RiskActions tables. Parent: SettlementsTransactions-333243.

---

## 2. Business Logic

No complex logic. Raw risk action data from settlement processing.

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @SettlementsTransactions@Id-333243 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

Parent: SettlementsTransactions-333243.

---

## 6. Dependencies

Depends on: SettlementsTransactions-333243.

---

## 7. Technical Details

Standard Tribe child indexes and defaults.

---

## 8. Sample Queries

### 8.1 Recent
```sql
SELECT TOP 10 * FROM Tribe.[SettlementsTransactions_RiskActions-236807] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join
```sql
SELECT p.[@FileName], c.* FROM Tribe.[SettlementsTransactions-333243] p WITH (NOLOCK)
JOIN Tribe.[SettlementsTransactions_RiskActions-236807] c WITH (NOLOCK) ON c.[@SettlementsTransactions@Id-333243] = p.[@Id] ORDER BY c.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[SettlementsTransactions_RiskActions-236807] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.SettlementsTransactions_RiskActions-236807 | Type: Table*
