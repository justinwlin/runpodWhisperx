Build the Image using Depot

```
depot build -t runpodwhisperx . --platform linux/amd64
```

Tag and Push it

```
docker tag runpodwhisperx:latest justinwlin/runpodwhisperx:1.0 && docker push justinwlin/runpodwhisperx:1.0
```
