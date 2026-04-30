# Trade.InterestMonthly_July

> Archive snapshot of the InterestMonthly table from July. Empty backup taken before a migration. Stores monthly aggregated interest per customer: untaxed interest, tax percentage, taxed interest, and CreditID linking to the credit transaction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InterestMonthlyID (bigint, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | PK + UQ |

---

## 1. Business Meaning

Trade.InterestMonthly_July is an archive snapshot of the InterestMonthly table from July. The main InterestMonthly table stores monthly aggregated interest amounts per customer: InterestUntaxed, TaxPercentage, InterestTaxed, CreditID (linking to the actual credit transaction), RegulationID, StatusID, and Date. This backup is part of the same July interest migration backup as InterestDaily_July. The live database reports EXISTS with 0 rows; the table is empty but retains the schema.

This table exists to preserve a prior state of monthly interest data before a migration or cleanup. The FK to Dictionary.InterestStatus (named FK_InterestStatus) ties StatusID to interest processing states.

---

## 2. Business Logic

### 2.1 Archived Monthly Interest Structure

**What**: One row per customer per month (CID, Date) with monthly interest aggregates and tax calculation.

**Columns/Parameters Involved**: `CID`, `Date`, `InterestUntaxed`, `TaxPercentage`, `InterestTaxed`, `CreditID`, `StatusID`

**Rules**:
- UQ_InterestMonthly enforces one row per (CID, Date)
- StatusID FK to Dictionary.InterestStatus
- CreditID links to the credit transaction when interest is paid
- Occurred records when the row was created (default getutcdate())

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Live DB | EXISTS |
| Row count | 0 (empty) |
| Purpose | Archive/reference only |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | InterestMonthlyID | bigint | NO | IDENTITY(1,1) | Surrogate key (PK) |
| 2 | CID | int | NO | - | Customer ID |
| 3 | InterestUntaxed | decimal(12,2) | NO | - | Interest before tax |
| 4 | TaxPercentage | decimal(5,2) | NO | - | Tax rate applied |
| 5 | InterestTaxed | decimal(12,2) | NO | - | Interest after tax |
| 6 | CreditID | bigint | YES | - | Links to credit transaction when paid |
| 7 | RegulationID | int | NO | - | Regulation context |
| 8 | StatusID | tinyint | NO | - | FK to Dictionary.InterestStatus |
| 9 | Date | date | NO | - | Month of interest (month boundary) |
| 10 | Occurred | datetime | NO | getutcdate() | When row was created |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StatusID | Dictionary.InterestStatus | FK (FK_InterestStatus) | Interest processing state |
| CreditID | (Credit table) | Implicit | Links to credit transaction |

### 5.2 Referenced By

None in SSDT. Archive table.

---

## 6. Dependencies

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestStatus | Table | FK StatusID |

### 6.2 Objects That Depend On This

None found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InterestMonthly | CLUSTERED | InterestMonthlyID | - | - | Active (PAGE compression) |
| UQ_InterestMonthly | UNIQUE | CID, Date | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| PK_InterestMonthly | PRIMARY KEY | InterestMonthlyID |
| UQ_InterestMonthly | UNIQUE | (CID, Date) |
| FK_InterestStatus | FOREIGN KEY | StatusID -> Dictionary.InterestStatus(StatusID) |

---

*Generated: 2026-03-14 | Quality: 7.0/10*
*Object: Trade.InterestMonthly_July | Type: Table | Archive snapshot (empty)*
