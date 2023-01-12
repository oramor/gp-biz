CREATE OR REPLACE FUNCTION aux.req(p_value boolean)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF p_value IS NULL THEN
		RAISE EXCEPTION 'Parameter bool is requred';
	END IF;

	RETURN p_value;
END;
$function$
;
