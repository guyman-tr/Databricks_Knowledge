/*

Get all requests from the http_requests table, parsing out helpful information to be used in the data source.

*/

WITH user_id_by_ip_address AS
(
    SELECT
        MAX(user_id)            AS user_id ,
        DATE_TRUNC('hour', created_at)
                                AS created_at_hour ,
        user_ip
    FROM http_requests
    WHERE user_id <> 0
    GROUP BY
        user_ip ,
        DATE_TRUNC('hour', created_at)
    HAVING COUNT(DISTINCT user_id) < 2
)

SELECT
    h.action ,
    h.completed_at ,
    h.controller ,
    h.created_at ,
    h.currentsheet ,
    h.http_referer ,
    h.http_user_agent ,
    h.http_request_uri ,
    h.remote_ip ,
    h.session_id ,
    h.user_cookie ,
    h.user_ip ,
    h.vizql_session ,
    h.worker ,
    h.id ,
    h.port ,
    h.site_id ,
    h.status ,
    COALESCE
    (
        NULLIF(h.user_id, 0) ,
        CASE
            WHEN h.vizql_session IS NOT NULL
                THEN MAX(NULLIF(h.user_id, 0)) OVER (PARTITION BY vizql_session)
            ELSE NULL
        END ,
        uip.user_id
    )                   AS user_id_imputed ,  --this is weird, but on purpose. 2019.2 fixed issues where user_id was not being accurately populated, so this prevents breakage from the legacy version.
                                                --edited: we expect the 2019.2 version to return a valid response to h.user_id, but legacy versions still need some help; added the uip.userid from previous versions to broaden compatability.  ~Kozar
    0                   AS user_id ,
    NULL                AS user_id_imputation_method ,

    -- The point of this nasty CASE statement is to try and extract a valid repository URL for views, workbooks, or data sources that requests are executed against.
    CASE
        WHEN COALESCE(h.currentsheet, '') = '' OR h.currentsheet LIKE '% %' OR currentsheet LIKE '%/null'
          THEN
            -- wrap all this to remove periods in URLs, e.g. "SDOR/TFSDefectsSinceRelease.pdf"
            SPLIT_PART (
                CASE SPLIT_PART(http_request_uri, '/', 2)
                    WHEN 'views'
                        THEN SPLIT_PART(http_request_uri, '/', 3) || '/' || SPLIT_PART(SPLIT_PART(http_request_uri, '/', 4), '?', 1)
                    WHEN 't'  -- string is heading with the site id
                        THEN SPLIT_PART(http_request_uri, '/', 5) || '/' || SPLIT_PART(SPLIT_PART(http_request_uri, '/', 6), '?', 1)
                    WHEN 'trusted'
                        THEN SPLIT_PART(http_request_uri, '/', 5) || '/' || SPLIT_PART(SPLIT_PART(http_request_uri, '/', 6), '?', 1)
                    WHEN 'vizql'
                        THEN
                            CASE SPLIT_PART(REPLACE(http_request_uri, ('/vizql/t/' || COALESCE(s.url_namespace, '')), '/vizql'), '/', 3)  -- trim off any site names for consistency
                                WHEN 'w'
                                    THEN
                                        CASE
                                            LEFT(
                                                REPLACE(
                                                    http_request_uri,
                                                    ('/vizql/t/' || COALESCE(s.url_namespace, '')),
                                                    '/vizql'
                                                ),
                                                12
                                            )
                                            WHEN '/vizql/w/ds:'
                                                THEN
                                                    REPLACE(
                                                        SPLIT_PART(REPLACE(http_request_uri, ('/vizql/t/' || COALESCE(s.url_namespace, '')), '/vizql'), '/', 4),
                                                        'ds:',
                                                        ''
                                                    )
                                            ELSE
                                                -- strip data source indicator off the front of the string
                                                SPLIT_PART(
                                                    REPLACE(http_request_uri, ('/vizql/t/' || COALESCE(s.url_namespace, '')), '/vizql'),
                                                    '/',
                                                    4
                                                )                                                                                               -- workbook name
                                                ||
                                                CASE
                                                  SPLIT_PART(
                                                      REPLACE(http_request_uri, ('/vizql/t/' || COALESCE(s.url_namespace, '')), '/vizql'),
                                                      '/',
                                                      6
                                                  )
                                                  WHEN 'null'       -- sometimes in ostensiby web-edit scenarios, the sheet name is "null", so strip it out
                                                    THEN ''
                                                  ELSE '/' ||
                                                    SPLIT_PART(
                                                        REPLACE(http_request_uri, ('/vizql/t/' || COALESCE(s.url_namespace, '')), '/vizql'),
                                                        '/',
                                                        6
                                                    )
                                                END                                                                                             -- sheet name
                                        END
                                WHEN 'authoring'
                                    THEN ''
                                ELSE ''
                            END
                    WHEN 'askData'
                        THEN SPLIT_PART(http_request_uri, '/', 3)
                    WHEN 'authoringNewWorkbook'
                        THEN SPLIT_PART(http_request_uri, '/', 4)
                    WHEN 'authoring'
                        THEN SPLIT_PART(http_request_uri, '/', 3) || '/' || SPLIT_PART(SPLIT_PART(http_request_uri, '/', 4), '?', 1)
                    WHEN 'startAskData'
                        THEN SPLIT_PART(SPLIT_PART(http_request_uri, '/', 3), '?', 1)
                    WHEN 'offline_views'
                        THEN SPLIT_PART(http_request_uri, '/', 3) || '/' || SPLIT_PART(SPLIT_PART(http_request_uri, '/', 4), '?', 1)

                    --  these are useless at present
                    --WHEN 'newWorkbook'
                    --    THEN ''

                    --WHEN 'admin'
                    --    THEN ''

                    ELSE NULL
                END,
                '.',
                1
            )
          ELSE
        -- we can use the currentsheet field
        CASE WHEN ( LEFT(currentsheet, 3) = 'ds:' OR LEFT(http_request_uri, 22) = '/authoringNewWorkbook/' OR LEFT(http_request_uri, 12) = '/vizql/w/ds:')
            THEN
                -- this is a web edit on a data source or workbook, so strip out the "ds" for data sources and build the repository url
                SPLIT_PART(REPLACE(h.currentsheet, 'ds:', ''), '/', 1)
            ELSE
                SPLIT_PART(REPLACE(h.currentsheet, 'ds:', ''), '/', 1)
                || '/' ||
                SPLIT_PART(REPLACE(h.currentsheet, 'ds:', ''), '/', 2)
        END
    END                 AS item_repository_url ,

    CASE
        WHEN currentsheet LIKE 'ds:%' OR LEFT(http_request_uri, 12) = '/vizql/w/ds:' OR LEFT(http_request_uri, 9) = '/askData/'
            THEN 'Data Source'
        WHEN http_request_uri LIKE '/authoringNewWorkbook/%'
            OR
                (
                -- this logic is to trap the right type of item for certain web-edit scenarios that seem to come up
                SPLIT_PART(
                    REPLACE(http_request_uri, ('/vizql/t/' || COALESCE(s.url_namespace, '')), '/vizql'),
                    '/',
                    6
                    ) = 'null'
                AND
                currentsheet NOT LIKE '%/%'
                )
            THEN 'Workbook'
        ELSE 'View'   -- this, like cake, is a lie. many of these records may not really be referring to a view. but for our LEFT join, it will make sense and be less complicated.
    END                 AS item_type ,

    CASE
        WHEN COALESCE(currentsheet, '') <> ''
            THEN SPLIT_PART(currentsheet, '/', 3)
        ELSE NULL
    END                 AS customized_view_owner ,
    CASE
        WHEN COALESCE(currentsheet, '') <> ''
            THEN SPLIT_PART(currentsheet, '/', 4)
        ELSE NULL
    END                 AS customized_view_name

FROM http_requests AS h
    LEFT JOIN sites AS s
        ON h.site_id = s.id
    LEFT JOIN user_id_by_ip_address AS uip
        ON h.user_ip = uip.user_ip
            AND DATE_TRUNC('hour', h.created_at) = uip.created_at_hour