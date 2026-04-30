# BackOffice.BlockedCard

> Legacy registry of blocked credit/debit card hashes, preventing deposits from previously flagged cards. Dormant since 2011 - functionality superseded by BackOffice.CustomerBlackList (BlockedDataTypeID=4).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CardHash (VARCHAR(50), CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.BlockedCard is a PCI-DSS-compliant registry of blocked payment cards, identified by their hashed card numbers (not the raw PAN). When a card was used for fraud, chargebacks, or abuse, its hash was added here to prevent future deposits using the same card - even from a new account.

The table contains 4,240 entries, all dated 2008-2011. No entries have been added since January 2011. The card blocking functionality was migrated to BackOffice.CustomerBlackList (BlockedDataTypeID=4 = Credit Card), which became the consolidated block registry. The table remains in place for historical reference and because Billing.CheckInBlockedCards still queries it.

**PCI note**: Storing a card hash rather than the actual card number is PCI-DSS compliant - the hash identifies the card without storing sensitive PAN data.

---

## 2. Business Logic

### 2.1 Hash-Based Card Blocking

**Rules**:
- Billing.BlockCardAdd: INSERT a new CardHash + GETDATE() as BlockDate.
- Billing.BlockCardRemove: DELETE by CardHash.
- Billing.CheckInBlockedCards: Returns @CheckResult=1 if the hash exists, 0 if not. Called during deposit processing to block flagged cards.
- CardHash is the PK - one row per unique card hash. Duplicate inserts would fail.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 4,240 |
| Oldest BlockDate | 2008-02-10 |
| Newest BlockDate | 2011-01-14 (no entries since) |
| Status | Dormant - legacy table |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CardHash | varchar(50) | NO | - | VERIFIED | Hashed representation of the blocked credit/debit card PAN. Clustered PK - one row per unique card hash. PCI-DSS compliant (no raw card number stored). |
| 2 | BlockDate | datetime | NO | - | VERIFIED | Timestamp when the card was added to the block list. Set to GETDATE() by Billing.BlockCardAdd. All entries are from 2008-2011. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No formal FK relationships.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BlockCardAdd | CardHash | WRITER | Adds a card hash to the block list |
| Billing.BlockCardRemove | CardHash | DELETER | Removes a card hash from the block list |
| Billing.CheckInBlockedCards | CardHash | READER | Returns 1 if card hash is blocked |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BlockedCard (table)
- No FK constraints (leaf table)
- Accessed by Billing schema procedures
```

### 6.1 Objects This Depends On

None (leaf table).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BlockCardAdd | Procedure | WRITER |
| Billing.BlockCardRemove | Procedure | DELETER |
| Billing.CheckInBlockedCards | Procedure | READER - deposit gating check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BBLC | CLUSTERED PK | CardHash ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BBLC | PK | CardHash uniqueness |

---

## 8. Sample Queries

### 8.1 Check if a card hash is blocked
```sql
SELECT 1 AS IsBlocked
FROM BackOffice.BlockedCard WITH (NOLOCK)
WHERE CardHash = @CardHash
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.8/10, Relationships: 8.8/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 3 analyzed (Billing schema) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.BlockedCard | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.BlockedCard.sql*
