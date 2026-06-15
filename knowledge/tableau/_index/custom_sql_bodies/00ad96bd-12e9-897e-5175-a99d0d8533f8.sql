--generate a delimited list of collections for each bit of content
SELECT
    ali.useable_luid ,
    ali.useable_type ,
    string_agg(al.name, ',')       As "Collection List"
FROM asset_lists al
    INNER JOIN asset_list_items ali
        ON al.id = ali.asset_list_id
WHERE al.list_type = 'collection'
GROUP BY
    ali.useable_luid ,
    ali.useable_type