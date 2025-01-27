CREATE OR REPLACE FUNCTION "home budget application".calc_currency(
    input_dollar_rate numeric,
    output_dollar_rate numeric,
    input_value numeric
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN input_value * input_dollar_rate / output_dollar_rate;
END;
$function$
;


/*
    Updates update_time in group that changes were made
*/
CREATE OR REPLACE FUNCTION "home budget application".update_group_update_time()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
;

/*
    Updates update_time in user that changes were made
*/
CREATE OR REPLACE FUNCTION "home budget application".update_user_update_time()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.update_time = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
;

-- Trigger function to update wallet balance
CREATE OR REPLACE FUNCTION "home budget application".update_wallet_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_transaction "home budget application".transactions%ROWTYPE;
    v_wallet "home budget application".wallets%ROWTYPE;

    v_in_dollar_rate numeric;
    v_out_dollar_rate numeric;
    v_calc_value numeric;
BEGIN
    SELECT * INTO v_transaction
    FROM "home budget application".transactions
    WHERE transaction_id = NEW.transaction_id;

    IF v_transaction.transaction_id IS NULL THEN
        RAISE EXCEPTION 'Transaction with id % does not exist', NEW.transaction_id;
        RETURN OLD;
    END IF;

    SELECT * INTO v_wallet
    FROM "home budget application".wallets
    WHERE wallet_id = NEW.wallet_id;

    IF v_wallet.wallet_id IS NULL THEN
        RAISE EXCEPTION 'Wallet with id % does not exist', NEW.wallet_id;
        RETURN OLD;
    END IF;

    -- Get dollar rate from transaction currency
    SELECT dollar_rate INTO v_in_dollar_rate
    FROM "home budget application".currency
    WHERE currency_id = v_transaction.currency_id;

    -- Get dollar rate of wallet currency
    SELECT dollar_rate INTO v_out_dollar_rate
    FROM "home budget application".currency
    WHERE currency_id = v_wallet.currency_id;

    -- Calculate the transaction value in the wallet currency
    v_calc_value := "home budget application".calc_currency(
        v_in_dollar_rate, v_out_dollar_rate, v_transaction.value
    );

    -- Update the wallet balance based on transaction type
    IF v_transaction.transaction_type = 'withdraw'::"home budget application".transaction_type THEN
        UPDATE "home budget application".wallets
        SET balance = balance - v_calc_value
        WHERE wallet_id = NEW.wallet_id;
    ELSIF v_transaction.transaction_type = 'deposit'::"home budget application".transaction_type THEN
        UPDATE "home budget application".wallets
        SET balance = balance + v_calc_value
        WHERE wallet_id = NEW.wallet_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Function to add a new currency and return the whole row
CREATE OR REPLACE FUNCTION "home budget application".add_currency(
    p_currency_name VARCHAR,
    p_currency_short CHAR(3),
    p_dollar_rate NUMERIC
) RETURNS "home budget application".currency AS $$
DECLARE
    v_currency "home budget application".currency%ROWTYPE;
BEGIN
    INSERT INTO "home budget application".currency (
        currency_name, currency_short, dollar_rate
    ) VALUES (
        p_currency_name, p_currency_short, p_dollar_rate
    ) RETURNING * INTO v_currency;
    
    RETURN v_currency;
END;
$$ LANGUAGE plpgsql;

-- Function to add a new country and return the whole row
CREATE OR REPLACE FUNCTION "home budget application".add_country(
    p_country_name character varying,
    p_country_code character,
    p_currency_short character
)
RETURNS "home budget application".countries
LANGUAGE plpgsql
AS $function$
DECLARE
    v_country "home budget application".countries%ROWTYPE;
    v_currency_id INTEGER;
BEGIN
    -- Check if the currency exists
    SELECT currency_id INTO v_currency_id
    FROM "home budget application".currency
    WHERE currency_short = p_currency_short;

    -- If the currency ID is null, raise an exception and do not insert the country
    IF v_currency_id IS NULL THEN
        RAISE EXCEPTION 'Currency with short code % does not exist', p_currency_short;
        RETURN NULL;
    END IF;

    -- Insert the country if the currency exists
    INSERT INTO "home budget application".countries (
        country_name, country_code, currency_id
    ) VALUES (
        p_country_name, p_country_code, v_currency_id
    ) RETURNING * INTO v_country;
    
    RETURN v_country;
END;
$function$
;

-- Function to add a new category and return the whole row
CREATE OR REPLACE FUNCTION "home budget application".add_category(
    p_category_name character varying,
    p_category_description character varying
)
RETURNS "home budget application".categories
LANGUAGE plpgsql
AS $function$
DECLARE
    v_category "home budget application".categories%ROWTYPE;
BEGIN
    -- Insert the category
    INSERT INTO "home budget application".categories (
        category_name, category_description
    ) VALUES (
        p_category_name, p_category_description
    ) RETURNING * INTO v_category;
    
    RETURN v_category;
END;
$function$
;

-- Function to add a new subcategory and return the whole row
CREATE OR REPLACE FUNCTION "home budget application".add_subcategory(
    p_subcategory_name character varying,
    p_subcategory_description character varying,
    p_category_name character varying
)
RETURNS "home budget application".subcategories
LANGUAGE plpgsql
AS $function$
DECLARE
    v_subcategory "home budget application".subcategories%ROWTYPE;
    v_category_id INTEGER;
BEGIN
    -- Check if the category exists
    SELECT category_id INTO v_category_id
    FROM "home budget application".categories
    WHERE category_name = p_category_name;

    -- If the category ID is null, raise an exception and do not insert the subcategory
    IF v_category_id IS NULL THEN
        RAISE EXCEPTION 'Category with name % does not exist', p_category_name;
        RETURN NULL;
    END IF;

    -- Insert the subcategory if the category exists
    INSERT INTO "home budget application".subcategories (
        subcategory_name, subcategory_description, category_id
    ) VALUES (
        p_subcategory_name, p_subcategory_description, v_category_id
    ) RETURNING * INTO v_subcategory;
    
    RETURN v_subcategory;
END;
$function$
;

-- Function to create user
CREATE OR REPLACE FUNCTION "home budget application".create_user(
    p_name VARCHAR,
    p_email VARCHAR,
    p_user_password VARCHAR,
    p_country_short CHAR(3),
    p_surname VARCHAR DEFAULT NULL,
    p_nick_name VARCHAR DEFAULT NULL,
    p_phone_number VARCHAR DEFAULT NULL   
)
RETURNS "home budget application".users
LANGUAGE plpgsql
AS $function$
DECLARE
    v_user "home budget application".users%ROWTYPE;
    v_salt VARCHAR := md5(random()::text || clock_timestamp()::text);
    v_hashed_password VARCHAR := md5(p_user_password || v_salt);
    v_country_id INTEGER;
    v_sequence INTEGER := 1;
    v_new_nick_name VARCHAR;
BEGIN
    -- Check if email has correct syntax
    IF p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Invalid email format: %', p_email;
        RETURN NULL;
    END IF;

    -- Lookup country_id based on country_short
    SELECT country_id INTO v_country_id
    FROM "home budget application".countries
    WHERE country_code = p_country_short;

    -- If country_id is null, raise an exception
    IF v_country_id IS NULL THEN
        RAISE EXCEPTION 'Country with short code % does not exist', p_country_short;
        RETURN NULL;
    END IF;

    -- Generate a unique nick_name if not provided
    IF p_nick_name IS NULL THEN
        v_new_nick_name := p_name || to_char(floor(random() * 9 + 1)::integer, 'FM0000');
        -- Check if the generated nick_name already exists
        WHILE EXISTS (SELECT 1 FROM "home budget application".users WHERE nick_name = v_new_nick_name) LOOP
            v_sequence := v_sequence + 1;
            v_new_nick_name := p_name || to_char(v_sequence, 'FM0000');
        END LOOP;
        p_nick_name := v_new_nick_name;
    ELSE
        -- Check if the provided nick_name already exists
        WHILE EXISTS (SELECT 1 FROM "home budget application".users WHERE nick_name = p_nick_name) LOOP
            v_sequence := v_sequence + 1;
            p_nick_name := p_nick_name || to_char(v_sequence, 'FM0000');
        END LOOP;
    END IF;

    -- Insert the new user
    INSERT INTO "home budget application".users (
        name, surname, nick_name, email, phone_number, user_password, salt, country_id
    ) VALUES (
        p_name, p_surname, p_nick_name, p_email, p_phone_number, v_hashed_password, v_salt, v_country_id
    ) RETURNING * INTO v_user;

    RETURN v_user;
END;
$function$

-- Function to login user and return hash unique to session
CREATE OR REPLACE FUNCTION "home budget application".login_user(
    p_email VARCHAR,
    p_user_password VARCHAR
)
RETURNS TEXT 
LANGUAGE plpgsql
AS $function$
DECLARE
    v_user "home budget application".users%ROWTYPE;
    v_session "home budget application".sessions%ROWTYPE;
BEGIN
    -- Retrieve user by email
    SELECT * INTO v_user
    FROM "home budget application".users
    WHERE email = p_email;

    -- Check if user exists and verify password
    IF v_user.user_id IS NULL THEN
        RAISE EXCEPTION 'User with email % does not exist', p_email;
        RETURN NULL;
    ELSIF v_user.user_password != md5(p_user_password || v_user.salt) THEN
        RAISE EXCEPTION 'Incorrect password for email %', p_email;
        RETURN NULL;
    END IF;

    -- Create a new session
    INSERT INTO "home budget application".sessions DEFAULT VALUES
    RETURNING * INTO v_session;

    -- Link the session with the user
    INSERT INTO "home budget application".users_sessions (
        session_id, user_id
    ) VALUES (
        v_session.session_id, v_user.user_id
    );

    -- Return the session hash
    RETURN v_session.hash;
END;
$function$
;

-- Function to verify session, returns user_id if session is valid
CREATE OR REPLACE FUNCTION "home budget application".verify_session(
    p_session_hash TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $function$
DECLARE
    v_session "home budget application".sessions%ROWTYPE;
    v_user_id INTEGER;
BEGIN
    -- Retrieve session by session hash
    SELECT * INTO v_session
    FROM "home budget application".sessions
    WHERE hash = p_session_hash;

    -- Check if session exists and is still valid
    IF v_session.session_id IS NULL THEN
        RETURN NULL;
    ELSIF v_session.expiration_time < CURRENT_TIMESTAMP THEN
        RETURN NULL;
    ELSE
        -- Retrieve user_id from users_sessions
        SELECT user_id INTO v_user_id
        FROM "home budget application".users_sessions
        WHERE session_id = v_session.session_id;

        RETURN v_user_id;
    END IF;
END;
$function$
;

-- Function to create wallet
CREATE OR REPLACE FUNCTION "home budget application".create_wallet(
    p_session_hash TEXT,
    p_wallet_name VARCHAR,
    p_currency_short CHAR(3)
)
RETURNS "home budget application".wallets
LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_id INTEGER;
    v_wallet "home budget application".wallets%ROWTYPE;
    v_currency_id INTEGER;
BEGIN
    -- Verify session and get user_id
    v_user_id := "home budget application".verify_session(p_session_hash);

    -- If user_id is null, raise an exception
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired session';
        RETURN NULL;
    END IF;

    -- Lookup currency_id based on currency_short
    SELECT currency_id INTO v_currency_id
    FROM "home budget application".currency
    WHERE currency_short = p_currency_short;

    -- If currency_id is null, raise an exception
    IF v_currency_id IS NULL THEN
        RAISE EXCEPTION 'Currency with short code % does not exist', p_currency_short;
        RETURN NULL;
    END IF;

    -- Create a new wallet
    INSERT INTO "home budget application".wallets (
        wallet_name, currency_id
    ) VALUES (
        p_wallet_name, v_currency_id
    ) RETURNING * INTO v_wallet;

    -- Link the wallet with the user
    INSERT INTO "home budget application".users_wallets (
        wallet_id, user_id
    ) VALUES (
        v_wallet.wallet_id, v_user_id
    );

    -- Return the wallet
    RETURN v_wallet;
END;
$function$
;

-- Function for joining group returns users_groups row
CREATE OR REPLACE FUNCTION "home budget application".join_group(
    p_session_hash TEXT,
    p_group_id integer,
    p_user_role VARCHAR
)
RETURNS "home budget application".users_groups
LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_id INTEGER;
    v_group "home budget application".groups%ROWTYPE;
    v_users_groups "home budget application".users_groups%ROWTYPE;
BEGIN
    -- Verify session and get user_id
    v_user_id := "home budget application".verify_session(p_session_hash);

    -- If user_id is null, raise an exception
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired session';
        RETURN NULL;
    END IF;

    -- Check if group exists --
    SELECT * INTO v_group
    FROM "home budget application".groups
    WHERE group_id = p_group_id;

    IF v_group IS NULL THEN
        RAISE EXCEPTION 'Group with ID: % does not exist', p_group_id;
        RETURN NULL;
    END IF;

    INSERT INTO "home budget application".users_groups (
        user_role, group_id, user_id
    ) VALUES (
        p_user_role::"home budget application".user_role_in_group, p_group_id, v_user_id
    ) RETURNING * INTO v_users_groups;

    RETURN v_users_groups;
    
END;
$function$
;



CREATE OR REPLACE FUNCTION "home budget application".create_group(
    p_session_hash TEXT,
    p_group_name VARCHAR,
    p_group_description VARCHAR DEFAULT NULL,
    p_group_photo VARCHAR DEFAULT NULL
)
RETURNS "home budget application".groups
LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_id INTEGER;
    v_group "home budget application".groups%ROWTYPE;
BEGIN
    -- Verify session and get user_id
    v_user_id := "home budget application".verify_session(p_session_hash);

    -- If user_id is null, raise an exception
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired session';
        RETURN NULL;
    END IF;

    -- Creates new group in table groups
    INSERT INTO "home budget application".groups (
        group_name, group_description, group_photo, owner_id
    ) VALUES (
        p_group_name, p_group_description, p_group_photo, v_user_id
    ) RETURNING * INTO v_group;

    -- Adds User to users_groups table with admin permissions
    PERFORM "home budget application".join_group(p_session_hash, v_group.group_id, 'admin');

    RETURN v_group;

END;
$function$
;

-- Function that changes user role in group by admin user
CREATE OR REPLACE FUNCTION "home budget application".change_user_role_in_group(
    p_session_hash TEXT,
    p_email VARCHAR,
    p_group_id INTEGER,
    p_role VARCHAR
)
RETURNS "home budget application".users_groups
LANGUAGE plpgsql
AS $function$
DECLARE
    v_admin_user_id INTEGER;
    v_target_user_id INTEGER;
    v_users_groups "home budget application".users_groups%ROWTYPE;
BEGIN
    -- Verify session and get admin_user_id
    v_admin_user_id := "home budget application".verify_session(p_session_hash);

    -- If admin_user_id is null, raise an exception
    IF v_admin_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired session';
        RETURN NULL;
    END IF;

    -- Check if admin user is in the group and has an admin role
    IF NOT EXISTS (
        SELECT 1
        FROM "home budget application".users_groups
        WHERE user_id = v_admin_user_id
        AND group_id = p_group_id
        AND user_role = 'admin'
    ) THEN
        RAISE EXCEPTION 'User does not have admin permissions in group %', p_group_id;
        RETURN NULL;
    END IF;

    -- Get the user ID of the target user
    SELECT user_id INTO v_target_user_id
    FROM "home budget application".users
    WHERE email = p_email;

    -- If target user does not exist, raise an exception
    IF v_target_user_id IS NULL THEN
        RAISE EXCEPTION 'User with email % does not exist', p_email;
        RETURN NULL;
    END IF;

    -- Check if the target user is in the specified group
    IF NOT EXISTS (
        SELECT 1
        FROM "home budget application".users_groups
        WHERE user_id = v_target_user_id
        AND group_id = p_group_id
    ) THEN
        RAISE EXCEPTION 'User with email % is not in group %', p_email, p_group_id;
        RETURN NULL;
    END IF;

    -- Update the user role in the group
    UPDATE "home budget application".users_groups
    SET user_role = p_role::"home budget application".user_role_in_group
    WHERE user_id = v_target_user_id
    AND group_id = p_group_id
    RETURNING * INTO v_users_groups;

    -- Return the updated users_groups row
    RETURN v_users_groups;
END;
$function$
;
