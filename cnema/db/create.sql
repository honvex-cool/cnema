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
    company_name character varying(100) UNIQUE NOT NULL,
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
    base_ticket_price numeric NOT NULL CHECK(base_ticket_price>=0),
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
        SELECT string_agg(genres.short_name, ', ')
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


CREATE OR REPLACE FUNCTION screenings_delete_check()
RETURNS TRIGGER AS $screenings_delete_check$
BEGIN
	IF 
		(SELECT COALESCE(COUNT(ticket_id),0)
		FROM tickets 
		WHERE screening=OLD.screening_id) > 0
	THEN
		RETURN OLD;
	END IF;
	RETURN NULL;
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
RETURNS numeric
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
                WHERE t.reservation = reservation_id
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
    fs.screening_date,
    fs.screening_hour,
	m.title,
	rln."audio",
	rln."lector",
	rln."subtitles",
	r.room_name,
    fs.base_ticket_price
FROM
	full_screenings fs
	JOIN rooms r ON fs.room=r.room_id
	JOIN movies m ON fs.movie=m.movie_id
	JOIN regionalizations_language_names rln ON fs.regionalization = rln.regionalization_id
WHERE fs.screening_date >= NOW()::date
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
                                            base_ticket_price_ numeric)
RETURNS VOID AS
$$
DECLARE
rg_id integer;
mr_id integer;
as_id integer;
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

	INSERT INTO screenings VALUES(DEFAULT,screening_date_,as_id);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION schedule_insert() 
RETURNS TRIGGER AS $schedule_insert$
DECLARE
mv_id integer := (SELECT movie_id FROM movies WHERE title=NEW.title);
rm_id integer := (SELECT room_id FROM rooms WHERE room_name = NEW.room_name);
BEGIN
    SELECT add_to_schedule(NEW.screening_date,NEW.screening_hour,mv_id,NEW.audio,NEW.lector,NEW.subtitles,rm_id,NEW.base_ticket_price);
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

-------------
--INSERT TICKET WHEN SCREENING ALREADY STARTED/ENDED
CREATE OR REPLACE FUNCTION cant_buy_ticket() RETURNS TRIGGER AS $$
BEGIN
	IF	get_start(NEW.screening) IS NULL
                OR (NEW.reservation IS NOT NULL AND NEW.reservation NOT IN (SELECT reservation_id FROM reservations))
                OR (NEW.reservation IS NULL)
                OR get_start(NEW.screening)<=NOW()
		OR get_roomid(NEW.screening)=(SELECT room FROM seats s WHERE NEW.seat=s.seat_id)
                OR NEW.seat IN ( SELECT os.seat_id FROM occupied_seats(NEW.seat) os )
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
CREATE OR REPLACE FUNCTION buy_ticket(scr_id int, s_id int, type int, res_id int, c_id int) RETURNS boolean AS $$
BEGIN
	IF	get_start(scr_id) IS NULL
		OR (res_id IS NOT NULL AND res_id NOT IN (SELECT reservation_id FROM reservations))
		OR (res_id IS NULL AND (c_id IS NULL OR c_id NOT IN (SELECT customer_id FROM customers)))
		OR get_start(scr_id)<=NOW()
		OR get_roomid(scr_id)=(SELECT room FROM seats s WHERE s_id=s.seat_id)
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
	RETURN true;
END;
$$ LANGUAGE plpgsql;
---------------------
--ALL BOUGHT TICKETS FROM USER
CREATE OR REPLACE FUNCTION user_history(id INTEGER) RETURNS TABLE(
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
		a.title AS "title", a.screening_hour AS "hour", a.screening_date AS "date", a.room_name AS "room", a.row_no AS "row", a.seat_no AS "seat",
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
	t.cancellation_date
FROM
	tickets t
	JOIN seats s ON t.seat=s.seat_id
	JOIN rooms sr ON sr.room_id=s.room
	JOIN reservations r ON t.reservation=r.reservation_id
	JOIN customers c ON c.customer_id=r.customer
	JOIN full_schedule fs ON fs.screening_id=t.screening
ORDER BY screening_date DESC, screening_hour DESC;

CREATE OR REPLACE RULE all_tickets_no_delete AS ON DELETE TO all_tickets DO INSTEAD NOTHING;
CREATE OR REPLACE RULE all_tickets_no_insert AS ON INSERT TO all_tickets DO INSTEAD NOTHING;
CREATE OR REPLACE RULE all_tickets_no_update AS ON UPDATE TO all_tickets DO INSTEAD NOTHING;
---------------------
