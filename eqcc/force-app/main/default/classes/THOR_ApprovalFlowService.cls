/**
 * @author K.B. Carte
 * @description Approval Process service class for EQCC_Step approval
 */
public without sharing class THOR_ApprovalFlowService {
    private static String roleName;
    /**
     * @description submits EQCC_Step record for approval.
     * @param stepId is the Id of the EQCC_Step we're submitting for approval
     * @return boolean true if the approval process went through okay, false on error
     */
    @AuraEnabled
    public static Boolean submitForApproval(String stepId, String userId) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> submitForApproval');
        // Create an approval request for the passed in EQCC_Step record Id (stepId)
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(stepId);
        // Submit the record to specific process
        // approvals are all based on entry criteria
        // String currentUserRoleId = UserInfo.getUserRoleId();
        // roleName = [SELECT Name FROM UserRole WHERE Id = :currentUserRoleId LIMIT 1].Name;
        EQCC_Step__c eqcc_step = [SELECT Id, Form_Code__c, Step_Number__c, Header_Sheet__r.Sheet__r.Group__c, Owner.Name, Is_Current__c, Status__c FROM EQCC_Step__c WHERE Id = :stepId];

        Set<Id> groupId = new Set<Id>();
        Set<String> newSheetCodes = new Set<String>();
        User user = [SELECT Id, UserRoleId,UserRole.Name, Role_Approve_process__c FROM User WHERE Id =: UserInfo.getUserId()];
         system.debug('===debug==user.Role_Approve_process__c=='+user.Role_Approve_process__c);
      List<Group> groups = [Select Id, Name, DeveloperName From Group where Related.Name =: user.userRole.Name or Related.Name =: user.Role_Approve_process__c ];
      //  List<Group> groups = [Select Id, Name, DeveloperName From Group where Related.Name =: user.Role_Approve_process__c];
        for(Group g : groups) {
            groupId.add(g.Id);
        }
        List<GroupMember> gm = [Select Id, Group.Name, Group.DeveloperName, Group.Type, UserOrGroupId From GroupMember
										WHERE Group.Name =: eqcc_step.Form_Code__c];
        system.debug('===debug==Group.Name =: eqcc_step.Form_Code__c=='+eqcc_step.Form_Code__c+'========UserOrGroupId IN: groupId=='+groupId);
        List<GroupMember> groupMembers = [Select Id, Group.Name, Group.DeveloperName, Group.Type, UserOrGroupId From GroupMember
										WHERE Group.Name =: eqcc_step.Form_Code__c AND UserOrGroupId IN: groupId];
        if(groupMembers.size() == 0 && !Test.isRunningTest()) {
            throw new AuraHandledException('You cannot submit based on role, profile or status');
        }

        // if (!roleName.contains('Team Lead') && !roleName.contains('Working Team')) {
        //     throw new AuraHandledException('You cannot submit based on role, profile or status');
        // }
        try {
            // Get approvers based on form codes and current approval step
            List<String> approverList = new List<String>();
            approverList.addAll(getApprovers(stepId, userId));
            req1.setNextApproverIds(approverList);
            Approval.ProcessResult result = Approval.process(req1);
            if (result.isSuccess()) {
                Id processId = resolveStepProcess(stepId);
                /*List<ProcessInstanceStep> processSteps = [
                    SELECT
                        Id,
                        ActorId,
                        Comments,
                        StepStatus,
                        ProcessInstance.Status,
                        ProcessInstance.TargetObjectId,
                        CreatedDate
                    FROM ProcessInstanceStep
                    WHERE ProcessInstance.TargetObjectId = :stepId
                    ORDER BY CreatedDate DESC
                ];*/
                // EQCC_Step__c step = [SELECT Id, Form_Code__c, Step_Number__c, Header_Sheet__r.Sheet__r.Group__c, Owner.Name, Header_Sheet__r.Header__c FROM EQCC_Step__c WHERE Id = :stepId];
                // sendAlert(
                //     approverList,processId,step.Form_Code__c +'[Step ' +step.Step_Number__c +'] has been submitted for your approval.','New Approval',
                //     step.Header_Sheet__r.Sheet__r.Group__c);

                // List<GroupMember> groupMs = [Select Id, Group.Name, Group.DeveloperName, Group.Type, UserOrGroupId From GroupMember where GroupId =: approverList.get(0)];
                // if((step.Form_Code__c == 'EQCC-ENRM-006' || step.Form_Code__c == 'EQCC-ENRM-002') && step.Step_Number__c == 3) {
                //     for(GroupMember i : groupMs) {
                //         EQCC_Header__Share stepShr = new EQCC_Header__Share();
                //          stepShr.ParentId = step.Header_Sheet__r.Header__c;
                //          stepShr.UserOrGroupId = i.UserOrGroupId;
                //          stepShr.AccessLevel = 'Read';
                //          stepShr.RowCause = Schema.EQCC_Header__Share.RowCause.Manual;
                //          Database.SaveResult sr = Database.insert(stepShr,false); 

                //          if(sr.isSuccess()){
                //             // Indicates success
                //          }
                //          else {
                //             // Get first save result error.
                //             Database.Error err = sr.getErrors()[0];
                //           }
                //      }
                // }
                // createNotification('Started', step, approverList);
                // sendEmailForApprove(step, approverList);
            }
            return result.isSuccess();
        } catch (DmlException dmle) {
/*            System.debug(System.LoggingLevel.ERROR, String.format('{0}: {1}\r\n{2}', new List<String>{
                dmle.getDmlMessage(0),
                dmle.getStackTraceString(),
                dmle.getMessage()
            }));*/
            throw new AuraHandledException(dmle.getMessage());
            // throw new AuraHandledException('EQCC step already in progress.');
        } catch (QueryException qe) {
            system.debug('Check-----' + qe.getLineNumber() + ' : ' + qe.getMessage());
            throw new AuraHandledException(
                'No qualified users available to assign to or you are not in the required role. Line:' + qe.getLineNumber()
            );
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting form.Line:' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static Boolean recallForApproval(String stepId){
        system.debug('Method >>>>>>>>>>>>>>>>>>>> recallForApproval');
        ProcessInstanceWorkitem[] pVal = [SELECT Id FROM ProcessInstanceWorkItem WHERE 
                                          ProcessInstance.TargetObjectId = :stepId AND 
                                          ProcessInstance.Status = 'Pending']; 
        if(pVal.size() > 0){

            Approval.ProcessWorkItemRequest Preq= new Approval.ProcessWorkItemRequest();
            Preq.setAction('Removed');
            Preq.setWorkItemId(pVal[0].Id);
            Approval.ProcessResult result = Approval.process(Preq);
/*
            List<EQCC_Step__c>stepList = [select id, status__c from EQCC_Step__c where id =: stepId];
            if(stepList.size() > 0)
            {
                stepList[0].status__c = 'Recalled';
                update stepList[0];
            }*/
            return true;
        }
        return false;
    }

    @AuraEnabled
    public static Boolean getIgnorSpecialSubmit(String stepId){
        system.debug('Method >>>>>>>>>>>>>>>>>>>> getIgnorSpecialSubmit');
        Boolean isSpecial = false;
        EQCC_Step__c step = [SELECT Id, Header_Sheet__r.Sheet__r.Name FROM EQCC_Step__c WHERE Id =: stepId];
        String sheetCode = step.Header_Sheet__r.Sheet__r.Name;
        List<String> forms = new List<String>();
        for(Special_Submit_Form__mdt form : [SELECT MasterLabel, DeveloperName FROM Special_Submit_Form__mdt]) {
            if (sheetCode == form.MasterLabel) {
                isSpecial = true;
                break;
            }
        }
        return isSpecial;
    }

    /**
     * @description approves or rejects step from approval process
     * @param stepId is the Id of the EQCC_Step we're submitting for approval
     * @param approveReject is a string to either 'Approve' or 'Reject'
     * @param comments is a string with user comments that will be added to the end of the approver comment
     * @return boolean true if the approve/reject went through okay, False if error
     */
    @AuraEnabled
    public static Boolean approveOrReject(String stepId, String approveReject, String comments) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> approveOrReject');
        //Class used for Approving Record
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        if (String.isBlank(comments)) {
            req.setComments('');
        } else {
            req.setComments(comments);
        }

        //Approve or Reject Record
        req.setAction(approveReject);

        //Getting Work Item Id
        ProcessInstanceWorkitem[] pItem = [SELECT ProcessInstance.TargetObjectId, ProcessInstance.Status FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :stepId WITH SECURITY_ENFORCED
        ];
        if (approveReject == Constants.PROCESS.ACTION_APPROVE) {
            List<String> ids = new List<String>();
            ids.addAll(getApprovers(stepId, null));
            req.setNextApproverIds(ids);
            Id processId = resolveStepProcess(stepId);
/*[
                SELECT
                    Id,
                    ActorId,
                    Comments,
                    StepStatus,
                    ProcessInstance.Status,
                    ProcessInstance.TargetObjectId,
                    CreatedDate
                FROM ProcessInstanceStep
                WHERE ProcessInstance.TargetObjectId = :stepId
                ORDER BY CreatedDate DESC
            ];*/
            EQCC_Step__c step = [SELECT Id, Form_Code__c, Step_Number__c, Header_Sheet__r.Sheet__r.Group__c, Header_Sheet__r.Header__c, Owner.Name FROM EQCC_Step__c WHERE Id = :stepId];
            
            sendAlert(ids,processId,step.Form_Code__c +'[Step ' +step.Step_Number__c +'] has been submitted for your approval.','New Approval',
                step.Header_Sheet__r.Sheet__r.Group__c);
            List<GroupMember> groupMembers = [Select Id, Group.Name, Group.DeveloperName, Group.Type, UserOrGroupId From GroupMember where GroupId =: ids.get(0)];
            //if(step.Form_Code__c == 'EQCC-ENRM-006' || step.Form_Code__c == 'EQCC-ENRM-002') {
                for(GroupMember i : groupMembers) {
                    EQCC_Header__Share stepShr = new EQCC_Header__Share();
                     stepShr.ParentId = step.Header_Sheet__r.Header__c;
                     stepShr.UserOrGroupId = i.UserOrGroupId;
                     stepShr.AccessLevel = 'Read';
                     stepShr.RowCause = Schema.EQCC_Header__Share.RowCause.Manual;
                     Database.SaveResult sr = Database.insert(stepShr,false); 

                     if(sr.isSuccess()){
                        // Indicates success
                     }
                     else {
                        // Get first save result error.
                        Database.Error err = sr.getErrors()[0];
                      }
                 }
            //}
            createNotification('Approved', step, ids);
            sendEmailForApprove(step, ids); 
        }else if (approveReject == 'Reject') {
            EQCC_Step__c step = [SELECT Id, Form_Code__c, Step_Number__c, Header_Sheet__r.Sheet__r.Group__c, Header_Sheet__r.Header__c, Owner.Name FROM EQCC_Step__c WHERE Id = :stepId];
            createReviseNotification(step);
        }

        req.setWorkitemId(pItem[0].Id);
        // Submit the request for approval
        Approval.ProcessResult result = Approval.process(req);

        Boolean successful = result.isSuccess();
        String stepApproved = result.getInstanceStatus();

        if (successful) {
            if (stepApproved == Constants.PROCESS.STATUS_APPROVED) {
                markNextStepAsCurrent(stepId);
            } else if (stepApproved == Constants.PROCESS.STATUS_REJECTED) {
                handleReviseAlert(stepId);
            }
        }

        return successful;
    }

    @TestVisible 
    private static void handleReviseAlert(Id stepId) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> handleReviseAlert');
        EQCC_Step__c step = getStepById(stepId);
        Header_Sheet__c headerSheet = getHeaderSheetFromStep(step);
        Id alertType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'THOR_Push_Notification'].Id;
        Set<String> receivers = new Set<String>{ headerSheet.RequesterId__c };
        Id processId = resolveStepProcess(stepId);
        Messaging.CustomNotification alert = CustomNotificationHelper.buildAlert(alertType,getStepPageRef(processId, step.Header_Sheet__r.Sheet__r.Group__c),
            resolveReviseAlertBody(step),'Revise Checked Sheet');

        CustomNotificationHelper.sendAlert(alert, receivers);
    }

    @TestVisible 
    private static EQCC_Step__c getStepById(Id stepId) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> getStepById');
        return [SELECT Id, Header_Sheet__c, Form_Code__c, Header_Sheet__r.Sheet__r.Group__c, Owner.Name, Step_Number__c FROM EQCC_Step__c WHERE Id = :stepId LIMIT 1];
    }

    private static Header_Sheet__c getHeaderSheetFromStep(EQCC_Step__c step) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> getHeaderSheetFromStep');
        return [SELECT Id, RequesterId__c FROM Header_Sheet__c WHERE Id = :step.Header_Sheet__c LIMIT 1];
    }

    /**
     * @description marks the next checked sheet step as the current one in case of existing,
     *              otherwise it marks the checked sheet as completed
     * @param currentStepId current step
     */
    private static void markNextStepAsCurrent(String currentStepId) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> markNextStepAsCurrent');
        //Get current step as an sObject by using the stepId
        EQCC_Step__c currentStep = [SELECT Id, Header_Sheet__c, Step_Number__c, Header_Sheet__r.Sheet__c, Form_Code__c, Header_Sheet__r.Sheet__r.Group__c, Owner.Name
            FROM EQCC_Step__c WHERE Id = :currentStepId];

        //Get the next step number by adding 1 to the current
        Decimal nextStepNumber = currentStep.Step_Number__c + 1;

        //Get the current Header Sheet as an sObject by matching the Ids
        Header_Sheet__c currentHeaderSheet = [SELECT Id, RequesterId__c FROM Header_Sheet__c WHERE Id = :currentStep.Header_Sheet__c];

        //Get the next EQCC_Step by querying for a step with a step number one more than previous
        List<EQCC_Step__c> nextSteps = [SELECT Id, Header_Sheet__r.Sheet__r.Group__c, Owner.Name FROM EQCC_Step__c
            WHERE Header_Sheet__c = :currentStep.Header_Sheet__c AND Step_Number__c = :nextStepNumber];

        if (!nextSteps.isEmpty()) {
            nextSteps.get(0).Is_Current__c = true;
            nextSteps.get(0).Status__c = 'Draft';

            update nextSteps;
            EQCC_Step__c step = getStepById(currentStepId);
            Header_Sheet__c headerSheet = getHeaderSheetFromStep(step);
            Id alertType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'THOR_Push_Notification'].Id;
            Set<String> receivers = new Set<String>{ headerSheet.RequesterId__c };
            Id processId = resolveStepProcess(currentStepId);
            Messaging.CustomNotification alert = CustomNotificationHelper.buildAlert(
                alertType,getStepPageRef(processId, step.Header_Sheet__r.Sheet__r.Group__c),resolveFinalApproverAlertBody(step),
                'Approved Checked Sheet step ' + currentStep.Step_Number__c);
            CustomNotificationHelper.sendAlert(alert, receivers);
        } else {
            currentHeaderSheet.Status__c = Constants.CHECKED_SHEETS.STATUS_APPROVED;
            update currentHeaderSheet;
            handleFinalApproverAlert(currentHeaderSheet, currentStep);
        }
    }

    public static void handleFinalApproverAlert(Header_Sheet__c headerSheet, EQCC_Step__c step) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> handleFinalApproverAlert');
        Id alertType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'THOR_Push_Notification'].Id;
        Set<String> receivers = new Set<String>{ headerSheet.RequesterId__c };
        Id processId = resolveStepProcess(step.Id);
        Messaging.CustomNotification alert = CustomNotificationHelper.buildAlert(alertType,getStepPageRef(processId, step.Header_Sheet__r.Sheet__r.Group__c),
            resolveFinalApproverAlertBody(step),'Checked Sheet approved');

        CustomNotificationHelper.sendAlert(alert, receivers);
        sendEmailToSubmitor(step);
    }

    private static Id resolveStepProcess(Id stepId) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveStepProcess');
        List<ProcessInstanceStep> processSteps = [
            SELECT Id,ActorId,Comments,StepStatus,ProcessInstance.Status,ProcessInstance.TargetObjectId,CreatedDate
            FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :stepId ORDER BY CreatedDate DESC];
		if(processSteps.size() > 0)
        {
            return processSteps[0].Id;
        }
        else
        {
            return null;
        }
    }

    private static String getStepPageRef(Id processId, String sheetGroup) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> getStepPageRef');
        return '{"type": "standard__component", "attributes": {"componentName": "c__THOR_ApprovalSteps"}, "state": {"c__recordId": "' +
            processId +'", "c__sheetGroup": "' + sheetGroup + '"}}';
    }

    private static String resolveFinalApproverAlertBody(EQCC_Step__c step) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveFinalApproverAlertBody');
        return CustomNotificationHelper.buildFormattedMessage('{0} has already been approved',new List<String>{ step.Form_Code__c });
    }

    private static String resolveReviseAlertBody(EQCC_Step__c step) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveReviseAlertBody');
        return CustomNotificationHelper.buildFormattedMessage('{0} needs your revision',new List<String>{ step.Form_Code__c });
    }

    /**
     * @description get approval queue for next approval step
     * @param stepId is the Id of the EQCC_Step we're submitting for approval
     * @return List<String> queues assigned to approval
     */
    private static List<String> getApprovers(String stepId, String userId) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> getApprovers');
        //String currentUserRoleId = UserInfo.getUserRoleId();
        //roleName = [SELECT Name FROM UserRole WHERE Id = :currentUserRoleId LIMIT 1].Name;
        
        String currentUserId = UserInfo.getUserId();
        roleName = [SELECT Role_Approve_process__c FROM User WHERE Id = :currentUserId LIMIT 1].Role_Approve_process__c;
        EQCC_Step__c step = [SELECT Id, Step_Number__c, Form_Code__c, Owner.Name, Header_Sheet__r.Header__c FROM EQCC_Step__c WHERE Id = :stepId];
        
        List<ProcessInstance> pItem = [
            SELECT Id,Status,CreatedDate,CompletedDate,TargetObjectId,SubmittedById,
                (
                    SELECT
                        Id,StepStatus,Actor.Name,ElapsedTimeInDays,ElapsedTimeInMinutes,CreatedDate,ProcessNodeId,ProcessNode.Name,Comments
                    FROM StepsAndWorkitems ORDER BY CreatedDate ASC, Id ASC
                )
            FROM ProcessInstance WHERE TargetObjectId = :stepId AND (Status = 'Started' OR Status = 'Pending') ORDER BY CreatedDate ASC, Id ASC];
        String lastStep = null;

        for (ProcessInstance pr : pItem) {
            for (ProcessInstanceHistory str : pr.StepsAndWorkitems) {
                if (str.ProcessNode.Name != null && str.ProcessNode.Name != '') {
                    lastStep = str.ProcessNode.Name;
                }
            }
        }

        User workingTeamUser = new User();

        List<String> approverList = new List<String>();
        if(userId == null) {
            if (lastStep != null && lastStep.length() > 0) {
                system.debug('lastStep != null && lastStep.length()');
                system.debug('pItem[0].SubmittedById ' +pItem[0].SubmittedById);
                workingTeamUser = [SELECT Id, Name, UserRole.Id, UserRole.Name,Role_Approve_process__c FROM User WHERE Id = :pItem[0].SubmittedById];
            } else {
                system.debug('lastStep == null || lastStep.length() == 0');
                system.debug('UserInfo.getUserId() ' +UserInfo.getUserId());
                workingTeamUser = [SELECT Id, Name, UserRole.Id, UserRole.Name,Role_Approve_process__c FROM User WHERE Id = :UserInfo.getUserId()];
            }

// UserRole workingTeamRole = [
//     SELECT Id, Name, ParentRoleId
//     FROM UserRole
//     WHERE Id = :workingTeamUser.UserRole.Id
// ]; 
system.debug('===debug==workingTeamUser.Role_Approve_process__c=='+workingTeamUser.Role_Approve_process__c);
            UserRole workingTeamRole = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Name = :workingTeamUser.Role_Approve_process__c];
