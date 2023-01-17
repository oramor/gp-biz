CREATE OR REPLACE FUNCTION adm.get_entity_schema_name(p_entity_id integer)
 RETURNS text
 LANGUAGE sql
AS $function$
	SELECT concat('api_', t.inner_name) FROM db_table t WHERE id IN (
		SELECT e.db_table_id FROM entity e WHERE e.id = p_entity_id
	);
$function$
;
