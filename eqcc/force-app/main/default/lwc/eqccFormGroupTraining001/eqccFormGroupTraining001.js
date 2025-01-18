import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord, getRecord, getFieldValue } from "lightning/uiRecordApi";
import { loadStyle, loadScript } from "lightning/platformResourceLoader";

import EQCC_STEP_ID from "@salesforce/schema/EQCC_Step__c.Id";
import EQCC_STEP_JSON from "@salesforce/schema/EQCC_Step__c.jsonString__c";
import EQCC_STEP_STATUS from "@salesforce/schema/EQCC_Step__c.Status__c";
import EQCC_STEP_NUMBER from "@salesforce/schema/EQCC_Step__c.Step_Number__c";
import EQCC_STEP_FORM_TYPE from "@salesforce/schema/EQCC_Step__c.Header_Sheet__r.Sheet__r.Form_Type__c";
import EQCC_STEP_FORM_TYPE_VER from "@salesforce/schema/EQCC_Step__c.Header_Sheet__r.Sheet__r.Version__c";

import submitForApproval from "@salesforce/apex/THOR_ApprovalFlowService.submitForApproval";

import defaultTemplate from "./forms/_default.html";
import EQCC_TRAINING_001 from "./forms/EQCC_TRAINING_001.html";

export default class EqccFormGroupTraining001 extends NavigationMixin(LightningElement) {
    @track checkedSheetName;
    @track stepNumber;
    @track checkedSheetVersion;

    @track modalTitle;
    @track modalMessage;
    @track modalCancelButton;
    @track modalConfirmButton;
    @track modalVisible = false;
    @track modalName;

    newRecordId

