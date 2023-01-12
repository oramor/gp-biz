CREATE OR REPLACE FUNCTION aux.parse_int(p_json jsonb, p_key text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	l_value int;
BEGIN
	l_value := (p_json->>p_key)::int;
	RETURN l_value;
EXCEPTION WHEN OTHERS THEN
		RAISE EXCEPTION 'Parsing error: %', SQLERRM;
END;
$function$
;
