CREATE OR REPLACE FUNCTION adm.get_supported_data_type_id(p_data_type_name text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	l_result int;
BEGIN
	SELECT id INTO l_result FROM supported_data_type t
	-- В aliases могут быть значения, разделенные запятыми
	WHERE p_data_type_name = ANY(string_to_array(concat(t.inner_name,',',t.aliases),','))
	LIMIT 1;

	RETURN l_result;
END;
$function$
;
