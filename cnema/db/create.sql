-------- MOVIE INFO --------
---- Languages ----
CREATE TABLE languages (
    language_id serial NOT NULL,
    language_name character varying(40) NOT NULL,
    CONSTRAINT pk_languages
        PRIMARY KEY(language_id)
);
------------

---- Movies ----
CREATE TABLE movies (
    movie_id serial NOT NULL,
    title character varying(200) NOT NULL,
    duration interval NOT NULL,
    age_rating integer NOT NULL,
    international_release date,
    original_language integer,
    CONSTRAINT pk_movies
        PRIMARY KEY(movie_id),
    CONSTRAINT age_rating_for_kids_only
        CHECK(age_rating <= 19)
);

-- connect movies and languages --
ALTER TABLE movies
    ADD CONSTRAINT fk_movies_languages
        FOREIGN KEY(original_language)
            REFERENCES languages(language_id);
------
------------

---- Genres ----
CREATE TABLE genres (
    genre_id serial NOT NULL,
    genre_name character varying(50) NOT NULL,
    short_name character varying(10),
    CONSTRAINT pk_genres
        PRIMARY KEY(genre_id),
    CONSTRAINT unq_genres
        UNIQUE(genre_name)
);

-- connect movies and genres --
CREATE TABLE movies_genres (
    movie_id integer NOT NULL,
    genre_id integer NOT NULL,
    CONSTRAINT pk_movies_genres
        UNIQUE(movie_id, genre_id)
);

ALTER TABLE movies_genres
    ADD CONSTRAINT fk_movies_genres_genres
        FOREIGN KEY(genre_id)
            REFERENCES genres(genre_id);

ALTER TABLE movies_genres
    ADD CONSTRAINT fk_movies_genres_movies
        FOREIGN KEY(movie_id)
            REFERENCES movies(movie_id);
------
------------

---- Producers (companies) ----
CREATE TABLE producers (
    producer_id serial NOT NULL,
    company_name character varying(100) NOT NULL,
    CONSTRAINT pk_producers
        PRIMARY KEY(producer_id)
);

-- connect movies and producers --
CREATE TABLE movies_producers (
    movie_id integer NOT NULL,
    producer_id integer NOT NULL,
    CONSTRAINT pk_movies_producers
        UNIQUE(movie_id, producer_id)
);

ALTER TABLE movies_producers
    ADD CONSTRAINT fk_movies_producers_movies
        FOREIGN KEY(movie_id)
            REFERENCES movies(movie_id);

ALTER TABLE movies_producers
    ADD CONSTRAINT fk_movies_producers_producers
        FOREIGN KEY(producer_id)
            REFERENCES producers(producer_id);
------
------------

---- People (actors, directors, etc.) ----
CREATE TABLE people (
    person_id serial NOT NULL,
    first_name character varying(50),
    last_name character varying(100) NOT NULL,
    pseudonym character varying(50),
    CONSTRAINT pk_directors
        PRIMARY KEY(person_id),
    CONSTRAINT unq_people
        UNIQUE(first_name, last_name, pseudonym)
);

-- connect movies and actors --
CREATE TABLE movies_actors (
    movie_id integer NOT NULL,
    actor_id integer NOT NULL,
    portraying character varying(80) NOT NULL,
    CONSTRAINT unq_movies_actors
        UNIQUE(movie_id, actor_id, portraying)
);

ALTER TABLE movies_actors
    ADD CONSTRAINT fk_movies_actors_movies
        FOREIGN KEY(movie_id)
            REFERENCES movies(movie_id);

ALTER TABLE movies_actors
    ADD CONSTRAINT fk_movies_actors_people
        FOREIGN KEY(actor_id)
            REFERENCES people(person_id);
------

-- connect movies and directors --
CREATE TABLE movies_directors (
    movie_id integer NOT NULL,
    director_id integer NOT NULL,
    CONSTRAINT pk_movies_directors
        UNIQUE(movie_id, director_id)
);

ALTER TABLE movies_directors
    ADD CONSTRAINT fk_movies_directors_movies
        FOREIGN KEY(movie_id)
            REFERENCES movies(movie_id);

ALTER TABLE movies_directors
    ADD CONSTRAINT fk_movies_directors_directors
        FOREIGN KEY(director_id)
            REFERENCES people(person_id);
------
------------
------------------------

-------- SCREENING INFO --------
---- Rooms ----
CREATE TABLE rooms (
    room_id serial NOT NULL,
    room_name character varying(100),
    CONSTRAINT unq_rooms_room_id
        UNIQUE(room_id),
    CONSTRAINT pk_rooms
        PRIMARY KEY(room_id)
);
------------

---- Seats ----
CREATE TABLE seats (
    seat_id serial NOT NULL,
    room integer NOT NULL,
    row_no integer NOT NULL,
    seat_no integer NOT NULL,
    CONSTRAINT pk_seats
        PRIMARY KEY(seat_id)
);

-- ensure unique seat --
ALTER TABLE seats
    ADD CONSTRAINT unq_seats
        UNIQUE(room, row_no, seat_no);

-- connect seats and rooms --
ALTER TABLE seats
    ADD CONSTRAINT fk_seats_rooms
        FOREIGN KEY(room)
            REFERENCES rooms(room_id);
------
------------

---- Regionalizations ----
CREATE TABLE regionalizations (
    regionalization_id serial NOT NULL,
    audio integer,
    lector integer,
    subtitles integer,
    CONSTRAINT unq_regionalizations_regionalization_id
        UNIQUE(regionalization_id),
    CONSTRAINT pk_regionalizations
        PRIMARY KEY(regionalization_id)
);

