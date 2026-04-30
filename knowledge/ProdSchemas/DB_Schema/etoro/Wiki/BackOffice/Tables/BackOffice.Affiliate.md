# BackOffice.Affiliate

> Affiliate profile and settings registry - one row per affiliate account, controlling their reputation tier and assigned spread group. AffiliateID maps to the affiliate's own customer ID in the trading system. Status changes sync to Dynamics CRM via Service Broker.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID (INT, CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 3 active (1 clustered PK + 2 NC on FK columns) |

---

## 1. Business Meaning

BackOffice.Affiliate is the affiliate settings table for eToro's affiliate marketing program. Each row represents one affiliate partner: their reputation/tier classification (AffiliateStatusID), their assigned trading spread group (SpreadGroupID), and an optional BackOffice manager assignment (ManagerID).

The AffiliateID is NOT an independent identity - it maps directly to the affiliate's own customer account ID (SerialID/CID) in the trading system. An affiliate is a customer who also participates in eToro's affiliate program, referring new customers. The table exists separately from BackOffice.Customer because affiliate settings (spread group, tier) are distinct from customer governance settings.

45,621 rows as of 2026-03-17. AffiliateID ranges from -1 (one special/test record) to 30,000,361. The vast majority (93.2%) have AffiliateStatusID=1 (Normal). Nearly all (99.996%) have SpreadGroupID=0 (default/no custom spread). Only 1 of 45,621 rows has a ManagerID set.

**Dynamics CRM integration**: When AffiliateEdit updates a row, it fires a Service Broker message to `svcDynamics` with the new AffiliateID and AffiliateStatusID (as AffiliateRank XML), synchronizing the affiliate's tier to the CRM system.

**Cascade to referred customers**: When an affiliate's SpreadGroupID changes, AffiliateEdit also updates `Customer.Customer.SpreadGroupID` for all customers whose SerialID matches the AffiliateID and who still have the old SpreadGroupID. This propagates the affiliate's spread group change to their referred customer base.

---

## 2. Business Logic

### 2.1 Affiliate Upsert (Create or Update)

**What**: AffiliateEdit creates a new affiliate record or updates an existing one, and synchronizes the change to Dynamics CRM.

**Columns Involved**: `AffiliateID`, `AffiliateStatusID`, `SpreadGroupID`, `ManagerID`

**Rules**:
- If no row exists for AffiliateID: INSERT with provided AffiliateStatusID, SpreadGroupID, NULL ManagerID.
- If row exists: UPDATE SpreadGroupID and AffiliateStatusID.
- If SpreadGroupID changes during update: also UPDATE Customer.Customer SET SpreadGroupID=@new WHERE SerialID=@AffiliateID AND SpreadGroupID=@old (cascade to referred customers who still have the old spread group).
- After insert or update: fire SSB message to 'svcDynamics' with AffiliateID + AffiliateStatusID as `AffiliateRank` XML element, syncing to Dynamics CRM.

### 2.2 Spread Group Assignment

**What**: An affiliate's SpreadGroupID determines their trading conditions and cascades to referred customers.

**Columns Involved**: `AffiliateID`, `SpreadGroupID`

**Rules**:
- Default SpreadGroupID = 0 (standard/default spread group). 99.996% of affiliates use this.
- SpreadGroupID=3 appears for 2 affiliates (custom premium spread group).
- BackOffice.SetDefaultSpreadGroup: direct UPDATE of SpreadGroupID for a given AffiliateID (simpler than AffiliateEdit - no CRM sync, no cascade).
- FK (WITH CHECK) to Trade.SpreadGroup.

### 2.3 Backfill from Source System

**What**: UpdateBackOfficeAffiliateTableForMissingRecords syncs new affiliates from the external affiliate source into this table.

**Rules**:
- Reads from `fiktivo_tblaff_Affiliates` (synonym for fiktivo.dbo.tblaff_Affiliates, the external affiliate management system).
- Inserts affiliates not yet present in BackOffice.Affiliate with default status=1 (Normal), SpreadGroupID=0, ManagerID=NULL.
- This is the initial population mechanism for new affiliates.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows (2026-03-17) | 45,621 |
| AffiliateID range | -1 to 30,000,361 |
| Rows with ManagerID set | 1 (AffiliateID=14, ManagerID=99) |
| Rows with ManagerID NULL | 45,620 (99.998%) |
| Unique SpreadGroupIDs | 2 (0 and 3) |

**AffiliateStatus distribution**:

| AffiliateStatusID | Name | Count | Share |
|-------------------|------|-------|-------|
| 1 | Normal | 42,512 | 93.2% |
| 3 | Bad | 2,182 | 4.8% |
| 2 | Good | 703 | 1.5% |
| 6 | Platinum | 124 | 0.3% |
| 5 | Excellent | 63 | 0.1% |
| 4 | Untouchable | 37 | 0.08% |

**SpreadGroup distribution**:

