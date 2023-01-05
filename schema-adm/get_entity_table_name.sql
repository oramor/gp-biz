CREATE OR REPLACE FUNCTION adm.get_entity_table_name(p_entity_id integer)
 RETURNS text
 LANGUAGE sql
AS $function$
	SELECT inner_name FROM md_table WHERE id IN (
		SELECT e.md_table_id FROM entity e WHERE e.id = p_entity_id
	);
$function$
;
