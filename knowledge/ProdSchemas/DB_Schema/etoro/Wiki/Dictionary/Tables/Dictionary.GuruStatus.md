# Dictionary.GuruStatus

> Lookup table defining the 9 Popular Investor (Guru) program states — from non-participant through Cadet, Rising Star, Champion, Elite, and Elite Pro tiers, plus Removed and Rejected terminal states.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | GuruStatusID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 9 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.GuruStatus defines the lifecycle states of eToro's Popular Investor (PI) program — a key business feature where successful traders are rewarded for allowing others to copy their trades. The program has a structured tier progression: traders start as non-participants (No, 0), apply to become Cadets (2), progress through Rising Star (3), Champion (4), Elite (5), and Elite Pro (6) based on performance criteria, or may be Certified (1) as a legacy/alternative status. Traders can be Removed (7) for violations or Rejected (8) if their application is denied.

The GuruStatus is stored on BackOffice.Customer and determines: withdrawal fee exemptions (via Billing.GuruStatusToCashoutFeeGroup mapping), copy-trading eligibility, PI payment processing, and reporting categorization. Higher PI tiers earn higher compensation percentages from the AUM (Assets Under Management) of their copiers.

The status is frequently filtered in business logic: `GuruStatusID IN (2,3,4,5)` captures active program participants (Cadet through Elite), while `GuruStatusID IN (2,3,4,5,6)` includes Elite Pro. `GuruStatusID = 0` is used to exclude non-PIs from PI-specific features and reports.

---

## 2. Business Logic

### 2.1 Popular Investor Tier Progression

**What**: The PI program tier structure and progression.

**Columns/Parameters Involved**: `GuruStatusID`, `Name`

**Rules**:
- **No (0)**: Not a Popular Investor. Default state for all customers. No PI benefits or obligations.
- **Certified (1)**: Legacy or directly certified Popular Investor. May bypass the standard tier progression.
- **Cadet (2)**: Entry-level PI tier. Trader has been accepted into the program and is building a track record. Minimum requirements met.
- **Rising Star (3)**: Second PI tier. Demonstrating consistent performance and attracting copiers. Increased compensation.
- **Champion (4)**: Third PI tier. Established track record, significant AUM from copiers. Higher compensation rate.
- **Elite (5)**: Top-tier PI. Exceptional performance, large copier base. Premium compensation and exclusive benefits.
- **Elite Pro (6)**: Highest PI tier. Reserved for the very top performers. Maximum compensation rate.
- **Removed (7)**: Removed from the PI program. May be due to performance deterioration, rule violations, or account issues. Terminal state (can be re-admitted as Cadet).
- **Rejected (8)**: Application to the PI program was denied. Criteria not met. Terminal state (can re-apply).

**Diagram**:
```
Popular Investor Program Lifecycle:

  No (0) ──► Application ──► Cadet (2) ──► Rising Star (3) ──► Champion (4)
                  │                                                   │
                  │                                          Elite (5) ──► Elite Pro (6)
                  │
                  ├──► Rejected (8)         [application denied]
                  │
                  └──► Certified (1)        [legacy/direct entry]

  Any Active Tier ──► Removed (7)           [violations/performance]
```

### 2.2 Impact on Cashout Fees

**What**: How GuruStatus drives withdrawal fee exemptions.

**Columns/Parameters Involved**: `GuruStatusID`

**Rules**:
- Billing.GuruStatusToCashoutFeeGroup maps each GuruStatusID to a CashoutFeeGroupID
- Active PIs (higher tiers) typically mapped to Exempt or Discount fee groups
- Billing.ProcessCashoutFeeGroupUpdate recalculates fee group when GuruStatus changes
- Fee group affects actual withdrawal fees via Trade.CashoutRange

### 2.3 Business Logic Filtering Patterns

**What**: Common filtering patterns for PI-related queries.

**Columns/Parameters Involved**: `GuruStatusID`

**Rules**:
- `GuruStatusID = 0`: Exclude non-PIs (Customer.CheckFraudUsers)
- `GuruStatusID IN (2,3,4,5)`: Active PI tiers — Cadet through Elite (Trade.CheckListOfManuallPositions)
- `GuruStatusID IN (2,3,4,5,6)`: All active tiers including Elite Pro (History.GetFaultedPIBonusFlow)

---

## 3. Data Overview

