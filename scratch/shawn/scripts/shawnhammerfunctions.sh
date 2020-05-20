#!/bin/bash

matching_dockers () {
    # the $1 in the single quotes doesn't get replaced with the input
    # arg ; it's the first column of the grep output
    if [ -z "$(docker ps | grep $1 | awk '{print $1}')" ] ; then
	return 0
    else
	return 1
    fi
}

stop_pyrogue () {
    # stop pyrogue dockers
    echo "-> Stopping slot $1 pyrogue docker $2";
    cd $2;
    ./stop.sh -N $1;
}

# I hate this
wait_for_docker () {
    latest_docker=`docker ps -a -n 1 -q`    
}

start_slot_tmux_and_pyrogue() {
    slot_number=$1
    pyrogue=$2
    tmux new-window -t ${tmux_session_name}:${slot_number}
    tmux rename-window -t ${tmux_session_name}:${slot_number} smurf_slot${slot_number}
    tmux send-keys -l -t ${tmux_session_name}:${slot_number} C-b S-p
    tmux send-keys -t ${tmux_session_name}:${slot_number} 'cd '${pyrogue} C-m
    tmux send-keys -t ${tmux_session_name}:${slot_number} './run.sh -N '${slot_number}'; sleep 5; docker logs smurf_server_s'${slot_number}' -f' C-m
}

is_slot_pyrogue_up() {
    slot_number=$1
    if [[ -z `docker ps  | grep smurf_server_s${slot_number}`  ]]; then
	#echo '-> smurf_server_s'${slot_number}' docker started.'
	return 1
    fi
    return 0
}

is_slot_gui_up() {
    slot_number=$1
    tmux capture-pane -pt ${tmux_session_name}:${slot_number} | grep -q "Starting GUI..."
    return $?
}

start_slot_pysmurf() {
    slot_number=$1
    
    # start pysmurf in a split window and initialize the carrier
    tmux split-window -v -t ${tmux_session_name}:${slot_number}
    tmux send-keys -t ${tmux_session_name}:${slot_number} 'cd '${pysmurf} C-m
    tmux send-keys -t ${tmux_session_name}:${slot_number} './run.sh shawnhammer_pysmurf_s'${slot_number} C-m
    sleep 1

    tmux send-keys -t ${tmux_session_name}:${slot_number} 'ipython3 -i '${pysmurf_init_script}' '${slot_number} C-m
}

start_slot_tmux_serial () {
    slot_number=$1
    pyrogue=$2

    pysmurf_docker0=`docker ps -a | grep pysmurf | grep -v pysmurf_s${slot_number} | head -n 1 | awk '{print $1}'`
    
    tmux new-window -t ${tmux_session_name}:${slot_number}
    tmux rename-window -t ${tmux_session_name}:${slot_number} smurf_slot${slot_number}
    tmux send-keys -t ${tmux_session_name}:${slot_number} 'cd '$2 C-m
    tmux send-keys -t ${tmux_session_name}:${slot_number} './run.sh -N '${slot_number}'; sleep 5; docker logs smurf_server_s'${slot_number}' -f' C-m


    echo '-> Waiting for smurf_server_s'${slot_number}' docker to start.'
    while [[ -z `docker ps  | grep smurf_server_s${slot_number}`  ]]; do
	sleep 1
    done
    echo '-> smurf_server_s'${slot_number}' docker started.'    
    
    echo '-> Waiting for smurf_server_s'${slot_number}' GUI to come up.'    
    sleep 2
    grep -q "Starting GUI" <(docker logs smurf_server_s${slot_number} -f)
    
    # start pysmurf in a split window and initialize the carrier
    tmux split-window -v -t ${tmux_session_name}:${slot_number}
    tmux send-keys -t ${tmux_session_name}:${slot_number} 'cd '${pysmurf} C-m
    tmux send-keys -t ${tmux_session_name}:${slot_number} './run.sh shawnhammer_pysmurf_s'${slot_number} C-m
    sleep 1

#    tmux run-shell -t ${tmux_session_name}:${slot_number} /home/cryo/tmux-logging/scripts/toggle_logging.sh
    tmux send-keys -t ${tmux_session_name}:${slot_number} 'ipython3 -i '${pysmurf_init_script}' '${slot_number} C-m

    ## not the safest way to do this.  If someone else starts a
    ## pysmurf docker, will satisfy this condition.  Not even sure why
    ## this is even needed - why is there so much latency on
    ## smurf-srv03 between starting a docker and it showing up in
    ## docker ps?
    echo "pysmurf_docker0=$pysmurf_docker0"
    latest_pysmurf_docker=`docker ps -a | grep pysmurf | grep -v pysmurf_s${slot_number} | head -n 1 | awk '{print $1}'`
    echo "latest_pysmurf_docker=$latest_pysmurf_docker"	    
#    while [ "$pysmurf_docker0" == "$latest_pysmurf_docker" ]; do
#    	latest_pysmurf_docker=`docker ps -a | grep pysmurf | grep -v pysmurf_s${slot_number} | head -n 1 | awk '{print $1}'`
#    	sleep 1
#	echo "latest_pysmurf_docker=$latest_pysmurf_docker"		
#    done
    
    # after running this, can run
    # pysmurf_docker=`docker ps -n 1 -q`
    # to hex of most recently created docker.
}


