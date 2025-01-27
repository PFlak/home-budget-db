
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

