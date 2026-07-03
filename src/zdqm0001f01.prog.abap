*&---------------------------------------------------------------------*
*& Include          ZDQM0001F01
*&---------------------------------------------------------------------*

data: filename type string.

define gui_download.
  FILENAME = &1.
    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        FILENAME                      = filename
        FILETYPE                      = 'ASC'
        WRITE_FIELD_SEPARATOR         = 'X'
      TABLES
        DATA_TAB                      = &2
      EXCEPTIONS
        FILE_WRITE_ERROR              = 1
        NO_BATCH                      = 2
        GUI_REFUSE_FILETRANSFER       = 3
        INVALID_TYPE                  = 4
        NO_AUTHORITY                  = 5
        UNKNOWN_ERROR                 = 6
        HEADER_NOT_ALLOWED            = 7
        SEPARATOR_NOT_ALLOWED         = 8
        FILESIZE_NOT_ALLOWED          = 9
        HEADER_TOO_LONG               = 10
        DP_ERROR_CREATE               = 11
        DP_ERROR_SEND                 = 12
        DP_ERROR_WRITE                = 13
        UNKNOWN_DP_ERROR              = 14
        ACCESS_DENIED                 = 15
        DP_OUT_OF_MEMORY              = 16
        DISK_FULL                     = 17
        DP_TIMEOUT                    = 18
        FILE_NOT_FOUND                = 19
        DATAPROVIDER_EXCEPTION        = 20
        CONTROL_FLUSH_ERROR           = 21
        OTHERS                        = 22
                .
  if sy-subrc <> 0.
    message s999 with '錯誤檔下載失敗:' filename.
  endif.
end-of-definition.
