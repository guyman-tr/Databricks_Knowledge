# Tribe.Lookups_ExternalPaymentTransactionType-741187

> Grandchild lookup: individual external payment transaction type code values. Code (@cc) + description (#text). Collection parent: ExternalPaymentTransactionTypes-463228.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

---

## 1. Business Meaning

External payment transaction type codes from Tribe. Defines types of external payment transactions (SEPA credit, direct debit, Faster Payments, etc.).

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
| 2 | @Lookups_ExternalPaymentTransactionTypes@Id-463228 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Type code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

---

## 5. Relationships

Parent: ExternalPaymentTransactionTypes-463228 -> Lookups-75520.

---

## 6. Dependencies

Depends on: ExternalPaymentTransactionTypes-463228.

---

## 7. Technical Details

Standard Tribe lookup indexes and defaults.

---

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc] AS Code, [#text] AS Description FROM Tribe.[Lookups_ExternalPaymentTransactionType-741187] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_ExternalPaymentTransactionType-741187] WITH (NOLOCK);
```

### 8.3 Join
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_ExternalPaymentTransactionTypes-463228] col WITH (NOLOCK)
JOIN Tribe.[Lookups_ExternalPaymentTransactionType-741187] c WITH (NOLOCK) ON c.[@Lookups_ExternalPaymentTransactionTypes@Id-463228] = col.[@Id];
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_ExternalPaymentTransactionType-741187 | Type: Table*
