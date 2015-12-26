from klaus.contrib.wsgi_autoreload import make_autoreloading_app
import os
import ldap3
from base64 import b64decode
from expiringdict import ExpiringDict


def add_auth(app):
    auth_cache = ExpiringDict(max_len=100, max_age_seconds=120)

    def call(env, start_response):
        def return_401(message='Please login to Klaus'):
            start_response('401 Unauthorized', [
                ('content-type', 'text/plain'),
                ('WWW-Authenticate', 'Basic realm="%s"' % message)
            ])
            return ['No auth']

        if 'HTTP_AUTHORIZATION' not in env:
            return return_401('Please login to Klaus')

        # was authenticated during last few minutes?
        if env['HTTP_AUTHORIZATION'] in auth_cache:
            env['REMOTE_USER'] = auth_cache[env['HTTP_AUTHORIZATION']]
            # update ttl
            auth_cache[env['HTTP_AUTHORIZATION']] = env['REMOTE_USER']

            return app(env, start_response)

        # try to authenticate via ldap
        type, header = env['HTTP_AUTHORIZATION'].split(' ', 1)
        if type != 'Basic':
            return return_401('Incorrect authorization type. '
                              'Your browser does understand HTTP BASIC AUTH?')

        user, password = b64decode(header).decode('UTF-8').split(':', 1)

        conn = ldap3.Connection(
            ldap3.Server(os.environ['LDAP_SERVER']),
            user=user,
            password=password,
            lazy=False,
            read_only=True,
            auto_referrals=False
        )

        if not conn.bind():
            return return_401('Incorrect authentication data'
                              ' (bind failed)')

        if not conn.search(
            os.environ['LDAP_SEARCH_BASE'],
            os.environ.get(
                'LDAP_SEARCH_FILTER', '(userPrincipalName=%s)') % user,
            attributes=['cn', 'userPrincipalName']
        ):
            return return_401('Incorrect authentication data'
                              ' (search failed)')

        if len(conn.entries) != 1:
            return return_401('Incorrect authentication data'
                              ' (search returned != 1 entries)')

        env['REMOTE_USER'] = conn.entries[0].userPrincipalName

        # remember
        auth_cache[env['HTTP_AUTHORIZATION']] = env['REMOTE_USER']

        return app(env, start_response)
    return call

application = add_auth(make_autoreloading_app(
    os.environ['KLAUS_REPOS_ROOT'],
    os.environ['KLAUS_SITE_NAME'],
    os.environ.get('KLAUS_USE_SMARTHTTP'),
    ctags_policy=os.environ.get('KLAUS_CTAGS_POLICY', 'none'),
))
