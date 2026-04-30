# Dictionary.VerificationLevel

> Lookup table defining the four tiers of customer identity verification (Level 0-3) that progressively unlock platform capabilities — from basic registration through full KYC-verified status with complete trading and withdrawal access.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, manually assigned) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 clustered (PK on ID) |

---

## 1. Business Meaning

Dictionary.VerificationLevel defines the progressive identity verification tiers that customers pass through as they complete KYC (Know Your Customer) requirements. Each level represents a milestone in the verification journey, unlocking additional platform capabilities. Level 0 is the starting state (unverified), while Level 3 represents full verification with all trading and withdrawal privileges.

Without this table, the platform could not enforce tiered access based on verification status. Regulatory requirements (MiFID II, ASIC, CySEC) mandate that certain operations (large withdrawals, leveraged trading, real stock purchases) are restricted until identity verification reaches a minimum threshold. This table provides the classification system that drives those restrictions.

The table is one of the most heavily referenced Dictionary tables, consumed by 60+ procedures across BackOffice, Customer, Billing, Compliance, DWH, and SalesForce schemas. Key consumers include: BackOffice.ChangeCustomerVerificationLevel (level transitions), BackOffice.AddKYC/KycAddILQ (KYC document processing), BackOffice.GetCustomerByCID/GetCustomerHeader (customer profile display), BackOffice.GetUnapprovedWithdrawRequests (verification-aware withdrawal filtering), and multiple compliance/risk reporting procedures.

---

## 2. Business Logic

### 2.1 Progressive Verification Tiers

**What**: Customers advance through verification levels as they submit and pass identity checks, each level unlocking more platform features.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- Level 0 — baseline state after registration, minimal platform access, severe restrictions on withdrawals and trading
- Level 1 — basic verification complete (e.g., email confirmed, basic questionnaire), allows limited trading
- Level 2 — intermediate verification (e.g., POI document submitted), allows moderate trading and some withdrawals
- Level 3 — full KYC verification (POI + POA confirmed), full platform access including unlimited withdrawals and all instrument types
- Transitions are managed by BackOffice.ChangeCustomerVerificationLevel and tracked in BackOffice.Customer.VerificationLevelID
- The level is checked by 60+ procedures to gate operations: withdrawal limits, trading instrument access, deposit processing, and compliance reporting

**Diagram**:
```
Verification Level Progression:
  ┌────────────┐    Email/basic    ┌────────────┐
  │  Level 0   │  ──────────────►  │  Level 1   │
  │ Unverified │     verified      │   Basic    │
  └────────────┘                   └────────────┘
                                         │
                                   POI submitted
                                         ▼
                                   ┌────────────┐
                                   │  Level 2   │
                                   │Intermediate│
                                   └────────────┘
                                         │
                                   POI+POA confirmed
                                         ▼
                                   ┌────────────┐
                                   │  Level 3   │
                                   │ Full KYC   │
                                   └────────────┘
```

### 2.2 Verification-Gated Operations

**What**: Different platform operations require minimum verification levels.

**Columns/Parameters Involved**: `ID` (checked against BackOffice.Customer.VerificationLevelID)

**Rules**:
- Withdrawal processing (Billing.RedeemPayoutProcess) checks verification level before releasing funds
- Risk reporting (BackOffice.GetRiskExposureReportPCIVersion) segments customers by verification level
- Compliance reports (Compliance.GetPOADocumentsExpirationPopulation) target specific levels for document renewal
- Economic reports (DWH.SP_Economic_Report) use verification level as a segmentation dimension

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | Level 0 | Unverified — customer has registered but completed no identity checks. Severe restrictions on trading and withdrawals. Must advance to access most platform features. |
| 1 | Level 1 | Basic verification — minimal identity confirmation complete. Allows limited trading access; withdrawal limits may apply. First step in the KYC journey. |
| 2 | Level 2 | Intermediate verification — primary identity document (POI) submitted or under review. Moderate trading access with some restrictions on advanced features. |
| 3 | Level 3 | Full KYC verification — all required documents (POI + POA) confirmed. Unlocks complete platform access: unlimited withdrawals, all instrument types, leveraged trading, real stock purchases. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Verification tier identifier: 0=Unverified, 1=Basic, 2=Intermediate, 3=Full KYC. Stored on BackOffice.Customer.VerificationLevelID and checked by 60+ procedures to gate trading, withdrawals, and compliance operations. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Display label for the verification tier: "Level 0" through "Level 3". Used in BackOffice UI, compliance reports, and customer headers. Nullable by DDL but all current values are populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | VerificationLevelID | Implicit | Each customer's current verification tier |
| History.BackOfficeCustomer | VerificationLevelID | Implicit | Historical record of customer verification levels |
| BackOffice.MassVerificationRecords | VerificationLevelID | Implicit | Bulk verification update records |
| BackOffice.ChangeCustomerVerificationLevel | @VerificationLevelID | Reader | Transitions customer between levels |
| BackOffice.CustomerGetVerificationLevelID | (return) | Reader | Retrieves current level for a customer |
| BackOffice.AddKYC | VerificationLevelID | Reader | Checks/updates level during KYC processing |
| BackOffice.GetCustomerByCID | VerificationLevelID | Reader | Returns level in customer profile |
| BackOffice.GetRiskExposureReportPCIVersion | VerificationLevelID | Reader | Segments risk reports by verification |
| Billing.RedeemPayoutProcess_GetNewRecords | VerificationLevelID | Reader | Filters withdrawals by verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.VerificationLevel (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Stores VerificationLevelID per customer |
| BackOffice.ChangeCustomerVerificationLevel | Stored Procedure | Manages level transitions |
| BackOffice.AddKYC | Stored Procedure | Updates level during document processing |
| BackOffice.GetCustomerByCID | Stored Procedure | Returns level in customer lookup |
| BackOffice.GetRiskExposureReportPCIVersion | Stored Procedure | Risk reporting by verification tier |
| Compliance.GetPOADocumentsExpirationPopulation | Stored Procedure | Targets specific levels for document renewal |
| Billing.RedeemPayoutProcess_GetNewRecords | Stored Procedure | Verification-gated withdrawal processing |
| 50+ additional procedures | Various | Verification level checks across the platform |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_VerificationLevel_ID | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all verification levels
```sql
SELECT  ID AS VerificationLevelID,
        Name
FROM    [Dictionary].[VerificationLevel] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Resolve a customer's verification level to its label
```sql
SELECT  c.CustomerID,
        vl.Name AS VerificationLevel
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[VerificationLevel] vl WITH (NOLOCK)
        ON vl.ID = c.VerificationLevelID
WHERE   c.CustomerID = 12345;
```

### 8.3 Count customers per verification level
```sql
SELECT  vl.Name AS VerificationLevel,
        COUNT(*) AS CustomerCount
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[VerificationLevel] vl WITH (NOLOCK)
        ON vl.ID = c.VerificationLevelID
GROUP BY vl.ID, vl.Name
ORDER BY vl.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 60+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.VerificationLevel | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.VerificationLevel.sql*
