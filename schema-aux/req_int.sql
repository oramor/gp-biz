CREATE OR REPLACE FUNCTION aux.req(p_value integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF p_value IS NULL THEN
		RAISE EXCEPTION 'Parameter int is requred';
	END IF;

	RETURN p_value;
END;
$function$
;
