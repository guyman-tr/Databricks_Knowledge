# Tribe.Lookups_RegionTypes-204382

> Collection for region types. Parent: Lookups-75520. Child: RegionType-404277.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

## 1. Business Meaning

Region types collection. Parent: Lookups. Child: RegionType-404277.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @Lookups@Id-75520 | uniqueidentifier | NO | - | CODE-BACKED | FK. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

## 5-9. Standard Tribe collection. Parent: Lookups-75520. Child: RegionType-404277. No Atlassian sources.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_RegionTypes-204382 | Type: Table*
