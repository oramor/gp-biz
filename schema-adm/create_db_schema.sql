CREATE OR REPLACE PROCEDURE adm.create_db_schema(OUT p_schema_id integer, IN p_schema_name text)
 LANGUAGE plpgsql
AS $procedure$
BEGIN
	EXECUTE format('CREATE SCHEMA IF NOT EXISTS %s', p_schema_name);

	INSERT INTO db_schema (inner_name) VALUES (p_schema_name);

	SELECT id INTO p_schema_id FROM db_schema t WHERE t.inner_name = lower(p_schema_name); 
END;
$procedure$
;
