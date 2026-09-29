REPORT zr_tr13_docpage_test NO STANDARD PAGE HEADING
                            LINE-SIZE 80
                            LINE-COUNT 10.

* 每張「文件」（這裡用航空公司代碼模擬傳票號碼）各自從第 1 頁起算頁次，
* 頁首印「頁次 n / 該文件總頁數」。
TYPES: BEGIN OF ty_docpage,
         doc        TYPE s_carr_id,
         first_page TYPE i,
         last_page  TYPE i,
       END OF ty_docpage.

DATA: gt_flight  TYPE STANDARD TABLE OF sflight,
      gs_flight  TYPE sflight,
      gt_docpage TYPE STANDARD TABLE OF ty_docpage,
      gs_docpage TYPE ty_docpage,
      gv_doc     TYPE s_carr_id.

TOP-OF-PAGE.
  WRITE: /1 '文件：', gv_doc, 60 '頁次：', (9) '###/###'.
  ULINE.

START-OF-SELECTION.
  SELECT * FROM sflight INTO TABLE gt_flight
    WHERE carrid IN ('AA', 'LH', 'UA').
  SORT gt_flight BY carrid connid fldate.

END-OF-SELECTION.
  PERFORM write_report.
  PERFORM fill_page_numbers.

FORM write_report.
  LOOP AT gt_flight INTO gs_flight.
    AT NEW carrid.
      gv_doc = gs_flight-carrid.
      NEW-PAGE.                              " 每張文件從新的一頁開始
      CLEAR gs_docpage.
      gs_docpage-doc = gs_flight-carrid.
    ENDAT.

    WRITE: / gs_flight-connid, gs_flight-fldate.
    IF gs_docpage-first_page = 0.
      gs_docpage-first_page = sy-pagno.      " 文件第一行寫出後，sy-pagno 就是它的第一頁
    ENDIF.

    AT END OF carrid.
      gs_docpage-last_page = sy-pagno.       " 文件最後一行寫出後的頁次
      APPEND gs_docpage TO gt_docpage.
    ENDAT.
  ENDLOOP.
ENDFORM.

FORM fill_page_numbers.
  DATA: lv_page  TYPE i,
        lv_total TYPE i,
        lv_n     TYPE i,
        lv_nc    TYPE c LENGTH 3,
        lv_tc    TYPE c LENGTH 3,
        lv_text  TYPE c LENGTH 9.

  LOOP AT gt_docpage INTO gs_docpage.
    lv_total = gs_docpage-last_page - gs_docpage-first_page + 1.
    lv_page  = gs_docpage-first_page.
    WHILE lv_page <= gs_docpage-last_page.
      lv_n = lv_page - gs_docpage-first_page + 1.
      lv_nc = lv_n.
      lv_tc = lv_total.
      CONDENSE: lv_nc, lv_tc.
      CONCATENATE lv_nc '/' lv_tc INTO lv_text.
      READ LINE 1 OF PAGE lv_page.           " 頁次在頁首第 1 行
      IF sy-subrc = 0.
        REPLACE '###/###' WITH lv_text INTO sy-lisel.
        MODIFY LINE 1 OF PAGE lv_page.
      ENDIF.
      lv_page = lv_page + 1.
    ENDWHILE.
  ENDLOOP.
ENDFORM.
