permissionset 90000 PIPrintAll
{
    Assignable = true;
    Caption = 'PIPrint All Permissions';
    Permissions =
        table PIPrintPrinter = X,
        tabledata PIPrintPrinter = RMID,
        table PIPrintQueue = X,
        tabledata PIPrintQueue = RMID,
        codeunit PIPrintManagement = X,
        page PIPrintPrinter = X,
        page PIPrintPrinterWS = X,
        page PIPrintQueue = X,
        page PIPrintQueueWS = X;
}