import os
import logging
from typing import List

from kubernetes import client, config, watch

logger = logging.getLogger(__name__)

MAX_RETRY_COUNT = 3

def load_k8s_config():
    if os.getenv('KUBERNETES_SERVICE_HOST'):
        logger.debug('Detected running inside cluster. Using incluster auth.')
        config.load_incluster_config()
    else:
        logger.debug('Using kube auth.')
        config.load_kube_config()

class K8sUtils(object):
    def __init__(self):
        self.authenticate()

    def authenticate(self):
        load_k8s_config()
        self.coreapi = client.CoreV1Api()
        self.appsapi = client.AppsV1Api()

    def get_endpoint_ips(self,
                         svc_name: str,
                         namespace: str = "default") -> List[str]:
        """
        Returns a list of IP addresses backing the given service.
        :param svc_name:
        :param namespace:
        :return:
        """
        success = False
        retry_count = 0
        while not success:
            try:
                endpoints = k8s.coreapi.read_namespaced_endpoints(name=svc_name, namespace=namespace)
                success = True
            except client.exceptions.ApiException as e:
                if retry_count > MAX_RETRY_COUNT:
                    logger.error(f"Call failed despite {MAX_RETRY_COUNT} retries. Giving up.")
                    raise e
                # Retry with new auth
                logger.error(f"Authentication failed. Retrying. {e}")
                self.authenticate()
                retry_count += 1

        all_ip_addresses = []
        for subset in endpoints.subsets:
            for addr in subset.addresses:
                all_ip_addresses.append(addr.ip)
        return list(set(all_ip_addresses))

if __name__ == '__main__':
    k8s = K8sUtils()
    s = k8s.get_endpoint_ips("cassandra-server-svc")