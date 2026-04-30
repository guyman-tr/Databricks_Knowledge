# Tribe.Lookups_TransactionCode-321545

> Grandchild lookup: transaction code values. Collection: TransactionCodes-305974. Defines transaction type codes used in Tribe activity records.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

## 1. Business Meaning

Transaction codes from Tribe. Referenced by AccountsActivities_AccountActivity TransactionCode column.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_TransactionCodes@Id-305974 | uniqueidentifier | NO | - | CODE-BACKED | FK. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Transaction code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

## 5-6. Parent: TransactionCodes-305974.

## 8. Sample: `SELECT [@cc], [#text] FROM Tribe.[Lookups_TransactionCode-321545] WITH (NOLOCK);`

## 9. No Atlassian sources.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_TransactionCode-321545 | Type: Table*
