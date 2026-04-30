# BackOffice.CustomerToIMType_Del

> Deprecated mapping of customer CIDs to their Instant Messaging (IM) platform accounts (Skype, Google Talk, etc.) - both table and its lookup dictionary carry the "_Del" suffix indicating scheduled deletion; only 7 rows remain from early eToro operations.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (CID, IMTypeID, IMIdentifier) - composite CLUSTERED PK |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 2 active (1 clustered composite PK + 1 NC on IMTypeID) |

---

## 1. Business Meaning

BackOffice.CustomerToIMType_Del is a deprecated feature table that once stored customer Instant Messaging (IM) account identifiers for contact and communication purposes. A customer could register their Skype username, Google Talk address, or other IM platform handle with eToro, and BackOffice agents could contact them via these channels.

The table and its lookup dictionary (Dictionary.IMType_Del) both carry the `_Del` suffix, indicating they were flagged for deletion when the IM contact feature was decommissioned. The feature became obsolete as the IM platforms themselves were discontinued (Google Talk was shut down in 2013; Windows Live Messenger in 2013; Yahoo! Messenger in 2018) and the feature was never updated to support modern messaging platforms.

As of 2026-03-17, only 7 rows remain across 5 customers - test and very early eToro accounts. Only IMTypeID 3 (Google Talk) and 4 (Skype) appear in the data. No stored procedure, view, or function in the SSDT repo references this table - it is entirely inert.

**Dictionary.IMType_Del** contains 5 IM platform types: 1=Windows Live Messenger, 2=Yahoo! Messenger, 3=Google Talk, 4=Skype, 5=ICQ. All are either discontinued platforms or have negligible active use.

---

## 2. Business Logic

No active business logic. No procedures write to, read from, or modify this table in the current codebase. The table is an inert remnant of the IM contact feature. Historical behavior (pre-decommission) would have included:
- Agents viewing a customer's IM handles in the BackOffice profile
- Customers registering/updating their IM identifiers
- The `Verified` flag indicating whether the IM identifier had been confirmed as belonging to the customer

---

## 3. Data Overview

7 rows across 5 customers as of 2026-03-17:

| CID | IMTypeID | IMType | IMIdentifier | Verified | Note |
|-----|----------|--------|--------------|----------|------|
| 222 | 3 | Google Talk | test@gmail.com | No | CID=222 - very early account. Test email address. |
| 158200 | 3 | Google Talk | danieladams | No | Google Talk username. Google Talk shut down 2013. |
| 158200 | 4 | Skype | danieladams | Yes | Same identifier used for both platforms. |
| 265280 | 3 | Google Talk | sylvia@tradonomi.com | Yes | tradonomi.com = trading/social platform. |
| 534207 | 4 | Skype | konradlabuschagne | No | Skype username. |
| 1894268 | 3 | Google Talk | Fatimazo | Yes | |
| 1894268 | 4 | Skype | genine0 | Yes | |

Only IMTypeIDs 3 and 4 appear - the other three IM types (Windows Live Messenger, Yahoo! Messenger, ICQ) have no rows. 4 of 7 rows are Verified=true.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID. FK (WITH CHECK) to BackOffice.Customer(CID). Leading key of composite CLUSTERED PK. |
| 2 | IMTypeID | int | NO | - | VERIFIED | Instant Messaging platform type. FK (WITH CHECK) to Dictionary.IMType_Del. Values observed: 3=Google Talk, 4=Skype. Full lookup: 1=Windows Live Messenger, 2=Yahoo! Messenger, 3=Google Talk, 4=Skype, 5=ICQ. NC index on IMTypeID supports lookup from platform direction. Part of composite PK. |
| 3 | IMIdentifier | varchar(255) | NO | - | VERIFIED | The customer's username or address on the specified IM platform. Format varies by platform: email address for Google Talk (e.g., "test@gmail.com"), username for Skype (e.g., "danieladams"). Max 255 chars. Part of composite PK. |
| 4 | Verified | bit | NO | 0 | CODE-BACKED | Whether this IM identifier has been confirmed as belonging to the customer. 1=verified, 0=not verified. DEFAULT=0. 4 of 7 current rows are verified. No constraint logic enforcing verification workflow - likely set manually by BackOffice agents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer | FK (WITH CHECK) | Parent customer record |
| IMTypeID | Dictionary.IMType_Del | FK (WITH CHECK) | IM platform lookup (deprecated) |

### 5.2 Referenced By (other objects point to this)

No objects reference this table. It is not consumed by any procedure, view, or function in the current SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerToIMType_Del (deprecated table)
- FK targets:
  |- BackOffice.Customer (table)
  |- Dictionary.IMType_Del (deprecated lookup table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FK on CID |
| Dictionary.IMType_Del | Table | FK on IMTypeID (deprecated lookup) |

### 6.2 Objects That Depend On This

None.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BC2I | CLUSTERED PK | CID ASC, IMTypeID ASC, IMIdentifier ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| BC2I_IMTYPE | NC | IMTypeID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BC2I | PK | Uniqueness of (CID, IMTypeID, IMIdentifier) - a customer can have one identifier per platform |
| FK_BCST_BC2I | FK (WITH CHECK) | CID -> BackOffice.Customer(CID) |
| FK_DIMT_BC2I | FK (WITH CHECK) | IMTypeID -> Dictionary.IMType_Del(IMTypeID) |
| BC2I_VERIFIED | DEFAULT | Verified = 0 |

---

## 8. Sample Queries

### 8.1 View all IM accounts on record
```sql
SELECT c2i.CID, c2i.IMTypeID, im.Name AS IMPlatform,
       c2i.IMIdentifier, c2i.Verified
FROM BackOffice.CustomerToIMType_Del c2i WITH (NOLOCK)
JOIN Dictionary.IMType_Del im WITH (NOLOCK) ON im.IMTypeID = c2i.IMTypeID
ORDER BY c2i.CID, c2i.IMTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. The `_Del` suffix indicates deprecation intent; no specific Jira ticket or Confluence page found documenting the decommission decision.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerToIMType_Del | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerToIMType_Del.sql*
