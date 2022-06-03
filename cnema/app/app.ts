import dotenv from 'dotenv';
import express, { Express, Request, Response } from 'express';
import pg from 'pg'

dotenv.config();

const app: Express = express();
const port = process.env.PORT;

const db = new pg.Client('postgres://cnemaadmin:bazunia@localhost:5432/cnema');
db.connect();

app.set('view engine', 'ejs');

app.get(
    '/',
    async (_request: Request, response: Response) => {
        const data = await db.query('SELECT * FROM people');
        const result = data.rows.map(row => row.first_name + ' ' + row.last_name).join('<br/>');
        return response.send(`Found ${data.rowCount} entries in table people:<br/>${result}`);
    }
);

app.listen(
    port,
    () => {
        console.log(`[server] Server is running at port ${port}!`);
    }
);
