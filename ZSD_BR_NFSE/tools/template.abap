*---------------------------------------------------------------------*
* Report    ZSD_BR_NFSE_DDIC_GEN                                      *
*---------------------------------------------------------------------*
* Date:                 12.10.2026                                    *
* Developer:            Renato Santos                                 *
* IT Responsible:       Renato Santos                                 *
* Business Responsible: Juliana Reimberg                              *
*---------------------------------------------------------------------*
* Functional description                                              *
* One-off generator for the dictionary objects of the NFS-e upload    *
* solution (ZSD_BR_NFSE_UPLOAD / _ADM). Run once in the development   *
* system, BEFORE the programs are activated. It creates, registers in *
* the package and records in the transport request:                   *
*   - 7 domains (with fixed values)                                   *
*   - 71 data elements (English labels)                               *
*   - 4 tables ZSD_BR_NFSE_FILE / _DATA / _LOG / _PARM                *
*   - message class ZSD_BR_NFSE_MSG with messages 001 - 046           *
* Objects that already exist are skipped, never overwritten.          *
* "Test run" (default) only lists what would be created.              *
* Master language of every object: English (guideline item 11).       *
* Still manual afterwards (see ZSD_BR_NFSE_DDIC.md): number range     *
* ZNFSE_FILE, maintenance dialog of ZSD_BR_NFSE_PARM (SE54),          *
* secondary indexes, transactions, GUI statuses, text symbols.        *
* Uses the dictionary function modules behind SE11 (DDIF_*_PUT /      *
* DDIF_*_ACTIVATE) - not released by SAP, development system only.    *
*---------------------------------------------------------------------*
* Authorization logic                                                 *
* S_DEVELOP (package, object type, ACTVT 02) checked before anything  *
* is created. The DDIF function modules and the transport functions   *
* perform their own standard checks as well.                          *
*---------------------------------------------------------------------*
* Change history                                                      *
* 12.10.2026  Renato Santos                                           *
* Initial version.                                                    *
* 06.11.2026  Alexandre Marcondes Silva                               *
* v0.5 - ZSD_BR_NFSE_PARM with delivery class A; maintenance flag     *
*   follows the change-logging flag. New message 047.                 *
*---------------------------------------------------------------------*
REPORT zsd_br_nfse_ddic_gen.

TYPE-POOLS: icon.

*---------------------------------------------------------------------*
* Constants
*---------------------------------------------------------------------*
CONSTANTS:
  gc_lang       TYPE spras    VALUE 'E',        " master language: English
  gc_msgid      TYPE arbgb    VALUE 'ZSD_BR_NFSE_MSG',
  gc_msg_text   TYPE natxt    VALUE 'NFS-e upload and NF Writer creation',
  gc_amount_tab TYPE tabname  VALUE 'ZSD_BR_NFSE_DATA',
  gc_pgmid      TYPE pgmid    VALUE 'R3TR'.

*---------------------------------------------------------------------*
* Types
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF gty_domain,
    name      TYPE domname,
    datatype  TYPE datatype_d,
    leng      TYPE ddleng,
    decimals  TYPE decimals,
    lowercase TYPE lowercase,
    text      TYPE as4text,
  END OF gty_domain,
  BEGIN OF gty_fixval,
    domname TYPE domname,
    valpos  TYPE valpos,
    value   TYPE domvalue_l,
    text    TYPE val_text,
  END OF gty_fixval,
  BEGIN OF gty_dtel,
    name     TYPE rollname,
    domname  TYPE domname,          " domain-based, or ...
    datatype TYPE datatype_d,       " ... predefined type
    leng     TYPE ddleng,
    decimals TYPE decimals,
    short    TYPE scrtext_s,
    medium   TYPE scrtext_m,
    long     TYPE scrtext_l,
  END OF gty_dtel,
  BEGIN OF gty_table,
    name     TYPE tabname,
    text     TYPE as4text,
    contflag TYPE contflag,
    tabart   TYPE tabart,
    tabkat   TYPE tabkat,
    logging  TYPE abap_bool,
  END OF gty_table,
  BEGIN OF gty_field,
    tabname   TYPE tabname,
    fieldname TYPE fieldname,
    key       TYPE abap_bool,
    rollname  TYPE rollname,
    reftable  TYPE tabname,
    reffield  TYPE fieldname,
  END OF gty_field,
  BEGIN OF gty_message,
    msgnr TYPE msgnr,
    text  TYPE natxt,
  END OF gty_message,
  BEGIN OF gty_result,
    icon    TYPE icon_d,
    objtype TYPE trobjtype,
    objname TYPE sobj_name,
    action  TYPE char30,
    message TYPE bapi_msg,
  END OF gty_result.

