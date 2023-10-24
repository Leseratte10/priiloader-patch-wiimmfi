#
#  Copyright (c) 2020-2023 Leseratte10
#  This file is part of the Priiloader Wiimmfi patch hack by Leseratte.
#  https://github.com/Leseratte10/priiloader-patch-wiimmfi
#  
# 


# Build: 
# DOCKER_BUILDKIT=1 docker build -o output .
# for Windows, use 
# { "features": { "buildkit": true } }
# instead of the environment variable

# Build an Ubuntu Focal container
FROM ubuntu:focal as priiloader_ubuntu
ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/London"
RUN apt-get update -y && apt-get install -y \ 
    wget xz-utils make xxd git

# Build a container with devkitPPC as needed for the update
FROM priiloader_ubuntu as priiloader_dkp
ADD https://wii.leseratte10.de/devkitPro/file.php/devkitPPC-r33-1-linux.pkg.tar.xz /
RUN tar -xf /devkitPPC-r33-1-linux.pkg.tar.xz opt/devkitpro/devkitPPC --strip-components=1 && \
    mkdir /projectroot 

ENV DEVKITPRO=/devkitpro
ENV DEVKITPPC=/devkitpro/devkitPPC

# Now we have a container that has the dev environment set up. 
# Copy current folder into container
COPY . /projectroot/

##########################################################################
# Build a container that builds the hacks_hash.ini
FROM priiloader_dkp as priiloader_dkp_hacks
RUN export PATH=$PATH:/devkitpro/devkitPPC/bin && \
    cd /projectroot && \
    ./compile-wiimmfi-all.sh CI > /tmp/hacks_hash.ini


FROM scratch AS export-stage
COPY --from=priiloader_dkp_hacks /tmp/hacks_hash.ini /
