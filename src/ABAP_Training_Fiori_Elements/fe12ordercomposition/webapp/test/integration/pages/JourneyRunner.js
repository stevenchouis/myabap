sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"fe12ordercomposition/test/integration/pages/OrderHeaderList.gen",
	"fe12ordercomposition/test/integration/pages/OrderHeaderObjectPage.gen"
], function (JourneyRunner, OrderHeaderListGenerated, OrderHeaderObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('fe12ordercomposition') + '/test/flp.html#app-preview',
        pages: {
			onTheOrderHeaderListGenerated: OrderHeaderListGenerated,
			onTheOrderHeaderObjectPageGenerated: OrderHeaderObjectPageGenerated
        },
        async: true
    });

    return runner;
});

