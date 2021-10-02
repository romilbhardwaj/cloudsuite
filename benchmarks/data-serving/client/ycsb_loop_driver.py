# This script is python 2.7 compatible to run it in the client container.
import argparse
import os
import subprocess
import time
# from k8s_utils import K8sUtils


class LoopDriver(object):
    """
    Runs a command in a loop in a shell window and writes the output
    to a folder.
    """

    def __init__(self, cmd, output_dir):
        """
        :param cmd: Command that will be run in a loop
        :param output_dir: Directory to write the output logs to
        """
        self.cmd = cmd
        self.output_dir = output_dir
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)

    def run_loop(self):
        while True:
            timestr = time.strftime("%Y%m%d-%H%M%S")
            temp_log_filename = "output_%s.INCOMPLETE" % timestr    # To avoid the client from reading incomplete logs, we label it as incomplete
            temp_log_filepath = os.path.join(self.output_dir, temp_log_filename)
            final_log_filename = "output_%s.log" % timestr  # This will be the final name of the log
            final_log_filepath = os.path.join(self.output_dir, final_log_filename)

            shell_cmd = "%s 2>&1 | tee %s" % (self.cmd, temp_log_filepath)

            # TODO: Add load here
            p = subprocess.call(shell_cmd, shell=True)

            # Remove incomplete tag once the log has been written.
            rename_cmd = "mv %s %s" % (temp_log_filepath, final_log_filepath)
            p = subprocess.call(rename_cmd, shell=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Runs a command in a loop.')
    parser.add_argument('--cmd', type=str, help='command to run in a loop.')
    parser.add_argument('--out-dir', type=str, help='Output dir to store logs in.')
    # parser.add_argument('--use-k8s', type=str, help='Output dir to store logs in.')

    args = parser.parse_args()
    cmd = args.cmd
    out_dir = args.out_dir

    ld = LoopDriver(cmd, out_dir)
    ld.run_loop()

