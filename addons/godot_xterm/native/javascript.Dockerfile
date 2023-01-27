# For convenient building of the library for HTML5.
FROM emscripten/emsdk:3.1.14
RUN apt-get update && apt-get install pkg-config python3 -y
RUN pip3 install scons==4.4.0
VOLUME /scons-cache
CMD scons platform=javascript target=${TARGET:-template_release} arch=${ARCH:-wasm32}
