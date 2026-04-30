# History.CustomerToFunding

> Unified audit trail for customer payment-method change history - combines the retired INT-era archive (History.ActiveCustomerToFunding_INT) with the current BIGINT table (History.ActiveCustomerToFunding) to provide a seamless full-history query across both storage generations.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | ID (bigint, promoted from int in INT-era rows) |
| **Partition** | N/A (view - both base tables use YearlyHistory partition scheme on LastUsedDate) |
| **Indexes** | N/A (view - base table indexes are used) |

---

## 1. Business Meaning

History.CustomerToFunding is the complete audit trail for changes to customer payment method links (`Billing.CustomerToFunding`). Every time a customer's funding record is updated - when a card is blocked, its deposit type changes, its LastUsedDate is refreshed, or its verification status is updated - the previous state (pre-image) is captured in one of the two base tables. This view unifies those two tables into a single queryable history spanning the full platform lifetime.

The view solves a storage generation problem: when the INT-keyed table (`History.ActiveCustomerToFunding_INT`) approached its 2.1 billion row limit, a new bigint-keyed table (`History.ActiveCustomerToFunding`) was introduced to continue accumulating history. The INT table was frozen as a permanent archive. Without this view, queries for complete payment-method audit history would require two separate queries unioned manually. The view handles this transparently: query `History.CustomerToFunding` and get the full timeline.

There are no procedure references to this view in the current codebase - it is an ad-hoc compliance and investigation tool. Back-office analysts and compliance investigators use it to answer questions like "was this card blocked before the withdrawal?" or "when did this customer's payment method type change?" The data is written by more than 10 Billing procedures that capture pre-images on every modification to Billing.CustomerToFunding.

---

## 2. Business Logic

### 2.1 INT-to-BIGINT Migration Bridge

**What**: The UNION ALL combines two generations of the same logical data, with three column NULLs to align the INT table's older schema.

**Columns/Parameters Involved**: `ID`, `ModificationDate`, `IsVerified`, `BlockManagerID`

**Rules**:
- INT table (`History.ActiveCustomerToFunding_INT`) has 13 columns; BIGINT table has 16
- The three extra columns added after the INT table was retired: `ModificationDate`, `IsVerified`, `BlockManagerID`
- In the UNION ALL, the INT rows get `NULL AS ModificationDate`, `NULL AS IsVerified`, `NULL AS BlockManagerID` for these newer columns
- ID in the INT table is stored as int; SQL Server implicitly promotes to bigint in the UNION ALL result
- Consumers will see all 16 columns for all rows; NULL values in the three extra columns signal an INT-era row

**Diagram**:
```
History.ActiveCustomerToFunding_INT (retired, int era, ~100M+ rows, frozen)
  SELECT *, NULL AS ModificationDate, NULL AS IsVerified, NULL AS BlockManagerID
  |
UNION ALL
  |
History.ActiveCustomerToFunding (active, bigint era, receives new records)
  SELECT *  (all 16 columns natively)
  |
  v
History.CustomerToFunding (view - 16 columns, full history)
  ID column is bigint in both branches (int promoted in UNION ALL)
```

### 2.2 Pre-Image Capture Pattern

**What**: Only UPDATE operations on Billing.CustomerToFunding generate history rows - new payment methods (INSERT) do not.

**Columns/Parameters Involved**: `CID`, `FundingID`, `Occurred`, `ModificationDate`, `LastUsedDate`

**Rules**:
- When Billing.CustomerToFunding_Upsert executes a MERGE and the result is UPDATE, the OLD (DELETED) row values are written to the history table
- Occurred in the history row = the Occurred timestamp of the PREVIOUS state of the live record (when that state was first created)
- ModificationDate = GETUTCDATE() at write time (not inherited from source) - this is the actual change timestamp for BIGINT-era rows; NULL for INT-era rows
- The most frequent trigger is LastUsedDate refresh on payment-method use - this generates the majority of rows

---

## 3. Data Overview

