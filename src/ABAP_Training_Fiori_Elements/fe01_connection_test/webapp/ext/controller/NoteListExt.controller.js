sap.ui.define(
    ["sap/ui/core/mvc/ControllerExtension", "sap/ui/core/library"],
    function (ControllerExtension, coreLibrary) {
        "use strict";

        var MessageType = coreLibrary.MessageType;

        return ControllerExtension.extend("fe01connectiontest.ext.controller.NoteListExt", {
            override: {
                onInit: function () {
                    // 一般 UI5 controller lifecycle hook，跟框架自己的 onInit 一起被呼叫，不會互相取代
                    // eslint-disable-next-line no-console
                    console.log("[NoteListExt] onInit fired");
                },
                routing: {
                    // FE 框架專屬的 lifecycle hook，只在頁面停留期間「真正建立新綁定」時觸發一次（導覽進頁面、首次把資料綁上表格）；
                    // 實測確認：同一頁停留期間按 Go 重新查詢不會再次觸發，這個 Hook 綁的是「路由/導覽」不是「表格資料重新整理」
                    onAfterBinding: function (oBindingContext, mParameters) {
                        var extensionAPI = this.base.getExtensionAPI();
                        var sNow = new Date().toLocaleTimeString();

                        extensionAPI.setCustomMessage({
                            message: "資料於 " + sNow + " 重新載入完成（這則訊息由 Controller Extension 的 routing.onAfterBinding 動態產生）",
                            type: MessageType.Information
                        });
                    }
                }
            }
        });
    }
);
