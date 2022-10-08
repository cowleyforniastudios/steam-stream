#!/bin/bash

function usage {
    echo "steam-stream.sh <Source file> <Upload Token>"
    exit 1
}
SourceFile="$1"
if [ -z "$SourceFile" ]; then
    usage
fi
UploadToken="$2"
if [ -z "$UploadToken" ]; then
    usage
fi

# Steam ingest that will redirect to the geographically nearest ingest point
IngestServer="rtmp://ingest-rtmp.broadcast.steamcontent.com/app"

# Settings from https://partner.steamgames.com/doc/store/broadcast/setting_up
#
# Audio 160k, video 2500k
# keyframe interval is 2s
#
# NB without -re it will send the data as quickly as possible, that will overload and steam drops the connection
VideoBitRate="2500k"
AudioBitRate="160k"
KeyFrameIntervalSeconds=2

# Settings that worked for me, depending on CPU, connection, source video they can likely be increased
Framerate=30
Resolution="1280x720"
FFmpegPreset="medium"

ffmpeg \
    -re -stream_loop -1 \
    -i "$SourceFile" \
    -f flv \
    -vcodec libx264 \
    -acodec aac \
    -pix_fmt yuv420p \
    -b:v "$VideoBitRate" -minrate "$VideoBitRate" -maxrate "$VideoBitRate" -bufsize "$VideoBitRate" \
    -b:a "$AudioBitRate" \
    -s "$Resolution" \
    -filter:v fps=$Framerate \
    -g $(($Framerate * $KeyFrameIntervalSeconds)) \
    -flvflags no_duration_filesize \
    -preset "$FFmpegPreset" \
    "$IngestServer/$UploadToken"
