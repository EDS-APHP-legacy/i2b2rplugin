/**
 * @projectDescription	Example using the Patient Data Object (PDO).
 * @inherits	i2b2
 * @namespace	i2b2.ExportOCPU
 * @author	Nick Benik, Griffin Weber MD PhD
 * @version 	1.3
 * ----------------------------------------------------------------------------------------
 * updated 11-06-08: 	Initial Launch [Nick Benik] 
 */

i2b2.ExportOCPU.Init = function(loadedDiv) {
	//NPS load ocpu url for cors
	ocpu.seturl(i2b2.ExportOCPU.cfg.config.plugin.ocpuUrl);
	// register DIV as valid DragDrop target for Patient Record Sets (PRS) objects
	var op_trgt = {dropTarget:true};
	i2b2.sdx.Master.AttachType("ExportOCPU-CONCPTDROP", "CONCPT", op_trgt);
	i2b2.sdx.Master.AttachType("ExportOCPU-PRSDROP", "PRS", op_trgt);
	i2b2.sdx.Master.AttachType("ExportOCPU-ENSDROP", "ENS", op_trgt);
	// drop event handlers used by this plugin
//	i2b2.sdx.Master.setHandlerCustom("ExportOCPU-CONCPTDROP", "CONCPT", "DropHandler", i2b2.ExportOCPU.conceptDropped);
	i2b2.sdx.Master.setHandlerCustom("ExportOCPU-PRSDROP", "PRS", "DropHandler", i2b2.ExportOCPU.prsDropped);
	i2b2.sdx.Master.setHandlerCustom("ExportOCPU-ENSDROP", "ENS", "DropHandler", i2b2.ExportOCPU.ensDropped);
	// set default output options
	i2b2.ExportOCPU.model.outputOptions = {};
	i2b2.ExportOCPU.model.outputOptions.patients = true;
	i2b2.ExportOCPU.model.outputOptions.events = true;
	i2b2.ExportOCPU.model.outputOptions.observations = true;
	i2b2.ExportOCPU.model.outputOptions.modifiers = true;
	i2b2.ExportOCPU.model.outputOptions.observers = true;

	// manage YUI tabs
	this.yuiTabs = new YAHOO.widget.TabView("ExportOCPU-TABS", {activeIndex:0});
};

i2b2.ExportOCPU.Unload = function() {
	// purge old data
	i2b2.ExportOCPU.model.prsRecord = false;
	i2b2.ExportOCPU.model.ensRecord = false;
	i2b2.ExportOCPU.model.conceptRecord = false;
	i2b2.ExportOCPU.model.dirtyResultsData = true;
	i2b2.ExportOCPU.model.outputOptions.patients = true;
	i2b2.ExportOCPU.model.outputOptions.events = false;
	i2b2.ExportOCPU.model.outputOptions.observations = false;
	i2b2.ExportOCPU.model.outputOptions.modifiers = false;
	i2b2.ExportOCPU.model.outputOptions.observers = false;	
	return true;
};

i2b2.ExportOCPU.prsDropped = function(sdxData) {
	sdxData = sdxData[0];	// only interested in first record
	// save the info to our local data model
	i2b2.ExportOCPU.model.prsRecord = sdxData;
	// let the user know that the drop was successful by displaying the name of the patient set
	$("ExportOCPU-PRSDROP").innerHTML = i2b2.h.Escape(sdxData.sdxInfo.sdxDisplayName);
	// temporarly change background color to give GUI feedback of a successful drop occuring
	$("ExportOCPU-PRSDROP").style.background = "#CFB";
	setTimeout("$('ExportOCPU-PRSDROP').style.background='#DEEBEF'", 250);	
	// optimization to prevent requerying the hive for new results if the input dataset has not changed
	i2b2.ExportOCPU.model.dirtyResultsData = true;		

};

i2b2.ExportOCPU.ensDropped = function(sdxData) {
	sdxData = sdxData[0];	// only interested in first record
	// save the info to our local data model
	i2b2.ExportOCPU.model.ensRecord = sdxData;
	// let the user know that the drop was successful by displaying the name of the patient set
	$("ExportOCPU-ENSDROP").innerHTML = i2b2.h.Escape(sdxData.sdxInfo.sdxDisplayName);
	// temporarly change background color to give GUI feedback of a successful drop occuring
	$("ExportOCPU-ENSDROP").style.background = "#CFB";
	setTimeout("$('ExportOCPU-ENSDROP').style.background='#DEEBEF'", 250);	
	// optimization to prevent requerying the hive for new results if the input dataset has not changed
	i2b2.ExportOCPU.model.dirtyResultsData = true;		

};


