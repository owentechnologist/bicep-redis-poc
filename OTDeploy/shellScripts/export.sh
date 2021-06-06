. envars

DATE=gdate 			# Use gdate to mimic linux date on mac. Install thus: brew install coreutils
EXPIRY=$(${DATE:?} -u -d "60 minutes" '+%Y-%m-%dT%H:%MZ')
TOKEN=$(az storage container generate-sas --account-key $SRC_ACCOUNT_ACCESS_KEY --account-name $SRC_ACCOUNT --expiry "${EXPIRY}" --name $SRC_CONTAINER --permissions dlrw | tr -d '"')
SAS_URI="https://${SRC_ACCOUNT:?}.blob.core.windows.net/${SRC_CONTAINER:?}?${TOKEN:?}"


JSON_BODY="{ \"sasUri\": \"${SAS_URI:?};${SRC_ACCOUNT_ACCESS_KEY:?}\" }"

az rest -m POST -u https://management.azure.com/subscriptions/${SUBSCRIPTION_ID:?}/resourceGroups/${RESOURCE_GROUP_NAME:?}/providers/Microsoft.Cache/redisEnterprise/${SRC_CLUSTER_NAME:?}/databases/${SRC_DATABASE_NAME:?}/export?api-version=2021-03-01 -b "$JSON_BODY"