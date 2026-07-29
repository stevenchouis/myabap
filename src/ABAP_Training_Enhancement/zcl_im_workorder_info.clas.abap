class ZCL_IM_WORKORDER_INFO definition
  public
  final
  create public .

public section.

  interfaces IF_EX_WORKORDER_INFOSYSTEM .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_WORKORDER_INFO IMPLEMENTATION.


  method IF_EX_WORKORDER_INFOSYSTEM~AT_OUTPUT_SCREEN.
  endmethod.


  method IF_EX_WORKORDER_INFOSYSTEM~AT_OUTPUT_SCREEN_LAY.
  endmethod.


  method IF_EX_WORKORDER_INFOSYSTEM~AT_SELECTION_SCREEN.
  endmethod.


  method IF_EX_WORKORDER_INFOSYSTEM~DETAIL_LIST_LAY.
  endmethod.


  method IF_EX_WORKORDER_INFOSYSTEM~ORDER_TABLES_MODIFY.
  endmethod.


  method IF_EX_WORKORDER_INFOSYSTEM~OVERVIEW_MODIFY.
  endmethod.


  method IF_EX_WORKORDER_INFOSYSTEM~OVERVIEW_TREE_LAY.
  endmethod.


  method IF_EX_WORKORDER_INFOSYSTEM~PLANNED_ORDER_TABLES_MODIFY.
  endmethod.


  method IF_EX_WORKORDER_INFOSYSTEM~TABLES_MODIFY_LAY.
* Populate ZZEXTWG (External Material Group, from the header
* material's Basic View) on the COOIS header list, sourced from
* MARA-EXTWG via the order's header material (CT_IOHEADER-MATNR).
    DATA: ls_ioheader TYPE ioheader.

    LOOP AT ct_ioheader INTO ls_ioheader.
      IF ls_ioheader-matnr IS NOT INITIAL.
        SELECT SINGLE extwg
          FROM mara
          INTO ls_ioheader-zzextwg
          WHERE matnr = ls_ioheader-matnr.
        MODIFY ct_ioheader FROM ls_ioheader.
      ENDIF.
    ENDLOOP.
  endmethod.
ENDCLASS.