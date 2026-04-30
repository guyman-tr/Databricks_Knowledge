# Customer.GetAffiliationInfo

> Retrieves affiliate/partner tracking data (serial ID, sub-serial ID, download ID) for a single user by their legacy CID from the Real_Customer table.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (legacy customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAffiliationInfo retrieves a user's affiliate and partner tracking identifiers. These fields track which marketing channel, affiliate partner, or app download campaign brought the user to the platform.

This procedure exists to support affiliate commission calculations, partner reporting, and marketing attribution. Services that need to determine a user's acquisition source call this procedure to get the SerialID (affiliate partner), SubSerialID (sub-partner or campaign), and DownloadID (mobile app installation attribution).

Data is read from dbo.Real_Customer, a legacy table/synonym that stores the original customer record including marketing attribution fields. The procedure uses a CID (legacy Customer ID) rather than GCID, indicating it serves older integration points.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple single-table read returning affiliate tracking columns.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Legacy Customer ID to look up. Used against dbo.Real_Customer.CID. Note: this uses CID (legacy), not GCID (global). |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | The legacy Customer ID, echoed back for caller reference. |
| 2 | SerialID | int | YES | - | CODE-BACKED | Affiliate/partner serial number - identifies the marketing partner or affiliate that referred this user. Maps to AccountUserInfo.SerialID. |
| 3 | SubSerialID | varchar | YES | - | CODE-BACKED | Sub-serial identifier for granular partner/campaign tracking within the affiliate. Free-form string. |
| 4 | DownloadID | int | YES | - | CODE-BACKED | Mobile app download/installation tracking identifier. Used for attribution of app installs to marketing campaigns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | dbo.Real_Customer | SELECT (READER) | Reads affiliate tracking fields by CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by affiliate/marketing services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAffiliationInfo (procedure)
+-- dbo.Real_Customer (table/synonym) - reads affiliate fields
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table/Synonym | SELECT - reads CID, SerialID, SubSerialID, DownloadID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get affiliation info for a user
```sql
EXEC Customer.GetAffiliationInfo @CID = 12345
```

### 8.2 Check affiliation data with context
```sql
-- First resolve CID from GCID
DECLARE @cid INT
SELECT @cid = CID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = 67890
EXEC Customer.GetAffiliationInfo @CID = @cid
```

### 8.3 Verify affiliate tracking fields
```sql
SELECT CID, SerialID, SubSerialID, DownloadID
FROM dbo.Real_Customer WITH (NOLOCK)
WHERE CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetAffiliationInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetAffiliationInfo.sql*
