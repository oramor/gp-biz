CREATE OR REPLACE FUNCTION adm.get_logical_data_type_id(p_column_name text)
 RETURNS integer
 LANGUAGE sql
AS $function$
	SELECT a.logical_data_type_id FROM abstract_column a WHERE a.snake_name = p_column_name;
$function$
;
