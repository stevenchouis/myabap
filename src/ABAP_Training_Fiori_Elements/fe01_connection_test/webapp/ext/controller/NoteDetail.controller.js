sap.ui.define(
    ["sap/fe/core/PageController"],
    function (PageController) {
        "use strict";

        return PageController.extend("fe01connectiontest.ext.controller.NoteDetail", {
            onNavBack: function () {
                window.history.back();
            }
        });
    }
);
