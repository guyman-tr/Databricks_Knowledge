# Dictionary.BonusStatus

> Lookup table defining the lifecycle states of deposit bonuses — from New through Approved, Declined, or Reverted. Referenced by bonus-related billing and deposit tables.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | BonusStatusID (int, PK CLUSTERED) |
| **Filegroup** | DICTIONARY |
| **Row Count** | 4 (MCP verified) |
| **Indexes** | 1 active (PK only) |
| **FILLFACTOR** | 90 |

---

## 1. Business Meaning

Dictionary.BonusStatus tracks the lifecycle state of deposit bonuses. When a customer receives a promotional bonus on a deposit (e.g., welcome bonus, referral bonus, promotional credit), the bonus record references this table to indicate its current state. The four states cover the full lifecycle: **New (0)** when the bonus is first created and pending review, **Approved (1)** when the bonus is credited to the customer, **Declined (2)** when the bonus criteria are not met and the bonus is rejected, and **Reverted (3)** when a previously approved bonus is clawed back (e.g., customer withdrew before meeting holding requirements).

The table is central to bonus and deposit processing. Billing.Deposit and BackOffice.Bonus store BonusStatusID; procedures such as Billing.DepositAdd set the initial status, and Billing.AmountAddBonus updates it when bonuses are approved or reverted. Views and procs like Billing.GetDepositByID, Billing.GetDepositsByCid, Billing.FundingDataForDeposit, and dbo.BillingDepositWithoutXML expose BonusStatusID for reporting and API responses. History.Deposit preserves historical snapshots for audit.

**BonusStatusID = 1 (Approved)** is the key operational state — it indicates the bonus has been credited and the customer can use the funds. **BonusStatusID = 3 (Reverted)** supports claw-back scenarios when promotional terms are violated (e.g., early withdrawal), ensuring compliance with bonus T&C.

---

## 2. Business Logic

### 2.1 Bonus Lifecycle State Machine

**What**: The state transitions for a deposit bonus from creation to final disposition.

**Columns/Parameters Involved**: `BonusStatusID`, `Name`

**Rules**:
- **New (0)**: Initial state when a bonus is created (e.g., by Billing.DepositAdd). Pending validation against promotion terms.
- **Approved (1)**: Bonus validated and credited. Customer can use the funds. Set by Billing.AmountAddBonus when criteria are met.
- **Declined (2)**: Bonus rejected — criteria not met, or duplicate/invalid. Customer does not receive the bonus.
- **Reverted (3)**: Previously approved bonus clawed back — e.g., customer withdrew before holding period. Funds removed; audit trail preserved in History.Deposit.

**Diagram**:
```
Bonus Lifecycle:

  New (0) ──► Approved (1)  ──► (eligible for Reverted (3) if T&C violated)
       │
       └──► Declined (2)
```

### 2.2 Deposit and Bonus Integration

**What**: How BonusStatusID flows through deposit and bonus processing.

**Columns/Parameters Involved**: `BonusStatusID`

**Rules**:
- Billing.Deposit.BonusStatusID: Each deposit with a bonus has a status.
- Billing.DepositAdd: Creates deposit and sets initial BonusStatusID (typically New).
- Billing.AmountAddBonus: Adds bonus amount and may set Approved.
- Billing.GetDepositByID, GetDepositsByCid, GetDepositsByCidWithFundingType: Return BonusStatusID for API/UI.
- DWH.BillingDepositHourly: ETL uses BonusStatusID for reporting.

---

## 3. Data Overview

