# Dictionary.KYPStatus

> Lookup table defining the lifecycle states of an affiliate's Know Your Partner (KYP) verification process, controlling whether the affiliate can receive commissions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | KYPStatusID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.KYPStatus defines the seven lifecycle states of the KYP (Know Your Partner) verification process. Each affiliate must complete KYP verification to receive commissions. The status controls the affiliate's operational capabilities - unverified affiliates may be restricted from certain activities until their identity and business documentation are approved.

This table is critical to the compliance workflow. Without it, the system could not track where each affiliate stands in the verification pipeline, nor enforce commission holds on unverified partners. Multiple procedures across the KYP and Affiliate schemas reference KYPStatusID to gate business operations.

KYPStatus progresses through a linear workflow: Unavailable -> Unverified -> In Progress -> Submitted -> Verified, with Cancel Pending as a side path and Submit Pending as an intermediate holding state.

---

## 2. Business Logic

### 2.1 KYP Verification Lifecycle

**What**: Seven states representing the full verification pipeline from initial state to approved or cancelled.

**Columns/Parameters Involved**: `KYPStatusID`, `KYPStatusName`

**Rules**:
- ID=1 (Unavailable) is the initial state when KYP has not been initiated
- ID=2 (Unverified) means KYP is required but the affiliate has not yet submitted documents
- ID=3 (In Progress) means documents are submitted and under compliance review
- ID=4 (Submit Pending) is a holding state where documents are prepared but not yet sent for review
- ID=5 (Submitted) means all documents are submitted, awaiting the final compliance decision
- ID=6 (Cancel Pending) means cancellation of the KYP process has been initiated
- ID=7 (Verified) is the terminal success state - the affiliate has passed all checks and can receive commissions

**Diagram**:
```
[Unavailable (1)] --> [Unverified (2)] --> [Submit Pending (4)] --> [Submitted (5)]
                                                                        |
                                    [In Progress (3)] <-----------------+
                                         |
                          +--------------+--------------+
                          |                             |
                   [Verified (7)]              [Cancel Pending (6)]
```

---

## 3. Data Overview

| KYPStatusID | KYPStatusName | Meaning |
|---|---|---|
| 1 | Unavailable | KYP not yet initiated or not applicable for this affiliate. Initial default state before the verification process begins |
| 2 | Unverified | KYP is required but the affiliate has not yet submitted any documents. The affiliate may be restricted from receiving commissions |
| 3 | In Progress | Documents have been submitted and are currently under compliance review. Turnaround depends on document quality and jurisdiction complexity |
| 5 | Submitted | All required documents submitted, awaiting final compliance decision. No further action required from the affiliate |
| 7 | Verified | All KYP checks passed - the affiliate is fully verified and authorized to receive commissions. Terminal success state |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | KYPStatusID | int | NO | - | VERIFIED | Primary key identifying the KYP verification state. Values: 1=Unavailable, 2=Unverified, 3=In Progress, 4=Submit Pending, 5=Submitted, 6=Cancel Pending, 7=Verified. See [KYP Status](../../_glossary.md#kyp-status) for full definitions. Controls commission eligibility gating. |
| 2 | KYPStatusName | nvarchar(25) | NO | - | VERIFIED | Human-readable label for the KYP status. Displayed in KYP admin screens, affiliate dashboards, and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.Affiliate | KYPStatusID | Implicit FK | Tracks current KYP status for each affiliate |
| History.KYPAffiliate | KYPStatusID | Implicit FK | Historical KYP status snapshots |
| KYP.GetAffiliateKYPStatus | Parameter | Lookup | Returns KYP status for a specific affiliate |
| KYP.UpdateAffiliateKYPStatus | Parameter | Lookup | Updates KYP status during verification workflow |
| KYP.CreateAffiliate | Parameter | Lookup | Sets initial KYP status on affiliate creation |
| Affiliate.GetAffiliateInfoById | JOIN | Lookup | Returns affiliate info including KYP status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | Stores KYPStatusID for each affiliate |
| History.KYPAffiliate | Table | Historical KYP status records |
| KYP.GetAffiliateKYPStatus | Stored Procedure | READER - checks KYP status |
| KYP.UpdateAffiliateKYPStatus | Stored Procedure | MODIFIER - transitions KYP status |
| KYP.CreateAffiliate | Stored Procedure | WRITER - sets initial KYP status |
| Affiliate.GetAffiliateInfoById | Stored Procedure | READER - includes KYP status in affiliate info |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryKYPStatus | CLUSTERED PK | KYPStatusID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all KYP statuses
```sql
SELECT KYPStatusID, KYPStatusName
FROM Dictionary.KYPStatus WITH (NOLOCK)
ORDER BY KYPStatusID
```

### 8.2 Find affiliates pending verification
```sql
SELECT a.AffiliateID, ks.KYPStatusName
FROM KYP.Affiliate a WITH (NOLOCK)
JOIN Dictionary.KYPStatus ks WITH (NOLOCK) ON a.KYPStatusID = ks.KYPStatusID
WHERE a.KYPStatusID IN (2, 3, 4, 5)
```

### 8.3 Count affiliates by KYP status
```sql
SELECT ks.KYPStatusID, ks.KYPStatusName, COUNT(*) AS AffiliateCount
FROM KYP.Affiliate a WITH (NOLOCK)
JOIN Dictionary.KYPStatus ks WITH (NOLOCK) ON a.KYPStatusID = ks.KYPStatusID
GROUP BY ks.KYPStatusID, ks.KYPStatusName
ORDER BY AffiliateCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.KYPStatus | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.KYPStatus.sql*
