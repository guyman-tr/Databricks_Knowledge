# BackOffice.BlockedNeteller

> Legacy registry of blocked Neteller e-wallet account IDs, preventing deposits from previously flagged Neteller accounts. Dormant since 2010 - contains 29 entries, all from 2009-2010.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | AccountID (NUMERIC(12,0), CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.BlockedNeteller is a legacy block registry for Neteller e-wallet accounts. Neteller was a popular e-wallet payment method in eToro's early years. When a Neteller account was linked to fraud or chargebacks, its numeric account ID was added here to prevent future deposits from that account.

The table contains only 29 entries, all from 2009-2010. Neteller blocking functionality has since been absorbed into BackOffice.CustomerBlackList (PayPal Email type covers PayPal; Neteller-specific entries are no longer maintained here). The table is dormant.

---

## 2. Business Logic

- Billing.BlockNetellerAdd: INSERT AccountID + GETDATE().
- Billing.BlockNetellerRemove: DELETE by AccountID.
- No CheckIn procedure found for Neteller (unlike BlockedCard) - suggests Neteller blocking checks may have been removed or done at application level.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 29 |
| Oldest BlockDate | 2009-09-16 |
| Newest BlockDate | 2010-11-05 (no entries since) |
| Status | Dormant - legacy table |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountID | numeric(12,0) | NO | - | VERIFIED | Neteller e-wallet account number. Clustered PK. Numeric(12,0) accommodates Neteller's 12-digit account ID format. |
| 2 | BlockDate | datetime | NO | - | VERIFIED | Timestamp when the Neteller account was added to the block list. All 29 entries are from 2009-2010. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No formal FK relationships.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BlockNetellerAdd | AccountID | WRITER | Adds a Neteller account to the block list |
| Billing.BlockNetellerRemove | AccountID | DELETER | Removes a Neteller account from the block list |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BlockedNeteller (table)
- No FK constraints (leaf table)
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BlockNetellerAdd | Procedure | WRITER |
| Billing.BlockNetellerRemove | Procedure | DELETER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BBLN | CLUSTERED PK | AccountID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BBLN | PK | AccountID uniqueness |

---

## 8. Sample Queries

### 8.1 Check all blocked Neteller accounts
```sql
SELECT AccountID, BlockDate
FROM BackOffice.BlockedNeteller WITH (NOLOCK)
ORDER BY BlockDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.6/10 (Elements: 8.8/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 2 analyzed (Billing schema) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BlockedNeteller | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.BlockedNeteller.sql*
