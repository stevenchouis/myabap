class ZCL_EN08_COMPLOG definition
  public
  final
  create public .

public section.

  class-methods LOG_CHANGE
    importing
      !IT_HEAD type STANDARD TABLE
      !IT_COMP type STANDARD TABLE .
protected section.
private section.

  class-methods GET_USERNAME_TEXT
    importing
      !IV_UNAME type SYUNAME
    returning
      value(RV_TEXT) type TEXT80 .
ENDCLASS.



CLASS ZCL_EN08_COMPLOG IMPLEMENTATION.


  method GET_USERNAME_TEXT.

    data: lv_full_text type string,
          lv_tmp       type string.

    clear rv_text.

    call function 'BM_CONVERT_USER_NAMES'
      exporting
        bname  = iv_uname
      importing
        adress = lv_full_text.

    split lv_full_text at ',' into lv_full_text lv_tmp.
    rv_text = lv_full_text.

  endmethod.


  method LOG_CHANGE.

    types: begin of ty_field,
             fname      type fieldname,
             fname_dscr type text30,
           end of ty_field.

    types: tt_head type standard table of caufvdb,
           tt_comp type standard table of resbb.

    field-symbols: <lt_head> type tt_head,
                   <lt_comp> type tt_comp,
                   <ls_comp> type resbb,
                   <new>     type any,
                   <old>     type any.

    data: lt_field    type standard table of ty_field,
          ls_field    type ty_field,
          lt_resb_old type standard table of resb,
          ls_resb_old type resb,
          ls_head     type caufvdb,
          ls_log      type zen08_complog,
          lt_log      type standard table of zen08_complog,
          lv_updat    type updat,
          lv_uptim    type uptim,
          lv_name     type text80,
          lv_seq      type zen08_seq.

    assign it_head to <lt_head>.
    assign it_comp to <lt_comp>.

    read table <lt_head> into ls_head index 1.
    check sy-subrc = 0.
    check <lt_comp> is not initial.

*   -- Lock the order (see EZEN08_COMPLOG lock object, built in SE11)
    call function 'ENQUEUE_EZEN08_COMPLOG'
      exporting
        mandt          = sy-mandt
        aufnr          = ls_head-aufnr
        artnr          = ls_head-matnr
      exceptions
        foreign_lock   = 1
        system_failure = 2
        others         = 3.

    lv_updat = sy-datum.
    lv_uptim = sy-uzeit.
    lv_name  = get_username_text( sy-uname ).

*   -- fields to compare (component before vs after CO02 change)
    ls_field-fname = 'POSNR'. ls_field-fname_dscr = 'Item Number'.        append ls_field to lt_field.
    ls_field-fname = 'MATNR'. ls_field-fname_dscr = 'Component'.          append ls_field to lt_field.
    ls_field-fname = 'ERFMG'. ls_field-fname_dscr = 'Requirement Qty'.    append ls_field to lt_field.
    ls_field-fname = 'ERFME'. ls_field-fname_dscr = 'Unit of Measure'.    append ls_field to lt_field.
    ls_field-fname = 'WERKS'. ls_field-fname_dscr = 'Plant'.              append ls_field to lt_field.
    ls_field-fname = 'LGORT'. ls_field-fname_dscr = 'Storage Location'.   append ls_field to lt_field.
    ls_field-fname = 'CHARG'. ls_field-fname_dscr = 'Batch'.              append ls_field to lt_field.
    ls_field-fname = 'SCHGT'. ls_field-fname_dscr = 'Bulk Material'.      append ls_field to lt_field.
    ls_field-fname = 'RGEKZ'. ls_field-fname_dscr = 'Backflush'.          append ls_field to lt_field.
    ls_field-fname = 'SOBKZ'. ls_field-fname_dscr = 'Special Stock Ind'.  append ls_field to lt_field.
    ls_field-fname = 'KZEAR'. ls_field-fname_dscr = 'Final Issue'.        append ls_field to lt_field.
    ls_field-fname = 'XLOEK'. ls_field-fname_dscr = 'Deletion Indicator'. append ls_field to lt_field.

*   -- current DB values (before CO02 change) for the changed components
    select * from resb into table lt_resb_old
      for all entries in <lt_comp>
      where rsnum = <lt_comp>-rsnum
        and rspos = <lt_comp>-rspos
        and rsart = <lt_comp>-rsart.

    loop at <lt_comp> assigning <ls_comp> where vbkz = 'I' or vbkz = 'D' or vbkz = 'U'.

      clear ls_resb_old.
      read table lt_resb_old into ls_resb_old
        with key rsnum = <ls_comp>-rsnum
                 rspos = <ls_comp>-rspos
                 rsart = <ls_comp>-rsart.

      clear lv_seq.

      loop at lt_field into ls_field.

        unassign: <new>, <old>.
        assign component ls_field-fname of structure <ls_comp> to <new>.
        check sy-subrc = 0.
        assign component ls_field-fname of structure ls_resb_old to <old>.
        check sy-subrc = 0.

        check <new> <> <old> or <ls_comp>-vbkz = 'D'.

        clear ls_log.
        ls_log-aufnr      = ls_head-aufnr.
        ls_log-artnr      = ls_head-matnr.
        ls_log-updat      = lv_updat.
        ls_log-uptim      = lv_uptim.
        ls_log-rsnum      = <ls_comp>-rsnum.
        ls_log-rspos      = <ls_comp>-rspos.
        ls_log-rsart      = <ls_comp>-rsart.
        lv_seq            = lv_seq + 1.
        ls_log-seq        = lv_seq.
        ls_log-fname      = ls_field-fname.
        ls_log-fname_dscr = ls_field-fname_dscr.
        ls_log-id         = sy-uname.
        ls_log-name       = lv_name.
        ls_log-tcode      = sy-tcode.

        if <ls_comp>-vbkz = 'D'.
          if ls_field-fname = 'ERFMG'.
            write <new> to ls_log-value_old unit ls_resb_old-erfme left-justified.
          else.
            write <new> to ls_log-value_old left-justified.
          endif.
        else.
          if ls_field-fname = 'ERFMG'.
            write <old> to ls_log-value_old unit ls_resb_old-erfme left-justified.
            write <new> to ls_log-value_new unit <ls_comp>-erfme left-justified.
          else.
            write <old> to ls_log-value_old left-justified.
            write <new> to ls_log-value_new left-justified.
          endif.
        endif.

        if <ls_comp>-vbkz = 'I'.
          ls_log-chngind = 'I'.
        elseif ( <ls_comp>-vbkz = 'U' and <ls_comp>-xloek = 'X' ) or <ls_comp>-vbkz = 'D'.
          ls_log-chngind = 'D'.
        elseif <ls_comp>-vbkz = 'U'.
          ls_log-chngind = 'U'.
        else.
          ls_log-chngind = '?'.
        endif.

        append ls_log to lt_log.

      endloop.

    endloop.

    if lt_log is not initial.
      modify zen08_complog from table lt_log.
    endif.

*   -- Unlock
    call function 'DEQUEUE_EZEN08_COMPLOG'
      exporting
        mandt = sy-mandt
        aufnr = ls_head-aufnr
        artnr = ls_head-matnr.

  endmethod.
ENDCLASS.
