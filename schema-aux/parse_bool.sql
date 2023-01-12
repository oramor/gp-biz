CREATE OR REPLACE FUNCTION aux.parse_bool(p_json jsonb, p_key text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	l_value bool;
BEGIN
	/* Эта функция неявно возвращает false, если нужный ключ отсутствует*/
	l_value := (p_json->>p_key)::bool;
	RETURN coalesce(l_value, false);
EXCEPTION WHEN OTHERS THEN
		RAISE EXCEPTION 'Parsing error: %', SQLERRM;
END;
$function$
;
