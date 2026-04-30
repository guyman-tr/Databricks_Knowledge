# Customer.RafGetReferralHistory_NogaJunk210725

> Returns the referral history for a referring customer: all customers they referred with their current RAF status (WaitForEligibility, Expired, Completed, ReachMaxCompensation) and relevant status date.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT - the referring customer to query |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RafGetReferralHistory_NogaJunk210725` is the read-side of the RAF referral history API. Given a referring customer's CID, it returns each customer they referred with the current status of that referral relationship: whether the referred customer is still building toward eligibility, whether the window has expired, whether compensation was already paid, or whether the program's maximum compensation cap has been reached.

The procedure presents referral results sorted so completed referrals (paid) appear first, giving the customer a clear view of their most successful referrals before seeing pending or expired ones.

Status values are computed on-the-fly via CROSS APPLY: the procedure reads live data from `RAFGiven`, `RafEligibleCustomers`, and `CountryRafConfiguration` to determine current state. An expiration extension of 30 days (PART-1655, added June 2023) gives referred customers extra time beyond the configured `DaysToCheckMinPositionsAmountFromRegistration` window before a referral is marked expired.

The `_NogaJunk210725` suffix indicates this procedure was flagged for cleanup/refactoring by developer Noga in July 2025. The underlying logic remains production-active.

---

## 2. Business Logic

### 2.1 RAF Status Computation (Per Referred Customer)

**What**: Classifies each referred customer's RAF status based on compensation history, eligibility state, and expiration window.

**Columns/Parameters Involved**: `@CID`, `@Take`, `@ExpirationExtensionDays`, `raf.RowInserted`, `RE.RafStatus`, `ccrc.DaysToCheckMinPositionsAmountFromRegistration`, `cc.Registered`

**Rules**:
- Status 3 (Completed): `raf.RowInserted IS NOT NULL` - compensation has been paid to the referring customer.
- Status 4 (ReachMaxCompensation): `RE.RafStatus = 4` in `RafEligibleCustomers` - pair reached the program's compensation cap.
- Status 1 (WaitForEligibility): `DaysToCheckMinPositionsAmountFromRegistration = 0` (no position requirement) OR the expiration deadline (registration date + configured days + 30 extension days) is still in the future.
- Status 2 (Expired): The position-window deadline has passed (beyond `DaysToCheckMinPositionsAmountFromRegistration + 30` days from registration).

```
CROSS APPLY status resolution:
  IF raf.RowInserted IS NOT NULL     -> StatusID = 3 (Completed)
  ELIF RE.RafStatus = 4              -> StatusID = 4 (ReachMaxCompensation)
  ELIF DaysToCheck = 0 OR
       DATEADD(days, DaysToCheck+30, cc.Registered) > NOW  -> StatusID = 1 (WaitForEligibility)
  ELSE                               -> StatusID = 2 (Expired)
