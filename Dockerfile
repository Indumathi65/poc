# Use an official lightweight image
FROM alpine:latest

# Set a label for the image
LABEL maintainer="Your Name <your.email@example.com>"

# Define the command to run when the container starts
CMD ["echo", "Hello, World!"]
