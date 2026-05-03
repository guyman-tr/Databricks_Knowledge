# BI_DB_dbo.BI_DB_SF_Cases_Panel — Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Description |
|---|---|---|---|---|
| 1 | Salesforce Cases (external) | External System | Writer | Salesforce CRM case/ticket data. Loaded by SP_SF_Cases (not in SSDT repo). |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | CreatedDate | Salesforce Cases | CreatedDate | Passthrough (external ETL) | Tier 3 |
| 2 | LastStatusDate | Salesforce Cases | LastStatusDate | Passthrough (external ETL) | Tier 3 |
| 3 | TicketStatus | Salesforce Cases | TicketStatus | Passthrough (external ETL) | Tier 3 |
| 4 | CaseNumber | Salesforce Cases | CaseNumber | Passthrough (external ETL) | Tier 3 |
| 5 | TicketID | Salesforce Cases | TicketID | Passthrough (external ETL) | Tier 3 |
| 6 | HistoryID_AtOpen | Salesforce Cases | HistoryID | Snapshot at ticket open | Tier 3 |
| 7 | IsVisitor_Atopen | Salesforce Cases | IsVisitor | Snapshot at ticket open | Tier 3 |
| 8 | DepositorType_AtOpen | Salesforce Cases | DepositorType | Snapshot at ticket open | Tier 3 |
| 9 | Regulation_AtOpen | Salesforce Cases | Regulation | Snapshot at ticket open | Tier 3 |
| 10 | ClubTier_AtOpen | Salesforce Cases | ClubTier | Snapshot at ticket open | Tier 3 |
| 11 | Role_AtOpen | Salesforce Cases | Role | Snapshot at ticket open | Tier 3 |
| 12 | SubRole_AtOpen | Salesforce Cases | SubRole | Snapshot at ticket open | Tier 3 |
| 13 | ServiceLanguage_AtOpen | Salesforce Cases | ServiceLanguage | Snapshot at ticket open | Tier 3 |
| 14 | ServiceDesk_AtOpen | Salesforce Cases | ServiceDesk | Snapshot at ticket open | Tier 3 |
| 15 | Phase_AtOpen | Salesforce Cases | Phase | Snapshot at ticket open | Tier 3 |
| 16 | Source_AtOpen | Salesforce Cases | Source | Snapshot at ticket open | Tier 3 |
| 17 | Priority_AtOpen | Salesforce Cases | Priority | Snapshot at ticket open | Tier 3 |
| 18 | Product_AtOpen | Salesforce Cases | Product | Snapshot at ticket open | Tier 3 |
| 19 | Type_AtOpen | Salesforce Cases | Type | Snapshot at ticket open | Tier 3 |
| 20 | ActionType_AtOpen | Salesforce Cases | ActionType | Snapshot at ticket open | Tier 3 |
| 21 | SubType_AtOpen | Salesforce Cases | SubType | Snapshot at ticket open | Tier 3 |
| 22 | SubType2_AtOpen | Salesforce Cases | SubType2 | Snapshot at ticket open | Tier 3 |
| 23 | Country_AtOpen | Salesforce Cases | Country | Snapshot at ticket open | Tier 3 |
| 24 | PlayerStatus_AtOpen | Salesforce Cases | PlayerStatus | Snapshot at ticket open | Tier 3 |
| 25 | AccountManagerID_AtOpen | Salesforce Cases | AccountManagerID | Snapshot at ticket open | Tier 3 |
| 26 | ActiveAgentID_Atopen | Salesforce Cases | ActiveAgentID | Snapshot at ticket open | Tier 3 |
| 27 | Owner_Atopen | Salesforce Cases | Owner | Snapshot at ticket open | Tier 3 |
| 28 | CID_Last | Salesforce Cases | CID | Latest snapshot value | Tier 3 |
| 29 | HistoryID_Last | Salesforce Cases | HistoryID | Latest snapshot value | Tier 3 |
| 30 | IsVisitor_Last | Salesforce Cases | IsVisitor | Latest snapshot value | Tier 3 |
| 31 | DepositorType_Last | Salesforce Cases | DepositorType | Latest snapshot value | Tier 3 |
| 32 | Regulation_Last | Salesforce Cases | Regulation | Latest snapshot value | Tier 3 |
| 33 | ClubTier_Last | Salesforce Cases | ClubTier | Latest snapshot value | Tier 3 |
| 34 | Role_Last | Salesforce Cases | Role | Latest snapshot value | Tier 3 |
| 35 | SubRole_Last | Salesforce Cases | SubRole | Latest snapshot value | Tier 3 |
| 36 | ServiceLanguage_Last | Salesforce Cases | ServiceLanguage | Latest snapshot value | Tier 3 |
| 37 | ServiceDesk_Last | Salesforce Cases | ServiceDesk | Latest snapshot value | Tier 3 |
| 38 | Phase_Last | Salesforce Cases | Phase | Latest snapshot value | Tier 3 |
| 39 | Source_Last | Salesforce Cases | Source | Latest snapshot value | Tier 3 |
| 40 | Priority_Last | Salesforce Cases | Priority | Latest snapshot value | Tier 3 |
| 41 | Product_Last | Salesforce Cases | Product | Latest snapshot value | Tier 3 |
| 42 | Type_Last | Salesforce Cases | Type | Latest snapshot value | Tier 3 |
| 43 | ActionType_Last | Salesforce Cases | ActionType | Latest snapshot value | Tier 3 |
| 44 | SubType_Last | Salesforce Cases | SubType | Latest snapshot value | Tier 3 |
| 45 | SubType2_Last | Salesforce Cases | SubType2 | Latest snapshot value | Tier 3 |
| 46 | Country_Last | Salesforce Cases | Country | Latest snapshot value | Tier 3 |
| 47 | PlayerStatus_Last | Salesforce Cases | PlayerStatus | Latest snapshot value | Tier 3 |
| 48 | AccountManagerID_Last | Salesforce Cases | AccountManagerID | Latest snapshot value | Tier 3 |
| 49 | ActiveAgentID_Last | Salesforce Cases | ActiveAgentID | Latest snapshot value | Tier 3 |
| 50 | Owner_Last | Salesforce Cases | Owner | Latest snapshot value | Tier 3 |
| 51 | FirstCSAT | Salesforce Cases | FirstCSAT | Passthrough (external ETL) | Tier 3 |
| 52 | LastCSAT | Salesforce Cases | LastCSAT | Passthrough (external ETL) | Tier 3 |
| 53 | IsSupervisorCall | Salesforce Cases | IsSupervisorCall | Passthrough (external ETL) | Tier 3 |
| 54 | IsT3 | Salesforce Cases | IsT3 | Passthrough (external ETL) | Tier 3 |
| 55 | IsTechnicalTeam | Salesforce Cases | IsTechnicalTeam | Passthrough (external ETL) | Tier 3 |
| 56 | IsPPReport | Salesforce Cases | IsPPReport | Passthrough (external ETL) | Tier 3 |
| 57 | IsTmail | Salesforce Cases | IsTmail | Passthrough (external ETL) | Tier 3 |
| 58 | IsCOCall | Salesforce Cases | IsCOCall | Passthrough (external ETL) | Tier 3 |
| 59 | IsCHBCase | Salesforce Cases | IsCHBCase | Passthrough (external ETL) | Tier 3 |
| 60 | IsCOCase | Salesforce Cases | IsCOCase | Passthrough (external ETL) | Tier 3 |
| 61 | IsRisk | Salesforce Cases | IsRisk | Passthrough (external ETL) | Tier 3 |
| 62 | IsOfficial | Salesforce Cases | IsOfficial | Passthrough (external ETL) | Tier 3 |
| 63 | IsSpam | Salesforce Cases | IsSpam | Passthrough (external ETL) | Tier 3 |
| 64 | IsReopened | Salesforce Cases | IsReopened | Passthrough (external ETL) | Tier 3 |
| 65 | IsInternal | Salesforce Cases | IsInternal | Passthrough (external ETL) | Tier 3 |
| 66 | IsKYcMonitoring | Salesforce Cases | IsKYcMonitoring | Passthrough (external ETL) | Tier 3 |
| 67 | IsTechnicalRefund | Salesforce Cases | IsTechnicalRefund | Passthrough (external ETL) | Tier 3 |
| 68 | IsSocial | Salesforce Cases | IsSocial | Passthrough (external ETL) | Tier 3 |
| 69 | IsGoodwill | Salesforce Cases | IsGoodwill | Passthrough (external ETL) | Tier 3 |
| 70 | IsOneTouch | Salesforce Cases | IsOneTouch | Passthrough (external ETL) | Tier 3 |
| 71 | NumberOfTocuhes | Salesforce Cases | NumberOfTouches | Passthrough (external ETL, typo in column name) | Tier 3 |
| 72 | FirstResponse | Salesforce Cases | FirstResponse | Passthrough (external ETL) | Tier 3 |
| 73 | TotalTimeSpent | Salesforce Cases | TotalTimeSpent | Passthrough (external ETL) | Tier 3 |
| 74 | NumberIncomingMessages | Salesforce Cases | NumberIncomingMessages | Passthrough (external ETL) | Tier 3 |
| 75 | NumberOutgoingMessages | Salesforce Cases | NumberOutgoingMessages | Passthrough (external ETL) | Tier 3 |
| 76 | UpdateDate | Salesforce Cases | UpdateDate | Passthrough (external ETL) | Tier 3 |
| 77 | CloseDateTime | Salesforce Cases | CloseDateTime | Passthrough (external ETL) | Tier 3 |
| 78 | IsNormal | Salesforce Cases | IsNormal | Passthrough (external ETL) | Tier 3 |
| 79 | IsComplaint | Salesforce Cases | IsComplaint | Passthrough (external ETL) | Tier 3 |
| 80 | IsPhase2 | Salesforce Cases | IsPhase2 | Passthrough (external ETL) | Tier 3 |
| 81 | IsPhase3 | Salesforce Cases | IsPhase3 | Passthrough (external ETL) | Tier 3 |
| 82 | VerificationLevelID_AtOpen | Salesforce Cases | VerificationLevelID | Snapshot at ticket open | Tier 3 |
| 83 | VerificationLevelID_Last | Salesforce Cases | VerificationLevelID | Latest snapshot value | Tier 3 |
