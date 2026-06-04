#!/bin/bash

# TO DO:
# Get variables and write a config file for the user to use in the future
# Add a check to see if the config file exists and if not, run the script to get the variables and write the config file
# Run first to staging and then to production
# Setup a cron job to run this script on a regular basis

################################ User Variables ###############################
SECRETS_FILE=${HOME}/.secrets/namecert
############################## End User Variables #############################

############################### Fixed Variables ###############################
NECESSARY_BINARIES="curl python3 awk certbot"
PROD_ACME_SERVER="https://acme-v02.api.letsencrypt.org/directory"
STAGE_ACME_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
############################# End Fixed Variables #############################

################################## Functions ##################################
function check_for_binary() {
    if ! command -v "$1" &> /dev/null
    then    echo "$1 could not be found. Please install $1 to run this script."
        exit
    fi  
}   

function manage_challenge_record() {
    python3 -c "from namecheap import *; $1_challenge_record()"
}

function check_permission() {
    if [[ "$EUID" -ne 0 || $(sudo -l certbot >/dev/null 2>&1) -gt 0 ]]
    then    
        echo "This script must be run with root privileges or with sudo access to certbot."
        exit
    fi  
}
################################# End Functions ###############################

############################## Pre Flight Checks ##############################
# Make sure we have the necessary binaries to run this script
for BINARY in ${NECESSARY_BINARIES} ; do check_for_binary "${BINARY}" ; done

# Check if the user has the necessary permissions to run certbot:
check_permission
############################ End Pre Flight Checks ############################

# Get the external IP address of the machine running this script:
EXTERNAL_IP=$(curl -s https://ipinfo.io/ip)

# Create the DNS Challenge Record:
manage_challenge_record set

# Remove the DNS Challenge Record:
manage_challenge_record remove

