# Streaming to Steam from the command line with `ffmpeg`

This is a script to stream a video to Steam Broadcast from the command line using `ffmpeg`.
It can be inconvenient to dedicate a machine to upload a stream for the entire week of a Steam festival, so it might be preferable to stream it from a cloud server.
Our [blogpost](https://www.cowleyforniastudios.com/2022/11/11/stream-to-steam-from-command-line) introducing this script has some further background.

The script is straightforward to use as long as you are comfortable with SSHing into a Linux server. The core of the script is an invocation of `ffmpeg` similar to the following:

```
ffmpeg \
    -re -stream_loop -1 \
    -i /path/to/source \
    -f flv \
    -vcodec libx264 \
    -acodec aac \
    -pix_fmt yuv420p \
    -b:v "2500k" -minrate "2500k" -maxrate "2500k" -bufsize "2500k" \
    -b:a "160k" \
    -s "1280x720" \
    -filter:v fps=30 \
    -g 60 \
    -flvflags no_duration_filesize \
    -preset "medium" \
    "rtmp://ingest-rtmp.broadcast.steamcontent.com/app/rmtp_token_goes_here"
```

Some parameters were derived from Steam's documentation, and some were arrived at by experimentation.
The most likely changes you want to make are to the resolution `-s "1280x720"` and the framerate `-filter:v fps=30`.
If you choose to change the framerate, you will also need to change the keyframe setting `-g 60`.
Steam expects a keyframe every 2s so the keyframe interval (`-g` parameter) should always be *framerate * 2*.

## How to use the script

* When you setup your stream settings in your Steamworks account as described [here](https://partner.steamgames.com/doc/store/broadcast/setting_up) be sure to take note of the RMTP Token; the script will need it to authenticate with Steam.
* SSH into your server and install `ffmpeg` (e.g. `sudo apt install ffmpeg` on Debian/Ubuntu).
* `scp` your video file and `steam-stream.sh` into your cloud server
* run `bash steam-stream.sh /path/to/video.mkv rmtp_token_goes_here`. This should not return unless there is an error. Once started you will be able to see the video in the broadcast page described in the [Steam documentation above](https://partner.steamgames.com/doc/store/broadcast/setting_up).

To run this as a background service so it starts on boot and gets restarted on failure, you can use the following `systemd` configuration. Insert your video path and RMTP token into the following service file:

```
[Unit]
Description=steam-stream
After=syslog.target

[Service]
Type=simple
ExecStart=/bin/bash /root/steam-stream.sh /path/to/video rmtp_token_goes_here
Restart=on-abort

[Install]
WantedBy=multi-user.target
```

Save this in `/etc/systemd/system/steam-stream.service`, run `systemctl daemon-reload && systemctl start steam-stream && systemctl enable steam-stream` and it should be run automatically on boot until you delete the server at the end of the festival.

## CPU usage

Be sure to check the CPU usage ahead of time.
If the CPU maxes out you risk losing frames, or dropping the stream entirely.
You may need to switch to a larger VPS.
