*&---------------------------------------------------------------------*
*& Report  ZR_TR12_PRINT_LAYOUT
*& 練習 12：列印排版與頁面規劃（答案程式）
*&---------------------------------------------------------------------*
* LINE-SIZE 132  ：寬機點矩陣 10 CPI 一行 132 字元（窄機/A4 直印選 80）
*                  對應 SAP 列印格式 X_65_132（SPAD 維護）
* LINE-COUNT 65(3)：11 吋連續報表紙 × 6 LPI = 66 行，取 65 留安全邊界；
*                  (3) 表示每頁「保留 3 行」給頁尾（END-OF-PAGE）
* NO STANDARD PAGE HEADING：關掉系統預設表頭，自己用 TOP-OF-PAGE 畫
*&---------------------------------------------------------------------*
REPORT zr_tr12_print_layout NO STANDARD PAGE HEADING
                            LINE-SIZE 132
                            LINE-COUNT 65(3).

TYPES: BEGIN OF ty_item,
         itemno TYPE n LENGTH 4,                  " 項次
         name   TYPE c LENGTH 20,                 " 品名
         qty    TYPE i,                           " 數量
         price  TYPE p LENGTH 8 DECIMALS 2,       " 單價
         amount TYPE p LENGTH 10 DECIMALS 2,      " 金額
       END OF ty_item.

DATA: gt_items TYPE STANDARD TABLE OF ty_item,
      gs_item  TYPE ty_item.

START-OF-SELECTION.
* 產生 150 筆測試資料——故意超過一頁，觀察分頁、頁首、頁尾
  DO 150 TIMES.
    gs_item-itemno = sy-index.
    CONCATENATE '品項' gs_item-itemno INTO gs_item-name.
    gs_item-qty    = sy-index * 3.
    gs_item-price  = sy-index / 2.
    gs_item-amount = gs_item-qty * gs_item-price.
    APPEND gs_item TO gt_items.
  ENDDO.

*----------------------------------------------------------------------*
* WRITE 精確排版：
*   /1      → 換行後從第 1 欄開始
*   2(6)    → 從第 2 欄開始、寬度 6
*   CENTERED / RIGHT-JUSTIFIED → 在指定寬度內置中/靠右（數值預設靠右）
*   CURRENCY 'USD' → 依幣別的小數位格式化金額
*----------------------------------------------------------------------*
  LOOP AT gt_items INTO gs_item.
    WRITE: /1  '|', 2(6)   gs_item-itemno,
            9  '|', 10(20) gs_item-name,
            31 '|', 32(10) gs_item-qty,
            43 '|', 44(14) gs_item-price  CURRENCY 'USD',
            59 '|', 60(16) gs_item-amount CURRENCY 'USD',
            77 '|'.
  ENDLOOP.
  ULINE AT /1(77).
  WRITE: / '報表結束，總筆數 150'.

*----------------------------------------------------------------------*
* TOP-OF-PAGE：每頁開頭（頁首）
*----------------------------------------------------------------------*
TOP-OF-PAGE.
  WRITE: /1   '程式：', (20) sy-repid,
          50(20) '測試列印報表' CENTERED,
          108 '日期：', sy-datum.
  WRITE: /1   '使用者：', (18) sy-uname,
          108 '頁次：', (4) sy-pagno.
  ULINE AT /1(77).
  WRITE: /1  '|', 2(6)   '項次' CENTERED,
          9  '|', 10(20) '品名' CENTERED,
          31 '|', 32(10) '數量' CENTERED,
          43 '|', 44(14) '單價' CENTERED,
          59 '|', 60(16) '金額' CENTERED,
          77 '|'.
  ULINE AT /1(77).

*----------------------------------------------------------------------*
* END-OF-PAGE：每頁結尾（頁尾）
* 只有 LINE-COUNT 有保留行數（本例 (3)）才會觸發！
*----------------------------------------------------------------------*
END-OF-PAGE.
  ULINE AT /1(77).
  WRITE: /1 '審核：____________', 40 '製表：____________'.