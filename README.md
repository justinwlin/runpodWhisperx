# Summary

This is a Docker Image that runs the [WhisperX](https://github.com/m-bain/whisperX) repository. This is specifically for Runpod, where the handler is setup to get a response with an audio encoded in base64 as a string:

```
{
    "input": {
        "audio_base_64": "base64 encoding of audio"
    }
}
```

## Other helpful repositories:
WhisperX SRT Generator.
(Repository I made to take in the segments result I get from WhisperX and generate SRT transcriptions). 

https://github.com/justinwlin/WhisperXSRTGenerator

## Example How to Run the Docker Locally on ARM64
```
docker run --rm --gpus all -it justinwlin/runpodwhisperx:1.3 /bin/bash
```

If you want to run it against th example mp3 through the bash shell:

Mac / CPU
```
whisperx example.mp3 --compute_type int8 --language en
```

Windows / GPU
```
whisperx example.mp3 --language en
```

Or run the Runpod API Endpoint:

https://blog.runpod.io/workers-local-api-server-introduced-with-runpod-python-0-9-13/

https://docs.runpod.io/docs/handler#testing-locally

Running the below will use the test_input.json that is copied in. Or you can follow the runpod docs and do it through the shell.

https://github.com/justinwlin/runpodWhisperx/blob/master/test_input.json
```
python handler.py
```

If you want Mac instructions, I have a different repo setup for that:
https://github.com/justinwlin/WhisperXMac

## How to Build This Docker Image

You can replace anything that is `depot` with docker. I'm just using their service to build for amd64 platform, since I am on an arm64 platform on an M1 Mac.

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

Environment Variable for when working on Mac locally:

```
export DEVICE=cpu
export COMPUTE_TYPE=int8
```

## Local Testing

If you want to test locally, can just run:
`python3 main.py` It will automatically call the handler with the test_input.json

https://docs.runpod.io/docs/local-testing

This is assuming that you install requirements such as anything listed on the WHisperX repository and the runpod sdk.

# EXTREMELY IMPORTANT NOTE

Sometimes the output in the segment / word_segment, **DOES NOT** have a start/end time. 

Ex. Sometimes this will be:
 ```{"word": "Hello", "start": 0.27, "end": 0.61, "score": 0.862},```

Without a start/end:
 ```{"word": "Hello"},```

This is an error I caught after checking through my logs, and is just something about the model. Personally, I generated a sml transcription, by just asking chatgpt to write me a script, by giving it the word_segment / segment output I got, and at that time, it all had start/end points, but I had a rare transcription where it didn't have a start/end.
# You can encode your audio using:
```
import base64


def encodeAudioToBase64(audioPath):
    with open(audioPath, "rb") as audio_file:
        encoded_string = base64.b64encode(audio_file.read())
    return encoded_string.decode("utf-8")
```

# Example Functions from my application calling the Runpod API. 
Clientside Helper function to call Runpod deployed API:
(You use this AFTER you deploy this docker image to Runpod so you can use this repository as an API.)

Runpod API Deployment Code:

https://github.com/justinwlin/runpodWhisperx

Clientside helper functions to call Runpod deployed API:

https://github.com/justinwlin/runpod_whisperx_serverless_clientside_code

Helper functions to generate SRT transcriptions:

https://github.com/justinwlin/WhisperXSRTGenerator

## Usage Example
``` python
    # Grab the output path sound and encode it to base64 string
    base64AudioString = encodeAudioToBase64("./output.mp3")

    # Calling my helper functions to call the Runpod API
    apiResponse = transcribe_audio(
        base64_string=base64AudioString,
        runpod_api_key=RUNPOD_API_KEY,
        server_endpoint=SERVER_ENDPOINT,
        polling_interval=20
    )

    apiResponseOutput = apiResponse["output"]

    # Calling my SRT Generator helper functions to generate SRT transcriptions
    srtConverter = SRTConverter(apiResponseOutput["segments"])
    srtConverter.adjust_word_per_segment(words_per_segment=5)
    srtString = srtConverter.to_srt_highlight_word()
    srtConverter.write_to_file("output.srt", srtString)
```