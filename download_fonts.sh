#!/bin/bash

# Create the fonts directory
mkdir -p assets/fonts

# Download Roboto fonts - using actual TTF files from GitHub
curl -L "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf" -o assets/fonts/Roboto-Regular.ttf
curl -L "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf" -o assets/fonts/Roboto-Bold.ttf
curl -L "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Italic.ttf" -o assets/fonts/Roboto-Italic.ttf

echo "Fonts downloaded successfully!"