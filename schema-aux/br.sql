CREATE OR REPLACE FUNCTION aux.br(p_cnt integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
	t TEXT = '';
BEGIN
	FOR i IN 1..p_cnt LOOP
		t := t||chr(10);
	END LOOP;
	
	RETURN t;
END;
$function$
;
