page 90001 PIPrintPrinter
{
    Caption = 'PIPrint Printers';
    PageType = List;
    SourceTable = PIPrintPrinter;
    UsageCategory = None;
    SourceTableView = sorting(HostID, PrinterID);

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
                field(PrinterName; Rec.PrinterName)
                {
                    ApplicationArea = All;
                    ToolTip = 'This is the Printer Name of the Printer this job should be printed to';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Is this printer enabled or not?';
                }
                field(NewJobsOnHold; Rec.NewJobsOnHold)
                {
                    ToolTip = 'Place new jobs on Hold';
                    ApplicationArea = All;
                }
                field(HostID; Rec.HostID)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'This is the Host ID handling printing to the Printer this job should be printed to';
                }
                field(PrinterID; Rec.PrinterID)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'This is the Printer ID of the Printer this job should be printed to';
                }
                field(PrinterJsonPayload; Rec.PrinterJsonPayload)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'This is the JSON payload describing the Printer';
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
                field(NoQueued; Rec.NoQueued)
                {
                    ToolTip = 'This is current no. of jobs Queued';
                    ApplicationArea = All;
                }
                field(NoOnHold; Rec.NoOnHold)
                {
                    ToolTip = 'This is current no. of jobs on Hold';
                    ApplicationArea = All;
                }
                field(NoPrinting; Rec.NoPrinting)
                {
                    ToolTip = 'This is current no. of jobs beeing Printed';
                    ApplicationArea = All;
                }
                field(NoInError; Rec.NoInError)
                {
                    ToolTip = 'This is current no. of jobs in Error';
                    ApplicationArea = All;
                }
                field(NoCancelled; Rec.NoCancelled)
                {
                    Visible = false;
                    ToolTip = 'This is current no. of jobs Cancelled';
                    ApplicationArea = All;
                }
                field(NoPrinted; Rec.NoPrinted)
                {
                    Visible = false;
                    ToolTip = 'This is current no. of jobs Printed';
                    ApplicationArea = All;
                }
                field(LatestUpdate; Rec.LatestUpdate)
                {
                    Caption = 'Latest update';
                    ToolTip = 'Latest update from PIPrint processor';
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(PrinterManagement)
            {
                ApplicationArea = All;
                Caption = 'Printer Management';
                ToolTip = 'Open the Printer Management page';
                Image = Print;
                RunObject = Page "Printer Management";
            }
            action(Queue)
            {
                ApplicationArea = All;
                Caption = 'Printer Queue';
                ToolTip = 'Open the Printer Queue page for this printer';
                Image = Line;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page PIPrintQueue;
                RunPageLink = PrinterRowNo = field(RowNo);
            }
        }
    }
}
