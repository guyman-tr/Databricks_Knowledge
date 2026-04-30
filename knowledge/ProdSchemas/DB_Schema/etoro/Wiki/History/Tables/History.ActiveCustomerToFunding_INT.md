# History.ActiveCustomerToFunding_INT

> Legacy int-era archive of customer payment-method change history, structurally equivalent to History.ActiveCustomerToFunding but with an int-typed ID and three fewer columns added in the post-migration era.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY(100000000,1), NONCLUSTERED PK with LastUsedDate) |
| **Partition** | Yes - YearlyHistory scheme, partitioned on LastUsedDate (yearly partitions) |
| **Indexes** | 1 active (NC PK on ID + LastUsedDate) |

---

## 1. Business Meaning

History.ActiveCustomerToFunding_INT is the retired int-era predecessor to History.ActiveCustomerToFunding. It recorded the same pre-image change history for Billing.CustomerToFunding but was limited by an int identity column (max ~2.1 billion rows). When ID values approached the int ceiling, a new bigint-keyed table (History.ActiveCustomerToFunding) was created to continue accumulating history. The INT version was frozen and its data is preserved as a permanent archive of older payment method changes.

Without this table, the complete payment-method audit trail for older customer accounts and early platform history would be lost. The History.CustomerToFunding view unifies both this archive and the current table to provide a seamless history query across both eras.

No procedures write to this table in the current system - it is purely archival. The IDENTITY(100000000,1) seed starting at 100 million reflects either a migration that preserved original values or the table was used starting from that seed for a deliberate offset.

---

## 2. Business Logic

### 2.1 Structural Equivalence to ActiveCustomerToFunding

**What**: This table is a structural subset of History.ActiveCustomerToFunding - same data semantics, three columns absent.

**Columns/Parameters Involved**: All shared columns

**Rules**:
- All shared columns carry identical semantics to History.ActiveCustomerToFunding
- Missing columns (vs the current table): ModificationDate, IsVerified, BlockManagerID - these were added after this table was retired
- ID is int (vs bigint in the current table) - the int-era limitation that prompted the migration
- Same YearlyHistory partition scheme by LastUsedDate
- Same CreditType, DepositType, and status semantics

**Diagram**:
```
Payment method history timeline:
  [INT era]   ID 100000000 to ~2.1B -> History.ActiveCustomerToFunding_INT (retired, archived)
  [BIGINT era] ID 1837084922+       -> History.ActiveCustomerToFunding (active, receiving new records)

History.CustomerToFunding view unifies both:
  SELECT ... FROM History.ActiveCustomerToFunding_INT
  UNION ALL
  SELECT ... FROM History.ActiveCustomerToFunding
```

---

## 3. Data Overview

