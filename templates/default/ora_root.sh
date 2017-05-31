# User specific environment and startup programs
PATH=$PATH:$HOME/bin

export PATH
unset JAVA_HOME
unset JAVA_PTH
export ORACLE_HOSTNAME=`hostname -s`
export ORACLE_SID="<%= @db_sid %>"
export ORACLE_BASE="<%= @oracle_base %>"
export ORACLE_HOME="<%= @oracle_home %>"
export GRID_HOME="<%= @grid_home %>"

export PATH=/usr/bin:$PATH:$ORACLE_HOME/bin:$GRID_HOME/bin
#export LD_LIBRARY_PATH=/lib:/usr/lib:$ORACLE_HOME/lib

#. /usr/local/bin/oraenv
