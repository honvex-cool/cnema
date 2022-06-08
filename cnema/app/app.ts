import dotenv from 'dotenv'
import express from 'express'
import pg from 'pg'
import expressLayouts from 'express-ejs-layouts'

dotenv.config()

const app = express()
const port = process.env.PORT

const db = new pg.Client('postgres://cnemaadmin:bazunia@localhost:5432/cnema')

let user_id: any;
let res_id: any;

db.connect()

app.use(express.static('public'))
app.use(express.urlencoded({ extended: true }))
app.use(express.json())

app.set('view engine', 'ejs')
app.set('layout', './layouts/layout')
app.use(expressLayouts)

app.get(
    '/',
    (_request, response) => response.redirect('/index')
)

app.get(
    '/logout',
    (_request, response) => {
        user_id = undefined
        res_id = undefined
        response.redirect('/index')
    }
)

app.get(
    '/index',
    (_request, response) => {
        if(user_id) {
            if(user_id == -1)
                response.render('admin-view')
            else
                response.render('user-view')
        }
        else
            response.redirect('/login')
    }
)

app.get(
    '/add-screening',
    async (_request, response) => {
        const schedule = await db.query('SELECT * FROM schedule ORDER BY screening_date, screening_hour;')
        const movies = await db.query('SELECT movie_id, title FROM movies;')
        const languages = await db.query('SELECT * FROM languages;')
        const rooms = await db.query('SELECT * FROM rooms;')
        return response.render(
            'add-screening',
            {
                schedule: schedule.rows,
                movies: movies.rows,
                languages: languages.rows,
                rooms: rooms.rows,
            }
        )
    }
)

app.post(
    '/add-screening-result',
    (request, response) => {
        const form = request.body
        const q =
            `
            INSERT INTO schedule
            VALUES
            (
                DEFAULT,
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7,
                $8
            );
            `
        if(form.screening_audio == '')
            form.screening_audio = null
        if(form.screening_lector == '')
            form.screening_lector = null
        if(form.screening_subtitles == '')
            form.screening_subtitles = null
        console.log(q)
        const d = [
                form.screening_date,
                form.screening_time,
                form.screening_movie,
                form.screening_audio,
                form.screening_lector,
                form.screening_subtitles,
                form.screening_room,
                form.screening_ticket_price
            ]
        console.log(d)
        db.query(
            q,
            d,
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                else
                    console.log('No error')
                response.redirect('/add-screening')
            }
        )
    }
)

app.get(
    '/add-room',
    (_request, response) => {
        db.query(
            'SELECT room_name FROM rooms;',
            (_error, result) => {
                response.render('add-room', { rooms: result.rows })
            }
        )
    }
)

app.get(
    '/add-language',
    async (_request, response) => {
        const languages = await db.query('SELECT * FROM languages;')
        return response.render(
            'add-language',
            {
                languages: languages.rows
            }
        )
    }
)

