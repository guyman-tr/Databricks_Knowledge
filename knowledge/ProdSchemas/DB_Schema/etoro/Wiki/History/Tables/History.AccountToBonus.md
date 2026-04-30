# History.AccountToBonus

> Legacy bridge table linking account balance-update events to the bonus type that caused them; all referencing logic has been commented out and the table is empty.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (AccountUpdateID, BonusID) - composite PK NONCLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (composite PK nonclustered) |

---

## 1. Business Meaning

History.AccountToBonus was designed as a junction table connecting a bonus credit event in History.Account to the specific bonus type (BackOffice.BonusType) that was awarded. Each row would have represented: "account update event X was a bonus of type Y." This allowed systems to look up not just that a bonus was credited (AccountUpdateTypeID=3 in History.Account), but which named bonus campaign or type it belonged to.

Without this table the original design could not answer: "which specific bonus campaign (registration, deposit, retention, championship win, etc.) caused this account update?" The table was the semantic link between the financial ledger row and the bonus catalogue.

In practice, this table is defunct. The Billing.Account table - required for the join chain connecting a customer (CID) to their account update events - was dropped. Both procedures that referenced this table (Billing.CustomerRemove and Billing.GetCustomerBonuses) have had their History.AccountToBonus logic commented out as a direct consequence. The table currently holds 0 rows and receives no new inserts.

---

## 2. Business Logic

### 2.1 Original Bonus-to-AccountUpdate Linkage

**What**: The table was the bridge between the financial audit event and the bonus catalogue entry.

**Columns/Parameters Involved**: `AccountUpdateID`, `BonusID`

**Rules**:
- One row per (AccountUpdateID, BonusID) pair - a bonus credit event maps to exactly one bonus type
- AccountUpdateID references the History.Account row where AccountUpdateTypeID=3 (Bonus) - the credit event
- BonusID references BackOffice.BonusType, identifying which campaign or product the bonus belonged to
- Insert was intended to be done at the time of bonus credit, alongside the History.Account insert

**Diagram**:
```
Original data flow (no longer active):
  Customer receives bonus
    -> History.Account row inserted (AccountUpdateTypeID=3)
    -> History.AccountToBonus row inserted
         AccountUpdateID = new History.Account.AccountUpdateID
         BonusID         = BackOffice.BonusType.BonusTypeID (e.g. 2=SalesFirstDepositBonus)

Billing.GetCustomerBonuses would query:
  Billing.Account (dropped) -> History.Account -> History.AccountToBonus -> BackOffice.BonusType
  To return: AccountBalance, BonusTypeID, PreviousBalance, NewBalance, Amount, UpdateDate
```

### 2.2 Current Status - Defunct

**What**: The table is inactive - 0 rows, no active writers, no active readers.

**Columns/Parameters Involved**: All columns

**Rules**:
- Billing.CustomerRemove had a DELETE against this table; it is commented out with note: "Because we drop table Billing.Account then I can't use in this Delete"
- Billing.GetCustomerBonuses had a SELECT joining this table; it is fully commented out and returns 0 unconditionally
- No other procedures reference this table (verified by codebase grep)
- The FK constraint to History.Account and BackOffice.BonusType remain enforced, but are effectively irrelevant given 0 rows

**Diagram**:
```
Status: DEFUNCT
  Writers:  None (original writer code removed when Billing.Account was dropped)
  Readers:  None (Billing.GetCustomerBonuses returns 0 unconditionally)
  Row count: 0
  Risk of removal: Low FK risk (referencing procs already commented out)
```

---

## 3. Data Overview

The table is empty (0 rows). No representative rows can be shown.

For reference, the BackOffice.BonusType FK target contains bonus types such as:

