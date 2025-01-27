-- Test group_update_time_trigger

/*
    1. Inserts new group owned by uses with id=1
    2. Checks update time (same sa creation_time or null)
    3. Updates description
    4. Checks update time (new)
*/
BEGIN;
INSERT INTO "home budget application".groups (group_name, group_description, creation_time, update_time, owner_id)
VALUES ('Test Group', 'Description', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1);

SELECT update_time FROM "home budget application".groups WHERE owner_id=1 AND group_name='Test Group';

UPDATE "home budget application".groups SET group_description='NEW Description' WHERE owner_id=1 AND group_name='Test Group';

SELECT update_time, group_description FROM "home budget application".groups WHERE owner_id=1 AND group_name='Test Group';

COMMIT;