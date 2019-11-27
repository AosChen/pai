import os

from kubernetes import client, config

KUBE_APISERVER_ADDRESS = "KUBE_APISERVER_ADDRESS"


class Collector:
    def __init__(self):
        kube_apiserver_address = os.environ.get(KUBE_APISERVER_ADDRESS)
        if kube_apiserver_address:
            self.kube_apiserver_address = os.environ.get(KUBE_APISERVER_ADDRESS)
            config.load_kube_config(client_configuration={})
        else:
            config.load_incluster_config()

    def collect_pods_info(self):
        return client.CoreV1Api().list_pod_for_all_namespaces()

    def collect_nodes_info(self):
        return client.CoreV1Api().list_node()

    def collect_orphan_priority_class(self):
        # Here we list the priory classes
        return client.AppsV1beta1Api()