| BonusTypeID | Name | IsWithdrawable | IsDepositRelated | Meaning |
|---|---|---|---|---|
| 1 | First Registration Bonus | false | 0 | Awarded on first account registration; non-withdrawable promotional credit |
| 2 | Sales First Deposit Bonus | false | 1 | Awarded by sales team on first deposit; deposit-linked campaign |
| 3 | Custom | false | 0 | Manual/custom bonus applied by operations team |
| 4 | Championship Winner | false | 0 | Prize awarded to trading game championship winner |
| 10 | Retention | false | 1 | Retention campaign bonus tied to deposit activity |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountUpdateID | int | NO | - | CODE-BACKED | Foreign key to History.Account(AccountUpdateID). Identifies the account balance-update event (ledger row) that represents the bonus credit. In original design this would always be a row where AccountUpdateTypeID=3 (Bonus) in History.Account. Composite PK component. |
| 2 | BonusID | int | NO | - | CODE-BACKED | Foreign key to BackOffice.BonusType(BonusTypeID). Identifies the specific bonus product or campaign that was credited. Maps to named bonus types such as First Registration Bonus (1), Sales First Deposit Bonus (2), Custom (3), Championship Winner (4), Retention Deposit Bonus (5). Composite PK component. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountUpdateID | History.Account(AccountUpdateID) | FK | Links the bridge row to the account ledger event that recorded the bonus credit |
| BonusID | BackOffice.BonusType(BonusTypeID) | FK | Identifies which bonus campaign or type was awarded in this event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CustomerRemove | AccountUpdateID | FK - COMMENTED OUT | Original DELETE logic (commented out; Billing.Account dependency was dropped) |
| Billing.GetCustomerBonuses | AccountUpdateID, BonusID | JOIN - COMMENTED OUT | Original SELECT logic (commented out; returns 0 unconditionally) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AccountToBonus (table)
```

Tables are always leaf nodes - no code-level dependencies.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Account | Table | FK target - AccountUpdateID references History.Account(AccountUpdateID) |
| BackOffice.BonusType | Table | FK target - BonusID references BackOffice.BonusType(BonusTypeID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerRemove | Stored Procedure | DELETE (commented out) - was a Deleter in customer removal cascade |
| Billing.GetCustomerBonuses | Stored Procedure | SELECT JOIN (commented out) - was a Reader for customer bonus history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HA2B | NC PK | AccountUpdateID ASC, BonusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HA2B | PRIMARY KEY | Composite key: (AccountUpdateID, BonusID) - one bonus type per account update event |
| FK_HACC_HA2B | FOREIGN KEY | AccountUpdateID -> History.Account(AccountUpdateID) - referential integrity to audit ledger |
| FK_BBNT_HA2B | FOREIGN KEY | BonusID -> BackOffice.BonusType(BonusTypeID) - referential integrity to bonus catalogue |

---

## 8. Sample Queries

### 8.1 Check current row count (table is empty)
```sql
SELECT COUNT(*) AS RowCount
FROM [History].[AccountToBonus] WITH (NOLOCK)
```

### 8.2 List all bonus types that could be referenced (from FK target)
```sql
SELECT bt.BonusTypeID, bt.Name, bt.DisplayName, bt.IsWithdrawable, bt.IsDepositRelated
FROM [BackOffice].[BonusType] bt WITH (NOLOCK)
WHERE bt.IsActive = 1
ORDER BY bt.BonusTypeID
```

### 8.3 Original bonus history query pattern (now defunct - for reference only)
```sql
-- Original Billing.GetCustomerBonuses query pattern (commented out in procedure)
-- Requires Billing.Account which has been dropped
-- SELECT
--   hacc.AccountUpdateID, hacc.PreviousAccountBalance, hacc.NewAccountBalance,
--   hacc.Amount, hacc.UpdateDate, bbnt.BonusTypeID, bbnt.Name
-- FROM History.Account hacc WITH (NOLOCK)
-- JOIN History.AccountToBonus ha2b WITH (NOLOCK) ON hacc.AccountUpdateID = ha2b.AccountUpdateID
-- JOIN BackOffice.BonusType bbnt WITH (NOLOCK) ON ha2b.BonusID = bbnt.BonusTypeID
-- WHERE hacc.AccountID = @AccountID  -- (Billing.Account lookup required for CID -> AccountID)

-- Current safe query (no data expected):
SELECT a.AccountUpdateID, a.BonusID, bt.Name AS BonusName
FROM [History].[AccountToBonus] a WITH (NOLOCK)
JOIN [BackOffice].[BonusType] bt WITH (NOLOCK) ON a.BonusID = bt.BonusTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AccountToBonus | Type: Table | Source: etoro/etoro/History/Tables/History.AccountToBonus.sql*