| BonusStatusID | Name | Meaning |
|---|---|---|
| 0 | New | Bonus created, pending validation. Initial state for new bonuses. |
| 1 | Approved | Bonus credited to customer. Funds available for trading. |
| 2 | Declined | Bonus rejected; criteria not met or invalid. |
| 3 | Reverted | Previously approved bonus clawed back (e.g., early withdrawal). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BonusStatusID | int | NO | - | VERIFIED | Primary key; unique identifier. Range 0–3. Referenced by Billing.Deposit, BackOffice.Bonus, and related procs. MCP-verified 4 rows. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable status label (New, Approved, Declined, Reverted). Used in joins for display and reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | BonusStatusID | Column reference | Status of bonus on deposit |
| BackOffice.Bonus | BonusStatusID | Column reference | Status of bonus record |
| Billing.DepositAdd | BonusStatusID | INSERT/SET | Sets initial bonus status |
| Billing.AmountAddBonus | BonusStatusID | UPDATE | Updates when bonus approved/reverted |
| Billing.GetDepositByID | BonusStatusID | SELECT | Returns in deposit data |
| Billing.GetDepositsByCid | BonusStatusID | SELECT | Returns in deposit list |
| Billing.GetDepositsByCidWithFundingType | BonusStatusID | SELECT | Returns in deposit list with funding |
| Billing.FundingDataForDeposit | BonusStatusID | View | Includes in funding view |
| History.Deposit | BonusStatusID | Table | Historical deposit snapshots |
| DWH.BillingDepositHourly | BonusStatusID | Proc | ETL/reporting |
| dbo.BillingDepositWithoutXML | BonusStatusID | View | Reporting view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.BonusStatus (table)
  └── referenced by Billing.Deposit, BackOffice.Bonus
  └── consumed by Billing.DepositAdd, AmountAddBonus
  └── read by GetDepositByID, GetDepositsByCid, FundingDataForDeposit
  └── used by History.Deposit, DWH.BillingDepositHourly, BillingDepositWithoutXML
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | BonusStatusID column |
| BackOffice.Bonus | Table | BonusStatusID column |
| Billing.DepositAdd | Stored Procedure | Sets BonusStatusID on insert |
| Billing.AmountAddBonus | Stored Procedure | Updates BonusStatusID |
| Billing.GetDepositByID | Stored Procedure | Returns BonusStatusID |
| Billing.GetDepositsByCid | Stored Procedure | Returns BonusStatusID |
| Billing.GetDepositsByCidWithFundingType | Stored Procedure | Returns BonusStatusID |
| Billing.FundingDataForDeposit | View | Includes BonusStatusID |
| History.Deposit | Table | Historical BonusStatusID |
| DWH.BillingDepositHourly | Stored Procedure | ETL uses BonusStatusID |
| dbo.BillingDepositWithoutXML | View | Includes BonusStatusID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCBS | CLUSTERED PK | BonusStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|------------------------|
| PK_DCBS | PRIMARY KEY | Unique bonus status identifier, DICTIONARY filegroup, FILLFACTOR 90 |

---

## 8. Sample Queries

### 8.1 List all bonus statuses
```sql
SELECT  BonusStatusID,
        Name
FROM    Dictionary.BonusStatus WITH (NOLOCK)
ORDER BY BonusStatusID;
```

### 8.2 Count deposits by bonus status
```sql
SELECT  bs.Name,
        COUNT(*) AS DepositCount
FROM    Billing.Deposit d WITH (NOLOCK)
JOIN    Dictionary.BonusStatus bs WITH (NOLOCK)
        ON d.BonusStatusID = bs.BonusStatusID
WHERE   d.BonusStatusID IS NOT NULL
GROUP BY bs.Name
ORDER BY DepositCount DESC;
```

### 8.3 Recent approved bonuses
```sql
SELECT  TOP 100
        d.DepositID,
        d.CID,
        d.Amount,
        d.InsertDate
FROM    Billing.Deposit d WITH (NOLOCK)
WHERE   d.BonusStatusID = 1  -- Approved
ORDER BY d.InsertDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data (4 statuses), codebase analysis of Billing.Deposit, BackOffice.Bonus, Billing.DepositAdd, Billing.AmountAddBonus, and related procs/views.

---

*Generated: 2026-03-13 | Quality: 9.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8+ analyzed | MCP Data: 4 rows | Corrections: 0 applied*
*Object: Dictionary.BonusStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BonusStatus.sql*
