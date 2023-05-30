/* CREATE TABLES */
CREATE TABLE interest_level(
    id serial PRIMARY KEY,
    level VARCHAR(50) UNIQUE
);
CREATE TABLE cities(
    id serial PRIMARY KEY,
    created_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    updated_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    name VARCHAR(50) NOT NULL UNIQUE,
    name_normalized VARCHAR(50) NOT NULL 
);
CREATE TABLE users(
    id serial PRIMARY KEY,
    city_id INTEGER REFERENCES cities(id),
    interest_id INTEGER REFERENCES interest_level(id),
    created_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    updated_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    username VARCHAR(50) UNIQUE NOT NULL,
    username_normalized VARCHAR(50) NOT NULL,
    firstname VARCHAR(50) NOT NULL,
    lastname VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    email_normalized VARCHAR(50) NOT NULL,
    user_location POINT,
    password_hash VARCHAR(256) NOT NULL,
    active_session BOOLEAN default 'f'
);
CREATE TABLE roles(
    id serial PRIMARY KEY,
    name VARCHAR(50) UNIQUE
);
CREATE TABLE instruments(
    id serial PRIMARY KEY,
    created_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    updated_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    name VARCHAR(50) UNIQUE NOT NULL,
    name_normalized VARCHAR(50) NOT NULL
);
CREATE TABLE genres(
    id serial PRIMARY KEY,
    created_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    updated_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    name VARCHAR(50) UNIQUE NOT NULL,
    name_normalized VARCHAR(50) NOT NULL
);
CREATE TABLE wanteds(
    id serial PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    city_id INTEGER REFERENCES cities(id),
    instrument_id INTEGER REFERENCES instruments(id),
    level_id INTEGER REFERENCES interest_level(id),
    description TEXT
);
CREATE TABLE user_instruments(
    user_id INTEGER REFERENCES users(id),
    instrument_id INTEGER REFERENCES instruments(id),
    is_main BOOLEAN,
    PRIMARY KEY (user_id, instrument_id)
);
CREATE TABLE user_genres(
    user_id INTEGER REFERENCES users(id),
    genre_id INTEGER REFERENCES genres(id),
    PRIMARY KEY (user_id, genre_id)
);
CREATE TABLE user_roles(
    user_id INTEGER REFERENCES users(id),
    role_id INTEGER REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id) 
);
CREATE TABLE wanted_genres(
    wanted_id INTEGER REFERENCES wanteds(id),
    genre_id INTEGER REFERENCES genres(id),
    PRIMARY KEY (wanted_id, genre_id)
);

/* UPDATE TRIGGERS */

/* UPDATED AT*/
CREATE FUNCTION updated_at_stamp() 
RETURNS trigger 
AS $updated_at_stamp$
    BEGIN
        NEW.updated_at := CURRENT_TIMESTAMP;
        RETURN NEW;
    END
$updated_at_stamp$ LANGUAGE plpgsql;

/* name_normalized changed on update*/

CREATE FUNCTION name_normalized_update() 
RETURNS trigger 
AS $update_name_normalized$
    BEGIN
        NEW.name_normalized := UPPER(NEW.name);
        RETURN NEW;
    END
$update_name_normalized$ LANGUAGE plpgsql;

CREATE TRIGGER updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON cities FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON wanteds FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON instruments FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON genres FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();

CREATE TRIGGER name_normalized_update BEFORE UPDATE ON cities FOR EACH ROW WHEN (NEW.name IS DISTINCT FROM OLD.name) EXECUTE PROCEDURE name_normalized_update();
CREATE TRIGGER name_normalized_insert BEFORE INSERT ON cities FOR EACH ROW EXECUTE PROCEDURE name_normalized_update();
CREATE TRIGGER name_normalized_update BEFORE UPDATE ON instruments FOR EACH ROW WHEN (NEW.name IS DISTINCT FROM OLD.name) EXECUTE PROCEDURE name_normalized_update();
CREATE TRIGGER name_normalized_insert BEFORE INSERT ON instruments FOR EACH ROW EXECUTE PROCEDURE name_normalized_update();
CREATE TRIGGER name_normalized_update BEFORE UPDATE ON genres FOR EACH ROW WHEN (NEW.name IS DISTINCT FROM OLD.name) EXECUTE PROCEDURE name_normalized_update();
CREATE TRIGGER name_normalized_insert BEFORE INSERT ON genres FOR EACH ROW EXECUTE PROCEDURE name_normalized_update();


/* INSERT BASIC VAUES */

