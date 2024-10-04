const routes = (app) => {
    app.use('/', (req, res) => {
        res.send('Hello World!');
    })
}

module.exports = routes