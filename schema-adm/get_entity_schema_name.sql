CREATE OR REPLACE FUNCTION adm.get_entity_schema_name(p_entity_id integer)
 RETURNS text
 LANGUAGE sql
AS $function$
	SELECT concat('api_', t.inner_name) FROM md_table t WHERE id IN (
		SELECT e.md_table_id FROM entity e WHERE e.id = p_entity_id
	);
$function$
;
