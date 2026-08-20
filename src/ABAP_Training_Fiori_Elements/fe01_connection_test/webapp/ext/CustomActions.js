sap.ui.define(["sap/m/MessageToast"], function (MessageToast) {
    "use strict";

    return {
        // 全域 Custom Action 的 press handler：一個單純的 JS 函式，不用宣告 sap.ui.controllerExtensions，
        // 只要在 manifest.json 的 content.header.actions 指到 "<app id>.ext.CustomActions.showInfo" 即可
        showInfo: function (oContext, aSelectedContexts) {
            MessageToast.show("這是 List Report 全域 Custom Action，透過 Extension Point 加的按鈕，不需要完整的 Controller Extension 註冊");
        }
    };
});
