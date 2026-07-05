*&---------------------------------------------------------------------*
*& Report  ZR_TR21_ZTABLE
*& 練習 21：Z 資料表 Open SQL 寫入（答案程式）
*& 前提：SE11 已建立並啟用 ZTR21_STUD（欄位規格見 ex21 第一部分）
*&---------------------------------------------------------------------*
REPORT zr_tr21_ztable.

DATA: gs_stud TYPE ztr21_stud,          " 表名直接當結構型別
      gt_stud TYPE STANDARD TABLE OF ztr21_stud.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* 1) 防呆：清掉本程式的舊測試資料（讓程式可重複執行）
*    只刪 S00%：SM30 手動建的 S9001 不受影響
*----------------------------------------------------------------------*
  DELETE FROM ztr21_stud WHERE id LIKE 'S00%'.
  WRITE: / '清除舊測試資料：', sy-dbcnt, '筆'.

*----------------------------------------------------------------------*
* 2) INSERT 單筆：主鍵不存在才成功；帶稽核欄是好習慣
*----------------------------------------------------------------------*
  CLEAR gs_stud.
  gs_stud-id      = 'S0001'.
  gs_stud-name    = '王小明'.
  gs_stud-score   = 85.
  gs_stud-upduser = sy-uname.
  gs_stud-upddate = sy-datum.
  INSERT ztr21_stud FROM gs_stud.
  IF sy-subrc = 0.
    WRITE / 'INSERT S0001：成功'.
  ELSE.
    WRITE / 'INSERT S0001：失敗'.
  ENDIF.

*----------------------------------------------------------------------*
* 3) 同主鍵再 INSERT：sy-subrc = 4，不會覆蓋既有資料
*----------------------------------------------------------------------*
  INSERT ztr21_stud FROM gs_stud.
  WRITE: / '再 INSERT S0001：sy-subrc =', sy-subrc, '（主鍵重複）'.

*----------------------------------------------------------------------*
* 4) 批次 INSERT FROM TABLE：
*    沒加 ACCEPTING DUPLICATE KEYS 時，任一筆重複整批 dump！
*----------------------------------------------------------------------*
  CLEAR gt_stud.
  CLEAR gs_stud.
  gs_stud-upduser = sy-uname.  gs_stud-upddate = sy-datum.
  gs_stud-id = 'S0002'. gs_stud-name = '李小美'. gs_stud-score = 92.
  APPEND gs_stud TO gt_stud.
  gs_stud-id = 'S0003'. gs_stud-name = '陳大文'. gs_stud-score = 67.
  APPEND gs_stud TO gt_stud.
  INSERT ztr21_stud FROM TABLE gt_stud ACCEPTING DUPLICATE KEYS.
  WRITE / '批次 INSERT：完成'.

*----------------------------------------------------------------------*
* 5) UPDATE：改既有資料；WHERE 沒中任何列 → sy-subrc = 4
*----------------------------------------------------------------------*
  UPDATE ztr21_stud SET score   = 90
                        upduser = sy-uname
                        upddate = sy-datum
    WHERE id = 'S0001'.
  IF sy-subrc = 0.
    WRITE / 'UPDATE S0001 成績 90：成功'.
  ENDIF.

*----------------------------------------------------------------------*
* 6) MODIFY = upsert：不存在就新增、存在就整筆覆寫
*----------------------------------------------------------------------*
  CLEAR gs_stud.
  gs_stud-id      = 'S0004'.
  gs_stud-name    = '張三豐'.
  gs_stud-score   = 45.
  gs_stud-upduser = sy-uname.
  gs_stud-upddate = sy-datum.
  MODIFY ztr21_stud FROM gs_stud.
  WRITE: / 'MODIFY S0004（新增）：sy-subrc =', sy-subrc.

  gs_stud-score = 75.
  MODIFY ztr21_stud FROM gs_stud.
  WRITE: / 'MODIFY S0004（修改為 75）：sy-subrc =', sy-subrc.

*----------------------------------------------------------------------*
* 7) DELETE
*----------------------------------------------------------------------*
  DELETE FROM ztr21_stud WHERE id = 'S0003'.
  IF sy-subrc = 0.
    WRITE / 'DELETE S0003：成功'.
  ENDIF.

*----------------------------------------------------------------------*
* 8) 讀回全表驗證（跟 SE16N 對照）
*----------------------------------------------------------------------*
  WRITE / '=== 目前表內容 ==='.
  SELECT * FROM ztr21_stud INTO TABLE gt_stud.
  LOOP AT gt_stud INTO gs_stud.
    WRITE: / gs_stud-id, gs_stud-name, gs_stud-score.
  ENDLOOP.

*----------------------------------------------------------------------*
* 9) 明確結束這個 LUW：全部確認落地
*    （若中途 sy-subrc 異常，正式寫法是 ROLLBACK WORK. 整包撤銷
*      + MESSAGE 告知，確保不會只寫一半）
*----------------------------------------------------------------------*
  COMMIT WORK.
