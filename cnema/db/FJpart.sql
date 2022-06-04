---- TRIGGERS ----
-- Screenings delete check --
CREATE OR REPLACE FUNCTION abstract_screening_length(a_s_id integer) RETURNS timestamp AS
$$
BEGIN
	RETURN COALESCE((SELECT sum(duration) 
				FROM movies_screenings ms
					JOIN movie_realization mr ON ms.movie_realization = mr.movie_realization_id
					JOIN movies m ON mr.movie = movie_id 
				WHERE ms.abstract_screening=a_s_id)::timestamp,timestamp '0 second');
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
															WHERE abstract_screening_id=NEW.abstract_screening)::timestamp;
new_end_time timestamp := new_begin_time + '15 minutes' + (SELECT abstract_screening_length(NEW.abstract_screening));
temp record;
BEGIN
		IF new_begin_time <= NOW() THEN
			RETURN NULL;
		END IF;

		FOR temp IN SELECT
				s.screening_date::timestamp + a_s.screening_hour::interval AS "begin_time",
				s.screening_date::timestamp + a_s.screening_hour::interval + interval '15 minutes' + (SELECT abstract_screening_length(a_s.abstract_screening_id))
			FROM
				screenings s JOIN abstract_screenings a_s ON s.abstract_screening = a_s.abstract_screening_id
			WHERE s.screening_date >= TODAY() AND a_s.room = (SELECT room FROM abstract_screenings WHERE abstract_screening_id=NEW.abstract_screening)
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
ORDER BY s.screening_date,a_s.screening_hour,m.title;


CREATE OR REPLACE RULE full_schedule_no_delete AS ON DELETE TO full_schedule DO INSTEAD NOTHING;
CREATE OR REPLACE RULE full_schedule_no_insert AS ON INSERT TO full_schedule DO INSTEAD NOTHING;
CREATE OR REPLACE RULE full_schedule_no_update AS ON UPDATE TO full_schedule DO INSTEAD NOTHING;
------
------------
----------------------------