*---------------------------------------------------------------------*
* Global data
*---------------------------------------------------------------------*
DATA:
  gt_domain  TYPE STANDARD TABLE OF gty_domain,
  gt_fixval  TYPE STANDARD TABLE OF gty_fixval,
  gt_dtel    TYPE STANDARD TABLE OF gty_dtel,
  gt_table   TYPE STANDARD TABLE OF gty_table,
  gt_field   TYPE STANDARD TABLE OF gty_field,
  gt_message TYPE STANDARD TABLE OF gty_message,
  gt_result  TYPE STANDARD TABLE OF gty_result.

*---------------------------------------------------------------------*
* Selection screen
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
  PARAMETERS:
    p_devc   TYPE devclass DEFAULT 'ZSD_BR_NFSE' OBLIGATORY,
    p_trkorr TYPE trkorr,
    p_test   AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.

*---------------------------------------------------------------------*
AT SELECTION-SCREEN.
*---------------------------------------------------------------------*
  PERFORM check_selection.

*---------------------------------------------------------------------*
START-OF-SELECTION.
*---------------------------------------------------------------------*
  PERFORM check_authority.
  PERFORM fill_definitions.

  PERFORM process_domains.
  PERFORM process_data_elements.
  PERFORM process_tables.
  PERFORM process_messages.

  PERFORM display_result.

*&---------------------------------------------------------------------*
*&      Form  CHECK_SELECTION
*&---------------------------------------------------------------------*
* Package must exist and must not be local; a real run needs an open
* (modifiable) transport request.
*----------------------------------------------------------------------*
FORM check_selection.

  IF p_devc(1) = '$'.
    MESSAGE 'Use a transportable package, not a local one' TYPE 'E'.
  ENDIF.
  SELECT SINGLE devclass FROM tdevc WHERE devclass = @p_devc INTO @DATA(lv_devc).
  IF sy-subrc <> 0.
    MESSAGE |Package { p_devc } does not exist| TYPE 'E'.
  ENDIF.

  IF p_test = abap_false.
    IF p_trkorr IS INITIAL.
      MESSAGE 'Enter a transport request for a real run' TYPE 'E'.
    ENDIF.
    SELECT SINGLE trkorr FROM e070
      WHERE trkorr   = @p_trkorr
        AND trstatus = 'D'
      INTO @DATA(lv_trkorr).
    IF sy-subrc <> 0.
      MESSAGE |Request { p_trkorr } does not exist or is not modifiable| TYPE 'E'.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORITY
*&---------------------------------------------------------------------*
FORM check_authority.

  DATA lt_types TYPE STANDARD TABLE OF trobjtype WITH DEFAULT KEY.

* Object types as character fields - AUTHORITY-CHECK does not accept strings
  lt_types = VALUE #( ( 'DOMA' ) ( 'DTEL' ) ( 'TABL' ) ( 'MSAG' ) ).

  LOOP AT lt_types INTO DATA(lv_type).
    AUTHORITY-CHECK OBJECT 'S_DEVELOP'
      ID 'DEVCLASS' FIELD p_devc
      ID 'OBJTYPE'  FIELD lv_type
      ID 'OBJNAME'  DUMMY
      ID 'P_GROUP'  DUMMY
      ID 'ACTVT'    FIELD '02'.
    IF sy-subrc <> 0.
      MESSAGE |No development authorization for { lv_type } in package { p_devc }| TYPE 'E'.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  FILL_DEFINITIONS
*&---------------------------------------------------------------------*
* Object definitions - same content as ZSD_BR_NFSE_DDIC.md.
*----------------------------------------------------------------------*
FORM fill_definitions.

* Domains and fixed values
@@DOMAINS@@

* Data elements
@@DTELS@@

* Tables and fields
@@TABLES@@

