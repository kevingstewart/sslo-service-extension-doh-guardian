#!/bin/bash

if [[ -z "${BIGUSER}" ]]
then
    echo 
    echo "The user:pass must be set in an environment variable. Exiting."
    echo "   export BIGUSER='admin:password'"
    echo 
    exit 1
fi

# ## Install doh-guardian-rule iRule
echo "..Creating the doh-guardian-rule iRule"
rule=$(curl -sk https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/doh-guardian/doh-guardian-rule | awk '{printf "%s\\n", $0}' | sed -e 's/\"/\\"/g;s/\x27/\\'"'"'/g')
data="{\"name\":\"doh-guardian-rule\",\"apiAnonymous\":\"${rule}\"}"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "${data}" \
https://localhost/mgmt/tm/ltm/rule -o /dev/null

## Create SSLO DoH-Guardian Inspection Service
echo "..Creating the SSLO doh-guardian inspection service"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "$(curl -sk https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/doh-guardian/doh-guardian-service)" \
https://localhost/mgmt/shared/iapp/blocks -o /dev/null

## Sleep for 15 seconds to allow SSLO inspection service creation to finish
echo "..Sleeping for 15 seconds to allow SSLO inspection service creation to finish"
sleep 15

## Modify SSLO DoH-Guardian Service (remove tenant-restrictions iRule)
echo "..Modifying the SSLO doh-guardian service"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-X PATCH \
-d '{"rules":["/Common/doh-guardian-rule"]}' \
https://localhost/mgmt/tm/ltm/virtual/ssloS_F5_DoH.app~ssloS_F5_DoH-t-4 -o /dev/null

echo "..Done"
