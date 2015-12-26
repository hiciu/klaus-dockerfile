FROM debian

MAINTAINER Krzysztof Warzecha <kwarzecha7@gmail.com>

# see https://www.google.pl/search?q=eatmydata+docker
# This forces dpkg not to call sync() after package extraction and speeds up install
# (we are also using eatmydata for that, I'm not sure if this is nessecary)
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup

# do not install recommended / suggested packages, always assume "yes", do not cache packages
ADD apt-config /etc/apt/apt.conf.d/docker-config

RUN apt-get update && apt-get install eatmydata

RUN eatmydata apt-get install \
    virtualenv python-dev git exuberant-ctags build-essential

RUN useradd --create-home $USERADD_ARGS build
USER build

WORKDIR /home/build

RUN virtualenv /home/build
RUN /home/build/bin/pip install wheel

VOLUME /home/build/wheelhouse
CMD /home/build/bin/pip wheel klaus markdown docutils uwsgi python-ctags