INSERT INTO interest_level(level) VALUES('Hobby'), ('Amateur'), ('SemiPro'), ('Professional');
INSERT INTO roles(name) VALUES ('Standard'), ('Moderator'), ('Admin');

/* STORED PROCEDURES */

/* These are mainly for all the tables with a name field -- can be used also for other tables */
/* GET */
CREATE FUNCTION get_by_id 
(
    tbl regclass,
    id INTEGER,
    result OUT refcursor
)
AS $$
BEGIN
    OPEN result FOR
    EXECUTE format
    (
        '
        SELECT * FROM %s 
        WHERE id = %s
        ', tbl, id
    );
END;
$$ LANGUAGE plpgsql;

/* Accepts name as filter */
CREATE FUNCTION get_all
(
    tbl regclass,
    page INTEGER,
    page_size INTEGER,
    name TEXT default null,
    result OUT refcursor
)
AS $$
DECLARE 
offset_amount INTEGER default page_size * (page - 1);
BEGIN
    OPEN result FOR
    EXECUTE 
    format
    (
        '
        SELECT * FROM %1$s
        WHERE (1 = (CASE WHEN %4$L IS NULL THEN 1 ELSE 0 END) or position(UPPER(%4$L) in name_normalized) > 0)
        ORDER BY name
        LIMIT %2$s
        OFFSET %3$s;
        ', $1, $3, offset_amount, $4
    );
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION insert_entity_with_name
(
    tbl regclass,
    name VARCHAR(50)
)
RETURNS BOOLEAN
AS $$
BEGIN
    EXECUTE
    format
    (
        '
        INSERT INTO %1$s(name)
        VALUES(%2$L);
        ', tbl, name
    );
    RETURN 't';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_entity_with_name
(
    tbl regclass,
    name VARCHAR(50),
    id INTEGER
)
RETURNS BOOLEAN
AS $$
BEGIN
    EXECUTE
    format
    (
        '
        UPDATE %1$s
        SET name = %2$L
        WHERE id = %3$s;
        ', tbl, name, id
    );
    return 't';
end;
$$ LANGUAGE plpgsql;

CREATE FUNCTION delete_entity
(
    tbl regclass,
    id INTEGER
)
RETURNS BOOLEAN
AS $$
DECLARE 
BEGIN
    EXECUTE
    format 
    (
        '
        DELETE FROM %1$s
        WHERE id = %2$s;
        ', tbl, id
    );
    RETURN 't';
END;
$$ LANGUAGE plpgsql;

/* User operations*/
CREATE FUNCTION create_user
(
    username VARCHAR(50),
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    email VARCHAR(50),
    city_id INTEGER,
    interest_id INTEGER,
    password_hash VARCHAR(256)
)
RETURNS BOOLEAN
AS $$
DECLARE
username_normalized VARCHAR(50) DEFAULT UPPER(username);
email_normalized VARCHAR(50) DEFAULT UPPER(email);
BEGIN
    EXECUTE 
    format 
    (
        '
        INSERT INTO users(username, username_normalized, firstname, lastname, email, email_normalized, city_id, interest_id, password_hash)
        VALUES(%L, %L, %L, %L, %L, %L, %L, %L, %L);
        ', username, username_normalized, firstname, lastname, email, email_normalized, city_id, interest_id, password_hash
    );
    RETURN 't';
END;
$$ LANGUAGE plpgsql;

/* returns the state of active session after toggle */
CREATE FUNCTION toggle_active_session
(
    user_id INTEGER,
    session_after_toggle OUT BOOLEAN
)
RETURNS BOOLEAN
AS $$
BEGIN
    EXECUTE 
    format
    (
        '
        UPDATE users
        SET active_session = NOT active_session
        WHERE id = %s;
        ', user_id
    );
    SELECT active_session 
    FROM users 
    WHERE id = $1 INTO session_after_toggle;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION add_instrument_to_user
(   
    user_id INTEGER,
    instrument_id INTEGER,
    is_main BOOLEAN
)
RETURNS BOOLEAN
AS $$
BEGIN
    EXECUTE
    format
    (
        '
        INSERT INTO user_instruments(user_id, instrument_id, is_main)
        VALUES(%L, %L, %L);
        ', user_id, instrument_id, is_main
    );
    RETURN 't';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION add_role_to_user
(
    user_id INTEGER,
    role_id INTEGER,
)
RETURNS BOOLEAN
AS $$
BEGIN
    EXECUTE
    format
    (
        '
        INSERT INTO user_roles(user_id, role_id)
        VALUES(%L, %L);
        ', user_id, role_id
    );
    RETURN 't';
END;
$$ LANGUAGE plpgsql;






