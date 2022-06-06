import dotenv from 'dotenv'
import express from 'express'
import pg from 'pg'
import expressLayouts from 'express-ejs-layouts'

dotenv.config()

const app = express()
const port = process.env.PORT

const db = new pg.Client('postgres://cnemaadmin:bazunia@localhost:5432/cnema')
db.connect()

app.use(express.static('public'))
app.use(express.urlencoded({ extended: true }))
app.use(express.json())

app.set('view engine', 'ejs')
app.set('layout', './layouts/user-layout')
app.use(expressLayouts)

app.get(
    '/',
    (_request, response) => response.redirect('/index')
)

app.get(
    '/index',
    (_request, response) => response.render('index')
)

app.get(
    '/add-screening',
    async (_request, response) => {
        const schedule = await db.query('SELECT * FROM schedule ORDER BY screening_date, screening_hour;')
        const regionalizations = await db.query('SELECT * FROM regionalizations_language_names;')
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
                regionalizations: regionalizations.rows,
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
                '${form.screening_date}',
                '${form.screening_time}',
                ${form.screening_movie},
                ${form.screening_audio},
                ${form.screening_lector},
                ${form.screening_subtitles},
                ${form.screening_room},
                ${form.screening_ticket_price}
            );
            `
        db.query(
            q,
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

app.post(
    '/add-room-result',
    (request, response) => {
        db.query(
            `INSERT INTO rooms VALUES (DEFAULT, '${request.body.room_name}');`,
            (error, _result) => {
                if(error)
                    console.log(error.message)
                response.redirect('/add-room')
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
            `INSERT INTO languages VALUES (DEFAULT, '${form.language_name}');`,
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
app.get(
    '/buy-ticket',
    (_request, response) => {
        return response.render('buy-screen')
    }
)

app.get(
    '/cancel-ticket',
    (_request, response) => {
        return response.render('cancel-screen')
    }
)

app.post(
    '/ensure-user',
    (request, response) => {
        const form = request.body
        const q = `
            SELECT get_or_make_user_id('${form.username}', '${form.mail}') AS user_id;
            `
        console.log(q)
        db.query(
            q,
            (error, result) => {
                if(error) {
                    console.log('You stuped: ' + error.message)
                    response.redirect('/login')
                } else {
                    console.log('USER ID: ' + result.rows[0].user_id)
                    response.redirect('/login')
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

app.post(
    '/add-movie-action',
    (request, response) => {
        const form = request.body
        if(form.release_date == '')
            form.release_date = 'NULL'
        else
            form.release_date = `'${form.release_date}'`
        const q = `INSERT INTO movies VALUES (
                    DEFAULT, 
                    '${form.title}',
                    '${form.hours}:${form.minutes}',
                    ${form.age_rating},
                    ${form.release_date},
                    ${form.original_language}
                );`
        console.log(q)
        db.query(
            q,
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/browse-movies-admin')
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
                    ${form.movie_id},
                    ${form.director_id}
                );`,
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/browse-movies-admin')
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
                    ${form.movie_id},
                    ${form.composer_id}
                );`,
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/browse-movies-admin')
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
                    ${form.movie_id},
                    ${form.screenwriter_id}
                );`,
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/browse-movies-admin')
            }
        )
    }
)

app.post(
    '/add-movie-producer-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO movies_producers VALUES ( 
                    ${form.movie_id},
                    ${form.producer_id}
                );`,
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/browse-movies-admin')
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
        await db.query(`DELETE FROM genres WHERE genre_id = ${request.query.genre_id};`)
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
            form.short_name = `'${form.short_name}'`
        db.query(
            `INSERT INTO genres VALUES (DEFAULT, '${form.genre_name}', ${form.short_name});`,
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
            form.first_name = `'${form.first_name}'`
        if(form.pseudonym == '')
            form.pseudonym = 'NULL'
        else
            form.pseudonym = `'${form.pseudonym}'`
        db.query(
            `INSERT INTO people VALUES (DEFAULT, ${form.first_name}, '${form.last_name}',${form.pseudonym});`,
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
        await db.query(`DELETE FROM people WHERE person_id = ${request.query.person_id};`)
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
        await db.query(`DELETE FROM producers WHERE producer_id = ${request.query.producer_id};`)
        return response.redirect('/add-producers')
    }
)

app.post(
    '/add-producer-action',
    (request, response) => {
        const form = request.body
        db.query(
            `INSERT INTO producers VALUES (DEFAULT, '${form.company_name}');`,
            (error, _result) => {
                if(error)
                    console.log('ERROR: ' + error.message)
                response.redirect('/add-producers')
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
