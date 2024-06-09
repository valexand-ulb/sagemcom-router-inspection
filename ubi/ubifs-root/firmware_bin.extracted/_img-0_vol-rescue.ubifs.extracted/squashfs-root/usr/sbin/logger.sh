#!/bin/sh

prep_term()
{
        unset term_child_pid
        unset term_kill_needed
        unset process_name
        trap_with_arg 'handle_term' TERM INT USR1 USR2
}

trap_with_arg() {
    func="$1" ; shift
    for sig ; do
        trap "$func $sig" "$sig"
    done
}

handle_term()
{
        if [ "${term_child_pid}" ]; then
                kill -$1 "${term_child_pid}" 2>/dev/null
        else
                term_kill_needed="$1"
        fi
}

wait_term()
{
        term_child_pid=$(jobs -p)
        if [ "${term_kill_needed}" ]; then
                kill -"${term_kill_needed}" "${term_child_pid}" 2>/dev/null
        fi
        wait
        while [ -e /proc/${term_child_pid} ]; do
                wait
        done
}
prep_term
process_name=$1
shift
${*} 2>&1 | logger -t $process_name &
wait_term
