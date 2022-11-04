const childProcess = require('child_process')
const ffmpeg = require('ffmpeg-static')
const express = require('express')
const ytdl = require('ytdl-core')

const app = express()
app.use(express.json())
const port = process.env.PORT || 8080

function print(message) {
    console.log(`${new Date().toLocaleString()} | ${message}`)
}

function itagExists(info) {
    for (const index in info.formats) {
        switch (info.formats[index].itag) {
            case 247: // 720p
                return [247, 'copy']
            case 244: // 480p
                return [244, 'copy']
            case 243: // 360p
                return [243, 'copy']
            case 242: // 240p
                return [242, 'copy']
            case 278: // 144p
                return [278, 'copy']
        }
    } return ['highestvideo', 'libvpx-vp9']
}

app.post('/yt/video', async (req, res) => {
    if (!req.query.videoId) return res.sendStatus(404)
    let videoURL = 'https://youtu.be/' + req.query.videoId
    let validURL = ytdl.validateURL(videoURL)

    if (validURL) {
        try { let info = await ytdl.getInfo(videoURL)
            let [videoQuality, codec] = itagExists(info)
            print(`downloading ${videoURL} | videoQuality: ${videoQuality}`)
            let video = ytdl.downloadFromInfo(info, { quality: videoQuality })
            let audio = ytdl.downloadFromInfo(info, { quality: 'highestaudio' })
            let ffmpegProcess = childProcess.spawn(ffmpeg, ['-loglevel', 'quiet',
                '-i', 'pipe:0', '-i', 'pipe:1', '-map', '0:v', '-map', '1:a',
                '-metadata','duration=' + info.videoDetails.lengthSeconds,
                '-c:v', codec, '-f', 'webm', '-shortest', 'pipe:2'
            ]); video.pipe(ffmpegProcess.stdio[0])
            audio.pipe(ffmpegProcess.stdio[1])
            ffmpegProcess.stdio[2].pipe(res)
            .on('finish', () => {
                print('downloaded ' + videoURL)
            })
        } catch(err) { res.sendStatus(404)
            print('WEBM ERR : ' + err)
        }
    } else { res.sendStatus(404) }
})

app.post('/yt/audio', async (req, res) => {
    if (!req.query.videoId) return res.sendStatus(404)
    let videoURL = 'https://youtu.be/' + req.query.videoId
    let validURL = ytdl.validateURL(videoURL)

    if (validURL) { try { print('downloading audio ' + videoURL)
            let audio = ytdl(videoURL, { quality: 'highestaudio' })
            let ffmpegProcess = childProcess.spawn(ffmpeg, [
                '-loglevel','quiet', '-i', 'pipe:0',
                '-f', 'mp3', 'pipe:1'
            ]); audio.pipe(ffmpegProcess.stdio[0])
            ffmpegProcess.stdio[1].pipe(res)
            .on('finish', () => {
                print('downloaded ' + videoURL)
            })
        } catch(err) { res.sendStatus(404)
            print('MP3 ERR : ' + err)
        }
    } else { res.sendStatus(404) }
})

app.listen(port, () => {
    print(`server running on port ${port}`)
})
