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
        return response.render(
            'browse-movies-admin',
            {
                movies: movies.rows,
            }
        )
    }
)

app.get(
    '/add-genres',
    async (_request, response) => {
        const genres = await db.query('SELECT * FROM genres;')
        return response.render(
            'add-genres',
            {
                genres: genres.rows,
            }
        )
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

app.listen(
    port,
    () => {
        console.log(`[server] Server is running at port ${port}!`)
    }
)
