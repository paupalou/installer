FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y
RUN apt-get install sudo vim -y
RUN useradd -ms /bin/bash pau
RUN usermod -aG sudo pau
RUN passwd -d pau

USER pau
WORKDIR /home/pau
RUN mkdir dotfiles
WORKDIR /home/pau/dotfiles
COPY . ./
