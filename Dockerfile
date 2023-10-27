# Base image
FROM runpod/pytorch:2.0.1-py3.10-cuda11.8.0-devel as base

# Set Work Directory
WORKDIR /app

# ARGs and ENVs
ARG WHISPER_MODEL=small
ARG LANG=en
ARG TORCH_HOME=/cache/torch
ARG HF_HOME=/cache/huggingface
ENV TORCH_HOME=${TORCH_HOME}
ENV HF_HOME=${HF_HOME}
ENV WHISPER_MODEL=${WHISPER_MODEL}
ENV LANG=${LANG}
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/
ENV DEBIAN_FRONTEND=noninteractive

# Set Locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Install Python dependencies, setuptools-rust, PyTorch, and download WhisperX
RUN pip install --upgrade pip && \
    pip install setuptools-rust huggingface_hub runpod torch==2.0.0 torchvision==0.15.0 torchaudio==2.0.0 -f https://download.pytorch.org/whl/cu118/torch_stable.html

# Install FFmpeg and Git
RUN apt-get update && \
    apt-get install -y ffmpeg git

# Clone and install WhisperX
COPY ./whisperx /code
RUN pip install /code

# Preload Models
RUN python3 -c 'from whisperx.vad import load_vad_model; load_vad_model("cpu");' && \
    python3 -c 'import faster_whisper; model = faster_whisper.WhisperModel("'${WHISPER_MODEL}'")'

# Preload align model
COPY load_align_model.py .
RUN python3 load_align_model.py ${LANG}

# Copy and install application-specific requirements
COPY requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt

# COPY the example.mp3 file to the container as a default testing audio file
COPY example.mp3 /app/example.mp3
COPY handler.py /app/handler.py
COPY test_input.json /app/test_input.json

# Set Stop signal and CMD
STOPSIGNAL SIGINT
CMD ["python", "-u", "handler.py"]
