.PHONY: all

# Set the version file path
VERSION_FILE := version.txt

# Get the current version number from the file (default to 1.0.0 if file doesn't exist)
VERSION := $(shell cat $(VERSION_FILE) 2>/dev/null || echo 1.0.0)

all:
	depot build -t justinwlin/runpodwhisperx:$(VERSION) -t justinwlin/runpodwhisperx:latest . --platform linux/amd64 --push
	echo $(shell echo $(VERSION) | awk -F. '{$$NF = $$NF + 1;} 1' | sed 's/ /./g') > $(VERSION_FILE)