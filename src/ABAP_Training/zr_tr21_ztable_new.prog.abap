*&---------------------------------------------------------------------*
*& Report  ZR_TR21_ZTABLE_NEW
*& 練習 21：Z 資料表 Open SQL 寫入（答案程式，新式寫法版）
*& 對照 ZR_TR21_ZTABLE：輸出相同；寫入的來源加 @，可以直接放
*& @( VALUE #( ... ) ) 運算式，不必先填 work area；UPDATE SET 用逗號分隔
*&---------------------------------------------------------------------*
REPORT zr_tr21_ztable_new.

START-OF-SELECTION.
* 1) 防呆：清掉本程式的舊測試資料
  DELETE FROM ztr21_stud WHERE id LIKE 'S00%'.
  WRITE: / '清除舊測試資料：', sy-dbcnt, '筆'.

* 2) INSERT 單筆：@( VALUE ztr21_stud( ... ) ) 直接在 INSERT 裡建出一列
*    運算式要用 @( ) 包起來；client 欄位不用填，Open SQL 自動帶目前 client
  INSERT ztr21_stud FROM @( VALUE #( id      = 'S0001'
                                     name    = '王小明'
                                     score   = 85
                                     upduser = sy-uname
                                     upddate = sy-datum ) ).
  IF sy-subrc = 0.
    WRITE / 'INSERT S0001：成功'.
  ELSE.
    WRITE / 'INSERT S0001：失敗'.
  ENDIF.

* 3) 同主鍵再 INSERT：sy-subrc = 4
  INSERT ztr21_stud FROM @( VALUE #( id = 'S0001' name = '王小明' score = 85
                                     upduser = sy-uname upddate = sy-datum ) ).
  WRITE: / '再 INSERT S0001：sy-subrc =', sy-subrc, '（主鍵重複）'.

* 4) 批次 INSERT FROM TABLE：內表一樣可以用 VALUE 現場建好
  INSERT ztr21_stud FROM TABLE @( VALUE #(
    ( id = 'S0002' name = '李小美' score = 92 upduser = sy-uname upddate = sy-datum )
    ( id = 'S0003' name = '陳大文' score = 67 upduser = sy-uname upddate = sy-datum ) ) )
    ACCEPTING DUPLICATE KEYS.
  WRITE / '批次 INSERT：完成'.

* 5) UPDATE：新式寫法 SET 的欄位之間要用逗號，宿主變數加 @
  UPDATE ztr21_stud SET score   = 90,
                        upduser = @sy-uname,
                        upddate = @sy-datum
    WHERE id = 'S0001'.
  IF sy-subrc = 0.
    WRITE / 'UPDATE S0001 成績 90：成功'.
  ENDIF.

* 6) MODIFY：來源是變數時寫 @gs_stud
  DATA(gs_stud) = VALUE ztr21_stud( id = 'S0004' name = '張三豐' score = 45
                                    upduser = sy-uname upddate = sy-datum ).
  MODIFY ztr21_stud FROM @gs_stud.
  WRITE: / 'MODIFY S0004（新增）：sy-subrc =', sy-subrc.

  gs_stud-score = 75.
  MODIFY ztr21_stud FROM @gs_stud.
  WRITE: / 'MODIFY S0004（修改為 75）：sy-subrc =', sy-subrc.

* 7) DELETE
  DELETE FROM ztr21_stud WHERE id = 'S0003'.
  IF sy-subrc = 0.
    WRITE / 'DELETE S0003：成功'.
  ENDIF.

* 8) 讀回全表驗證
  WRITE / '=== 目前表內容 ==='.
  SELECT * FROM ztr21_stud INTO TABLE @DATA(gt_stud).
  LOOP AT gt_stud INTO gs_stud.
    WRITE: / gs_stud-id, gs_stud-name, gs_stud-score.
  ENDLOOP.

* 9) 外鍵教學：先準備班級主檔
  DELETE FROM ztr21_class WHERE klasse = 'S101'.
  INSERT ztr21_class FROM @( VALUE #( klasse = 'S101' klname = '資訊一班' ) ).
  WRITE: / 'INSERT 班級 S101（資訊一班）：sy-subrc =', sy-subrc.

* 10) 合法 KLASSE
  INSERT ztr21_stud FROM @( VALUE #( id = 'S0005' name = '林小華' score = 88 klasse = 'S101'
                                     upduser = sy-uname upddate = sy-datum ) ).
  WRITE: / 'INSERT S0005（KLASSE=S101，合法班級）：sy-subrc =', sy-subrc.

* 11) 不存在的 KLASSE：Open SQL 不受 DDIC 外鍵影響
  INSERT ztr21_stud FROM @( VALUE #( id = 'S0006' name = '吳小芳' score = 79 klasse = 'ZZZZ'
                                     upduser = sy-uname upddate = sy-datum ) ).
  WRITE: / 'INSERT S0006（KLASSE=ZZZZ，班級不存在）：sy-subrc =', sy-subrc.
  WRITE / '  → 對比：sy-subrc = 0，程式端 INSERT 依然成功！'.
  WRITE / '  → DDIC 外鍵是「畫面層防呆」（SM30/Dynpro 才會擋），不是「資料庫層 constraint」，'.
  WRITE / '     Open SQL 呼叫不會被擋下來，資料正確性仍要靠程式自行檢查。'.

* 12) COMMIT WORK：沒有新式寫法
  COMMIT WORK.
