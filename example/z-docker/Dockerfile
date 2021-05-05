FROM ubuntu:latest
RUN apt update && apt install -y openssl libev4
COPY app.exe .
ENTRYPOINT /app.exe
