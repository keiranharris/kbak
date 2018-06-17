#!/bin/sh

########################################
# VERSION:  1.0
# UPDATED:  17/6/2018
# DESCRIP:  backup data
#   NOTES:  this script is intended to live (and be launched) on the external drive
#           it should be placed in a /_BAKSCRIPT/ folder (also create /_BAKSCRIPT/_LOGS/) on that drive
#
#	    Note ALSO that this requires a newer version of RSYNC to support the --iconv switch (see evernote)
########################################

declare -a ARGUMENTS

#--------------------------------------------------------------------------------
#DISPLAY A SELECTIVE (BASED ON CURRENT USER) MENU
PrintMenu () {
    clear
    echo "----- Welcome to the kBAK Program -----"
    echo "|                                     |"
    echo "| Menu Choices:                       |"
    echo "|  (kw) KdataWork(AU10822)   => K_3TB |"
    echo "|                                     |"
    echo "|  (  q) quit                         |"
    echo "|                                     |"
    echo "---------------------------------------"
}

#POPULATE GLOBAL ARGUMENTS ARRAY WITH ALL (MAX 3) THE MENU ITEMS THE USER ENTERS
ReadMenuInput () {
    read -p " ENTER BACKUP CHOICES (MULTIPLE OK, SPACE SEPARATED) ->" choices
    read c1 c2 c3 <<<"$choices"

    #fill the array with choices (perhaps arguments 2 and 3 dont exist)
    ARGUMENTS[0]=$c1
    [[ -n $c2 ]] && ARGUMENTS[1]=$c2
    [[ -n $c3 ]] && ARGUMENTS[2]=$c3
    #if more than 3 arguments are entered, break out of THIS ITERATION of the main menu loop
    myRegEx=".+ .*"
    if [[ "$c3" =~ $myRegEx ]]; then
        echo "max of 3 please!"
        sleep 1
        return 99       #error return
    else
        return 0        #healthy return
    fi
}

#HANDLES ALL THE VALID MENU INPUT
ProcessMenuCommand () {
    case $1 in
        kw) BuildRsyncCmd "kdata-work"
            ;;
        q)  CleanExit
            ;;
        *)  echo "'$1' not a valid choice"
            sleep 1
            ;;
    esac
}

BuildRsyncCmd () {
    KLOG=`date "+/Volumes/K_3TB/_KBAK-SCRIPT/_LOGS/%Y%m%d-%H%M_$1.txt"`
    case $1 in
        kdata-nas)
		#KNOTE:password-file is for SECOND password (the RSYNC process) it is set in /etc/rsyncd.conf on NAS, default is 'mynasrsyncpass'
            KARG=' -av --del --rsh=ssh --exclude="._*" --iconv=UTF8-MAC,UTF-8 --password-file=/_LOCALDATA/_PROGDATA/SCRIPTS/kbakpass.txt '
            KSRC=' rsync://admin@10.10.10.5/_DATAKEIRAN/_KNAS/ '
            KDST=' /Volumes/K_2TB/K_BAK/_KNAS/ '
            echo "Performing rsync of [$KSRC] to [$KDST] \n....redirecting output to [$KLOG]"
            rsync $KARG $KSRC $KDST | grep -v '/$' > $KLOG
            ;;

        kdata-work)
		#KNOTES: -L to follow symlinks
    # insert '--dry-run' into args to test
            KARG=' -L -av --del  --exclude-from /_KEIRAN/_SCRIPTS/__CONFIG/rsync_k_exclude.conf '
            KSRC=' /_KEIRAN/ '
            KDST=' /Volumes/K_3TB/BACKUPS/_AU10822/ '
            echo "Performing rsync of [$KSRC] to [$KDST] \n....redirecting output to [$KLOG]"
#echo "rsync $KARG $KSRC $KDST | grep -v '/$'"
            rsync $KARG $KSRC $KDST | grep -v '/$' 2>&1 | tee $KLOG
            ;;
    esac
    read -p "Backup of [$1] DONE.... [hit enter to return to menu]"
}


#--------------------------------------------------------------------------------
#CLEANEXIT CODE TO BE CALLED BY MENU 'q' OR BY ANY CONCEIVABLE SHELL EVENT (SEE traps BELOW)
CleanExit () {
    #NOT DOING MUCH AT THE MOMENT APART FROM EXITING
    exit 0
}

#FORCE CLEAN EXIT, REGARDLESS OF THE WAY PROGRAM TERMINATES
trap CleanExit SIGHUP      #event 1  (hang up. This is when user kills term window via GUI)
trap CleanExit SIGINT      #event 2  (ctrl+c)
trap CleanExit SIGTERM     #event 15 (terminate signal sent by kill)
trap CleanExit SIGKILL     #event 9  (terminate immediately from kernal)

#--------------------------------------------------------------------------------
#MAIN CODE
while true; do
    PrintMenu
    ReadMenuInput
    #MAKE SURE ALL IS OK WITH INPUT BEFORE PROCEEDING, 99 FLAGS AN ISSUE
    if [[ $? -eq 99 ]]; then continue; fi   #'continue' breaks out of THIS ITERATION of the loop

    #FOR EACH MENU INPUT (ON A SINGLE LINE) PROCESS THAT COMMAND
    max=${#ARGUMENTS[*]}    #notation for working out the upper indicie of the array
    for (( k=0; k<$((max)); k=k+1 )); do
        ProcessMenuCommand ${ARGUMENTS[k]}
    done
    unset ARGUMENTS     #destroy arguments array at end of each iteration
done
