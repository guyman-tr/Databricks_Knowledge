# Tribe.Lookups_RiskAction-588435

> Grandchild lookup: risk action codes. Collection: RiskActions-660937. Defines risk engine action types.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

## 1. Business Meaning

Risk action codes from Tribe. Defines the types of risk actions the system can take (flag, block, reject, etc.).

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_RiskActions@Id-660937 | uniqueidentifier | NO | - | CODE-BACKED | FK. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Risk action code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

## 5-6. Parent: RiskActions-660937.

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc], [#text] FROM Tribe.[Lookups_RiskAction-588435] WITH (NOLOCK) ORDER BY [@cc];
```

## 9. No Atlassian sources.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_RiskAction-588435 | Type: Table*
