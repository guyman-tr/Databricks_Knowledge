# History.ActiveCustomerToFunding

> Pre-image audit log recording the previous state of customer payment-method links whenever Billing.CustomerToFunding is updated - capturing the full state of a funding record before each change.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint IDENTITY, NONCLUSTERED PK with LastUsedDate) |
| **Partition** | Yes - YearlyHistory scheme, partitioned on LastUsedDate (yearly partitions) |
| **Indexes** | 1 active (NC PK on ID + LastUsedDate) |

---

## 1. Business Meaning

History.ActiveCustomerToFunding is the manual change history for Billing.CustomerToFunding - the live table linking eToro customers to their payment methods (credit cards, bank accounts, wire transfers, etc.). Every time a customer's funding record is updated (LastUsedDate refreshed, block status changed, deposit type changed), the OLD pre-update values are saved here by Billing.CustomerToFunding_Upsert and related procedures.

Without this table, there would be no audit trail of when a customer's payment method status changed, who blocked it, what it was blocked for, or how its deposit type changed over time. This supports compliance investigations ("was this card blocked before the withdrawal?"), chargeback disputes, AML reviews, and back-office funding management.

Data is inserted exclusively by Billing stored procedures during MERGE/UPDATE operations: when Billing.CustomerToFunding is UPDATED (existing link modified), the procedure captures the DELETED (old) values and writes them here. INSERTs to Billing.CustomerToFunding (new funding method added) do NOT create history rows. The YearlyHistory partition scheme by LastUsedDate efficiently stores historical records by year.

---

## 2. Business Logic

### 2.1 Pre-Image Capture Pattern

**What**: Only UPDATE operations on Billing.CustomerToFunding write here - not inserts or deletes.

**Columns/Parameters Involved**: `CID`, `FundingID`, `Occurred`, `ModificationDate`

**Rules**:
- When Billing.CustomerToFunding_Upsert runs MERGE and the result is UPDATE (Act='UPDATE'), it inserts the DELETED row values into this table
- The captured row is the state BEFORE the update (the old value of LastUsedDate, IsBlocked, etc.)
- ModificationDate = GETUTCDATE() at the moment of capture (not the original Occurred timestamp)
- INSERTs into Billing.CustomerToFunding (Act='INSERT') do NOT write to this history table
- This means the table shows a complete timeline of all changes after the initial link was created

### 2.2 Payment Method Lifecycle

**What**: Tracks the lifecycle of a customer's payment method - from active to blocked, type changes, and status changes.

**Columns/Parameters Involved**: `IsBlocked`, `BlockedAt`, `BlockedDescription`, `BlockManagerID`, `CustomerFundingStatusID`, `DepositTypeID`, `IsRefundExcluded`, `IsVerified`

**Rules**:
- IsBlocked=false -> payment method is active and usable for deposits/refunds
- IsBlocked=true -> payment method has been blocked (by customer or compliance), BlockedAt and BlockedDescription capture when and why
- BlockManagerID identifies the back-office manager who applied the block
- IsRefundExcluded=true -> refunds cannot be sent back to this payment method (e.g., for compliance reasons)
- IsVerified=true -> the payment method has been verified (ID check, 3DS, etc.)
- CustomerFundingStatusID=0 is the standard active state

---

## 3. Data Overview

