#!/bin/bash

# TO DO:
# source variable file with verfied to know whether or not to test first with staging
# Get variables and write a config file for the user to use in the future
# Run first to staging and then to production if VERIFIED=0
# Setup a cron job to run this script on a regular basis

################################ User Variables ###############################
SECRETS_FILE_BASE=${HOME}/.secrets/namecert_
############################## End User Variables #############################

###############################################################################

############################### Fixed Variables ###############################
NECESSARY_BINARIES="curl python3 awk certbot"
PROD_ACME_SERVER="https://acme-v02.api.letsencrypt.org/directory"
STAGE_ACME_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
WRITE_SECRET=0 # This variable is used to determine if we need to write the secrets file at the end of the script. It is set to 1 if any of the necessary variables are not set and we have to ask the user for input.  
############################# End Fixed Variables #############################

###############################################################################

#################################### Usage ####################################
if [[ "${1}" = "-h" || "${1}" = "--help" ]] ; then echo -e "\nUsage: $(basename ${0}) <issue|renew> <domain.name>\n\n" ; exit ; fi

if [[  "${1}" != "issue" && "${1}" != "renew" ]] ; then echo -e "\nUsage: $(basename ${0}) <issue|renew> <domain.name>\n\n" ; exit ; fi

if [[ -z "${2}" ]] ; then echo -e "\nUsage: $(basename ${0}) <issue|renew> <domain.name>\n\n" ; exit ; fi
################################## End Usage ##################################

###############################################################################

################################## Functions ##################################
function check_for_binary() {
    if ! command -v "$1" &> /dev/null
    then    echo "$1 could not be found. Please install $1 to run this script."
        exit
    fi  
}   

function manage_challenge_record() {
    python3 -c "from namecheap import *; $1_challenge_record()"
    sleep 30
}

function check_permission() {
    if [ "$EUID" -ne 0 ] ; then if
       [ $(sudo -l certbot) ] ; then
            echo "Access available"
        else
            echo  "This script must be run with root privileges or with sudo access to certbot."
            exit
        fi
        fi
}

function issue_certificate() {
# Check this
LESERVER=${STAGE_ACME_SERVER}
sudo certbot certonly --manual --preferred-challenges=dns --manual-auth-hook "python3 -c 'from namecheap import *; set_challenge_record()'" --manual-cleanup-hook "python3 -c 'from namecheap import *; remove_challenge_record()'" --server "${LESERVER}" -d "${SLD}.${TLD}" --email "${EMAIL}" --agree-tos --non-interactive --dry-run
# Figure out how to use
# Create the DNS Challenge Record:
# manage_challenge_record set

# Remove the DNS Challenge Record:
# manage_challenge_record remove}
}

function renew_certificate() {
# Check This    
sudo certbot renew --manual --preferred-challenges=dns --manual-auth-hook "python3 -c 'from namecheap import *; set_challenge_record()'" --manual-cleanup-hook "python3 -c 'from namecheap import *; remove_challenge_record()'" --server "${LESERVER}" --email "${EMAIL}" --agree-tos --non-interactive
# Figure out how to use
# Create the DNS Challenge Record:
# manage_challenge_record set

# Remove the DNS Challenge Record:
# manage_challenge_record remove}
}
################################# End Functions ###############################
echo "after functions"
###############################################################################

