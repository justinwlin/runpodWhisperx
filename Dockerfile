FROM runpod/base:0.0.2

# Set Work Directory
WORKDIR /app

ARG WHISPER_MODEL=small
ARG LANG=en
ARG TORCH_HOME=/cache/torch
ARG HF_HOME=/cache/huggingface

# Environment variables
ENV TORCH_HOME=${TORCH_HOME}
ENV HF_HOME=${HF_HOME}
ENV WHISPER_MODEL=${WHISPER_MODEL}
ENV LANG=${LANG}

# Set LD_LIBRARY_PATH for library location (if still necessary)
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/
ENV DEBIAN_FRONTEND=noninteractive

# Update alternatives to ensure 'python' and 'pip' point to 'python3.10' and 'pip3.10' respectively
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    ln -s /usr/bin/pip3.10 /usr/bin/pip

# Install Python dependencies, setuptools-rust, PyTorch, and download WhisperX
# Avoid use of cache directory with pip, Pin versions in pip
RUN pip install --upgrade pip --no-cache-dir && \
    pip install \
        setuptools-rust==1.8.0 \
        huggingface_hub==0.18.0 \
        runpod==1.3.0 \
        torch==2.0.0 \
        torchvision==0.15.0 \
        torchaudio==2.0.0 \
        -f https://download.pytorch.org/whl/cu118/torch_stable.html && \
    pip install --no-cache-dir git+https://github.com/m-bain/whisperx.git

# Install FFmpeg
# Pin versions in apt get install, Avoid additional packages, Delete the apt-get lists after installing
RUN apt-get update && \
    apt-get install -y ffmpeg --no-install-recommends

# Copy and install requirements
COPY requirements.txt /app/requirements.txt

# Avoid use of cache directory with pip
RUN pip install --no-cache-dir -r requirements.txt

# Preload vad model
RUN python3 -c 'from whisperx.vad import load_vad_model; load_vad_model("cpu");'

# Preload fast-whisper
RUN python3 -c 'import faster_whisper; model = faster_whisper.WhisperModel("'${WHISPER_MODEL}'")'

# Preload align model
COPY load_align_model.py .
RUN python3 load_align_model.py ${LANG}

# COPY the example.mp3 file to the container as a default testing audio file
COPY example.mp3 /app/example.mp3
COPY handler.py /app/handler.py
COPY test_input.json /app/test_input.json

STOPSIGNAL SIGINT

CMD ["python", "-u", "handler.py"]
