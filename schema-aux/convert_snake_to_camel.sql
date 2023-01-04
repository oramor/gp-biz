CREATE OR REPLACE FUNCTION aux.convert_snake_to_camel(p_snake_case text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
	l_pascal text;
BEGIN
	l_pascal := convert_snake_to_pascal(p_snake_case);
	return lower(left(l_pascal, 1)) || right(l_pascal, -1);
end;
$function$
;
