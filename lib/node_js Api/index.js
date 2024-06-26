// server.js
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const app = express();
const port = 3000;

let items = [];
let id = 1;

app.use(cors());
app.use(bodyParser.json());

app.get('/items', (req, res) => {
  res.json(items);
});

app.post('/items', (req, res) => {
  const item = { id: id++, ...req.body };
  items.push(item);
  res.json(item);
});

app.put('/items/:id', (req, res) => {
  const item = items.find(i => i.id == req.params.id);
  if (item) {
    Object.assign(item, req.body);
    res.json(item);
  } else {
    res.status(404).send('Item not found');
  }
});

app.delete('/items/:id', (req, res) => {
  items = items.filter(i => i.id != req.params.id);
  res.sendStatus(204);
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
