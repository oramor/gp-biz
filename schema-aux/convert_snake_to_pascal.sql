CREATE OR REPLACE FUNCTION aux.convert_snake_to_pascal(p_snake_case text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
begin
	return
    	replace(
      		initcap(
        		replace(p_snake_case, '_', ' ')
      		),
      	' ', ''
    );
end;
$function$
;
