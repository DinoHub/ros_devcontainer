# build x86_64 or amd64 image with ./build.sh. build arm64 image with ./build_arm.sh (requires docker buildx)

# start container with ./run.sh

# FROM dustynv/ros:noetic-ros-base-l4t-r32.5.0

## Base layer for docker image
## from https://hub.docker.com/layers/ros/library/ros/noetic-ros-core-bionic/images/sha256-d2e788898450a73cde929eaeea33d2bb44225cc3d1ab16534fb2afe8a9bdd5e9?context=explore
# for amd64 (barebones ros - no rviz, no git)
FROM osrf/ros:noetic-desktop-full
# # for arm64
# FROM ros@sha256:d2e788898450a73cde929eaeea33d2bb44225cc3d1ab16534fb2afe8a9bdd5e9

SHELL ["/bin/bash", "-c"]


## GPU/ display support
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,graphics,utility

## Install dependencies
## splitting installation into different layers so inserting new dependencies and rebuilding does not take bloody forever
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
  build-essential \
  vim \
  tmux \
  wget \
  unzip \
  git \
  gdb \
  cmake 

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
  python3-rosdep \
  ros-noetic-pcl-ros \
  pcl-tools \
  python3-pcl \
  ros-noetic-eigen-conversions \
  libarmadillo-dev \
  libdynamic-reconfigure-config-init-mutex-dev \
  libpcl-conversions-dev \
  ros-noetic-rviz 

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
  ros-noetic-cv-bridge \
  ros-noetic-mavros*\
  ros-noetic-tf2-sensor-msgs \
  ros-noetic-tf2-geometry-msgs 

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
  libdw-dev \
  gcc-9 \
  g++-9 \
  python-pyinotify \
  python3-pip \
  protobuf-compiler \
  libprotoc-dev \
  python3-catkin-tools \
  sudo \
  xterm 

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
  ros-noetic-rqt \
  ros-noetic-rqt-common-plugins \
  gedit \
  nautilus \
  xcb

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
  nano

WORKDIR ${HOME}

# install geographiclib dependency for mavros
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh
RUN chmod +x install_geographiclib_datasets.sh
RUN ./install_geographiclib_datasets.sh
RUN rm install_geographiclib_datasets.sh

# install nlopt
RUN wget https://github.com/stevengj/nlopt/archive/v2.7.1.tar.gz
RUN tar xf v2.7.1.tar.gz
RUN cd nlopt-2.7.1 && cmake . && make && make install && rm ../v2.7.1.tar.gz
### Update LD_LIBRARY_PATH so NLOPT can be found
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib"

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# ********************************************************
# * Anything else you want to do like clean up goes here *
# ********************************************************

# [Optional] Set the default user. Omit if you want to keep the default as root.
USER $USERNAME
RUN mkdir -p /home/$USERNAME/ws/src


## YOLOX
RUN python3 -m pip install -U pip
RUN python3 -m pip install pyyaml rospkg simple-pid pyinotify gdown

RUN echo "export PATH=/home/$USERNAME/.local/bin:$PATH" >> ~/.bashrc 


## Set up bashrc
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
RUN echo "source ~/ws/devel/setup.bash" >> ~/.bashrc

WORKDIR /home/$USERNAME/ws







