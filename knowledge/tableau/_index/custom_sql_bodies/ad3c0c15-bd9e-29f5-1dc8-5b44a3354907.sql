--generate a delimited list of tags for each bit of content
SELECT
    ts.taggable_id ,
    ts.taggable_type ,
    string_agg(t.name, ',')       As "Tag List"
FROM taggings ts
    INNER JOIN tags t
        ON ts.tag_id = t.id
GROUP BY 
    ts.taggable_id ,
    ts.taggable_type