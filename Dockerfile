FROM debian

# see https://github.com/oddbloke/klaus-dockerfile
MAINTAINER Krzysztof Warzecha <kwarzecha7@gmail.com>

# see https://www.google.pl/search?q=eatmydata+docker
# This forces dpkg not to call sync() after package extraction and speeds up install
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup

# We don't need an apt cache in a container
RUN echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

# Make sure the package repository is up to date
RUN apt-get update && apt-get -qy install eatmydata

RUN eatmydata apt-get install -y -q \
    python-pip python-virtualenv git exuberant-ctags libpython2.7

RUN virtualenv /opt/klaus/venv
RUN /opt/klaus/venv/bin/pip install wheel

# you can also use locally built wheels by mounting volume with them under /wheelhouse and overriding that variable
ENV WHEELHOUSE_URL=https://hiciu.org/docker/klaus-dockerfile/wheelhouse/
ADD wheelhouse /wheelhouse

# install
RUN /opt/klaus/venv/bin/pip install --no-index --find-links=$WHEELHOUSE_URL \
    klaus markdown docutils uwsgi python-ctags

WORKDIR /opt/klaus
ADD wsgi_autoreload_ctags.py wsgi_autoreload_ctags.py

EXPOSE 8080

VOLUME /srv/git

ENV KLAUS_REPOS_ROOT /srv/git/
ENV KLAUS_SITE_NAME "klaus"

# you can set this to "none" or "tags-and-branches"
# ee tags-and-brancheshttps://github.com/jonashaag/klaus/wiki/Enable-ctags-support
ENV KLAUS_CTAGS_POLICY "tags-and-branches"

# uwsgi will switch to that uid before running klaus
ENV UWSGI_SETUID 1000

ENV UWSGI_WSGI_FILE wsgi_autoreload_ctags.py

# feel free to override these
CMD /opt/klaus/venv/bin/uwsgi --uid $UWSGI_SETUID --wsgi-file $UWSGI_WSGI_FILE --http 0.0.0.0:8080 --processes 4 --threads 2
