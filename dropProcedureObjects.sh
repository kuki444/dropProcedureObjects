#!/usr/bin/env bash

# サイト名（環境名）
site_name=${1,,}

# スキーマ名
schema_name=${site_name^^}

# 編集用出力ファイル
## ディレクトオブジェクト削除SQL
dorp_objects_file=$(mktemp)

cat  <<EOF > ${dorp_objects_file}
SET ECHO OFF;
SET LINESIZE 1000;
SET HEADING OFF;
SET UNDERLINE OFF;
SET PAGESIZE 0;
SET TRIMSPOOL ON;
SET FEEDBACK OFF;
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT 9
DECLARE
  CURSOR OBJECT_LIST_CUR IS
    SELECT OWNER
          ,OBJECT_TYPE
          ,OBJECT_NAME
      FROM DBA_OBJECTS
     WHERE OWNER = '${schema_name}'
       AND OBJECT_TYPE IN('FUNCTION','PROCEDURE','PACKAGE');

  OBJECT_LIST_REC OBJECT_LIST_CUR%ROWTYPE;
BEGIN
  OPEN OBJECT_LIST_CUR;
  LOOP
    FETCH OBJECT_LIST_CUR INTO OBJECT_LIST_REC;
    EXIT WHEN OBJECT_LIST_CUR%NOTFOUND;
    EXECUTE IMMEDIATE 'DROP ' || OBJECT_LIST_REC.OBJECT_TYPE || '  ' || OBJECT_LIST_REC.OWNER || '.' || OBJECT_LIST_REC.OBJECT_NAME;
    DBMS_OUTPUT.PUT_LINE('Drop ' || OBJECT_LIST_REC.OBJECT_TYPE || ' ' || OBJECT_LIST_REC.OBJECT_NAME);
  END LOOP;
  CLOSE OBJECT_LIST_CUR;
END;
/
EXIT;
EOF

#sqlplus sys/oracle as sysdba @${dorp_objects_file}  > /dev/null 2>&1
sqlplus sys/oracle as sysdba @${dorp_objects_file}
ret=$?
if [ ${ret} -ne 0 ]; then
  echo "Oracle Err ErrorCode:${ret}"
  exit ${ret}
fi

# 完了メッセージ
echo "Oracle ProcedureObjects Drop Success ${site_name}"
