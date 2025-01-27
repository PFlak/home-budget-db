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

-- Test user_update_time_trigger

/*
    1. Inserts new user
    2. Checks update time (same sa creation_time or null)
    3. Updates email
    4. Checks update time (new)
*/
BEGIN;
INSERT INTO "home budget application".users (name, nick_name, email, user_password, salt, country_id)
VALUES ('Tester', 'Tester#2', 'email', 'password', 'salt', 1);

SELECT update_time FROM "home budget application".users WHERE nick_name='Tester#2';

UPDATE "home budget application".users SET email='NEW email' WHERE nick_name='Tester#2';

SELECT update_time, email FROM "home budget application".users WHERE nick_name='Tester#2';

COMMIT;

-- Test add_currency function
BEGIN;
SELECT * FROM "home budget application".add_currency('Zloty', 'PLN', 0.2493);
COMMIT;

-- Test add_country function
BEGIN;
SELECT * FROM "home budget application".add_country(
    'Poland', 'PL', 'PLN'
);
COMMIT;

-- Test add_category function
SELECT * FROM "home budget application".add_category('Shopping', 'General shopping');

-- Test add_subdirectory function
SELECT * FROM "home budget application".add_subcategory('Clothes', NULL, 'Entertainment');
-- Error
SELECT * FROM "home budget application".add_subcategory('Clothes', NULL, 'Shopping');
-- Success

