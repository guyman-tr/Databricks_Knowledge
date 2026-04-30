# Tribe.Lookups_ExternalPaymentTransactionStatusCode-856121

> Grandchild lookup: individual external payment transaction status code values. Code (@cc) + description (#text). Collection parent: Lookups_ExternalPaymentTransactionStatusCodes-713603.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

---

## 1. Business Meaning

External payment transaction status code values from Tribe lookups. Defines the possible statuses for external payment transactions (SEPA, Faster Payments, etc.) in Tribe's system.

---

## 2. Business Logic

Code/description pair for external payment transaction statuses.

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_ExternalPaymentTransactionStatusCodes@Id-713603 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Status code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

---

## 5. Relationships

Parent: Lookups_ExternalPaymentTransactionStatusCodes-713603.

---

## 6. Dependencies

Depends on: Lookups_ExternalPaymentTransactionStatusCodes-713603 -> Lookups-75520.

---

## 7. Technical Details

Standard Tribe lookup indexes and defaults.

---

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc] AS Code, [#text] AS Description FROM Tribe.[Lookups_ExternalPaymentTransactionStatusCode-856121] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_ExternalPaymentTransactionStatusCode-856121] WITH (NOLOCK);
```

### 8.3 Join
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_ExternalPaymentTransactionStatusCodes-713603] col WITH (NOLOCK)
JOIN Tribe.[Lookups_ExternalPaymentTransactionStatusCode-856121] c WITH (NOLOCK) ON c.[@Lookups_ExternalPaymentTransactionStatusCodes@Id-713603] = col.[@Id];
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_ExternalPaymentTransactionStatusCode-856121 | Type: Table*
