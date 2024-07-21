schema DataBase: 
    """ DataBase is the schema of cloud database.
    Attributes
    ----------
    dataBaseType: Literal Type, cloud database type name, default is "aliyun_rds".
    dataBaseAttr: DBAttr, cloud database attribute, default is Undefined.
    
    Examples
    --------
    dataBaseType = "aliyun_rds"
    dataBaseAttr = DBAttr {
        databaseEngine = "MySQL"
        databaseEngineVersion = "5.7"
        cloudChargeType = "Serverless"
        databaseAccountName = "root"
        databaseAccountPassword = "Kusion123456"
        internetAccess = True
    }
    
    """
    dataBaseType: "aliyun_rds" | "aws_rds"
    dataBaseAttr: DBAttr

schema DBAttr: 
    """ DBAttr is the Attributes of cloud database.
    Attributes
    ----------
    databaseEngine: "MySQL" | "SQLServer" | "PostgreSQL" | "MariaDB", cloud database engine type, default is "MySQL". 
    databaseEngineVersion: str, cloud database engine version, default is Undefined. 
    cloudChargeType: "Prepaid" | "Postpaid" | "Serverless", cloud database charge type, default is "Postpaid". 
    databaseAccountName: str, initialized account name of cloud database, default is Undefined. 
    databaseAccountPassWord: str, intitialized account password of cloud database, default is Undefined. 
    internetAccess: bool, decide whether the cloud database needs internet access. 
    
    """
    databaseEngine: "MySQL" | "SQLServer" | "PostgreSQL" | "MariaDB" = "MySQL"
    databaseEngineVersion: str
    instanceType: str
    databaseAccountName: str
    databaseAccountPassword: str
    internetAccess: bool
    allocatedStorage?: int = 10
    extraMap?: {str:str}