* Messages of ZSD_BR_NFSE_MSG
@@MESSAGES@@

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  PROCESS_DOMAINS
*&---------------------------------------------------------------------*
FORM process_domains.

  DATA: ls_dd01v TYPE dd01v,
        lt_dd07v TYPE STANDARD TABLE OF dd07v,
        lv_rc    TYPE sysubrc,
        lv_ok    TYPE abap_bool.

  LOOP AT gt_domain INTO DATA(ls_domain).
    SELECT SINGLE domname FROM dd01l
      WHERE domname = @ls_domain-name AND as4local = 'A'
      INTO @DATA(lv_exists).
    IF sy-subrc = 0.
      PERFORM add_result USING icon_led_yellow 'DOMA' ls_domain-name 'Skipped' 'Already exists'.
      CONTINUE.
    ENDIF.
    IF p_test = abap_true.
      PERFORM add_result USING icon_led_inactive 'DOMA' ls_domain-name 'Would be created' ls_domain-text.
      CONTINUE.
    ENDIF.

    CLEAR: ls_dd01v, lt_dd07v.
    ls_dd01v-domname    = ls_domain-name.
    ls_dd01v-ddlanguage = gc_lang.
    ls_dd01v-datatype   = ls_domain-datatype.
    ls_dd01v-leng       = ls_domain-leng.
    ls_dd01v-decimals   = ls_domain-decimals.
    ls_dd01v-lowercase  = ls_domain-lowercase.
    ls_dd01v-ddtext     = ls_domain-text.
*   Output length: digits + decimal separator + thousands separators
    IF ls_domain-datatype = 'CURR' OR ls_domain-datatype = 'DEC'.
      ls_dd01v-outputlen = ls_domain-leng
                         + COND i( WHEN ls_domain-decimals > 0 THEN 1 ELSE 0 )
                         + ( ls_domain-leng - ls_domain-decimals - 1 ) DIV 3.
    ELSE.
      ls_dd01v-outputlen = ls_domain-leng.
    ENDIF.

    LOOP AT gt_fixval INTO DATA(ls_fixval) WHERE domname = ls_domain-name.
      APPEND VALUE #( domname    = ls_domain-name
                      valpos     = ls_fixval-valpos
                      ddlanguage = gc_lang
                      domvalue_l = ls_fixval-value
                      ddtext     = ls_fixval-text ) TO lt_dd07v.
    ENDLOOP.
    IF lt_dd07v IS NOT INITIAL.
      ls_dd01v-valexi = abap_true.
    ENDIF.

    PERFORM register_object USING 'DOMA' ls_domain-name CHANGING lv_ok.
    CHECK lv_ok = abap_true.

    CALL FUNCTION 'DDIF_DOMA_PUT'
      EXPORTING
        name      = ls_domain-name
        dd01v_wa  = ls_dd01v
      TABLES
        dd07v_tab = lt_dd07v
      EXCEPTIONS
        OTHERS    = 1.
    IF sy-subrc <> 0.
      PERFORM add_result_sy USING 'DOMA' ls_domain-name 'Save failed'.
      CONTINUE.
    ENDIF.

    CALL FUNCTION 'DDIF_DOMA_ACTIVATE'
      EXPORTING
        name   = ls_domain-name
      IMPORTING
        rc     = lv_rc
      EXCEPTIONS
        OTHERS = 1.
    PERFORM add_activation_result USING 'DOMA' ls_domain-name lv_rc sy-subrc.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  PROCESS_DATA_ELEMENTS
*&---------------------------------------------------------------------*
FORM process_data_elements.

  DATA: ls_dd04v TYPE dd04v,
        lv_rc    TYPE sysubrc,
        lv_ok    TYPE abap_bool.

  LOOP AT gt_dtel INTO DATA(ls_dtel).
    SELECT SINGLE rollname FROM dd04l
      WHERE rollname = @ls_dtel-name AND as4local = 'A'
      INTO @DATA(lv_exists).
    IF sy-subrc = 0.
      PERFORM add_result USING icon_led_yellow 'DTEL' ls_dtel-name 'Skipped' 'Already exists'.
      CONTINUE.
    ENDIF.
    IF p_test = abap_true.
      PERFORM add_result USING icon_led_inactive 'DTEL' ls_dtel-name 'Would be created' ls_dtel-long.
      CONTINUE.
    ENDIF.

    CLEAR ls_dd04v.
    ls_dd04v-rollname   = ls_dtel-name.
    ls_dd04v-ddlanguage = gc_lang.
    IF ls_dtel-domname IS NOT INITIAL.
      ls_dd04v-domname = ls_dtel-domname.
      ls_dd04v-refkind = 'D'.
    ELSE.
