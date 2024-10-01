
drop function hello_world();

CREATE or replace function hello_world()
returns varchar
language plpgsql AS
    $$
        BEGIN
            return CONCAT('hello', 'world', ' ! ', current_timestamp);
        end;
    $$;

select CONCAT('hello', 'world', ' ! ', current_timestamp) as greeting;

select hello_world();
select * from hello_world();
select hello_world from hello_world();
select hello_world as result from hello_world();

CREATE or replace function sp_sum(m double precision, n double precision)
returns double precision
language plpgsql AS
    $$
        DECLARE
            -- x: int = 0
            x integer := 0;
        BEGIN
            return m + n + x;
        end;
    $$;

select sp_sum(2.2, 3.5);


drop function sp_product;
CREATE or replace function sp_product(x double precision, y double precision,
    OUT prod double precision,
    OUT div_res double precision)
language plpgsql AS
    $$
        DECLARE
            -- z: float = 1.0
            z double precision := 1.0;
        BEGIN
            prod = x * y * z;
            div_res = x / y;
        end;
    $$;
select * from sp_product(8, 2);


create table countries
(
    id   bigserial not null constraint countries_pk primary key,
    name text      not null
);
create table movies
(
    id           bigserial                  not null
        constraint movies_pk
            primary key,
    title        text,
    release_date timestamp                  not null,
    price        double precision default 0 not null,
    country_id   bigint
        constraint movies_countries_id_fk
            references countries
);
update movies
    set price = NULL -- will be blocked because not null
where movies.id = 2;

insert into countries(name) values ('Israel'); -- 1
insert into countries(name) values ('USA'); -- 2
insert into countries(name) values ('JAPAN'); -- 3
insert into countries(name) values ('CANADA'); -- 4
insert into movies (title, release_date, price, country_id)
values ('batman returns', '2020-12-16 20:21:00', 45.5, 3);
insert into movies (title, release_date, price, country_id)
values ('wonder woman', '2018-07-11 08:12:11', 125.5, 3);
insert into movies (title, release_date, price, country_id)
values ('matrix resurrection', '2021-01-03 09:10:11', 38.7, 4);

select min(price), max(price), avg(price)::numeric(5,2)
from movies;

CREATE or replace function sp_movies_stat(
    OUT min_price double precision,
    OUT max_price double precision,
    OUT avg_price double precision)
language plpgsql AS
    $$
        BEGIN
            select min(price), max(price), avg(price)::numeric(5,2)
            into min_price, max_price, avg_price
            from movies;
        end;
    $$;
select * from sp_movies_stat();

drop function sp_most_expensive_movie_name;
CREATE or replace function sp_most_expensive_movie_name(OUT movie_name text, OUT movie_price double precision)
language plpgsql AS
    $$
        BEGIN
            SELECT title, price
            into movie_name, movie_price
            from movies
            where price = (select max(price) from movies);
        end;
    $$;

select * from sp_most_expensive_movie_name();


---------- TARGIl 1
drop function sp_movies_expensive_name;
CREATE or replace function sp_movies_expensive_name(out most_expensive_movie_name text)
language plpgsql AS
    $$
        DECLARE
            max_price double precision := 0;
        BEGIN
            -- select into max_price the most expensive movie
            select max(price)
            into max_price
            from movies;

            -- select into most_expensive_movie_name the title of the movie
            --      with this price
            select title from movies
            where price = max_price
            into most_expensive_movie_name;
        end;
    $$;

select * from sp_movies_expensive_name();

--------- TARGIl 2
-- create sp_num_of_movies return the number of movies + number of countries
drop function sp_count_movies_and_countries;
CREATE or replace function sp_count_movies_and_countries(out count_movies_and_countries bigint)
language plpgsql AS
    $$
        DECLARE
            count_movies bigint := 0;
            count_countries bigint := 0;
        BEGIN
            -- select into count_movies
            select count(*) into count_movies
            from movies;

            -- select into count_countries
            select count(*) into count_countries
            from countries;

            -- return sum of both
            count_movies_and_countries = count_movies + count_countries;
        END;
    $$;
