CREATE FUNCTION updated_at_stamp() RETURNS trigger as $updated_at_stamp$
    BEGIN
        NEW.updated_at := CURRENT_TIMESTAMP;
        RETURN NEW;
    END
$updated_at_stamp$ LANGUAGE plpgsql;

CREATE TABLE users(
    id serial PRIMARY KEY,
    city_id INTEGER REFERENCES cities(id),
    interest_id INTEGER REFERENCES interest_level(id),
    created_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    updated_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    username VARCHAR(50) UNIQUE NOT NULL,
    firstname VARCHAR(50) NOT NULL,
    lastname VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL,
    user_location POINT,
    password_hash VARCHAR(256) NOT NULL,
    active_session BOOLEAN default 'f'
);
CREATE TABLE interest_level(
    id serial PRIMARY KEY,
    level VARCHAR(50) UNIQUE
);
CREATE TABLE cities(
    id serial PRIMARY KEY,
    created_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    updated_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    name VARCHAR(50) NOT NULL UNIQUE
);
CREATE TABLE instruments(
    id serial PRIMARY KEY,
    created_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    updated_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    name VARCHAR(50) NOT NULL UNIQUE
);
CREATE TABLE genres(
    id serial PRIMARY KEY,
    created_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    updated_at TIMESTAMP with time zone default CURRENT_TIMESTAMP,
    name VARCHAR(50) NOT NULL UNIQUE
);
CREATE TABLE user_instruments(
    user_id INTEGER REFERENCES users(id),
    instrument_id INTEGER REFERENCES instruments(id),
    PRIMARY KEY (user_id, instrument_id)
);
CREATE TABLE user_genres(
    user_id INTEGER REFERENCES users(id),
    genre_id INTEGER REFERENCES genre(id),
    PRIMARY KEY (user_id, genre_id)
);

CREATE TRIGGER updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON cities FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON instruments FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();
CREATE TRIGGER updated_at BEFORE UPDATE ON genres FOR EACH ROW EXECUTE PROCEDURE updated_at_stamp();

INSERT INTO interest_level(level) VALUES('Hobby'), ('Amateur'), ('SemiPro'), ('Professional');
