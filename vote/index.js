const nunjucks = require('nunjucks')
const express = require('express')
const Redis = require('ioredis')
const axios = require('axios')

console.log('env.NODE_ENV:', process.env.NODE_ENV)
console.log('env.WEBSITE_PORT:', process.env.WEBSITE_PORT)
console.log('env.REDIS_HOST:', process.env.REDIS_HOST)

const NODE_ENV = process.env.NODE_ENV || 'production'
const WEBSITE_PORT = process.env.WEBSITE_PORT || 4000
const REDIS_HOST = process.env.REDIS_HOST || 'redis'

const app = express()

app.use(express.static('public'))
app.use(express.json())

nunjucks.configure('views', {
    express: app,
    autoescape: false,
    noCache: true
})

app.set('view engine', 'njk')

app.locals.node_env = NODE_ENV
app.locals.version = require('./package.json').version

if (NODE_ENV == 'development') {
    const livereload = require('connect-livereload')
    app.use(livereload())
}

const redis = new Redis({
    port: 6379,
    host: REDIS_HOST
})

app.get('/', async (req, res) => {
    try {
        res.render('index')
        
    } catch (err) {
        return res.json({
            code: err.code, 
            message: err.message
        })
    }
})

/*
    curl http://localhost:4000/vote
*/
app.get('/vote', async (req, res) => {
    let up = await redis.get('up')
    let down = await redis.get('down')
    return res.send({ up: Number(up) , down: Number(down) })
})

/*
    curl http://localhost:4000/vote \
        --header 'Content-Type: application/json' \
        --data '{"vote":"up"}'
*/
app.post('/vote', async (req, res) => {
    try {
        console.log('POST /vote: %j', req.body)
        console.log(req.body.vote)
        const result = await redis.incr(req.body.vote)
        console.log('result:', result)
        return res.send({ success: true, result: 'hello' })
        
    } catch (err) {
        console.log('ERROR: POST /vote: %s', err.message || err.response || err);
        res.status(500).send({ success: false, reason: 'internal error' });
    }
})

app.listen(WEBSITE_PORT, () => {
    console.log(`listening on port ${WEBSITE_PORT}`)
})
