CREATE OR REPLACE FUNCTION aux.convert_timestamp_to_date(p_ts timestamp with time zone)
 RETURNS text
 LANGUAGE sql
AS $function$
	SELECT to_char(p_ts, 'DD.MM.YYYY');
$function$
;
