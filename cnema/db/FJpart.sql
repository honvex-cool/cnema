---- TRIGGERS ----
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
			RETURN NULL;
		END IF;

		FOR temp IN SELECT
				s.screening_date + a_s.screening_hour AS "begin_time",
				s.screening_date + a_s.screening_hour + interval '15 minutes' + (SELECT abstract_screening_length(a_s.abstract_screening_id))::time AS "end_time"
			FROM
				screenings s JOIN abstract_screenings a_s ON s.abstract_screening = a_s.abstract_screening_id
			WHERE s.screening_date >= NOW() :: date AND a_s.room = (SELECT room FROM abstract_screenings WHERE abstract_screening_id=NEW.abstract_screening)
		LOOP
			IF (new_begin_time,new_end_time) OVERLAPS (temp."begin_time",temp."end_time") THEN
				RETURN NULL;
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


---- FUNCTIONS ----

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
------------

---- VIEWS ----

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
CREATE OR REPLACE VIEW regionalizations_langague_names AS
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

CREATE OR REPLACE RULE regionalizations_langague_names_no_delete AS ON DELETE TO regionalizations_langague_names DO INSTEAD NOTHING;
CREATE OR REPLACE RULE regionalizations_langague_names_no_insert AS ON INSERT TO regionalizations_langague_names DO INSTEAD NOTHING;
CREATE OR REPLACE RULE regionalizations_langague_names_no_update AS ON UPDATE TO regionalizations_langague_names DO INSTEAD NOTHING;
------




































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
	JOIN regionalizations_langague_names rln ON fs.regionalization = rln.regionalization_id
WHERE fs.screening_date >= NOW()::date
ORDER BY fs.screening_date,fs.screening_hour,fs.screening_id;



CREATE OR REPLACE FUNCTION schedule_insert() 
RETURNS TRIGGER AS $schedule_insert$
DECLARE
mv_id integer := (SELECT movie_id FROM movies WHERE title=NEW.title);
rg_id integer := (SELECT regionalization_id 
					FROM regionalizations_langague_names 
					WHERE COALESCE(audio,'##')=COALESCE(NEW.audio,'##') AND COALESCE(lector,'##')=COALESCE(NEW.lector,'##') AND COALESCE(subtitles,'##')=COALESCE(NEW.subtitles,'##'));
rm_id integer := (SELECT room_id FROM rooms WHERE room_name = NEW.room_name);
mr_id integer;
as_id integer;
BEGIN
	IF mv_id IS NULL OR rg_id IS NULL OR rm_id IS NULL THEN 
		RETURN NULL;
	END IF;

	SELECT movie_realization_id INTO mr_id
				FROM movie_realizations 
				WHERE movie=mv_id AND regionalization=rg_id;
	IF mr_id IS NULL THEN
		INSERT INTO movie_realizations 
			VALUES (DEFAULT,mv_id,rg_id) RETURNING movie_realization_id INTO mr_id;
	END IF;

	SELECT abstract_screening_id INTO as_id
				FROM (SELECT
							a_s.abstract_screening_id,
							COUNT(a_s.abstract_screening_id) AS "count"
						FROM
							abstract_screenings a_s
							JOIN movies_screenings ms ON a_s.abstract_screening_id = ms.abstract_screening
						WHERE a_s.screening_hour = NEW.screening_hour
							AND a_s.room = rm_id
							AND a_s.base_ticket_price = NEW.base_ticket_price
						GROUP BY a_s.abstract_screening_id) AS "s"
				WHERE "s"."count"=1 AND (SELECT movie_realization 
										FROM movies_screenings 
										WHERE abstract_screening=abstract_screening_id)=mr_id;
	IF as_id IS NULL THEN
		INSERT INTO abstract_screenings
			VALUES(DEFAULT,NEW.screening_hour,rm_id,NEW.base_ticket_price)
			RETURNING abstract_screening_id INTO as_id;
		INSERT INTO movies_screenings VALUES(as_id,mr_id);
	END IF;

	INSERT INTO screenings VALUES(DEFAULT,NEW.screening_date,as_id);
	RETURN NEW;
END;
$schedule_insert$
LANGUAGE plpgsql;
CREATE TRIGGER schedule_insert INSTEAD OF INSERT ON schedule
FOR EACH ROW EXECUTE PROCEDURE schedule_insert();






























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



-- Full schedule --
CREATE OR REPLACE VIEW full_schedule AS
SELECT
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
