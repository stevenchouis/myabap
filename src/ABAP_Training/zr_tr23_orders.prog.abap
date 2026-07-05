*&---------------------------------------------------------------------*
*& Report  ZR_TR23_ORDERS
*& 練習 23：期末整合練習 —— 訂單 Header/Detail，LUW all-or-nothing 示範
*& 前提：ZTR23_ORDH（訂單主檔）／ZTR23_ORDI（訂單明細，ORDNO 外鍵指向 ORDH）已建立並啟用
*&---------------------------------------------------------------------*
REPORT zr_tr23_orders.

DATA: gs_ordh TYPE ztr23_ordh,
      gs_ordi TYPE ztr23_ordi.

START-OF-SELECTION.
*----------------------------------------------------------------------*
* 1) 防呆：清掉本程式會用到的舊測試訂單，讓程式可重複執行
*    ORD0001／ORD0002 是本程式的測試訂單；ZZZZZZZZZZ 是外鍵教學用的孤兒明細
*    順序：先刪明細、再刪主檔（雖然 DDIC 外鍵不會擋 Open SQL，但養成好習慣）
*----------------------------------------------------------------------*
  DELETE FROM ztr23_ordi WHERE ordno IN ( 'ORD0001', 'ORD0002', 'ZZZZZZZZZZ' ).
  WRITE: / '清除舊測試明細：', sy-dbcnt, '筆'.
  DELETE FROM ztr23_ordh WHERE ordno IN ( 'ORD0001', 'ORD0002' ).
  WRITE: / '清除舊測試主檔：', sy-dbcnt, '筆'.
  COMMIT WORK.

*----------------------------------------------------------------------*
* 2) 正常情境：INSERT 一筆 Header（ORD0001）+ 兩筆明細，走完就 COMMIT WORK
*----------------------------------------------------------------------*
  WRITE / '=== 正常情境：建立訂單 ORD0001 ==='.

  CLEAR gs_ordh.
  gs_ordh-ordno    = 'ORD0001'.
  gs_ordh-customer = '王小美商行'.
  gs_ordh-orddate  = sy-datum.
  gs_ordh-status   = 'N'.
  gs_ordh-upduser  = sy-uname.
  gs_ordh-upddate  = sy-datum.
  INSERT ztr23_ordh FROM gs_ordh.
  WRITE: / 'INSERT Header ORD0001：sy-subrc =', sy-subrc.

  CLEAR gs_ordi.
  gs_ordi-ordno    = 'ORD0001'.
  gs_ordi-itemno   = '001'.
  gs_ordi-product  = 'NOTEBOOK'.
  gs_ordi-qty      = 2.
  gs_ordi-price    = '25000.00'.
  gs_ordi-upduser  = sy-uname.
  gs_ordi-upddate  = sy-datum.
  INSERT ztr23_ordi FROM gs_ordi.
  WRITE: / 'INSERT Item ORD0001/001（NOTEBOOK）：sy-subrc =', sy-subrc.

  gs_ordi-itemno  = '002'.
  gs_ordi-product = 'MOUSE'.
  gs_ordi-qty     = 5.
  gs_ordi-price   = '500.00'.
  INSERT ztr23_ordi FROM gs_ordi.
  WRITE: / 'INSERT Item ORD0001/002（MOUSE）：sy-subrc =', sy-subrc.

  COMMIT WORK.
  WRITE / '  → COMMIT WORK 完成，ORD0001 連同兩筆明細正式落地。'.

*----------------------------------------------------------------------*
* 3)【重點教學】LUW all-or-nothing：一筆訂單處理到一半失敗，整包撤銷
*----------------------------------------------------------------------*
  WRITE / ' '.
  WRITE / '=== LUW 示範：建立訂單 ORD0002，過程中失敗 → ROLLBACK WORK ==='.

  CLEAR gs_ordh.
  gs_ordh-ordno    = 'ORD0002'.
  gs_ordh-customer = '測試貿易有限公司'.
  gs_ordh-orddate  = sy-datum.
  gs_ordh-status   = 'N'.
  gs_ordh-upduser  = sy-uname.
  gs_ordh-upddate  = sy-datum.
  INSERT ztr23_ordh FROM gs_ordh.
  WRITE: / 'INSERT Header ORD0002：sy-subrc =', sy-subrc.

  CLEAR gs_ordi.
  gs_ordi-ordno    = 'ORD0002'.
  gs_ordi-itemno   = '001'.
  gs_ordi-product  = 'KEYBOARD'.
  gs_ordi-qty      = 3.
  gs_ordi-price    = '1200.00'.
  gs_ordi-upduser  = sy-uname.
  gs_ordi-upddate  = sy-datum.
  INSERT ztr23_ordi FROM gs_ordi.
  WRITE: / 'INSERT Item ORD0002/001（第一次）：sy-subrc =', sy-subrc.

