CREATE OR REPLACE FUNCTION adm.is_column_for_view(p_column_name TEXT)
RETURNS bool
LANGUAGE sql
AS $function$
	SELECT NOT EXISTS (
		SELECT 1 FROM abstract_column a 
		WHERE a.snake_name = lower(p_column_name)
			AND a.is_for_view = FALSE);
$function$
;
