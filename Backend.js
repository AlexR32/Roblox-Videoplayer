const childProcess = require('child_process')
const ffmpeg = require('ffmpeg-static')
const express = require('express')
const ytdl = require('ytdl-core')

const app = express()
app.use(express.json())
const port = process.env.PORT || 8080

function itagExists(info, itag) {
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

    if (validURL) { try { let info = await ytdl.getInfo(videoURL)
            if (itagExists(info, 247)) {
                let video = ytdl.downloadFromInfo(info, { quality: 247 })
                let audio = ytdl.downloadFromInfo(info, { quality: 'highestaudio' })
                console.log(`${new Date().toLocaleString()} | downloading ${videoURL}`)
                let ffmpegProcess = childProcess.spawn(ffmpeg, ['-loglevel', 'quiet',
                    '-i', 'pipe:0', '-i', 'pipe:1', '-map', '0:v', '-map', '1:a',
                    '-metadata','duration=' + info.videoDetails.lengthSeconds,
                    '-c:v', 'copy', '-f', 'webm', '-shortest', 'pipe:2'
                ])
                video.pipe(ffmpegProcess.stdio[0])
                audio.pipe(ffmpegProcess.stdio[1])
                ffmpegProcess.stdio[2].pipe(res)
            } else { res.sendStatus(404) }
        } catch(err) {
            console.log('WEBM ERR - ' + err)
            res.sendStatus(404)
        }
    } else { res.sendStatus(404) }
})

app.post('/yt/audio', async (req, res) => {
    if (!req.query.videoId) return res.sendStatus(404)
    let videoURL = 'https://youtu.be/' + req.query.videoId
    let validURL = ytdl.validateURL(videoURL)

    if (validURL) { try { let audio = ytdl(videoURL, { quality: 'highestaudio' })
            console.log(`${new Date().toLocaleString()} | downloading ${videoURL}`)
            let ffmpegProcess = childProcess.spawn(ffmpeg, ['-loglevel', 'quiet',
                '-i', 'pipe:0', '-f', 'mp3', 'pipe:1'
            ])
            audio.pipe(ffmpegProcess.stdio[0])
            ffmpegProcess.stdio[1].pipe(res)
        } catch(err) {
            console.log('MP3 ERR - ' + err)
            res.sendStatus(404)
        }
    } else { res.sendStatus(404) }
})

app.listen(port, () => {
    console.log(`${new Date().toLocaleString()} | server running on port ${port}`)
})
