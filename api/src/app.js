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
const ProductOptionRouter = require('./routes/ProductOptionRouter');
const ReservationRouter = require('./routes/ReservationRouter');
const CartRouter = require('./routes/CartRouter');
const OrderRouter = require('./routes/OrderRouter');
const ChatRouter = require('./routes/ChatRouter');
const ReportRouter = require('./routes/ReportRouter');
const MapRouter = require('./routes/MapRouter');
const {
    resourceNotFound,
    handleError,
} = require('./controllers/ErrorController');
const app = express();
app.use(cors({
    origin: function (origin, callback) {
        if (!origin) return callback(null, true);
        if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
            return callback(null, true);
        }
        callback(null, true);
    },
    credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.get('/', (req, res) => {
    res.send(JSend.success());
});
app.use('/public', express.static('public'));
UserRouter.setup(app);
ProductOptionRouter.setup(app);
ProductRouter.setup(app);
CategoryRouter.setup(app);
TableRouter.setup(app);
BranchRouter.setup(app);
FloorRouter.setup(app);
ReservationRouter.setup(app);
CartRouter.setup(app);
OrderRouter.setup(app);
ChatRouter.setup(app);
ReportRouter.setup(app);
MapRouter.setup(app);
app.use(resourceNotFound);
app.use(handleError);
module.exports = app;