select * from sp_count_movies_and_countries();

drop function sp_insert_movie;
-- each parameter starts with _ (i.e. _title) to avoid ambiguity with the table columns
CREATE or replace function sp_insert_movie(_title text, _release_date timestamp,
    _price double precision, _country_id bigint)
    returns bigint
language plpgsql AS
    $$
        DECLARE
            new_id bigint := 0;
        BEGIN
            INSERT INTO movies(title, release_date, price, country_id)
            values (_title, _release_date, _price, _country_id)
            returning id into new_id;

            return new_id; -- returning the id of the newly created record
        end;
    $$;

-- INSERT INTO users (name, age) VALUES ('John', 30) RETURNING id, name;
-- UPDATE users SET age = 31 WHERE name = 'John' RETURNING id, name, age;
-- DELETE FROM users WHERE name = 'John' RETURNING id, name;
-- If several rows are deleted, PostgreSQL will return a result set

select * from sp_insert_movie('Queen gambit', cast('2020-08-12' as timestamp)
    , 87.1, 3);
select * from sp_insert_movie('Eternals', cast('2020-05-21' as timestamp)
    , 101.3, 1);

drop function sp_update_movie;
-- procedure does not return a value
CREATE or replace procedure sp_update_movie(_title text, _release_date timestamp,
    _price double precision, _country_id bigint, _update_id bigint)
language plpgsql AS
    $$
        BEGIN
            UPDATE movies
            set title = _title, release_date = _release_date,
                price = _price, country_id = _country_id
            where id = _update_id;
            -- should return id of the updated row
        end;
    $$;

call sp_update_movie('Queen gambit 2', cast('2020-08-12' as timestamp)
    , 87.1, 3, 5);

drop function sp_get_movies_in_range;
CREATE or replace function sp_get_movies_in_range(_min double precision, _max double precision)
returns TABLE(id bigint, title text, release_date timestamp,
              price double precision, country_id bigint, country_name text)
-- RETURNS SETOF students
language plpgsql AS
    $$
        BEGIN
            return QUERY
            select m.id, m.title, m.release_date, m.price, m.country_id, c.name from movies m
            join countries c on m.country_id = c.id
            where m.price between _min and _max;
        end;
    $$;

select * from sp_get_movies_in_range(100, 150) order by release_date;

-- return movies not the cheapest and not the most expansive
drop function sp_get_movies_mid;
CREATE or replace function sp_get_movies_mid()
returns TABLE(id bigint, title text, release_date timestamp,
    price double precision, country_id bigint, country_name text)
language plpgsql AS
    $$
        BEGIN
            return QUERY
            WITH cheapest_movie AS
                (
                    select * from movies
                    where movies.price = (select min(movies.price)from movies)
                ),
            expensive_movie AS
                (
                    select * from movies
                    where movies.price = (select max(movies.price)from movies)
                )
            select m.id, m.title, m.release_date, m.price, m.country_id, c.name from movies m
            join countries c on m.country_id = c.id
            where m.id not in (select cheapest_movie.id from cheapest_movie)
              and m.id not in (select expensive_movie.id from expensive_movie);
        end;
    $$;

select * from sp_get_movies_mid() order by release_date;

drop function sp_get_max;
CREATE or replace function sp_get_max(_x integer, _y integer)
returns integer
language plpgsql AS
    $$
        BEGIN
            if _x > _y then
                return _x;
            -- ELSEIF
            else
                return _y;
            end if;
        end;
    $$;

select * from sp_get_max(3, 2);

drop function sp_get_max3;
CREATE or replace function sp_get_max3(_x integer, _y integer, _z integer)
returns integer
language plpgsql AS
    $$
        BEGIN
            if _x >_y and _x > _z then
                return _x;
            elseif _y > _z then
                return _y;
            else
                return _z;
            end if;
        end;
    $$;

