CREATE OR REPLACE FUNCTION aux.parse_text(p_json jsonb, p_key text)
 RETURNS text
 LANGUAGE sql
AS $function$
	SELECT p_json->>p_key;
$function$
;