run_pysmurf_setup () {
    slot_number=$1
    tmux send-keys -t ${tmux_session_name}:${slot_number} 'S = pysmurf.SmurfControl(epics_root=epics_prefix,cfg_file=config_file,setup=True,make_logfile=False,shelf_manager="'${shelfmanager}'")' C-m
}

is_slot_pysmurf_setup_complete() {
    slot_number=$1
    tmux capture-pane -pt ${tmux_session_name}:${slot_number} | grep -q "Done with setup"
    return $?
}

# right now, real dumb.  Assumes the active window in tmux is this
# slot's
config_pysmurf_serial () {
    slot_number=$1
    pysmurf_docker=$2
    
    tmux send-keys -t ${tmux_session_name}:${slot_number} 'S = pysmurf.SmurfControl(epics_root=epics_prefix,cfg_file=config_file,setup=True,make_logfile=False,shelf_manager="'${shelfmanager}'")' C-m
    
    # wait for setup to complete
    echo "-> Waiting for carrier setup (watching pysmurf docker ${pysmurf_docker})"
    # not clear why, but on smurf-srv03 need this wait or attempt to
    # wait until done with setup fails.
    sleep 2
    grep -q "Done with setup" <(docker logs $pysmurf_docker -f)
    echo "-> Carrier is configured"

    if [ "$disable_streaming" = true ] ; then    
	echo "-> Disable streaming (unless taking data)"
	tmux send-keys -t ${tmux_session_name}:${slot_number} 'S.set_stream_enable(0)' C-m
	sleep 2
    fi

    # write config
    if [ "$write_config" = true ] ; then
	sleep 2    
	tmux send-keys -t ${tmux_session_name}:${slot_number} 'S.set_read_all(write_log=True); S.write_config("/home/cryo/shawn/'${ctime}'_slot'${slot_number}'.yml")' C-m
	sleep 45
    fi

    if [ "$run_full_band_response" = true ] ; then    
	sleep 2
	echo "-> Running full band response across all configured bands."
	tmux send-keys -t ${tmux_session_name}:${slot_number} 'exec(open("scratch/shawn/full_band_response.py").read())' C-m    
	grep -q "Done running full_band_response.py." <(docker logs $pysmurf_docker -f)
    fi
    
    if [ "$run_half_band_test" = true ] ; then    
	sleep 2
	echo "-> Running half-band fill test"
	tmux send-keys -t ${tmux_session_name}:${slot_number} 'sys.argv[1]='${ctime}'; exec(open("scratch/shawn/half_band_filling_test.py").read())' C-m    
	grep -q "Done with half-band filling test." <(docker logs $pysmurf_docker -f)
    fi
    
    sleep 1
}
