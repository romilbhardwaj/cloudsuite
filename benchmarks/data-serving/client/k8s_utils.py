import os

from kubernetes import client, config, watch

MAX_RETRY_COUNT = 3

def load_k8s_config():
    if os.getenv('KUBERNETES_SERVICE_HOST'):
        print('Detected running inside cluster. Using incluster auth.')
        config.load_incluster_config()
    else:
        print('Using kube auth.')
        config.load_kube_config()

class K8sUtils(object):
    def __init__(self):
        self.authenticate()

    def authenticate(self):
        load_k8s_config()
        self.coreapi = client.CoreV1Api()
        self.appsapi = client.AppsV1Api()

    def get_endpoint_ips(self,
                         svc_name,
                         namespace="default"):
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
                endpoints = self.coreapi.read_namespaced_endpoints(name=svc_name, namespace=namespace)
                success = True
            except client.exceptions.ApiException as e:
                if retry_count > MAX_RETRY_COUNT:
                    print("Call failed despite {} retries. Giving up.".format(MAX_RETRY_COUNT))
                    raise e
                # Retry with new auth
                print("Authentication failed. Retrying. {}".format(e))
                self.authenticate()
                retry_count += 1

        all_ip_addresses = []
        for subset in endpoints.subsets:
            if subset.addresses is None:
                continue
            else:
                for addr in subset.addresses:
                    all_ip_addresses.append(addr.ip)
        return list(set(all_ip_addresses))

if __name__ == '__main__':
    k8s = K8sUtils()
    s = k8s.get_endpoint_ips("cassandra-server-svc")