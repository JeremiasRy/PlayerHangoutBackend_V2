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

CREATE FUNCTION updated_at_stamp() RETURNS trigger as $updated_at_stamp$
    BEGIN
        NEW.updated_at := CURRENT_TIMESTAMP;
        RETURN NEW;
    END
$updated_at_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON cities FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON instruments FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON genres FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON wanteds FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();

/* INSERT BASIC VAUES */

INSERT INTO interest_level(level) VALUES('Hobby'), ('Amateur'), ('SemiPro'), ('Professional');
INSERT INTO roles(name) VALUES ('Standard'), ('Moderator'), ('Admin');

/* STORED PROCEDURES */

/* GET */

CREATE FUNCTION get_all_cities
(
    page INTEGER,
    page_size INTEGER,
    name TEXT default null
)
RETURNS refcursor
AS $$
DECLARE 
ref refcursor;
BEGIN
    OPEN ref FOR
    SELECT * FROM cities 
    WHERE (1 = (CASE WHEN $3 IS NULL then 1 ELSE 0 END) OR position(UPPER($3) in name_normalized) > 0)
    ORDER BY name
    LIMIT $2
    OFFSET $2 * ($1 - 1);
    RETURN ref;
END;
$$ LANGUAGE plpgsql;