select * from sp_get_max3(3, 2, -1);

drop function sp_get_movies_country_id;
CREATE or replace function sp_get_movies_country_id(_id_type text)
returns TABLE(id bigint, title text)
language plpgsql AS
    $$
        BEGIN
            return QUERY
            select case when _id_type = 'M' then m.id
                                  else m.country_id end, m.title
            from movies m;
        end;
    $$;

select * from sp_get_movies_country_id('M');

drop function sp_get_movies_price_or_pow2;
CREATE or replace function sp_get_movies_price_or_pow2(_pow boolean)
returns TABLE(id bigint, title text, price double precision)
language plpgsql AS
    $$
        BEGIN
            return QUERY
            select m.id, m.title, case when _pow then pow(m.price, 2)
                                  else m.price end
            from movies m;
        end;
    $$;

select * from sp_get_movies_price_or_pow2(true);
select * from sp_get_movies_price_or_pow2(false);

drop function sp_get_random;
CREATE or replace function sp_get_random(_max integer)
returns integer
language plpgsql AS
    $$
        BEGIN
            return random() * (_max - 1) + 1;
        end;
    $$;

select * from sp_get_random(10);
select * from random(); -- 0 .. 0.999999


drop function sp_get_sum_loop;
CREATE or replace function sp_get_sum_loop()
returns double precision
language plpgsql AS
    $$
        declare
            sum double precision := 0.0;
        BEGIN
            for i in 1..(select max(movies.id) from movies)
                loop
                    if (select count(*) from movies m where m.id = i) > 0 then
                        sum := sum + (select m.price from movies m where m.id = i);
                    end if;
                end loop;
            return sum;
        end;
    $$;

select * from sp_get_sum_loop();

drop function sp_div;
create or replace function sp_div(x integer, y integer) returns double precision
language plpgsql as
    $$
        begin
            if y = 0 then
                raise division_by_zero;
            end if;
            return x::double precision / y::double precision ;
        end;
    $$;
select * from sp_div(2, 4);
select * from sp_div(2, 0);

-- DO $$
-- BEGIN
--     -- Try block: Attempt to insert a record
--     INSERT INTO users (name, age) VALUES ('John', 25);
-- EXCEPTION
--     WHEN unique_violation THEN
--         -- Catch block: Handle unique key violations (e.g., duplicate entries)
--         RAISE NOTICE 'User already exists!';
--     WHEN others THEN
--         -- Catch all other exceptions
--         RAISE NOTICE 'An unexpected error occurred!';
-- END;
-- $$;

-- upsert
drop function sp_upsert_movie;
CREATE or replace function sp_upsert_movie(_title text, _release_date timestamp,
    _price double precision, _country_id bigint)
    returns bigint
language plpgsql AS
    $$
        DECLARE
            record_id bigint := 0;
        BEGIN
            SELECT movies.id
                into record_id from movies
                    where movies.title = _title;
            if not found then
                INSERT INTO movies(title, release_date, price, country_id)
                values (_title, _release_date, _price, _country_id)
                returning id into record_id;
            else
                update movies
                    set release_date = _release_date, price = _price, country_id = _country_id
                    where movies.id = record_id;
            end if;
            return record_id; -- returning the id of the newly created record
        end;
    $$;

select * from movies order by id;
select * from sp_upsert_movie('batman returns', '2020-12-17 20:21:00.000000', 148, 3);
select * from sp_upsert_movie('spiderman home', '2022-01-02 07:10:03.000000', 98.03, 1);

-- INSERT INTO table_name (column1, column2, ...)
-- VALUES (value1, value2, ...)
-- ON CONFLICT (constraint_column)
-- DO UPDATE SET column1 = value, column2 = value
-- WHERE condition;

-- LATER: over partitioning --
