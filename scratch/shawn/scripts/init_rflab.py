import os
import pysmurf
import matplotlib.pylab as plt
import numpy as np
import sys

config_file_path='/data/pysmurf_cfg/'

slot=int(sys.argv[1])
epics_prefix = 'smurf_server_s%d'%slot

if slot in [2,3,4,5,6,7]:
    config_file='experiment_rflab_thermal_testing_201907.cfg'
else:
    assert False,"There isn't a SMuRF carrier in slot %d right now!"%slot


config_file='experiment_rflab_thermal_testing_201907.cfg'
config_file=os.path.join(config_file_path,config_file)

S = pysmurf.SmurfControl(epics_root=epics_prefix,cfg_file=config_file,setup=False,make_logfile=False)

