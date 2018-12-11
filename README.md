# OctoPrint Docker Image



[![GitHub release](https://img.shields.io/github/release/reloxx13/docker-octoprint.svg)](https://GitHub.com/reloxx13/docker-octoprint/releases/) 
[![Build Status](https://travis-ci.org/reloxx13/docker-octoprint.svg?branch=master)](https://travis-ci.org/reloxx13/docker-octoprint) 
[![GitHub contributors](https://img.shields.io/github/contributors/reloxx13/docker-octoprint.svg)](https://GitHub.com/reloxx13/docker-octoprint/graphs/contributors/) 

[![HitCount](http://hits.dwyl.io/reloxx13/docker-octoprint.svg)](http://hits.dwyl.io/reloxx13/docker-octoprint)
[![GitHub stars](https://img.shields.io/github/stars/reloxx13/docker-octoprint.svg)](https://github.com/reloxx13/docker-octoprint/stargazers)
[![DockerHub Star](https://img.shields.io/docker/stars/reloxx13/octoprint.svg)](https://hub.docker.com/r/reloxx13/octoprint/)
[![GitHub forks](https://img.shields.io/github/forks/reloxx13/docker-octoprint.svg)](https://github.com/reloxx13/docker-octoprint/network)
[![DockerHub Pull](https://img.shields.io/docker/pulls/reloxx13/octoprint.svg)](https://hub.docker.com/r/reloxx13/octoprint/)
[![Github all releases](https://img.shields.io/github/downloads/reloxx13/docker-octoprint/total.svg?label=gh%20downloads)](https://GitHub.com/reloxx13/docker-octoprint/releases/) 

[![GitHub license](https://img.shields.io/github/license/reloxx13/docker-octoprint.svg)](https://github.com/reloxx13/docker-octoprint/blob/master/LICENSE)


This the Source Repo for the [OctoPrint](https://github.com/foosel/OctoPrint) Docker Image. 

[Docker Hub](https://hub.docker.com/r/reloxx13/octoprint/)

It supports the following architectures automatically:


- arm32v6 (Raspberry Pi, etc.)
- x86

## Docker Tags

|Tag|Octoprint|
|---|---------|
|latest|Latest Stable|
|beta|ReleaseCandidate|
|dev|master|



## Tested devices

| Device              | Working? |
| ------------------- | -------- |
| Raspberry Pi 2b     | ✅        |
| Raspberry Pi 3b+    | ✅        |
| Raspberry Pi Zero W | ❌        |

## Usage

### Witout Webcam:
```shell
docker run -d  \
  --restart=unless-stopped \
  --name=OctoPrint \
  -p 1337:80 \
  --device=/dev/ttyUSB0:/dev/ttyUSB0 \
  -v /home/pi/Docker/OctoPrint/data:/data \
  reloxx13/octoprint:latest 
```

### With Webcam:
```shell
docker run -d  \
  --restart=unless-stopped \
  --name=OctoPrint \
  -p 1337:80 \
  --device=/dev/video0:/dev/video0 \
  --device=/dev/ttyUSB0:/dev/ttyUSB0 \
  -v /home/pi/Docker/OctoPrint/data:/data \
  -e STREAMER_FLAGS="-y -n -r 1280x720 -f 10" \
  reloxx13/octoprint:latest 
```

More about Webcams: [Webcams known to work](https://github.com/foosel/OctoPrint/wiki/Webcams-known-to-work)


## Environment Variables

| Variable                 | Description                    | Default Value      |
| ------------------------ | ------------------------------ | ------------------ |
| CAMERA_DEV               | The camera device node         | `/dev/video0`      |
| MJPEG_STREAMER_AUTOSTART | Start the camera automatically | `true`             |
| STREAMER_FLAGS           | Flags to pass to mjpg_streamer | `-y -n -r 640x480` |


## CuraEngine integration

Cura engine integration was very outdated (using version `15.04.6`) and was removed.

It will return once OctoPrint [supports python3](https://github.com/foosel/OctoPrint/pull/1416#issuecomment-371878648) (needed for the newest versions of cura engine).

## Webcam integration

1. Bind the camera to the docker using --device=/dev/video0:/dev/videoX
2. Optionally, change `STREAMER_FLAGS` to your preferred settings (ex: `-y -n -r 1280x720 -f 10`)
3. Use the following settings in octoprint:

```yaml
webcam:
  stream: /webcam/?action=stream
  snapshot: http://127.0.0.1:8080/?action=snapshot
  ffmpeg: /usr/bin/ffmpeg
```

### Notes

This image uses `supervisord` in order to launch 3 processes: _haproxy_, _octoprint_ and _mjpeg-streamer_.

This means you can disable/enable the camera at will from within octoprint by editing your `config.yaml`:

```yaml
system:
  actions:
  - action: streamon
    command: supervisorctl start mjpeg-streamer
    confirm: false
    name: Start webcam
  - action: streamoff
    command: supervisorctl stop mjpeg-streamer
    confirm: false
    name: Stop webcam
```

### Credits

Forked from https://github.com/nunofgs/docker-octoprint   
Original credits go to https://bitbucket.org/a2z-team/docker-octoprint



