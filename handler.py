import runpod
import os
import time
import whisperx
import gc 
import base64
import tempfile
import requests

# CHECK THE ENV VARIABLES FOR DEVICE AND COMPUTE TYPE
device = os.environ.get('DEVICE', 'cuda') # cpu if on Mac
compute_type = os.environ.get('COMPUTE_TYPE', 'float16') #int8 if on Mac
batch_size = 16 # reduce if low on GPU mem
language_code = "en"

def base64_to_tempfile(base64_data):
    """
    Decode base64 data and write it to a temporary file.
    Returns the path to the temporary file.
    """
    # Decode the base64 data to bytes
    audio_data = base64.b64decode(base64_data)

    # Create a temporary file and write the decoded data
    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.mp3')
    with open(temp_file.name, 'wb') as file:
        file.write(audio_data)

    return temp_file.name

def download_file(url):
    """
    Download a file from a URL to a temporary file and return its path.
    """
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception("Failed to download file from URL")

    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.mp3')
    temp_file.write(response.content)
    temp_file.close()
    return temp_file.name

def handler(event):
    '''
    Run inference on the model.
    Returns output path, width the seed used to generate the image.
    '''
    job_input = event['input']
    job_input_audio_base_64 = job_input.get('audio_base_64')
    job_input_audio_url = job_input.get('audio_url')

    if job_input_audio_base_64:
        # If there is base64 data
        audio_input = base64_to_tempfile(job_input_audio_base_64)
    elif job_input_audio_url and job_input_audio_url.startswith('http'):
        # If there is an URL
        audio_input = download_file(job_input_audio_url)
    else:
        raise Exception("No audio input provided")
    
    # 1. Transcribe with original whisper (batched)
    model = whisperx.load_model("small", device, compute_type=compute_type, language="en")

    # Load the audio
    audio = whisperx.load_audio(audio_input)
    # Transcribe the audio
    result = model.transcribe(audio, batch_size=batch_size, language=language_code, print_progress=True)

    # 2. Align whisper output
    model_a, metadata = whisperx.load_align_model(language_code=language_code, device=device)
    result = whisperx.align(result["segments"], model_a, metadata, audio, device)
    print(result["segments"]) # after alignment
    return result

runpod.serverless.start({
    "handler": handler
})