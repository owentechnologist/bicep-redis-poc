. envars

SRC_BLOB=${1:?"No source blob given"}
DEST_BLOB=${SRC_BLOB:?}

 az storage blob copy start --source-container ${SRC_CONTAINER:?} --source-blob ${SRC_BLOB:?}  --destination-container ${DEST_CONTAINER:?} --destination-blob ${DEST_BLOB:?} --account-name ${DEST_ACCOUNT:?} --account-key ${DEST_ACCOUNT_ACCESS_KEY:?} --source-account-name ${SRC_ACCOUNT:?} --source-account-key ${SRC_ACCOUNT_ACCESS_KEY:?}