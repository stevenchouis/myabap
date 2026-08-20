sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"fe08taskprojection/test/integration/pages/TaskList.gen",
	"fe08taskprojection/test/integration/pages/TaskObjectPage.gen"
], function (JourneyRunner, TaskListGenerated, TaskObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('fe08taskprojection') + '/test/flp.html#app-preview',
        pages: {
			onTheTaskListGenerated: TaskListGenerated,
			onTheTaskObjectPageGenerated: TaskObjectPageGenerated
        },
        async: true
    });

    return runner;
});