-- connect regionalizations and languages --
ALTER TABLE regionalizations
    ADD CONSTRAINT fk_regionalizations_languages_audio
        FOREIGN KEY(audio)
            REFERENCES languages(language_id);

ALTER TABLE regionalizations
    ADD CONSTRAINT fk_regionalizations_languages_lector
        FOREIGN KEY(lector)
            REFERENCES languages(language_id);

ALTER TABLE regionalizations
    ADD CONSTRAINT fk_regionalizations_languages_subtitles
        FOREIGN KEY(subtitles)
            REFERENCES languages(language_id);
------
------------

---- Abstract_screenings ----
CREATE TABLE abstract_screenings(
    abstract_screening_id serial NOT NULL,
    screening_hour time NOT NULL,
    room integer NOT NULL,
    base_ticket_price numeric NOT NULL,
    CONSTRAINT pk_abstract_screenings
        PRIMARY KEY(abstract_screening_id)
);

-- connect abstract_screenings and rooms --
ALTER TABLE abstract_screenings
    ADD CONSTRAINT fk_abstract_screenings_rooms
        FOREIGN KEY(room)
            REFERENCES rooms(room_id);
------
------------

---- Screenings ----
CREATE TABLE screenings (
    screening_id serial NOT NULL,
    screening_date date NOT NULL,
    abstract_screening integer NOT NULL,
    CONSTRAINT pk_screenings
        PRIMARY KEY(screening_id)
);

-- connect screenings and abstract_screenings --
ALTER TABLE screenings
    ADD CONSTRAINT fk_screenings_abstract_screenings
        FOREIGN KEY(abstract_screening)
            REFERENCES abstract_screenings(abstract_screening_id);
------
------------

---- Movie_realizations ----
CREATE TABLE movie_realizations(
    movie_realization_id serial NOT NULL,
    movie integer NOT NULL,
    regionalization integer NOT NULL,
    CONSTRAINT pk_movie_realization_id
        PRIMARY KEY(movie_realization_id)
);

-- connect movie_realizations and movies --
ALTER TABLE movie_realizations
    ADD CONSTRAINT fk_movie_realizations_movies
        FOREIGN KEY(movie)
            REFERENCES movies(movie_id);
------

-- connnect movie_realizations and regionalizations --
ALTER TABLE movie_realizations
    ADD CONSTRAINT fk_movie_realizations_regionalizations
        FOREIGN KEY(regionalization)
            REFERENCES regionalizations(regionalization_id);
------
------------

---- Movies_screenings ----
CREATE TABLE movies_screenings(
    abstract_screening integer NOT NULL,
    movie_realization integer NOT NULL
);

-- connect movies_screenings and movie_realizations --
ALTER TABLE movies_screenings
    ADD CONSTRAINT fk_movies_screenings_movie_realizations
        FOREIGN KEY(movie_realization)
            REFERENCES movie_realizations(movie_realization_id);
------

-- connect movies_screenings and abstract_screenings --
ALTER TABLE movies_screenings
    ADD CONSTRAINT fk_movies_screenings_abstract_screenings
        FOREIGN KEY(abstract_screening)
            REFERENCES abstract_screenings(abstract_screening_id);
------
------------

-------- RESERVATION INFO --------
---- Customers ----
CREATE TABLE customers (
    customer_id serial NOT NULL,
    username character varying(30) NOT NULL,
    email character varying(100) NOT NULL,
    CONSTRAINT pk_users
        PRIMARY KEY(customer_id)
);
------------

---- Ticket types ----
CREATE TABLE ticket_types (
    ticket_type_id serial NOT NULL,
    type_name character varying(40),
    discount numeric,
    CONSTRAINT pk_ticket_types
        PRIMARY KEY(ticket_type_id)
);
------------

---- Reservations ----
CREATE TABLE reservations (
    reservation_id serial NOT NULL,
    customer integer NOT NULL,
    reservation_date timestamp DEFAULT now() NOT NULL,
    CONSTRAINT pk_reservations
        PRIMARY KEY(reservation_id)
);

-- connect reservations and customers --
ALTER TABLE reservations
    ADD CONSTRAINT fk_reservations_customers
        FOREIGN KEY(customer)
            REFERENCES customers(customer_id);
------
------------

---- Tickets ----
CREATE TABLE tickets (
    ticket_id serial NOT NULL,
    screening integer NOT NULL,
    seat integer NOT NULL,
    ticket_type integer NOT NULL,
    reservation integer NOT NULL,
    cancellation_date timestamp,
    CONSTRAINT pk_tickets
        PRIMARY KEY(ticket_id)
);

-- connect tickets and screenings --
ALTER TABLE tickets
    ADD CONSTRAINT fk_tickets_screenings
        FOREIGN KEY(screening)
            REFERENCES screenings(screening_id);
------

-- connect tickets and seats --
ALTER TABLE tickets
    ADD CONSTRAINT fk_tickets_seats
        FOREIGN KEY(seat)
            REFERENCES seats(seat_id);
------

-- connect tickets and ticket types --
ALTER TABLE tickets
    ADD CONSTRAINT fk_tickets_ticket_types
        FOREIGN KEY(ticket_type)
            REFERENCES ticket_types(ticket_type_id);
------

-- connect tickets and reservations --
ALTER TABLE tickets
    ADD CONSTRAINT fk_tickets_reservations
        FOREIGN KEY(reservation)
            REFERENCES reservations(reservation_id);
------
------------
------------------------
