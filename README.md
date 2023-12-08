# Summary

This is a Docker Image that runs the [WhisperX](https://github.com/m-bain/whisperX) repository. This is specifically for Runpod, where the handler is setup to get a response with an audio encoded in base64 as a string:

```
{
    "input": {
        "audio_base_64": "base64 encoding of audio"
    }
}
```

## Example How to Run the Docker Locally on ARM64
```
docker run --rm --gpus all -it justinwlin/runpodwhisperx:1.3 /bin/bash
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
 {"word": "Hello", "start": 0.27, "end": 0.61, "score": 0.862},

Without a start/end:
 {"word": "Hello"},

This is an error I caught after checking through my logs, and is just something about the model. Personally, I generated a sml transcription, by just asking chatgpt to write me a script, by giving it the word_segment / segment output I got, and at that time, it all had start/end points, but I had a rare transcription where it didn't have a start/end.

# Example Functions of me calling the runpod:

```
SERVER_ENDPOINT = "XXXXXXXX"

def send_and_auto_async_request_runpod_subtitler(base64_string, RUNPOD_API_KEY):
    """
    Automatically makes an async request to runpod and keeps checking the status until the job is completed.

    @param
    base64_string: The base64 string of the audio file
    RUNPOD_API_KEY: The API key for Runpod

    @return
    outputResponse: The response from Runpod. Structured as:
    {
        "status": "COMPLETED",
        "output": {
            "segments": [
                {
                    "start": 0.27,
                    "end": 1.632,
                    "text": " Hello world.",
                    "words": [
                        {"word": "Hello", "start": 0.27, "end": 0.61, "score": 0.862},
                        {"word": "world.", "start": 0.69, "end": 1.091, "score": 0.779},
                    ],
                },
            ...
            "words_segments": [
            {
                "start": 0.27,
                "end": 1.632,
                "text": " Hello"
            }
         ]
        }
    }
    """
    jobId = send_async_request_runpod_subtitler(
        base64_string=base64_string, RUNPOD_API_KEY=RUNPOD_API_KEY
    )
    outputResponse = get_runpod_job_status_from_id(jobId, RUNPOD_API_KEY=RUNPOD_API_KEY)
    jobStatus = outputResponse["status"]  # Will be either "IN_PROGRESS" or "COMPLETED"
    # Keep checking every minute until the job is completed
    while jobStatus == "IN_PROGRESS" or jobStatus == "IN_QUEUE":
        time.sleep(60)  # Wait for 1 minute
        outputResponse = get_runpod_job_status_from_id(
            jobId, RUNPOD_API_KEY=RUNPOD_API_KEY
        )
        print("Current output Response: ", outputResponse)
        jobStatus = outputResponse["status"]
    outputResponse = outputResponse["output"]
    return outputResponse


def send_async_request_runpod_subtitler(base64_string, RUNPOD_API_KEY):
    """
    Sends an async request to Runpod and returns the job id.

    @param
    base64_string: The base64 string of the audio file
    RUNPOD_API_KEY: The API key for Runpod

    @return
    jobId: The job id of the request
    """
    url = f"https://api.runpod.ai/v2/{SERVER_ENDPOINT}/run"

    payload = json.dumps({"input": {"audio_base_64": base64_string}})
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + RUNPOD_API_KEY,
    }

    response = requests.post(url, headers=headers, data=payload).json()
    return response["id"]


def get_runpod_job_status_from_id(id, RUNPOD_API_KEY):
    """
    Grabs a job status from Runpod using the job id.

    @param
    id: The job id of the request
    RUNPOD_API_KEY: The API key for Runpod

    @return
    outputResponse: The response from Runpod. Structured as:
    {
        "status": "COMPLETED",
        "output": [{...}...]
    }
    Or if the job is still in progress/in Queue:
    {
        "status": "IN_PROGRESS" / "IN_QUEUE
    }
    """
    url = f"https://api.runpod.ai/v2/{SERVER_ENDPOINT}/status/{id}"

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + RUNPOD_API_KEY,
    }

    response = requests.get(url, headers=headers).json()
    print("Response from Runpod: ", response)

    if response["status"] == "IN_PROGRESS" or response["status"] == "IN_QUEUE":
        return {"status": response["status"]}
    else:
        return {
            "status": "COMPLETED",
            "output": response["output"],
        }

    return response