############################## Pre Flight Checks ##############################
# Make the SECRETS_FILE directory if it doesn't exist:
[[ ! -d ${SECRETS_FILE_BASE%/*} ]] && mkdir -p "${SECRETS_FILE_BASE%/*}"

# Make sure we have the necessary binaries to run this script
for BINARY in ${NECESSARY_BINARIES} ; do check_for_binary "${BINARY}" ; done

# Check if the user has the necessary permissions to run certbot:
check_permission
############################ End Pre Flight Checks ############################

###############################################################################

####################### Automatically Gather what we can ######################
# Source the secrets file if it exists:
[[ -f "${SECRETS_FILE_BASE}${DOMAIN_NAME}" ]] && source "${SECRETS_FILE_BASE}${DOMAIN_NAME}"

# Get the external IP address of the machine running this script:
EXTERNAL_IP=$(curl -s https://ipinfo.io/ip)
################################# End Gather ##################################

###############################################################################

################################ Get Cert Input ###############################
[[ -z "${USERNAME}" ]] && WRITE_SECRET=1 && \
read -p "What is your username for Namecheap? " USERNAME

[[ -z "${API_KEY}" ]]&& WRITE_SECRET=1 && \
read -p "What is your API key for Namecheap? " API_KEY

[[ -z "${API_USER}" ]] && \
read -p "Do you have a different username for the API key? (y/n) " DIFFERENT_USERNAME
if [[ "${DIFFERENT_USERNAME,,}" == "y" ]]
then    read -p "What is the username for the API key? " API_USER
else    API_USER="${USERNAME}"
fi  

[[ -z "${CLIENT_IP}" ]] && WRITE_SECRET=1 && \
read -p "Your external IP address is ${EXTERNAL_IP}. Is this correct client IP address to use? (y/n) " IP_CONFIRM
if [[ "${IP_CONFIRM,,}" != "y" ]]
then    read -p "Please enter the correct cient IP address to use: " CLIENT_IP
else    CLIENT_IP="${EXTERNAL_IP}"
fi

[[ -z "${SLD}" ]]&& WRITE_SECRET=1 && \
read -p "What is the domain you want to get a certificate for? (Example: the mydomain in mydomain.com) " SLD

[[ -z "${TLD}" ]] && WRITE_SECRET=1 && \
read -p "What is the TLD for the domain you want to get a certificate for? (Example: the com in mydomain.com) " TLD

[[ -z "${EMAIL}" ]] && WRITE_SECRET=1 && \
read -p "What email address do you want to use for the certificate? " EMAIL
################################ End Cert Input ###############################

###############################################################################

################################## Run Script #################################
if [[ "${WRITE_SECRET}" -eq 1 ]] ; then
echo "Would you like me to save the following information to a secrets file for future use?"
echo "Username: ${USERNAME}"
echo "API Key: ${API_KEY}"
echo "API User: ${API_USER}"
echo "Client IP: ${CLIENT_IP}"
echo "Domain: ${SLD}.${TLD}"
echo "Email: ${EMAIL}"
read -p "(y/n) " SAVE_SECRETS
if [[ "${SAVE_SECRETS,,}" == "y" ]]
then    echo "Saving secrets to ${SECRETS_FILE_BASE}${DOMAIN_NAME}"
        echo "USERNAME=\"${USERNAME}\"" > "${SECRETS_FILE_BASE}${DOMAIN_NAME}"
        echo "API_KEY=\"${API_KEY}\"" >> "${SECRETS_FILE_BASE}${DOMAIN_NAME}"
        echo "API_USER=\"${API_USER}\"" >> "${SECRETS_FILE_BASE}${DOMAIN_NAME}"
        echo "CLIENT_IP=\"${CLIENT_IP}\"" >> "${SECRETS_FILE_BASE}${DOMAIN_NAME}"
        echo "SLD=\"${SLD}\"" >> "${SECRETS_FILE_BASE}${DOMAIN_NAME}"
        echo "TLD=\"${TLD}\"" >> "${SECRETS_FILE_BASE}${DOMAIN_NAME}"
        echo "EMAIL=\"${EMAIL}\"" >> "${SECRETS_FILE_BASE}${DOMAIN_NAME}"
fi  
fi

read -p "Would you like to issue a new certificate or renew an existing one? (issue/renew) " ACTION
if [[ "${ACTION,,}" == "issue" ]]
then    issue_certificate
elif [[ "${ACTION,,}" == "renew" ]]
then    renew_certificate
else    echo "Invalid action. Please enter 'issue' or 'renew'."
        exit
fi
################################## End Script #################################
