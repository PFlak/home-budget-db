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

-- Test create_user function
SELECT * FROM "home budget application".create_user('Tester', 'tester@domain.com', 'password', 'PL', NULL, 'tester');
-- Success
SELECT * FROM "home budget application".create_user('Tester', 'tester@domain.com', 'password', 'PLN', NULL, 'tester');
-- Error
SELECT * FROM "home budget application".create_user('Tester', 'testerdomain.com', 'password', 'PL', NULL, 'tester');
-- Error
SELECT * FROM "home budget application".create_user('Tester', 'tester1@domain.com', 'password', 'PL', NULL, 'tester');
-- Success


-- Test login_user function
SELECT * FROM "home budget application".login_user('tester@domain.com', 'password');
-- Got: da37d8301bc2dd827949e0701a69824e
-- Success
SELECT * FROM "home budget application".login_user('tester@domain.com', 'password1');
-- Error
SELECT * FROM "home budget application".login_user('tester2@domain.com', 'password');
-- Error


-- Test verify_session function
SELECT * FROM "home budget application".verify_session('da37d8301bc2dd827949e0701a69824e');
-- Success
SELECT * FROM "home budget application".verify_session('da37d8301bc2dd827949e0701a698');
-- Error

-- Test create_wallet function
SELECT * FROM "home budget application".create_wallet('da37d8301bc2dd827949e0701a69824e', 'Test wallet', 'USD');
-- Success
SELECT * FROM "home budget application".create_wallet('wrong_session_hash', 'Test wallet', 'USD');
-- Error
SELECT * FROM "home budget application".create_wallet('da37d8301bc2dd827949e0701a69824e', 'Test wallet', 'NOT');
-- Error

-- Test create group and join group and change user role in group
DO $$
DECLARE
	admin_session_hash TEXT;
	test_group_id INTEGER;
BEGIN
    -- Create an admin user
    PERFORM "home budget application".create_user(
        'AdminUser', 'admin1@example.com', 'adminpassword', 'PL', 'adminuser', 'adminuser', NULL
    );

    -- Log in the admin user to get a session hash
    SELECT * INTO admin_session_hash FROM "home budget application".login_user('admin1@example.com', 'adminpassword');

    -- Create a group
    SELECT group_id INTO test_group_id FROM "home budget application".create_group(
        admin_session_hash, 'Test Group', 'This is a test group'
    );

    -- Add another user
    PERFORM "home budget application".create_user(
        'RegularUser', 'user1@example.com', 'userpassword', 'PL', 'guestuser', 'guestuser', NULL
    );

    -- Admin adds the regular user to the group
    PERFORM "home budget application".join_group(
        admin_session_hash, test_group_id, 'guest'
    );

    -- Admin changes the role of the regular user within the group
    PERFORM "home budget application".change_user_permission_in_group(
        admin_session_hash, 'user1@example.com', test_group_id, 'admin'
    );
END $$;