*     Predefined ABAP Dictionary type, no domain
      ls_dd04v-datatype  = ls_dtel-datatype.
      ls_dd04v-leng      = ls_dtel-leng.
      ls_dd04v-decimals  = ls_dtel-decimals.
      ls_dd04v-outputlen = ls_dtel-leng.
    ENDIF.
    ls_dd04v-ddtext    = ls_dtel-long.
    ls_dd04v-reptext   = ls_dtel-medium.
    ls_dd04v-scrtext_s = ls_dtel-short.
    ls_dd04v-scrtext_m = ls_dtel-medium.
    ls_dd04v-scrtext_l = ls_dtel-long.
    ls_dd04v-headlen   = 20.
    ls_dd04v-scrlen1   = 10.
    ls_dd04v-scrlen2   = 20.
    ls_dd04v-scrlen3   = 40.

    PERFORM register_object USING 'DTEL' ls_dtel-name CHANGING lv_ok.
    CHECK lv_ok = abap_true.

    CALL FUNCTION 'DDIF_DTEL_PUT'
      EXPORTING
        name     = ls_dtel-name
        dd04v_wa = ls_dd04v
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
      PERFORM add_result_sy USING 'DTEL' ls_dtel-name 'Save failed'.
      CONTINUE.
    ENDIF.

    CALL FUNCTION 'DDIF_DTEL_ACTIVATE'
      EXPORTING
        name   = ls_dtel-name
      IMPORTING
        rc     = lv_rc
      EXCEPTIONS
        OTHERS = 1.
    PERFORM add_activation_result USING 'DTEL' ls_dtel-name lv_rc sy-subrc.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  PROCESS_TABLES
*&---------------------------------------------------------------------*
* Transparent, client-dependent tables. Amount fields refer to
* ZSD_BR_NFSE_DATA-WAERS. ZSD_BR_NFSE_PARM is an application table
* (delivery class A - maintained directly in each client, no transport
* request), maintainable and with change logging.
*----------------------------------------------------------------------*
FORM process_tables.

  DATA: ls_dd02v TYPE dd02v,
        ls_dd09l TYPE dd09l,
        lt_dd03p TYPE STANDARD TABLE OF dd03p,
        lv_pos   TYPE tabfdpos,
        lv_rc    TYPE sysubrc,
        lv_ok    TYPE abap_bool.

  LOOP AT gt_table INTO DATA(ls_table).
    SELECT SINGLE tabname FROM dd02l
      WHERE tabname = @ls_table-name AND as4local = 'A'
      INTO @DATA(lv_exists).
    IF sy-subrc = 0.
      PERFORM add_result USING icon_led_yellow 'TABL' ls_table-name 'Skipped' 'Already exists'.
      CONTINUE.
    ENDIF.
    IF p_test = abap_true.
      PERFORM add_result USING icon_led_inactive 'TABL' ls_table-name 'Would be created' ls_table-text.
      CONTINUE.
    ENDIF.

    CLEAR: ls_dd02v, ls_dd09l, lt_dd03p, lv_pos.
    ls_dd02v-tabname    = ls_table-name.
    ls_dd02v-ddlanguage = gc_lang.
    ls_dd02v-tabclass   = 'TRANSP'.
    ls_dd02v-clidep     = abap_true.
    ls_dd02v-ddtext     = ls_table-text.
    ls_dd02v-contflag   = ls_table-contflag.
