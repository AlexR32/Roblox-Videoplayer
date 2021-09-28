const childProcess = require('child_process')
const ffmpeg = require('ffmpeg-static')
const ytdl = require('ytdl-core')
const express = require('express')
const app = express()
const port = process.env.PORT || 80

app.use(express.static('static'))
app.use(express.urlencoded({extended: true}))

app.post('/download', function(request, responce) {
    if (!request.body && !request.body.link) return responce.sendStatus(404)
    let link = 'https://youtu.be/' + request.body.link
    let validURL = ytdl.validateURL(link)
    if (validURL) {
        let video = ytdl(link, {quality: 247}) // only 720p webm
        let audio = ytdl(link, {quality: 'highestaudio'})
        
        const ffmpegProcess = childProcess.spawn(ffmpeg, [
            '-loglevel', '8', '-hide_banner',
            '-i', 'pipe:3',
            '-i', 'pipe:4',
            '-map', '0:v',
            '-map', '1:a',
            '-c:v', 'copy',
            '-f', "webm",
            'pipe:5',
        ], {
            windowsHide: true,
            stdio: [
                'inherit', 'inherit', 'inherit',
                'pipe', 'pipe', 'pipe',
            ],
        })
        console.log('downloading ' + link)
        video.pipe(ffmpegProcess.stdio[3])
        audio.pipe(ffmpegProcess.stdio[4])
        ffmpegProcess.stdio[5].pipe(responce)
        ffmpegProcess.on('close', () => {
            console.log('downloaded ' + link)
        })
    } else {
        console.log('failed to download ' + link)
        responce.sendStatus(404)
    }
})

app.listen(port, () => {
    console.log('server running')
})
