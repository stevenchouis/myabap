*&---------------------------------------------------------------------*
*& Report  ZR_SELSCREEN_DEMO
*& Selection Screen 元件示範（抽自 Z_INVENTORY_COST_REPORT 練習區塊）
*&---------------------------------------------------------------------*
REPORT zr_selscreen_demo.

TABLES: sscrfields. " 必須宣告這個系統結構，才能捕捉按鈕點擊

* --- 同一行：說明文字 + 兩個輸入框 ---
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_b1.
SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(20) text_lbl FOR FIELD p_val1.
  SELECTION-SCREEN POSITION 25.
  PARAMETERS: p_val1 TYPE i.
  SELECTION-SCREEN COMMENT 40(2) text_to.
  SELECTION-SCREEN POSITION 45.
  PARAMETERS: p_val2 TYPE i.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.

* --- 按鈕（全選/全不選）+ 核取方塊 ---
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE t_b2.
SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN POSITION 1.
  SELECTION-SCREEN PUSHBUTTON 1(15) btn_all USER-COMMAND select_all.
  SELECTION-SCREEN POSITION 20.
  SELECTION-SCREEN PUSHBUTTON 20(15) btn_none USER-COMMAND deselect_all.
SELECTION-SCREEN END OF LINE.
PARAMETERS: p_chk1 AS CHECKBOX,
            p_chk2 AS CHECKBOX,
            p_chk3 AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b2.

* --- Radio button 群組（直排，含預設值） ---
SELECTION-SCREEN BEGIN OF BLOCK rad1 WITH FRAME TITLE t_rad1.
PARAMETERS: p_r1_1 RADIOBUTTON GROUP grp1 DEFAULT 'X',
            p_r1_2 RADIOBUTTON GROUP grp1,
            p_r1_3 RADIOBUTTON GROUP grp1.
SELECTION-SCREEN END OF BLOCK rad1.

SELECTION-SCREEN BEGIN OF BLOCK rad2 WITH FRAME TITLE t_rad2.
PARAMETERS: p_r2_a RADIOBUTTON GROUP grp2,
            p_r2_b RADIOBUTTON GROUP grp2 DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK rad2.

* --- Radio button 排在同一列 ---
SELECTION-SCREEN BEGIN OF BLOCK rad3 WITH FRAME TITLE t_rad3.
SELECTION-SCREEN BEGIN OF LINE.
  PARAMETERS: r1 RADIOBUTTON GROUP grp3 DEFAULT 'X'.
  SELECTION-SCREEN COMMENT 3(10) t_r1 FOR FIELD r1.
  SELECTION-SCREEN POSITION 20.
  PARAMETERS: r2 RADIOBUTTON GROUP grp3.
  SELECTION-SCREEN COMMENT 23(10) t_r2 FOR FIELD r2.
  SELECTION-SCREEN POSITION 40.
  PARAMETERS: r3 RADIOBUTTON GROUP grp3.
  SELECTION-SCREEN COMMENT 43(10) t_r3 FOR FIELD r3.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK rad3.

INITIALIZATION.
  t_b1     = '同一行輸入元件'.
  t_b2     = '按鈕與核取方塊'.
  t_rad1   = 'Radio 群組 1'.
  t_rad2   = 'Radio 群組 2'.
  t_rad3   = 'Radio 同一列'.
  text_lbl = '數值範圍'.
  text_to  = '到'.
  btn_all  = '全選'.
  btn_none = '全不選'.
  t_r1     = '選項一'.
  t_r2     = '選項二'.
  t_r3     = '選項三'.

AT SELECTION-SCREEN.
  " 按鈕的 USER-COMMAND 會放在 sscrfields-ucomm
  CASE sscrfields-ucomm.
    WHEN 'SELECT_ALL'.
      p_chk1 = p_chk2 = p_chk3 = 'X'.
    WHEN 'DESELECT_ALL'.
      p_chk1 = p_chk2 = p_chk3 = ' '.
  ENDCASE.

START-OF-SELECTION.
  " 把畫面選擇結果輸出，方便驗證元件行為
  WRITE: / '數值範圍：', p_val1, '到', p_val2.
  WRITE: / '核取方塊：', p_chk1, p_chk2, p_chk3.
  WRITE: / 'Radio 1 ：', p_r1_1, p_r1_2, p_r1_3.
  WRITE: / 'Radio 2 ：', p_r2_a, p_r2_b.
  WRITE: / 'Radio 3 ：', r1, r2, r3.
