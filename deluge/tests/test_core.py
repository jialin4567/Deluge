from twisted.trial import unittest
from twisted.internet import reactor
from twisted.python.failure import Failure
from twisted.web.http import FORBIDDEN
from twisted.web.resource import Resource
from twisted.web.server import Site
from twisted.web.static import File

try:
    from hashlib import sha1 as sha
except ImportError:
    from sha import sha

import os
import common
import warnings
rpath = common.rpath

from deluge.core.rpcserver import RPCServer
from deluge.core.core import Core
warnings.filterwarnings("ignore", category=RuntimeWarning)
from deluge.ui.web.common import compress
warnings.resetwarnings()
import deluge.component as component
import deluge.error

class TestCookieResource(Resource):

    def render(self, request):
        if request.getCookie("password") != "deluge":
            request.setResponseCode(FORBIDDEN)
            return

        request.setHeader("Content-Type", "application/x-bittorrent")
        return open(rpath("ubuntu-9.04-desktop-i386.iso.torrent")).read()

class TestPartialDownload(Resource):

    def render(self, request):
        data = open(rpath("ubuntu-9.04-desktop-i386.iso.torrent")).read()
        request.setHeader("Content-Type", len(data))
        request.setHeader("Content-Type", "application/x-bittorrent")
        if request.requestHeaders.hasHeader("accept-encoding"):
            return compress(data, request)
        return data

class TestRedirectResource(Resource):

    def render(self, request):
        request.redirect("/ubuntu-9.04-desktop-i386.iso.torrent")
        return ""

class TopLevelResource(Resource):

    addSlash = True

    def __init__(self):
        Resource.__init__(self)
        self.putChild("cookie", TestCookieResource())
        self.putChild("partial", TestPartialDownload())
        self.putChild("redirect", TestRedirectResource())
        self.putChild("ubuntu-9.04-desktop-i386.iso.torrent", File(common.rpath("ubuntu-9.04-desktop-i386.iso.torrent")))

class CoreTestCase(unittest.TestCase):
    def setUp(self):
        common.set_tmp_config_dir()
        self.rpcserver = RPCServer(listen=False)
        self.core = Core()
        return component.start().addCallback(self.startWebserver)

    def startWebserver(self, result):
        self.website = Site(TopLevelResource())
        self.webserver = reactor.listenTCP(51242, self.website)
        return result

    def tearDown(self):

        def on_shutdown(result):
            component._ComponentRegistry.components = {}
            del self.rpcserver
            del self.core
            return self.webserver.stopListening()

        return component.shutdown().addCallback(on_shutdown)

    def test_add_torrent_file(self):
        options = {}
        filename = os.path.join(os.path.dirname(__file__), "test.torrent")
        import base64
        torrent_id = self.core.add_torrent_file(filename, base64.encodestring(open(filename).read()), options)

        # Get the info hash from the test.torrent
        from deluge.bencode import bdecode, bencode
        info_hash = sha(bencode(bdecode(open(filename).read())["info"])).hexdigest()

        self.assertEquals(torrent_id, info_hash)

    def test_add_torrent_url(self):
        url = "http://localhost:51242/ubuntu-9.04-desktop-i386.iso.torrent"
        options = {}
        info_hash = "60d5d82328b4547511fdeac9bf4d0112daa0ce00"

        d = self.core.add_torrent_url(url, options)
        d.addCallback(self.assertEquals, info_hash)
        return d

    def test_add_torrent_url_with_cookie(self):
        url = "http://localhost:51242/cookie"
        options = {}
        headers = { "Cookie" : "password=deluge" }
        info_hash = "60d5d82328b4547511fdeac9bf4d0112daa0ce00"

        d = self.core.add_torrent_url(url, options)
        d.addCallbacks(self.fail, self.assertIsInstance, errbackArgs=(Failure,))

        d = self.core.add_torrent_url(url, options, headers)
        d.addCallbacks(self.assertEquals, self.fail, callbackArgs=(info_hash,))

        return d

    def test_add_torrent_url_with_redirect(self):
        url = "http://localhost:51242/redirect"
        options = {}
        info_hash = "60d5d82328b4547511fdeac9bf4d0112daa0ce00"

        d = self.core.add_torrent_url(url, options)
        d.addCallback(self.assertEquals, info_hash)

        return d

    def test_add_torrent_url_with_partial_download(self):
        url = "http://localhost:51242/partial"
        options = {}
        info_hash = "60d5d82328b4547511fdeac9bf4d0112daa0ce00"

        d = self.core.add_torrent_url(url, options)
        d.addCallback(self.assertEquals, info_hash)

        return d

    def test_add_magnet(self):
        info_hash = "60d5d82328b4547511fdeac9bf4d0112daa0ce00"
        import deluge.common
        uri = deluge.common.create_magnet_uri(info_hash)
        options = {}

        torrent_id = self.core.add_torrent_magnet(uri, options)
        self.assertEquals(torrent_id, info_hash)

    def test_remove_torrent(self):
        options = {}
        filename = os.path.join(os.path.dirname(__file__), "test.torrent")
        import base64
        torrent_id = self.core.add_torrent_file(filename, base64.encodestring(open(filename).read()), options)

        self.assertRaises(deluge.error.InvalidTorrentError, self.core.remove_torrent, "torrentidthatdoesntexist", True)

        ret = self.core.remove_torrent(torrent_id, True)

        self.assertTrue(ret)
        self.assertEquals(len(self.core.get_session_state()), 0)

    def test_get_session_status(self):
        status = self.core.get_session_status(["upload_rate", "download_rate"])
        self.assertEquals(type(status), dict)
        self.assertEquals(status["upload_rate"], 0.0)

    def test_get_cache_status(self):
        status = self.core.get_cache_status()
        self.assertEquals(type(status), dict)
        self.assertEquals(status["write_hit_ratio"], 0.0)
        self.assertEquals(status["read_hit_ratio"], 0.0)

    def test_get_free_space(self):
        space = self.core.get_free_space(".")
        self.assertTrue(type(space) in (int, long))
        self.assertTrue(space >= 0)
        self.assertEquals(self.core.get_free_space("/someinvalidpath"), 0)

    def test_test_listen_port(self):
        d = self.core.test_listen_port()

        def result(r):
            self.assertTrue(r in (True, False))

        d.addCallback(result)
        return d