*   Only the parameter table (the one with change logging) is maintained
*   in the dialog; the log tables keep restricted maintenance
    ls_dd02v-mainflag   = COND #( WHEN ls_table-logging = abap_true THEN 'X' ELSE ' ' ).
    ls_dd02v-exclass    = '1'.                          " cannot be enhanced

    ls_dd09l-tabname  = ls_table-name.
    ls_dd09l-as4local = 'A'.
    ls_dd09l-tabkat   = ls_table-tabkat.
    ls_dd09l-tabart   = ls_table-tabart.
    ls_dd09l-bufallow = 'N'.                              " no buffering
    ls_dd09l-protokoll = ls_table-logging.

    LOOP AT gt_field INTO DATA(ls_field) WHERE tabname = ls_table-name.
      lv_pos = lv_pos + 1.
      APPEND VALUE #( tabname    = ls_table-name
                      fieldname  = ls_field-fieldname
                      ddlanguage = gc_lang
                      position   = lv_pos
                      keyflag    = ls_field-key
                      notnull    = ls_field-key
                      rollname   = ls_field-rollname
                      reftable   = ls_field-reftable
                      reffield   = ls_field-reffield ) TO lt_dd03p.
    ENDLOOP.

    PERFORM register_object USING 'TABL' ls_table-name CHANGING lv_ok.
    CHECK lv_ok = abap_true.

    CALL FUNCTION 'DDIF_TABL_PUT'
      EXPORTING
        name      = ls_table-name
        dd02v_wa  = ls_dd02v
        dd09l_wa  = ls_dd09l
      TABLES
        dd03p_tab = lt_dd03p
      EXCEPTIONS
        OTHERS    = 1.
    IF sy-subrc <> 0.
      PERFORM add_result_sy USING 'TABL' ls_table-name 'Save failed'.
      CONTINUE.
    ENDIF.

    CALL FUNCTION 'DDIF_TABL_ACTIVATE'
      EXPORTING
        name     = ls_table-name
        auth_chk = abap_true
      IMPORTING
        rc       = lv_rc
      EXCEPTIONS
        OTHERS   = 1.
    PERFORM add_activation_result USING 'TABL' ls_table-name lv_rc sy-subrc.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  PROCESS_MESSAGES
*&---------------------------------------------------------------------*
* Message class header (T100A) and texts (T100), English. Existing
* messages are kept.
*----------------------------------------------------------------------*
FORM process_messages.

  DATA: ls_t100a TYPE t100a,
        lv_ok    TYPE abap_bool,
        lv_new   TYPE i,
        lv_kept  TYPE i,
        lv_action TYPE char30,
        lv_text  TYPE bapi_msg.

  SELECT SINGLE arbgb FROM t100a WHERE arbgb = @gc_msgid INTO @DATA(lv_exists).
  DATA(lv_class_exists) = xsdbool( sy-subrc = 0 ).

  IF p_test = abap_true.
    lv_action = COND #( WHEN lv_class_exists = abap_true THEN 'Messages would be added'
                        ELSE 'Would be created' ).
    lv_text = |{ lines( gt_message ) } messages|.
    PERFORM add_result USING icon_led_inactive 'MSAG' gc_msgid lv_action lv_text.
    RETURN.
  ENDIF.

  PERFORM register_object USING 'MSAG' gc_msgid CHANGING lv_ok.
  IF lv_ok = abap_false.
    RETURN.
  ENDIF.

  IF lv_class_exists = abap_false.
    ls_t100a-arbgb      = gc_msgid.
    ls_t100a-masterlang = gc_lang.
    ls_t100a-stext      = gc_msg_text.
    ls_t100a-respuser   = sy-uname.
    ls_t100a-lastuser   = sy-uname.
    ls_t100a-ldate      = sy-datum.
    ls_t100a-ltime      = sy-uzeit.
    INSERT t100a FROM ls_t100a.
  ENDIF.

  LOOP AT gt_message INTO DATA(ls_message).
    INSERT t100 FROM @( VALUE #( sprsl = gc_lang
                                 arbgb = gc_msgid
                                 msgnr = ls_message-msgnr
                                 text  = ls_message-text ) ).
    IF sy-subrc = 0.
      lv_new = lv_new + 1.
    ELSE.
      lv_kept = lv_kept + 1.                    " message already there - kept as is
    ENDIF.
  ENDLOOP.
  COMMIT WORK.

  lv_text = |{ lv_new } messages created, { lv_kept } already existed|.
  PERFORM add_result USING icon_led_green 'MSAG' gc_msgid 'Created' lv_text.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  REGISTER_OBJECT
