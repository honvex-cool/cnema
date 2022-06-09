-------- MOVIE INFO --------
---- Languages ----
CREATE TABLE languages (
    language_id serial NOT NULL,
    language_name character varying(40) UNIQUE NOT NULL,
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
        CHECK(age_rating BETWEEN 0 AND 19)
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

CREATE OR REPLACE VIEW genres_with_statistics
AS
SELECT
    genre_id,
    genre_name,
    short_name,
    count(movie_id) AS occurence_count
FROM
    genres LEFT JOIN movies_genres USING(genre_id)
GROUP BY genre_id;
------------

---- Producers (companies) ----
CREATE TABLE producers (
    producer_id serial NOT NULL,
    company_name character varying(100) UNIQUE NOT NULL,
    CONSTRAINT pk_producers
        PRIMARY KEY(producer_id)
);


CREATE TABLE movies_producers (
    movie_id integer NOT NULL,
    producer_id integer NOT NULL,
    CONSTRAINT pk_movies_producers
        UNIQUE(movie_id, producer_id)
);
-- connect movies and producers --

ALTER TABLE movies_producers
    ADD CONSTRAINT fk_movies_producers_movies
        FOREIGN KEY(movie_id)
            REFERENCES movies(movie_id);

ALTER TABLE movies_producers
    ADD CONSTRAINT fk_movies_producers_producers
        FOREIGN KEY(producer_id)
            REFERENCES producers(producer_id);
------

CREATE OR REPLACE VIEW producers_with_statistics
AS
SELECT
    producer_id,
    company_name,
    count(movie_id) AS occurence_count
FROM
    producers LEFT JOIN movies_producers USING(producer_id)
GROUP BY producer_id;
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
    room_name character varying(100) UNIQUE NOT NULL,
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
    CONSTRAINT pk_regionalizations
        PRIMARY KEY(regionalization_id)
);

ALTER TABLE regionalizations
    ADD CONSTRAINT unq_regionalizations
        UNIQUE(audio, lector, subtitles);

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
    base_ticket_price numeric(4,2) NOT NULL CHECK(base_ticket_price>=0),
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

ALTER TABLE screenings
    ADD CONSTRAINT unq_screenings
        UNIQUE(screening_date,abstract_screening);

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

ALTER TABLE movie_realizations
    ADD CONSTRAINT unq_movie_realizations
        UNIQUE(movie, regionalization);

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

ALTER TABLE movies_screenings
    ADD CONSTRAINT unq_movies_screenings
        UNIQUE(abstract_screening,movie_realization);

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
    email character varying(100) UNIQUE NOT NULL CHECK(email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
    CONSTRAINT pk_users 
        PRIMARY KEY(customer_id)
);
------------

