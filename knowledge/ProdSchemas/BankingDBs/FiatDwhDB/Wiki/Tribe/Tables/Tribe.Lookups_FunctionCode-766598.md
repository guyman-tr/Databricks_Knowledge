# Tribe.Lookups_FunctionCode-766598

> Grandchild lookup: individual function code values. Code (@cc) + description (#text). Collection: FunctionCodes-738887.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

---

## 1. Business Meaning

Function code values from Tribe lookups. Defines transaction processing function codes. Grandchild of Lookups-75520 via FunctionCodes-738887.

---

## 2. Business Logic

Code/description pair.

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_FunctionCodes@Id-738887 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Function code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

---

## 5. Relationships

Parent: FunctionCodes-738887 -> Lookups-75520.

---

## 6. Dependencies

Depends on: FunctionCodes-738887.

---

## 7. Technical Details

Standard Tribe lookup indexes and defaults.

---

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc] AS Code, [#text] AS Description FROM Tribe.[Lookups_FunctionCode-766598] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_FunctionCode-766598] WITH (NOLOCK);
```

### 8.3 Join
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_FunctionCodes-738887] col WITH (NOLOCK)
JOIN Tribe.[Lookups_FunctionCode-766598] c WITH (NOLOCK) ON c.[@Lookups_FunctionCodes@Id-738887] = col.[@Id];
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_FunctionCode-766598 | Type: Table*