| GuruStatusID | Name | Meaning |
|---|---|---|
| 0 | No | Not a Popular Investor. Default for all customers. No PI program participation, no PI benefits, standard fees apply. Most common status. |
| 1 | Certified | Legacy/directly certified Popular Investor. May have entered the program before the tiered structure was introduced, or certified through an alternative path. |
| 2 | Cadet | Entry-level PI tier. Accepted into the program, building track record and copier base. Minimum AUM and performance criteria met. Included in active PI queries (IN 2,3,4,5). |
| 3 | Rising Star | Second PI tier. Consistent performance, growing copier base. Higher compensation than Cadet. Included in active PI queries. |
| 4 | Champion | Third PI tier. Established performance record, significant copier AUM. Premium compensation rate. Included in active PI queries. |
| 5 | Elite | Top PI tier. Exceptional long-term performance, large copier base. Premium compensation and exclusive benefits. Included in active PI queries. |
| 6 | Elite Pro | Highest PI tier. Reserved for the best-performing PIs with the largest AUM. Maximum compensation rate. Included in extended PI queries (IN 2,3,4,5,6). |
| 7 | Removed | Removed from the PI program. Triggered by performance deterioration, rule violations, or account issues. Terminal state — must re-apply as Cadet to rejoin. |
| 8 | Rejected | PI application denied. Criteria not met during application review. Terminal state — can re-apply after addressing deficiencies. Note: trailing space in production data ("Rejected "). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GuruStatusID | int | NO | - | VERIFIED | Primary key identifying the PI program state. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. Referenced by BackOffice.Customer (FK), Billing.GuruStatusToCashoutFeeGroup (FK). Filtered as IN (2,3,4,5) for active PIs or IN (2,3,4,5,6) including Elite Pro. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Note: "Rejected" has trailing space in production data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | GuruStatusID | Explicit FK | Customer's current PI status |
| History.BackOfficeCustomer | GuruStatusID | Explicit FK | Historical PI status snapshots |
| Billing.GuruStatusToCashoutFeeGroup | GuruStatusID | Explicit FK | Maps PI tier to fee group |
| History.GuruStatusToCashoutFeeGroup | GuruStatusID | History table | Historical fee group mapping |
| BackOffice.AccountUserInfo | GuruStatusId | UDT column | TVP for bulk account updates |
| BackOffice.CustomerSafty | GuruStatusID | View SELECT | Schema-bound customer view |
| BackOffice.CustomerSetGuruStatus | @GuruStatusID | Parameter UPDATE | Sets PI status |
| BackOffice.Bulk_UpdateAccountUserInfoRemote | GuruStatusID | UPDATE from TVP | Bulk PI status updates |
| BackOffice.GetCustomerByCID | GuruStatusID | SELECT | Customer lookup returns PI status |
| Billing.ProcessCashoutFeeGroupUpdate | @GuruStatusID | Parameter, SELECT | Fee group recalculation on PI change |
| Customer.UpdateAccountUserInfoRemote | @guruStatusID | Parameter UPDATE | Remote PI status update |
| Customer.DynamicsInsert | GuruStatusID | SELECT | Dynamics CRM integration |
| Trade.GetUserInfo | GuruStatusID | SELECT | Trading user info includes PI status |
| Trade.GetUserInfoByGCIDs | GuruStatusID | SELECT | Batch user info includes PI status |
| Trade.GetCustomersDataWithCopyRestirctions | GuruStatusID | Output | Copy restriction data includes PI status |
| Trade.CheckListOfManuallPositions | GuruStatusID | WHERE IN (2,3,4,5) | Checks manual positions for active PIs |
| SalesForce.GetBackOfficeCustomer | GuruStatusID | SELECT | SalesForce integration |
| History.GetFaultedPIBonusFlow | GuruStatusID | WHERE IN (2,3,4,5,6) | PI bonus fault detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GuruStatus (table)
  └── referenced by BackOffice.Customer (FK)
  └── referenced by Billing.GuruStatusToCashoutFeeGroup (FK)
  └── consumed by 15+ procedures across BackOffice, Billing, Customer, Trade, SalesForce
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FK — customer's PI status |
| Billing.GuruStatusToCashoutFeeGroup | Table | FK — maps PI tier to fee group |
| History.BackOfficeCustomer | Table | FK — historical snapshots |
| BackOffice.CustomerSetGuruStatus | Stored Procedure | Sets PI status |
| Billing.ProcessCashoutFeeGroupUpdate | Stored Procedure | Fee group recalculation |
| Customer.UpdateAccountUserInfoRemote | Stored Procedure | Remote PI status update |
| Trade.GetUserInfo | Stored Procedure | Returns PI status |
| Trade.CheckListOfManuallPositions | Stored Procedure | Filters active PIs |
| SalesForce.GetBackOfficeCustomer | Stored Procedure | CRM integration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_GuruStatusID | CLUSTERED PK | GuruStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_GuruStatusID | PRIMARY KEY | Unique PI status identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all PI statuses
```sql
SELECT  GuruStatusID,
        Name
FROM    Dictionary.GuruStatus WITH (NOLOCK)
ORDER BY GuruStatusID;
```

### 8.2 Count customers by PI tier
```sql
SELECT  dgs.Name            AS PITier,
        COUNT(*)            AS CustomerCount
FROM    BackOffice.Customer boc WITH (NOLOCK)
JOIN    Dictionary.GuruStatus dgs WITH (NOLOCK)
        ON boc.GuruStatusID = dgs.GuruStatusID
WHERE   boc.GuruStatusID > 0  -- exclude non-PIs
GROUP BY dgs.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Find active Popular Investors with their fee group
```sql
SELECT  boc.CID,
        dgs.Name            AS PITier,
        dcfg.Name           AS FeeGroup
FROM    BackOffice.Customer boc WITH (NOLOCK)
JOIN    Dictionary.GuruStatus dgs WITH (NOLOCK)
        ON boc.GuruStatusID = dgs.GuruStatusID
JOIN    Dictionary.CashoutFeeGroup dcfg WITH (NOLOCK)
        ON boc.CashoutFeeGroupID = dcfg.CashoutFeeGroupID
WHERE   boc.GuruStatusID IN (2, 3, 4, 5, 6)
ORDER BY boc.GuruStatusID, boc.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data (9 statuses) and codebase analysis across 15+ procedures in BackOffice, Billing, Customer, Trade, and SalesForce schemas.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GuruStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.GuruStatus.sql*
