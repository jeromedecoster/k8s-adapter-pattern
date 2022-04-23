const client = require('prom-client')
const express = require('express')
const Redis = require('ioredis')

console.log('env.NODE_ENV:', process.env.NODE_ENV)
console.log('env.SERVER_PORT:', process.env.SERVER_PORT)
console.log('env.REDIS_HOST:', process.env.REDIS_HOST)

const SERVER_PORT = process.env.SERVER_PORT || 5000
const REDIS_HOST = process.env.REDIS_HOST || 'localhost'

const collectDefaultMetrics = client.collectDefaultMetrics
// collect every 5 seconds
collectDefaultMetrics({ timeout: 5000 })


const app = express()

const redis = new Redis({
  port: 6379,
  host: REDIS_HOST
})

// home
app.get('/', (req, res) => {
  res.redirect('/metrics')
})

//
// Up + Down
//

const up_gauge = new client.Gauge({
  name: 'up_gauge',
  help: 'Number of up.'
})

const down_gauge = new client.Gauge({
  name: 'down_gauge',
  help: 'Number of down.'
})

// metrics endpoint
/*
    curl http://localhost:5000/metrics
*/
app.get('/metrics', async (req, res) => {
  let up = await redis.get('up')
  console.log('up:', up)
  up_gauge.set(Number(up))
  let down = await redis.get('down')
  console.log('down:', down)
  down_gauge.set(Number(down))
  res.set('Content-Type', client.register.contentType)
  res.end(await client.register.metrics())
})


app.listen(SERVER_PORT, () => {
  console.log(`Listening port : ${SERVER_PORT}`)
})
