-- create the i2b2 audit 
DROP TABLE IF EXISTS i2b2pm.pm_rplugin_audit;
CREATE TABLE i2b2pm.pm_rplugin_audit
(
rplugin_audit_id bigserial PRIMARY KEY,
user_id            character varying NOT NULL,
session_id         character varying NOT NULL,
project_id         character varying NOT NULL,
result_instance_id integer NOT NULL,
user_role_cd       character varying,
action             character varying, 
start_date         timestamp NOT NULL,
end_date           timestamp,
parameters         jsonb NOT NULL,
has_status_ok      boolean,
error_msg          character varying
);
