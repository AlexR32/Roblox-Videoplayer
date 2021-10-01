const childProcess = require('child_process')
const ffmpeg = require('ffmpeg-static')
const ytdl = require('ytdl-core')
const express = require('express')
const app = express()
const port = process.env.PORT || 80

app.use(express.static('static'))
app.use(express.json())

function checkItag(info) {
    for (i in info.formats) {
        if (info.formats[i].itag === 247) {
            return true
        }
    }
}

app.post('/youtube', async function(request, responce) {
    if (!request.body && !request.body.videoId) return responce.sendStatus(404)
    let body = request.body
    let videoId = 'https://youtu.be/' + body.videoId
    let validURL = ytdl.validateURL(videoId)
    if (validURL) {
        let info = await ytdl.getInfo(videoId)
        if (checkItag(info)) {
            console.log('downloading ' + videoId)
            let video = ytdl(videoId, {quality: 247}) // only 720p webm
            let audio = ytdl(videoId, {quality: 'highestaudio'})
            const ffmpegProcess = childProcess.spawn(ffmpeg, [
                '-loglevel', '8', '-hide_banner',
                '-i', 'pipe:3',
                '-i', 'pipe:4',
                '-map', '0:v',
                '-map', '1:a',
                '-metadata','duration=' + info.videoDetails.lengthSeconds,
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
            video.pipe(ffmpegProcess.stdio[3])
            audio.pipe(ffmpegProcess.stdio[4])
            ffmpegProcess.stdio[5].pipe(responce)
            ffmpegProcess.on('close', () => {
                console.log('downloaded ' + videoId)
            })
        } else {
            responce.sendStatus(404)
        }
    } else {
        responce.sendStatus(404)
    }
})

app.listen(port, () => {
    console.log('server running')
})
