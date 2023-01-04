CREATE OR REPLACE PROCEDURE adm.create_entity_log_trigger_bu(IN p_table_name text)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_sql text;
BEGIN
	l_sql :=
	'CREATE OR REPLACE TRIGGER '||p_table_name||'_tbu'||br(1)||
	'	BEFORE UPDATE ON biz.'||p_table_name||br(1)||
	'FOR EACH ROW'||br(1)||
	'	EXECUTE FUNCTION log_trigger_bu('||quote_literal(p_table_name)||');';
	
	EXECUTE l_sql;
END;
$procedure$
;