| ID | CID | FundingID | DepositTypeID | IsBlocked | LastUsedDate | Meaning |
|----|-----|----------|--------------|-----------|-------------|---------|
| (data present in production) | - | - | - | - | - | Table is archived - contains historical payment method change records from the int-era period. Same row semantics as History.ActiveCustomerToFunding. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(100000000,1) | NO | - | VERIFIED | Surrogate auto-incrementing key. int type - the legacy constraint that caused migration. Seeded at 100,000,000. All values in this table are below the migration cutoff (~1.84B). |
| 2 | CID | int | NO | - | VERIFIED | Customer ID. Same semantics as History.ActiveCustomerToFunding.CID. |
| 3 | FundingID | int | NO | - | VERIFIED | Payment method identifier. Same semantics as History.ActiveCustomerToFunding.FundingID. |
| 4 | Occurred | datetime | YES | - | CODE-BACKED | Original Billing.CustomerToFunding row Occurred timestamp before the update. Same semantics as History.ActiveCustomerToFunding.Occurred. |
| 5 | DepositTypeID | int | YES | - | VERIFIED | Payment method deposit type. FK to Dictionary.DepositType: 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment. Same semantics as History.ActiveCustomerToFunding.DepositTypeID. |
| 6 | ReasonID | int | YES | - | CODE-BACKED | Reason for the customer-funding association. Default=6 (By user). Same semantics as History.ActiveCustomerToFunding.ReasonID. |
| 7 | LastUsedDate | datetime | NO | - | VERIFIED | Last-used date from the previous state (pre-image). Also the partition key for YearlyHistory. Same semantics as History.ActiveCustomerToFunding.LastUsedDate. |
| 8 | CustomerFundingStatusID | int | YES | - | CODE-BACKED | Status of the customer-funding relationship (0=standard active). Same semantics as History.ActiveCustomerToFunding.CustomerFundingStatusID. |
| 9 | IsBlocked | bit | YES | - | VERIFIED | Whether payment method was blocked at this snapshot. true=blocked, false=active. Same semantics as History.ActiveCustomerToFunding.IsBlocked. |
| 10 | IsRefundExcluded | bit | YES | - | VERIFIED | Whether refunds were excluded for this method. Same semantics as History.ActiveCustomerToFunding.IsRefundExcluded. |
| 11 | ManagerID | int | YES | - | CODE-BACKED | Back-office manager who last modified this record. Same semantics as History.ActiveCustomerToFunding.ManagerID. |
| 12 | BlockedAt | datetime | YES | - | VERIFIED | Timestamp of block application (if IsBlocked=true). Same semantics as History.ActiveCustomerToFunding.BlockedAt. |
| 13 | BlockedDescription | varchar(255) | YES | - | VERIFIED | Reason for block (if IsBlocked=true). Same semantics as History.ActiveCustomerToFunding.BlockedDescription. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositTypeID | Dictionary.DepositType | Implicit | 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment. |
| CID + FundingID | Billing.CustomerToFunding | Pre-image source | Historical snapshots of this live table from the int-era period. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CustomerToFunding | (view) | View | Unifies this INT archive with History.ActiveCustomerToFunding for full payment method history. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCustomerToFunding_INT (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CustomerToFunding | View | Unions this INT archive with the current bigint table for unified history queries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryActiveCustomerToFunding_int | NC PK | ID ASC, LastUsedDate ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryActiveCustomerToFunding_int | PRIMARY KEY NC | (ID, LastUsedDate) - composite key for partitioned table |
| DATA_COMPRESSION = PAGE | Storage | Page compression on table and index |

---

## 8. Sample Queries

### 8.1 Get int-era payment method history for a customer
```sql
SELECT
    hac.ID,
    hac.FundingID,
    dt.DepositType       AS PaymentType,
    hac.IsBlocked,
    hac.IsRefundExcluded,
    hac.BlockedAt,
    hac.BlockedDescription,
    hac.LastUsedDate     AS PrevLastUsedDate
FROM History.ActiveCustomerToFunding_INT hac WITH (NOLOCK)
LEFT JOIN Dictionary.DepositType dt WITH (NOLOCK)
    ON hac.DepositTypeID = dt.DepositTypeID
WHERE hac.CID = 12345678
ORDER BY hac.LastUsedDate DESC;
```

### 8.2 Unified payment method history (INT + BIGINT eras)
```sql
-- Use the unified view instead of querying tables directly
SELECT *
FROM History.CustomerToFunding WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY LastUsedDate DESC;
```

### 8.3 Find historically blocked payment methods from int era
```sql
SELECT
    hac.CID,
    hac.FundingID,
    hac.BlockedAt,
    hac.BlockedDescription,
    hac.ManagerID
FROM History.ActiveCustomerToFunding_INT hac WITH (NOLOCK)
WHERE hac.IsBlocked = 1
  AND hac.BlockedAt IS NOT NULL
ORDER BY hac.BlockedAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 9.2/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active (retired table) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActiveCustomerToFunding_INT | Type: Table | Source: etoro/etoro/History/Tables/History.ActiveCustomerToFunding_INT.sql*
