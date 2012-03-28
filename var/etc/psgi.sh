#!/bin/sh
# @(#)$Id: psgi.sh 1213 2011-06-22 00:28:06Z pjf $

### BEGIN INIT INFO
# Provides: App::Munchies
# Required-Start: $local_fs $network $named
# Required-Stop: $local_fs $network $named
# Should-Start:
# Should-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start/Stop a Catalyst application under Plack/Starman
### END INIT INFO

# Initialise

APPDIR=$(basename ${0})

test -f /etc/default/${APPDIR} && . /etc/default/${APPDIR}
test -n "${APPLDIR}" || exit 0;

. /lib/lsb/init-functions

# Private functions

_check_compile() {
   local cmd; cmd="cd ${APPLDIR} ; perl -Ilib -M${APPNAME} -ce1 2>/dev/null"

   if [ -n "${USER}" ]; then
      ( su ${USER} -c "${cmd}" ) && return 1
   else
      ( ${cmd} ) && return 1
   fi

   return 0
}

_check_running() {
   [ -s ${PIDFILE} ] && kill -0 $(cat ${PIDFILE}) 2>/dev/null
}

_start() {
   local args; args="${PLACKARGS} --access-log ${LOGFILE} ${PSGIFILE}"

   start-stop-daemon --start --quiet --pidfile ${PIDFILE}  \
      --make-pidfile --chdir ${APPLDIR} ${USER:+"--chuid"} ${USER} \
      ${GROUP:+"--group"} ${GROUP} --background --exec ${PLACKUP} -- ${args}

   for i in 1 2 3 4 5 ; do
      sleep 1 ; _check_running && return 0
   done

   return 1
}

# Public functions

start() {
   local rc; log_daemon_msg "Starting ${APPNAME}" " "

   if _check_running ; then
      log_failure_msg "Already running"
      log_end_msg 1
      exit 1
   fi

   if _check_compile ; then
      log_failure_msg "Error detected; not restarting"
      log_end_msg 1
      exit 1
   fi

   rm -f ${PIDFILE} 2>/dev/null; _start; rc=${?}
   log_end_msg ${rc}
   return ${rc}
}

stop() {
   local rc; log_daemon_msg "Stopping ${APPNAME}" " "

   start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
      --retry 1 ${USER:+"--user"} ${USER} ; rc=${?}

   [ ${rc} -eq 0 ] && rm -f ${PIDFILE} 2>/dev/null
   log_end_msg ${rc}
   return ${rc}
}

# Main

case "${1}" in
   start)
      start
      ;;
   stop)
      stop
      ;;
   restart|force-reload)
      stop ; start
      ;;
   *) echo "Usage: ${0} {start|stop|restart}"
      exit 1
esac

exit ${?}