---- Ticket types ----
CREATE TABLE ticket_types (
    ticket_type_id serial NOT NULL,
    type_name character varying(40) UNIQUE NOT NULL,
    discount numeric(4,2),
    CONSTRAINT pk_ticket_types
        PRIMARY KEY(ticket_type_id),
    CONSTRAINT sensible_discount
        CHECK(discount BETWEEN 0 AND 1)
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

-- Oskwariusz
CREATE TABLE journals (
    journal_id serial NOT NULL,
    full_name character varying(50) NOT NULL,
    short_name character varying(10),
    CONSTRAINT pk_journals
        PRIMARY KEY(journal_id),
    CONSTRAINT unq_journal_full_names
        UNIQUE(full_name)
);

CREATE TABLE reviews (
    review_id serial NOT NULL,
    journal_id integer NOT NULL,
    title character varying(100) NOT NULL,
    contents text NOT NULL,
    summary character varying(50),
    publication_date date NOT NULL,
    stars integer,
    CONSTRAINT pk_reviews
        PRIMARY KEY(review_id),
    CONSTRAINT zero_to_ten_scale
        CHECK(stars BETWEEN 0 AND 10),
    CONSTRAINT unq_reviews
        UNIQUE(journal_id, title, publication_date)
);

ALTER TABLE reviews
    ADD CONSTRAINT fk_reviews_journals
        FOREIGN KEY(journal_id)
            REFERENCES journals(journal_id);

CREATE TABLE reviews_authors (
    review_id integer NOT NULL,
    author_id integer NOT NULL,
    CONSTRAINT unq_reviews_authors
        UNIQUE(review_id, author_id)
);

ALTER TABLE reviews_authors
    ADD CONSTRAINT fk_reviews_authors_reviews
        FOREIGN KEY(review_id)
            REFERENCES reviews(review_id),
    ADD CONSTRAINT fk_reviews_authors_authors
        FOREIGN KEY(author_id)
            REFERENCES people(person_id);

CREATE TABLE movies_reviews (
    movie_id integer NOT NULL,
    review_id integer NOT NULL,
    CONSTRAINT unq_movies_reviews
        UNIQUE(movie_id, review_id)
);

CREATE OR REPLACE FUNCTION short_format_review(review reviews)
RETURNS text
AS
$$
BEGIN
    RETURN
        review.summary
        ||
        ' ('
        ||
        (SELECT short_name FROM journals WHERE journal_id = review.journal_id)
        ||
        ')';
END;
$$
LANGUAGE plpgsql;

ALTER TABLE movies_reviews
    ADD CONSTRAINT fk_movies_reviews_movies
        FOREIGN KEY(movie_id)
            REFERENCES movies(movie_id),
    ADD CONSTRAINT fk_movies_reviews_reviews
        FOREIGN KEY(review_id)
            REFERENCES reviews(review_id);

CREATE TABLE movies_screenwriters (
    movie_id integer NOT NULL,
    screenwriter_id integer NOT NULL,
    CONSTRAINT unq_movies_screenwriters
        UNIQUE(movie_id, screenwriter_id)
);

ALTER TABLE movies_screenwriters
    ADD CONSTRAINT fk_movies_screenwriters_movies
        FOREIGN KEY(movie_id)
            REFERENCES movies(movie_id),
    ADD CONSTRAINT fk_movies_screenwriters_screenwriters
        FOREIGN KEY(screenwriter_id)
            REFERENCES people(person_id);

CREATE TABLE movies_composers (
    movie_id integer NOT NULL,
    composer_id integer NOT NULL,
    CONSTRAINT unq_movies_composers
        UNIQUE(movie_id, composer_id)
);

ALTER TABLE movies_composers
    ADD CONSTRAINT fk_movies_composers_movies
        FOREIGN KEY(movie_id)
            REFERENCES movies(movie_id),
    ADD CONSTRAINT fk_movies_composers_composers
        FOREIGN KEY(composer_id)
            REFERENCES people(person_id);

CREATE OR REPLACE FUNCTION format_person(person people)
RETURNS text
AS
$$
BEGIN
    RETURN
        coalesce(person.first_name || ' ', '')
        ||
        coalesce('"' || person.pseudonym || '" ', '')
        ||
        person.last_name;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION format_actor(actor people, portraying text)
RETURNS text
AS
$$
BEGIN
    RETURN format_person(actor) || ' as ' || portraying;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION format_movie_genres(movie integer)
RETURNS text
AS
$$
BEGIN
    RETURN (
        SELECT string_agg(coalesce(genres.short_name, genres.genre_name), ', ')
        FROM
            movies_genres JOIN genres ON genres.genre_id = movies_genres.genre_id
        WHERE movies_genres.movie_id = movie
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION format_movie_directors(movie integer)
RETURNS text
AS
$$
BEGIN
    RETURN (
        SELECT string_agg(format_person(directors), ', ')
        FROM
            movies_directors JOIN people directors ON directors.person_id = movies_directors.director_id
        WHERE movies_directors.movie_id = movie
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION format_movie_screenwriters(movie integer)
RETURNS text
AS
$$
BEGIN
    RETURN (
        SELECT string_agg(format_person(screenwriters), ', ')
        FROM
            movies_screenwriters JOIN people screenwriters ON screenwriters.person_id = movies_screenwriters.screenwriter_id
        WHERE movies_screenwriters.movie_id = movie
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION format_movie_actors(movie integer)
RETURNS text
AS
$$
BEGIN
    RETURN (
        SELECT string_agg(format_actor(actors, portraying), ', ')
        FROM
            movies_actors JOIN people actors ON actors.person_id = movies_actors.actor_id
        WHERE movies_actors.movie_id = movie
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION format_movie_composers(movie integer)
RETURNS text
AS
$$
BEGIN
    RETURN (
        SELECT string_agg(format_person(composers), ', ')
        FROM
            movies_composers JOIN people composers ON composers.person_id = movies_composers.composer_id
        WHERE movies_composers.movie_id = movie
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION format_movie_producers(movie integer)
RETURNS text
AS
$$
BEGIN
    RETURN (
        SELECT string_agg(company_name, ', ')
        FROM
            movies_producers JOIN producers ON producers.producer_id = movies_producers.producer_id
        WHERE movies_producers.movie_id = movie
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION short_format_movie_reviews(movie integer)
RETURNS text
AS
$$
BEGIN
    RETURN (
        SELECT string_agg(short_format_review(reviews), '; ')
        FROM
            movies_reviews JOIN reviews ON reviews.review_id = movies_reviews.review_id
        WHERE movies_reviews.movie_id = movie
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE VIEW movie_info
AS
SELECT
    movie_id,
    title,
    format_movie_genres(movie_id) AS genres,
    duration,
    age_rating,
    international_release AS release_date,
    language_name AS original_language,
    format_movie_directors(movie_id) AS directed_by,
    format_movie_screenwriters(movie_id) AS screenplay_by,
    format_movie_actors(movie_id) AS starring,
    format_movie_composers(movie_id) AS music_by,
    format_movie_producers(movie_id) AS produced_by,
    short_format_movie_reviews(movie_id) AS reviewed_as
FROM
    movies LEFT JOIN languages ON languages.language_id = movies.original_language;

CREATE OR REPLACE FUNCTION activity_count_as_parameterized(person integer, table_suffix text)
RETURNS integer
AS
$$
DECLARE
    result integer;
BEGIN
    EXECUTE
    'SELECT count(*) FROM movies_'
    ||
    table_suffix
    ||
    's WHERE '
    ||
    table_suffix
    ||
    '_id = '
    ||
    person :: text
    ||
    ';'
    INTO result;
    RETURN result;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION activity_count_as_actor(person integer)
RETURNS integer
AS
$$
BEGIN
    RETURN activity_count_as_parameterized(person, 'actor');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION activity_count_as_director(person integer)
RETURNS integer
AS
$$
BEGIN
    RETURN activity_count_as_parameterized(person, 'director');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION activity_count_as_screenwriter(person integer)
RETURNS integer
AS
$$
BEGIN
    RETURN activity_count_as_parameterized(person, 'screenwriter');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION activity_count_as_composer(person integer)
RETURNS integer
AS
$$
BEGIN
    RETURN activity_count_as_parameterized(person, 'composer');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION activity_count_as_reviewer(person integer)
RETURNS integer
AS
$$
BEGIN
    RETURN (SELECT count(*) FROM reviews_authors WHERE author_id = person);
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION activity_count(person integer)
RETURNS integer
AS
$$
BEGIN
    RETURN
        activity_count_as_actor(person)
        +
        activity_count_as_director(person)
        +
        activity_count_as_screenwriter(person)
        +
        activity_count_as_composer(person)
        +
        activity_count_as_reviewer(person);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE VIEW ticket_types_with_statistics
AS
SELECT
    ticket_types.*,
    count(ticket_id) AS occurence_count
FROM
    ticket_types LEFT JOIN tickets ON ticket_type = ticket_type_id
GROUP BY ticket_type_id;

CREATE OR REPLACE FUNCTION format_journal(journal journals)
RETURNS text
AS
$$
BEGIN
    RETURN journal.full_name || coalesce(' (' || journal.short_name || ')', '');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION format_review_movies(review integer)
RETURNS text
AS
$$
BEGIN
    RETURN (
        SELECT string_agg(title, ', ')
        FROM
            movies_reviews JOIN movies USING(movie_id)
        WHERE review_id = review
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION format_review_authors(review integer)
RETURNS text
AS
$$
BEGIN
    RETURN (
        SELECT string_agg(format_person(people), ', ')
        FROM
            reviews_authors JOIN people ON person_id = author_id
        WHERE review_id = review
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE VIEW review_info
AS
SELECT
    review_id,
    title,
    (SELECT format_journal(journals) FROM journals WHERE journals.journal_id = reviews.journal_id) AS journal,
    format_review_movies(review_id) AS of_movies,
    format_review_authors(review_id) AS authors,
    contents,
    summary,
    publication_date,
    stars,
    (SELECT count(*) FROM movies_reviews WHERE movies_reviews.review_id = reviews.review_id) AS reference_count,
    (SELECT count(*) FROM reviews_authors WHERE reviews_authors.review_id = reviews.review_id) AS author_count
FROM reviews;

CREATE OR REPLACE VIEW people_info
AS
SELECT
    people.*,
    format_person(people) AS personal_info,
    activity_count(person_id) AS activity_in_industry
FROM people
ORDER BY last_name, first_name, person_id;
------------------------

-- Jasion
-- Screenings delete check --
CREATE OR REPLACE FUNCTION abstract_screening_length(a_s_id integer) RETURNS time AS
$$
BEGIN
	RETURN COALESCE((SELECT sum(duration) 
				FROM movies_screenings ms
					JOIN movie_realizations mr ON ms.movie_realization = mr.movie_realization_id
					JOIN movies m ON mr.movie = movie_id 
				WHERE ms.abstract_screening=a_s_id)::time,(interval '0 second')::time);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ticket_count_for_screening(screening_id integer)
RETURNS integer
AS
$$
BEGIN
    RETURN (
        SELECT count(*)
        FROM tickets
        WHERE screening = screening_id
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION active_ticket_count_for_screening(screening_id integer)
RETURNS integer
AS
$$
BEGIN
    RETURN (
        SELECT count(*)
        FROM tickets
        WHERE
            screening = screening_id
            AND
            cancellation_date IS NULL
    );
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION screenings_delete_check()
RETURNS TRIGGER AS $screenings_delete_check$
BEGIN
	IF
        ticket_count_for_screening(OLD.screening_id) = 0
	THEN
		RETURN OLD;
	END IF;
    RAISE EXCEPTION 'Cannot delete a screening referenced by tickets';
END;
$screenings_delete_check$
LANGUAGE plpgsql;
CREATE TRIGGER screenings_delete_check BEFORE DELETE ON screenings
FOR EACH ROW EXECUTE PROCEDURE screenings_delete_check();
------

-- Screenings insert check --
CREATE OR REPLACE FUNCTION screenings_insert_check()
RETURNS TRIGGER AS $screenings_insert_check$
DECLARE
new_begin_time timestamp := NEW.screening_date::timestamp + (SELECT screening_hour 
															FROM abstract_screenings 
															WHERE abstract_screening_id=NEW.abstract_screening);
new_end_time timestamp := new_begin_time + interval '15 minutes' + (SELECT abstract_screening_length(NEW.abstract_screening))::time;
temp record;
BEGIN
		IF new_begin_time <= NOW() THEN
			RAISE EXCEPTION 'Screening in the past';
		END IF;

		FOR temp IN SELECT
				s.screening_date + a_s.screening_hour AS "begin_time",
				s.screening_date + a_s.screening_hour + interval '15 minutes' + (SELECT abstract_screening_length(a_s.abstract_screening_id))::time AS "end_time"
			FROM
				screenings s JOIN abstract_screenings a_s ON s.abstract_screening = a_s.abstract_screening_id
			WHERE s.screening_date >= NOW() :: date AND a_s.room = (SELECT room FROM abstract_screenings WHERE abstract_screening_id=NEW.abstract_screening)
		LOOP
			IF (new_begin_time,new_end_time) OVERLAPS (temp."begin_time",temp."end_time") THEN
				RAISE EXCEPTION 'Screening overlaps';
			END IF;
		END LOOP;
	RETURN NEW;
END;
$screenings_insert_check$
LANGUAGE plpgsql;
CREATE TRIGGER screenings_insert_check BEFORE INSERT ON screenings
FOR EACH ROW EXECUTE PROCEDURE screenings_insert_check();
------
------------

-- Reservation value --
CREATE OR REPLACE FUNCTION reservation_value(reservation_id integer)
RETURNS numeric(4,2)
AS
$$
BEGIN
    RETURN
        COALESCE(
            (
                SELECT SUM(COALESCE(a.base_ticket_price*COALESCE(1-tt.discount,1),0))
                FROM
                    tickets t JOIN screenings s ON t.screening = s.screening_id
					JOIN abstract_screenings a ON s.abstract_screening=a.abstract_screening_id
                    JOIN ticket_types tt ON t.ticket_type = tt.ticket_type_id
                WHERE t.reservation = reservation_id AND t.cancellation_date IS NULL
            ),
            0
        );
END;
$$
LANGUAGE plpgsql;
------

-- Occupied seats --
CREATE OR REPLACE FUNCTION occupied_seats (screening_id INTEGER)
RETURNS TABLE(
	seat_id INTEGER,
	row_no INTEGER,
	seat_no INTEGER) AS
$$
BEGIN
	RETURN QUERY SELECT
	s.seat_id,
	s.row_no,
	s.seat_no
	FROM seats s WHERE s.seat_id IN (SELECT seat FROM tickets WHERE screening=screening_id AND cancellation_date IS NULL);
END;
$$
LANGUAGE plpgsql;
------

-- Regular customers --
CREATE OR REPLACE VIEW regular_customers AS
SELECT
	customer_id,
	username,
	email,
	COUNT(customer_id) AS "BoughtTickets"
FROM
	customers c JOIN reservations r ON c.customer_id=r.customer
	JOIN tickets t ON r.reservation_id=t.reservation
WHERE t.cancellation_date IS NULL
GROUP BY customer_id
ORDER BY "BoughtTickets" DESC;

CREATE OR REPLACE RULE regular_customers_no_delete AS ON DELETE TO regular_customers DO INSTEAD NOTHING;
CREATE OR REPLACE RULE regular_customers_no_insert AS ON INSERT TO regular_customers DO INSTEAD NOTHING;
CREATE OR REPLACE RULE regular_customers_no_update AS ON UPDATE TO regular_customers DO INSTEAD NOTHING;
------

-- Most popular seats --
CREATE OR REPLACE VIEW most_popular_seats AS
SELECT
	"sel".room,
	"sel".seat_id,
	"sel"."NumberOfSeatReservations"
FROM
	(SELECT
		s.room,
		s.seat_id,
		COUNT(seat_id) AS "NumberOfSeatReservations",
        ROW_NUMBER() OVER(PARTITION BY room ORDER BY COUNT(seat_id))
	FROM seats s JOIN tickets t ON s.seat_id = t.seat
	WHERE t.cancellation_date IS NULL
    GROUP BY(s.room,s.seat_id)) AS "sel"
WHERE "sel"."NumberOfSeatReservations"<6
ORDER BY "sel".room;


CREATE OR REPLACE RULE most_popular_seats_no_delete AS ON DELETE TO most_popular_seats DO INSTEAD NOTHING;
CREATE OR REPLACE RULE most_popular_seats_no_insert AS ON INSERT TO most_popular_seats DO INSTEAD NOTHING;
CREATE OR REPLACE RULE most_popular_seats_no_update AS ON UPDATE TO most_popular_seats DO INSTEAD NOTHING;
------

-- Regionalizations_language_names --
CREATE OR REPLACE VIEW regionalizations_language_names AS
SELECT
	rg.regionalization_id,
	al.language_name AS "audio",
	ll.language_name AS "lector",
	sl.language_name AS "subtitles"
FROM
	regionalizations rg
	LEFT OUTER JOIN languages al ON rg.audio = al.language_id
	LEFT OUTER JOIN languages ll ON rg.lector = ll.language_id
	LEFT OUTER JOIN languages sl ON rg.subtitles = sl.language_id;



CREATE OR REPLACE FUNCTION regionalizations_language_names_insert() 
RETURNS TRIGGER AS $regionalizations_language_names_insert$
DECLARE
audio_id integer := NULL;
lector_id integer := NULL;
subtitles_id integer := NULL;
BEGIN
    IF NEW."audio" IS NOT NULL THEN
        SELECT language_id INTO audio_id FROM languages WHERE language_name=NEW."audio";
        IF audio_id IS NULL THEN
            RAISE EXCEPTION 'Incorrect audio language';
        END IF;
    END IF;
    IF NEW."lector" IS NOT NULL THEN
        SELECT language_id INTO lector_id FROM languages WHERE language_name=NEW."lector";
        IF lector_id IS NULL THEN
            RAISE EXCEPTION 'Incorrect lector language';
        END IF;
    END IF;
    IF NEW."subtitles" IS NOT NULL THEN
        SELECT language_id INTO subtitles_id FROM languages WHERE language_name=NEW."subtitles";
        IF subtitles_id IS NULL THEN
            RAISE EXCEPTION 'Incorrect subtitles language';
        END IF;
    END IF;
	INSERT INTO regionalizations VALUES(DEFAULT,audio_id,lector_id,subtitles_id) RETURNING regionalization_id INTO NEW.regionalization_id;
    RETURN NEW;
END;
$regionalizations_language_names_insert$
LANGUAGE plpgsql;
CREATE TRIGGER regionalizations_language_names_insert INSTEAD OF INSERT ON regionalizations_language_names
FOR EACH ROW EXECUTE PROCEDURE regionalizations_language_names_insert();

CREATE OR REPLACE RULE regionalizations_language_names_no_delete AS ON DELETE TO regionalizations_language_names DO INSTEAD NOTHING;
CREATE OR REPLACE RULE regionalizations_language_names_no_update AS ON UPDATE TO regionalizations_language_names DO INSTEAD NOTHING;
------

-- Full screenings --
CREATE OR REPLACE VIEW full_screenings AS
SELECT 
    s.screening_id,
    s.screening_date,
    a_s.screening_hour,
    a_s.room,
    a_s.base_ticket_price,
    mr.movie,
    mr.regionalization,
    a_s.abstract_screening_id,
    mr.movie_realization_id
 
FROM
	screenings s 
	JOIN abstract_screenings a_s ON s.abstract_screening = a_s.abstract_screening_id
	JOIN movies_screenings ms ON a_s.abstract_screening_id = ms.abstract_screening
	JOIN movie_realizations mr ON ms.movie_realization = mr.movie_realization_id
WHERE s.screening_date >= NOW()::date
ORDER BY s.screening_date,a_s.screening_hour,s.screening_id;

CREATE OR REPLACE RULE full_screenings_no_delete AS ON DELETE TO full_screenings DO INSTEAD NOTHING;
CREATE OR REPLACE RULE full_screenings_no_insert AS ON INSERT TO full_screenings DO INSTEAD NOTHING;
CREATE OR REPLACE RULE full_screenings_no_update AS ON UPDATE TO full_screenings DO INSTEAD NOTHING;

-- Schedule --
CREATE OR REPLACE VIEW schedule AS
SELECT
    fs.screening_id,
    fs.screening_date,
    fs.screening_hour,
	m.title,
    m.duration,
	rln."audio",
	rln."lector",
	rln."subtitles",
	r.room_name,
    fs.base_ticket_price,
    ticket_count_for_screening(fs.screening_id) AS ticket_count,
    active_ticket_count_for_screening(fs.screening_id) AS active_ticket_count
FROM
	full_screenings fs
	JOIN rooms r ON fs.room=r.room_id
	JOIN movies m ON fs.movie=m.movie_id
	JOIN regionalizations_language_names rln ON fs.regionalization = rln.regionalization_id
WHERE fs.screening_date >= NOW() :: timestamp
ORDER BY fs.screening_date,fs.screening_hour,fs.screening_id;

CREATE OR REPLACE RULE schedule_no_delete AS ON DELETE TO schedule DO INSTEAD NOTHING;
CREATE OR REPLACE RULE schedule_no_update AS ON UPDATE TO schedule DO INSTEAD NOTHING;



CREATE OR REPLACE FUNCTION add_to_schedule(screening_date_ date,
                                            screening_hour_ time,
                                            movie_id_ integer,
                                            audio_language varchar,
                                            lector_language varchar,
                                            subtitles_language varchar,
                                            room_id_ integer,
                                            base_ticket_price_ numeric(4,2))
RETURNS integer AS
$$
DECLARE
rg_id integer;
mr_id integer;
as_id integer;
result_id integer;
BEGIN
	IF movie_id_ IS NULL OR room_id_ IS NULL THEN 
		RAISE EXCEPTION 'No room or movie found';
	END IF;

    SELECT regionalization_id INTO rg_id
					FROM regionalizations_language_names 
					WHERE COALESCE(audio,'##')=COALESCE(audio_language,'##') AND COALESCE(lector,'##')=COALESCE(lector_language,'##') AND COALESCE(subtitles,'##')=COALESCE(subtitles_language,'##');
    IF rg_id IS NULL THEN
        INSERT INTO regionalizations_language_names
            VALUES(DEFAULT,audio_language,lector_language,subtitles_language) RETURNING regionalization_id INTO rg_id;
    END IF;

	SELECT movie_realization_id INTO mr_id
				FROM movie_realizations 
				WHERE movie=movie_id_ AND regionalization=rg_id;
	IF mr_id IS NULL THEN
		INSERT INTO movie_realizations 
			VALUES (DEFAULT,movie_id_,rg_id) RETURNING movie_realization_id INTO mr_id;
	END IF;

	SELECT abstract_screening_id INTO as_id
				FROM (SELECT
							a_s.abstract_screening_id,
							COUNT(a_s.abstract_screening_id) AS "count"
						FROM
							abstract_screenings a_s
							JOIN movies_screenings ms ON a_s.abstract_screening_id = ms.abstract_screening
						WHERE a_s.screening_hour = screening_hour_
							AND a_s.room = room_id_
							AND a_s.base_ticket_price = base_ticket_price_
						GROUP BY a_s.abstract_screening_id) AS "s"
				WHERE "s"."count"=1 AND (SELECT movie_realization 
										FROM movies_screenings 
										WHERE abstract_screening=abstract_screening_id)=mr_id;
	IF as_id IS NULL THEN
		INSERT INTO abstract_screenings
			VALUES(DEFAULT,screening_hour_,room_id_,base_ticket_price_)
			RETURNING abstract_screening_id INTO as_id;
		INSERT INTO movies_screenings VALUES(as_id,mr_id);
	END IF;

	INSERT INTO screenings VALUES(DEFAULT,screening_date_,as_id) RETURNING screening_id INTO result_id;
    RETURN result_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION schedule_insert() 
RETURNS TRIGGER AS $schedule_insert$
DECLARE
mv_id integer := (SELECT movie_id FROM movies WHERE title=NEW.title);
rm_id integer := (SELECT room_id FROM rooms WHERE room_name = NEW.room_name);
result_id integer;
BEGIN
    SELECT add_to_schedule(NEW.screening_date,NEW.screening_hour,mv_id,NEW.audio,NEW.lector,NEW.subtitles,rm_id,NEW.base_ticket_price) INTO result_id;
    NEW.screening_id = result_id;
	RETURN NEW;
END;
$schedule_insert$
LANGUAGE plpgsql;
CREATE TRIGGER schedule_insert INSTEAD OF INSERT ON schedule
FOR EACH ROW EXECUTE PROCEDURE schedule_insert();
------

-- Full schedule --
CREATE OR REPLACE VIEW full_schedule AS
SELECT
	s.screening_id,
	a_s.screening_hour,
	s.screening_date,
	m.title,
	al.language_name AS "audio",
	ll.language_name AS "lector",
	sl.language_name AS "subtitles",
	r.room_name
FROM
	screenings s JOIN abstract_screenings a_s ON s.abstract_screening = a_s.abstract_screening_id
	JOIN movies_screenings ms ON a_s.abstract_screening_id = ms.abstract_screening
	JOIN movie_realizations mr ON ms.movie_realization = mr.movie_realization_id
	JOIN rooms r ON a_s.room = r.room_id
	JOIN movies m ON mr.movie = m.movie_id
	JOIN regionalizations rg ON mr.regionalization = rg.regionalization_id
	LEFT OUTER JOIN languages al ON rg.audio = al.language_id
	LEFT OUTER JOIN languages ll ON rg.lector = ll.language_id
	LEFT OUTER JOIN languages sl ON rg.subtitles = sl.language_id
WHERE s.screening_date >= NOW() :: date
ORDER BY s.screening_date,a_s.screening_hour,m.title;


CREATE OR REPLACE RULE full_schedule_no_delete AS ON DELETE TO full_schedule DO INSTEAD NOTHING;
CREATE OR REPLACE RULE full_schedule_no_insert AS ON INSERT TO full_schedule DO INSTEAD NOTHING;
CREATE OR REPLACE RULE full_schedule_no_update AS ON UPDATE TO full_schedule DO INSTEAD NOTHING;
------
------------
----------------------------

--Przemo
----------------------
CREATE OR REPLACE FUNCTION get_or_make_user_id(un text, mail text) RETURNS int AS $$
DECLARE
    x int;
BEGIN
    IF (SELECT customer_id FROM customers c WHERE c.email=mail) IS NULL THEN
        INSERT INTO customers VALUES(DEFAULT, un, mail) RETURNING customer_id INTO x;
        RETURN x;
    END IF;
    IF (SELECT customer_id FROM customers c WHERE c.email=mail AND c.username = un) IS NULL THEN
        RAISE EXCEPTION 'Email is taken';
    END IF;
    RETURN (SELECT customer_id FROM customers c WHERE c.email=mail);

END;
$$ LANGUAGE plpgsql;
----------------------

--get_id
CREATE OR REPLACE FUNCTION get_roomid(s_id int) RETURNS int AS $$
BEGIN
	RETURN (SELECT room FROM full_screenings WHERE s_id=screening_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION last_res_id(c_id int) RETURNS int AS $$
BEGIN
	RETURN (SELECT reservation_id FROM reservations WHERE customer=c_id ORDER BY reservation_date DESC LIMIT 1);
END;
$$ LANGUAGE plpgsql;
--

CREATE OR REPLACE FUNCTION get_free_seats( scr_id int ) RETURNS TABLE (
	seat_id INTEGER,
	row_no INTEGER,
	seat_no INTEGER
    ) AS $$
DECLARE
    r_id int;
BEGIN
    SELECT INTO r_id get_roomid(scr_id);
    RETURN QUERY SELECT s.seat_id, s.row_no, s.seat_no FROM seats s WHERE s.room=r_id AND s.seat_id NOT IN (SELECT os.seat_id FROM occupied_seats(scr_id) os);
END;
$$ LANGUAGE plpgsql;
-------------
--INSERT TICKET WHEN SCREENING ALREADY STARTED/ENDED
CREATE OR REPLACE FUNCTION cant_buy_ticket() RETURNS TRIGGER AS $$
BEGIN
	IF	get_start(NEW.screening) IS NULL
                OR (NEW.reservation IS NOT NULL AND NEW.reservation NOT IN (SELECT reservation_id FROM reservations))
                OR (NEW.reservation IS NULL)
                OR get_start(NEW.screening)<=NOW()
		        OR get_roomid(NEW.screening)!=(SELECT room FROM seats s WHERE NEW.seat=s.seat_id)
                OR NEW.seat IN ( SELECT os.seat_id FROM occupied_seats(NEW.screening) os )
                OR NEW.ticket_type NOT IN (SELECT ticket_type_id FROM ticket_types)
	THEN
		RAISE EXCEPTION 'cant insert ticket';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cant_buy_ticket BEFORE INSERT ON tickets
FOR EACH ROW EXECUTE PROCEDURE cant_buy_ticket();

-------------
--DELETE TRIGGER
CREATE OR REPLACE FUNCTION delete_reservation_if_empty() RETURNS TRIGGER AS $$
BEGIN
	IF (SELECT COALESCE(count(t.ticket_id), 0) FROM reservations r JOIN tickets t ON t.reservation=r.reservation_id WHERE OLD.reservation=r.reservation_id)=0
	THEN
		DELETE FROM reservations WHERE reservation_id=OLD.reservation;
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_reservation_if_empty AFTER DELETE ON tickets
FOR EACH ROW EXECUTE PROCEDURE delete_reservation_if_empty();
-------------
--BUY TICKET FUNCTION
CREATE OR REPLACE FUNCTION buy_ticket(scr_id int, s_id int, type int, res_id int, c_id int) RETURNS integer AS $$
BEGIN
	IF	get_start(scr_id) IS NULL
		OR (res_id IS NOT NULL AND res_id NOT IN (SELECT reservation_id FROM reservations))
		OR (res_id IS NULL AND (c_id IS NULL OR c_id NOT IN (SELECT customer_id FROM customers)))
		OR get_start(scr_id)<=NOW()
		OR get_roomid(scr_id)!=(SELECT room FROM seats s WHERE s_id=s.seat_id)
		OR s_id IN ( SELECT os.seat_id FROM occupied_seats(scr_id) os )
		OR type NOT IN (SELECT ticket_type_id FROM ticket_types)
	THEN
		RAISE EXCEPTION 'cant buy this ticket';
	END IF;
	IF	res_id IS NULL
	THEN
		INSERT INTO reservations VALUES(DEFAULT, c_id, NOW()) RETURNING reservation_id INTO res_id;
	END IF;
	INSERT INTO tickets VALUES(DEFAULT, scr_id, s_id, type, res_id, NULL);
	RETURN res_id;
END;
$$ LANGUAGE plpgsql;
---------------------
--ALL BOUGHT TICKETS FROM USER
CREATE OR REPLACE FUNCTION user_history(id INTEGER) RETURNS TABLE(
        "screening_id" integer,
        "ticket_id" integer,
        "title" varchar(100),
        "hour" time,
        "date" date,
        "room" varchar(100),
        "row" integer,
        "seat" integer,
        "reservation_date" timestamp,
	    "cancelled" timestamp
) AS $$
BEGIN
	RETURN QUERY SELECT
		a.screening AS "screening_id", a.ticket_id, a.title AS "title", a.screening_hour AS "hour", a.screening_date AS "date", a.room_name AS "room", a.row_no AS "row", a.seat_no AS "seat",
		a.reservation_date AS "reservation_date", a.cancellation_date AS "cancelled"
		FROM all_tickets a WHERE a.customer_id=id;
END;
$$ LANGUAGE plpgsql;
---------------------
--RESERVATION TRIGGER
CREATE OR REPLACE FUNCTION get_start(id int) RETURNS timestamp AS $$
BEGIN
	RETURN (SELECT screening_date + screening_hour FROM full_schedule WHERE id=screening_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cant_cancel_hour_before() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.cancellation_date IS NULL
	AND NEW.cancellation_date+'1 hour' < get_start(NEW.screening)
	THEN
		RETURN NEW;
	END IF;
	RAISE EXCEPTION 'It is to late to cancel the ticket';
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER cant_cancel_hour_before BEFORE UPDATE ON tickets
FOR EACH ROW EXECUTE PROCEDURE cant_cancel_hour_before();
---------------------
--CANCEL TICKET
CREATE OR REPLACE FUNCTION cancel_ticket(id int) RETURNS VOID AS $$
	UPDATE tickets
	SET cancellation_date=NOW()
	WHERE id=ticket_id;
$$ LANGUAGE SQL;
---------------------
--ALL TICKETS
CREATE OR REPLACE VIEW all_tickets AS
SELECT
	t.ticket_id,
	t.screening,
	fs.title,
	fs.screening_hour,
	fs.screening_date,
	sr.room_name,
	s.row_no,
	s.seat_no,
	r.reservation_date,
	c.customer_id,
	t.cancellation_date,
    tt.discount
FROM
	tickets t
	JOIN seats s ON t.seat=s.seat_id
	JOIN rooms sr ON sr.room_id=s.room
	JOIN reservations r ON t.reservation=r.reservation_id
	JOIN customers c ON c.customer_id=r.customer
	JOIN full_schedule fs ON fs.screening_id=t.screening
    JOIN ticket_types tt ON tt.ticket_type_id=t.ticket_type
ORDER BY screening_date DESC, screening_hour DESC;

CREATE OR REPLACE RULE all_tickets_no_delete AS ON DELETE TO all_tickets DO INSTEAD NOTHING;
CREATE OR REPLACE RULE all_tickets_no_insert AS ON INSERT TO all_tickets DO INSTEAD NOTHING;
CREATE OR REPLACE RULE all_tickets_no_update AS ON UPDATE TO all_tickets DO INSTEAD NOTHING;
---------------------

INSERT INTO languages
VALUES
(DEFAULT, 'English'),
(DEFAULT, 'Polish'),
(DEFAULT, 'German'),
(DEFAULT, 'French'),
(DEFAULT, 'Spanish'),
(DEFAULT, 'Portuguese'),
(DEFAULT, 'Japanese'),
(DEFAULT, 'Chinese'),
(DEFAULT, 'Greek');

INSERT INTO journals
VALUES
(DEFAULT, 'The Dublin Postman', 'TDP'),
(DEFAULT, 'The Washington News', 'TWN'),
(DEFAULT, 'The New York Bugle', 'TNYB'),
(DEFAULT, 'The Washington Observer', 'TWO'),
(DEFAULT, 'The Manchester Mail', 'TMM'),
(DEFAULT, 'The Washington Mail', 'TWM'),
(DEFAULT, 'The New York Observer', 'TNYO'),
(DEFAULT, 'The Glasgow Bugle', 'TGB'),
(DEFAULT, 'The Manchester Bugle', 'TMB'),
(DEFAULT, 'The Dublin News', 'TDN'),
(DEFAULT, 'The Warsaw Guardian', 'TWG'),
(DEFAULT, 'The Warsaw Sun', 'TWS'),
(DEFAULT, 'The Weekly Guardian', 'TWG'),
(DEFAULT, 'The London News', 'TLN'),
(DEFAULT, 'The Daily Postman', 'TDP'),
(DEFAULT, 'The Glasgow Postman', 'TGP'),
(DEFAULT, 'The Washington Bugle', 'TWB'),
(DEFAULT, 'The London Sun', 'TLS'),
(DEFAULT, 'The Weekly Mail', 'TWM'),
(DEFAULT, 'The Washington Guardian', 'TWG');

INSERT INTO genres
VALUES
(DEFAULT, 'drama', NULL),
(DEFAULT, 'biographical', 'biography'),
(DEFAULT, 'science-fiction', 'sci-fi'),
(DEFAULT, 'fantasy', NULL),
(DEFAULT, 'historical', 'history'),
(DEFAULT, 'documentary', 'doc'),
(DEFAULT, 'comedy', NULL),
(DEFAULT, 'action', NULL),
(DEFAULT, 'thriller', NULL),
(DEFAULT, 'horror', NULL);

INSERT INTO people
VALUES
(DEFAULT, 'John', 'Hu', NULL),
(DEFAULT, 'Robert', 'Yao', NULL),
(DEFAULT, 'Anna', 'Fu', 'A'),
(DEFAULT, 'Abdul', 'Deng', 'Abdud'),
(DEFAULT, 'Jean', 'Shi', NULL),
(DEFAULT, 'Nushi', 'Ahmed', NULL),
(DEFAULT, 'Ali', 'Yan', 'Ya'),
(DEFAULT, 'Robert', 'Islam', 'Robisl'),
(DEFAULT, 'Mary', 'Hassan', 'Mh'),
(DEFAULT, 'Michael', 'Pan', 'Michp'),
(DEFAULT, 'Juan', 'Yan', NULL),
(DEFAULT, 'Muhammad', 'Cai', NULL),
(DEFAULT, 'Nushi', 'Zhou', 'Nzho'),
(DEFAULT, 'Anna', 'Singh', NULL),
(DEFAULT, 'Anna', 'Hussain', NULL),
(DEFAULT, 'Michael', 'Li', NULL),
(DEFAULT, 'Jose', 'Yao', NULL),
(DEFAULT, 'Ahmed', 'Ren', NULL),
(DEFAULT, 'Jose', 'Das', NULL),
(DEFAULT, 'Abdul', 'Wang', NULL),
(DEFAULT, 'Ahmed', 'Peng', NULL),
(DEFAULT, 'Ying', 'Zhao', NULL),
(DEFAULT, 'Yan', 'Fu', NULL),
(DEFAULT, 'Wei', 'Zhu', NULL),
(DEFAULT, 'Mohamed', 'Cheng', NULL),
(DEFAULT, 'Ying', 'Wang', NULL),
(DEFAULT, 'Ana', 'Zhang', 'Azh'),
(DEFAULT, 'Mohammad', 'Huang', 'M'),
(DEFAULT, 'Ana', 'Fang', 'Anf'),
(DEFAULT, 'Muhammad', 'Sanchez', NULL),
(DEFAULT, 'Michael', 'Sun', 'Michaesu'),
(DEFAULT, 'Li', 'Jiang', NULL),
(DEFAULT, 'Robert', 'He', NULL),
(DEFAULT, 'David', 'Du', NULL),
(DEFAULT, 'Abdul', 'Xiao', NULL),
(DEFAULT, 'Mohammad', 'Guo', 'Gu'),
(DEFAULT, 'Michael', 'Ahmed', NULL),
(DEFAULT, 'Maria', 'Wu', NULL),
(DEFAULT, 'Nushi', 'Ahmed', 'Ah'),
(DEFAULT, 'Mohammed', 'Cai', 'Mohamme'),
(DEFAULT, 'Michael', 'Khan', NULL),
(DEFAULT, 'Juan', 'Su', NULL),
(DEFAULT, 'Ana', 'Begum', NULL),
(DEFAULT, 'Jose', 'Ali', NULL),
(DEFAULT, 'John', 'Hernandez', NULL),
(DEFAULT, 'Nushi', 'Pereira', NULL),
(DEFAULT, 'Mary', 'Ali', 'Ma'),
(DEFAULT, 'Mohammad', 'Kim', 'Mohamma'),
(DEFAULT, 'Li', 'Lin', ''),
(DEFAULT, 'Abdul', 'Begum', NULL),
(DEFAULT, 'Michael', 'Ali', 'Mich'),
(DEFAULT, 'Mohammed', 'Silva', NULL),
(DEFAULT, 'Mohamed', 'Kaur', NULL),
(DEFAULT, 'Wei', 'Yan', NULL),
(DEFAULT, 'Mohamed', 'Deng', 'Mohde'),
(DEFAULT, 'Abdul', 'Liang', NULL),
(DEFAULT, 'Michael', 'Sanchez', NULL),
(DEFAULT, 'Muhammad', 'Kim', 'Ki'),
(DEFAULT, 'Michael', 'Huang', NULL),
(DEFAULT, 'Nushi', 'Yang', NULL),
(DEFAULT, 'Ying', 'Tran', 'T'),
(DEFAULT, 'Mohammed', 'Fan', 'Mohf'),
(DEFAULT, 'Jose', 'Yadav', 'Yada'),
(DEFAULT, 'Mohammed', 'Feng', NULL),
(DEFAULT, 'Juan', 'Xiao', 'Jux'),
(DEFAULT, 'Jean', 'Ding', 'Jedin'),
(DEFAULT, 'Muhammad', 'Du', NULL),
(DEFAULT, 'Abdul', 'Islam', NULL),
(DEFAULT, 'Mohammed', 'Li', NULL),
(DEFAULT, 'Juan', 'Ali', 'Jal'),
(DEFAULT, 'Ahmed', 'Khan', NULL),
(DEFAULT, 'Mohammed', 'Luo', NULL),
(DEFAULT, 'Mohamed', 'Cao', NULL),
(DEFAULT, 'Robert', 'Wei', NULL),
(DEFAULT, 'Mary', 'Tran', 'Ma'),
(DEFAULT, 'Muhammad', 'Gao', 'Mga'),
(DEFAULT, 'Michael', 'Zhu', 'Mich'),
(DEFAULT, 'Robert', 'Xie', 'Roberx'),
(DEFAULT, 'Ying', 'Ceng', ''),
(DEFAULT, 'Mary', 'Hernandez', NULL),
(DEFAULT, 'Nushi', 'Wang', NULL),
(DEFAULT, 'Muhammad', 'Fu', NULL),
(DEFAULT, 'Mohamed', 'Yin', NULL),
(DEFAULT, 'Robert', 'Hernandez', NULL),
(DEFAULT, 'Jose', 'Wu', NULL),
(DEFAULT, 'Robert', 'Zhu', NULL),
(DEFAULT, 'John', 'Perez', NULL),
(DEFAULT, 'Li', 'Khan', 'L'),
(DEFAULT, 'John', 'Hu', NULL),
(DEFAULT, 'Jean', 'Zhao', NULL),
(DEFAULT, 'Michael', 'Kaur', NULL),
(DEFAULT, 'Muhammad', 'Khatun', NULL),
(DEFAULT, 'Mohamed', 'Kaur', 'Mohamka'),
(DEFAULT, 'Li', 'Cui', NULL),
(DEFAULT, 'Mohammad', 'Zheng', 'Mzhe'),
(DEFAULT, 'Nushi', 'Gonzalez', 'Nusgonza'),
(DEFAULT, 'Yan', 'Sharma', NULL),
(DEFAULT, 'Mohammad', 'Guo', 'Mohg'),
(DEFAULT, 'Ali', 'Tang', NULL),
(DEFAULT, 'Ahmed', 'Han', NULL);

INSERT INTO producers
VALUES
(DEFAULT, 'Good Traveller Cinema'),
(DEFAULT, 'First Family Inc.'),
(DEFAULT, 'Last Cat Cinema'),
(DEFAULT, 'Last Family Inc.'),
(DEFAULT, 'Bad Man & Sons'),
(DEFAULT, 'Bad Journey Cinema'),
(DEFAULT, 'Blue Spider Cinema'),
(DEFAULT, 'Amazing Plane Inc.'),
(DEFAULT, 'Bad Family Cinema'),
(DEFAULT, 'Shy Traveller Ltd.'),
(DEFAULT, 'Great Spider Inc.'),
(DEFAULT, 'First Journey & Sons'),
(DEFAULT, 'Blue Plane Cinema'),
(DEFAULT, 'Magical Traveller Bros'),
(DEFAULT, 'First Spider & Sons'),
(DEFAULT, 'Shy Cat Ltd.'),
(DEFAULT, 'Bad Traveller Bros'),
(DEFAULT, 'Colorful Journey Cinema'),
(DEFAULT, 'Magical Spider Cinema'),
(DEFAULT, 'Big Plane & Sons');

INSERT INTO movies
VALUES
(DEFAULT, 'The Bad Journey', '157 minutes', 11, '1999-08-15', 4),
(DEFAULT, 'No Brave Cat', '170 minutes', 3, '1976-09-22', 6),
(DEFAULT, 'A Joyful Traveller', '81 minutes', 8, '1965-03-01', 1),
(DEFAULT, 'The Brave Journey', '20 minutes', 15, '1993-11-19', 4),
(DEFAULT, 'Some Brave Spider', '64 minutes', 5, '1940-02-25', 7),
(DEFAULT, 'The Colorful Ship', '120 minutes', 2, '2011-04-28', 2),
(DEFAULT, 'Some Red Snake', '172 minutes', 17, '2011-10-11', 8),
(DEFAULT, 'No Yellow Spider', '142 minutes', 15, '1960-12-28', 8),
(DEFAULT, 'Some Last Car', '165 minutes', 9, '2006-08-21', 4),
(DEFAULT, 'The Entire Blossoming Dog', '75 minutes', 8, '1974-06-11', 9),
(DEFAULT, 'A Red Cat', '61 minutes', 13, '1959-12-07', 2),
(DEFAULT, 'Some Bad Man', '140 minutes', 15, '1993-01-07', 7),
(DEFAULT, 'Some Happy Family', '149 minutes', 13, '2001-01-12', 5),
(DEFAULT, 'Some Bad Ship', '141 minutes', 8, '2002-04-09', 7),
(DEFAULT, 'Some Big Spider', '88 minutes', 13, '1961-08-05', 9),
(DEFAULT, 'A Good Journey', '146 minutes', 1, '1950-11-14', 3),
(DEFAULT, 'Some Colorful Family', '68 minutes', 13, '1981-04-15', 6),
(DEFAULT, 'The Entire Good Plane', '109 minutes', 9, '1950-08-01', 9),
(DEFAULT, 'A Great Car', '168 minutes', 3, '1945-01-08', 4),
(DEFAULT, 'A Red Car', '34 minutes', 16, '1954-10-07', 8),
(DEFAULT, 'The Entire Great Cat', '157 minutes', 4, '1960-05-04', 1),
(DEFAULT, 'The Entire Happy Traveller', '98 minutes', 13, '1965-02-19', 4),
(DEFAULT, 'A Magical Traveller', '155 minutes', 4, '2012-01-12', 9),
(DEFAULT, 'Some Great Dog', '131 minutes', 11, '1941-07-27', 8),
(DEFAULT, 'A Bad Man', '164 minutes', 15, '1959-07-06', 9),
(DEFAULT, 'The Entire Shy Snake', '121 minutes', 14, '2015-05-11', 4),
(DEFAULT, 'A Last Snake', '64 minutes', 15, '2012-10-22', 7),
(DEFAULT, 'The Entire Big Snake', '85 minutes', 6, '2002-04-12', 5),
(DEFAULT, 'The Entire Last Journey', '72 minutes', 18, '1941-09-07', 2),
(DEFAULT, 'The Bad Snake', '144 minutes', 8, '2000-11-23', 8),
(DEFAULT, 'Some Big Dog', '77 minutes', 8, '1991-12-08', 5),
(DEFAULT, 'No Great Snake', '143 minutes', 17, '1984-07-24', 9),
(DEFAULT, 'The Entire Great Snake', '71 minutes', 10, '1972-04-04', 4),
(DEFAULT, 'The Entire Blue Ship', '178 minutes', 6, '1964-04-24', 8),
(DEFAULT, 'The Entire Happy Ship', '154 minutes', 10, '1952-04-10', 4),
(DEFAULT, 'The Entire Colorful Plane', '5 minutes', 18, '1956-05-02', 1),
(DEFAULT, 'No Magical Cat', '165 minutes', 16, '1953-01-19', 5),
(DEFAULT, 'Some Brave Snake', '89 minutes', 6, '1946-05-28', 8),
(DEFAULT, 'A Tiny Spider', '127 minutes', 3, '2013-11-22', 1),
(DEFAULT, 'The Red Journey', '79 minutes', 3, '1971-02-18', 7),
(DEFAULT, 'No Joyful Ship', '99 minutes', 15, '1996-05-28', 7),
(DEFAULT, 'The Entire Happy Journey', '17 minutes', 4, '1966-11-07', 5),
(DEFAULT, 'A Colorful Car', '46 minutes', 18, '1949-03-01', 7),
(DEFAULT, 'Some Brave Plane', '10 minutes', 8, '1976-12-10', 8),
(DEFAULT, 'A Joyful Plane', '162 minutes', 19, '1965-07-04', 9),
(DEFAULT, 'The Red Plane', '38 minutes', 3, '1947-03-26', 5),
(DEFAULT, 'No Happy Plane', '114 minutes', 4, '1999-12-10', 7),
(DEFAULT, 'The Entire Yellow Ship', '128 minutes', 15, '1950-10-02', 7),
(DEFAULT, 'The Entire Last Family', '25 minutes', 8, '2013-10-01', 5),
(DEFAULT, 'No Small Cat', '122 minutes', 17, '1996-05-06', 7),
(DEFAULT, 'Some Tiny Snake', '91 minutes', 14, '1982-06-22', 2),
(DEFAULT, 'The First Spider', '179 minutes', 16, '1976-11-13', 9),
(DEFAULT, 'A Blossoming Dog', '82 minutes', 9, '1981-02-25', 7),
(DEFAULT, 'No Big Traveller', '140 minutes', 15, '1992-01-07', 9),
(DEFAULT, 'The Entire Brave Traveller', '115 minutes', 2, '1966-05-18', 3),
(DEFAULT, 'The Entire Blossoming Snake', '33 minutes', 1, '2020-10-26', 4),
(DEFAULT, 'The Magical Ship', '5 minutes', 18, '1992-02-08', 2),
(DEFAULT, 'Some Blue Traveller', '41 minutes', 16, '1977-09-23', 5),
(DEFAULT, 'Some Brave Snake II', '64 minutes', 15, '2010-03-13', 4),
(DEFAULT, 'No Yellow Cat', '19 minutes', 9, '1993-06-26', 9),
(DEFAULT, 'The Entire Big Plane', '78 minutes', 19, '2014-11-16', 3),
(DEFAULT, 'Some Shy Snake', '90 minutes', 11, '2010-09-13', 8),
(DEFAULT, 'The Entire Amazing Car', '148 minutes', 13, '1969-07-02', 6),
(DEFAULT, 'Some Good Spider', '171 minutes', 5, '2003-01-05', 9),
(DEFAULT, 'No First Dog', '114 minutes', 4, '2007-08-01', 3),
(DEFAULT, 'Some Red Dog', '122 minutes', 9, '1983-10-23', 7),
(DEFAULT, 'A First Traveller', '138 minutes', 13, '1980-11-23', 8),
(DEFAULT, 'No Small Journey', '19 minutes', 8, '2020-11-10', 4),
(DEFAULT, 'A Bad Dog', '164 minutes', 4, '1996-03-23', 5),
(DEFAULT, 'A Small Man', '16 minutes', 10, '1985-06-14', 3),
(DEFAULT, 'The Yellow Spider', '146 minutes', 6, '1961-03-03', 7),
(DEFAULT, 'No Joyful Snake', '151 minutes', 5, '1969-08-21', 5),
(DEFAULT, 'Some Last Traveller', '4 minutes', 15, '1976-11-18', 3),
(DEFAULT, 'A Blossoming Man', '152 minutes', 10, '2021-07-23', 5),
(DEFAULT, 'Some Magical Car', '100 minutes', 16, '1953-04-13', 6),
(DEFAULT, 'No Magical Plane', '7 minutes', 13, '1975-01-19', 1),
(DEFAULT, 'No Brave Plane', '60 minutes', 12, '1968-11-07', 5),
(DEFAULT, 'The Blue Traveller', '167 minutes', 2, '1979-08-02', 6),
(DEFAULT, 'The Tiny Plane', '85 minutes', 14, '1962-04-05', 9),
(DEFAULT, 'The Entire Bad Trip To Vipers Nest','105 minutes',18,'2022-03-01',2),
(DEFAULT, 'The Entire Yellow Shipping Company Went Bancrupt', '71 minutes', 6, '1972-08-26', 5),
(DEFAULT, 'The Entire Blue Snake', '21 minutes', 5, '1968-11-24', 7),
(DEFAULT, 'No Great Dog', '103 minutes', 1, '1973-09-04', 8),
(DEFAULT, 'The Entire Last Journey', '99 minutes', 12, '1953-11-08', 8),
(DEFAULT, 'A Shy Man', '158 minutes', 8, '1948-11-27', 8),
(DEFAULT, 'The Entire Bad Dog', '37 minutes', 2, '1944-05-16', 2),
(DEFAULT, 'A Joyful Ship', '36 minutes', 13, '1998-06-22', 9),
(DEFAULT, 'Some Happy Cat', '108 minutes', 4, '2002-10-14', 5),
(DEFAULT, 'A Great Car', '115 minutes', 15, '1970-06-04', 6),
(DEFAULT, 'No Great Family', '103 minutes', 9, '1964-02-28', 8),
(DEFAULT, 'A Amazing Traveller', '165 minutes', 1, '1946-06-08', 3),
(DEFAULT, 'No Amazing Dog', '143 minutes', 7, '2015-04-27', 4),
(DEFAULT, 'The Entire Red Journey (Starving to death in 2 minutes)', '2 minutes', 9, '1958-03-18', 5),
(DEFAULT, 'The Blue Traveller', '8 minutes', 5, '1941-06-26', 4),
(DEFAULT, 'No First Family', '46 minutes', 9, '1946-03-24', 7),
(DEFAULT, 'No Blue Dog', '123 minutes', 15, '1986-09-19', 2),
(DEFAULT, 'Some Yellow Car', '159 minutes', 2, '2006-05-15', 1),
(DEFAULT, 'A Brave Spider', '111 minutes', 4, '2002-12-15', 2),
(DEFAULT, 'A First Journey', '39 minutes', 3, '1956-05-20', 9),
(DEFAULT, 'The Entire Good Journey', '137 minutes', 10, '1998-09-20', 7);

INSERT INTO movies_genres
VALUES
(55, 2),
(34, 10),
(36, 7),
(50, 6),
(96, 3),
(94, 3),
(8, 9),
(10, 6),
(19, 9),
(51, 7),
(2, 2),
(49, 7),
(6, 2),
(97, 10),
(89, 6),
(45, 3),
(70, 2),
(47, 9),
(27, 6),
(3, 6),
(17, 10),
(30, 2),
(42, 4),
(9, 10),
(11, 7),
(43, 5),
(98, 5),
(1, 8),
(26, 7),
(29, 6),
(16, 6),
(38, 9),
(79, 10),
(97, 3),
(55, 6),
(22, 3),
(36, 2),
(59, 4),
(27, 8),
(85, 4),
(24, 3),
(81, 9),
(72, 6),
(82, 8),
(73, 5),
(54, 10),
(45, 7),
(47, 4),
(100, 7),
(80, 10),
(65, 3),
(66, 2),
(68, 8),
(33, 8),
(35, 5),
(15, 2),
(98, 9),
(18, 7),
(39, 5),
(87, 6),
(20, 1),
(31, 10),
(36, 6),
(77, 7),
(14, 3),
(37, 5),
(69, 3),
(91, 6),
(100, 9),
(74, 8),
(52, 5),
(32, 2),
(96, 5),
(44, 1),
(98, 2),
(24, 7),
(15, 4),
(72, 1),
(18, 9),
(53, 6),
(20, 3),
(56, 2),
(100, 2),
(77, 9),
(5, 2),
(58, 5),
(60, 2),
(67, 8),
(74, 1),
(52, 7),
(99, 3),
(7, 2),
(71, 5),
(20, 5),
(56, 4),
(12, 1),
(12, 10),
(3, 7),
(23, 10),
(4, 6),
(58, 7),
(59, 6),
(67, 10),
(78, 10),
(83, 6),
(89, 10),
(51, 10),
(92, 9),
(94, 6),
(43, 6),
(13, 2),
(24, 2),
(25, 1),
(88, 5),
(18, 4),
(53, 1),
(40, 1),
(63, 3),
(29, 10),
(40, 10),
(95, 10),
(21, 6),
(97, 7),
(14, 9),
(70, 8),
(52, 2),
(33, 7),
(35, 4),
(88, 7),
(16, 9),
(57, 10),
(48, 7),
(39, 4),
(62, 6),
(68, 10),
(84, 3),
(86, 9),
(12, 5),
(58, 2),
(41, 4),
(75, 6),
(19, 1),
(30, 1),
(42, 3),
(93, 5),
(19, 10),
(11, 6),
(90, 6),
(81, 3),
(38, 8),
(14, 4),
(87, 10),
(4, 3),
(80, 4),
(61, 9),
(28, 6),
(30, 3),
(93, 7),
(96, 6),
(10, 9),
(1, 6),
(79, 8),
(48, 2),
(49, 1),
(15, 8),
(38, 10),
(22, 1),
(87, 3),
(77, 10),
(78, 9),
(4, 5),
(69, 6),
(80, 6),
(50, 2),
(61, 2),
(10, 2),
(76, 2),
(79, 1),
(2, 7),
(25, 9),
(46, 7),
(57, 7),
(39, 1),
(7, 6),
(21, 5),
(84, 9),
(64, 3),
(34, 8),
(5, 8),
(94, 10),
(65, 4),
(25, 2),
(66, 3),
(99, 6),
(48, 6),
(13, 6),
(63, 4),
(84, 2),
(72, 9),
(86, 8);

INSERT INTO movies_producers
VALUES
(55, 2),
(7, 17),
(18, 17),
(21, 16),
(56, 1),
(78, 4),
(54, 13),
(89, 13),
(70, 9),
(61, 6),
(97, 17),
(22, 17),
(36, 16),
(28, 12),
(83, 12),
(88, 8),
(68, 2),
(48, 8),
(13, 8),
(95, 4),
(86, 1),
(26, 14),
(72, 11),
(45, 3),
(59, 2),
(55, 13),
(59, 11),
(70, 11),
(5, 3),
(47, 18),
(14, 15),
(83, 14),
(52, 17),
(35, 10),
(6, 4),
(79, 10),
(10, 20),
(15, 16),
(62, 3),
(87, 2),
(72, 13),
(82, 15),
(34, 5),
(70, 4),
(53, 18),
(37, 1),
(27, 8),
(14, 8),
(75, 3),
(30, 13),
(92, 19),
(85, 13),
(93, 17),
(41, 10),
(95, 8),
(62, 5),
(64, 2),
(72, 15),
(100, 7),
(40, 20),
(92, 3),
(100, 16),
(14, 10),
(19, 6),
(52, 3),
(61, 15),
(52, 12),
(75, 14),
(98, 9),
(90, 5),
(1, 12),
(39, 5),
(73, 16),
(29, 13),
(63, 15),
(56, 9),
(21, 18),
(91, 15),
(69, 12),
(94, 11),
(51, 6),
(50, 8),
(43, 2),
(60, 18),
(83, 20),
(8, 20),
(25, 15),
(16, 12),
(48, 10),
(39, 7),
(31, 12),
(77, 18),
(80, 14),
(60, 11),
(94, 13),
(98, 4),
(50, 19),
(8, 13),
(2, 6),
(7, 2),
(25, 17),
(81, 15),
(7, 11),
(71, 14),
(63, 10),
(20, 5),
(47, 1),
(49, 20),
(40, 17),
(86, 5),
(23, 10),
(3, 7),
(3, 16),
(90, 2),
(44, 14),
(48, 5),
(90, 20),
(6, 17),
(78, 3),
(87, 15),
(89, 12),
(51, 3),
(30, 8),
(42, 10),
(99, 7),
(74, 17),
(76, 14),
(85, 17),
(62, 6),
(84, 3),
(20, 9),
(77, 6),
(69, 2),
(12, 14),
(32, 1),
(45, 20),
(47, 17),
(61, 16),
(80, 20),
(24, 6),
(57, 3),
(82, 2),
(11, 15),
(57, 12),
(20, 2),
(40, 14),
(58, 4),
(53, 17),
(67, 16),
(96, 6),
(17, 15),
(30, 12),
(33, 11),
(74, 12),
(85, 12),
(99, 20),
(38, 1),
(49, 1),
(66, 17),
(71, 13),
(15, 8),
(18, 13),
(21, 12),
(77, 10),
(97, 13),
(4, 5),
(59, 5),
(67, 18),
(45, 15),
(91, 12),
(8, 5),
(33, 4),
(37, 20),
(65, 2),
(19, 14),
(2, 7),
(66, 10),
(68, 7),
(63, 2),
(46, 16),
(15, 10),
(95, 9),
(86, 6),
(87, 5),
(36, 5),
(28, 1),
(19, 7),
(1, 1),
(9, 6),
(17, 19),
(74, 16),
(99, 15),
(29, 2),
(84, 2),
(13, 15);

INSERT INTO movies_directors
VALUES
(12, 4),
(26, 21),
(79, 88),
(99, 100),
(16, 93),
(37, 6),
(100, 74),
(94, 3),
(28, 67),
(81, 48),
(36, 80),
(82, 47),
(90, 51),
(48, 54),
(71, 56),
(8, 82),
(30, 82),
(24, 8),
(18, 10),
(18, 74),
(89, 79),
(34, 76),
(40, 34),
(14, 79),
(100, 30),
(83, 78),
(95, 43),
(60, 21),
(97, 40),
(32, 69),
(52, 17),
(84, 52),
(20, 58),
(13, 74),
(61, 93),
(84, 6),
(10, 29),
(59, 50),
(64, 64),
(19, 41),
(7, 21),
(17, 53),
(39, 83),
(76, 47),
(93, 63),
(22, 76),
(40, 27),
(82, 97),
(14, 17),
(80, 17),
(24, 67),
(12, 47),
(27, 29),
(38, 11),
(60, 32),
(23, 56),
(6, 70),
(90, 21),
(53, 66),
(70, 61),
(31, 17),
(74, 52),
(40, 84),
(31, 81),
(74, 6),
(65, 3),
(3, 92),
(13, 60),
(84, 65),
(87, 61),
(8, 91),
(78, 58),
(82, 19),
(20, 10),
(16, 92),
(62, 25),
(14, 12),
(73, 98),
(66, 59),
(86, 92),
(33, 65),
(21, 45),
(89, 42),
(45, 39),
(24, 16),
(10, 26),
(79, 80),
(51, 45),
(49, 27),
(34, 75),
(17, 68),
(22, 82),
(29, 33),
(7, 39),
(61, 74),
(75, 73),
(50, 19),
(98, 4),
(41, 80),
(36, 93),
(50, 92),
(98, 77),
(71, 14),
(55, 60),
(20, 60),
(45, 59),
(53, 72),
(94, 61),
(58, 7),
(37, 73),
(80, 16),
(13, 48),
(67, 28),
(59, 79),
(98, 61),
(4, 88),
(43, 70),
(41, 82),
(65, 12),
(88, 78),
(1, 18),
(91, 95),
(45, 52),
(77, 50),
(69, 64),
(92, 66),
(97, 89),
(44, 62),
(62, 98),
(64, 40),
(73, 52),
(48, 62),
(8, 90),
(57, 19),
(11, 31),
(5, 45),
(43, 38),
(21, 17),
(68, 46),
(15, 40),
(2, 58),
(54, 41),
(100, 93),
(10, 16),
(70, 37),
(71, 2),
(76, 71),
(64, 60),
(76, 25),
(52, 98),
(78, 71),
(95, 87),
(4, 12),
(80, 13),
(49, 44),
(69, 77),
(97, 93),
(34, 22),
(73, 47),
(78, 98),
(5, 86),
(88, 20),
(99, 84),
(32, 79),
(63, 64),
(21, 67),
(9, 47),
(44, 32),
(57, 32),
(77, 10),
(87, 67),
(41, 54),
(89, 18),
(96, 54),
(81, 44),
(47, 21),
(85, 5),
(91, 76),
(70, 87),
(93, 73),
(66, 65),
(27, 91),
(68, 7),
(93, 91),
(91, 39),
(51, 94),
(6, 71),
(35, 22),
(46, 89),
(50, 41),
(92, 65),
(25, 39),
(72, 34),
(42, 64),
(36, 78),
(22, 24),
(31, 36),
(56, 35),
(28, 37),
(43, 83),
(6, 9);

INSERT INTO movies_composers
VALUES
(15, 85),
(25, 41),
(18, 99),
(75, 8),
(38, 7),
(35, 72),
(46, 84),
(67, 52),
(35, 90),
(73, 74),
(35, 35),
(10, 100),
(62, 83),
(71, 31),
(45, 21),
(36, 18),
(17, 69),
(16, 49),
(57, 59),
(12, 91),
(71, 58),
(2, 68),
(28, 87),
(74, 84),
(68, 13),
(15, 62),
(69, 42),
(27, 36),
(53, 64),
(17, 44),
(25, 91),
(64, 73),
(20, 79),
(42, 61),
(5, 5),
(14, 72),
(77, 21),
(66, 55),
(88, 58),
(21, 32),
(29, 45),
(22, 39),
(72, 43),
(84, 54),
(13, 67),
(70, 34),
(66, 82),
(89, 47),
(51, 93),
(45, 53),
(33, 33),
(78, 65),
(18, 87),
(48, 42),
(37, 76),
(63, 95),
(85, 61),
(96, 12),
(81, 29),
(65, 97),
(8, 54),
(63, 24),
(93, 67),
(76, 60),
(86, 28),
(32, 57),
(31, 37),
(52, 5),
(44, 1),
(18, 46),
(32, 11),
(98, 66),
(52, 23),
(67, 42),
(8, 20),
(90, 71),
(79, 16),
(80, 48),
(2, 22),
(30, 38),
(54, 5),
(79, 89),
(74, 47),
(83, 59),
(48, 37),
(41, 53),
(66, 52),
(11, 61),
(50, 74),
(10, 65),
(69, 32),
(78, 99),
(25, 63),
(7, 57),
(73, 2),
(16, 23),
(68, 24),
(6, 15),
(39, 82),
(89, 10),
(91, 74),
(3, 80),
(26, 45),
(29, 99),
(4, 88),
(64, 38),
(50, 30),
(56, 43),
(61, 94),
(27, 37),
(19, 88),
(82, 62),
(20, 62),
(85, 97),
(60, 43),
(32, 45),
(58, 64),
(67, 12),
(6, 90),
(95, 92),
(58, 18),
(50, 69),
(87, 88),
(86, 98),
(33, 62),
(96, 66),
(59, 35),
(47, 97),
(1, 75),
(42, 92),
(65, 23),
(9, 89),
(39, 68),
(54, 2),
(77, 52),
(57, 83),
(11, 95),
(100, 72),
(53, 24),
(4, 19),
(45, 84),
(91, 26),
(99, 73),
(19, 83),
(90, 15),
(9, 27),
(65, 25),
(49, 8),
(28, 49),
(24, 27),
(22, 72),
(24, 91),
(84, 78),
(58, 68),
(49, 99),
(55, 78),
(16, 41),
(72, 39),
(73, 93),
(27, 16),
(28, 70),
(88, 11),
(90, 8),
(94, 88),
(40, 7),
(97, 59),
(26, 72),
(43, 88),
(33, 96),
(59, 60),
(86, 86),
(39, 29),
(80, 79),
(96, 63),
(78, 91),
(89, 91),
(99, 59),
(88, 68),
(46, 62),
(23, 39),
(63, 2),
(3, 100),
(75, 86),
(49, 12),
(75, 31),
(6, 25),
(55, 73),
(93, 57),
(36, 14),
(62, 33),
(91, 69),
(34, 26),
(59, 25),
(51, 5),
(54, 38),
(85, 71),
(92, 22),
(37, 31),
(84, 48),
(3, 93),
(37, 95),
(19, 89),
(51, 23),
(80, 38),
(68, 18),
(11, 94),
(97, 8);

INSERT INTO movies_screenwriters
VALUES
(68, 91),
(15, 85),
(95, 20),
(35, 97),
(1, 40),
(50, 61),
(8, 9),
(39, 42),
(20, 93),
(60, 10),
(63, 43),
(21, 55),
(18, 1),
(14, 49),
(77, 53),
(98, 85),
(66, 96),
(19, 39),
(89, 70),
(17, 51),
(36, 18),
(99, 1),
(34, 30),
(52, 8),
(46, 68),
(23, 45),
(50, 29),
(55, 43),
(43, 23),
(51, 91),
(12, 54),
(61, 93),
(88, 22),
(90, 83),
(89, 63),
(23, 20),
(74, 13),
(93, 81),
(78, 29),
(13, 58),
(58, 35),
(61, 86),
(50, 31),
(87, 59),
(15, 18),
(64, 2),
(65, 95),
(100, 71),
(28, 9),
(39, 39),
(9, 5),
(38, 41),
(94, 9),
(22, 32),
(6, 45),
(37, 30),
(37, 94),
(60, 25),
(78, 95),
(44, 72),
(27, 31),
(70, 100),
(10, 24),
(62, 62),
(41, 39),
(81, 20),
(96, 48),
(29, 77),
(86, 83),
(4, 75),
(89, 24),
(61, 72),
(56, 48),
(73, 64),
(24, 25),
(87, 63),
(1, 87),
(47, 54),
(9, 37),
(74, 93),
(10, 99),
(46, 86),
(79, 34),
(56, 11),
(88, 46),
(100, 2),
(92, 7),
(17, 68),
(41, 53),
(46, 49),
(72, 40),
(67, 90),
(71, 60),
(15, 70),
(53, 54),
(71, 69),
(73, 66),
(16, 23),
(53, 72),
(2, 33),
(30, 58),
(48, 39),
(58, 7),
(20, 87),
(31, 87),
(68, 51),
(12, 83),
(69, 71),
(78, 19),
(87, 22),
(58, 25),
(42, 8),
(26, 54),
(42, 72),
(21, 49),
(16, 16),
(85, 88),
(85, 33),
(31, 7),
(38, 77),
(100, 53),
(75, 41),
(34, 70),
(54, 18),
(76, 48),
(5, 6),
(95, 28),
(6, 90),
(60, 6),
(81, 38),
(12, 94),
(98, 63),
(90, 68),
(45, 45),
(75, 98),
(85, 44),
(49, 24),
(77, 6),
(40, 85),
(14, 11),
(97, 82),
(49, 97),
(80, 75),
(96, 59),
(44, 55),
(67, 32),
(44, 64),
(54, 32),
(72, 46),
(80, 93),
(2, 3),
(25, 5),
(47, 90),
(70, 37),
(88, 18),
(54, 50),
(3, 96),
(92, 98),
(83, 49),
(26, 79),
(32, 95),
(43, 95),
(18, 29),
(84, 32),
(86, 93),
(91, 10),
(2, 51),
(90, 8),
(51, 19),
(57, 69),
(56, 58),
(38, 74),
(48, 20),
(84, 71),
(11, 99),
(24, 93),
(97, 86),
(26, 99),
(64, 28),
(59, 78),
(82, 43),
(52, 72),
(96, 8),
(17, 17),
(59, 87),
(93, 18),
(37, 38),
(43, 81),
(41, 29),
(84, 64),
(7, 70),
(21, 69),
(92, 1),
(97, 79),
(33, 52),
(13, 49),
(39, 31),
(18, 97),
(16, 45),
(55, 27),
(72, 34),
(31, 91),
(95, 2),
(68, 27);

INSERT INTO movies_actors
VALUES
(89, 4, 'Mohammad Sanchez'),
(41, 49, 'Mohamed Hossain'),
(55, 66, 'Juan Hossain'),
(76, 43, 'David Silva'),
(82, 38, 'Li Zhao'),
(19, 73, 'Ying Bibi'),
(42, 75, 'Juan Zhong'),
(12, 98, 'Abdul Tan'),
(41, 24, 'Jean Le'),
(46, 20, 'Muhammad Han'),
(14, 49, 'Ana Zhao'),
(51, 98, 'Muhammad Han'),
(97, 65, 'Ying Martinez'),
(6, 20, 'Jose Cao'),
(21, 73, 'Abdul Islam'),
(44, 38, 'Maria Xie'),
(62, 74, 'Jean Cui'),
(81, 23, 'Mohamed Yuan'),
(18, 83, 'Abdul Ahmed'),
(22, 10, 'Mary Lin'),
(56, 12, 'Maria Yin'),
(82, 95, 'Wei Lopez'),
(91, 9, 'David Wang'),
(47, 82, 'Wei Tang'),
(8, 11, 'Mohammed Su'),
(48, 47, 'Ali He'),
(4, 23, 'Ahmed Du'),
(23, 36, 'Ying Fu'),
(4, 87, 'Juan Zhou'),
(52, 17, 'Abdul Ram'),
(98, 5, 'Juan Kumar'),
(35, 10, 'Ali Nguyen'),
(58, 42, 'John Zhong'),
(61, 93, 'Anna Ma'),
(72, 59, 'Li Lin'),
(10, 29, 'Michael Zhong'),
(38, 82, 'Mohamed Rahman'),
(62, 67, 'Mohamed Islam'),
(25, 27, 'Anna Yang'),
(71, 79, 'Maria Ceng'),
(54, 72, 'Li Yao'),
(64, 18, 'Robert Cao'),
(47, 20, 'Mohammed Yadav'),
(12, 84, 'Nushi Tang'),
(31, 97, 'Abdul Yadav'),
(66, 9, 'Ana Yuan'),
(32, 89, 'Juan Zhou'),
(50, 40, 'Abdul Cheng'),
(67, 56, 'Mary Silva'),
(88, 24, 'Ahmed Han'),
(15, 82, 'Mohammed Cao'),
(35, 30, 'Jose Ferreira'),
(88, 88, 'Wei Begum'),
(34, 7, 'Robert Han'),
(16, 90, 'Anna Tian'),
(2, 36, 'Anna Ma'),
(94, 55, 'Wei Begum'),
(3, 65, 'Ahmed Fan'),
(62, 32, 'Ali Pak'),
(69, 10, 'Ying Pereira'),
(28, 73, 'Muhammad Silva'),
(30, 70, 'Nushi Tang'),
(68, 54, 'Muhammad Jin'),
(83, 82, 'Mohammad Lu'),
(24, 5, 'Mohammad Muhammad'),
(38, 4, 'David Ceng'),
(32, 18, 'David Lopez'),
(93, 31, 'Ying Bibi'),
(21, 61, 'Ana Shi'),
(24, 23, 'Mohammed Lal'),
(79, 78, 'Mary Du'),
(54, 58, 'Mohammed Mandal'),
(85, 36, 'Wei Hernandez'),
(37, 51, 'Ana Zheng'),
(88, 99, 'Michael Su'),
(23, 70, 'Ali Yao'),
(63, 88, 'Nushi Ali'),
(17, 11, 'Abdul Zhang'),
(20, 28, 'Abdul Wang'),
(94, 20, 'Li He'),
(52, 14, 'Muhammad Kumari'),
(7, 46, 'Mary Mohammad'),
(33, 65, 'Nushi Ahmad'),
(75, 80, 'Robert Silva'),
(70, 93, 'Robert Ali'),
(95, 58, 'Muhammad Le'),
(59, 38, 'Maria Jin'),
(93, 33, 'Jose Hernandez'),
(89, 60, 'Ana Wu'),
(10, 90, 'Jose Islam'),
(44, 92, 'Yan Ma'),
(79, 89, 'Muhammad Hossain'),
(65, 35, 'Muhammad Singh'),
(73, 18, 'Maria Ye'),
(42, 49, 'Abdul Han'),
(45, 11, 'Mary Bibi'),
(74, 1, 'Wei Xu'),
(6, 31, 'Muhammad Silva'),
(20, 30, 'Li Islam'),
(46, 49, 'Mohammad Tang'),
(96, 62, 'Mohammad Yuan'),
(84, 42, 'Anna Liang'),
(19, 13, 'Robert Chen'),
(90, 27, 'Jean Wei'),
(60, 50, 'David Das'),
(51, 47, 'Mohammad Ibrahim'),
(80, 62, 'Mohammad Ibrahim'),
(14, 71, 'Mohammed Tran'),
(5, 13, 'Maria Mohammad'),
(77, 84, 'Muhammad Bai'),
(92, 18, 'Juan Feng'),
(27, 10, 'Jean Yu'),
(92, 82, 'Mohammed Zhang'),
(90, 57, 'Maria Gao'),
(11, 11, 'Ying Liang'),
(47, 95, 'Ying Ren'),
(55, 53, 'Robert Yan'),
(7, 68, 'Anna Zhu'),
(95, 10, 'Ying Hu'),
(65, 39, 'Muhammad Pan'),
(74, 51, 'Robert Rodriguez'),
(85, 51, 'Mohammad Huang'),
(83, 63, 'Abdul Ye'),
(9, 59, 'Yan Du'),
(24, 41, 'Mohamed Nguyen'),
(77, 77, 'Maria Maung'),
(64, 22, 'John Xiao'),
(97, 89, 'Ahmed Sun'),
(89, 94, 'Ahmed Lal'),
(78, 39, 'Maria Song'),
(96, 75, 'Ahmed Tran'),
(34, 45, 'Ana Hassan'),
(71, 64, 'Nushi Ibrahim'),
(27, 39, 'Mohamed Tan'),
(10, 32, 'Juan Pereira'),
(60, 100, 'Mohammad Yin'),
(32, 93, 'Nushi Li'),
(2, 37, 'David Zhu'),
(4, 56, 'Robert Yin'),
(12, 5, 'Mohammad Shi'),
(9, 52, 'Mohammed Su'),
(86, 73, 'Ying Pereira'),
(98, 47, 'Mohamed Guo'),
(53, 24, 'Nushi Yan'),
(13, 52, 'Yan Shi'),
(21, 35, 'John He'),
(1, 68, 'Abdul Tan'),
(42, 85, 'Ana Ren'),
(36, 99, 'Michael Muhammad'),
(57, 12, 'Muhammad Wang'),
(99, 82, 'Maria Ahmed'),
(11, 88, 'Mary Zhong'),
(91, 53, 'Ali Wang'),
(58, 50, 'David Yin'),
(68, 39, 'Jose Hu'),
(55, 14, 'Mohammad Feng'),
(26, 97, 'Nushi Lu'),
(34, 13, 'Mohammed Devi'),
(96, 52, 'Ying Kaur'),
(58, 77, 'John Hassan'),
(81, 51, 'Mohammed Perez'),
(99, 11, 'Mohammed Le'),
(18, 56, 'Li Sanchez'),
(2, 69, 'Mohammad Das'),
(31, 50, 'Robert Yin'),
(37, 100, 'Mohammad Wu'),
(39, 63, 'Muhammad Ferreira'),
(15, 8, 'Jose Zhu'),
(71, 77, 'Ali Kaur'),
(44, 32, 'Abdul Mohamed'),
(23, 73, 'Jose Xu'),
(87, 76, 'Wei Shi'),
(90, 38, 'John Ahmad'),
(8, 51, 'Jean Wei'),
(48, 41, 'David Lopez'),
(76, 57, 'Michael Luo'),
(70, 32, 'Jose Li'),
(40, 46, 'Wei Sharma'),
(99, 77, 'Jean Tian'),
(30, 87, 'Mohammed Perez'),
(57, 71, 'Mohammed Zhang'),
(66, 19, 'Wei Hossain'),
(49, 12, 'Muhammad Xu'),
(20, 6, 'Ali Nguyen'),
(29, 73, 'Mohamed Su'),
(26, 19, 'David Ibrahim'),
(98, 90, 'John Jiang'),
(43, 99, 'Ahmed Tang'),
(75, 49, 'Muhammad Liu'),
(6, 25, 'Anna Luo'),
(86, 15, 'Ana Kaur'),
(26, 92, 'Ana Huang'),
(41, 56, 'Li He'),
(7, 33, 'Ying Luo'),
(36, 78, 'Michael Mandal'),
(37, 77, 'John Martinez'),
(83, 74, 'Ana Han'),
(91, 87, 'Ying Shi'),
(100, 99, 'Mohamed Chen'),
(39, 58, 'Ahmed Huang'),
(94, 92, 'Ana Tran'),
(97, 54, 'Juan Ahmed'),
(69, 47, 'Jose Luo');

-- Rooms
INSERT INTO rooms VALUES
(DEFAULT,'Sala Tomka'),
(DEFAULT,'Sala Zosi'),
(DEFAULT,'Sala Basi'),
(DEFAULT,'Sala Kasi'),
(DEFAULT,'Sala Asi'),
(DEFAULT,'Sala Czesi');

-- Customers
INSERT INTO customers (email,username)
VALUES
  ('nunc@hotmail.couk','sem,'),
  ('erat.in.consectetuer@outlook.couk','lorem,'),
  ('auctor.quis@yahoo.ca','enim'),
  ('faucibus@icloud.org','sed'),
  ('lacus.quisque.purus@icloud.edu','tortor,'),
  ('ipsum@hotmail.ca','ipsum.'),
  ('magna@aol.org','enim.'),
  ('non@google.couk','Suspendisse'),
  ('semper.egestas@aol.edu','urna'),
  ('lacus.varius@icloud.net','Cras'),
  ('magnis@icloud.couk','lorem'),
  ('sed@icloud.net','mollis'),
  ('mauris.vestibulum@hotmail.org','mollis'),
  ('tellus.nunc.lectus@hotmail.ca','lectus'),
  ('mus@google.ca','enim,'),
  ('nibh.sit.amet@icloud.net','Donec'),
  ('erat.vivamus@outlook.couk','Phasellus'),
  ('nec.ante@protonmail.com','In'),
  ('hendrerit.consectetuer@icloud.com','Nam'),
  ('mus.proin.vel@icloud.ca','vulputate'),
  ('felis.nulla@google.couk','nunc'),
  ('felis@icloud.net','montes,'),
  ('ut.tincidunt@aol.couk','sapien'),
  ('vel.est.tempor@aol.org','adipiscing'),
  ('nec@outlook.org','dui.'),
  ('donec.est@google.org','mus.'),
  ('aliquam.enim@yahoo.org','Nam'),
  ('phasellus@yahoo.com','est,'),
  ('risus.donec@protonmail.edu','Donec'),
  ('et@icloud.net','ac'),
  ('arcu.eu@protonmail.ca','Donec'),
  ('curabitur.egestas.nunc@outlook.org','libero'),
  ('congue.in@outlook.ca','sed,'),
  ('ante@google.edu','convallis'),
  ('dis.parturient.montes@icloud.com','eu,'),
  ('vitae.mauris@protonmail.net','leo,'),
  ('consectetuer.rhoncus@google.edu','Donec'),
  ('gravida@protonmail.com','magna'),
  ('libero.proin@outlook.edu','neque'),
  ('dis.parturient.montes@outlook.org','scelerisque'),
  ('vitae.erat.vel@aol.net','tincidunt'),
  ('cras.vehicula.aliquet@icloud.ca','vestibulum'),
  ('scelerisque@hotmail.couk','elit,'),
  ('nec.euismod@outlook.edu','Sed'),
  ('in.nec@outlook.org','aptent'),
  ('cursus.luctus@google.edu','Donec'),
  ('mi.duis@outlook.ca','odio.'),
  ('suspendisse.aliquet.molestie@icloud.com','lobortis'),
  ('nibh.lacinia@yahoo.org','nisi'),
  ('diam.nunc.ullamcorper@protonmail.org','leo.'),
  ('pharetra.ut.pharetra@outlook.com','taciti'),
  ('nec@aol.couk','ut,'),
  ('dolor@outlook.com','semper'),
  ('pharetra.felis@icloud.couk','laoreet,'),
  ('euismod.in.dolor@icloud.ca','elit,'),
  ('nec.quam@google.ca','dictum'),
  ('cursus.purus@google.net','Cum'),
  ('eu@yahoo.com','Integer'),
  ('proin.velit@outlook.ca','massa.'),
  ('ridiculus.mus.proin@hotmail.com','sem'),
  ('turpis.nulla.aliquet@outlook.couk','eu'),
  ('dolor.egestas@hotmail.edu','a'),
  ('pellentesque.eget@yahoo.couk','fringilla'),
  ('turpis@protonmail.edu','risus'),
  ('euismod.et@icloud.edu','diam'),
  ('eu.ligula@aol.couk','mus.'),
  ('libero.proin@google.org','metus'),
  ('duis.at@google.couk','dolor.'),
  ('nullam.scelerisque@outlook.net','a'),
  ('etiam.vestibulum.massa@outlook.net','nec,'),
  ('mi@google.net','vel'),
  ('posuere.enim.nisl@google.ca','arcu.'),
  ('netus.et@outlook.org','Morbi'),
  ('sed.hendrerit@icloud.com','mi'),
  ('libero.proin@hotmail.org','ligula'),
  ('a.auctor.non@yahoo.couk','ullamcorper,'),
  ('feugiat@hotmail.com','arcu'),
  ('at.risus@hotmail.com','sociis'),
  ('dui.fusce@aol.ca','Pellentesque'),
  ('felis.nulla@icloud.couk','tristique'),
  ('adipiscing.non.luctus@hotmail.net','at'),
  ('eleifend.nunc@google.com','sit'),
  ('adipiscing.fringilla.porttitor@yahoo.ca','eu,'),
  ('neque.et@icloud.org','nisi.'),
  ('luctus@aol.net','euismod'),
  ('dignissim.magna@protonmail.net','blandit.'),
  ('pharetra.nibh@hotmail.com','magna'),
  ('eget.laoreet.posuere@icloud.edu','ligula.'),
  ('mattis.semper@yahoo.ca','libero'),
  ('et.ipsum.cursus@protonmail.net','In'),
  ('laoreet.lectus@protonmail.org','quis'),
  ('ullamcorper.eu@yahoo.couk','metus'),
  ('dui@hotmail.couk','mus.'),
  ('quisque@outlook.com','a'),
  ('ridiculus.mus.aenean@icloud.edu','eget'),
  ('erat.semper@hotmail.ca','sagittis'),
  ('accumsan.sed@protonmail.edu','Integer'),
  ('placerat.orci@aol.org','iaculis'),
  ('quisque.tincidunt@google.edu','elementum'),
  ('mauris.eu@aol.org','eget,');


INSERT INTO ticket_types VALUES
  (DEFAULT,'Normalny',0),
  (DEFAULT,'Ulgowy',0.4),
  (DEFAULT,'Kombatancki',0.99),
  (DEFAULT,'Studencki',0.6);


INSERT INTO seats VALUES
(DEFAULT,1,1,1),
(DEFAULT,1,1,2),
(DEFAULT,1,1,3),
(DEFAULT,1,1,4),
(DEFAULT,1,1,5),
(DEFAULT,1,1,6),
(DEFAULT,1,1,7),
(DEFAULT,1,1,8),
(DEFAULT,1,2,1),
(DEFAULT,1,2,2),
(DEFAULT,1,2,3),
(DEFAULT,1,2,4),
(DEFAULT,1,2,5),
(DEFAULT,1,2,6),
(DEFAULT,1,2,7),
(DEFAULT,1,2,8),
(DEFAULT,1,3,1),
(DEFAULT,1,3,2),
(DEFAULT,1,3,3),
(DEFAULT,1,3,4),
(DEFAULT,1,3,5),
(DEFAULT,1,3,6),
(DEFAULT,1,3,7),
(DEFAULT,1,3,8),
(DEFAULT,1,4,1),
(DEFAULT,1,4,2),
(DEFAULT,1,4,3),
(DEFAULT,1,4,4),
(DEFAULT,1,4,5),
(DEFAULT,1,4,6),
(DEFAULT,1,4,7),
(DEFAULT,1,4,8),
(DEFAULT,1,5,1),
(DEFAULT,1,5,2),
(DEFAULT,1,5,3),
(DEFAULT,1,5,4),
(DEFAULT,1,5,5),
(DEFAULT,1,5,6),
(DEFAULT,1,5,7),
(DEFAULT,1,5,8),
(DEFAULT,1,6,1),
(DEFAULT,1,6,2),
(DEFAULT,1,6,3),
(DEFAULT,1,6,4),
(DEFAULT,1,6,5),
(DEFAULT,1,6,6),
(DEFAULT,1,6,7),
(DEFAULT,1,6,8),
(DEFAULT,1,7,1),
(DEFAULT,1,7,2),
(DEFAULT,1,7,3),
(DEFAULT,1,7,4),
(DEFAULT,1,7,5),
(DEFAULT,1,7,6),
(DEFAULT,1,7,7),
(DEFAULT,1,7,8),
(DEFAULT,1,8,1),
(DEFAULT,1,8,2),
(DEFAULT,1,8,3),
(DEFAULT,1,8,4),
(DEFAULT,1,8,5),
(DEFAULT,1,8,6),
(DEFAULT,1,8,7),
(DEFAULT,1,8,8),
(DEFAULT,1,9,1),
(DEFAULT,1,9,2),
(DEFAULT,1,9,3),
(DEFAULT,1,9,4),
(DEFAULT,1,9,5),
(DEFAULT,1,9,6),
(DEFAULT,1,9,7),
(DEFAULT,1,9,8),
(DEFAULT,1,10,1),
(DEFAULT,1,10,2),
(DEFAULT,1,10,3),
(DEFAULT,1,10,4),
(DEFAULT,1,10,5),
(DEFAULT,1,10,6),
(DEFAULT,1,10,7),
(DEFAULT,1,10,8),
(DEFAULT,2,1,1),
(DEFAULT,2,1,2),
(DEFAULT,2,1,3),
(DEFAULT,2,1,4),
(DEFAULT,2,1,5),
(DEFAULT,2,1,6),
(DEFAULT,2,1,7),
(DEFAULT,2,1,8),
(DEFAULT,2,2,1),
(DEFAULT,2,2,2),
(DEFAULT,2,2,3),
(DEFAULT,2,2,4),
(DEFAULT,2,2,5),
(DEFAULT,2,2,6),
(DEFAULT,2,2,7),
(DEFAULT,2,2,8),
(DEFAULT,2,3,1),
(DEFAULT,2,3,2),
(DEFAULT,2,3,3),
(DEFAULT,2,3,4),
(DEFAULT,2,3,5),
(DEFAULT,2,3,6),
(DEFAULT,2,3,7),
(DEFAULT,2,3,8),
(DEFAULT,2,4,1),
(DEFAULT,2,4,2),
(DEFAULT,2,4,3),
(DEFAULT,2,4,4),
(DEFAULT,2,4,5),
(DEFAULT,2,4,6),
(DEFAULT,2,4,7),
(DEFAULT,2,4,8),
(DEFAULT,2,5,1),
(DEFAULT,2,5,2),
(DEFAULT,2,5,3),
(DEFAULT,2,5,4),
(DEFAULT,2,5,5),
(DEFAULT,2,5,6),
(DEFAULT,2,5,7),
(DEFAULT,2,5,8),
(DEFAULT,2,6,1),
(DEFAULT,2,6,2),
(DEFAULT,2,6,3),
(DEFAULT,2,6,4),
(DEFAULT,2,6,5),
(DEFAULT,2,6,6),
(DEFAULT,2,6,7),
(DEFAULT,2,6,8),
(DEFAULT,2,7,1),
(DEFAULT,2,7,2),
(DEFAULT,2,7,3),
(DEFAULT,2,7,4),
(DEFAULT,2,7,5),
(DEFAULT,2,7,6),
(DEFAULT,2,7,7),
(DEFAULT,2,7,8),
(DEFAULT,2,8,1),
(DEFAULT,2,8,2),
(DEFAULT,2,8,3),
(DEFAULT,2,8,4),
(DEFAULT,2,8,5),
(DEFAULT,2,8,6),
(DEFAULT,2,8,7),
(DEFAULT,2,8,8),
(DEFAULT,2,9,1),
(DEFAULT,2,9,2),
(DEFAULT,2,9,3),
(DEFAULT,2,9,4),
(DEFAULT,2,9,5),
(DEFAULT,2,9,6),
(DEFAULT,2,9,7),
(DEFAULT,2,9,8),
(DEFAULT,2,10,1),
(DEFAULT,2,10,2),
(DEFAULT,2,10,3),
(DEFAULT,2,10,4),
(DEFAULT,2,10,5),
(DEFAULT,2,10,6),
(DEFAULT,2,10,7),
(DEFAULT,2,10,8),
(DEFAULT,3,1,1),
(DEFAULT,3,1,2),
(DEFAULT,3,1,3),
(DEFAULT,3,1,4),
(DEFAULT,3,1,5),
(DEFAULT,3,1,6),
(DEFAULT,3,1,7),
(DEFAULT,3,1,8),
(DEFAULT,3,2,1),
(DEFAULT,3,2,2),
(DEFAULT,3,2,3),
(DEFAULT,3,2,4),
(DEFAULT,3,2,5),
(DEFAULT,3,2,6),
(DEFAULT,3,2,7),
(DEFAULT,3,2,8),
(DEFAULT,3,3,1),
(DEFAULT,3,3,2),
(DEFAULT,3,3,3),
(DEFAULT,3,3,4),
(DEFAULT,3,3,5),
(DEFAULT,3,3,6),
(DEFAULT,3,3,7),
(DEFAULT,3,3,8),
(DEFAULT,3,4,1),
(DEFAULT,3,4,2),
(DEFAULT,3,4,3),
(DEFAULT,3,4,4),
(DEFAULT,3,4,5),
(DEFAULT,3,4,6),
(DEFAULT,3,4,7),
(DEFAULT,3,4,8),
(DEFAULT,3,5,1),
(DEFAULT,3,5,2),
(DEFAULT,3,5,3),
(DEFAULT,3,5,4),
(DEFAULT,3,5,5),
(DEFAULT,3,5,6),
(DEFAULT,3,5,7),
(DEFAULT,3,5,8),
(DEFAULT,3,6,1),
(DEFAULT,3,6,2),
(DEFAULT,3,6,3),
(DEFAULT,3,6,4),
(DEFAULT,3,6,5),
(DEFAULT,3,6,6),
(DEFAULT,3,6,7),
(DEFAULT,3,6,8),
(DEFAULT,3,7,1),
(DEFAULT,3,7,2),
(DEFAULT,3,7,3),
(DEFAULT,3,7,4),
(DEFAULT,3,7,5),
(DEFAULT,3,7,6),
(DEFAULT,3,7,7),
(DEFAULT,3,7,8),
(DEFAULT,3,8,1),
(DEFAULT,3,8,2),
(DEFAULT,3,8,3),
(DEFAULT,3,8,4),
(DEFAULT,3,8,5),
(DEFAULT,3,8,6),
(DEFAULT,3,8,7),
(DEFAULT,3,8,8),
(DEFAULT,3,9,1),
(DEFAULT,3,9,2),
(DEFAULT,3,9,3),
(DEFAULT,3,9,4),
(DEFAULT,3,9,5),
(DEFAULT,3,9,6),
(DEFAULT,3,9,7),
(DEFAULT,3,9,8),
(DEFAULT,3,10,1),
(DEFAULT,3,10,2),
(DEFAULT,3,10,3),
(DEFAULT,3,10,4),
(DEFAULT,3,10,5),
(DEFAULT,3,10,6),
(DEFAULT,3,10,7),
(DEFAULT,3,10,8),
(DEFAULT,4,1,1),
(DEFAULT,4,1,2),
(DEFAULT,4,1,3),
(DEFAULT,4,1,4),
(DEFAULT,4,1,5),
(DEFAULT,4,1,6),
(DEFAULT,4,1,7),
(DEFAULT,4,1,8),
(DEFAULT,4,2,1),
(DEFAULT,4,2,2),
(DEFAULT,4,2,3),
(DEFAULT,4,2,4),
(DEFAULT,4,2,5),
(DEFAULT,4,2,6),
(DEFAULT,4,2,7),
(DEFAULT,4,2,8),
(DEFAULT,4,3,1),
(DEFAULT,4,3,2),
(DEFAULT,4,3,3),
(DEFAULT,4,3,4),
(DEFAULT,4,3,5),
(DEFAULT,4,3,6),
(DEFAULT,4,3,7),
(DEFAULT,4,3,8),
(DEFAULT,4,4,1),
(DEFAULT,4,4,2),
(DEFAULT,4,4,3),
(DEFAULT,4,4,4),
(DEFAULT,4,4,5),
(DEFAULT,4,4,6),
(DEFAULT,4,4,7),
(DEFAULT,4,4,8),
(DEFAULT,4,5,1),
(DEFAULT,4,5,2),
(DEFAULT,4,5,3),
(DEFAULT,4,5,4),
(DEFAULT,4,5,5),
(DEFAULT,4,5,6),
(DEFAULT,4,5,7),
(DEFAULT,4,5,8),
(DEFAULT,4,6,1),
(DEFAULT,4,6,2),
(DEFAULT,4,6,3),
(DEFAULT,4,6,4),
(DEFAULT,4,6,5),
(DEFAULT,4,6,6),
(DEFAULT,4,6,7),
(DEFAULT,4,6,8),
(DEFAULT,4,7,1),
(DEFAULT,4,7,2),
(DEFAULT,4,7,3),
(DEFAULT,4,7,4),
(DEFAULT,4,7,5),
(DEFAULT,4,7,6),
(DEFAULT,4,7,7),
(DEFAULT,4,7,8),
(DEFAULT,4,8,1),
(DEFAULT,4,8,2),
(DEFAULT,4,8,3),
(DEFAULT,4,8,4),
(DEFAULT,4,8,5),
(DEFAULT,4,8,6),
(DEFAULT,4,8,7),
(DEFAULT,4,8,8),
(DEFAULT,4,9,1),
(DEFAULT,4,9,2),
(DEFAULT,4,9,3),
(DEFAULT,4,9,4),
(DEFAULT,4,9,5),
(DEFAULT,4,9,6),
(DEFAULT,4,9,7),
(DEFAULT,4,9,8),
(DEFAULT,4,10,1),
(DEFAULT,4,10,2),
(DEFAULT,4,10,3),
(DEFAULT,4,10,4),
(DEFAULT,4,10,5),
(DEFAULT,4,10,6),
(DEFAULT,4,10,7),
(DEFAULT,4,10,8),
(DEFAULT,5,1,1),
(DEFAULT,5,1,2),
(DEFAULT,5,1,3),
(DEFAULT,5,1,4),
(DEFAULT,5,1,5),
(DEFAULT,5,1,6),
(DEFAULT,5,1,7),
(DEFAULT,5,1,8),
(DEFAULT,5,2,1),
(DEFAULT,5,2,2),
(DEFAULT,5,2,3),
(DEFAULT,5,2,4),
(DEFAULT,5,2,5),
(DEFAULT,5,2,6),
(DEFAULT,5,2,7),
(DEFAULT,5,2,8),
(DEFAULT,5,3,1),
(DEFAULT,5,3,2),
(DEFAULT,5,3,3),
(DEFAULT,5,3,4),
(DEFAULT,5,3,5),
(DEFAULT,5,3,6),
(DEFAULT,5,3,7),
(DEFAULT,5,3,8),
(DEFAULT,5,4,1),
(DEFAULT,5,4,2),
(DEFAULT,5,4,3),
(DEFAULT,5,4,4),
(DEFAULT,5,4,5),
(DEFAULT,5,4,6),
(DEFAULT,5,4,7),
(DEFAULT,5,4,8),
(DEFAULT,5,5,1),
(DEFAULT,5,5,2),
(DEFAULT,5,5,3),
(DEFAULT,5,5,4),
(DEFAULT,5,5,5),
(DEFAULT,5,5,6),
(DEFAULT,5,5,7),
(DEFAULT,5,5,8),
(DEFAULT,5,6,1),
(DEFAULT,5,6,2),
(DEFAULT,5,6,3),
(DEFAULT,5,6,4),
(DEFAULT,5,6,5),
(DEFAULT,5,6,6),
(DEFAULT,5,6,7),
(DEFAULT,5,6,8),
(DEFAULT,5,7,1),
(DEFAULT,5,7,2),
(DEFAULT,5,7,3),
(DEFAULT,5,7,4),
(DEFAULT,5,7,5),
(DEFAULT,5,7,6),
(DEFAULT,5,7,7),
(DEFAULT,5,7,8),
(DEFAULT,5,8,1),
(DEFAULT,5,8,2),
(DEFAULT,5,8,3),
(DEFAULT,5,8,4),
(DEFAULT,5,8,5),
(DEFAULT,5,8,6),
(DEFAULT,5,8,7),
(DEFAULT,5,8,8),
(DEFAULT,5,9,1),
(DEFAULT,5,9,2),
(DEFAULT,5,9,3),
(DEFAULT,5,9,4),
(DEFAULT,5,9,5),
(DEFAULT,5,9,6),
(DEFAULT,5,9,7),
(DEFAULT,5,9,8),
(DEFAULT,5,10,1),
(DEFAULT,5,10,2),
(DEFAULT,5,10,3),
(DEFAULT,5,10,4),
(DEFAULT,5,10,5),
(DEFAULT,5,10,6),
(DEFAULT,5,10,7),
(DEFAULT,5,10,8),
(DEFAULT,6,1,1),
(DEFAULT,6,1,2),
(DEFAULT,6,1,3),
(DEFAULT,6,1,4),
(DEFAULT,6,1,5),
(DEFAULT,6,1,6),
(DEFAULT,6,1,7),
(DEFAULT,6,1,8),
(DEFAULT,6,2,1),
(DEFAULT,6,2,2),
(DEFAULT,6,2,3),
(DEFAULT,6,2,4),
(DEFAULT,6,2,5),
(DEFAULT,6,2,6),
(DEFAULT,6,2,7),
(DEFAULT,6,2,8),
(DEFAULT,6,3,1),
(DEFAULT,6,3,2),
(DEFAULT,6,3,3),
(DEFAULT,6,3,4),
(DEFAULT,6,3,5),
(DEFAULT,6,3,6),
(DEFAULT,6,3,7),
(DEFAULT,6,3,8),
(DEFAULT,6,4,1),
(DEFAULT,6,4,2),
(DEFAULT,6,4,3),
(DEFAULT,6,4,4),
(DEFAULT,6,4,5),
(DEFAULT,6,4,6),
(DEFAULT,6,4,7),
(DEFAULT,6,4,8),
(DEFAULT,6,5,1),
(DEFAULT,6,5,2),
(DEFAULT,6,5,3),
(DEFAULT,6,5,4),
(DEFAULT,6,5,5),
(DEFAULT,6,5,6),
(DEFAULT,6,5,7),
(DEFAULT,6,5,8),
(DEFAULT,6,6,1),
(DEFAULT,6,6,2),
(DEFAULT,6,6,3),
(DEFAULT,6,6,4),
(DEFAULT,6,6,5),
(DEFAULT,6,6,6),
(DEFAULT,6,6,7),
(DEFAULT,6,6,8),
(DEFAULT,6,7,1),
(DEFAULT,6,7,2),
(DEFAULT,6,7,3),
(DEFAULT,6,7,4),
(DEFAULT,6,7,5),
(DEFAULT,6,7,6),
(DEFAULT,6,7,7),
(DEFAULT,6,7,8),
(DEFAULT,6,8,1),
(DEFAULT,6,8,2),
(DEFAULT,6,8,3),
(DEFAULT,6,8,4),
(DEFAULT,6,8,5),
(DEFAULT,6,8,6),
(DEFAULT,6,8,7),
(DEFAULT,6,8,8),
(DEFAULT,6,9,1),
(DEFAULT,6,9,2),
(DEFAULT,6,9,3),
(DEFAULT,6,9,4),
(DEFAULT,6,9,5),
(DEFAULT,6,9,6),
(DEFAULT,6,9,7),
(DEFAULT,6,9,8),
(DEFAULT,6,10,1),
(DEFAULT,6,10,2),
(DEFAULT,6,10,3),
(DEFAULT,6,10,4),
(DEFAULT,6,10,5),
(DEFAULT,6,10,6),
(DEFAULT,6,10,7),
(DEFAULT,6,10,8);