app.post(
    '/add-language-result',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO languages VALUES (DEFAULT, $1);`,
            [form.language_name],
            (error, _result) => {
                if(error)
                    console.log("ERROR: " + error.message)
                response.redirect('/add-language')
            }
        )
    }
)

app.get(
    '/login',
    (_request, response) => {
        return response.render('login-screen')
    }
)

app.post(
    '/ensure-user',
    (request, response) => {
        const form = request.body
        if(form.username == 'admin' && form.mail == 'admin') {
            user_id = -1
            return response.redirect('/index')
        }
        const q = `
            SELECT get_or_make_user_id($1, $2) AS user_id;
            `
        console.log(q)
        db.query(
            q,
            [form.username, form.mail],
            (error, result) => {
                if(error) {
                    console.log('You stuped: ' + error.message)
                    response.redirect('/login')
                } else {
                    user_id = result.rows[0].user_id
                    response.redirect('/index')
                }
            }
        )
    }
)

app.get(
    '/browse-movies-admin',
    async (_request, response) => {
        const movies = await db.query('SELECT * FROM movie_info ORDER BY movie_id DESC;')
        const languages = await db.query('SELECT * FROM languages;')
        const people = await db.query('SELECT * FROM people ORDER BY last_name ASC;')
        const producers = await db.query('SELECT * FROM producers ORDER BY company_name ASC;')
        return response.render(
            'browse-movies-admin',
            {
                movies: movies.rows,
                languages: languages.rows,
                people: people.rows,
                producers: producers.rows,
            }
        )
    }
)

app.get(
    '/alter-movie',
    async (request, response) => {
        const movies = await db.query(`SELECT * FROM movie_info WHERE movie_id=$1;`, [request.query.movie_id])
        const languages = await db.query('SELECT * FROM languages;')
        const people = await db.query('SELECT * FROM people_info;')
        const producers = await db.query('SELECT * FROM producers ORDER BY company_name ASC;')
        const genres = await db.query('SELECT * FROM genres;')
        const producers_in_movie = await db.query(`SELECT * FROM movies_producers JOIN producers USING(producer_id) WHERE movie_id=$1 ORDER BY company_name ASC;`, [request.query.movie_id])
        const screenwriters_in_movie = await db.query(`SELECT * FROM movies_screenwriters JOIN people_info ON screenwriter_id=person_id WHERE movie_id=$1;`, [request.query.movie_id])
        const composers_in_movie = await db.query(`SELECT * FROM movies_composers JOIN people_info ON composer_id=person_id WHERE movie_id=$1;`, [request.query.movie_id])
        const directors_in_movie = await db.query(`SELECT * FROM movies_directors JOIN people_info ON director_id=person_id WHERE movie_id=$1;`, [request.query.movie_id])
        const actors_in_movie = await db.query(`SELECT * FROM movies_actors JOIN people_info ON actor_id=person_id WHERE movie_id=$1;`, [request.query.movie_id])
        const genres_in_movie = await db.query(`SELECT * FROM movies_genres JOIN genres USING(genre_id) WHERE movie_id=$1 ORDER BY genre_name ASC;`, [request.query.movie_id])
        const reviews = await db.query('SELECT * FROM reviews;')
        const reviews_for_movie = await db.query(`SELECT * FROM movies_reviews JOIN reviews ON reviews.review_id=movies_reviews.review_id WHERE movie_id=$1 ORDER BY title ASC;`, [request.query.movie_id])
        return response.render(
            'alter-movie',
            {
                movie: movies.rows[0],
                languages: languages.rows,
                people: people.rows,
                producers: producers.rows,
                genres: genres.rows,
                producers_in_movie: producers_in_movie.rows,
                screenwriters_in_movie: screenwriters_in_movie.rows,
                composers_in_movie: composers_in_movie.rows,
                directors_in_movie: directors_in_movie.rows,
                actors_in_movie: actors_in_movie.rows,
                genres_in_movie: genres_in_movie.rows,
                reviews: reviews.rows,
                reviews_for_movie: reviews_for_movie.rows,
            }
        )
    }
)

app.post(
    '/update-movie-title',
    (request, response) => {
        db.query(
            'UPDATE movies SET title = $2 WHERE movie_id = $1;',
            [request.query.movie_id, request.body.new_title],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/update-movie-language',
    (request, response) => {
        db.query(
            'UPDATE movies SET original_language = $1 WHERE movie_id = $2',
            [request.body.language == '' ? null : request.body.language, request.query.movie_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/add-movie-action',
    (request, response) => {
        const form = request.body
        if(form.release_date == '')
            form.release_date = 'NULL'
        else
            form.release_date = `${form.release_date}`
        const tm = `${form.hours}:${form.minutes}`
        const q = `INSERT INTO movies VALUES (
                    DEFAULT,
                    $1,
                    $2,
                    $3,
                    $4,
                    $5
                );`
        console.log(q)
        db.query(
            q,
            [form.title, tm, form.age_rating, form.release_date, form.original_language],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/browse-movies-admin')
            }
        )
    }
)

app.post(
    '/add-movie-actor-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO movies_actors VALUES (
                    $1,
                    $2,
                    $3
                );`,
            [request.query.movie_id, form.actor_id, form.portraying],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/delete-movie-actor-action',
    (request, response) => {
        const form = request.body
        let id: number = form.actor.split(' ')[0]
        let prt: string = form.actor.split(' ')[1]
        prt = prt.substring(1, prt.length - 1)
        db.query(
            `DELETE FROM movies_actors WHERE
                    movie_id=$1 AND
                    actor_id=$2 AND
                    portraying = $3
                ;`,
            [request.query.movie_id, id, prt],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/add-movie-director-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO movies_directors VALUES (
                    $1,
                    $2
                );`,
            [request.query.movie_id, form.director_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/delete-movie-director-action',
    (request, response) => {
        const form = request.body
        db.query(
            `DELETE FROM movies_directors WHERE
                    movie_id=$1 AND
                    director_id=$2
                ;`,
            [request.query.movie_id, form.director_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/add-movie-composer-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO movies_composers VALUES (
                    $1,
                    $2
                );`,
            [request.query.movie_id, form.composer_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/delete-movie-composer-action',
    (request, response) => {
        const form = request.body
        db.query(
            `DELETE FROM movies_composers WHERE
                    movie_id=$1 AND
                    composer_id=$2
                ;`,
            [request.query.movie_id, form.composer_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/add-movie-screenwriter-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO movies_screenwriters VALUES (
                    $1, $2
                );`,
            [request.query.movie_id, form.screenwriter_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/delete-movie-screenwriter-action',
    (request, response) => {
        const form = request.body
        db.query(
            `DELETE FROM movies_screenwriters WHERE
                    movie_id=$1 AND
                    screenwriter_id=$2
                ;`,
            [request.query.movie_id, form.screenwriter_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/add-movie-producer-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO movies_producers VALUES ($1, $2);`,
            [request.query.movie_id, form.producer_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/delete-movie-producer-action',
    (request, response) => {
        const form = request.body
        db.query(
            `DELETE FROM movies_producers WHERE
                    movie_id=$1 AND
                    producer_id=$2
                ;`,
            [request.query.movie_id, form.producer_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/add-movie-genre-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO movies_genres VALUES ($1, $2);`,
            [request.query.movie_id, form.genre_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/delete-movie-genre-action',
    (request, response) => {
        const form = request.body
        db.query(
            `DELETE FROM movies_genres WHERE
                    movie_id=$1 AND
                    genre_id=$2
                ;`,
            [request.query.movie_id, form.genre_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.get(
    '/add-genres',
    async (_request, response) => {
        const genres = await db.query('SELECT * FROM genres_with_statistics ORDER BY genre_id DESC;')
        return response.render(
            'add-genres',
            {
                genres: genres.rows,
            }
        )
    }
)

app.get(
    '/remove-genre',
    async (request, response) => {
        await db.query(`DELETE FROM genres WHERE genre_id = $1;`, [request.query.genre_id])
        return response.redirect('/add-genres')
    }
)

app.post(
    '/add-genre-action',
    (request, response) => {
        const form = request.body
        if(form.short_name == '')
            form.short_name = 'NULL'
        else
            form.short_name = `${form.short_name}`
        db.query(
            `INSERT INTO genres VALUES (DEFAULT, $1, $2);`,
            [form.genre_name, form.short_name],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/add-genres')
            }
        )
    }
)


app.get(
    '/add-people',
    async (_request, response) => {
        const people = await db.query('SELECT * FROM people_with_activity ORDER BY person_id DESC;')
        return response.render(
            'add-people',
            {
                people: people.rows,
            }
        )
    }
)

app.post(
    '/add-person-action',
    (request, response) => {
        const form = request.body
        if(form.first_name == '')
            form.first_name = 'NULL'
        else
            form.first_name = `${form.first_name}`
        if(form.pseudonym == '')
            form.pseudonym = null
        else
            form.pseudonym = `${form.pseudonym}`
        db.query(
            `INSERT INTO people VALUES (DEFAULT, $1, $2, $3);`,
            [form.first_name, form.last_name, form.pseudonym],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/add-people')
            }
        )
    }
)

app.get(
    '/remove-person',
    async (request, response) => {
        await db.query(`DELETE FROM people WHERE person_id = $1;`, [request.query.person_id])
        response.redirect('/add-people')
    }
)




app.get(
    '/add-producers',
    async (_request, response) => {
        const producers = await db.query('SELECT * FROM producers_with_statistics ORDER BY producer_id DESC;')
        return response.render(
            'add-producers',
            {
                producers: producers.rows,
            }
        )
    }
)

app.get(
    '/remove-producer',
    async (request, response) => {
        await db.query(`DELETE FROM producers WHERE producer_id = $1;`, [request.query.producer_id])
        return response.redirect('/add-producers')
    }
)

app.post(
    '/add-producer-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO producers VALUES (DEFAULT, $1);`, [form.company_name],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/add-producers')
            }
        )
    }
)

app.get(
    '/user-history',
    async (_request, response) => {
        const user_history = await db.query('SELECT * FROM user_history($1) ORDER BY date DESC,hour DESC, ticket_id DESC;', [user_id])
        return response.render(
            'user-history',
            {
                user_history: user_history.rows,
            }
        )
    }
)

app.get(
    '/cancel-ticket',
    (request, response) => {
        db.query(
            `SELECT cancel_ticket($1);`,
            [request.query.ticket_id],
            (error, _result) => {
                if(error)
                    console.log('Samo życie')
                response.redirect('/user-history')
            }
        )
    }
)


app.get(
    '/buy-ticket',
    async (_request, response) => {
        const schedule = await db.query('SELECT * FROM schedule ORDER BY screening_date, screening_hour;')
        return response.render(
            'buy-ticket',
            {
                schedule: schedule.rows,
            }
        )
    }
)

app.get(
    '/buy-for-screening',
    async (request, response) => {
        const schedule = await db.query(`SELECT * FROM schedule WHERE screening_id = $1`, [request.query.screening_id])
        const free_seats = await db.query(`SELECT * FROM get_free_seats($1);`, [request.query.screening_id])
        const ticket_types = await db.query('SELECT * FROM ticket_types;')
        return response.render(
            'buy-for-screening',
            {
                schedule: schedule.rows,
                free_seats: free_seats.rows,
                ticket_types: ticket_types.rows,
            }
        )
    }
)

app.post(
    '/buy-for-screening-action',
    (request, response) => {
        const form = request.body
        if(res_id){
            db.query(
                `SELECT buy_ticket(
                    $1,
                    $2,
                    $3,
                    $4,
                    $5);`,
                [request.query.screening_id, form.seat_id, form.ticket_type_id, res_id, user_id],
                (error, _result) => {
                    if(error)
                        console.log('ERROR: ' + error.message)
                    response.redirect(`/buy-for-screening?screening_id=${request.query.screening_id}`)
                }
            )
        }
        else{
            db.query(
                `SELECT buy_ticket(
                    $1,
                    $2,
                    $3,
                    NULL,
                    $4) AS "re";`,
                [request.query.screening_id, form.seat_id, form.ticket_type_id, user_id],
                (error, result) => {
                    if(error)
                        console.log('ERROR: ' + error.message)
                    else
                        res_id = result.rows[0].re
                    response.redirect(`/buy-for-screening?screening_id=${request.query.screening_id}`)
                }
            )

        }
    }
)

app.get(
    '/add-ticket-type',
    async (_request, response) => {
        const types = await db.query('SELECT * FROM ticket_types_with_statistics ORDER BY ticket_type_id DESC;')
        return response.render(
            'add-ticket-type',
            {
                types: types.rows,
            }
        )
    }
)

app.get(
    '/remove-ticket-type',
    async (request, response) => {
        await db.query(`DELETE FROM ticket_types WHERE ticket_type_id = $1;`, [request.query.type_id])
        return response.redirect('/add-ticket-type')
    }
)

app.post(
    '/add-ticket-type-action',
    (request, response) => {
        const form = request.body
        const discount = form.discount === '' ? 'NULL' : form.discount
        db.query(
            `
            INSERT INTO ticket_types
            VALUES
            (
                DEFAULT,
                $1,
                $2
            );
            `,
            [form.type_name, discount],
            (error, _result) => {
                if(error)
                    console.log('ERROR ' + error.message)
                response.redirect('/add-ticket-type')
            }
        )
    }
)

app.get(
    '/view-movie',
    async (request, response) => {
        const movies = await db.query(`SELECT * FROM movie_info WHERE movie_id IN (SELECT movie FROM full_screenings WHERE screening_id=$1);`, [request.query.screening_id])
        return response.render(
            'view-movie',
            {
                movies: movies.rows,
            }
        )
    }
)

app.get(
    '/best-customers',
    async (_request, response) => {
        const best_customers = await db.query('SELECT * FROM regular_customers;')
        return response.render(
            'best-customers',
            {
                best_customers: best_customers.rows,
            }
        )
    }
)

app.get(
    '/sum-money',
    async (request, response) => {
        const money = request.query.money
        const s_beg = request.query.s_beg
        const s_end = request.query.s_end
        return response.render(
            'sum-money',
            {
                money: money,
                s_beg: s_beg,
                s_end: s_end,
            }
        )
    }
)


app.post(
    '/sum-money-action',
    async (request, response) => {
        console.log("dupa")
        const s_beg = request.body.s_beg
        const s_end = request.body.s_end
        const q = `SELECT coalesce(sum(s.x), 0) AS sm FROM (SELECT reservation_value(reservation_id) AS "x" FROM reservations WHERE reservation_date BETWEEN $1 AND $2) AS "s";`
        console.log(q)
        const money = await db.query(q, [s_beg, s_end])
        const money_sum = money.rows[0].sm
        response.redirect(`/sum-money?money=${money_sum}&s_beg=${s_beg}&s_end=${s_end}`)
    }
)

app.get(
    '/best-seats',
    async (_request, response) => {
        const best_seats = await db.query('SELECT * FROM most_popular_seats JOIN rooms ON room=room_id JOIN seats USING(seat_id);')
        return response.render(
            'best-seats',
            {
                best_seats: best_seats.rows,
            }
        )
    }
)

app.listen(
    port,
    () => {
        console.log(`[server] Server is running at port ${port}!`)
    }
)


app.get(
    '/manage-reviews',
    async (_request, response) => {
        const reviews = await db.query('SELECT * FROM review_info ORDER BY review_id DESC;')
        const journals = await db.query('SELECT * FROM journals;')
        return response.render(
            'manage-reviews',
            {
                reviews: reviews.rows,
                journals: journals.rows,
            }
        )
    }
)

app.post(
    '/add-review-action',
    (request, response) => {
        const form = request.body
        form.summary = form.summary ? `${form.summary}` : 'NULL'
        form.stars = form.stars === '' ? 'NULL' : form.stars
        const q =
            `
            INSERT INTO reviews
            VALUES
            (
                DEFAULT,
                $1,
                $2,
                $3,
                $4,
                $5,
                $6
            );
            `
        db.query(
            q,
            [form.journal, form.title, form.content, form.summary, form.publication_date, form.stars],
            (error, _result) => {
                if(error)
                    console.log("ERROR: " + error.message)
                response.redirect('/manage-reviews')
            }
        )
    }
)

app.get(
    '/alter-review',
    async (request, response) => {
        const reviews = await db.query(`SELECT * FROM review_info WHERE review_id=$1;`, [request.query.review_id])
        const people = await db.query('SELECT * FROM people ORDER BY last_name ASC;')
        const authors = await db.query(`SELECT * FROM reviews_authors JOIN people ON author_id=person_id WHERE review_id=$1 ORDER BY last_name ASC;`, [request.query.review_id])
        const movies = await db.query('SELECT * FROM movies;')
        const reviewed = await db.query(`SELECT * FROM movies_reviews JOIN movies ON movies.movie_id=movies_reviews.movie_id WHERE review_id=$1 ORDER BY title ASC;`, [request.query.review_id])
        return response.render(
            'alter-review',
            {
                movies: movies.rows,
                reviewed: reviewed.rows,
                reviews: reviews.rows,
                people: people.rows,
                authors: authors.rows,
            }
        )
    }
)

app.post(
    '/link-author-to-review-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO reviews_authors VALUES (
                    $1,
                    $2
                );`,
            [request.query.review_id, form.author_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-review?review_id=${request.query.review_id}`)
            }
        )
    }
)

app.post(
    '/unlink-author-from-review-action',
    (request, response) => {
        const form = request.body
        db.query(
            `DELETE FROM reviews_authors WHERE
                    review_id=$1 AND
                    author_id=$2
                ;`,
            [request.query.review_id, form.author_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-review?review_id=${request.query.review_id}`)
            }
        )
    }
)

app.post(
    '/add-review-of-movie-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO movies_reviews VALUES ($1, $2);`,
            [form.movie_id, request.query.review_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-review?review_id=${request.query.review_id}`)
            }
        )
    }
)

app.post(
    '/remove-review-of-movie-action',
    (request, response) => {
        const form = request.body
        db.query(
            `DELETE FROM movies_reviews WHERE
                    movie_id=$1 AND
                    review_id=$2
                ;`,
            [form.movie_id, request.query.review_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-review?review_id=${request.query.review_id}`)
            }
        )
    }
)

app.get(
    '/remove-review',
    async (request, response) => {
        await db.query(`DELETE FROM reviews WHERE review_id = $1;`, [request.query.review_id])
        return response.redirect('/manage-reviews')
    }
)

app.post(
    '/add-movie-review-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO movies_reviews VALUES ($1, $2);`,
            [request.query.movie_id, form.review_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)

app.post(
    '/delete-movie-review-action',
    (request, response) => {
        const form = request.body
        db.query(
            `DELETE FROM movies_reviews WHERE
                    movie_id=$1 AND
                    review_id=$2
                ;`,
            [request.query.movie_id, form.review_id],
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect(`/alter-movie?movie_id=${request.query.movie_id}`)
            }
        )
    }
)
