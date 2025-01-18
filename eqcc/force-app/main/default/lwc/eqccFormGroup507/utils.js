function disableButtons(save, submit, reject, recall, formStatus, isSubmit) {
    if(isSubmit) {
        if(formStatus == "Draft" || formStatus == "Recalled") {
            if(recall) {
                recall.setAttribute("disabled", "true");
            }
            if (save) {
                save.removeAttribute("disabled");
            }
            if (submit) {
                submit.removeAttribute("disabled");
            }
            if (reject) {
                reject.removeAttribute("disabled");
            }
        }
        else if(formStatus == 'In progress' || formStatus == 'Approved') {
            if (save) {
                save.setAttribute("disabled", "true");
            }
            if (submit) {
                submit.setAttribute("disabled", "true");
            }
            if (reject) {
                reject.setAttribute("disabled", "true");
            }
            if (recall) {
                submit.setAttribute("disabled", "true");
            }
        }
        else {
            if (save) {
                save.setAttribute("disabled", "true");
            }
            if (submit) {
                submit.setAttribute("disabled", "true");
            }
            if (reject) {
                reject.setAttribute("disabled", "true");
            }
            if (recall) {
                recall.removeAttribute("disabled");
            }
        }
    }
    else {
        if (save) {
            save.setAttribute("disabled", "true");
        }
        if (submit) {
            submit.setAttribute("disabled", "true");
        }
        if (reject) {
            reject.setAttribute("disabled", "true");
        }
        if (recall) {
            recall.setAttribute("disabled", "true");
        }
    }
}

function dynamicRow(checkedSheetName) {
    switch (checkedSheetName) {
        case "Inspection_Test_Report_Control_VOOV_1_7": {
            let htmlText = "";
            for (let i=4;i<=10;i++) {
                let tr =`<tr class="hideRow"><td class="text-center"><div class="slds-form-element__control"><input type="text" data-id="1-7-input-`+i+`-1" class="slds-input"/></div></td><td class="text-center"><div class="slds-form-element__control"><input type="text" data-id="1-7-input-`+i+`-2" class="slds-input"/></div></td><td class="text-center"><div class="slds-form-element__control"><input type="text" data-id="1-7-input-`+i+`-3" class="slds-input"/></div></td></tr>`;
                htmlText+=tr;
            }
            return htmlText;
        }
        case "Inspection_Test_Report_Control_VOOV_1_8": {
            let htmlText = "";
            for (let i=4;i<=10;i++) {
                let tr = `<tr class="hideRow"><td class="text-center"><div class="slds-form-element__control"><input onchange={onIEH} type="text" data-id="1-8-input-`+i+`-1" class="slds-input" /></div></td><td class="text-center"><div class="slds-form-element__control"><input onchange={onIEH} type="text" data-id="1-8-input-`+i+`-2" class="slds-input" /></div></td><td class="text-center"><div class="slds-form-element__control"><input onchange={onIEH} type="text" data-id="1-8-input-`+i+`-3" class="slds-input" /></div></td></tr>`;
                htmlText+=tr;
            }
            return htmlText;
        }
        case "Inspection_Test_Report_Control_VOOV_UPLOAD": {
            let htmlText = "";
            for (let i=3;i<=10;i=i+2) {
                let j = i;
                j++;
                let trUpload = `<div class="slds-grid slds-wrap hideRow"><div class="slds-col slds-size_1-of-1 slds-medium-size_6-of-12 slds-large-size_6-of-12 slds-var-p-left_small"> <article class="slds-card"><div class="slds-card__header slds-grid"> <header class="slds-media slds-media_center slds-has-flexi-truncate"><div class="slds-media__body"><h2 class="slds-card__header-title"> <span class="slds-form-element__label">Before</span></h2></div><div class="slds-no-flex"><div class="upload-btn-wrapper" > <button class="btn-file">Upload File</button> <input type="file" name="myfile" data-id="`+i+`" data-upload="`+i+`" class="upload"/></div> <button class="slds-button slds-button_brand save" data-id="`+i+`" data-save="`+i+`" disabled="disabled">Upload</button></div> </header></div><div class=""> <span class="slds-card"><div class="text-center"> <span data-filename="`+i+`" class="filename"> <img src="https://thaioil--c.documentforce.com/servlet/servlet.ImageServer?id=0152v00000HLxWo&oid=00D2v000003OMdM&lastMod=1613126764000" width="30%"> </span></div> </span></div> <footer class="slds-card__footer"> <button data-id="`+i+`" data-preview="`+i+`" class="slds-button slds-button_success preview" disabled="disabled">Preview</button> <button data-id="`+i+`" data-delete="`+i+`" class="slds-button slds-button_destructive delete" disabled="disabled">Delete</button><div class="slds-form-element__control"> <input type="text" data-name="`+i+`" data-id="filename-`+i+`" disabled="disabled" class="slds-input slds-hidden name"/> <input type="text" data-id="remark-`+i+`" class="slds-input"/></div> </footer> </article></div><div class="slds-col slds-size_1-of-1 slds-medium-size_6-of-12 slds-large-size_6-of-12 slds-var-p-left_small"> <article class="slds-card"><div class="slds-card__header slds-grid"> <header class="slds-media slds-media_center slds-has-flexi-truncate"><div class="slds-media__body"><h2 class="slds-card__header-title"> <span class="slds-form-element__label">After</span></h2></div><div class="slds-no-flex"><div class="upload-btn-wrapper" > <button class="btn-file">Upload File</button> <input type="file" name="myfile" data-id="`+j+`" data-upload="`+j+`" class="upload"/></div> <button class="slds-button slds-button_brand save" data-id="`+j+`" data-save="`+j+`" disabled="disabled">Upload</button></div> </header></div><div class=""> <span class="slds-card"><div class="text-center"> <span data-filename="`+j+`" class="filename"> <img src="https://thaioil--c.documentforce.com/servlet/servlet.ImageServer?id=0152v00000HLxWo&oid=00D2v000003OMdM&lastMod=1613126764000" width="30%"> </span></div> </span></div> <footer class="slds-card__footer"> <button data-id="`+j+`" data-preview="`+j+`" class="slds-button slds-button_success preview" disabled="disabled">Preview</button> <button data-id="`+j+`" data-delete="`+j+`" class="slds-button slds-button_destructive delete" disabled="disabled">Delete</button><div class="slds-form-element__control"> <input type="text" data-name="`+j+`" data-id="filename-`+j+`" disabled="disabled" class="slds-input slds-hidden name"/> <input type="text" data-id="remark-`+j+`" class="slds-input"/></div> </footer> </article></div></div>`;
                htmlText+=trUpload;
            }
            return htmlText;
        }
    }
}

