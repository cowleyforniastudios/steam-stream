# Streaming to Steam from the command line with `ffmpeg`

This is a script to stream a video to Steam Broadcast from the command line using `ffmpeg`.
It can be inconvenient to dedicate a machine to upload a stream for the entire week of a Steam festival, so it might be preferable to stream it from a cloud server.
Our [blogpost]() introducing this script has some further background.

The script is straightforward to use as long as you are comfortable with SSHing into a Linux server. The core of the script is an invocation of `ffmpeg` similar to the following (some parameters derived from Steam's docs, and some are from experimentation):

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

Save this in `/etc/systemd/system/steam-stream.service` and run `systemctl daemon-reload && systemctl start steam-stream && systemctl enable steam-stream` and it should be run automatically on boot until you delete the server at the end of the festival.

## Alternatives to Cloud servers

This can also be used on a Raspberry PIs if you have one and prefer that. It would be worth testing first to be sure the processor can handle the load though.

`ffmpeg` runs on Windows, Mac and Linux, so if you don't want to set up a cloud server, but do want to stream from the command line you can use it on any computer. Mac is identical to Linux in this respect, just run the bash script from Terminal, but you would need to use `launchctl` rather than `systemd` if you want to run it as a background service.

On Windows you can also run it unmodified if you are using WSL, it is even possible to run it as a background service as long as you [configure systemd](https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/). Alternatively it should not be hard to translate the script to Powershell.
