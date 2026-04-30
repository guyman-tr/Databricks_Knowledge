# BackOffice.BlockedPayPal

> Legacy registry of blocked PayPal email addresses, preventing deposits from previously flagged PayPal accounts. Dormant since 2011 - contains 1,093 entries dated 2008-2011. Functionality superseded by BackOffice.CustomerBlackList (BlockedDataTypeID=5).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PayPalEmailAccount (VARCHAR(50), CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.BlockedPayPal is a legacy block registry for PayPal email accounts. When a PayPal account was linked to fraud, chargebacks, or terms violations, its email address was added here to block future deposits from that account - even across new customer registrations.

The table contains 1,093 entries. The oldest BlockDate is 1970-01-01 00:00:00 (Unix epoch - indicates null/unknown date at time of data migration), and the newest is 2011-01-14. No entries since 2011. PayPal blocking is now handled by BackOffice.CustomerBlackList (BlockedDataTypeID=5 = Pay Pal Email).

---

## 2. Business Logic

- Billing.BlockPayPalAdd: INSERT PayPalEmailAccount + GETDATE().
- Billing.BlockPayPalRemove: DELETE by PayPalEmailAccount.
- Billing.CheckInBlockedPayPals: Returns @CheckResult=1 if the email is blocked, 0 if not. Called during PayPal deposit processing.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 1,093 |
| Oldest BlockDate | 1970-01-01 (epoch/null - data migration artifact) |
| Newest BlockDate | 2011-01-14 (no entries since) |
| Status | Dormant - legacy table |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PayPalEmailAccount | varchar(50) | NO | - | VERIFIED | PayPal email address of the blocked account. Clustered PK - one row per email. Case-sensitive matching depends on server collation. |
| 2 | BlockDate | datetime | NO | - | VERIFIED | Timestamp when the PayPal account was blocked. Oldest value is 1970-01-01 00:00:00 (Unix epoch, indicates date was NULL or unknown during legacy migration). All real entries pre-date 2012. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No formal FK relationships.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BlockPayPalAdd | PayPalEmailAccount | WRITER | Adds a PayPal email to the block list |
| Billing.BlockPayPalRemove | PayPalEmailAccount | DELETER | Removes a PayPal email from the block list |
| Billing.CheckInBlockedPayPals | PayPalEmailAccount | READER | Deposit gating check - returns 1 if blocked |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BlockedPayPal (table)
- No FK constraints (leaf table)
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BlockPayPalAdd | Procedure | WRITER |
| Billing.BlockPayPalRemove | Procedure | DELETER |
| Billing.CheckInBlockedPayPals | Procedure | READER - deposit gate |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BBLP | CLUSTERED PK | PayPalEmailAccount ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BBLP | PK | PayPalEmailAccount uniqueness |

---

## 8. Sample Queries

### 8.1 Check if a PayPal email is blocked
```sql
SELECT 1 AS IsBlocked
FROM BackOffice.BlockedPayPal WITH (NOLOCK)
WHERE PayPalEmailAccount = @PayPalEmail
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 8.8/10, Logic: 8.7/10, Relationships: 8.7/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 3 analyzed (Billing schema) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BlockedPayPal | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.BlockedPayPal.sql*