*&---------------------------------------------------------------------*
* Object directory entry (TADIR) in the package and entry in the
* transport request.
*----------------------------------------------------------------------*
FORM register_object USING    uv_type TYPE any
                              uv_name TYPE any
                     CHANGING cv_ok   TYPE abap_bool.

  DATA: lt_e071  TYPE STANDARD TABLE OF e071,
        lt_e071k TYPE STANDARD TABLE OF e071k,
        lv_type  TYPE trobjtype,
        lv_name  TYPE sobj_name,
        lv_text  TYPE bapi_msg.

  cv_ok   = abap_false.
  lv_type = uv_type.
  lv_name = uv_name.

  SELECT SINGLE devclass FROM tadir
    WHERE pgmid = @gc_pgmid AND object = @lv_type AND obj_name = @lv_name
    INTO @DATA(lv_devclass).
  IF sy-subrc <> 0.
    CALL FUNCTION 'TR_TADIR_INTERFACE'
      EXPORTING
        wi_test_modus       = abap_false
        wi_tadir_pgmid      = gc_pgmid
        wi_tadir_object     = lv_type
        wi_tadir_obj_name   = lv_name
        wi_tadir_devclass   = p_devc
        wi_tadir_masterlang = gc_lang
      EXCEPTIONS
        OTHERS              = 1.
    IF sy-subrc <> 0.
      PERFORM add_result_sy USING lv_type lv_name 'Object directory entry failed'.
      RETURN.
    ENDIF.
  ELSEIF lv_devclass <> p_devc.
    lv_text = |Object already registered in package { lv_devclass }|.
    PERFORM add_result USING icon_led_red lv_type lv_name 'Not created' lv_text.
    RETURN.
  ENDIF.

  APPEND VALUE #( pgmid = gc_pgmid object = lv_type obj_name = lv_name ) TO lt_e071.
  CALL FUNCTION 'TR_APPEND_TO_COMM_OBJS_KEYS'
    EXPORTING
      wi_trkorr = p_trkorr
    TABLES
      wt_e071   = lt_e071
      wt_e071k  = lt_e071k
    EXCEPTIONS
      OTHERS    = 1.
  IF sy-subrc <> 0.
    PERFORM add_result_sy USING lv_type lv_name 'Transport entry failed'.
    RETURN.
  ENDIF.

  cv_ok = abap_true.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ADD_ACTIVATION_RESULT
*&---------------------------------------------------------------------*
* RC of DDIF_*_ACTIVATE: 0 active, 4 active with warnings, 8 error.
*----------------------------------------------------------------------*
FORM add_activation_result USING uv_type  TYPE any
                                 uv_name  TYPE any
                                 uv_rc    TYPE sysubrc
                                 uv_subrc TYPE sysubrc.

  IF uv_subrc <> 0.
    PERFORM add_result_sy USING uv_type uv_name 'Activation failed'.
  ELSEIF uv_rc = 0.
    PERFORM add_result USING icon_led_green uv_type uv_name 'Created and activated' ''.
  ELSEIF uv_rc = 4.
    PERFORM add_result USING icon_led_yellow uv_type uv_name 'Activated with warnings'
                             'Check the activation log in SE11'.
  ELSE.
    PERFORM add_result USING icon_led_red uv_type uv_name 'Saved, not active'
                             'Activation error - check the activation log in SE11'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ADD_RESULT
*&---------------------------------------------------------------------*
FORM add_result USING uv_icon    TYPE icon_d
                      uv_type    TYPE any
                      uv_name    TYPE any
                      uv_action  TYPE any
                      uv_message TYPE any.

  APPEND VALUE #( icon    = uv_icon
                  objtype = uv_type
                  objname = uv_name
                  action  = uv_action
                  message = uv_message ) TO gt_result.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ADD_RESULT_SY
*&---------------------------------------------------------------------*
* Error line with the system message of the failed call.
*----------------------------------------------------------------------*
FORM add_result_sy USING uv_type   TYPE any
                         uv_name   TYPE any
                         uv_action TYPE any.

  DATA lv_text TYPE bapi_msg.

  IF sy-msgid IS NOT INITIAL.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_text.
  ENDIF.
  PERFORM add_result USING icon_led_red uv_type uv_name uv_action lv_text.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_RESULT
*&---------------------------------------------------------------------*
FORM display_result.

  DATA lo_alv TYPE REF TO cl_salv_table.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_result ).
      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->get_columns( )->set_optimize( abap_true ).
      CAST cl_salv_column_table( lo_alv->get_columns( )->get_column( 'ICON' ) )->set_icon( abap_true ).
      lo_alv->get_display_settings( )->set_list_header(
        COND #( WHEN p_test = abap_true THEN TEXT-h01 ELSE TEXT-h02 ) ).
      lo_alv->display( ).
    CATCH cx_salv_msg cx_salv_not_found INTO DATA(lx_salv).
      MESSAGE lx_salv TYPE 'I'.
  ENDTRY.

ENDFORM.
