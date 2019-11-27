import argparse
import faulthandler
import logging
import os
import signal
import sys
import threading

import prometheus_client
from prometheus_client.twisted import MetricsResource
from twisted.internet import reactor
from twisted.web.resource import Resource
from twisted.web.server import Site

LOGGER = logging.getLogger(__name__)


def get_logging_level():
    mapping = {
        "DEBUG": logging.DEBUG,
        "INFO": logging.INFO,
        "WARNING": logging.WARNING
    }

    result = logging.INFO

    if os.environ.get("LOGGING_LEVEL") is not None:
        level = os.environ["LOGGING_LEVEL"]
        result = mapping.get(level.upper())
        if result is None:
            sys.stderr.write("unknown logging level " + level +
                             ", default to INFO\n")
            result = logging.INFO

    return result


def try_remove_old_prom_file(path) -> None:
    """ try to remove old prom file, since old prom file are exposed by node-exporter,
    if we do not remove, node-exporter will still expose old metrics """
    if os.path.isfile(path):
        try:
            os.remove(path)
        except OSError:
            LOGGER.warning("can not remove old prom file %s",
                           path,
                           exc_info=True)


class AtomicRef(object):
    """ a thread safe way to store and get object, should not modify data get from this ref """
    def __init__(self):
        self.data = None
        self.lock = threading.RLock()

    def get_and_set(self, new_data):
        data = None
        with self.lock:
            data, self.data = self.data, new_data
        return data

    def get(self):
        with self.lock:
            return self.data


class HealthResource(Resource):
    def render_GET(self, request) -> bytes:
        request.setHeader("Content-Type", "text/html; charset=utf-8")
        return "<html>Ok</html>".encode("utf-8")


class CustomCollector(object):
    def __init__(self, atomic_ref):
        self.atomic_ref = atomic_ref

    def collect(self):
        data = self.atomic_ref.get()

        if data is not None:
            for datum in data:
                yield datum
        else:
            # https://stackoverflow.com/a/6266586
            # yield nothing
            return
            # yield


def start_watchdog(args) -> None:
    LOGGER.info("Watchdog Sarting")
    log_dir = args.log
    try_remove_old_prom_file(log_dir)
    atomic_ref = AtomicRef()

    prometheus_client.REGISTRY.register(CustomCollector(atomic_ref))

    root = Resource()
    root.putChild(b"metrics", MetricsResource())
    root.putChild(b"healthz", HealthResource())

    factory = Site(root)
    reactor.listenTCP(int(args.port), factory)
    reactor.run()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log",
                        "-l",
                        help="log dir to store log",
                        default="/datastorage/prometheus")
    parser.add_argument("--interval",
                        "-i",
                        help="interval between two collection",
                        default="30")
    parser.add_argument("--port",
                        "-p",
                        help="port to expose metrics",
                        default="9101")
    args = parser.parse_args()
    logging.basicConfig(
        format=
        "%(asctime)s - %(levelname)s - %(filename)s:%(lineno)s - %(message)s",
        level=get_logging_level())

    faulthandler.register(signal.SIGTRAP, all_threads=True, chain=False)
    start_watchdog(args)


if __name__ == "__main__":
    main()
