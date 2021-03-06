# Build arguments

ARG QEMU_ARCH
ARG BUILD_ARCH

# Intermediate build container with arm support.
FROM ${QEMU_ARCH} as qemu
FROM ${BUILD_ARCH}/python:2.7-slim as build

COPY --from=qemu /qemu-arm /usr/bin/qemu-arm-static

ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Label
LABEL \
    maintainer1="Reloxx <reloxx@interia.pl>" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.license="GNU" \
    org.label-schema.name="OctoPrint Docker" \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.description="OctoPrint Docker" \
    org.label-schema.url="https://github.com/reloxx13/docker-octoprint" \
    org.label-schema.usage="https://github.com/reloxx13/docker-octoprint/blob/master/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://github.com/reloxx13/docker-octoprint"
	
# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  avrdude \
  stm32flash \
  libwxgtk3.0-dev libreadline-dev \
  autoconf libusb-1.0-0-dev \
  usbmount \
  build-essential \
  cmake \
  git \
  haproxy \
  imagemagick \
  libav-tools \
  v4l-utils \
  libjpeg-dev \
  libjpeg62-turbo \
  libprotobuf-dev \
  libv4l-dev \
  psmisc \
  supervisor \
  unzip \
  wget \
  zlib1g-dev


RUN apt-get install -y --no-install-recommends build-essential
RUN apt-get install -y --no-install-recommends cmake

# Download packages
RUN wget -vO- https://github.com/foosel/OctoPrint/archive/${BUILD_VERSION}.tar.gz | tar xz
RUN wget -vO- https://github.com/jacksonliam/mjpg-streamer/archive/master.tar.gz | tar xz

# Install mjpg-streamer
WORKDIR /mjpg-streamer-master/mjpg-streamer-experimental
RUN make
RUN make install




# Install OctoPrint
WORKDIR /OctoPrint-${BUILD_VERSION}
RUN pip install -r requirements.txt
RUN python setup.py install

VOLUME /data
WORKDIR /data

COPY haproxy.cfg /etc/haproxy/haproxy.cfg
# COPY pip.conf /root/.pip/pip.conf
COPY supervisord.conf /etc/supervisor/supervisord.conf

ENV CAMERA_DEV_1 /dev/video0
ENV CAMERA_DEV_2 /dev/video2

ENV MJPEG_STREAMER_AUTOSTART_1 true
ENV MJPEG_STREAMER_AUTOSTART_2 false

ENV STREAMER_FLAGS_1 -y -n -r 640x480
ENV STREAMER_FLAGS_2 -y -n -r 640x480

EXPOSE 80

RUN apt-get remove --yes --purge make build-essential

RUN apt-get clean --yes
RUN apt-get autoremove --yes

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
