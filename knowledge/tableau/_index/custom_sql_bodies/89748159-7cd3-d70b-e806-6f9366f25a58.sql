WITH FilteredCases AS (
    SELECT
        c.id AS CaseId,
        c.CaseNumber,
        c.CID__c,
        to_timestamp(c.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate,
        c.Origin,
        c.Category__c,
        c.Type__c,
        c.Initial_Sub_Type__c,
        c.Initial_Sub_Type_2__c,
        c.Sub_Type__c,
        c.Sub_Type_2__c,
        c.Country__c,
        c.IsClosedOnCreate,
        dictc.name as Registration_country,
        CASE
            WHEN
                (c.initial_sub_type__c in ("2FA")
                and c.Initial_Sub_Type_2__c in ("2FA -Other",
                "Cannot activate",
                "Code not working",
                "Did not receive voice call",
                "Didn't receive SMS"))  THEN "2FA"
            WHEN
                c.initial_sub_type__c in
                ("General question - Other",
                "Account details - Other",
                "My Profile")  THEN 'General Question Cases'
            WHEN
                c.initial_sub_type__c in
                ("Cannot withdraw",
                "Withdrawal - Other",
                "Status of withdrawal") THEN 'Withdrawal Cases'
            WHEN c.initial_sub_type__c = "Login issues"  THEN "Login Issue Cases"
            WHEN c.sub_type__c = "Phone Verification" THEN "Phone Verification Cases"
            WHEN (c.initial_sub_type__c ="Detail Change" and c.Initial_Sub_Type_2__c ="Phone")  THEN "Phone Detail Change Cases"
            WHEN (c.initial_sub_type__c = "Detail Change" and c.Initial_Sub_Type_2__c in
                    ("Details change - Other",
                    "Email",
                    "Address"))
                    THEN 'Detail Change Cases'
            -- WHEN c.initial_sub_type__c = 'Trade cannot be opened' and dictc.name='Germany' THEN 'Trade Cannot Be Opened'
            -- WHEN c.initial_sub_type__c ='Trade cannot be closed' and dictc.name='Germany'  THEN  'Trade Cannot Be Closed'
            WHEN c.initial_sub_type__c ="General technical issues - Other" then "General Tech Issue"
            ELSE null
        END as classification
    FROM main.crm.silver_crm_case c
    LEFT JOIN general.bronze_etoro_customer_customer_masked cm
    ON c.cid__c = cm.cid
    LEFT JOIN general.bronze_etoro_dictionary_country dictc
        ON cm.countryID = dictc.countryID
    WHERE  CreatedDate > '2024-11-22' and origin in ('Portal','Email')
),
FollowUpCases AS (
    SELECT c1.cid__c,c1.category__c,to_timestamp(c1.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') as CreatedDate,c1.origin
        FROM main.crm.silver_crm_case c1
        LEFT JOIN main.crm.silver_crm_livechattranscript t
            ON c1.id = t.caseid
        WHERE to_timestamp(c1.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')>'2024-11-22' and (t.visitormessagecount>0 or t.visitormessagecount is null)
-- follow up cases can be from both portal and email
),
DeflectedCases AS (
    SELECT
        c.casenumber,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM FollowUpCases p
                WHERE p.CID__c = c.CID__c
                    AND (p.Category__c = c.Category__c or p.origin in ('Chatbot','Chat'))
                    AND p.CreatedDate > c.CreatedDate
                    AND p.CreatedDate <= c.CreatedDate + INTERVAL '24 hour'
            ) THEN FALSE
            ELSE TRUE
        END AS IsDeflected
    FROM (
        SELECT DISTINCT
            CID__c,
            Category__c,
            CreatedDate,
            casenumber
        FROM FilteredCases
    ) c
)
SELECT
    case1.CaseId,
    case1.CaseNumber,
    case1.CID__c,
    case1.CreatedDate,
    case1.Origin,
    case1.Category__c,
    case1.Type__c,
    case1.Initial_Sub_Type__c,
    case1.Initial_Sub_Type_2__c,
    case1.Sub_Type__c,
    case1.Sub_Type_2__c,
    case1.Country__c,
    case1.IsClosedOnCreate,
    case1.classification,
    case1.Registration_country,
    COALESCE(dc.IsDeflected, FALSE) AS IsDeflected
FROM FilteredCases case1
LEFT JOIN DeflectedCases dc
ON case1.casenumber = dc.casenumber
WHERE  case1.classification is not null AND NOT (Registration_country = 'United States')