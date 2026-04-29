# BI_DB_dbo.BI_DB_RiskAlertManagementTool — Column Lineage

## Source Objects

| Source | Schema | Role |
|--------|--------|------|
| External_AlertServiceDB_Alert_Alert | BI_DB_dbo | Core alert records + JSON columns (UnsatisfiedRulesData, Resource) |
| External_AlertServiceDB_Configuration_AlertTemplate | BI_DB_dbo | Alert template → AlertTypeID, CategoryID, TriggerType mapping |
| External_AlertServiceDB_Dictionary_AlertType | BI_DB_dbo | AlertType name + description |
| External_AlertServiceDB_Dictionary_Category | BI_DB_dbo | Category name (KYC, Risk, Cashouts, AML, etc.) |
| External_AlertServiceDB_Dictionary_TriggerType | BI_DB_dbo | Trigger type name (OneTime, Recurring, None) |
| External_AlertServiceDB_Configuration_AlertStatus | BI_DB_dbo | Status → StatusTypeID, StatusReasonID mapping |
| External_AlertServiceDB_Dictionary_StatusType | BI_DB_dbo | Status type name (Active, Clear, Follow Up) |
| External_AlertServiceDB_Dictionary_StatusReason | BI_DB_dbo | Status reason name |
| External_AlertServiceDB_Configuration_ReasonToClassification | BI_DB_dbo | Status reason → classification mapping |
| External_AlertServiceDB_Dictionary_StatusClassification | BI_DB_dbo | Alert Status Reason name |

## Column Lineage

| Target Column | Source | Source Column | Transform |
|---------------|--------|---------------|-----------|
| AlertID | External_AlertServiceDB_Alert_Alert | Id | Rename |
| CID | External_AlertServiceDB_Alert_Alert | CID | Passthrough |
| Assignee | External_AlertServiceDB_Alert_Alert | Assignee | Passthrough |
| ModifiedBy | External_AlertServiceDB_Alert_Alert | ModifiedBy | Passthrough |
| Comment | External_AlertServiceDB_Alert_Alert | Comment | Passthrough |
| CreationDate | External_AlertServiceDB_Alert_Alert | CreationDate | Passthrough |
| ModificationDate | External_AlertServiceDB_Alert_Alert | ModificationDate | Passthrough |
| TicketID | External_AlertServiceDB_Alert_Alert | TicketID | Passthrough |
| FundingID | External_AlertServiceDB_Alert_Alert | FundingID | Passthrough |
| ResourceType | External_AlertServiceDB_Alert_Alert | ResourceType | Passthrough |
| FollowUpDate | External_AlertServiceDB_Alert_Alert | FollowUpDate | Passthrough |
| AlertType | External_AlertServiceDB_Dictionary_AlertType | Name | Dim-lookup (via AlertTemplate.AlertTypeID) |
| AlertTypeDescription | External_AlertServiceDB_Dictionary_AlertType | Description | Dim-lookup |
| CategoryName | External_AlertServiceDB_Dictionary_Category | Name | Dim-lookup (via AlertTemplate.CategoryID) |
| TriggerType | External_AlertServiceDB_Dictionary_TriggerType | Name | Dim-lookup (via AlertTemplate.TriggerType) |
| StatusType | External_AlertServiceDB_Dictionary_StatusType | Name | Dim-lookup (via AlertStatus.StatusTypeID) |
| StatusReason | External_AlertServiceDB_Dictionary_StatusReason | Name | Dim-lookup (via AlertStatus.StatusReasonID) |
| Alert Status Reason | External_AlertServiceDB_Dictionary_StatusClassification | Name | Dim-lookup (via ReasonToClassification) |
| Tables | — | 'Current' | Hardcoded literal |
| RN | Computed | ROW_NUMBER() OVER (PARTITION BY Id ORDER BY ModificationDate DESC) | Deduplication rank (from #current) |
| RN1 | Computed | ROW_NUMBER() OVER (PARTITION BY AlertID ORDER BY ModificationDate DESC) | Final deduplication rank |
| UpdateDate | — | GETDATE() | ETL timestamp |
| Cols 22-65 (AllowedTelesignScore...YearlySum) | External_AlertServiceDB_Alert_Alert | OPENJSON(UnsatisfiedRulesData, '$.EvaluationContext') | JSON path extraction → 44 flat columns |
| Cols 66-105 (AccountGuid...RiskClassification1) | External_AlertServiceDB_Alert_Alert | OPENJSON(Resource) | JSON path extraction → 37 flat columns (suffix "1" for duplicates) |

## ETL Pattern

- **SP**: BI_DB_dbo.SP_RiskAlertManagementTool
- **Schedule**: Daily (SB_Daily, Priority 0)
- **Load**: DELETE by ModificationDate/FollowUpDate on @Date + DELETE by AlertID (upsert), then INSERT from current day's alerts with flattened JSON
- **Author**: Pavlina Masoura (created 2025-02-27, JSON columns added 2025-11-06)
- **JSON parsing**: OPENJSON with explicit schema (WITH clause) for both UnsatisfiedRulesData.EvaluationContext and Resource columns
