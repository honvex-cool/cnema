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

CREATE OR REPLACE VIEW movie_info
AS
SELECT
    movies.movie_id,
    movies.title,
    string_agg(DISTINCT genres.short_name, ', ')
    duration,
    age_rating,
    international_release AS release_date,
    string_agg(DISTINCT language_name, ', ') AS original_language,
    string_agg(DISTINCT format_person(directors), ', ') AS directed_by,
    string_agg(DISTINCT format_person(screenwriters), ', ') AS screenplay_by,
    string_agg(DISTINCT format_actor(actors, portraying), ', ') AS starring,
    string_agg(DISTINCT format_person(composers), ', ') AS music_by,
    string_agg(DISTINCT company_name, ', ') AS produced_by,
    string_agg(DISTINCT short_format_review(reviews), '; ') AS reviewed_as
FROM
    movies
        LEFT JOIN languages ON languages.language_id = movies.original_language
        LEFT JOIN movies_genres ON movies_genres.movie_id = movies.movie_id
        LEFT JOIN genres ON genres.genre_id = movies_genres.genre_id
        LEFT JOIN movies_directors ON movies_directors.movie_id = movies.movie_id
        LEFT JOIN people directors ON directors.person_id = movies_directors.director_id
        LEFT JOIN movies_screenwriters ON movies_screenwriters.movie_id = movies.movie_id
        LEFT JOIN people screenwriters ON screenwriters.person_id = movies_screenwriters.screenwriter_id
        LEFT JOIN movies_actors ON movies_actors.movie_id = movies.movie_id
        LEFT JOIN people actors ON actors.person_id = movies_actors.actor_id
        LEFT JOIN movies_composers ON movies_composers.movie_id = movies.movie_id
        LEFT JOIN people composers ON composers.person_id = movies_composers.composer_id
        LEFT JOIN movies_producers ON movies_producers.movie_id = movies.movie_id
        LEFT JOIN producers ON producers.producer_id = movies_producers.producer_id
        LEFT JOIN movies_reviews ON movies_reviews.movie_id = movies.movie_id
        LEFT JOIN reviews ON reviews.review_id = movies_reviews.review_id
GROUP BY movies.movie_id;
