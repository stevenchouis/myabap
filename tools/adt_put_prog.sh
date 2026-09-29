#!/bin/sh
# 放在 repo：tools/adt_put_prog.sh（2026-09-29）。用於大段原始碼上傳，免得透過 sap_set_source 貼整份程式；
# 同時繞過 sap_set_source 內建啟用的假鎖 403（見 .claude/rules/sap-adt-mcp.md 第 36、62 節）。
# 用法：put_prog.sh <程式名小寫> <原始碼檔>
# 流程：stateful session → LOCK → PUT source/main → UNLOCK → activation → 印出啟用結果
set -e
NAME="$1"; SRC="$2"
B='http://127.0.0.1:8410/sap/bc/adt'
Q='sap-client=130&sap-language=EN'
J="$(mktemp)"
URI="/sap/bc/adt/programs/programs/$NAME"

curl -s -c "$J" -b "$J" -H 'x-csrf-token: fetch' -H 'x-sap-adt-sessiontype: stateful' "$B/discovery?$Q" -o /dev/null

LOCK=$(curl -s -c "$J" -b "$J" -H 'x-csrf-token: ADT-RFC-BRIDGE' -H 'x-sap-adt-sessiontype: stateful' \
  -H 'Accept: application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result' \
  -X POST "$B/programs/programs/$NAME?_action=LOCK&accessMode=MODIFY&$Q")
HANDLE=$(echo "$LOCK" | grep -o '<LOCK_HANDLE>[^<]*' | sed 's/<LOCK_HANDLE>//')
[ -n "$HANDLE" ] || { echo "LOCK failed: $LOCK"; exit 1; }

HC=$(curl -s -c "$J" -b "$J" -H 'x-csrf-token: ADT-RFC-BRIDGE' -H 'x-sap-adt-sessiontype: stateful' \
  -H 'Content-Type: text/plain; charset=utf-8' --data-binary "@$SRC" \
  -X PUT "$B/programs/programs/$NAME/source/main?lockHandle=$HANDLE&$Q" -o "$J.put" -w '%{http_code}')
echo "PUT: $HC"; [ "$HC" = "200" ] || cat "$J.put"

curl -s -c "$J" -b "$J" -H 'x-csrf-token: ADT-RFC-BRIDGE' -H 'x-sap-adt-sessiontype: stateful' \
  -X POST "$B/programs/programs/$NAME?_action=UNLOCK&lockHandle=$HANDLE&$Q" -o /dev/null -w 'UNLOCK: %{http_code}\n'

curl -s -b "$J" -H 'x-csrf-token: ADT-RFC-BRIDGE' -H 'Content-Type: application/vnd.sap.adt.activation+xml' \
  -X POST "$B/activation?method=activate&preauditRequested=true&$Q" \
  --data "<?xml version=\"1.0\" encoding=\"UTF-8\"?><adtcore:objectReferences xmlns:adtcore=\"http://www.sap.com/adt/core\"><adtcore:objectReference adtcore:uri=\"$URI\"/></adtcore:objectReferences>" \
  -w '\nACTIVATE: %{http_code}\n' | sed 's/<msg /\n<msg /g' | grep -o 'type="[EW]"\|<txt>[^<]*\|line=[0-9]*\|ACTIVATE: [0-9]*' | paste -sd' ' | sed 's/type=/\n&/g'
rm -f "$J" "$J.put"