```

### 2.2 Display Ordering (Completed-First)

**What**: Referred customers who have completed RAF appear first; expired appear last.

**Rules**:
- `OrderID` derivation: Completed(3)->1, WaitForEligibility(1)->2, Expired(2)->3, ReachMaxCompensation(4)->4.
- ORDER BY OrderID ASC, CID DESC - most recently registered referred customer within each status group appears first.
- `OPTION(RECOMPILE)` on the main query - per-execution plan due to parameter-sensitive join pattern.

### 2.3 StatusDate Interpretation

**What**: Each status carries a date that contextualizes the status for the customer.

**Rules**:
- StatusID=1 (WaitForEligibility): `cc.Registered` - the referred customer's registration date (start of the eligibility window).
- StatusID=2 (Expired): `DATEADD(day, DaysToCheckMinPositionsAmountFromRegistration, cc.Registered)` - when the window closed.
- StatusID=3 (Completed): `raf.RowInserted` - date compensation was issued.
- StatusID=4: No StatusDate (NULL via CASE fall-through).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The referring customer's CID. All customers where Customer.Customer.ReferralID = @CID are returned as the referred set. |
| 2 | @Take | INT | YES | 50 | CODE-BACKED | Maximum rows to return (SELECT TOP(@Take)). Defaults to 50. Controls result set size for pagination. |

**Returned Columns:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | GCID | Customer.Customer.GCID | Global ID of the referred customer |
| 2 | CID | Customer.Customer.CID | Internal ID of the referred customer |
| 3 | ReferringCompensationAmount | Customer.RAFGiven.ReferringCompensationAmount | Amount the referring customer received for this referral; 0 if not yet compensated |
| 4 | StatusID | Computed (CROSS APPLY) | Current RAF status: 1=WaitForEligibility, 2=Expired, 3=Completed, 4=ReachMaxCompensation |
| 5 | StatusDate | Computed (CASE) | Date contextualizing the status: registration date, expiration date, or compensation date depending on StatusID |
| 6 | OrderID | Computed | Sort key: Completed(3)->1, WaitFor(1)->2, Expired(2)->3, MaxComp(4)->4 |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | READ | Finds all referred customers (WHERE ReferralID = @CID); reads GCID, CID, Registered |
| (status check) | Customer.RAFGiven | READ (LEFT JOIN) | Checks if compensation was paid to the referring party |
| (status check) | Customer.RafEligibleCustomers | READ (LEFT JOIN) | Checks RafStatus=4 (ReachMaxCompensation) |
| (config) | Customer.CountryRafConfiguration | READ (INNER JOIN) | Gets DaysToCheckMinPositionsAmountFromRegistration for expiration calc |
| (validation) | BackOffice.Customer | READ (INNER JOIN) | Gets DesignatedRegulationID to match RAF configuration |
| (validation) | Dictionary.Country | READ (INNER JOIN) | Filters: CountryID > 0 and IsEligibleForRAFBonusCountry = 1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RAF API / microservice | External call | Caller | Provides referral history data for the "My Referrals" feature |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RafGetReferralHistory_NogaJunk210725 (procedure)
├── Customer.Customer (view) [READ - referred set + identity]
├── Customer.RAFGiven (table) [READ - compensation paid check]
├── Customer.RafEligibleCustomers (table) [READ - ReachMaxCompensation check]
├── Customer.CountryRafConfiguration (table) [READ - expiration days config]
├── BackOffice.Customer (table) [READ - DesignatedRegulationID]
└── Dictionary.Country (table) [READ - IsEligibleForRAFBonusCountry filter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | READ - main data source for referred customers |
| Customer.RAFGiven | Table | READ - LEFT JOIN to determine Completed status |
| Customer.RafEligibleCustomers | Table | READ - LEFT JOIN for ReachMaxCompensation (RafStatus=4) |
| Customer.CountryRafConfiguration | Table | READ - INNER JOIN for position window days |
| BackOffice.Customer | Table | READ - INNER JOIN for DesignatedRegulationID |
| Dictionary.Country | Table | READ - INNER JOIN, filter IsEligibleForRAFBonusCountry=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RAF service / "My Referrals" API | External | Calls to display referral history to the referring customer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @ExpirationExtensionDays = 30 | Application | Hard-coded 30-day grace period added to configured expiration window (PART-1655) |
| Country eligibility guard | Application | INNER JOIN Dictionary.Country WHERE IsEligibleForRAFBonusCountry=1 - non-eligible country customers are excluded |
| OPTION(RECOMPILE) | Performance | Forces per-execution query plan to handle @CID parameter sensitivity on large joins |
| @Take TOP | Application | Limits result set - default 50 rows, prevents unbounded return for heavy referrers |

---

## 8. Sample Queries

### 8.1 Check referral history for a specific referring CID

```sql
EXEC Customer.RafGetReferralHistory_NogaJunk210725 @CID = 12345, @Take = 50
```

### 8.2 Count referrals by status for a referring customer

```sql
SELECT
    RS.StatusID,
    CASE RS.StatusID
        WHEN 1 THEN 'WaitForEligibility'
        WHEN 2 THEN 'Expired'
        WHEN 3 THEN 'Completed'
        WHEN 4 THEN 'ReachMaxCompensation'
    END AS StatusName,
    COUNT(*) AS ReferralCount
FROM Customer.Customer cc WITH (NOLOCK)
LEFT JOIN Customer.RAFGiven raf WITH (NOLOCK)
    ON raf.ReferredCID = cc.CID AND raf.ReferringCID = cc.ReferralID
LEFT JOIN Customer.RafEligibleCustomers RE WITH (NOLOCK)
    ON RE.ReferredCID = cc.CID
JOIN Customer.CountryRafConfiguration ccrc WITH (NOLOCK)
    ON cc.CountryID = ccrc.CountryID
JOIN BackOffice.Customer bc WITH (NOLOCK) ON bc.CID = cc.CID
    AND bc.DesignatedRegulationID = ccrc.RegulationID
CROSS APPLY (
    SELECT CASE
        WHEN raf.RowInserted IS NOT NULL THEN 3
        WHEN RE.RafStatus = 4 THEN 4
        WHEN ISNULL(ccrc.DaysToCheckMinPositionsAmountFromRegistration, 0) = 0
          OR DATEADD(day, ccrc.DaysToCheckMinPositionsAmountFromRegistration + 30, cc.Registered) > GETUTCDATE() THEN 1
        ELSE 2
    END AS StatusID
) AS RS
WHERE cc.ReferralID = 12345
GROUP BY RS.StatusID
```

### 8.3 Find referring customers with the most completed referrals

```sql
SELECT TOP 20
    raf.ReferringCID,
    COUNT(*) AS CompletedReferrals,
    SUM(raf.ReferringCompensationAmount) AS TotalCompensation
FROM Customer.RAFGiven raf WITH (NOLOCK)
GROUP BY raf.ReferringCID
ORDER BY CompletedReferrals DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| PART-1655 | Jira | Added @ExpirationExtensionDays=30 grace period to avoid premature expiry |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RafGetReferralHistory_NogaJunk210725 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RafGetReferralHistory_NogaJunk210725.sql*
