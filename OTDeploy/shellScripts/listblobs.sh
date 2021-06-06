. envars

list_blobs() {
    CONTAINER=${1:?No container specified}
    ACCOUNT=${2:?No account specified}
    ACCOUNT_ACCESS_KEY=${3:?No access key}
az storage blob list --container-name ${CONTAINER:?} --account-name ${ACCOUNT:?} --account-key ${ACCOUNT_ACCESS_KEY:?} | jq -r '[.[]|{ name, date: .properties.creationTime, length: .properties.contentLength }] | sort_by(.date) | reverse | .[]|  [.name, .date, .length] | @tsv'

# or in tsv format suitable for processing by shell scripts:
# jq -r '[.[]|{ name, date: .properties.creationTime, length: .properties.contentLength }] | sort_by(.date) | reverse | .[] | [.name, .date, .length] | @tsv' blob_list.json
}

echo "blobs in source"
list_blobs ${SRC_CONTAINER:?} ${SRC_ACCOUNT:?} ${SRC_ACCOUNT_ACCESS_KEY:?}

echo
echo "blobs in destination"
list_blobs ${DEST_CONTAINER:?} ${DEST_ACCOUNT:?} ${DEST_ACCOUNT_ACCESS_KEY:?}