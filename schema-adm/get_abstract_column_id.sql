CREATE OR REPLACE FUNCTION adm.get_abstract_column_id(p_column_name TEXT)
RETURNS int4
LANGUAGE sql
AS $function$
	SELECT a.id FROM abstract_column a WHERE a.snake_name = lower(p_column_name);
$function$
;
