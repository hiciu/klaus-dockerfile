FROM debian

MAINTAINER Krzysztof Warzecha <kwarzecha7@gmail.com>

# see https://www.google.pl/search?q=eatmydata+docker
# This forces dpkg not to call sync() after package extraction and speeds up install
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup

# We don't need an apt cache in a container
RUN echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

# Make sure the package repository is up to date
RUN apt-get update && apt-get -qy install eatmydata

RUN eatmydata apt-get install -y -q \
    python-pip python-dev python-virtualenv git exuberant-ctags

RUN useradd --create-home $USERADD_ARGS build
USER build

WORKDIR /home/build

RUN virtualenv /home/build
RUN /home/build/bin/pip install wheel

VOLUME /home/build/wheelhouse
ENTRYPOINT /home/build/bin/pip wheel klaus markdown docutils uwsgi python-ctags
