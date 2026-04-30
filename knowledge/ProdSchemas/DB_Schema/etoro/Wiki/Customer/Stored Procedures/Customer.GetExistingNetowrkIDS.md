# Customer.GetExistingNetowrkIDS

> Filters a caller-provided XML list of social network user IDs to return only those already registered in Customer.PrivacyUniqueIdentity; includes legacy Facebook profile URL normalization for duplicate detection during registration.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserIDS (XML list of network user IDs to check) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetExistingNetowrkIDS (note: "Netowrk" is a typo in the original procedure name) checks whether a set of social network user IDs (Facebook, Google, etc.) are already registered eToro accounts. It is used during social login registration to detect if a social identity already exists in the platform before creating a new account.

The procedure is critical for preventing duplicate accounts via social login: if a user tries to register with a Facebook ID that's already linked to an eToro account, the platform should recognize it as an existing user rather than creating a duplicate.

The legacy Facebook URL normalization (`'http://www.facebook.com/profile.php?id=' + UserID`) handles old-format Facebook profile URLs that were stored before the platform switched to storing raw Facebook user IDs. A join on either the raw ID or the old URL format ensures backward compatibility.

---

## 2. Business Logic

### 2.1 XML Shredding and Network ID Existence Check

**What**: Parses XML user ID list, checks against PrivacyUniqueIdentity for existing registrations.

**Columns/Parameters Involved**: `@UserIDS`, `UserID`

**Rules**:
- XML format expected: `<Root><UserID>string</UserID>...</Root>`
- Shredding: @UserIDS.nodes('Root/UserID') extracts each UserID as nvarchar(510)
- Temp table #IDs holds the parsed values
- INNER JOIN to Customer.PrivacyUniqueIdentity: matches on UserID = I.UserID OR UserID = 'http://www.facebook.com/profile.php?id=' + I.UserID
- The OR condition handles legacy stored Facebook IDs: some older records store the full profile URL, newer records store just the numeric ID
- Returns DISTINCT UserIDs (the input format, not the stored format) that are already registered
- Non-existent UserIDs are silently excluded

**Diagram**:
```
Input: @UserIDS XML
  <Root><UserID>123456</UserID>...</Root>
        |
        v
  Temp table #IDs: UserID = '123456'
        |
        v
  JOIN Customer.PrivacyUniqueIdentity:
    Match 1: cp.UserID = '123456' (modern format)
    Match 2: cp.UserID = 'http://www.facebook.com/profile.php?id=123456' (legacy URL format)
        |
        v
  Returns: '123456' if already registered
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserIDS | XML | NO | - | CODE-BACKED | XML document containing network user IDs to validate. Expected format: `<Root><UserID>{string}</UserID>...</Root>`. Each `<UserID>` is parsed as nvarchar(510). Supports Facebook numeric IDs and other social network user ID formats. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| UserID | Customer.PrivacyUniqueIdentity.UserID (via DISTINCT) | Social network user ID that is already registered in eToro. The value returned is from PrivacyUniqueIdentity (may be the legacy URL format if stored that way). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserIDS | Customer.PrivacyUniqueIdentity | INNER JOIN (existence check) | Checks which network user IDs are already registered |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (called during social login registration flow).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetExistingNetowrkIDS (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | Source of registered social network user IDs; inner-joined to check existence |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Legacy URL handling | Backward compatibility | Also matches 'http://www.facebook.com/profile.php?id=' + UserID to find old Facebook profile URL format records |
| nvarchar(510) | Data type | UserID stored as nvarchar(510); input parsed as nvarchar(510) |
| DISTINCT | Deduplication | Prevents duplicate UserID rows in output if both URL and raw ID formats match |
| Typo in name | Code quality | Procedure name has "Netowrk" instead of "Network" - cannot rename without breaking callers |

---

## 8. Sample Queries

### 8.1 Check which Facebook IDs are already registered

```sql
EXEC Customer.GetExistingNetowrkIDS @UserIDS = '<Root><UserID>123456789</UserID><UserID>987654321</UserID></Root>'
-- Returns the UserIDs that already exist in PrivacyUniqueIdentity
```

### 8.2 Build XML input for batch check

```sql
DECLARE @xml XML = '<Root><UserID>123456789</UserID><UserID>987654321</UserID></Root>'
EXEC Customer.GetExistingNetowrkIDS @UserIDS = @xml
```

### 8.3 Check PrivacyUniqueIdentity for a specific network user ID

```sql
SELECT TOP 10 CID, UserID, NetworkID
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE UserID = '123456789'
   OR UserID = 'http://www.facebook.com/profile.php?id=123456789'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetExistingNetowrkIDS | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetExistingNetowrkIDS.sql*