/*i2b2.ExportOCPU.conceptDropped = function(sdxData) {
	sdxData = sdxData[0];	// only interested in first record
	// save the info to our local data model
	i2b2.ExportOCPU.model.conceptRecord = sdxData;
	// let the user know that the drop was successful by displaying the name of the concept
	$("ExportOCPU-CONCPTDROP").innerHTML = i2b2.h.Escape(sdxData.sdxInfo.sdxDisplayName);
	// temporarly change background color to give GUI feedback of a successful drop occuring
	$("ExportOCPU-CONCPTDROP").style.background = "#CFB";
	setTimeout("$('ExportOCPU-CONCPTDROP').style.background='#DEEBEF'", 250);	
	// optimization to prevent requerying the hive for new results if the input dataset has not changed
	i2b2.ExportOCPU.model.dirtyResultsData = true;		
};*/

i2b2.ExportOCPU.chgOutputOption = function(ckBox,option) {
	i2b2.ExportOCPU.model.outputOptions[option] = ckBox.checked;
	i2b2.ExportOCPU.model.dirtyResultsData = true;
};

i2b2.ExportOCPU.invalidateButton = function(that) {
	that.disabled=true;
	that.value="Downloading...";
};

i2b2.ExportOCPU.validateForm = function() {
		var flag = true;
		var msg = "---------------------------------------------------------------------\n";
		if( !i2b2.ExportOCPU.model.ensRecord & !i2b2.ExportOCPU.model.prsRecord ){//A SET
			flag = false;
			msg += "Drop a patient or an encounter set\n";
		}

		if(!document.getElementById("ExportOCPU-OutputPatient").checked       &
                   !document.getElementById("ExportOCPU-OutputEvents").checked        &
                   !document.getElementById("ExportOCPU-OutputObservations").checked  &
                   !document.getElementById("ExportOCPU-OutputTerminologies").checked &
                   !document.getElementById("ExportOCPU-OutputDocumentation").checked
		  ){//A CHECK
			flag = false;
			msg += "Check something to export\n";
		}
		if(document.getElementById('purpose').value.length < 10){//A PURPOSE
			flag = false;
			msg += "The purpose of the search must be greater than 10 characters\n";
		}
		if(!document.getElementById('condition').checked){//A PURPOSE
			flag = false;
			msg += "Accept the conditions\n";
		}
		msg += "---------------------------------------------------------------------\n";
		if(!flag){alert(msg);}
		return flag;
};

i2b2.ExportOCPU.download = function(){
var exportData = (document.getElementById("ExportOCPU-OutputPatient").checked?";1":"")
    exportData += (document.getElementById("ExportOCPU-OutputEvents").checked?";2":"")
    exportData += (document.getElementById("ExportOCPU-OutputObservations").checked?";3":"")
    exportData += (document.getElementById("ExportOCPU-OutputTerminologies").checked?";4":"")
    exportData += (document.getElementById("ExportOCPU-OutputDocumentation").checked?";5":"")
 var idResult;
     if(i2b2.ExportOCPU.model.ensRecord){
	     idResult = i2b2.ExportOCPU.model.ensRecord.origData.PRS_id;
     }else if(i2b2.ExportOCPU.model.prsRecord){
	     idResult = i2b2.ExportOCPU.model.prsRecord.origData.PRS_id;
     }else{alert("unresolved error");}
 var req = ocpu.call("downloadAsCsv",{
                           idUser        : i2b2.PM.model.login_username,
                           idResult        : idResult,
                           idProject       : i2b2.PM.model.login_project,
                           idSession       : i2b2.PM.model.login_password.split("SessionKey:")[1].split("</")[0],
                           researchGoal    : document.getElementById('purpose').value,
                           exportType      : exportData
         }, function(session){
        setTimeout(function () { window.location = i2b2.ExportOCPU.cfg.config.plugin.ocpuHost + "/ocpu/tmp/" + session.getKey() + "/files/export.zip"; }, 1);
});
req.fail(function(){
    alert("OpenCPU returned an error: " + req.responseText);
});
//ocpu.call('I2B2Ocpu', {xml:data},function(session){
//$j("div[id='plotdiv']").graphic(session,1);
//$j("div[id='plotdiv2']").graphic(session,2);
//});
}
