CREATE TRIGGER group_update_time_trigger
BEFORE UPDATE ON "home budget application".groups 
FOR EACH ROW EXECUTE FUNCTION "home budget application".update_group_update_time()