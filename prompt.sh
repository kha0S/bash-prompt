#!/bin/bash -e
# Filename:      custom_prompt.sh
# Maintainer:    Dave Vehrs 
# Last Modified: 27 Feb 2008 19:17:19 by Miguel Ramos

# Current Format: USER@HOST [dynamic section] { CURRENT DIRECTORY }$ 
# USER:      (also sets the base color for the prompt)
#   Red       == Root(UID 0) Login shell (i.e. sudo bash)
#   Light Red == Root(UID 0) Login shell (i.e. su -l or direct login)
#   Yellow    == Root(UID 0) priviledges in non-login shell (i.e. su)
#   Brown     == SU to user other than root(UID 0)
#   Green     == Normal user
# @:
#   Light Red == http_proxy environmental variable undefined.
#   Green     == http_proxy environmental variable configured.
# HOST:
#   Red       == Insecure remote connection (unknown type)
#   Yellow    == Insecure remote connection (Telnet)
#   Brown     == Insecure remote connection (RSH)
#   Cyan      == Secure remote connection (i.e. SSH)
#   Green     == Local session
# DYNAMIC SECTION:  
#     (If count is zero for any of the following, it will not appear)
#   [scr:#] ==== Number of detached screen sessions
#     Yellow    == 1-2
#     Red       == 3+
#   [bg:#]  ==== Number of backgrounded but still running jobs
#     Yellow    == 1-10
#     Red       == 11+
#   [stp:#] ==== Number of stopped (backgrounded) jobs
#     Yellow    == 1-2
#     Red       == 3+
# CURRENT DIRECTORY:     (truncated to 1/4 screen width)
#   Red       == Current user does not have write priviledges
#   Green     == Current user does have write priviledges
# NOTE:
#   1.  Displays message on day change at midnight on the line above the
#       prompt (Day changed to...). 
#   2.  Command is added to the history file each time you hit enter so its
#       available to all shells.

