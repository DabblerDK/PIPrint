permissionset 90001 PIPrintProcessor
{
    Assignable = true;
    Caption = 'PIPrint Processer webservice permissions';
    Permissions =
        table PIPrintPrinter = X,
        tabledata PIPrintPrinter = RMI,
        table PIPrintQueue = X,
        tabledata PIPrintQueue = RM,
        page PIPrintPrinterWS = X,
        page PIPrintQueueWS = X;
}