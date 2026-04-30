# Billing.FundingCustomerRisk_OccurredCheck

> Checks whether a specific risk flag already exists for a customer-funding pair, returning a boolean output parameter.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsOccurred BIT OUT - 1 if flag exists, 0 if not |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingCustomerRisk_OccurredCheck` is a simple existence-check guard used to determine whether a particular risk event has already been recorded for a given customer-payment instrument combination. It queries `Billing.FundingCustomerRisk` for a specific (CID, FundingID, RiskStatusID) triple and returns 1 if that flag exists or 0 if it does not.

This procedure enables callers to implement idempotency and deduplication: before triggering a downstream action (such as sending a risk notification), the application checks whether the underlying risk event has already occurred. If it has, the action can be skipped to avoid duplicates.

The procedure is granted to `FundingUser` - the application service account used by the Billing/Funding service. All calls originate from application code, not from other SQL procedures. In practice, the only risk flag currently stored in `Billing.FundingCustomerRisk` is RiskStatusID=7 (DepositNameConflict), so live calls to this procedure almost exclusively pass @RiskStatusID=7.

---

## 2. Business Logic

### 2.1 Existence Check Pattern

**What**: A lightweight read-only check that avoids side effects - no INSERT, UPDATE, or DELETE.

**Columns/Parameters Involved**: `@CID`, `@FundingID`, `@RiskStatusID`, `@IsOccurred`

**Rules**:
- If a row exists in `Billing.FundingCustomerRisk` matching all three key columns, `@IsOccurred` is set to 1 (true).
- If no matching row exists, `@IsOccurred` is set to 0 (false).
- The check uses all three PK columns - it is NOT a partial match. A flag for (CID=100, FundingID=200, RiskStatusID=5) does NOT satisfy a query for (CID=100, FundingID=200, RiskStatusID=7).

**Diagram**:
```
Caller
  |
  | EXEC FundingCustomerRisk_OccurredCheck(@CID, @FundingID, @RiskStatusID, @IsOccurred OUT)
  v
IF EXISTS (SELECT * FROM Billing.FundingCustomerRisk
           WHERE CID=@CID AND FundingID=@FundingID AND RiskStatusID=@RiskStatusID)
  |
  +-- Yes --> SET @IsOccurred = 1  --> Caller skips duplicate action
  |
  +-- No  --> SET @IsOccurred = 0  --> Caller proceeds with action
```

### 2.2 Deduplication Guard in Notification Flow

**What**: Prevents duplicate risk notifications from being sent when the same (customer, payment instrument, risk type) combination triggers multiple events.

**Columns/Parameters Involved**: `@CID`, `@FundingID`, `@RiskStatusID`, `@IsOccurred`

**Rules**:
- The companion procedure `Billing.FundingCustomerRisk_Add` performs an idempotent INSERT (INSERT...EXCEPT SELECT) to create the flag.
- This procedure (`_OccurredCheck`) is used BEFORE the notification step, not before the INSERT step.
- Flow: risk event occurs -> `_Add` creates flag (idempotent) -> `_OccurredCheck` confirms flag exists -> application sends notification only once.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Identifies the customer whose risk flag is being checked. Matched against `Billing.FundingCustomerRisk.CID` (FK to Customer.CustomerStatic). |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | Payment instrument ID. Identifies the specific funding method (card, bank account, e-wallet) being checked. Matched against `Billing.FundingCustomerRisk.FundingID` (FK to Billing.Funding). |
| 3 | @RiskStatusID | INT | NO | - | CODE-BACKED | Risk classification to check for. In practice, always 7 (DepositNameConflict) in current live usage. Matched against `Billing.FundingCustomerRisk.RiskStatusID` (FK to Dictionary.RiskStatus). |
| 4 | @IsOccurred | BIT | - | - | CODE-BACKED | OUTPUT parameter. Set to 1 if the (CID, FundingID, RiskStatusID) risk flag exists in `Billing.FundingCustomerRisk`; set to 0 if it does not. Caller uses this to decide whether to proceed with a risk-triggered action. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.FundingCustomerRisk | Lookup | Reads by CID to check for existing risk flag |
| @FundingID | Billing.FundingCustomerRisk | Lookup | Reads by FundingID to check for existing risk flag |
| @RiskStatusID | Billing.FundingCustomerRisk | Lookup | Reads by RiskStatusID to scope check to a specific risk type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| FundingUser (DB role) | EXECUTE permission | Permission | Application service account for the Billing/Funding service has EXECUTE rights - calls originate from application code |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingCustomerRisk_OccurredCheck (procedure)
└── Billing.FundingCustomerRisk (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingCustomerRisk | Table | SELECTed in IF EXISTS check. All three key columns (CID, FundingID, RiskStatusID) used in WHERE clause. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| FundingUser application service | External (application) | Calls via EXEC to check existence of a risk flag before triggering downstream actions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses SET NOCOUNT ON. All parameters are required (no defaults). @IsOccurred is OUTPUT-only.

---

## 8. Sample Queries

### 8.1 Check if a DepositNameConflict flag exists for a customer-funding pair

```sql
DECLARE @IsOccurred BIT;
EXEC Billing.FundingCustomerRisk_OccurredCheck
    @CID = 12345,
    @FundingID = 67890,
    @RiskStatusID = 7,  -- DepositNameConflict
    @IsOccurred = @IsOccurred OUT;
SELECT @IsOccurred AS IsOccurred;
-- 1 = flag exists (notification already triggered), 0 = no flag (new event)
```

### 8.2 Inspect the underlying flag data for a customer

```sql
SELECT
    fcr.CID,
    fcr.FundingID,
    fcr.RiskStatusID,
    rs.Name AS RiskStatusName,
    fcr.Occurred,
    fcr.AlertFlag
FROM Billing.FundingCustomerRisk fcr WITH (NOLOCK)
JOIN Dictionary.RiskStatus rs WITH (NOLOCK)
    ON rs.RiskStatusID = fcr.RiskStatusID
WHERE fcr.CID = 12345
ORDER BY fcr.Occurred DESC;
```

### 8.3 Find all customers with DepositNameConflict flags on a specific funding instrument

```sql
SELECT
    fcr.CID,
    fcr.FundingID,
    fcr.Occurred,
    f.FundingTypeID,
    rs.Name AS RiskName
FROM Billing.FundingCustomerRisk fcr WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK)
    ON f.FundingID = fcr.FundingID
JOIN Dictionary.RiskStatus rs WITH (NOLOCK)
    ON rs.RiskStatusID = fcr.RiskStatusID
WHERE fcr.RiskStatusID = 7  -- DepositNameConflict
ORDER BY fcr.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingCustomerRisk_OccurredCheck | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingCustomerRisk_OccurredCheck.sql*
