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


----------------------------

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
ORDER BY "BoughtTickets" ASC;

CREATE OR REPLACE RULE regular_customers_no_delete AS ON DELETE TO regular_customers DO INSTEAD NOTHING;
CREATE OR REPLACE RULE regular_customers_no_insert AS ON INSERT TO regular_customers DO INSTEAD NOTHING;
CREATE OR REPLACE RULE regular_customers_no_update AS ON UPDATE TO regular_customers DO INSTEAD NOTHING;

----------------------------


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