| SpreadGroupID | Count | Share |
|---------------|-------|-------|
| 0 | 45,619 | 99.996% |
| 3 | 2 | 0.004% |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | VERIFIED | Affiliate's unique identifier. Clustered PK. Maps directly to the affiliate's customer account ID (SerialID in Customer.Customer, CID in BackOffice.Customer). NOT an independent sequence - the affiliate must already exist as a customer. Range: -1 to 30,000,361 (AffiliateID=-1 is a special/placeholder record). |
| 2 | AffiliateStatusID | int | NO | 1 | VERIFIED | Affiliate reputation/tier classification. FK (WITH CHECK) to Dictionary.AffiliateStatus. Default 1 (Normal). Values: 1=Normal (93.2%), 2=Good (1.5%), 3=Bad (4.8%), 4=Untouchable (0.08%), 5=Excellent (0.1%), 6=Platinum (0.3%). Synced to Dynamics CRM as "AffiliateRank" on every change via AffiliateEdit. |
| 3 | SpreadGroupID | int | NO | 0 | VERIFIED | Trading spread group assigned to this affiliate. FK (WITH CHECK) to Trade.SpreadGroup. Default 0 (standard spread). 99.996% of affiliates have SpreadGroupID=0. When changed via AffiliateEdit, cascades to Customer.Customer.SpreadGroupID for all referred customers still on the old spread group. |
| 4 | ManagerID | int | YES | - | VERIFIED | BackOffice manager assigned to oversee this affiliate. FK (WITH CHECK) to BackOffice.Manager. NULL for 99.998% of affiliates (45,620 of 45,621). Only AffiliateID=14 has ManagerID=99. Effectively unused in current operations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | Customer.Customer (SerialID) | Semantic (no FK) | Affiliate's own customer account; AffiliateID = customer SerialID |
| AffiliateStatusID | Dictionary.AffiliateStatus | FK (WITH CHECK) | Affiliate tier/reputation classification |
| SpreadGroupID | Trade.SpreadGroup | FK (WITH CHECK) | Trading spread group |
| ManagerID | BackOffice.Manager | FK (WITH CHECK) | Assigned BackOffice manager (nearly always NULL) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AffiliateEdit | AffiliateID | WRITER (upsert) | Creates or updates affiliate record; syncs to Dynamics CRM |
| BackOffice.SetDefaultSpreadGroup | AffiliateID | MODIFIER | Updates SpreadGroupID only |
| BackOffice.UpdateBackOfficeAffiliateTableForMissingRecords | AffiliateID | WRITER (backfill) | Syncs new affiliates from fiktivo_tblaff_Affiliates |
| BackOffice.GetCustomerByCID | AffiliateID | READER | Joins for affiliate data in customer lookup |
| BackOffice.GetRegistrationReport | AffiliateID | READER | Affiliate data in registration reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Affiliate (table)
- FK targets: BackOffice.Manager, Dictionary.AffiliateStatus, Trade.SpreadGroup
- Semantically linked to: Customer.Customer (SerialID = AffiliateID)
- External source: fiktivo_tblaff_Affiliates (fiktivo.dbo, via synonym)
- CRM sink: Dynamics CRM via SSB svcDynamics
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | FK on ManagerID |
| Dictionary.AffiliateStatus | Table | FK on AffiliateStatusID; 6 tier values |
| Trade.SpreadGroup | Table | FK on SpreadGroupID; spread group settings |
| Customer.Customer | Table | Cascade target: SpreadGroupID updated on affiliate spread change |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AffiliateEdit | Procedure | WRITER - primary upsert + CRM sync |
| BackOffice.SetDefaultSpreadGroup | Procedure | MODIFIER - SpreadGroupID only |
| BackOffice.UpdateBackOfficeAffiliateTableForMissingRecords | Procedure | WRITER - backfill from external source |
| BackOffice.GetCustomerByCID | Procedure | READER |
| BackOffice.GetRegistrationReport | Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BAFF | CLUSTERED PK | AffiliateID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| BAFF_AFFSTATUS | NC | AffiliateStatusID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| BAFF_SPREADGROUP | NC | SpreadGroupID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BAFF | PK | AffiliateID uniqueness |
| BAFF_AFFSTATUS | DEFAULT | AffiliateStatusID = 1 (Normal) |
| BAFF_SPREADGROUP | DEFAULT | SpreadGroupID = 0 |
| FK_BMNG_BAFF | FK (WITH CHECK) | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_DAFS_BAFF | FK (WITH CHECK) | AffiliateStatusID -> Dictionary.AffiliateStatus(AffiliateStatusID) |
| FK_TSPG_BAFF | FK (WITH CHECK) | SpreadGroupID -> Trade.SpreadGroup(SpreadGroupID) |

---

## 8. Sample Queries

### 8.1 Get all affiliates by status
```sql
SELECT
    a.AffiliateID,
    ds.Name AS StatusName,
    a.SpreadGroupID,
    a.ManagerID
FROM BackOffice.Affiliate a WITH (NOLOCK)
JOIN Dictionary.AffiliateStatus ds WITH (NOLOCK) ON ds.AffiliateStatusID = a.AffiliateStatusID
ORDER BY a.AffiliateStatusID, a.AffiliateID
```

### 8.2 Find affiliates with non-default spread group
```sql
SELECT
    a.AffiliateID,
    a.SpreadGroupID,
    sg.SpreadGroupName,
    ds.Name AS StatusName
FROM BackOffice.Affiliate a WITH (NOLOCK)
JOIN Trade.SpreadGroup sg WITH (NOLOCK) ON sg.SpreadGroupID = a.SpreadGroupID
JOIN Dictionary.AffiliateStatus ds WITH (NOLOCK) ON ds.AffiliateStatusID = a.AffiliateStatusID
WHERE a.SpreadGroupID <> 0
ORDER BY a.AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.1/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Affiliate | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Affiliate.sql*