* 故意再 INSERT 同一筆明細：主鍵重複，模擬「這筆訂單處理到一半失敗」
  INSERT ztr23_ordi FROM gs_ordi.
  WRITE: / 'INSERT Item ORD0002/001（重複 INSERT，模擬處理失敗）：sy-subrc =', sy-subrc.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    WRITE / '  → 偵測到 sy-subrc <> 0，執行 ROLLBACK WORK：整個 LUW（含之前的 Header INSERT）全部撤銷。'.
  ENDIF.

  SELECT SINGLE * FROM ztr23_ordh INTO @DATA(gs_check) WHERE ordno = 'ORD0002'.
  WRITE: / '查詢 Header ORD0002（ROLLBACK 之後）：sy-subrc =', sy-subrc.
  IF sy-subrc <> 0.
    WRITE / '  → 查無此訂單！雖然 Header 當時 INSERT 是成功的（sy-subrc = 0），'.
    WRITE / '     但因為整個過程還沒 COMMIT WORK，ROLLBACK WORK 把同一個 LUW 裡'.
    WRITE / '     「已經寫入但尚未提交」的 Header 也一併撤銷了。'.
    WRITE / '     這就是 LUW（Logical Unit of Work）「all-or-nothing」的意義：'.
    WRITE / '     一筆訂單裡只要有任何一步失敗，寧可整包撤銷，也不要留下「只有 Header 沒有明細」的髒資料。'.
  ENDIF.

*----------------------------------------------------------------------*
* 4)【複習 ex21】DDIC 外鍵只是畫面層防呆，Open SQL 完全不會擋
*----------------------------------------------------------------------*
  WRITE / ' '.
  WRITE / '=== 複習 ex21：DDIC 外鍵不會擋 Open SQL ==='.

  CLEAR gs_ordi.
  gs_ordi-ordno    = 'ZZZZZZZZZZ'.        " ZTR23_ORDH 裡沒有這個訂單號
  gs_ordi-itemno   = '001'.
  gs_ordi-product  = 'GHOST-ITEM'.
  gs_ordi-qty      = 1.
  gs_ordi-price    = '1.00'.
  gs_ordi-upduser  = sy-uname.
  gs_ordi-upddate  = sy-datum.
  INSERT ztr23_ordi FROM gs_ordi.
  WRITE: / 'INSERT Item ORDNO=ZZZZZZZZZZ（訂單不存在於 ZTR23_ORDH）：sy-subrc =', sy-subrc.
  WRITE / '  → 對比：sy-subrc = 0，程式端 INSERT 依然成功！'.
  WRITE / '  → DDIC 外鍵（screenCheck）只在 SM30／Dynpro 這類畫面輸入時發生作用，'.
  WRITE / '     不是資料庫層的 constraint，Open SQL 呼叫不受影響，資料正確性仍要靠程式自行檢查。'.

*----------------------------------------------------------------------*
* 5) JOIN：訂單主檔 + 明細，印出 ORD0001 的完整內容
*    ON 條件不寫 MANDT（client field 由編譯器自動處理）
*----------------------------------------------------------------------*
  WRITE / ' '.
  WRITE / '=== JOIN 查詢：ORD0001 完整內容（訂單／客戶／日期／狀態／序號／產品／數量／單價） ==='.

  SELECT h~ordno, h~customer, h~orddate, h~status,
         i~itemno, i~product, i~qty, i~price
    FROM ztr23_ordh AS h
    INNER JOIN ztr23_ordi AS i
      ON i~ordno = h~ordno
    WHERE h~ordno = 'ORD0001'
    ORDER BY i~itemno
    INTO TABLE @DATA(gt_join).

  LOOP AT gt_join INTO DATA(gs_join).
    WRITE: / gs_join-ordno, gs_join-customer, gs_join-orddate, gs_join-status,
             gs_join-itemno, gs_join-product, gs_join-qty, gs_join-price.
  ENDLOOP.

*----------------------------------------------------------------------*
* 6) 明確結束這個 LUW：把第 4 步的孤兒明細（ZZZZZZZZZZ）也一併確認落地
*----------------------------------------------------------------------*
  COMMIT WORK.
  WRITE / ' '.
  WRITE / '=== 最終 COMMIT WORK 完成 ==='.
