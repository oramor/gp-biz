CREATE OR REPLACE FUNCTION aux.state(p_state_name text)
 RETURNS text
 LANGUAGE sql
AS $function$
	SELECT concat('(',chr(39),p_state_name,chr(39),')','::state_tp');
$function$
;
