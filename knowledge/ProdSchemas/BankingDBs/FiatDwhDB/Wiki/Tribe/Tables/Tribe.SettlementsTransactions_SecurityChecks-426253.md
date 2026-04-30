# Tribe.SettlementsTransactions_SecurityChecks-426253

> Child table storing security check records from Tribe settlement transaction files. Parent: SettlementsTransactions-333243.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

## 1. Business Meaning

Security checks from settlement processing. Parent: SettlementsTransactions-333243.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @SettlementsTransactions@Id-333243 | uniqueidentifier | NO | - | CODE-BACKED | FK. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

## 5-9. Parent: SettlementsTransactions-333243. Standard child pattern.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.SettlementsTransactions_SecurityChecks-426253 | Type: Table*
