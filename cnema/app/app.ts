import dotenv from 'dotenv';
import express from 'express';
import pg from 'pg'
import expressLayouts from 'express-ejs-layouts'

dotenv.config();

const app = express();
const port = process.env.PORT;

const db = new pg.Client('postgres://cnemaadmin:bazunia@localhost:5432/cnema');
db.connect();

app.use(express.static('public'));

app.set('view engine', 'ejs');
app.set('layout', './layouts/user-layout');
app.use(expressLayouts);

app.get(
    '/',
    (_request, response) => response.redirect('/index')
);

app.get(
    '/index',
    (_request, response) => response.render('index')
)

app.listen(
    port,
    () => {
        console.log(`[server] Server is running at port ${port}!`);
    }
);
