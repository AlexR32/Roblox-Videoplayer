const childProcess = require('child_process')
const ffmpeg = require('ffmpeg-static')
const express = require('express')
const ytdl = require('ytdl-core')

const app = express()
app.use(express.json())
const port = process.env.PORT || 80

function isCorrectItag(info, itag) {
    for (i in info.formats) {
        if (info.formats[i].itag === itag) {
            return true
        }
    }
}

app.post('/yt/video', async (req, res) => {
    if (!req.query.videoId) return res.sendStatus(404)
    let videoURL = 'https://youtu.be/' + req.query.videoId
    let validURL = ytdl.validateURL(videoURL)

    if (validURL) { let info = await ytdl.getInfo(videoURL)
        if (isCorrectItag(info, 247)) {
            let video = ytdl.downloadFromInfo(info, { quality: 247 })
            let audio = ytdl.downloadFromInfo(info, { quality: 'highestaudio' })
            let ffmpegProcess = childProcess.spawn(ffmpeg, [
                '-loglevel', '8', '-hide_banner',
                '-i', 'pipe:0', '-i', 'pipe:1', '-map', '0:v', '-map', '1:a',
                '-metadata','duration=' + info.videoDetails.lengthSeconds,
                '-c:v', 'copy', '-f', 'webm', 'pipe:2'
            ])
            video.pipe(ffmpegProcess.stdio[0])
            audio.pipe(ffmpegProcess.stdio[1])
            ffmpegProcess.stdio[2].pipe(res)
        } else { res.sendStatus(404) }
    } else { res.sendStatus(404) }
})

app.post('/yt/audio', async (req, res) => {
    if (!req.query.videoId) return res.sendStatus(404)
    let videoURL = 'https://youtu.be/' + req.query.videoId
    let validURL = ytdl.validateURL(videoURL)

    if (validURL) { let info = await ytdl.getInfo(videoURL)
        let audio = ytdl.downloadFromInfo(info, { quality: 'highestaudio' })
        let ffmpegProcess = childProcess.spawn(ffmpeg, [
            '-loglevel', '8', '-hide_banner',
            '-i', 'pipe:0', '-f', 'mp3', 'pipe:1'
        ])
        audio.pipe(ffmpegProcess.stdio[0])
        ffmpegProcess.stdio[1].pipe(res)
    } else { res.sendStatus(404) }
})

app.listen(port, () => {
    console.log(`${new Date().toLocaleString()} | server running on port ${port}`)
})