function enim_qfr_081(countPart1, countPart2, countPart3) { //Dev
    let enim_qfr_081 = ''; //Dev
            let part1 = `[{"notification":"Notification","order":"Order","fl":"FL.","status":"Status","service":"Service","pefs-no":"PEFS No","0-checkbox-1":"Body Overhaul","0-checkbox-2":"Actuator Overhaul","0-checkbox-3":"Test Only","Type-radio-1":"CM","Type-radio-2":"PM","Type-radio-3":"SH","header-na-1":"N/A","sectionOne-remark":"Remark","sectionOne-inputRemark":"Remark","1-1-1-input-1":"Body – Manufacturer","1-1-1-input-2":"Body – Model No.","1-1-1-input-3":"Body – Serial No.","1-1-1-input-4":"Body – Body Type","1-1-1-input-5":"Body – Body Size & Rating","1-1-1-input-6":"Body – Rated CV","1-1-1-input-7":"Body – Body Material","1-1-1-input-8":"Body – Plug Material","1-1-1-input-9":"Body – Seat Material","1-1-1-input-10":"Body – Packing Material","1-1-1-input-11":"Body – Seat Leakage Class","1-1-1-input-12":"Body – Plug Characteristic","1-1-1-input-13":"Body – Product Date","1-1-1-input-14":"Actuator - Manufacturer","1-1-2-input-1":"Actuator - Model No.","1-1-2-input-2":"Actuator - Serial No.","1-1-2-input-3":"Actuator - Actuator Type","1-1-2-input-4":"Actuator – Air Fail","1-1-2-input-5":"Actuator – Air Supply Pressure","1-1-2-input-6":"Actuator – Diaphragm Size ø dia (mm)","1-1-2-input-7":"Actuator - Spring Range (bar)","1-1-2-input-8":"Actuator - Stroke (mm)","1-1-2-input-9":"Actuator – Product Date","1-1-3-input-1":"Positioner - Manufacturer","1-1-3-input-2":"Positioner - Model No.","1-1-3-input-3":"Positioner - Serial No.","1-1-3-input-4":"Positioner - Positioner Type","1-1-3-input-5":"Positioner - Input Signal","1-1-3-input-6":"Positioner - Positioner Acting","1-1-3-input-7":"Positioner - Product Date","1-2-1-inspect-1":"Body – Plug Inspect Only","1-2-1-machine-1":"Body – Plug Machine/Lap","1-2-1-replace-1":"Body – Plug Replace","1-2-1-inspect-2":"Body – Seat Inspect Only","1-2-1-machine-2":"Body – Seat Machine/Lap","1-2-1-replace-2":"Body – Seat Replace","1-2-1-inspect-3":"Body – Stem Inspect Only","1-2-1-machine-3":"Body – Stem Machine/Lap","1-2-1-replace-3":"Body – Stem Replace","1-2-1-repair-1":"Body – Body Repair","1-2-1-no-1":"Body – Body No","1-2-1-repair-2":"Body – Body Gasket Repair","1-2-1-no-2":"Body – Body Gasket No","1-2-1-repair-3":"Body – Packing Repair","1-2-1-no-3":"Body – Packing No","1-2-1-repair-4":"Body – Lubricant Repair","1-2-1-no-4":"Body – Lubricant No","1-2-2-inspect-4":"Actuator – Diaphragm/Piston Inspect Only","1-2-2-pressure-1":"Actuator – Diaphragm/Piston Pressure Test","1-2-2-replace-4":"Actuator – Diaphragm/Piston Replace","1-2-2-good-1":"Actuator - Booster Good","1-2-2-none-1":"Actuator - Booster None","1-2-2-replace-5":"Actuator - Booster Replace","1-2-2-adjust-1":"Actuator - Lock up Adjust","1-2-2-replace-6":"Actuator - Lock up Replace","1-2-2-not-1":"Actuator - Lock up Not Adjust","1-2-2-none-2":"Actuator - Lock up None","1-2-2-adjust-2":"Actuator – Proximity Adjust","1-2-2-not-2":"Actuator – Proximity Not Adjust","1-2-2-done-1":"Actuator – Painting Done","1-2-2-not-3":"Actuator – Painting Not Done","1-2-2-done-2":"Actuator – Spring Rang Test Done","1-2-2-not-4":"Actuator – Spring Rang Test Not Done","1-2-3-good-2":"Positioner - Positioner Good","1-2-3-replace-7":"Positioner - Positioner Replace","1-2-3-none-3":"Positioner - Positioner None","1-2-3-good-3":"Positioner – Pressure Gauge Good","1-2-3-replace-8":"Positioner – Pressure Gauge Replace","1-2-3-none-4":"Positioner – Pressure None","1-2-3-auto-1":"Positioner – Positioner Calibration Auto","1-2-3-manual-1":"Positioner – Positioner Calibration Manual","1-2-3-retrieved-1":"Positioner – Valve Signature Capture Data File Retrieved","1-2-3-none-5":"Positioner – Valve Signature Capture Data File None","1-3-1-input-1":"Test Pressure (barg)","1-3-2-input-1":"Test Fluid Air","1-3-2-input-2":"Test Fluid Water","1-3-2-input-3":"Test Fluid N2","1-3-3-input-1":"Test Result Pass","1-3-3-input-2":"Test Result Not Pass","1-4-1-i-1":"Leakage Class I","1-4-1-ii-2":"Leakage Class II","1-4-1-iii-3":"Leakage Class III","1-4-1-iv-4":"Leakage Class IV","1-4-1-v-5":"Leakage Class V","1-4-1-vi-6":"Leakage Class VI","1-4-2-input-1":"Leak Allowance Rate","1-4-2-input-2":"As Found Leak Rate","1-4-2-input-3":"As Left Leak Rate","1-4-3-input-1":"Test Fluid Air","1-4-3-input-2":"Test Fluid Water","1-4-3-input-3":"Test Fluid N2","1-4-4-input-1":"Test Result Pass","1-4-4-input-2":"Test Result Not Pass","1-5-1-input-1":"Input (mA) 0","1-5-1-input-2":"Open (%) 0","1-5-1-input-3":"Before Adjust (%) Increase 0","1-5-1-input-4":"Before Adjust (%) Decrease 0","1-5-1-input-5":"After Adjust (%) Increase 0","1-5-1-input-6":"After Adjust (%) Decrease 0","1-5-1-input-7":"Input (mA) 25","1-5-1-input-8":"Open (%) 25","1-5-1-input-9":"Before Adjust (%) Increase 25","1-5-1-input-10":"Before Adjust (%) Decrease 25","1-5-1-input-11":"After Adjust (%) Increase 25","1-5-1-input-12":"After Adjust (%) Decrease 25","1-5-1-input-13":"Input (mA) 50","1-5-1-input-14":"Open (%) 50","1-5-1-input-15":"Before Adjust (%) Increase 50","1-5-1-input-16":"Before Adjust (%) Decrease 50","1-5-1-input-17":"After Adjust (%) Increase 50","1-5-1-input-18":"After Adjust (%) Decrease 50","1-5-1-input-19":"Input (mA) 75","1-5-1-input-20":"Open (%) 75","1-5-1-input-21":"Before Adjust (%) Increase 75","1-5-1-input-22":"Before Adjust (%) Decrease 75","1-5-1-input-23":"After Adjust (%) Increase 75","1-5-1-input-24":"After Adjust (%) Decrease 75","1-5-1-input-25":"Input (mA) 100","1-5-1-input-26":"Open (%) 100","1-5-1-input-27":"Before Adjust (%) Increase 100","1-5-1-input-28":"Before Adjust (%) Decrease 100","1-5-1-input-29":"After Adjust (%) Increase 100","1-5-1-input-30":"After Adjust (%) Decrease 100","1-2-3-input-1":"Specification Open to Close","1-2-3-input-2":"Actual Open to Close","1-2-3-input-3":"Specification Close to Open","1-2-3-input-4":"Actual Close to Open","1-6-1-radio-1":"Blind Flange Test","1-6-1-radio-2":"Machine Bench Test","1-6-1-input-1":"Tag No :","1-6-1-input-2":"Model No. :","1-6-1-input-3":"Manufacturer :","1-6-1-input-4":"Serial No. :","1-7-input-1-1":"Part Name","1-7-input-1-2":"Condition","1-7-input-1-3":"Action","1-7-input-2-1":"Part Name","1-7-input-2-2":"Condition","1-7-input-2-3":"Action","1-7-input-3-1":"Part Name","1-7-input-3-2":"Condition","1-7-input-3-3":"Action",`;

            let part2 = `"1-8-input-1-1":"Part Name","1-8-input-1-2":"Description Part","1-8-input-1-3":"Q'Ty","1-8-input-2-1":"Part Name","1-8-input-2-2":"Description Part","1-8-input-2-3":"Q'Ty","1-8-input-3-1":"Part Name","1-8-input-3-2":"Description Part","1-8-input-3-3":"Q'Ty",`;

            let part3 = `"sectionTwo":"2 Inspection","headingTwo":"2 Inspection","header-na-2":"N/A","sectionTwo-remark":"Remark","sectionTwo-inputRemark":"Remark","filename-1":"Before filename","remark-1":"Before remark","filename-2":"After filename","remark-2":"After remark",`;

            if(countPart1 > 0) {
                for (let i=0;i<countPart1;i++) {
                    let count = 4;
                    count = count + i;
                    let str = `"1-7-input-`+count+`-1": "Part Name",` + `"1-7-input-`+count+`-2": "Condition",` + `"1-7-input-`+count+`-3": "Action",`;
                    part1 += str;
                }
            }
            if(countPart2 > 0) {
                for (let i=0;i<countPart2;i++) {
                    let count = 4;
                    count = count + i;
                    let str = `"1-8-input-`+count+`-1": "Part Name",` + `"1-8-input-`+count+`-2": "Description Part",` + `"1-8-input-`+count+`-3": "Q'Ty",`;
                    part2 += str;
                }
            }
            if(countPart3 > 0) {
                for (let i=0;i<countPart3;i++) {
                    let countBefore = 3;
                    countBefore = countBefore + i;
                    let countAfter = countBefore + 1;
                    let str = `"filename-` +countBefore+ `": "Before filename"` + `"remark-` +countBefore+ `": "Before remark"` + `"filename-` +countAfter+ `": "After filename"` + `"remark-` +countAfter+ `": "After remark",`;
                    part3 += str;
                }
            }
            enim_qfr_081 = part1 + part2 + part3 + `}]`;
            return enim_qfr_081;
}
export { disableButtons, dynamicRow , enim_qfr_081 };