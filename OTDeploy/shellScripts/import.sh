. envars

DEST_BLOB_NAME=${1:?No blob name given}

DATE=gdate 			# Use gdate to mimic linux date on mac. Install thus: brew install coreutils
EXPIRY=$(${DATE} -u -d "60 minutes" '+%Y-%m-%dT%H:%MZ')

TOKEN=$(az storage blob generate-sas --account-key ${DEST_ACCOUNT_ACCESS_KEY:?} --account-name ${DEST_ACCOUNT:?} --expiry "${EXPIRY:?}" --container-name ${DEST_CONTAINER:?} --name ${DEST_BLOB_NAME:?} --permissions r | tr -d '"')
SAS_URI="https://${DEST_ACCOUNT:?}.blob.core.windows.net/${DEST_CONTAINER:?}/${DEST_BLOB_NAME:?}?${TOKEN:?}"

JSON_BODY="{ \"sasUri\": \"${SAS_URI};${DEST_ACCOUNT_ACCESS_KEY}\" }"

az rest -m POST -u https://management.azure.com/subscriptions/${SUBSCRIPTION_ID:?}/resourceGroups/${RESOURCE_GROUP_NAME:?}/providers/Microsoft.Cache/redisEnterprise/${DEST_CLUSTER_NAME:?}/databases/${DEST_DATABASE_NAME:?}/import?api-version=2021-03-01 -b "$JSON_BODY"