| ID | CID | FundingID | DepositTypeID | IsBlocked | LastUsedDate | ModificationDate | IsVerified | Meaning |
|---|---|---|---|---|---|---|---|---|
| BIGINT-era row (ID ~1.6B+) | 25484671 | 4155589 | 1 (Regular) | false | 2026-03-19 | 2026-03-19 | false | Standard credit card payment method update for a recent customer - LastUsedDate refresh captured as pre-image. ModificationDate shows this is a BIGINT-era row with the full column set. |
| INT-era row (ID ~100M+) | (older CIDs) | (older FundingIDs) | (varies) | (varies) | (older dates) | NULL | NULL | Archived payment method history from the int era. ModificationDate=NULL and IsVerified=NULL confirm this is from the INT table; these columns did not exist when the INT table was active. |

Note: Live data sample via MCP timed out for this view due to the cross-era UNION ALL over two large partitioned tables. Row data above is derived from the base table documentation.

---

## 4. Elements

16 output columns (13 from INT table + 3 NULLed in INT rows; all 16 native in BIGINT rows).

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | VERIFIED | Surrogate row identifier. For INT-era rows: original int value promoted to bigint in UNION ALL (range ~100M-2.1B). For BIGINT-era rows: bigint IDENTITY starting at 1,837,084,922. Disambiguates rows across both storage generations. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID whose payment method link changed. Central query key for per-customer payment method audit history. |
| 3 | FundingID | int | NO | - | VERIFIED | The specific payment instrument (card, bank account, wallet) whose Billing.CustomerToFunding record was updated. Each FundingID corresponds to one payment method in Billing.Funding. |
| 4 | Occurred | datetime | YES | - | CODE-BACKED | The creation/last-updated timestamp of the PREVIOUS state of the Billing.CustomerToFunding record (pre-image). Not the timestamp this history row was written - that is ModificationDate. NULL if not set in source. |
| 5 | DepositTypeID | int | YES | - | VERIFIED | Payment transaction type permitted for this funding method at the time of snapshot. 1=Regular (standard payment), 2=CvvFree (no CVV required), 3=Recurring (scheduled), 4=MoneyTransfer (internal), 5=RecurringInvestment. (Source: Dictionary.DepositType) |
| 6 | ReasonID | int | YES | - | CODE-BACKED | Reason for the customer-funding association. Default in application code is 6 (By user - customer-initiated). Lookup table not found in Dictionary schema; managed by application layer. |
| 7 | LastUsedDate | datetime | NO | - | VERIFIED | Last-used date from the PREVIOUS state (pre-image). Also the partition key - YearlyHistory partitions rows by year of this value. The most frequent trigger for history rows is this date being refreshed in Billing.CustomerToFunding_Upsert. |
| 8 | CustomerFundingStatusID | int | YES | - | CODE-BACKED | Status of the customer-funding relationship at the time of this snapshot. 0 = standard active state. Values managed by application logic; no Dictionary.CustomerFundingStatus table in schema. |
| 9 | IsBlocked | bit | YES | - | VERIFIED | Whether the payment method was blocked at this snapshot moment. false/0=active and usable for deposits/refunds; true/1=blocked by compliance or back-office. Blocking procedures (Billing.FundingBlock, Billing.BlockFundingUpdate) set this to true. |
| 10 | IsRefundExcluded | bit | YES | - | VERIFIED | Whether refunds were excluded for this payment method at this snapshot. true=refunds cannot be sent to this method (compliance/AML restriction); false=refunds permitted. |
| 11 | ManagerID | int | YES | - | CODE-BACKED | Back-office manager or agent who last modified this payment method link. Inherited from Billing.Funding.ManagerID at the time of the update. |
| 12 | BlockedAt | datetime | YES | - | VERIFIED | Timestamp when the payment method was blocked (if IsBlocked=true at this snapshot). NULL if not blocked at this point in history. |
| 13 | BlockedDescription | varchar(255) | YES | - | VERIFIED | Free-text reason for the block (if IsBlocked=true). E.g., "AML investigation", "Customer request", "Fraud detected". NULL if not blocked. |
| 14 | ModificationDate | datetime | YES | - | VERIFIED | Timestamp when THIS history row was written - i.e., when the UPDATE to Billing.CustomerToFunding occurred. Set to GETUTCDATE() by the writing procedure. NULL for INT-era rows (column did not exist when the INT table was active). |
| 15 | IsVerified | bit | YES | - | CODE-BACKED | Whether the payment method had been verified (3DS, ID check) at this snapshot. true=verified; false/NULL=not verified. NULL for INT-era rows (column added after INT table was retired, per PAYIL-5743 Jan 2023). |
| 16 | BlockManagerID | int | YES | - | CODE-BACKED | The specific manager who applied a block on this payment method. Distinct from ManagerID (general modifier). NULL for non-blocked rows and NULL for all INT-era rows (column did not exist in INT-era schema). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns - INT era) | History.ActiveCustomerToFunding_INT | View (UNION branch) | Historical archive of INT-era payment method changes (frozen, no new writes) |
| (all columns - BIGINT era) | History.ActiveCustomerToFunding | View (UNION branch) | Active table receiving new payment method change history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (no direct procedure consumers found) | - | - | This view appears to be used for ad-hoc compliance and audit queries rather than by scheduled procedures. The base tables are referenced by 10+ Billing writers. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CustomerToFunding (view)
├── History.ActiveCustomerToFunding_INT (table - leaf, INT era archive)
└── History.ActiveCustomerToFunding (table - leaf, current BIGINT era)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCustomerToFunding_INT | Table | First UNION ALL branch - INT-era archive rows with 3 NULLed columns |
| History.ActiveCustomerToFunding | Table | Second UNION ALL branch - current BIGINT-era rows with all columns |