//////Edited by AMORNRAT
            UserRole workingTeamLeadRole = [SELECT Id, Name FROM UserRole WHERE Id = :workingTeamRole.ParentRoleId LIMIT 1];
// User teamLeadUser = [select id,Role_Approve_process__c from user where Role_Approve_process__c =: new_workingTeamLeadRole.Name];
// system.debug('Old User TeamLEad ROLE----'+teamLeadUser.Role_Approve_process__c);
// UserRole workingTeamLeadRole = [SELECT Id, Name FROM UserRole WHERE Name = :teamLeadUser.Role_Approve_process__c LIMIT 1];
// system.debug('Old workingTeamLeadRole----'+workingTeamLeadRole.Name);
/////////////////////////
            String apuTeam = workingTeamRole.Name.substring(9, 14);
            //List<String> subGroups = workingTeamUser.UserRole.Name.split('/');
            List<String> subGroups = workingTeamUser.Role_Approve_process__c.split('/');
            String subGroup = '';
            if (subGroups.size() > 2) {
                subGroup = String.fromCharArray(new List<integer>{ subGroups[0].charAt(subGroups[0].length() - 1) });
                for (Integer i = 1; i < subGroups.size(); i++) {
                    subGroup += '/' + '%' + subGroups[i];
                }
            } else if (subGroups.size() == 1) {
                List<String> groupWoSlash = subGroups[0].split('-');
                subGroup = groupWoSlash[groupWoSlash.size() - 1];
            } else {
                subGroup =subGroups[0].substringAfterLast('-') +'/%' +subGroups[subGroups.size() - 1];
            }
            subGroup = '%' + subGroup + '%';
            String discipline = subGroups[0].right(1);
    
            switch on step.Form_Code__c {
                /*when 'ENIM-QFR-401' {
                    approverList.add(ENIM_QFR_401(lastStep, apuTeam, subGroup));
                }*/
                when 'EQCC-ENRM-007','EQCC-ENRM-008' {
                    approverList.add(EQCC_ENRM_007((Integer) step.Step_Number__c, lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }
                when 'EQCC-ENRM-002','EQCC-ENRM-006' {
                    approverList.add(EQCC_ENRM_002((Integer) step.Step_Number__c, lastStep, workingTeamLeadRole, apuTeam, subGroup, step.Id));
                }
                
                /*when 'EQCC-ENRM-006' {
                    approverList.add(
                        EQCC_ENRM_006((Integer) step.Step_Number__c, lastStep, workingTeamLeadRole, apuTeam, subGroup, step.Id)
                    );
                }*/
                when 'ENIM-QFR-006','ENCM-QFR-14','ENEM-QFR-9044-GNR','ENEM-QFR-9037-GNR','ENEM-QFR-5005-WS','ENIM-QFR-031',
                    'ENIM-QFR-030','ENEM-QFR-9043-GNR','ENIM-QFR-033','ENIM-QFR-034','ENIM-QFR-081','ENIM-QFR-032','ENIM-QFR-010',
                    'ENIM-QFR-011','ENIM-QFR-012','ENIM-QFR-013','ENIM-QFR-014','ENIM-QFR-015','ENIM-QFR-016','ENIM-QFR-017','ENIM-QFR-018',
                    'ENIM-QFR-036','ENIM-QFR-037','ENIM-QFR-038','ENIM-QFR-044','ENIM-QFR-035','ENIM-QFR-039','ENIM-QFR-040','ENIM-QFR-041',
                    'ENIM-QFR-042','ENIM-QFR-043','ENIM-QFR-070','ENIM-QFR-071','ENIM-QFR-072','ENIM-QFR-080','ENIM-QFR-082','ENEM-QFR-2604-REL', 
                    'ENEM-QFR-1325-UPS', 'ENEM-QFR-9003-GNR', 'ENEM-QFR-9008-GNR','ENEM-QFR-1007','ENEM-QFR-1013','ENEM-QFR-1014','ENEM-QFR-1015',
					'ENEM-QFR-1102','ENEM-QFR-1103','ENEM-QFR-1204','ENEM-QFR-1205','ENEM-QFR-1206','ENEM-QFR-1207','ENEM-QFR-1208','ENEM-QFR-1211',
					'ENEM-QFR-2601-1','ENEM-QFR-2601-3','ENEM-QFR-2603','ENEM-QFR-3001','ENEM-QFR-3002','ENEM-QFR-7409','ENEM-QFR-7410',
					'ENEM-QFR-7506','ENEM-QFR-7507','ENEM-QFR-7509','ENEM-QFR-9029','ENEM-QFR-9036','ENEM-QFR-9038','ENEM-QFR-9039','ENEM-QFR-9041',
					'ENEM-QFR-9042','ENEM-QFR-9045','ENEM-QFR-9047','ENEM-QFR-9048', 'ENEM-QFR-9049' {
                    approverList.add(Lead_Coordinator((Integer) step.Step_Number__c, lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }
                when 'EQCC-ENRM-004', 'EQCC-ENMM-001','EQCC-ENMM-002','EQCC-ENMM-003','EQCC-ENMM-004','EQCC-ENMM-005',
                     'EQCC-ENMM-011','EQCC-ENMM-012','EQCC-ENMM-013','EQCC-ENMM-014','EQCC-ENMM-015','EQCC-ENMM-017',
                     'EQCC-ENMM-018','EQCC-ENMM-019','EQCC-ENMM-020','EQCC-ENMM-021','EQCC-ENRM-005','EQCC-ENRM-009' {
                    approverList.add(Lead_Engineer((Integer) step.Step_Number__c, lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }
                /*when 'ENIM-QFR-031', 'ENIM-QFR-030' {
                    approverList.add(Lead_Coordinator_Operator(lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }*/
                when 'ENCM-QFR-13','ENIM-QFR-701','ENIM-QFR-702','ENIM-QFR-703','ENIM-QFR-704','ENIM-QFR-705','ENIM-QFR-706',
                    'ENIM-QFR-707','ENIM-QFR-708','ENIM-QFR-709','ENIM-QFR-712','ENIM-QFR-713','ENIM-QFR-714','ENIM-QFR-716',
                    'ENIM-QFR-741','ENEM-QFR-9050-GNR','EQCC-MECH-001','EQCC-MECH-002','EQCC-MECH-005','ENCM-QFR-04','ENCM-QFR-15',
                    'ENCM-QFR-17','ENCM-QFR-16','ENCM-QFR-18','ENCM-QFR-19','EQCC-ENRM-003','EQCC-ENMM-016','ENIM-QFR-501',
                    'ENIM-QFR-502','ENIM-QFR-503','ENIM-QFR-505','EQCC-MECH-004' {
                    approverList.add(Lead(lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }
                when 'ENEM-QFR-9040-GNR','ENIM-QFR-743','ENIM-QFR-742','ENIM-QFR-401','EQCC-MECH-006',
                    'EQCC-MECH-003','ENIM-QFR-710','ENIM-QFR-711','ENIM-QFR-715','ENIM-QFR-717','ENIM-QFR-718','ENIM-QFR-719','ENIM-QFR-720',
                    'ENIM-QFR-721','ENIM-QFR-722','ENIM-QFR-723','ENIM-QFR-724','ENIM-QFR-725','ENIM-QFR-726','ENIM-QFR-727',
                    'ENIM-QFR-728','ENIM-QFR-729','ENIM-QFR-730','ENIM-QFR-731','ENIM-QFR-732','ENIM-QFR-733','ENIM-QFR-734',
                    'ENIM-QFR-735','ENIM-QFR-736','ENIM-QFR-737','ENIM-QFR-738','ENIM-QFR-739','ENIM-QFR-740','ENIM-QFR-744',
                    'ENIM-QFR-745','ENIM-QFR-746','ENIM-QFR-747','ENIM-QFR-748','ENIM-QFR-749','ENIM-QFR-750','ENEM-QFR-4100',
                    'ENEM-QFR-4301','ENEM-QFR-4500','ENEM-QFR-1100','ENEM-QFR-5003','ENEM-QFR-5106','ENEM-QFR-5112','ENEM-QFR-9009','ENEM-QFR-4004','ENEM-QFR-4005','EQCC-TRAINING-001' {
                    approverList.add(Coordinator(lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }
                //DGMO Edit Flow To Manager
                /*when 'ENEM-QFR-4004','ENEM-QFR-4005' {
                    approverList.add(Coordinator_Manager( lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }*/
                /*when 'EQCC-ENRM-003' {
                    approverList.add(Lead_Operator(lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }*/
                when 'ENSA-QFR-01' {
                    approverList.add(Coordinator_Engineer(lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }
                // when 'ENEM-QFR-2604-REL', 'ENEM-QFR-1325-UPS', 'ENEM-QFR-9003-GNR', 'ENEM-QFR-9008-GNR' {
                //     approverList.add(Lead_Coordinator_Manager(lastStep, workingTeamLeadRole, apuTeam, subGroup));
                // }
                when 'EQCC-ENRM-001' {
                    approverList.add(Lead_Engineer(lastStep, workingTeamLeadRole, apuTeam, subGroup));
                }
                when else {
                }
            }
        }
        else {
            EQCC_Header__Share stepShr = new EQCC_Header__Share();
            stepShr.ParentId = step.Header_Sheet__r.Header__c;
            stepShr.UserOrGroupId = userId;
            stepShr.AccessLevel = 'Read';
            stepShr.RowCause = Schema.EQCC_Header__Share.RowCause.Manual;
            Database.SaveResult sr = Database.insert(stepShr,false);
            approverList.add(userId);
        }
        
        return approverList;
    }

    /**
     * @description returns the Id of the next queue/group for approval
     * @param stepNumber current step number
     * @param lastStep last approval step
     * @param workingTeamLeadRole working team member's lead
     * @param apuTeam apu division
     * @return String id of the next queue/role/user to approve based on the working team submitter's APU Hierarchy
     */

    /*private static String Lead_Coordinator_Manager(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        switch on lastStep {
            when 'Approved By Manager' {

            }
            when 'Approved By Coordinator' {
                return resolveManager(apuTeam);
            }
            when 'Approved By Lead' {
                return resolveCoordinator(apuTeam, subGroup, roleName);
            }
            when else {
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }
        return null;
    }*/
    
    //DGMO Edit
   /*private static String Coordinator_Manager(String lastStep, UserRole workingTeamLeadRole, String apuTeam, String subGroup){
        switch on lastStep {
            when 'Approved By Manager' {
                // don't need ids because the form is done
            }
           when 'Approved By Coordinator' {
                // step2
                return resolveManager(apuTeam);
            }
            when else {
                // step1
                System.debug(apuTeam+':'+subGroup+':'+roleName);
                return resolveCoordinator(apuTeam, subGroup, roleName);
            }
        }
        return null;
    }*/

    private static String Coordinator(String lastStep, UserRole workingTeamLeadRole, String apuTeam, String subGroup) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> Coordinator');
        switch on lastStep {
            when 'Approved By Coordinator' {
                // don't need ids because the form is done
            }
            when else {
                // Step 1: Coordinator
                return resolveCoordinator(apuTeam, subGroup, roleName);
            }
        }
        return null;
    }

    /**
     * @description returns the Id of the next queue/group for approval
     * @param stepNumber current step number
     * @param lastStep last approval step
     * @param workingTeamLeadRole working team member's lead
     * @param apuTeam apu division
     * @return String id of the next queue/role/user to approve based on the working team submitter's APU Hierarchy
     */
    // update 19/03/2021 By R2
    /*private static String Lead_Operator(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        switch on lastStep {
            when 'Approved By Operator' {

            }
            when 'Approved By Lead' {

                System.debug('Operator');
                return resolveOperator(apuTeam, subGroup);
            }
            when else {

                System.debug('Team Lead');
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }

        return null;
    }*/

    /**
     * @description returns the Id of the next queue/group for approval
     * @param stepNumber current step number
     * @param lastStep last approval step
     * @param workingTeamLeadRole working team member's lead
     * @param apuTeam apu division
     * @return String id of the next queue/role/user to approve based on the working team submitter's APU Hierarchy
     */
    private static String Lead_Coordinator(Integer stepNumber,String lastStep,UserRole workingTeamLeadRole,String apuTeam,String subGroup){
        system.debug('Method >>>>>>>>>>>>>>>>>>>> Lead_Coordinator');
        switch on lastStep {
            when 'Approved By Coordinator' {
                // don't need ids because the form is done
            }
            when 'Approved By Lead' {
                // Step 2: Coordinator
                return resolveCoordinator(apuTeam, subGroup, roleName);
            }
            when else {
                // Step 1: Team Lead
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }
        return null;
    }

    /**
     * @description returns the Id of the next queue/group for approval
     * @param lastStep last approval step
     * @param apuTeam current step
     * @return String id of the next queue/role/user to approve based on the working team submitter's APU Hierarchy
     */
    /*private static String ENIM_QFR_401(String lastStep, String apuTeam, String subGroup) {
        switch on lastStep {
            when 'Approved By Coordinator' {
                // don't need ids because the form is done
            }
            when 'Witness By Operator' {
                // Step 2: Coordinator
                System.debug('Coordinator');
                apuTeam = '%' + apuTeam + '%rdinator%';
                System.debug(apuTeam);
                subGroup = apuTeam.contains('APU-A') == true ? '%-' + subGroup.split('/')[0].right(1) : subGroup;
                String groupName = [
                    SELECT Role__c, Queue__c
                    FROM Approver__mdt
                    WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                    LIMIT 1
                ]
                .Queue__c;
                return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;
            }
            when else {
                // Step 1: Operator
                System.debug('Operator');
                apuTeam = '%' + apuTeam + '%Operator%';
                List<Approver__mdt> mappings = [
                    SELECT Role__c, Queue__c
                    FROM Approver__mdt
                    WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                    LIMIT 1
                ];
                String groupName;
                if (mappings.isEmpty()) {
                    subGroup = '%' + subGroup.split('/')[1];
                    groupName = [
                        SELECT Role__c, Queue__c
                        FROM Approver__mdt
                        WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                        LIMIT 1
                    ]
                    .Queue__c;
                } else {
                    groupName = mappings[0].Queue__c;
                }
                return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;
            }
        }

        return null;
    }*/

    /**
     * @description returns the Id of the next queue/group for approval
     * @param stepNumber current step number
     * @param lastStep last approval step
     * @param workingTeamLeadRole working team member's lead
     * @param apuTeam apu division
     * @return String id of the next queue/role/user to approve based on the working team submitter's APU Hierarchy
     */
    private static String EQCC_ENRM_007(Integer stepNumber,String lastStep,UserRole workingTeamLeadRole,String apuTeam,String subGroup) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> EQCC_ENRM_007');
        switch on stepNumber {
            when 1 {
                return EQCC_ENRM_007_Step1(lastStep, workingTeamLeadRole, apuTeam, subGroup);
            }
            when 2 {
                return EQCC_ENRM_007_Step2(lastStep, workingTeamLeadRole, apuTeam, subGroup);
            }
            when else {
                return null;
            }
        }
    }
    private static String EQCC_ENRM_007_Step1(String lastStep,UserRole workingTeamLeadRole,String apuTeam,String subGroup) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> EQCC_ENRM_007_Step1');
        switch on lastStep {
            when 'Witness By ENRM IP Engineer' {
                // don't need ids because the form is done
            }
            when 'Witness By Lead' {
                // Step 2: ENRM IP Engineer Group
                return resolveEngineer(apuTeam);
            }
            when else {
                // Step 1: Team Lead
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }
        return null;
    }
    private static String EQCC_ENRM_007_Step2(String lastStep,UserRole workingTeamLeadRole,String apuTeam,String subGroup) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> EQCC_ENRM_007_Step2');
        switch on lastStep {
            /*when 'Approved By Operator' {
                // don't need ids because the form is done
            }*/
            when 'Witness By ENRM QA Engineer' {
                // now
                // don't need ids because the form is done
                // before
                // Step 3: Operator
                /*System.debug('Operator');
                apuTeam = '%' + apuTeam + '%Operator%';
                List<Approver__mdt> mappings = [
                    SELECT Role__c, Queue__c
                    FROM Approver__mdt
                    WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                    LIMIT 1
                ];
                String groupName;
                if (mappings.isEmpty()) {
                    subGroup = '%' + subGroup.split('/')[1];
                    groupName = [
                        SELECT Role__c, Queue__c
                        FROM Approver__mdt
                        WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                        LIMIT 1
                    ]
                    .Queue__c;
                } else {
                    groupName = mappings[0].Queue__c;
                }
                return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;*/
            }
            when 'Witness By Lead' {
                // Step 2: ENRM QA Engineer Group
                return resolveQAEngineer(apuTeam);
            }
            when else {
                // Step 1: Team Lead
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }
        return null;
    }

    /**
     * @description returns the Id of the next queue/group for approval
     * @param stepNumber current step number
     * @param lastStep last approval step
     * @param workingTeamLeadRole working team member's lead
     * @param apuTeam apu division
     * @param subGroup apu sub-division
     * @return String id of the next queue/role/user to approve based on the working team submitter's APU Hierarchy
     */
    private static String EQCC_ENRM_002(Integer stepNumber,String lastStep,UserRole workingTeamLeadRole,String apuTeam,String subGroup,String stepId) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> EQCC_ENRM_002');
        switch on stepNumber {
            when 1 {
                return EQCC_ENRM_002_Step1(lastStep, workingTeamLeadRole, apuTeam, subGroup);
            }
            when 2 {
                return EQCC_ENRM_002_Step2(lastStep, workingTeamLeadRole, apuTeam, subGroup);
            }
            when 3 {
                return EQCC_ENRM_002_Step3(lastStep, workingTeamLeadRole, apuTeam, subGroup, stepId);
            }
            when else {
                return null;
            }
        }
    }

    private static String EQCC_ENRM_002_Step1(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> EQCC_ENRM_002_Step1');
        switch on lastStep {
            /*when 'Approved By Operator' {
                // don't need ids because the form is done
            }*/
            when 'Approved By ENRM IP Engineer' {
                // now
                // don't need ids because the form is done
                // before
                // Step 3: Operator
                /*System.debug('Operator');
                apuTeam = '%' + apuTeam + '%Operator%';
                List<Approver__mdt> mappings = [
                    SELECT Role__c, Queue__c
                    FROM Approver__mdt
                    WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                    LIMIT 1
                ];
                String groupName;
                if (mappings.isEmpty()) {
                    subGroup = '%' + subGroup.split('/')[1];
                    groupName = [
                        SELECT Role__c, Queue__c
                        FROM Approver__mdt
                        WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                        LIMIT 1
                    ]
                    .Queue__c;
                } else {
                    groupName = mappings[0].Queue__c;
                }

                return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;*/
            }
            when 'Witness By Lead' {
                // Step 2: ENRM IP Engineer Group
                return resolveEngineer(apuTeam);
            }
            when else {
                // Step 1: Team Lead
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }

        return null;
    }

    private static String EQCC_ENRM_002_Step2(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> EQCC_ENRM_002_Step2');
        switch on lastStep {
            when 'Witness By Lead' {
                // don't need ids because the form is done
            }
            when else {
                // Step 1: Team Lead
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }

        return null;
    }
	@TestVisible
    private static String EQCC_ENRM_002_Step3(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup,
        Id stepId
    ) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> EQCC_ENRM_002_Step3');
        Discipline_Mapping__mdt discipline = new Discipline_Mapping__mdt();

        EQCC_Step__c step = [SELECT Id, Step_Number__c, Form_Code__c, Owner.Name, Header_Sheet__r.Header__c FROM EQCC_Step__c WHERE Id = :stepId];
        EQCC_Header__c header = [SELECT Id, FunctionalLocation__c, Equipment__c FROM EQCC_Header__c WHERE Id =: step.Header_Sheet__r.Header__c];
        if(header.Equipment__c != null) {
            Equipment__c eq = [SELECT Id, maintenancePlant__r.Name, plantSection__c FROM Equipment__c WHERE Id =: header.Equipment__c];
            discipline = [SELECT Id, Area__c, Plant_Section_Description__c FROM Discipline_Mapping__mdt 
							WHERE Maintenance_Plant__c =: eq.maintenancePlant__r.Name AND Plant_Section__c =: eq.plantSection__c];
        }
        else {
            Functional_Location__c fl = [SELECT Id, Maintenance_Plant__r.Name, PlantSection__c FROM Functional_Location__c WHERE Id =: header.FunctionalLocation__c];
            discipline = [SELECT Id, Area__c, Plant_Section_Description__c FROM Discipline_Mapping__mdt 
							WHERE Maintenance_Plant__c =: fl.Maintenance_Plant__r.Name AND Plant_Section__c =: fl.PlantSection__c];
        }
        switch on lastStep {
            when 'Approved By ENRM IP Engineer' {
				 system.debug ('==Witpproved By ENRM IP Enginee===>'+resolveQAEngineer(apuTeam));
            }
            when 'Approved By ENRM QA Engineer' {
                system.debug ('==Approved By ENRM QA Enginee===>'+resolveEngineer(apuTeam));
                return resolveEngineer(apuTeam);
            }

            when 'Witness By ENRM IP Engineer' {
                return resolveEngineer(apuTeam);
            }
            when 'Witness By ENRM QA Engineer' {
                // now
                system.debug ('==Witness By ENRM QA Enginee===>'+resolveQAEngineer(apuTeam));
                //return resolveQAEngineer(apuTeam);
                return resolveEngineer(apuTeam);
            }
            when 'Witness By Instrumentation' {
                // Step 4: ENRM IP Engineer
                system.debug ('==Witness By Instrumentatio===>'+resolveQAEngineer(apuTeam));
                return resolveQAEngineer(apuTeam);
            }
            when 'Witness By Electrical' {
                // Step 3: Instrumentation
                String teamLead = '%APU-' + discipline.Area__c + ' Team Lead-ENM' + discipline.Area__c + '-I/' + discipline.Plant_Section_Description__c;
                system.debug ('==Witness By Electrical===>'+teamLead);
                return [SELECT Id FROM Group WHERE Name LIKE :teamLead LIMIT 1].Id;
            }
            when 'Witness By Mechanical' {
                // Step 2: Electrical
                String teamLead = '%APU-' + discipline.Area__c + ' Team Lead-ENM' + discipline.Area__c + '-E/' + discipline.Plant_Section_Description__c;
                system.debug ('==Witness By Mechanical===>'+teamLead);
                return [SELECT Id FROM Group WHERE Name LIKE :teamLead LIMIT 1].Id;
            }
            when else {
               
                String teamLead = '%APU-' + discipline.Area__c + ' Team Lead-ENM' + discipline.Area__c + '-M/' + discipline.Plant_Section_Description__c;
                  system.debug ('==When else==teamLead>'+teamLead);
                return [SELECT Id FROM Group WHERE Name LIKE :teamLead LIMIT 1].Id;
            }
        }

        return null;
    }

    /*private static String EQCC_ENRM_006(
        Integer stepNumber,
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup,
        Id stepId
    ) {
        switch on stepNumber {
            when 1 {
                return EQCC_ENRM_006_Step1(lastStep, workingTeamLeadRole, apuTeam, subGroup);
            }
            when 2 {
                return EQCC_ENRM_006_Step2(lastStep, workingTeamLeadRole, apuTeam, subGroup);
            }
            when 3 {
                return EQCC_ENRM_006_Step3(lastStep, workingTeamLeadRole, apuTeam, subGroup, stepId);
            }
            when else {
                return null;
            }
        }
    }

    private static String EQCC_ENRM_006_Step1(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        switch on lastStep {
            when 'Approved By ENRM IP Engineer' {
            }
            when 'Witness By Lead' {
                System.debug('ENRM QA Engineer');
                return resolveQAEngineer(apuTeam);
            }
            when else {
                System.debug('Team Lead');
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }

        return null;
    }

    private static String EQCC_ENRM_006_Step2(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        switch on lastStep {
            when 'Witness By Lead' {

            }
            when else {

                System.debug('Team Lead');
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }

        return null;
    }

    private static String EQCC_ENRM_006_Step3(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup,
        Id stepId
    ) {
        Discipline_Mapping__mdt discipline = new Discipline_Mapping__mdt();
        EQCC_Step__c step = [SELECT Id, Step_Number__c, Form_Code__c, Owner.Name, Header_Sheet__r.Header__c FROM EQCC_Step__c WHERE Id = :stepId];
        EQCC_Header__c header = [SELECT Id, FunctionalLocation__c, Equipment__c FROM EQCC_Header__c WHERE Id =: step.Header_Sheet__r.Header__c];
        if(header.Equipment__c != null) {
            Equipment__c eq = [SELECT Id, maintenancePlant__r.Name, plantSection__c FROM Equipment__c WHERE Id =: header.Equipment__c];
            discipline = [SELECT Id, Area__c, Plant_Section_Description__c FROM Discipline_Mapping__mdt 
                                                    WHERE Maintenance_Plant__c =: eq.maintenancePlant__r.Name
                                                    AND Plant_Section__c =: eq.plantSection__c];
        }
        else {
            Functional_Location__c fl = [SELECT Id, Maintenance_Plant__r.Name, PlantSection__c FROM Functional_Location__c WHERE Id =: header.FunctionalLocation__c];
            discipline = [SELECT Id, Area__c, Plant_Section_Description__c FROM Discipline_Mapping__mdt 
                                                    WHERE Maintenance_Plant__c =: fl.Maintenance_Plant__r.Name
                                                    AND Plant_Section__c =: fl.PlantSection__c];
        }
        switch on lastStep {

            when 'Approved By ENRM IP Engineer' {

            }
            when 'Witness By ENRM QA Engineer' {
                System.debug('ENRM IP Engineer');
                return resolveQAEngineer(apuTeam);
            }
            when 'Witness By Instrumentation' {

                System.debug('ENRM IP Engineer');
                return resolveQAEngineer(apuTeam);
            }
            when 'Witness By Electrical' {

                System.debug('Instrumentation Team Lead');
                String teamLead = '%APU-' + discipline.Area__c + ' Team Lead-ENM' + discipline.Area__c + '-I/' + discipline.Plant_Section_Description__c;
                System.debug('teamlead debug ' + teamlead);
                return [SELECT Id FROM Group WHERE Name LIKE :teamLead LIMIT 1].Id;
            }
            when 'Witness By Mechanical' {

                System.debug('Electrical Team Lead');
                String teamLead = '%APU-' + discipline.Area__c + ' Team Lead-ENM' + discipline.Area__c + '-E/' + discipline.Plant_Section_Description__c;
                System.debug('teamlead debug ' + teamlead);
                return [SELECT Id FROM Group WHERE Name LIKE :teamLead LIMIT 1].Id;
            }
            when else {

                System.debug('Mechanical Team Lead');
                
                System.debug('WorkingTeamLeadRole >>> ' + workingTeamLeadRole);
                System.debug('apuTeam >>> ' + apuTeam);
                String teamLead = '%APU-' + discipline.Area__c + ' Team Lead-ENM' + discipline.Area__c + '-M/' + discipline.Plant_Section_Description__c;
                System.debug('teamlead debug ' + teamlead);
                return [SELECT Id FROM Group WHERE Name LIKE :teamLead LIMIT 1].Id;
            }
        }

        return null;
    }*/

    /**
     * @description returns the Id of the next queue/group for approval
     * @param lastStep last approval step
     * @param workingTeamLeadRole team lead role
     * @param apuTeam apu Plant
     * @return String id of the next queue/role/user to approve based on the working team submitter's APU Hierarchy
     */
    private static String Lead_Engineer(
        Integer stepNumber,
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> Lead_Engineer');
        switch on stepNumber {
            when 1 {
                return Lead_Engineer_Step1(lastStep, workingTeamLeadRole, apuTeam, subGroup);
            }
            when 2 {
                return Lead_Engineer_Step2(lastStep, workingTeamLeadRole, apuTeam, subGroup);
            }
            when else {
                return null;
            }
        }
    }

    /**
     * @description returns the Id of the next queue/group for approval
     * @param lastStep last approval step
     * @param workingTeamLeadRole team lead role
     * @param apuTeam apu Plant
     * @return String id of the next queue/role/user to approve based on the working team submitter's APU Hierarchy
     */
    private static String Lead_Engineer_Step2(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> Lead_Engineer_Step2');
        switch on lastStep {
            /*when 'Approved By Operator' {
                // don't need ids because the form is done
            }*/
            when 'Approved By ENRM IP Engineer' {
                // now
                // don't need ids because the form is done

                //before
                // Step 3: Operator
                /*System.debug('Operator');
                apuTeam = '%' + apuTeam + '%Operator%';
                List<Approver__mdt> mappings = [
                    SELECT Role__c, Queue__c
                    FROM Approver__mdt
                    WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                    LIMIT 1
                ];
                String groupName;
                if (mappings.isEmpty()) {
                    subGroup = '%' + subGroup.split('/')[1];
                    groupName = [
                        SELECT Role__c, Queue__c
                        FROM Approver__mdt
                        WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                        LIMIT 1
                    ]
                    .Queue__c;
                } else {
                    groupName = mappings[0].Queue__c;
                }
                return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;*/
            }
            when 'Approved By Lead' {
                // Step 2: ENRM IP Engineer
                return resolveEngineer(apuTeam);
            }
            when else {
                // Step 1: Team Lead
                /*String teamLead = workingTeamLeadRole.Name;
                if (
                    [SELECT UserRole.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1]
                        .UserRole.Name.contains('Team Lead')
                ) {
                    teamLead = subGroup;
                }
                String groupName = [
                    SELECT Role__c, Queue__c
                    FROM Approver__mdt
                    WHERE Role__c LIKE :teamLead AND Role__c LIKE '%Team Lead%'
                ]
                .Queue__c;
                return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;*/
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }

        return null;
    }

    /**
     * @description returns the Id of the next queue/group for approval
     * @param lastStep last approval step
     * @param workingTeamLeadRole team lead role
     * @param apuTeam apu Plant
     * @return String id of the next queue/role/user to approve based on the working team submitter's APU Hierarchy
     */
    private static String Lead_Engineer_Step1(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> Lead_Engineer_Step1');
        switch on lastStep {
            when 'Approved By ENRM IP Engineer' {
                // don't need ids because the form is done
            }
            when 'Approved By Lead' {
                // Step 2: ENRM IP Engineer
                return resolveEngineer(apuTeam);
            }
            when else {
                // Step 1: Team Lead
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }

        return null;
    }

    /**
     * @description returns the Id of the next queue
     */

    /*private static String Lead_Coordinator_Operator(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        switch on lastStep {
            when 'Approved By Operator' {
                // don't need ids because the form is done
            }
            when 'Approved By Coordinator' {
                // Step 3: Operator
                System.debug('Operator');
                apuTeam = '%' + apuTeam + '%Operator%';
                //subGroup = '%' + subGroup.split('/')[1];
                String groupName = [
                    SELECT Role__c, Queue__c
                    FROM Approver__mdt
                    WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                    LIMIT 1
                ]
                .Queue__c;
                return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;
            }
            when 'Approved By Lead' {
                // Step 2: Coordinator
                System.debug('Coordinator');
                apuTeam = '%' + apuTeam + '%rdinator%';
                System.debug(apuTeam);
                subGroup = apuTeam.contains('APU-A') == true ? '%-' + subGroup.split('/')[0].right(1) : subGroup;
                String groupName = [
                    SELECT Role__c, Queue__c
                    FROM Approver__mdt
                    WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                    LIMIT 1
                ]
                .Queue__c;
                return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;
            }
            when else {
                // Step 1: Team Lead
                System.debug('Team Lead');
                String teamLead = workingTeamLeadRole.Name;
                if (
                    [SELECT UserRole.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1]
                        .UserRole.Name.contains('Team Lead')
                ) {
                    teamLead = subGroup;
                }
                String groupName = [
                    SELECT Role__c, Queue__c
                    FROM Approver__mdt
                    WHERE Role__c LIKE :teamLead AND Role__c LIKE '%Team Lead%'
                ]
                .Queue__c;
                return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;
            }
        }

        return null;
    }*/

    private static String Lead(String lastStep, UserRole workingTeamLeadRole, String apuTeam, String subGroup) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> Lead');
        switch on lastStep {
            when 'Approved By Lead' {
                // don't need ids because the form is done
            }
            when else {
                // Step 1: Team Lead
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }

        return null;
    }

    private static String Coordinator_Engineer(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> Coordinator_Engineer');
        switch on lastStep {
            when 'Approved By ENSA Engineer Group' {
                // don't need ids because the form is done
            }
            when 'Approved By Coordinator' {
                // Step 2: ENSA Engineer Group
                return resolveENSAEngineer();
            }
            when else {
                // Step 1: Coordinator
                return resolveCoordinator(apuTeam, subGroup, roleName);
            }
        }
        return null;
    }

    private static String Lead_Engineer(
        String lastStep,
        UserRole workingTeamLeadRole,
        String apuTeam,
        String subGroup
    ) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> Lead_Engineer');
        switch on lastStep {
            when 'Approved By ENRM IP Engineer' {
                // don't need ids because the form is done
            }
            when 'Approved By Lead' {
                // Step 2: ENRM IP Engineer
                return resolveEngineer(apuTeam);
            }
            when else {
                // Step 1: Lead
                return resolveTeamLeader(workingTeamLeadRole, apuTeam, subGroup);
            }
        }
        return null;
    }

    private static String resolveTeamLeader(UserRole workingTeamLeadRole, String apuTeam, String subGroup) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveTeamLeader');
        String teamLead = workingTeamLeadRole.Name;
 system.debug('==1310role== UserInfo.getUserId===='+UserInfo.getUserId());
        teamLead = [SELECT UserRole.Name,Role_Approve_process__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1]
                .Role_Approve_process__c.contains('Team Lead') ? subGroup :workingTeamLeadRole.Name;

        String groupName;
        if (teamLead.contains('APU-F')) {
            groupName = resolveAPUFGroupName(teamLead);
        } else {
            system.debug('==Role__c LIKE :teamLead===='+teamLead);
            groupName = [SELECT Role__c, Queue__c FROM Approver__mdt WHERE Role__c LIKE :teamLead AND Role__c LIKE '%Team Lead%'].Queue__c;
        }

        return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;
    }

    public static String resolveAPUFGroupName(String teamLead) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveAPUFGroupName');
        String groupName;
        if (teamLead.contains('Fabshop')) {
            groupName = [SELECT Role__c, Queue__c FROM Approver__mdt WHERE Role__c LIKE :teamLead AND Role__c LIKE '%Team Lead%' AND Role__c LIKE '%Fabshop%'].Queue__c;
        } else {
            groupName = [
                SELECT Role__c, Queue__c FROM Approver__mdt WHERE Role__c LIKE :teamLead AND Role__c LIKE '%Team Lead%' AND (NOT Role__c LIKE '%Fabshop%')].Queue__c;
        }
        return groupName;
    }

    //this is needed because of the lack of a pattern for Coordinator roles
    private static String resolveCoordinator(String apuTeam, String subGroup, String roleName) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveCoordinator');
        String inspectionRoleWT = 'TOP THOR ENRM Working Team-ENRM-Inspection/RCA/Project/';
        String inspectionRoleTL = 'TOP THOR ENRM Team Lead-ENRM-Inspection/RCA/Project/';
        String engineerProjectRoleWT = 'TOP THOR ENTS Working Team-ENTS QA Engineer Project&Welding';
        String engineerProjectRoleTL = 'TOP THOR ENTS Team Lead-ENTS QA Engineer Project&Welding';
        String ensaRole = 'TOP THOR ENSA Working Team-ENSA';
        String nextApprover;
        if (roleName.contains(inspectionRoleWT) || roleName.contains(inspectionRoleTL)) {
            nextApprover = 'TOP THOR ENRM Co-Ordinator-ENRM/Inspection&Reliability/All APU';
            return resolveSpecialCoordinator(nextApprover);
        } else if (roleName.contains(ensaRole)) {
            nextApprover = 'TOP THOR ENSA Co-Ordinator-ENSA Benchmarking&Planning/All APU';
            return resolveSpecialCoordinator(nextApprover);
        } else if (roleName.contains(engineerProjectRoleWT) || roleName.contains(engineerProjectRoleTL)) {
            nextApprover = 'TOP THOR ENTS Co-Ordinator-ENTS Corrosion Engineer';
            return resolveSpecialCoordinator(nextApprover);
        }

        return resolveCoordinator(apuTeam, subGroup);
    }

    

    private static String resolveSpecialCoordinator(String nextApprover) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveSpecialCoordinator');
        String groupName = [SELECT Role__c, Queue__c FROM Approver__mdt WHERE Role__c LIKE :nextApprover LIMIT 1].Queue__c;
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;
    }

    private static String resolveCoordinator(String apuTeam, String subGroup) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveCoordinator');
        system.debug('Original apuTeam ' +apuTeam);
        system.debug('Original subGroup ' +subGroup);
        apuTeam = '%' + apuTeam + '%rdinator%';
        subGroup = apuTeam.contains('APU-A') == true ? '%-' + subGroup.split('/')[0].right(1) : subGroup;
        system.debug('apuTeam ' +apuTeam);
        system.debug('subGroup ' +subGroup);
        String groupName;
        if (!apuTeam.contains('APU-A')) {
            System.debug('Not APU-A');
            String[] subGroups = subGroup.split(' ');
            String groups = '';
            for (Integer i = 0; i < subGroups.size(); i++) {
                subGroups[i] = subGroups[i].replace('%', '');
                String[] subSubgroups;
                if (subGroups[i].contains('/')) {
                    subSubgroups = subGroup.split('/');
                    for (Integer j = 0; j < subSubgroups.size() - 1; j++) {
                        if (subSubgroups[j].contains(' ')) {
                            String[] subSubgroupsWithoutSpace = subSubgroups[j].split(' ');
                            for (Integer k = 0; k < subSubgroupsWithoutSpace.size() - 1; k++) {
                                groups += ' AND Role__c LIKE \'%' + subSubgroupsWithoutSpace[k] + '%\'';
                            }
                            if (subSubgroupsWithoutSpace[subSubgroupsWithoutSpace.size() - 1] != 'Benchmarking') {
                                groups +=' AND Role__c LIKE \'%' +subSubgroupsWithoutSpace[subSubgroupsWithoutSpace.size() - 1] +'/%\'';
                            }
                        } else {
                            groups += ' AND Role__c LIKE \'%' + subSubgroups[j] + '/%\'';
                        }
                    }
                    groups += ' AND Role__c LIKE \'%' + subSubgroups[subSubgroups.size() - 1] + '%\'';
                } else {
                    groups += ' AND Role__c LIKE \'%' + subGroups[i] + '%\'';
                }
            }
            String query;
            if (groups.contains('APU-F')) {
                if (groups.contains('Fabshop')) {
                    query ='SELECT Role__c, Queue__c FROM Approver__mdt WHERE Role__c LIKE \'' +apuTeam +'\'' +groups +'AND Role__c LIKE \'%Fabshop%\' LIMIT 1';
                } 
                else if(groups.contains('Analyzer')) {
                    groups = groups.replace('APU-F', 'APU-E');
                    query ='SELECT Role__c, Queue__c FROM Approver__mdt WHERE Role__c LIKE \'' +apuTeam +'\'' +groups +' LIMIT 1';
                }
                else {
                    query ='SELECT Role__c, Queue__c FROM Approver__mdt WHERE Role__c LIKE \'' +apuTeam +'\'' +groups +'AND (NOT Role__c LIKE \'%Fabshop%\') LIMIT 1';
                }
            } else {
                query ='SELECT Role__c, Queue__c FROM Approver__mdt WHERE Role__c LIKE \'' +apuTeam +'\'' +groups +' LIMIT 1';
            }

            groupName = ((Approver__mdt) Database.query(query)).Queue__c;
        } else {
            groupName = [SELECT Role__c, Queue__c FROM Approver__mdt WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup LIMIT 1].Queue__c;
        }
        system.debug('groupName : '+groupName);
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;
    }

    /*private static String resolveOperator(String apuTeam, String subGroup) {
        apuTeam = '%' + apuTeam + '%Operator%';
        List<Approver__mdt> mappings = [
            SELECT Role__c, Queue__c
            FROM Approver__mdt
            WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
            LIMIT 1
        ];
        String groupName;
        if (mappings.isEmpty()) {
            subGroup = '%' + subGroup.split('/')[1];
            groupName = [
                SELECT Role__c, Queue__c
                FROM Approver__mdt
                WHERE Role__c LIKE :apuTeam AND Role__c LIKE :subGroup
                LIMIT 1
            ]
            .Queue__c;
        } else {
            groupName = mappings[0].Queue__c;
        }
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :groupName + '%' LIMIT 1].Id;
    }*/

    @TestVisible private static String resolveENSAEngineer() {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveENSAEngineer');
        String apuTeam = '%ENSA Engineer Group%';
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :apuTeam + '%' LIMIT 1].Id;
    }
    @TestVisible private static String resolveEngineer(String apuTeam) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveEngineer');
        apuTeam = '%' + apuTeam + '%ENRM IP Engineer%';
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :apuTeam + '%' LIMIT 1].Id;
    }
    @TestVisible private static String resolveQAEngineer(String apuTeam) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveQAEngineer');
        apuTeam = '%ENRM QA Engineer%';
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :apuTeam LIMIT 1].Id;
    }
    @TestVisible private static String resolveManager(String apuTeam) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> resolveManager');
        apuTeam = '%' + apuTeam + '%Manager%';
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND Name LIKE :apuTeam + '%' LIMIT 1].Id;
    }

    //FOR WHEN WINTER '21 RELEASE COMES OUT
    //FOR NOTIFICATIONS
    private static void sendAlert(List<String> users, String processId, String body, String title, String sheetGroup) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> sendAlert');
        Id typeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'THOR_Push_Notification'].Id;
        Set<String> userIds = new Set<String>();
        userIds.addAll(users);
        PageReference pageRef = new PageReference('n/My_approvals');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setBody(body);
        notification.setTitle(title);
        //notification.setTargetPageRef('{"type": "standard__navItemPage", "attributes": { "apiName": "My_approvals"}}');
        notification.setTargetPageRef(
            '{"type": "standard__component", "attributes": {"componentName": "c__THOR_ApprovalSteps"}, "state": {"c__recordId": "' +
            processId +'", "c__sheetGroup": "' + sheetGroup + '"}}'
        );
        notification.setNotificationTypeId(typeId);
        try {
            notification.send(userIds);
        } catch (Exception e) {
//System.debug('Problem sending notification: ' + e.getMessage());
        }
    }

    public static void createNotification(String status, EQCC_Step__c step, List<String> approvers) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> createNotification');
        ProcessInstanceStep processSteps = [
            SELECT Id,ActorId,Comments,StepStatus,ProcessInstance.Status,ProcessInstance.TargetObjectId,CreatedDate
            FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :step.Id ORDER BY CreatedDate DESC LIMIT 1];
            List<GroupMember> groupMembers = [Select Id, Group.Name, Group.DeveloperName, Group.Type, UserOrGroupId From GroupMember where GroupId =: approvers.get(0)];
            Set<String> devNames = new Set<String>();
            Set<String> roleNames = new Set<String>();
            List<String> groupId1s = new List<String>();
            List<String> groupId2s = new List<String>();
            for(GroupMember groupMember : groupMembers) {
                groupId1s.add(groupMember.UserOrGroupId);
            }

            List<GroupMember> regGroups = [Select Id, Group.Name, Group.DeveloperName, Group.Type, UserOrGroupId From GroupMember where GroupId IN: groupId1s];
            if(regGroups.size() > 0) {
                for(GroupMember regGroup : regGroups) {
                    groupId2s.add(regGroup.UserOrGroupId);
                }
                List<Group> groups = [Select Id, Name, DeveloperName From Group where Id IN: groupId2s];
                if(groups.size() > 0) {
                                            for(Group g : groups) {
                                                devNames.add(g.DeveloperName);
                                            }
                                        }
            }
            else {
                List<Group> groups = [Select Id, Name, DeveloperName From Group where Id IN: groupId1s];
                if(groups.size() > 0) {
                                            for(Group g : groups) {
                                                devNames.add(g.DeveloperName);
                                            }
                                        }
            }
                            
                    
            List<Approver__mdt> approverMDTs = [SELECT Id, DeveloperName, Role__c, Queue__c FROM Approver__mdt WHERE Developer_Name__c LIKE: devNames];

            for(Approver__mdt approverMDT : approverMDTs) {
                roleNames.add(approverMDT.Role__c);
            }

            if(status == 'Approved') {
                List<OPP_Notification__c> notifications = [SELECT Id, Status__c FROM OPP_Notification__c WHERE ReferenceID__c =: step.Id AND (Status__c = 'New' OR Status__c = 'Reassigned')];
				for(OPP_Notification__c notification : notifications) {
						notification.Status__c = 'Approved';
						update notification;
				}
                
            } else {
                List<OPP_Notification__c> notifications = [SELECT Id FROM OPP_Notification__c WHERE Status__c = 'Rejected' AND User__c =: UserInfo.getUserId() LIMIT 1];
                if(notifications.size() > 0) {
                    for(OPP_Notification__c notification : notifications) {
                        notification.Status__c = 'Done';
                        update notification;
                    }
                }
            }
        
            // List<User> users = [SELECT Id FROM User WHERE UserRole.Name IN: roleNames];
            // users = [SELECT Id FROM User WHERE Role_Approve_Process__c IN: roleNames];
            // String appId = [SELECT Id FROM OPP_Application__c WHERE Name = 'THOR' LIMIT 1].Id;
            // EQCC_Checked_Sheet__c checkSheet = [SELECT Id, Group__c FROM EQCC_Checked_Sheet__c WHERE Sheet_Code__c =: step.Form_Code__c LIMIT 1];
        
        	// THORIntegration__c ThorCustomSetting = THORIntegration__c.getInstance();
        	// String OrgUrl = ThorCustomSetting.OrgDomainUrl__c;
                
            // List<OPP_Notification__c> getNotifications = new List<OPP_Notification__c>();
            // if(users.size() > 0) {
            //     for(User user : users) {
            //         OPP_Notification__c notification = new OPP_Notification__c();
            //         notification.Application__c = appId;
            //         notification.Description__c =  processSteps.Comments;
            //         notification.Event__c = 'Action';
            //         notification.ReferenceID__c = step.Id;
            //         notification.Requester__c = step.Owner.Name;
            //         notification.Status__c = 'New';
            //         notification.Subject__c = 'Approve has been assigned to you';
            //         notification.Step__c = String.valueOf(step.Step_Number__c);
            //         notification.URL__c = OrgUrl + '/lightning/cmp/c__THOR_ApprovalSteps?c__recordId=' + processSteps.Id + '&c__sheetGroup=' + checkSheet.Group__c;
            //         notification.User__c = user.Id;
            //         getNotifications.add(notification);
            //     }
            //     insert getNotifications;
            // } 
    }
    
    public static void createReviseNotification(EQCC_Step__c step){
        system.debug('Method >>>>>>>>>>>>>>>>>>>> createReviseNotification');
        List<OPP_Notification__c> notifications = [SELECT Id, Status__c FROM OPP_Notification__c WHERE ReferenceID__c =: step.Id AND Status__c = 'New'];
        for(OPP_Notification__c notification : notifications) {
            notification.Status__c = 'Done';
            update notification;
        }
        Header_Sheet__c headerSheet = getHeaderSheetFromStep(step);
        String appId = [SELECT Id FROM OPP_Application__c WHERE Name = 'THOR' LIMIT 1].Id;
        ProcessInstanceStep processSteps = [SELECT Id,Comments FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :step.Id ORDER BY CreatedDate DESC LIMIT 1];
        EQCC_Checked_Sheet__c checkSheet = [SELECT Id, Group__c FROM EQCC_Checked_Sheet__c WHERE Sheet_Code__c =: step.Form_Code__c LIMIT 1];
        THORIntegration__c ThorCustomSetting = THORIntegration__c.getInstance();
        String OrgUrl = ThorCustomSetting.OrgDomainUrl__c;
    }
    
    public static void sendEmailForApprove(Eqcc_Step__c stepRecord, List<String> approvers) {
        system.debug('Method >>>>>>>>>>>>>>>>>>>> sendEmailForApprove');
        List<GroupMember> groupMembers = [Select Id, Group.Name, Group.DeveloperName, Group.Type, UserOrGroupId From GroupMember where GroupId =: approvers.get(0)];
            Set<String> devNames = new Set<String>();
            Set<String> roleNames = new Set<String>();
            List<String> groupId1s = new List<String>();
            List<String> groupId2s = new List<String>();
            for(GroupMember groupMember : groupMembers) {
                groupId1s.add(groupMember.UserOrGroupId);
            }

            List<GroupMember> regGroups = [Select Id, Group.Name, Group.DeveloperName, Group.Type, UserOrGroupId From GroupMember where GroupId IN: groupId1s];
            if(regGroups.size() > 0) {
                for(GroupMember regGroup : regGroups) {
                    groupId2s.add(regGroup.UserOrGroupId);
                }
                List<Group> groups = [Select Id, Name, DeveloperName From Group where Id IN: groupId2s];
                if(groups.size() > 0) {
                                            for(Group g : groups) {
                                                devNames.add(g.DeveloperName);
                                            }
                                        }
            }
            else {
                List<Group> groups = [Select Id, Name, DeveloperName From Group where Id IN: groupId1s];
                if(groups.size() > 0) {
                                            for(Group g : groups) {
                                                devNames.add(g.DeveloperName);
                                            }
                                        }
        }
                                  
        List<Approver__mdt> approverMDTs = [SELECT Id, DeveloperName, Role__c, Queue__c FROM Approver__mdt WHERE Developer_Name__c LIKE: devNames];
        for(Approver__mdt approverMDT : approverMDTs) {
            roleNames.add(approverMDT.Role__c);
        }
        //List<User> users = [SELECT Id, Email, Name FROM User WHERE UserRole.Name IN: roleNames];
        List<User> users = [SELECT Id, Email, Name FROM User WHERE Role_Approve_Process__c IN: roleNames];
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		EQCC_Step__c step = [SELECT Id, CreatedById,Header_Sheet__r.Header__r.Notification__r.Functional_Location__r.Name,
                          		  Header_Sheet__r.Header__r.Notification__r.Name,Header_Sheet__r.Header__r.Notification__r.Description__c,
                          		  Header_Sheet__r.Header__r.Order__r.Name,Header_Sheet__r.Header__r.Order__r.Description__c,Header_Sheet__r.Sheet__r.Name,Header_Sheet__r.Sheet__r.Form_Name__c 
                                  FROM EQCC_Step__c WHERE Id =: stepRecord.Id];
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        for(User user : users) {
            List<String> sendTo = new List<String>();
            sendTo.add(user.Email);
            mail.setToAddresses(sendTo);
			mail.setSenderDisplayName('Thaioil Salesforce Support');
			mail.setSubject('[THOR Mobility] Action Required : Approve EQCC FORM');
			mail.setBccSender(false);
			mail.setUseSignature(false);
			mail.setHtmlBody('Dear ' + user.Name + '<br> &nbsp;&nbsp; <br>You have received an approval request. <br> &nbsp;&nbsp; <br>Sheet Name + Description Sheet Name : '+
                 step.Header_Sheet__r.Sheet__r.Name + ' ' + step.Header_Sheet__r.Sheet__r.Form_Name__c +'<br>FL. : '+step.Header_Sheet__r.Header__r.Notification__r.Functional_Location__r.Name+'<br>Notification + Notification Description : ' 
                 +step.Header_Sheet__r.Header__r.Notification__r.Name + ' ' + step.Header_Sheet__r.Header__r.Notification__r.Description__c + '<br>Order + Order Description : '
                 +step.Header_Sheet__r.Header__r.Order__r.Name + ' ' + step.Header_Sheet__r.Header__r.Order__r.Description__c + '<br>Click on the link to access EQCC Form :<br>'
                 +baseUrl + '/lightning/n/My_approvals' + '<br><br>'
                 +'Please review the request.<br>'
                 +'Thank you');
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    public static void sendEmailToSubmitor(Eqcc_Step__c stepRecord) {
        // system.debug('Method >>>>>>>>>>>>>>>>>>>> sendEmailToSubmitor');
		// Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		// EQCC_Step__c step = [SELECT Id, CreatedById,Header_Sheet__r.Header__r.Notification__r.Functional_Location__r.Name, Owner.Email,
        //                   		  Header_Sheet__r.Header__r.Notification__r.Name,Header_Sheet__r.Header__r.Notification__r.Description__c,
        //                   		  Header_Sheet__r.Header__r.Order__r.Name,Header_Sheet__r.Header__r.Order__r.Description__c,Header_Sheet__r.Sheet__r.Name,Header_Sheet__r.Sheet__r.Form_Name__c 
        //                           FROM EQCC_Step__c WHERE Id =: stepRecord.Id];
        // List<String> sendTo = new List<String>();
        
        // if(!Test.isRunningTest())
        // {
        //     sendTo.add(step.Owner.Email);
        // }
        // else
        // {
        //     sendTo.add('test@test.com');
        // }
        // mail.setToAddresses(sendTo);
        // mail.setSenderDisplayName('Thaioil Salesforce Support');
        // mail.setSubject('[THOR Mobility] Notification : EQCC FORM has been fully approved');
        // mail.setBccSender(false);
        // mail.setUseSignature(false);
        // mail.setHtmlBody('Dear ' + user.Name + '<br> &nbsp;&nbsp; <br>EQCC Form was approved. <br> &nbsp;&nbsp; <br>Sheet Name + Description Sheet Name : '+
        //          step.Header_Sheet__r.Sheet__r.Name + ' ' + step.Header_Sheet__r.Sheet__r.Form_Name__c +'<br>FL. : '+step.Header_Sheet__r.Header__r.Notification__r.Functional_Location__r.Name+'<br>Notification + Notification Description : ' 
        //          +step.Header_Sheet__r.Header__r.Notification__r.Name + ' ' + step.Header_Sheet__r.Header__r.Notification__r.Description__c + '<br>Order + Order Description : '
        //          +step.Header_Sheet__r.Header__r.Order__r.Name + ' ' + step.Header_Sheet__r.Header__r.Order__r.Description__c
        //          +'<br>Thank you');
		// 	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}