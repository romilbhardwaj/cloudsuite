# This script is python 2.7 compatible to run it in the client container.
import argparse
import os
import subprocess
import time

from k8s_utils import K8sUtils

BASE_CMD = "/ycsb/bin/ycsb run cassandra-cql -s -p readproportion=1 -p updateproportion=0 -P /ycsb/workloads/workloada -p hdrhistogram.percentiles=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99"
CONN_SCALING_FACTOR = 1

class YCSBLoopDriver(object):
    """
    Runs YCSB client in a loop in a shell window and writes the output
    to a folder.
    """
    def __init__(self,
                 base_cmd,
                 output_dir,
                 use_k8s,
                 recordcount,
                 operationcount,
                 threadcount,
                 server_ips = None,
                 ):
        """
        :param cmd: Base command that will be run in a loop
        :param output_dir: Directory to write the output logs to
        """
        self.base_cmd = base_cmd
        self.output_dir = output_dir
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
        self.use_k8s = use_k8s
        self.recordcount = recordcount
        self.operationcount = operationcount
        self.threadcount = threadcount
        self.server_ips = server_ips

        if self.use_k8s:
            from k8s_utils import K8sUtils
            self.k8s = K8sUtils()


    def get_hosts_arg(self):
        if self.use_k8s:
            # Use the first IPs
            host_ips = self.k8s.get_endpoint_ips(self.server_ips[0])
            host_ips_csv = ",".join(host_ips)
        else:
            assert self.server_ips, "Use_k8s was not specified and server_ips is {}!".format(self.server_ips)
            host_ips_csv = self.server_ips
        if not host_ips_csv:
            raise ValueError("No IP in host_ips_csv.")
        self.last_host_count = len(host_ips_csv.split(","))
        hosts_arg = "-p hosts={}".format(host_ips_csv)
        return hosts_arg

    def get_threadcount_arg(self):
        conn_count = self.threadcount*CONN_SCALING_FACTOR   # Cassandra connections should scale with threads?
        threadcount_arg = "-p threads={} -p cassandra.coreconnections={} -p cassandra.maxconnections={}".format(self.threadcount, conn_count, conn_count)
        return threadcount_arg

    def get_operationcount_arg(self):
        operationcount_arg = "-p operationcount={}".format(self.operationcount)
        return operationcount_arg

    def get_recordcount_arg(self):
        recordcount_arg = "-p recordcount={}".format(self.recordcount)
        return recordcount_arg

    def get_all_args(self):
        args = ""
        args += " " + self.get_hosts_arg()
        args += " " + self.get_recordcount_arg()
        args += " " + self.get_threadcount_arg()
        args += " " + self.get_operationcount_arg()
        return args

    def run_loop(self):
        while True:
            timestr = time.strftime("%Y%m%d-%H%M%S")
            temp_log_filename = "output_%s.INCOMPLETE" % timestr    # To avoid the client from reading incomplete logs, we label it as incomplete
            temp_log_filepath = os.path.join(self.output_dir, temp_log_filename)
            final_log_filename = "output_%s.log" % timestr  # This will be the final name of the log
            final_log_filepath = os.path.join(self.output_dir, final_log_filename)

            try:
                all_args = self.get_all_args()
            except ValueError as e:
                if self.use_k8s:
                    print("No IP for hosts was found in k8s. Maybe the deployments are starting. Sleeping for 10s and retrying afterwards.")
                    time.sleep(10)
                    continue
                else:
                    raise e
            else:
                cmd = self.base_cmd + all_args
                print("Running: {}".format(cmd))

                # Write allocation info to the first line and then append the log
                with open(temp_log_filepath, 'w') as f:
                    f.write("{}\n".format(self.last_host_count))

                shell_cmd = "%s 2>&1 | tee -a %s" % (cmd, temp_log_filepath)

                p = subprocess.call(shell_cmd, shell=True)

                # Remove incomplete tag once the log has been written.
                rename_cmd = "mv %s %s" % (temp_log_filepath, final_log_filepath)
                p = subprocess.call(rename_cmd, shell=True)

if __name__ == '__main__':
    print("======== YCSB Loop Driver ===========")
    parser = argparse.ArgumentParser(description='Runs YCSB in a loop.')
    parser.add_argument('--out-dir', type=str, help='Output dir to store logs in.')
    parser.add_argument('--use-k8s', action='store_true', help='Uses k8s to fetch server IPs. If used, please use the '
                                                               'service name in server-ips and it will be resolved by k8s api.'
                                                               ' If not used, you must specify the server IPs as comma separated str in the server-ips args')

    # ================= Client args =====================
    parser.add_argument('--server-ips', type=str, help='K8s service name or List of server IPs if not using k8s.')
    parser.add_argument('--recordcount', type=int, help='RECORDCOUNT arg to YCSB')
    parser.add_argument('--operationcount', type=int, help='RECORDCOUNT arg to YCSB')
    parser.add_argument('--threadcount', type=int, help='THREADCOUNT arg to YCSB')

    args = parser.parse_args()
    out_dir = args.out_dir
    use_k8s = args.use_k8s
    server_ips = args.server_ips.split(",")
    recordcount = args.recordcount
    operationcount = args.operationcount
    threadcount = args.threadcount

    print("Got args: {}".format(args))

    ld = YCSBLoopDriver(BASE_CMD,
                        output_dir=out_dir,
                        use_k8s=use_k8s,
                        recordcount=recordcount,
                        operationcount=operationcount,
                        threadcount=threadcount,
                        server_ips=server_ips)
    ld.run_loop()

