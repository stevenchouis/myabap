sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"fe01connectiontest/test/integration/pages/NoteList.gen",
	"fe01connectiontest/test/integration/pages/NoteObjectPage.gen"
], function (JourneyRunner, NoteListGenerated, NoteObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('fe01connectiontest') + '/test/flp.html#app-preview',
        pages: {
			onTheNoteListGenerated: NoteListGenerated,
			onTheNoteObjectPageGenerated: NoteObjectPageGenerated
        },
        async: true
    });

    return runner;
});

