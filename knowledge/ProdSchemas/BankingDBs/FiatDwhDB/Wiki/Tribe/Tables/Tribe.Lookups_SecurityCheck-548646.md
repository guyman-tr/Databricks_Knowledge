# Tribe.Lookups_SecurityCheck-548646

> Grandchild lookup: security check codes. Collection: SecurityChecks-380020. Defines security validation types.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

## 1. Business Meaning

Security check codes from Tribe. Defines security validation types (3DS, AVS, CVV, etc.).

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_SecurityChecks@Id-380020 | uniqueidentifier | NO | - | CODE-BACKED | FK. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Security check code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

## 5-6. Parent: SecurityChecks-380020.

## 8. Sample: `SELECT [@cc], [#text] FROM Tribe.[Lookups_SecurityCheck-548646] WITH (NOLOCK);`

## 9. No Atlassian sources.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_SecurityCheck-548646 | Type: Table*
