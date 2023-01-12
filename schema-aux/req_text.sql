CREATE OR REPLACE FUNCTION aux.req(p_value text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF p_value IS NULL THEN
		RAISE EXCEPTION 'Parameter text is requred';
	END IF;

	RETURN p_value;
END;
$function$
;
