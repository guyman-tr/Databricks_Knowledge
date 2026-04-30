# Dictionary.OptOutReason

> Defines the reasons why a customer has opted out of marketing communications, distinguishing between active opt-in, self-service opt-out, inactivity-based opt-out, and geographic restriction.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | OptOutReasonID (smallint, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.OptOutReason classifies the marketing communication preferences of customers. Each customer has an opt-out reason that determines whether they receive promotional communications, and if not, why they were excluded. This is critical for GDPR/privacy compliance — the platform must track not just WHETHER a customer is opted out, but WHY.

Without this table, the marketing and communications teams could not differentiate between customers who actively chose to stop receiving promotions vs those who were automatically excluded due to inactivity or geographic restrictions. This distinction affects re-engagement strategies and regulatory compliance.

Referenced by Customer.CustomerStatic (OptOutReasonID column), set during registration (Customer.InsertRealCustomer, Customer.RegisterReal), updated by Customer.UpdateUserSettings and Customer.UpdateUserSettingsRemote, and read through Customer.Customer and Customer.CustomerSafty views.

---

## 2. Business Logic

### 2.1 Opt-Out Classification

**What**: Four states covering the spectrum from active opt-in to system-enforced exclusion.

**Columns/Parameters Involved**: `OptOutReasonID`, `OptOutReason`

**Rules**:
- Opt-In (0): Customer has actively consented to receive marketing communications — default for new registrations in most jurisdictions
- User Opt-Out (1): Customer explicitly chose to stop receiving marketing — must be honored per GDPR/CAN-SPAM
- Last Login Opt-Out (2): Customer has been inactive for an extended period — automatically excluded from campaigns to reduce bounce rates
- Country of Origin Opt-Out (3): Customer is from a jurisdiction where marketing communications are restricted by law

**Diagram**:
```
Customer Registration
       │
       ▼
Opt-In (0) [default in most countries]
   │
   ├── User clicks unsubscribe ──> User Opt-Out (1)
   │
   ├── No login for X days ──────> Last Login Opt-Out (2)
   │
   └── Country restricts marketing ──> Country of Origin Opt-Out (3)
```

---

## 3. Data Overview

| OptOutReasonID | OptOutReason | Meaning |
|---|---|---|
| 0 | Opt-In | Customer has consented to receive marketing communications — eligible for all promotional campaigns and engagement communications |
| 1 | User Opt-Out | Customer explicitly clicked unsubscribe or changed their communication preferences — legally binding opt-out that must be respected |
| 2 | Last Login Opt-Out | Customer has been inactive beyond the configured threshold — automatically excluded to maintain email deliverability and avoid spam complaints |
| 3 | Country of Origin Opt-Out | Customer's country of origin restricts unsolicited marketing communications — system-enforced exclusion based on regulatory requirements |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OptOutReasonID | smallint | NO | - | CODE-BACKED | Unique identifier for the opt-out state: 0=Opt-In, 1=User Opt-Out, 2=Last Login Opt-Out, 3=Country of Origin Opt-Out. Referenced by Customer.CustomerStatic and 10+ customer procedures. |
| 2 | OptOutReason | varchar(50) | NO | - | VERIFIED | Human-readable reason label. Note: column name matches table name. Displayed in BackOffice customer details and used in marketing campaign segmentation queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | OptOutReasonID | Implicit | Every customer record tracks their opt-out state |
| History.Customer | OptOutReasonID | Implicit | Historical customer snapshots preserve opt-out state |
| Customer.Customer | OptOutReasonID | View | Customer view exposes opt-out reason |
| Customer.CustomerSafty | OptOutReasonID | View | Safe customer view includes opt-out |
| Customer.InsertRealCustomer | @OptOutReasonID | Implicit | Sets initial opt-out state at registration |
| Customer.RegisterReal | @OptOutReasonID | Implicit | Registration sets opt-out based on country |
| Customer.UpdateUserSettings | @OptOutReasonID | Implicit | User settings update changes opt-out |
| Customer.SetPrivacyPolicyID | OptOutReasonID | Implicit | Privacy policy updates may change opt-out |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | OptOutReasonID column |
| History.Customer | Table | Historical opt-out tracking |
| Customer.Customer | View | Exposes opt-out reason |
| Customer.InsertRealCustomer | Stored Procedure | Sets opt-out at registration |
| Customer.RegisterReal | Stored Procedure | Sets opt-out at registration |
| Customer.UpdateUserSettings | Stored Procedure | Updates opt-out preference |
| Customer.UpdateUserSettingsRemote | Stored Procedure | Remote settings update |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DICT_OptOutReason | CLUSTERED PK | OptOutReasonID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all opt-out reasons
```sql
SELECT  OptOutReasonID,
        OptOutReason
FROM    [Dictionary].[OptOutReason] WITH (NOLOCK)
ORDER BY OptOutReasonID;
```

### 8.2 Count customers by opt-out status
```sql
SELECT  oor.OptOutReason,
        COUNT(*) AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[OptOutReason] oor WITH (NOLOCK)
        ON cs.OptOutReasonID = oor.OptOutReasonID
GROUP BY oor.OptOutReason
ORDER BY CustomerCount DESC;
```

### 8.3 Find customers with country-based opt-out
```sql
SELECT  cs.CID,
        oor.OptOutReason
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[OptOutReason] oor WITH (NOLOCK)
        ON cs.OptOutReasonID = oor.OptOutReasonID
WHERE   cs.OptOutReasonID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OptOutReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OptOutReason.sql*
