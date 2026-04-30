# Tribe.Lookups_RegionType-404277

> Grandchild lookup: region type codes. Collection: RegionTypes-204382. Defines geographic region types.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

## 1. Business Meaning

Region type codes from Tribe. Grandchild of Lookups via RegionTypes.

## 2-3. Code/description pair. N/A for data overview.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_RegionTypes@Id-204382 | uniqueidentifier | NO | - | CODE-BACKED | FK. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Region type code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

## 5-6. Parent: RegionTypes-204382. Depends on: RegionTypes-204382.

## 7-9. Standard indexes. Sample: `SELECT [@cc], [#text] FROM Tribe.[Lookups_RegionType-404277] WITH (NOLOCK)`. No Atlassian sources.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_RegionType-404277 | Type: Table*
