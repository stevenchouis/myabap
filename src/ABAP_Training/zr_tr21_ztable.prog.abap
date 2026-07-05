*&---------------------------------------------------------------------*
*& Report  ZR_TR21_ZTABLE
*& 練習 21：Z 資料表 Open SQL 寫入（答案程式）
*& 前提：SE11 已建立並啟用 ZTR21_STUD（欄位規格見 ex21 第一部分）
*& 擴充：ZTR21_CLASS（班級主檔）＋ ZTR21_STUD.KLASSE 外鍵（Check Table）教學
*&---------------------------------------------------------------------*
REPORT zr_tr21_ztable.

DATA: gs_stud  TYPE ztr21_stud,          " 表名直接當結構型別
      gt_stud  TYPE STANDARD TABLE OF ztr21_stud,
      gs_class TYPE ztr21_class.

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
* 9) 外鍵（Foreign Key/Check Table）教學：先準備班級主檔（Header）資料
*    ZTR21_STUD-KLASSE 的檢查表是 ZTR21_CLASS，這裡先放一筆合法班級
*----------------------------------------------------------------------*
  DELETE FROM ztr21_class WHERE klasse = 'S101'.
  CLEAR gs_class.
  gs_class-klasse = 'S101'.
  gs_class-klname = '資訊一班'.
  INSERT ztr21_class FROM gs_class.
  WRITE: / 'INSERT 班級 S101（資訊一班）：sy-subrc =', sy-subrc.

*----------------------------------------------------------------------*
* 10) 合法 KLASSE：S101 在 ZTR21_CLASS 裡存在，INSERT 正常成功
*----------------------------------------------------------------------*
  CLEAR gs_stud.
  gs_stud-id      = 'S0005'.
  gs_stud-name    = '林小華'.
  gs_stud-score   = 88.
  gs_stud-klasse  = 'S101'.
  gs_stud-upduser = sy-uname.
  gs_stud-upddate = sy-datum.
  INSERT ztr21_stud FROM gs_stud.
  WRITE: / 'INSERT S0005（KLASSE=S101，合法班級）：sy-subrc =', sy-subrc.

*----------------------------------------------------------------------*
* 11) 【重點教學】不存在的 KLASSE：Open SQL 層級完全不會擋下來
*     DDIC 外鍵／Check Table 只在畫面輸入（如 SM30、Dynpro 的 F4／
*     離開欄位檢查）時發生作用，不是資料庫層的 constraint。
*     程式用 INSERT/UPDATE 呼叫一律不受影響，sy-subrc 仍然是 0。
*----------------------------------------------------------------------*
  CLEAR gs_stud.
  gs_stud-id      = 'S0006'.
  gs_stud-name    = '吳小芳'.
  gs_stud-score   = 79.
  gs_stud-klasse  = 'ZZZZ'.        " ZTR21_CLASS 裡沒有這個班級代碼
  gs_stud-upduser = sy-uname.
  gs_stud-upddate = sy-datum.
  INSERT ztr21_stud FROM gs_stud.
  WRITE: / 'INSERT S0006（KLASSE=ZZZZ，班級不存在）：sy-subrc =', sy-subrc.
  WRITE / '  → 對比：sy-subrc = 0，程式端 INSERT 依然成功！'.
  WRITE / '  → DDIC 外鍵是「畫面層防呆」（SM30/Dynpro 才會擋），不是「資料庫層 constraint」，'.
  WRITE / '     Open SQL 呼叫不會被擋下來，資料正確性仍要靠程式自行檢查。'.

*----------------------------------------------------------------------*
* 12) JOIN 複習：學生 LEFT OUTER JOIN 班級，印出學號/姓名/班級代碼/班級名稱
*     用 LEFT OUTER JOIN 是因為部分學生的 KLASSE 是初始值或查無班級
*     （如上一步的 ZZZZ），這種情況 KLNAME 會是空白，不會整列不見
*     注意：MANDT 是 client field，JOIN 的 ON 條件不可寫出來，
*     Client Handling 由編譯器自動處理（兩邊都會自動限定同一 client）
*----------------------------------------------------------------------*
  SELECT s~id, s~name, s~klasse, c~klname
    FROM ztr21_stud AS s
    LEFT OUTER JOIN ztr21_class AS c
      ON c~klasse = s~klasse
    INTO TABLE @DATA(gt_join)
    ORDER BY s~id.

  WRITE / '=== 學生 JOIN 班級（學號／姓名／班級代碼／班級名稱） ==='.
  LOOP AT gt_join INTO DATA(gs_join).
    WRITE: / gs_join-id, gs_join-name, gs_join-klasse, gs_join-klname.
  ENDLOOP.

*----------------------------------------------------------------------*
* 13) 明確結束這個 LUW：全部確認落地
*    （若中途 sy-subrc 異常，正式寫法是 ROLLBACK WORK. 整包撤銷
*      + MESSAGE 告知，確保不會只寫一半）
*----------------------------------------------------------------------*
  COMMIT WORK.
