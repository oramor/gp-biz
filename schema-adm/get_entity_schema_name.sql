CREATE OR REPLACE FUNCTION adm.get_entity_schema_name(p_entity_id integer)
 RETURNS text
 LANGUAGE sql
AS $function$
	SELECT s.inner_name FROM db_schema s WHERE id IN (
		SELECT e.db_schema_id FROM entity e WHERE e.id = p_entity_id);
$function$
;
