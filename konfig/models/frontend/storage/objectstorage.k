
schema ObjectStorage:
    """ ObjectStorage is the schema of clouds object storage.
    Attributes
    ----------
    objectStorageType: str, cloud object storage name, default is Undefined.
    objectStorageAttr: str, cloud object storage attribute, default is Undefined.
    
    Examples
    --------
    clouds = ObjectStorage.ObjectStorage {
        objectStorageType = "aliyun_oss"
        objectStorageAttr = StorageAttr {
            bucket = "kusion-oss"
            acl    = "public-read"
        }
    }
    """
    objectStorageType: str 
    objectStorageAttr: StorageAttr

schema StorageAttr:
    """ StorageAttr is the Attributes of storage.
    Attributes
    ----------
    bucket: str, The name of the bucket, default is Undefined.
    acl: str, The canned ACL to apply, default is Undefined.
    """
    bucket: str
    acl: str