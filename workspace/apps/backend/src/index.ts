import express from 'express';
import cors from 'cors';
import { GREETING } from 'lib';

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

app.get('/hello', (_, res) => {
  res.json({ message: GREETING });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
