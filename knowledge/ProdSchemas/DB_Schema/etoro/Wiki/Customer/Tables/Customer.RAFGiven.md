# Customer.RAFGiven

> Immutable record of confirmed Refer-A-Friend compensation events: one row per successful referral payout, recording the referring and referred customer pair plus the dollar amounts paid to each.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, PK); ReferredCID (UNIQUE) |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR=95, PAGE compression) |
| **Indexes** | 3 (clustered PK + UNIQUE NC on ReferredCID + UNIQUE NC on ReferringCID+ReferredCID) |

---

## 1. Business Meaning

Customer.RAFGiven is the permanent ledger of completed Refer-A-Friend (RAF) bonuses. Each row confirms that a referring customer (ReferringCID) successfully invited a referred customer (ReferredCID) who met all program conditions, and that both parties received their compensation payments. Once a row exists here, it also serves as a deduplication gate: Customer.SetRafCompensation counts rows by ReferringCID and refuses to process more if the count reaches @MaxNumberOfCompensations (the program's per-customer limit).

The UNIQUE constraint on ReferredCID enforces a fundamental business rule: each referred customer can only generate ONE referral bonus (they can only be referred once). A new customer cannot be referred by multiple people and generate multiple payouts.

Data flows: Customer.SetRafCompensation is the sole writer. Before inserting, it: (1) validates the (Referring, Referred) pair via Customer.Customer.ReferralID; (2) acquires a concurrency lock via Customer.RafCIDInProcess; (3) checks if @MaxNumberOfCompensations is reached; (4) calls Customer.SetBalanceCompensation for both parties (BonusTypeID=53 for referring, 54 for referred); (5) inserts into RAFGiven with amounts in dollars (cents/100). The table currently has 142 rows dated 2017-2025 on this environment - indicating this is an active production-adjacent environment with a small RAF program.

---

## 2. Business Logic

### 2.1 Per-Referrer Compensation Cap Enforcement

**What**: RAFGiven acts as the counter for how many successful referrals a referring customer has made, enforcing the program's maximum payout limit.

**Columns/Parameters Involved**: `ReferringCID`, `ID`

**Rules**:
- Customer.SetRafCompensation: `SELECT @CountRAFCompensations=COUNT(*) FROM RAFGiven WHERE ReferringCID=@ReferringCID`
- If @CountRAFCompensations >= @MaxNumberOfCompensations -> RETURN 2 (limit reached, no payment made)
- MaxNumberOfCompensations is passed per call from the RAF orchestration process (configurable)
- This pattern means the table is queried on every potential RAF compensation, so the NC index on (ReferringCID, ReferredCID) supports this count efficiently

### 2.2 One Referred Customer Per RAF

**What**: The UNIQUE constraint on ReferredCID ensures each new customer generates at most one RAF bonus, regardless of how many potential referrers claim credit.

**Columns/Parameters Involved**: `ReferredCID`

**Rules**:
- UQ_RAFGiven_ReferredCID: UNIQUE NONCLUSTERED on ReferredCID
- First call that successfully completes SetRafCompensation for a ReferredCID wins
- Subsequent attempts for the same ReferredCID with a different ReferringCID would result in a duplicate key violation at the INSERT step
- The concurrency lock (RafCIDInProcess) prevents simultaneous processing for the same ReferringCID but not for the same ReferredCID - the UNIQUE index is the final guard

---

## 3. Data Overview

| ID | ReferringCID | ReferredCID | ReferringCompensationAmount | ReferredCompensationAmount | RowInserted | Meaning |
|----|-------------|------------|---------------------------|--------------------------|-------------|---------|
| (recent) | CID | CID | up to 500 | up to 20 | 2025-08-28 | Most recent RAF payout: referring party got up to $500, referred got up to $20 |
| (oldest) | CID | CID | varies | varies | 2017-01-04 | First RAF recorded in this environment - program running since 2017 |

*142 total rows. Date range: 2017-01-04 to 2025-08-28. Max ReferringCompensationAmount=500 ($500), Max ReferredCompensationAmount=20 ($20). Amounts stored in whole dollars (converted from cents by dividing by 100 in SetRafCompensation).*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReferringCID | int | NO | - | VERIFIED | The customer who made the referral (the inviter). Not a formal FK but references Customer.CustomerStatic. Validated via Customer.Customer.ReferralID check in SetRafCompensation. Part of UNIQUE constraint with ReferredCID. Indexed together for fast count queries during compensation checks. |
| 2 | ReferredCID | int | NO | - | VERIFIED | The newly registered customer who was referred (the invitee). UNIQUE constraint (UQ_RAFGiven_ReferredCID) enforces one-referral-per-referred-customer. The pair (ReferredCID, ReferralID=ReferringCID) is validated in Customer.Customer before compensation is granted. |
| 3 | RowInserted | datetime | YES | getutcdate() | VERIFIED | UTC timestamp when the RAF compensation was successfully processed and this record was inserted. Defaults to GETUTCDATE()-3ms (`DATEADD(MS, -3, GETUTCDATE())`) - the -3ms offset appears to be a workaround comment in SetRafCompensation ("make sure RowInserted is valid"). |
| 4 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. IDENTITY NOT FOR REPLICATION. Provides a unique row identifier and the clustered index key. Not meaningful for business logic (use ReferredCID or (ReferringCID, ReferredCID) for lookups). |
| 5 | ReferringCompensationAmount | int | YES | - | VERIFIED | Dollar amount paid to the referring customer as RAF bonus. Stored as whole dollars (converted from cents by dividing @ReferringCompensationInCents/100 in SetRafCompensation). Max observed: $500. NULL if referring party received no compensation (ReferringCompensationInCents=0 path skips SetBalanceCompensation but still inserts). |
| 6 | ReferredCompensationAmount | int | YES | - | VERIFIED | Dollar amount paid to the referred customer as RAF bonus. Stored as whole dollars. Max observed: $20. NULL if referred party received no compensation. Both compensation amounts are set via Customer.SetBalanceCompensation (BonusTypeID=53=Referring, BonusTypeID=54=Referred). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReferringCID | Customer.CustomerStatic | Implicit (no FK enforced) | References the referring customer; validated programmatically via Customer.Customer.ReferralID |
| ReferredCID | Customer.CustomerStatic | Implicit (no FK enforced) | References the referred customer; one-per-referred enforced by UNIQUE index |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetRafCompensation | ReferringCID, ReferredCID | Writer + Reader | Primary write path; also reads COUNT(*) by ReferringCID to enforce per-referrer cap |
| Customer.RafViewCustomerStatus_NogaJunk210725 | ReferringCID, ReferredCID | View (Reader) | Checks if compensation was already given for a referral pair |
| Customer.RafGetByReferedGCIDs | ReferredCID | Reader | Returns RAF records by referred customer GCIDs |
| Customer.RafGetReferralHistory_NogaJunk210725 | ReferringCID | Reader | Returns full referral history for a referring customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RAFGiven (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| No dependencies. | - | No FKs enforced; relationships are implicit |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetRafCompensation | Stored Procedure | Writer + Reader (cap check) |
| Customer.RafViewCustomerStatus_NogaJunk210725 | View | Reader - RAF status check |
| Customer.RafGetByReferedGCIDs | Stored Procedure | Reader |
| Customer.RafGetReferralHistory_NogaJunk210725 | Stored Procedure | Reader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_RAFGiven | Clustered PK | ID ASC | - | - | Active |
| UQ_RAFGiven_ReferredCID | Unique NC | ReferredCID ASC | - | - | Active |
| UQ_RAFGiven_ReferringCIDReferredCID | Unique NC | ReferringCID ASC, ReferredCID ASC | - | - | Active |

*PK name "PK_Billing_RAFGiven" retains "Billing" prefix from its original Billing schema origin. PAGE compression on the clustered index.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BillingRAFGivenRowInserted | DEFAULT | RowInserted = getutcdate() |
| UQ_RAFGiven_ReferredCID | UNIQUE | One RAF payout per referred customer (a customer can only be referred once) |
| UQ_RAFGiven_ReferringCIDReferredCID | UNIQUE | Each (referrer, referred) pair can only have one RAF record |

---

## 8. Sample Queries

### 8.1 Get RAF history for a specific referring customer
```sql
SELECT
    rg.ID,
    rg.ReferringCID,
    rg.ReferredCID,
    rg.ReferringCompensationAmount,
    rg.ReferredCompensationAmount,
    rg.RowInserted
FROM Customer.RAFGiven rg WITH (NOLOCK)
WHERE rg.ReferringCID = 12345
ORDER BY rg.RowInserted DESC;
```

### 8.2 Check RAF compensation cap status for a customer
```sql
SELECT
    ReferringCID,
    COUNT(*) AS CompensationsGiven,
    SUM(ReferringCompensationAmount) AS TotalPaidToReferrer,
    MIN(RowInserted) AS FirstRAF,
    MAX(RowInserted) AS LastRAF
FROM Customer.RAFGiven WITH (NOLOCK)
WHERE ReferringCID = 12345
GROUP BY ReferringCID;
```

### 8.3 Find top referrers by number of successful referrals
```sql
SELECT TOP 20
    rg.ReferringCID,
    cs.UserName,
    COUNT(*) AS TotalReferrals,
    SUM(rg.ReferringCompensationAmount) AS TotalEarned,
    MAX(rg.RowInserted) AS LastReferral
FROM Customer.RAFGiven rg WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = rg.ReferringCID
GROUP BY rg.ReferringCID, cs.UserName
ORDER BY TotalReferrals DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (SetRafCompensation, RAFCompensationProcess) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.RAFGiven | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.RAFGiven.sql*