### 6.2 Objects That Depend On This

No direct procedure consumers found in current codebase. The view serves as an ad-hoc compliance and audit query interface.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Both base tables use the YearlyHistory partition scheme on LastUsedDate and have NC PK indexes on (ID, LastUsedDate). Queries against this view that filter by LastUsedDate will benefit from partition elimination on both branches.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get complete payment method change history for a customer
```sql
SELECT
    ctf.ID,
    ctf.FundingID,
    ctf.DepositTypeID,
    ctf.IsBlocked,
    ctf.BlockedAt,
    ctf.BlockedDescription,
    ctf.IsVerified,
    ctf.ModificationDate,
    ctf.LastUsedDate
FROM History.CustomerToFunding ctf WITH (NOLOCK)
WHERE ctf.CID = 12345678
ORDER BY ctf.LastUsedDate DESC;
```

### 8.2 Find all block events for a specific payment method
```sql
SELECT
    ctf.CID,
    ctf.ID,
    ctf.IsBlocked,
    ctf.BlockedAt,
    ctf.BlockedDescription,
    ctf.BlockManagerID,
    ctf.ModificationDate
FROM History.CustomerToFunding ctf WITH (NOLOCK)
WHERE ctf.FundingID = 4155589
  AND ctf.IsBlocked = 1
ORDER BY ctf.ModificationDate DESC;
```

### 8.3 Identify INT-era rows vs BIGINT-era rows for a customer
```sql
SELECT
    ctf.ID,
    ctf.FundingID,
    ctf.LastUsedDate,
    ctf.ModificationDate,
    CASE WHEN ctf.ModificationDate IS NULL THEN 'INT era (archived)' ELSE 'BIGINT era (current)' END AS Era
FROM History.CustomerToFunding ctf WITH (NOLOCK)
WHERE ctf.CID = 12345678
ORDER BY ctf.LastUsedDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.CustomerToFunding. Business context inherited from History.ActiveCustomerToFunding and History.ActiveCustomerToFunding_INT documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.4/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 68 files scanned (base table consumers) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.CustomerToFunding | Type: View | Source: etoro/etoro/History/Views/History.CustomerToFunding.sql*
