CREATE TRIGGER group_update_time_trigger
BEFORE UPDATE ON "home budget application".groups 
FOR EACH ROW EXECUTE FUNCTION "home budget application".update_group_update_time()

CREATE TRIGGER user_update_time_trigger
BEFORE UPDATE ON "home budget application".users
FOR EACH ROW EXECUTE FUNCTION "home budget application".update_user_update_time();

CREATE TRIGGER update_wallet_balance_trigger
BEFORE INSERT ON "home budget application".users_groups_transactions
FOR EACH ROW EXECUTE FUNCTION "home budget application".update_wallet_balance()