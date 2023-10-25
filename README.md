Build the Image using Depot

```
depot build -t runpodwhisperx . --platform linux/amd64
```

Tag and Push it

```
docker tag runpodwhisperx:latest justinwlin/runpodwhisperx:1.0 && docker push justinwlin/runpodwhisperx:1.0
```

Or build & directly push it with depot:

```
depot build -t justinwlin/runpodwhisperx:1.0 . --platform linux/amd64 --push
```

Docker Repo:
(FYI - I don't do proper versioning control. I keep pushing over 1.0 until it is stable, and only there, do I
begin to do versioning control with 1.1, 1.2, etc.)

https://hub.docker.com/repository/docker/justinwlin/runpodwhisperx/general

Environment Variable for when working on Mac:

```
export DEVICE=cpu
export COMPUTE_TYPE=int8
```
