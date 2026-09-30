*&---------------------------------------------------------------------*
*& Report  ZR_TR21A_JOIN
*& 練習 21a：JOIN 串 Header／Detail 兩張 Z 表（答案程式）
*& 前提：練習 21 已建好 ZTR21_STUD、ZTR21_CLASS，並跑過 ZR_TR21_ZTABLE
*&---------------------------------------------------------------------*
REPORT zr_tr21a_join LINE-SIZE 120.

TYPES: BEGIN OF ty_join,
         id     TYPE ztr21_stud-id,
         name   TYPE ztr21_stud-name,
         klasse TYPE ztr21_stud-klasse,
         klname TYPE ztr21_class-klname,
       END OF ty_join.

DATA: gt_join    TYPE STANDARD TABLE OF ty_join,
      gs_join    TYPE ty_join,
      gv_missing TYPE i.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* 學生 LEFT OUTER JOIN 班級
*   用 LEFT OUTER：班級代碼不存在（如 ZZZZ）或空白的學生也要列出，
*   INNER JOIN 會把這些學生整筆漏掉
*   ON 條件不可寫 MANDT：client 欄位由編譯器自動處理
*----------------------------------------------------------------------*
  SELECT s~id s~name s~klasse c~klname
    FROM ztr21_stud AS s
    LEFT OUTER JOIN ztr21_class AS c
      ON c~klasse = s~klasse
    INTO CORRESPONDING FIELDS OF TABLE gt_join
    ORDER BY s~id.
  IF sy-subrc <> 0.
    WRITE / '查無學生資料，請先執行 ZR_TR21_ZTABLE'.
    RETURN.
  ENDIF.

  WRITE / '=== 學生 JOIN 班級（學號／姓名／班級代碼／班級名稱） ==='.
  LOOP AT gt_join INTO gs_join.
    WRITE: / gs_join-id, gs_join-name, gs_join-klasse, gs_join-klname.
*   班級代碼有值、班級名稱卻是空的：外鍵沒擋住的髒資料
    IF gs_join-klasse IS NOT INITIAL AND gs_join-klname IS INITIAL.
      WRITE '← 班級不存在'.
      gv_missing = gv_missing + 1.
    ENDIF.
  ENDLOOP.

  WRITE: / '班級不存在：', gv_missing, '筆'.
