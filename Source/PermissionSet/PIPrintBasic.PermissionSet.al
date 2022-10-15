permissionset 90002 PIPrintBasic
{
    Caption = 'PIPrint Basic Permissions';
    Permissions =
        table PIPrintPrinter = X,
        tabledata PIPrintPrinter = R,
        table PIPrintQueue = X,
        tabledata PIPrintQueue = RMID,
        codeunit PIPrintManagement = X,
        page PIPrintPrinter = X,
        page PIPrintQueue = X;
}