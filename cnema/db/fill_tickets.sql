create or replace function insert_gibberish_screenings()
returns void
as
$$
declare
    mc := (SELECT count(*) FROM movies);
    rc := (SELECT count(*) FROM rooms);
begin
    for i in 1..10000
    loop
        ll := 
        select add_to_schedule(data, godzina, (floor(random()*mc) + 1), al, ll, sl, floor(), floor(random() * 40))
    end loop;
end;
$$
language plpgsql;

create or replace function insert_gibberish_tickets()
returns void
as
$$
declare
	i integer;
	j integer;
	kk integer;
    lol integer;
begin
	for kk in 1..10
	loop
		for i in 3..6
		loop
		    for j in 1..5
			loop
                lol := floor(random() * 80) + 1;
				begin
					raise notice '%s', buy_ticket(i, lol, 1, null, kk);
				exception when others then
				end;
			end loop;
		end loop;
	end loop;
end;
$$
language plpgsql;

select insert_gibberish_tickets();

drop function insert_gibberish_tickets;
