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
        const movies = await db.query('SELECT movie_id, title FROM movies;')
        const languages = await db.query('SELECT * FROM languages;')
        const rooms = await db.query('SELECT * FROM rooms;')
        return response.render(
            'add-screening',
            {
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
        console.log(q)
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

app.listen(
    port,
    () => {
        console.log(`[server] Server is running at port ${port}!`)
    }
)
