page 90003 PIPrintQueue
{
    Caption = 'PIPrint Queues';
    PageType = List;
    SourceTable = PIPrintQueue;
    UsageCategory = None;
    SourceTableView = sorting(PrinterRowNo);
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(RowNo; Rec.RowNo)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'This is the Row No. of the Row';
                }
                field(PrinterRowNo; Rec.PrinterRowNo)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'This is the Row No. of Printer which this job should be printed to';
                }
                field(HostID; Rec.HostID)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'This is the Host ID handling printing to the Printer this job should be printed to';
                }
                field(PrinterID; Rec.PrinterID)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'This is the Printer ID of the Printer this job should be printed to';
                }
                field(PrinterName; Rec.PrinterName)
                {
                    ApplicationArea = All;
                    ToolTip = 'This is the Printer Name of the Printer this job should be printed to';
                }
                field(PrinterJobJsonPayload; Rec.PrinterJobJsonPayload)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'This is the JSON payload describing the Print job';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'This is the current status of the job';
                }
                field(Printed; Rec.Printed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Date and time of when the job was printed successfully';
                }
                field(PrinterMessage; Rec.PrinterMessage)
                {
                    ApplicationArea = All;
                    ToolTip = 'This field holds messages from the printer regarding the job (i.e. additional status information)';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(Show)
            {
                ApplicationArea = All;
                Caption = 'Show the Job';
                ToolTip = 'Show this job';
                Image = SendAsPDF;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = Rec.RowNo > 0;

                trigger OnAction()
                var
                    InStream_: InStream;
                    Filename: Text;
                    FilenameLbl: Label '%1.pdf', Locked = true, Comment = '%1 is the RowNo of the print job.';
                begin
                    if not Rec.PDFPrintJob.HasValue() then
                        exit;

                    Rec.CalcFields(PDFPrintJob);
                    Rec.PDFPrintJob.CreateInStream(InStream_);
                    Filename := StrSubstNo(FilenameLbl, Rec.RowNo);
                    DownloadFromStream(InStream_, '', '', '', Filename);
                end;
            }
        }
        area(Processing)
        {
            action(Hold)
            {
                ApplicationArea = All;
                Caption = 'Hold the Job';
                ToolTip = 'Hold this job';
                Image = Pause;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = (Rec.Status <> Rec.Status::Hold) and (Rec.RowNo > 0);

                trigger OnAction()
                begin
                    Rec.Validate(Status, Rec.Status::Hold);
                    Rec.Modify(true);
                end;
            }
            action(Restart)
            {
                ApplicationArea = All;
                Caption = 'Restart Job';
                ToolTip = 'Restart this job';
                Image = NextRecord;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = (Rec.Status <> Rec.Status::Queued) and (Rec.RowNo > 0);

                trigger OnAction()
                begin
                    Rec.Validate(Status, Rec.Status::Queued);
                    Rec.Modify(true);
                end;
            }
            action(Cancel)
            {
                ApplicationArea = All;
                Caption = 'Cancel Job';
                ToolTip = 'Restart this job';
                Image = Cancel;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = (Rec.Status <> Rec.Status::Cancelled) and (Rec.RowNo > 0);

                trigger OnAction()
                begin
                    Rec.Validate(Status, Rec.Status::Cancelled);
                    Rec.Modify(true);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        Rec.AutoCleanUpJobs();
    end;
}
