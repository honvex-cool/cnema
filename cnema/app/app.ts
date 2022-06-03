import dotenv from 'dotenv';
import express, { Express, Request, Response } from 'express';

dotenv.config();

const app: Express = express();
const port = process.env.PORT;

app.set('view engine', 'ejs');

app.get(
    '/',
    (_req: Request, res: Response) => {
        console.log('czemu to nie dziama')
        return res.send('Dziama');
    }
);

app.listen(
    port,
    () => {
        console.log(`[server] Server is running at port ${port}!`);
    }
);
