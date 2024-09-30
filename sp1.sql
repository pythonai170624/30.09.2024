
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
