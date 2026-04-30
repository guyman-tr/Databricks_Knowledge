# Trade.InterestDaily_July

> Archive snapshot of the InterestDaily table from July (likely July 2023 or similar). Empty backup taken before a migration or cleanup. Tracks daily interest accrual per customer via synonym Trade.InterestDaily.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InterestDailyID (bigint, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | PK + UQ |

---

## 1. Business Meaning

Trade.InterestDaily_July is an archive snapshot of the Trade.InterestDaily table (accessed via synonym) from July. The main InterestDaily table tracks daily interest accrual per customer: DailyInterest, FundsForInterest, YearlyInterestPercentage, DayOfInterest, and financial snapshot columns (Credit, RealizedEquity, BonusCredit, etc.). This backup was taken before a migration or cleanup operation and preserved for reference or rollback. The live database reports EXISTS with 0 rows; the table is empty but retains the schema and constraints.

This table exists because interest-processing migrations may require preserving a prior state for audit, comparison, or rollback. The _July suffix indicates the approximate backup date. The FK to Dictionary.InterestStatus ties StatusID to interest processing states (e.g., pending, processed, paid).

---

## 2. Business Logic

### 2.1 Archived Interest Snapshot Structure

**What**: One row per customer per day (CID, DayOfInterest) with daily interest amounts and account snapshot at snapshot time.

**Columns/Parameters Involved**: `CID`, `DayOfInterest`, `DailyInterest`, `FundsForInterest`, `Interest`, `StatusID`

**Rules**:
- UQ_InterestDaily enforces one row per (CID, DayOfInterest)
- StatusID FK to Dictionary.InterestStatus identifies interest processing state
- CountryID, PlayerLevelID, AccountTypeID, RegulationID capture customer attributes at snapshot time for interest calculation context

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
| 1 | InterestDailyID | bigint | NO | IDENTITY(1,1) | Surrogate key (PK) |
| 2 | CID | int | NO | - | Customer ID |
| 3 | GCID | int | NO | - | Global customer ID |
| 4 | DailyInterest | decimal(15,6) | YES | - | Daily interest amount |
| 5 | FundsForInterest | money | YES | - | Funds used for interest calculation |
| 6 | YearlyInterestPercentage | decimal(5,2) | YES | - | Annual interest rate |
| 7 | DayOfInterest | date | NO | - | Date of interest accrual |
| 8 | LastUpdate | datetime | NO | getutcdate() | Last modification timestamp |
| 9 | CountryID | int | NO | - | Customer country at snapshot |
| 10 | PlayerLevelID | int | NO | - | Player level at snapshot |
| 11 | AccountTypeID | int | NO | - | Account type at snapshot |
| 12 | RegulationID | int | NO | - | Regulation at snapshot |
| 13 | Interest | money | NO | - | Interest amount |
| 14 | MinRealMoney | money | NO | - | Minimum real money threshold |
| 15 | SumOfPendingCashoutRequests | money | YES | - | Pending cashout total |
| 16 | Credit | money | NO | - | Credit at snapshot |
| 17 | RealizedEquity | money | NO | - | Realized equity at snapshot |
| 18 | BonusCredit | money | NO | - | Bonus credit at snapshot |
| 19 | StatusID | tinyint | NO | - | FK to Dictionary.InterestStatus |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StatusID | Dictionary.InterestStatus | FK | Interest processing state |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Syn_InterestDaily_July | - | Synonym | May point to this or the live InterestDaily |

---

## 6. Dependencies

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestStatus | Table | FK StatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Syn_InterestDaily_July | Synonym | May reference this archive table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InterestDaily | CLUSTERED | InterestDailyID | - | - | Active (PAGE compression) |
| UQ_InterestDaily | UNIQUE | CID, DayOfInterest | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| PK_InterestDaily | PRIMARY KEY | InterestDailyID |
| UQ_InterestDaily | UNIQUE | (CID, DayOfInterest) |
| FK StatusID | FOREIGN KEY | StatusID -> Dictionary.InterestStatus(StatusID) |

---

*Generated: 2026-03-14 | Quality: 7.0/10*
*Object: Trade.InterestDaily_July | Type: Table | Archive snapshot (empty)*
