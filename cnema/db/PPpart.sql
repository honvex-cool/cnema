-------------
--INSERT TICKET WHEN SCREENING ALREADY STARTED/ENDED
CREATE OR REPLACE FUNCTION cant_buy_ticket() RETURNS TRIGGER AS $$
BEGIN
	IF	get_start(NEW.screening) IS NULL
                OR (NEW.reservation IS NOT NULL AND NEW.reservation NOT IN (SELECT reservation_id FROM reservations))
                OR (NEW.reservation IS NULL)
                OR get_start(NEW.screening)<=NOW()
                OR NEW.seat IN ( SELECT s.seat_id FROM occupied_seats(NEW.seat) s )
                OR NEW.ticket_type NOT IN (SELECT ticket_type_id FROM ticket_types)
	THEN
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cant_buy_ticket BEFORE INSERT ON tickets
FOR EACH ROW EXECUTE PROCEDURE cant_buy_ticket();

-------------
--BUY TICKET FUNCTION
CREATE OR REPLACE FUNCTION buy_ticket(scr_id int, seat_id int, type int, res_id int, c_id int) RETURNS boolean AS $$
BEGIN
	IF	get_start(scr_id) IS NULL
		OR (res_id IS NOT NULL AND res_id NOT IN (SELECT reservation_id FROM reservations))
		OR (res_id IS NULL AND (c_id IS NULL OR c_id NOT IN (SELECT customer_id FROM customers)))
		OR get_start(scr_id)<=NOW()
		OR seat_id IN ( SELECT s.seat_id FROM occupied_seats(scr_id) s )
		OR type NOT IN (SELECT ticket_type_id FROM ticket_types)
	THEN
		RETURN false;
	END IF;
	IF	res_id IS NULL
	THEN
		INSERT INTO reservations VALUES(DEFAULT, c_id, NOW()) RETURNING reservation_id INTO res_id;
	END IF;
	INSERT INTO tickets VALUES(DEFAULT, scr_id, seat_id, type, res_id, NULL);
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
	NEW.cancellation_date=OLD.cancellation_date;
	RETURN NEW;
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