def send_synchronous_request_runpod_subtitler(
    base64_string: str, RUNPOD_API_KEY: str, mock: bool = False
) -> SubtitlerResponse:
    """
    Sends a synchronous request to Runpod and returns the response. Can potentially time out if the Runpod server takes too long.

    @param
    base64_string: The base64 string of the audio file
    RUNPOD_API_KEY: The API key for Runpod
    mock: If true, returns a mock response

    @return
    outputResponse: The response from Runpod. Structured as:
    {
        "segments": [
            {
                "start": 0.27,
                "end": 1.632,
                "text": " Hello world.",
                "words": [
                    {"word": "Hello", "start": 0.27, "end": 0.61, "score": 0.862},
                    {"word": "world.", "start": 0.69, "end": 1.091, "score": 0.779},
                ],
            },
        ...
        "words_segments": [
        {
            "start": 0.27,
            "end": 1.632,
            "text": " Hello"
        }
        ]
    }
    """
    if mock == True:
        return {
            "segments": [
                {
                    "start": 0.27,
                    "end": 1.632,
                    "text": " Hello world.",
                    "words": [
                        {"word": "Hello", "start": 0.27, "end": 0.61, "score": 0.862},
                        {"word": "world.", "start": 0.69, "end": 1.091, "score": 0.779},
                    ],
                },
                {
                    "start": 1.632,
                    "end": 3.055,
                    "text": "Nice to meet you.",
                    "words": [
                        {"word": "Nice", "start": 1.632, "end": 1.913, "score": 0.868},
                        {"word": "to", "start": 1.953, "end": 2.033, "score": 0.832},
                        {"word": "meet", "start": 2.093, "end": 2.274, "score": 0.788},
                        {"word": "you.", "start": 2.294, "end": 2.454, "score": 0.849},
                    ],
                },
                {
                    "start": 3.055,
                    "end": 5.1,
                    "text": "My name is John Doe.",
                    "words": [
                        {"word": "My", "start": 3.055, "end": 3.216, "score": 0.996},
                        {"word": "name", "start": 3.276, "end": 3.476, "score": 0.979},
                        {"word": "is", "start": 3.556, "end": 3.637, "score": 0.63},
                        {"word": "John", "start": 3.737, "end": 4.017, "score": 0.684},
                        {"word": "Doe.", "start": 4.057, "end": 4.358, "score": 0.531},
                    ],
                },
                {
                    "start": 5.1,
                    "end": 6.803,
                    "text": "Here's a funny story about a dog.",
                    "words": [
                        {"word": "Here's", "start": 5.1, "end": 5.4, "score": 0.619},
                        {"word": "a", "start": 5.44, "end": 5.46, "score": 0.999},
                        {"word": "funny", "start": 5.52, "end": 5.781, "score": 0.812},
                        {"word": "story", "start": 5.841, "end": 6.162, "score": 0.789},
                        {"word": "about", "start": 6.222, "end": 6.422, "score": 0.901},
                        {"word": "a", "start": 6.462, "end": 6.482, "score": 0.999},
                        {"word": "dog.", "start": 6.523, "end": 6.803, "score": 0.993},
                    ],
                },
            ]
        }

    url = f"https://api.runpod.ai/v2/{SERVER_ENDPOINT}/runsync"

    payload = json.dumps({"input": {"audio_base_64": base64_string}})
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + RUNPOD_API_KEY,
    }

    response = requests.post(url, headers=headers, data=payload).json()
    print("Response from Runpod: ", response)
    output = response["output"]
    if output == None or output == []:
        raise Exception("No output from Runpod")

    return output
```