# Configure Colors:
COLOR_WHITE='\033[1;37m'
COLOR_LIGHTGRAY='033[0;37m'
COLOR_GRAY='\033[1;30m'
COLOR_BLACK='\033[0;30m'
COLOR_RED='\033[0;31m'
COLOR_LIGHTRED='\033[1;31m'
COLOR_GREEN='\033[0;32m'
COLOR_LIGHTGREEN='\033[1;32m'
COLOR_BROWN='\033[0;33m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_LIGHTBLUE='\033[1;34m'
COLOR_PURPLE='\033[0;35m'
COLOR_PINK='\033[1;35m'
COLOR_CYAN='\033[0;36m'
COLOR_LIGHTCYAN='\033[1;36m'
COLOR_DEFAULT='\033[0m'

#if [ `id -u` -gt 0 ]; then
    C1='[0;36m'
    C2='[1;36m'
    C3='[1;30m'
    C4='[0m'
#else
#    C1='[1;33m'
#    C2='[1;31m'
#    C3='[0;31m'
#    C4='[0m'
#fi

# Function to set prompt_command to.
function promptcmd () {
    history -a 
    local SSH_FLAG=0
    local TTY=$(tty | awk -F/dev/ '{print $2}')
    if [[ ${TTY} ]]; then 
        local SESS_SRC=$(who | grep "$TTY "  | awk '{print $6 }')
    fi
    
    # Titlebar
    case ${TERM} in 
        xterm*  )  
            local TITLEBAR='\[\033]0;\u@\h: { \w }  \007\]'
            ;;
        *       )  
            local TITLEBAR=''                               
            ;;
    esac
    PS1="${TITLEBAR}"
  
    # Test for day change.
    if [ -z $DAY ] ; then
        export DAY=$(date +%A)
    else
        local today=$(date +%A)
        if [ "${DAY}" != "${today}" ]; then
            PS1="${PS1}\n\[${COLOR_GREEN}\]Day changed to $(date '+%A, %d %B %Y').\n"
            export DAY=$today
       fi
    fi
   
    # User
    if [ ${UID} -eq 0 ] ; then
        if [ "${USER}" == "${LOGNAME}" ]; then
            if [[ ${SUDO_USER} ]]; then
                PS1="${PS1}\[${COLOR_LIGHTRED}\]\u"
            else
                PS1="${PS1}\[${COLOR_LIGHTRED}\]\u"
            fi
        else                               
            PS1="${PS1}\[${COLOR_YELLOW}\]\u"
        fi
    else
        #if [ ${USER} == ${LOGNAME} ]; then     
            PS1="${PS1}\[${COLOR_YELLOW}\]\u"
        #else                               
        #    PS1="${PS1}\[${COLOR_BROWN}\]\u"
        #fi
    fi

    # HTTP Proxy var configured or not
    if [ -n "$http_proxy" ] ; then
        PS1="${PS1}\[${COLOR_GREEN}\]@"
    else                               
        PS1="${PS1}\[${COLOR_LIGHTRED}\]@"
    fi

    # Host

    if [[ ${SSH_CLIENT} ]] || [[ ${SSH2_CLIENT} ]]; then 
        SSH_FLAG=1
    fi
    if [ ${SSH_FLAG} -eq 1 ]; then 
       PS1="${PS1}\[${COLOR_CYAN}\]\h "
    elif [[ -n ${SESS_SRC} ]]; then 
        if [ "${SESS_SRC}" == "(:0.0)" ]; then 
        PS1="${PS1}\[${COLOR_GREEN}\]\h "
        else 
	    local parent_process=`cat /proc/${PPID}/cmdline`
            if [[ "$parent_process" == "in.rlogind*" ]]; then
                #PS1="${PS1}\[${COLOR_BROWN}\]\h "
            #elif [[ "$parent_process" == "in.telnetd*" ]]; then 
                PS1="${PS1}\[${COLOR_YELLOW}\]\h "
            else
                PS1="${PS1}\[${COLOR_LIGHTRED}\]\h "
            fi
        fi
    elif [[ "${SESS_SRC}" == "" ]]; then
        PS1="${PS1}\[${COLOR_DEFAULT}\]\h "
    else                                 
        PS1="${PS1}\[${COLOR_RED}\]\h " 
    fi
    
    # Detached Screen Sessions
    local DTCHSCRN=$(screen -ls | grep -c Detach )
    if [ ${DTCHSCRN} -gt 2 ]; then
        PS1="${PS1}\[${COLOR_RED}\][scr:${DTCHSCRN}] "
    elif [ ${DTCHSCRN} -gt 0 ]; then
        PS1="${PS1}\[${COLOR_YELLOW}\][scr:${DTCHSCRN}] "
    fi
    
    # Backgrounded running jobs
    #local BKGJBS=$(jobs -r | wc -l )
    #if [ ${BKGJBS} -gt 2 ]; then
    #    PS1="${PS1}\[${COLOR_RED}\][bg:${BKGJBS}]"
    #elif [ ${BKGJBS} -gt 0 ]; then
    #    PS1="${PS1}\[${COLOR_YELLOW}\][bg:${BKGJBS}] "
    #fi
    
    # Stopped Jobs
    local STPJBS=$(jobs -s | wc -l )
    if [ ${STPJBS} -gt 2 ]; then
        PS1="${PS1}\[${COLOR_RED}\][stp:${STPJBS}]"
    elif [ ${STPJBS} -gt 0 ]; then
        PS1="${PS1}\[${COLOR_YELLOW}\][stp:${STPJBS}] "
    fi
    
    # Bracket {
    if [ ${UID} -eq 0 ]; then              
        if [ "${USER}" == "${LOGNAME}" ]; then 
            if [[ ${SUDO_USER} ]]; then
                PS1="${PS1}\[${COLOR_LIGHTRED}\]"
            else
                PS1="${PS1}\[${COLOR_LIGHTRED}\]"
            fi
        else                               
            PS1="${PS1}\[${COLOR_YELLOW}\]"
        fi
    else                                 
        if [ "${USER}" == "${LOGNAME}" ]; then 
            PS1="${PS1}\[${COLOR_GREEN}\]"
        else                               
            PS1="${PS1}\[${COLOR_BROWN}\]"
        fi
    fi
    PS1="${PS1}{ "
    
    # Working directory
    if [ -w "${PWD}" ]; then 
        PS1="${PS1}\[${COLOR_CYAN}\]$(prompt_workingdir)"
    else                                 
        PS1="${PS1}\[${COLOR_RED}\]$(prompt_workingdir)"
    fi
    
    # Closing bracket } and $\#
    if [ ${UID} -eq 0 ]; then              
        if [ "${USER}" == "${LOGNAME}" ]; then 
            if [[ ${SUDO_USER} ]]; then
                PS1="${PS1}\[${COLOR_LIGHTRED}\]"
            else
                PS1="${PS1}\[${COLOR_LIGHTRED}\]"
            fi
        else                               
            PS1="${PS1}\[${COLOR_YELLOW}\]"
        fi
	PS1="\[\033[36m\][\t] ${PS1} }# \[${COLOR_DEFAULT}\] "
	#PS1="\[${C2}\][\[${C1}\]\t\[${C2}\]] \[${C3}\]\n${PS1} } #\[${COLOR_DEFAULT}\] "
    else                                 
        #if [ "${USER}" == "${LOGNAME}" ]; then 
            PS1="${PS1}\[${COLOR_GREEN}\]"
        #else                               
        #    PS1="${PS1}\[${COLOR_BROWN}\]"
        #fi
	
	PS1="\[\033[36m\][\t] ${PS1} }\$ \[${COLOR_DEFAULT}\] "
	#PS1="\[${C2}\][\[${C1}\]\t\[${C2}\]] \[${C3}\]\n${PS1} } \$\[${COLOR_DEFAULT}\] "
    fi

}     

# Trim working dir to 1/4 the screen width
function prompt_workingdir () {
  local pwdmaxlen=$((${COLUMNS:=60}/4))
  local trunc_symbol="..."
  if [[ $PWD == $HOME* ]]; then
    newPWD="~${PWD#$HOME}" 
  else
    newPWD=${PWD}
  fi
  if [ ${#newPWD} -gt $pwdmaxlen ]; then
    local pwdoffset=$(( ${#newPWD} - $pwdmaxlen + 3 ))
    newPWD="${trunc_symbol}${newPWD:$pwdoffset:$pwdmaxlen}"
  fi
  echo $newPWD
}

# Determine what prompt to display:
# 1.  Display simple custom prompt for shell sessions started
#     by script.  
# 2.  Display "bland" prompt for shell sessions within emacs or 
#     xemacs.
# 3   Display promptcmd for all other cases.

function load_prompt () {
    # Get PIDs
    local parent_process=$(cat /proc/$PPID/cmdline | cut -d \. -f 1)
    local my_process=$(cat /proc/$$/cmdline | cut -d \. -f 1)

    if  [[ $parent_process == script* ]]; then
        PROMPT_COMMAND=""
        PS1="\t - \# - \u@\H { \w }\$ "
    elif [[ $parent_process == emacs* || $parent_process == xemacs* ]]; then
        PROMPT_COMMAND=""
        PS1="\u@\h { \w }\$ "
    else
        export DAY=$(date +%A)
        PROMPT_COMMAND=promptcmd
     fi 
    export PS1 PROMPT_COMMAND
}

load_prompt

alias less='less -R'
#export GREP_OPTIONS='--color=auto'
export HISTSIZE=5000
export HISTFILESIZE=5000



