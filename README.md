klaus-dockerfile
================

A Dockerfile for klaus, a simple git web viewer

building
========

building wheels
---------------

This step is optional. You can use pre-built wheels from https://hiciu.org/docker/klaus-dockerfile/wheelhouse/, you can also build your own.

To build your own wheels:

    docker build -f build-wheels.Dockerfile -t build-wheels .
    docker run -v $(pwd)/wheelhouse:/home/build/wheelhouse build-wheels

Wheels should appear in your `wheelhouse/` directory.

building image
--------------

    docker build -t my_klaus_image .

If you want to use your own wheels:

    docker build -t my_klaus_image --build-arg WHEELHOUSE_URL=file:///wheelhouse .

See Dockerfile for more informations.

running
=======

using ctags
-----------

To enable ctags set `KLAUS_CTAGS_POLICY` variable to `tags-and-branches`.

    docker run -p ... --volume ... --env KLAUS_CTAGS_POLICY=tags-and-branches my_klaus_image

I'm not sure if this will play nicely with multiple processes and threads managed by uwsgi. If you run into issues please create new bug report and use this as a workaround:

    docker run -p ... --volume ... --env KLAUS_CTAGS_POLICY=tags-and-branches my_klaus_image /opt/klaus/venv/bin/uwsgi --wsgi-file ... --http ... --enable-threads

You can find full command in Dockerfile. `--enable-threads` is needed to initialize Python's GIL (see http://uwsgi-docs.readthedocs.org/en/latest/ThingsToKnow.html), but by default even with `--enable-threads` there will be only one process and only one thread.

using ldap
----------

This was tested with windows server 2012r2 active directory as ldap server. I'm not really sure if this can be useful to other people.

Authentication is handled via `wsgi_autoreload_ctags_ldap.py` middleware (set `wsgi_autoreload_ctags_ldap.py` to `wsgi_autoreload_ctags_ldap.py`). You need to set `LDAP_SERVER` and `LDAP_SEARCH_BASE` variables. Feel free to modify that middleware, you can use modified one without rebuilding whole image; just mount it with `--volume` option.
