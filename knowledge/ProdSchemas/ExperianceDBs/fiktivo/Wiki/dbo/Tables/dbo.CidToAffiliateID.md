# dbo.CidToAffiliateID

> Mapping table that links Customer IDs (CIDs) to their associated affiliate IDs, tracking both mobile and previous affiliate attributions.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, no PK - heap table) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

This table maintains the mapping between customer identifiers (CIDs) and the affiliates that referred them. It is a key component of the affiliate attribution system - when a customer registers or takes action on the platform, this mapping determines which affiliate receives credit (and commission) for that customer's activity.

The table tracks two attribution dimensions: the mobile affiliate attribution (MobileAffiliateID) for customers acquired through mobile channels, and the previous affiliate attribution (PrevAffiliateID) for customers whose affiliate assignment changed over time. The OriginalCID column supports scenarios where a customer's ID was remapped (e.g., account migration).

Without this table, the system would have no way to attribute customer activity to the correct affiliate for commission calculation. It sits at the intersection of customer management (external) and affiliate commission tracking (internal).

The table is currently empty (0 rows in this environment), suggesting it may be populated via ETL from an external system or used only in specific operational scenarios.

---

## 2. Business Logic

### 2.1 Dual Attribution Tracking

**What**: Tracks both current (mobile) and historical (previous) affiliate attributions for each customer.

**Columns/Parameters Involved**: `CID`, `MobileAffiliateID`, `PrevAffiliateID`

**Rules**:
- MobileAffiliateID represents the affiliate credited for mobile channel acquisition
- PrevAffiliateID preserves the prior affiliate assignment when a customer's attribution changes
- When both are populated, it indicates an affiliate reassignment occurred
- All columns are nullable, allowing partial attribution records

### 2.2 CID Remapping

**What**: Supports customer ID remapping during account migrations.

**Columns/Parameters Involved**: `CID`, `OriginalCID`

**Rules**:
- CID is the current customer identifier used in the platform
- OriginalCID is the customer's ID before migration/remapping
- When CID != OriginalCID, the customer underwent an account migration

---

## 3. Data Overview

Table is empty (0 rows) in this environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID - the platform's primary identifier for a customer/trader. Used to look up which affiliate should receive commission for this customer's activity. |
| 2 | OriginalCID | int | YES | - | CODE-BACKED | Original Customer ID before any account migration or remapping. When equal to CID, no migration occurred. When different, the customer was migrated from OriginalCID to CID. |
| 3 | MobileAffiliateID | int | YES | - | CODE-BACKED | The affiliate ID credited for acquiring this customer through a mobile channel. References dbo.tblaff_Affiliates.AffiliateID (implicit). |
| 4 | PrevAffiliateID | int | YES | - | CODE-BACKED | The affiliate ID that was previously credited for this customer before a reassignment. Preserves attribution history for audit and dispute resolution. References dbo.tblaff_Affiliates.AffiliateID (implicit). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MobileAffiliateID | dbo.tblaff_Affiliates | Implicit | The affiliate credited for mobile channel acquisition |
| PrevAffiliateID | dbo.tblaff_Affiliates | Implicit | The previously attributed affiliate before reassignment |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

No indexes. This is a heap table with no clustered index, primary key, or nonclustered indexes. This suggests the table is either rarely queried, populated via bulk operations, or primarily used for ETL staging.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find affiliate attribution for a customer
```sql
SELECT CID, OriginalCID, MobileAffiliateID, PrevAffiliateID
FROM dbo.CidToAffiliateID WITH (NOLOCK)
WHERE CID = 12345
```

### 8.2 Find customers whose affiliate was reassigned
```sql
SELECT CID, MobileAffiliateID, PrevAffiliateID
FROM dbo.CidToAffiliateID WITH (NOLOCK)
WHERE PrevAffiliateID IS NOT NULL
  AND MobileAffiliateID != PrevAffiliateID
```

### 8.3 Join with affiliate details
```sql
SELECT c.CID, c.OriginalCID,
       a1.LoginName AS MobileAffiliate,
       a2.LoginName AS PrevAffiliate
FROM dbo.CidToAffiliateID c WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Affiliates a1 WITH (NOLOCK) ON c.MobileAffiliateID = a1.AffiliateID
LEFT JOIN dbo.tblaff_Affiliates a2 WITH (NOLOCK) ON c.PrevAffiliateID = a2.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.CidToAffiliateID | Type: Table | Source: fiktivo/dbo/Tables/dbo.CidToAffiliateID.sql*
