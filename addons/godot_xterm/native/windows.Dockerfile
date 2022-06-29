FROM ubuntu:latest
RUN apt-get update -y
RUN apt-get install -y cmake mingw-w64 scons
RUN apt-get install -y wget && \
	wget https://gist.githubusercontent.com/peterspackman/8cf73f7f12ba270aa8192d6911972fe8/raw/9d775cdff025ab12bdffe9e9a195e306a429bb86/mingw-w64-x86_64.cmake
RUN sed 's/x86_64-w64-mingw32/i686-w64-mingw32/g' /mingw-w64-x86_64.cmake > /mingw-w64-i686.cmake
