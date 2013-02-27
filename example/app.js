// This is a test harness for your module
// You should do something interesting in this harness 
// to test out the module and to provide instructions 
// to users on how to use it by example.


// open a single window
var win = Ti.UI.createWindow({
	backgroundColor:'white'
});
var label = Ti.UI.createLabel();
win.add(label);
win.open();

// TODO: write your module tests here
var customalert = require('tk.dmap.ti.customalert');
Ti.API.info("module is => " + customalert);

label.text = customalert.example();

Ti.API.info("module exampleProp is => " + customalert.exampleProp);
customalert.exampleProp = "This is a test value";

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

if (Ti.Platform.name == "android") {
	var proxy = customalert.createExample({
		message: "Creating an example Proxy",
		backgroundColor: "red",
		width: 100,
		height: 100,
		top: 100,
		left: 150
	});

	proxy.printMessage("Hello world!");
	proxy.message = "Hi world!.  It's me again.";
	proxy.printMessage("Hello world!");
	win.add(proxy);
}

