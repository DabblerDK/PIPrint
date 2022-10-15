page 90000 PIPrintPrinterWS
{
    Caption = 'PIPrint Printers WS', Locked = true;
    PageType = List;
    SourceTable = PIPrintPrinter;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(RowNo; Rec.RowNo)
                {
                    Caption = 'RowNo', Locked = true;
                    ToolTip = 'This is the Row No. of the Row';
                    ApplicationArea = All;
                }
                field(HostID; Rec.HostID)
                {
                    Caption = 'HostID', Locked = true;
                    ToolTip = 'This is the Host ID handling printing to the Printer this job should be printed to';
                    ApplicationArea = All;
                }
                field(PrinterID; Rec.PrinterID)
                {
                    Caption = 'PrinterID', Locked = true;
                    ToolTip = 'This is the Printer ID of the Printer this job should be printed to';
                    ApplicationArea = All;
                }
                field(PrinterName; Rec.PrinterName)
                {
                    Caption = 'PrinterName', Locked = true;
                    ToolTip = 'This is the Printer Name of the Printer this job should be printed to';
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    Caption = 'Enabled', Locked = true;
                    ToolTip = 'Is this printer enabled or not?';
                    ApplicationArea = All;
                }
                field(NewJobsOnHold; Rec.NewJobsOnHold)
                {
                    Caption = 'New Jobs on Hold', Locked = true;
                    ToolTip = 'Place new jobs on Hold';
                    ApplicationArea = All;
                }
                field(PrinterJsonPayload; Rec.PrinterJsonPayload)
                {
                    Caption = 'PrinterJsonPayload', Locked = true;
                    ToolTip = 'This is the JSON payload describing the Printer';
                    ApplicationArea = All;
                }
                field(AutoDeleteJobsOnHold; Rec.AutoDeleteJobsOnHold)
                {
                    ApplicationArea = All;
                    ToolTip = 'Jobs on Hold will be automatically deleted according to this date formula';
                }
                field(AutoDeleteJobsQueued; Rec.AutoDeleteJobsQueued)
                {
                    ApplicationArea = All;
                    ToolTip = 'Queued Jobs will be automatically deleted according to this date formula';
                }
                field(AutoDeleteJobsInError; Rec.AutoDeleteJobsInError)
                {
                    ApplicationArea = All;
                    ToolTip = 'Jobs in Error will be automatically deleted according to this date formula';
                }
                field(AutoDeleteJobsCancelled; Rec.AutoDeleteJobsCancelled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Cancelled Jobs will be automatically deleted according to this date formula';
                }
                field(AutoDeleteJobsPrinted; Rec.AutoDeleteJobsPrinted)
                {
                    ApplicationArea = All;
                    ToolTip = 'Printed Jobs will be automatically deleted according to this date formula';
                }

                field(NoOnHold; Rec.NoOnHold)
                {
                    Caption = 'No on Hold', Locked = true;
                    ToolTip = 'This is current no. of jobs on Hold';
                    ApplicationArea = All;
                }
                field(NoQueued; Rec.NoQueued)
                {
                    Caption = 'No Queued', Locked = true;
                    ToolTip = 'This is current no. of jobs Queued';
                    ApplicationArea = All;
                }
                field(NoInError; Rec.NoInError)
                {
                    Caption = 'No in Error', Locked = true;
                    ToolTip = 'This is current no. of jobs in Error';
                    ApplicationArea = All;
                }
                field(NoCancelled; Rec.NoCancelled)
                {
                    Caption = 'No Cancelled', Locked = true;
                    ToolTip = 'This is current no. of jobs Cancelled';
                    ApplicationArea = All;
                }
                field(NoPrinting; Rec.NoPrinting)
                {
                    Caption = 'No Printing', Locked = true;
                    ToolTip = 'This is current no. of jobs beeing Printed';
                    ApplicationArea = All;
                }
                field(NoPrinted; Rec.NoPrinted)
                {
                    Caption = 'No Printed', Locked = true;
                    ToolTip = 'This is current no. of jobs Printed';
                    ApplicationArea = All;
                }
                field(LatestUpdate; Rec.LatestUpdate)
                {
                    Caption = 'LatestUupdateFromPIPrintProcessor', Locked = true;
                    ToolTip = 'Latest update from PIPrint processor';
                    ApplicationArea = All;
                }
            }
        }
    }
}
