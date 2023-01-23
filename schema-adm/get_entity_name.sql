CREATE OR REPLACE FUNCTION adm.get_entity_name(p_entity_id int)
	RETURNS text
	LANGUAGE sql
AS $function$
	SELECT pascal_name FROM biz_object b
	WHERE b.id IN (SELECT e.biz_object_id FROM entity e WHERE e.id = p_entity_id);
$function$
;
