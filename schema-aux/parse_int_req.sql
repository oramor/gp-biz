CREATE OR REPLACE FUNCTION aux.parse_int_req(p_json jsonb, p_key text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	l_value int;
BEGIN
	l_value := (p_json->>p_key)::int;

	IF l_value IS NULL THEN
		RAISE EXCEPTION 'Null is not available for json key [ % ]', p_key;
	END IF;

	RETURN l_value;
EXCEPTION WHEN OTHERS THEN
		RAISE EXCEPTION 'Parsing error: %', SQLERRM;
END;
$function$
;