| ID | CID | FundingID | DepositTypeID | CustomerFundingStatusID | IsBlocked | LastUsedDate | Meaning |
|----|-----|----------|--------------|------------------------|-----------|-------------|---------|
| 1655922450 | 25484671 | 4155589 | 1 (Regular) | 0 | false | 2026-03-19 | A regular credit card payment method linked to this customer. LastUsedDate was just refreshed (today), which triggered the pre-image capture of the previous LastUsedDate. |
| 1655922449 | 25484666 | 4155586 | 1 (Regular) | 0 | false | 2026-03-19 | Another regular payment method updated for a different customer. All fields show a standard active, unblocked card. |
| 1655922448 | 25484665 | 4155583 | 1 (Regular) | 0 | false | 2026-03-19 | Same pattern - LastUsedDate update triggers pre-image capture. The FundingID differs, confirming each customer has their own funding record. |
| 1655922447 | 25484660 | 2252741 | 1 (Regular) | 0 | false | 2026-03-19 | Customer 25484660 has two funding records (different FundingIDs), each tracked independently. |
| 1655922446 | 25484660 | 4155581 | 1 (Regular) | 0 | false | 2026-03-19 | Second funding method for the same customer. Multiple payment methods per customer are common and each gets separate history rows. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint IDENTITY(1837084922,1) | NO | - | VERIFIED | Surrogate auto-incrementing key for this history row. IDENTITY seeds at 1,837,084,922 - the migration point from the INT-era table (ActiveCustomerToFunding_INT). bigint used to support the high volumes of payment method updates. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID whose payment method link was changed. Central lookup for per-customer payment method audit queries. |
| 3 | FundingID | int | NO | - | VERIFIED | The specific payment method (card, bank account, wallet) whose Billing.CustomerToFunding record was updated. Each FundingID represents one payment instrument in Billing.Funding. |
| 4 | Occurred | datetime | YES | - | CODE-BACKED | The original timestamp of the Billing.CustomerToFunding record being changed - i.e., when the CURRENT state was first created (not when this history row was written). Captures the prior row's Occurred value. NULL if not set in the source. |
| 5 | DepositTypeID | int | YES | - | VERIFIED | Type of deposit transaction permitted for this funding method. FK to Dictionary.DepositType: 1=Regular (standard payment), 2=CvvFree (no CVV required), 3=Recurring (scheduled), 4=MoneyTransfer (internal), 5=RecurringInvestment. Default in application code is 1 (Regular). |
| 6 | ReasonID | int | YES | - | CODE-BACKED | Reason for associating this payment method with the customer. Default in application code is 6 (By user - customer-initiated). FK to a reason lookup not found in Dictionary schema as standalone table. |
| 7 | LastUsedDate | datetime | NO | - | VERIFIED | The last-used date FROM THE PREVIOUS STATE (pre-image). Also the partition key - YearlyHistory routes rows by year of LastUsedDate. The most common trigger for history rows is the LastUsedDate update in Billing.CustomerToFunding_Upsert. |
| 8 | CustomerFundingStatusID | int | YES | - | CODE-BACKED | Status of the customer-funding relationship. 0 = standard active state. No Dictionary.CustomerFundingStatus table found; values managed by application logic. |
| 9 | IsBlocked | bit | YES | - | VERIFIED | Whether the payment method was blocked at the time of this snapshot. false=active and usable, true=blocked. Billing.FundingBlock, Billing.BlockFundingUpdate, and related procedures set this to true when compliance or operations blocks a payment method. |
| 10 | IsRefundExcluded | bit | YES | - | VERIFIED | Whether refunds were excluded for this payment method at the time of this snapshot. true=refunds cannot be sent to this method (compliance/AML restriction). false=refunds permitted. |
| 11 | ManagerID | int | YES | - | CODE-BACKED | Back-office manager or agent who last modified this payment method link. Inherited from Billing.Funding.ManagerID at the time of the update. |
| 12 | BlockedAt | datetime | YES | - | VERIFIED | Timestamp when the payment method was blocked (if IsBlocked=true). NULL if not blocked at this snapshot point. Written when compliance or back-office executes a block operation. |
| 13 | BlockedDescription | varchar(255) | YES | - | VERIFIED | Free-text reason for blocking this payment method (if IsBlocked=true). E.g., "AML investigation", "Customer request", "Fraud detected". NULL if not blocked. |
| 14 | ModificationDate | datetime | NO | GETUTCDATE() | VERIFIED | Timestamp when THIS history row was written - i.e., when the UPDATE to Billing.CustomerToFunding occurred. Set to GETUTCDATE() by Billing.CustomerToFunding_Upsert (not inherited from the source row). This is the actual change timestamp. |
| 15 | IsVerified | bit | YES | - | CODE-BACKED | Whether the payment method had been verified at the time of this snapshot. Added in Jan 2023 (PAYIL-5743 per proc comment). true=verified (3DS, ID check passed), false/NULL=not verified. Captured from Billing.CustomerToFunding.IsVerified. |
| 16 | BlockManagerID | int | YES | - | CODE-BACKED | The specific manager who applied a block on this payment method. Separate from ManagerID - ManagerID is the general modifier, BlockManagerID is specifically the blocking agent. NULL if no block was in effect. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Billing.CustomerToFunding | Pre-image source | Each row is a historical snapshot of a Billing.CustomerToFunding row before an update. |
| FundingID | Billing.Funding | Implicit | The payment method being tracked. No FK constraint on this history table. |
| DepositTypeID | Dictionary.DepositType | Implicit | Payment type: 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CustomerToFunding | (view) | View | History.CustomerToFunding view unions this table with ActiveCustomerToFunding_INT for unified history. |
| Billing.CustomerToFunding_Upsert | CID, FundingID | Writer | Captures pre-image on MERGE UPDATE - the primary writer. |
| Billing.BlockFundingUpdate | CID, FundingID | Writer | Captures state before a block is applied. |
| Billing.BlockFundingUpdate_v2 | CID, FundingID | Writer | v2 of the block procedure. |
| Billing.CustomerToFunding_UpdateRecord | CID, FundingID | Writer | General record update capture. |
| Billing.CustomerToFunding_UpdateStatus | CID, FundingID | Writer | Status change capture. |
| Billing.CustomerToFunding_UpdateType | CID, FundingID | Writer | Deposit type change capture. |
| Billing.CustomerToFunding_UpdateDate | CID, FundingID | Writer | LastUsedDate update capture. |
| Billing.DeactivateCustomerCreditCard | CID, FundingID | Writer | Deactivation event capture. |
| Billing.DeactivateFunding | CID, FundingID | Writer | Funding deactivation capture. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCustomerToFunding (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies. No FK constraints or computed columns referencing other objects.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CustomerToFunding | View | Unified payment-method history view, unions this with ActiveCustomerToFunding_INT |
| Billing.CustomerToFunding_Upsert | Stored Procedure | Primary writer - MERGE OUTPUT pre-image capture |
| Billing.BlockFundingUpdate / _v2 | Stored Procedure | Writer - pre-block state capture |
| Multiple Billing.CustomerToFunding_Update* | Stored Procedure | Writers - various update operations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryActiveCustomerToFunding | NC PK | ID ASC, LastUsedDate ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryActiveCustomerToFunding | PRIMARY KEY NC | (ID, LastUsedDate) - composite key for partitioned table |
| Def_ModificationDate | DEFAULT | ModificationDate = GETUTCDATE() - auto-stamps write time |
| DATA_COMPRESSION = PAGE | Storage | Page compression on table and index |

---

## 8. Sample Queries

### 8.1 Get payment method change history for a customer
```sql
SELECT
    hac.ID,
    hac.FundingID,
    dt.DepositType       AS PaymentType,
    hac.IsBlocked,
    hac.IsRefundExcluded,
    hac.IsVerified,
    hac.BlockedAt,
    hac.BlockedDescription,
    hac.LastUsedDate     AS PrevLastUsedDate,
    hac.ModificationDate AS ChangedAt
FROM History.ActiveCustomerToFunding hac WITH (NOLOCK)
LEFT JOIN Dictionary.DepositType dt WITH (NOLOCK)
    ON hac.DepositTypeID = dt.DepositTypeID
WHERE hac.CID = 12345678
ORDER BY hac.ModificationDate DESC;
```

### 8.2 Find all funding methods that have ever been blocked
```sql
SELECT
    hac.CID,
    hac.FundingID,
    hac.BlockedAt,
    hac.BlockedDescription,
    hac.BlockManagerID,
    hac.ModificationDate
FROM History.ActiveCustomerToFunding hac WITH (NOLOCK)
WHERE hac.IsBlocked = 1
  AND hac.BlockedAt IS NOT NULL
  AND hac.ModificationDate >= DATEADD(MONTH, -3, GETUTCDATE())
ORDER BY hac.BlockedAt DESC;
```

### 8.3 Track deposit type changes for a specific funding method
```sql
SELECT
    hac.ID,
    hac.CID,
    dt.DepositType       AS DepositType,
    hac.CustomerFundingStatusID,
    hac.IsBlocked,
    hac.ModificationDate AS ChangedAt
FROM History.ActiveCustomerToFunding hac WITH (NOLOCK)
LEFT JOIN Dictionary.DepositType dt WITH (NOLOCK)
    ON hac.DepositTypeID = dt.DepositTypeID
WHERE hac.FundingID = 4155589
ORDER BY hac.ModificationDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.4/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Billing.CustomerToFunding_Upsert) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActiveCustomerToFunding | Type: Table | Source: etoro/etoro/History/Tables/History.ActiveCustomerToFunding.sql*
