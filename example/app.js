// open a single window
var win = Ti.UI.createWindow({});
win.open();

var customalert = require('tk.dmap.ti.customalert');

var alertView = Ti.UI.createView({layout: 'horizontal', top: 0, height: 200});	// DON'T USE 'Ti.UI.SIZE'

var btn = Ti.UI.createButton({title: 'Hello', width: 100, height: 200});
alertView.add(btn);

var alertDialog = customalert.createAlertDialog({
	iOSView: alertView,
    title: 'CustomAlert',
    message: 'Test',
    buttonNames: ['OK', 'Later', 'Cancel']
});
alertDialog.show();
