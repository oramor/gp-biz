CREATE OR REPLACE FUNCTION aux.convert_dotted_to_snake(p_dotted_name text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
	RETURN replace(lower(p_dotted_name), '.','_');
END;
$function$
;
