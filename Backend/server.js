const ytdl = require('ytdl-core')
const express = require('express')
const app = express()
const port = process.env.PORT || 80

app.use(express.static('static'))
app.use(express.urlencoded({extended: true}))

app.post('/download', async function(request, responce) {
    if (!request.body && !request.body.link) return responce.sendStatus(404)
    let link = 'https://youtu.be/' + request.body.link
    let validURL = ytdl.validateURL(link)
    if (validURL) {
        console.log('downloading ' + link)
        ytdl(link,{quality:247}).pipe(responce)
    } else {
        console.log('failed to download ' + link)
        responce.sendStatus(404)
    }
})

app.listen(port, () => {
    console.log('server running')
})
