CREATE OR REPLACE FUNCTION adm.is_column_for_join(p_column_name text)
 RETURNS boolean
 LANGUAGE sql
AS $function$
	SELECT EXISTS (
		SELECT 1 FROM abstract_column a 
		WHERE a.snake_name = lower(p_column_name)
			AND a.is_for_join = TRUE);
$function$
;
