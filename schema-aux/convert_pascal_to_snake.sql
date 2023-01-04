CREATE OR REPLACE FUNCTION aux.convert_pascal_to_snake(p_pascal_case text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
	l_result TEXT;
BEGIN
	SELECT trim(both '_' from lower(regexp_replace(p_pascal_case, '([A-Z])','_\1', 'g'))) INTO l_result;
	RETURN l_result;
END;
$function$
;
