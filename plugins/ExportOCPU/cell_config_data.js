// this file contains a list of all files that need to be loaded dynamically for this i2b2 Cell
// every file in this list will be loaded after the cell's Init function is called
{
	files:[
		"ExportOCPU_ctrlr.js"
	],
	css:[ 
		"vwExportOCPU.css"
	],
	config: {
		// additional configuration variables that are set by the system
		short_name: "ExportOCPU",
		name: "Export - OpenCPU",
		icons: { size32x32: "ExportOCPU_icon_32x32.png" },
		description: "This plugin allows fast and compressed exports for i2b2",
		category: ["celless","plugin","standard"],
		plugin: {
			isolateHtml: false,  // this means do not use an IFRAME
			isolateComm: true,  // this means to expect the plugin to use AJAX communications provided by the framework
			standardTabs: true, // this means the plugin uses standard tabs at top
			html: {
				source: 'injected_screens.html',
				mainDivId: 'ExportOCPU-mainDiv'
			},
	ocpuUrl : "//xx.xx.xx.xx/ocpu/library/i2b2rplugin/R",
        ocpuHost :  "https://xx.xx.xx.xx"
		}
	}
}
