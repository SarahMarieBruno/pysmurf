import pysmurf

S = pysmurf.SmurfControl(make_logfile=False,setup=False,epics_root='test_epics',cfg_file='/usr/local/controls/Applications/smurf/pysmurf/pysmurf/cfg_files/experiment_fp28_smurfsrv03.cfg')

import time
while True:
    S.print_amplifier_biases()
    time.sleep(1)
