
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
