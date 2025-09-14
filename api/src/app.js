require('dotenv').config();
const express = require('express');
const cors = require('cors');

const JSend = require('./jsend');
const UserRouter = require('./routes/UserRouter');
const ProductRouter = require('./routes/ProductRouter');

const CategoryRouter = require('./routes/CategoryRouter');
const TableRouter = require('./routes/TableRouter');
const BranchRouter = require('./routes/BranchRouter');
const FloorRouter = require('./routes/FloorRouter');
const ProvinceRouter = require('./routes/ProvinceRouter');

const {
    resourceNotFound,
    handleError,
} = require('./controllers/ErrorController');
const { specs, swaggerUi, swaggerOptions } = require('./docs/swagger');
const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
    res.send(JSend.success());
});

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, swaggerOptions));
app.use('/public', express.static('public'));

UserRouter.setup(app);
ProductRouter.setup(app);
app.use('/api/categories', CategoryRouter);
app.use('/api/tables', TableRouter);
app.use('/api/branches', BranchRouter);
app.use('/api/floors', FloorRouter);
app.use('/api/provinces', ProvinceRouter);

app.use(resourceNotFound);
app.use(handleError);

module.exports = app;