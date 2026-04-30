# Dictionary.ChangedSections

> Lookup table identifying which business area or entity was modified in audit log entries, mapping each audit record to the specific configuration or data section that changed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SectionID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ChangedSections defines the 20 distinct business areas that can be tracked in the audit log system. When an admin modifies affiliate data, the system records not only WHAT operation was performed (via Dictionary.Action) but also WHICH area of the system was affected. This allows compliance and admin teams to filter audit trails by business domain.

This table is essential for audit granularity. Without it, audit logs would show "something changed" but not "what category of data changed." This matters for compliance investigations where auditors need to review, for example, all changes to payment details or all modifications to commission rate plans.

Rows are static reference data read by the audit log system. The dbo.AuditLog table stores SectionID alongside ActionID to create a two-dimensional audit classification: what type of change (Insert/Update/Delete) applied to which business area (Affiliates, Commission Plans, Countries, etc.).

---

## 2. Business Logic

### 2.1 Audit Domain Classification

**What**: Twenty business areas organized into logical groups representing all auditable parts of the affiliate management system.

**Columns/Parameters Involved**: `SectionID`, `Name`

**Rules**:
- Core affiliate data: Affiliates (1), AffiliateTypes (2), Affiliate Group (3)
- Marketing assets: Banners (18), MediaTag (10), AffiliatePixel (17), AffiliateURLs (14), Categories (5)
- Commission configuration: RegistrationRates (11), FirstPositionAssetPlan (12), IOBPlan (19), ISAPlan (20)
- Partner management: Tier2Members (15), AffiliateTypeCategories (16)
- Platform config: Countries (6), BlockedCountries (13), Brands (7), Languages (8)
- Financial: Payment Details (9)
- Communication: Announcements (4)

---

## 3. Data Overview

| SectionID | Name | Meaning |
|---|---|---|
| 1 | Affiliates | Change to an affiliate's core profile - registration details, contact info, status. The most common audit section as it covers all affiliate record modifications |
| 9 | Payment Details | Change to how an affiliate receives commission payouts - bank details, PayPal, wire transfer settings. Sensitive financial data requiring audit trail for compliance |
| 11 | RegistrationRates | Change to the commission rates paid when a referred customer registers. Directly impacts affiliate revenue and must be audited for unauthorized modifications |
| 13 | BlockedCountries | Change to which countries an affiliate is restricted from marketing to. Regulatory compliance control - blocking affiliates from operating in unauthorized jurisdictions |
| 19 | IOBPlan | Change to Introducing Broker plan settings - commission structures for affiliates operating as introducing brokers with recurring revenue shares |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SectionID | int | NO | - | VERIFIED | Primary key identifying the business area affected by an audit-logged change. Values: 1=Affiliates, 2=AffiliateTypes, 3=Affiliate Group, 4=Announcements, 5=Categories, 6=Countries, 7=Brands, 8=Languages, 9=Payment Details, 10=MediaTag, 11=RegistrationRates, 12=FirstPositionAssetPlan, 13=BlockedCountries, 14=AffiliateURLs, 15=Tier2Members, 16=AffiliateTypeCategories, 17=AffiliatePixel, 18=Banners, 19=IOBPlan, 20=ISAPlan. See [Changed Sections](../../_glossary.md#changed-sections) for full definitions. |
| 2 | Name | varchar(250) | NO | - | VERIFIED | Human-readable label for the business area. Used in audit log displays to show which part of the system was modified. Names match the business domain entities they represent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AuditLog | SectionID | Implicit FK | Audit log records which business area was affected by each logged change |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AuditLog | Table | Stores SectionID to classify audit entries by business area |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.ChangedSections_1 | CLUSTERED PK | SectionID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all changed sections
```sql
SELECT SectionID, Name
FROM Dictionary.ChangedSections WITH (NOLOCK)
ORDER BY SectionID
```

### 8.2 View audit log with section and action names
```sql
SELECT TOP 10
    al.*,
    a.Name AS ActionName,
    cs.Name AS SectionName
FROM dbo.AuditLog al WITH (NOLOCK)
JOIN Dictionary.Action a WITH (NOLOCK) ON al.ActionID = a.ActionID
JOIN Dictionary.ChangedSections cs WITH (NOLOCK) ON al.SectionID = cs.SectionID
ORDER BY al.AuditLogID DESC
```

### 8.3 Count audit entries by section
```sql
SELECT cs.SectionID, cs.Name, COUNT(*) AS ChangeCount
FROM dbo.AuditLog al WITH (NOLOCK)
JOIN Dictionary.ChangedSections cs WITH (NOLOCK) ON al.SectionID = cs.SectionID
GROUP BY cs.SectionID, cs.Name
ORDER BY ChangeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ChangedSections | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.ChangedSections.sql*
