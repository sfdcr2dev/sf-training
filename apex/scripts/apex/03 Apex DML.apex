Account acct = new Account();
acct.Name = 'Acme';
acct.Phone = '(415)555-1212';
acct.NumberOfEmployees = 100;

insert acct;

ID acctID = acct.ID;

System.debug('ID = ' + acctID);