import dotenv from 'dotenv';
import express, { Express, Request, Response } from 'express';

import pgPromise from 'pg-promise';

const pgp = pgPromise();
const db = pgp('postgres://cnemaadmin:bazunia@localhost:5432/cnema');

dotenv.config();

const app: Express = express();
const port = process.env.PORT;

app.get(
    '/',
    async (_req: Request, res: Response) => {
        let result = await db.manyOrNone('select * from people;').then(
            data => data.map((row, index, _data) => String(index + 1) + ". " + row.first_name + ' ' + row.last_name).join('<br/>')
        );
        return res.send(`People present in database:<br/>${result}`);
    }
);

app.listen(
    port,
    () => {
        console.log(`[server] Server is running at port ${port}!`);
    }
)
