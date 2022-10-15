pageextension 90000 PIPrintPrinterManagement extends "Printer Management"
{
    AdditionalSearchTerms = 'piprint';
    PromotedActionCategories = 'New,Process,Report,Manage,Email Print,Universal Print,PIPrint';

    actions
    {
        addlast(Creation)
        {
            action(PIPrintPrinters)
            {
                ApplicationArea = All;
                Caption = 'Maintain PIPrint Printers';
                Image = Print;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Category7;
                ToolTip = 'Maintain automatically registered PIPrint printers that are shared with your Business Central.';
                RunObject = page PIPrintPrinter;
            }
        }
        addlast(Navigation)
        {
            action(PIPrintQueues)
            {
                ApplicationArea = All;
                Caption = 'Maintain PIPrint Queues';
                Image = PrintDocument;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Category7;
                ToolTip = 'See and maintain the print queues of the installed PIPrint printers.';
                RunObject = page PIPrintQueue;
            }
            action(PIPrint)
            {
                ApplicationArea = All;
                Caption = 'PIPrint on GitHub';
                Image = Web;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Category7;
                ToolTip = 'Open the official PIPrint repository on GitHub.';

                trigger OnAction()
                var
                    PIPrintUrlLbl: Label 'https://github.com/DabblerDK/PIPrint', Locked = true;
                begin
                    Hyperlink(PIPrintUrlLbl);
                end;
            }
        }
    }
}