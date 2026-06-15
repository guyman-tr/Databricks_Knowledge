WITH owner_change AS (
    SELECT 
        ch.CaseId,
        ch.CreatedDate AS OwnerChangeDate,
        ch.OldValue AS PreviousOwner,
        ch.NewValue AS NewOwner
    FROM crm.silver_crm_casehistory ch
    WHERE ch.NewValue = 'OPS CS AML'
      AND YEAR(ch.CreatedDate) >= 2025
),
status_before AS (
    SELECT
        oc.CaseId,
        oc.OwnerChangeDate,
        ch.CreatedDate AS RerouteDate,
        ch.NewValue AS StatusBefore,
        ROW_NUMBER() OVER (
            PARTITION BY oc.CaseId, oc.OwnerChangeDate
            ORDER BY ch.CreatedDate DESC
        ) AS rn
    FROM crm.silver_crm_casehistory ch
    JOIN owner_change oc 
        ON ch.CaseId = oc.CaseId
       AND ch.CreatedDate < oc.OwnerChangeDate
    WHERE ch.Field = 'Status'
),
table1 AS (
    SELECT
        oc.CaseId,
        oc.OwnerChangeDate,
        oc.PreviousOwner,
        oc.NewOwner,
        sb.RerouteDate,
        sb.StatusBefore,
        NULL AS StatusChangeDate,
        NULL AS StatusAfter,
        NULL AS LatestOwner,
        CASE 
          WHEN oc.NewOwner = 'OPS CS AML' THEN oc.OwnerChangeDate
        END AS IncomingDate
    FROM owner_change oc
    LEFT JOIN status_before sb 
        ON oc.CaseId = sb.CaseId 
       AND oc.OwnerChangeDate = sb.OwnerChangeDate 
       AND sb.rn = 1
),
status_changes AS (
    SELECT 
        ch.CaseId,
        ch.CreatedDate AS StatusChangeDate, 
        ch.OldValue AS StatusBefore, 
        ch.NewValue AS StatusAfter
    FROM crm.silver_crm_casehistory ch
    WHERE ch.Field = 'Status'
      AND ch.NewValue IN ('Open','New','On- it')
      AND YEAR(ch.CreatedDate) >= 2025
),
latest_owner AS (
    SELECT
        sc.CaseId,
        sc.StatusChangeDate,
        oc.CreatedDate AS OwnerChangeDate,
        oc.NewValue AS OwnerNewValue,
        ROW_NUMBER() OVER (
            PARTITION BY sc.CaseId, sc.StatusChangeDate
            ORDER BY oc.CreatedDate DESC
        ) AS rn
    FROM status_changes sc
    LEFT JOIN crm.silver_crm_casehistory oc
        ON sc.CaseId = oc.CaseId
       AND oc.Field = 'Owner'
       AND oc.CreatedDate <= sc.StatusChangeDate
),
table2 AS (
    SELECT
        sc.CaseId,
        lo.OwnerChangeDate,
        NULL AS PreviousOwner,
        NULL AS NewOwner,
        NULL AS RerouteDate,
        sc.StatusBefore,
        sc.StatusChangeDate,
        sc.StatusAfter,
        'OPS CS AML' AS LatestOwner,
        sc.StatusChangeDate AS IncomingDate
    FROM status_changes sc
    JOIN latest_owner lo
        ON sc.CaseId = lo.CaseId
       AND sc.StatusChangeDate = lo.StatusChangeDate
       AND lo.rn = 1
    WHERE lo.OwnerNewValue IN ('OPS CS AML','00G08000002gMZfEAM')
), final as (
SELECT * 
FROM table1
UNION ALL
SELECT * 
FROM table2
ORDER BY CaseId, IncomingDate)
select cc.*,IncomingDate from final f 
left join bi_output.bi_output_customer_customer_support_case cc on cc.CaseID=f.CaseId
where cc.Status NOT IN ('Solved','Closed')