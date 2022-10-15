page 90002 PIPrintQueueWS
{
    Caption = 'PIPrint Queues WS', Locked = true;
    PageType = List;
    SourceTable = PIPrintQueue;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(RowNo; Rec.RowNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'This is the Row No. of the Row';
                    Editable = false;
                }
                field(PrinterRowNo; Rec.PrinterRowNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'This is the Printer RowNo of the printer this job should be printed to';
                    Editable = false;
                }
                field(HostID; Rec.HostID)
                {
                    ApplicationArea = All;
                    ToolTip = 'This is the Host ID handling printing to the Printer this job should be printed to';
                    Editable = false;
                }

                field(PrinterID; Rec.PrinterID)
                {
                    ApplicationArea = All;
                    ToolTip = 'This is the Printer ID of the Printer this job should be printed to';
                    Editable = false;
                }
                field(PrinterName; Rec.PrinterName)
                {
                    ApplicationArea = All;
                    ToolTip = 'This is the Printer Name of the Printer this job should be printed to';
                    Editable = false;
                }
                field(PrinterJobJsonPayload; Rec.PrinterJobJsonPayload)
                {
                    ApplicationArea = All;
                    ToolTip = 'This is the JSON payload describing the Print job';
                    Editable = false;
                }
                field(PDFPrintJobBASE64; PDFPrintJobBASE64)
                {
                    Caption = 'PDF Print Job BASE64', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'This is the actual BASE 64 encoded binary Print job as PDF';
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'This is the current status of the job';
                }
                field(Printed; Rec.Printed)
                {
                    Caption = 'Printed', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Date and time of when the job was printed successfully';
                    Editable = false;
                }
                field(PrinterMessage; Rec.PrinterMessage)
                {
                    Caption = 'Printer Message', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'This field holds messages from the printer regarding the job (i.e. additional status information)';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStream_: InStream;
    begin
        PDFPrintJobBASE64 := '';
        if Rec.PDFPrintJob.HasValue() then
            if Rec.CalcFields(PDFPrintJob) then begin
                Rec.PDFPrintJob.CreateInStream(InStream_);
                PDFPrintJobBASE64 := Base64Convert.ToBase64(InStream_);
            end;
    end;

    var
        PDFPrintJobBASE64: Text;
}