    @api
    get recordId() {
        return this.newRecordId;
    }
    set recordId(value) {
        if (this.newRecordId !== value) {
            this.isDifferent = true;
            this.disabledSections = [];
        }
        this.newRecordId = value;
    }

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [
            EQCC_STEP_JSON,
            EQCC_STEP_NUMBER,
            EQCC_STEP_FORM_TYPE,
            EQCC_STEP_FORM_TYPE_VER,
            EQCC_STEP_STATUS
        ]
    })
    recordResult({ data, error }) {
        if (data) {
            this.record = data;
            this.stepNumber = getFieldValue(this.record, EQCC_STEP_NUMBER);
            this.checkedSheetName = getFieldValue(this.record, EQCC_STEP_FORM_TYPE);
            this.checkedSheetVersion = getFieldValue(this.record, EQCC_STEP_FORM_TYPE_VER);
            this.formStatus = getFieldValue(this.record, EQCC_STEP_STATUS);
            this.render();
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: error.body.message,
                    variant: "error"
                })
            );
        }
    }

    // System Function
    render() {
        switch (this.checkedSheetName) {
            case "EQCC_TRAINING_001": {
                switch (this.stepNumber) {
                    case 1:
                        switch (this.checkedSheetVersion) {
                            case 1:
                                return EQCC_TRAINING_001;
                            default:
                                return defaultTemplate;
                        }
                    default:
                        return defaultTemplate;
                }
            }
            default:
                return defaultTemplate;
        }
    }

    // System Function
    renderedCallback() {
        this.loadDraft();
    }

    // User Defined Function
    loadDraft() {
        this.loadDraftAfterDraw();
    }

    // User Defined Function
    loadDraftAfterDraw() {
        var inputJson = getFieldValue(this.record, EQCC_STEP_JSON);
        if (this.record) {
            let inputs = JSON.parse(inputJson);
            if (inputs) {
                inputs.forEach((element) => {
                    let domElement = this.template.querySelector("[data-id='" + element.id + "']");
                    domElement.value = element.value;
                });
            }
        }
    }

    // User Defined Function
    openModal() {
        this.submitForApprovalButton();
    }

    // User Defined Function
    openSaveModal() {
        this.saveDraft();
    }

    // User Defined Function
    saveDraft(status = "Draft", notoast = false) {
        return new Promise((resolve, reject) => {
            let inputElements = this.template.querySelectorAll("input, textarea, select");
            let inputs = [];
            inputElements.forEach((element) => {
                if (element.type === "radio" || element.type === "checkbox") {
                    inputs.push({
                        id: element.dataset.id,
                        value: element.checked
                    });
                } else {
                    inputs.push({
                        id: element.dataset.id,
                        value: element.value
                    });
                }
            });

            if (status === "Pending for Approval") {
                let statusInput = inputs.find((el) => el.id === "status");
                if (statusInput) {
                    statusInput.value = "Pending for Approval";
                }
            }

            if (status === "Rejected") {
                let statusInput = inputs.find((el) => el.id === "status");
                if (statusInput) {
                    statusInput.value = "Rejected";
                }
            }

            if (status === "Recalled") {
                let statusInput = inputs.find((el) => el.id === "status");
                if (statusInput) {
                    statusInput.value = "Recalled";
                }
                status = "Recalled";
            }

            const fields = {};
            fields[EQCC_STEP_ID.fieldApiName] = this.recordId;
            if (inputs && inputs.length > 0) {
                fields[EQCC_STEP_JSON.fieldApiName] = JSON.stringify(inputs);
            }

            fields[EQCC_STEP_STATUS.fieldApiName] = status;
            const recordInput = {
                fields
            };

            updateRecord(recordInput)
                .then(() => {
                    if (!notoast) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Success",
                                message: "Saved Sheet successfully.",
                                variant: "success"
                            })
                        );
                    }
                    this._isModified = false;
                    resolve();
                })
                // .then(() => {
                //     updateHeaderSheetRequester({
                //         stepId: this.recordId
                //     });
                // })
                .catch((error) => {
                    if (
                        error.body &&
                        error.body.output &&
                        error.body.output.errors &&
                        error.body.output.errors[0] &&
                        error.body.output.errors[0].errorCode === "ENTITY_IS_LOCKED"
                    ) {
                        console.log("===> this is fine");
                    } else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Error",
                                message: "Unable to save draft.",
                                variant: "error"
                            })
                        );
                        reject();
                    }
                });
        });
    }

    submitForApprovalButton() {
        this.saveDraft("Pending for Approval", true)
            // .then(() => {
            //     updateStepPercentage({
            //         stepId: this.recordId,
            //         percentage: this.stepPercentage
            //     });
            // })
            .then((response) => {
                return submitForApproval({
                    stepId: this.recordId
                });
            })
            .then((result) => {
                if (result) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Form submitted for approval.",
                            variant: "success"
                        })
                    );
                    this.readOnly = true;
                    this.disableFields();
                    this.scrollToTop();
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error",
                            message: "Form has already been submitted.",
                            variant: "error"
                        })
                    );
                }
            })
            // .then(() => {
            //     let percentages = JSON.parse(this.percentageByStep);
            //     percentages[this.stepNumber] = this.stepPercentage;
            //     updateHeaderSheetPercentages({
            //         stepId: this.recordId,
            //         percentages: JSON.stringify(percentages)
            //     });
            // })
            .catch((error) => {
                // if (error.body.message !== "EQCC step already in progress.") {
                //     this.saveDraft("Draft", true);
                //     this.readOnly = false;
                //     this.disableFields();
                // }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });
    }

    openSubmitModal() {
        // let requiredFields = this.checkRequiredInputs();
        // if (!requiredFields) {
        //    this.scrollToTop();
        this.modalTitle = "Submit Form";
        this.modalMessage =
            "Are you sure you want to submit this form? Once submitted, you will not be able to modify the form.";
        this.modalCancelButton = "Cancel";
        this.modalConfirmButton = "Submit";
        this.modalVisible = true;
        this.modalName = "submitForm";
        // }
    }
}