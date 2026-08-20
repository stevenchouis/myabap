sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"fe09tasksummary/test/integration/pages/TaskSummaryList.gen",
	"fe09tasksummary/test/integration/pages/TaskSummaryObjectPage.gen"
], function (JourneyRunner, TaskSummaryListGenerated, TaskSummaryObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('fe09tasksummary') + '/test/flp.html#app-preview',
        pages: {
			onTheTaskSummaryListGenerated: TaskSummaryListGenerated,
			onTheTaskSummaryObjectPageGenerated: TaskSummaryObjectPageGenerated
        },
        async: true
    });

    return runner;
});

