table 90001 PIPrintQueue
{
    Caption = 'PIPrint Queue';
    DataClassification = SystemMetadata;
    LookupPageId = PIPrintQueue;
    DrillDownPageId = PIPrintQueue;
    DataPerCompany = false;

    fields
    {
        field(1; RowNo; Integer)
        {
            Caption = 'RowNo';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
            NotBlank = true;
            Editable = false;
        }
        field(2; PrinterRowNo; Integer)
        {
            Caption = 'Printer Row No';
            DataClassification = SystemMetadata;
            NotBlank = true;
            Editable = false;
            TableRelation = PIPrintPrinter.RowNo;
        }
        field(3; HostID; Text[250])
        {
            Caption = 'Host ID';
            FieldClass = FlowField;
            CalcFormula = lookup(PIPrintPrinter.HostID where(RowNo = field(PrinterRowNo)));
            Editable = false;
        }

        field(4; PrinterID; Text[250])
        {
            Caption = 'Printer ID';
            FieldClass = FlowField;
            CalcFormula = lookup(PIPrintPrinter.PrinterID where(RowNo = field(PrinterRowNo)));
            Editable = false;
        }
        field(5; PrinterName; Text[250])
        {
            Caption = 'Printer Name';
            FieldClass = FlowField;
            CalcFormula = lookup(PIPrintPrinter.PrinterName where(RowNo = field(PrinterRowNo)));
            Editable = false;
        }
        field(6; PrinterJobJsonPayload; Text[2048])
        {
            Caption = 'Print Job Json Payload';
            DataClassification = SystemMetadata;
            NotBlank = true;
            Editable = false;
        }
        field(7; PDFPrintJob; Blob)
        {
            Caption = 'Print Job (PDF)';
            DataClassification = SystemMetadata;
        }
        field(8; Status; Enum PIPrintJobState)
        {
            Caption = 'Job State';
            DataClassification = SystemMetadata;
            InitValue = Queued;

            trigger OnValidate()
            begin
                if Rec.Status <> xRec.Status then
                    if Rec.Status = Rec.Status::Printed then
                        Rec.Validate(Printed, CurrentDateTime())
                    else
                        Rec.Validate(Printed, 0DT);
            end;
        }
        field(9; PrinterMessage; Text[2048])
        {
            Caption = 'Printer Message';
            DataClassification = SystemMetadata;
        }
        field(10; Printed; DateTime)
        {
            Caption = 'Printed Date and Time';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; RowNo)
        {
            Clustered = true;
        }
        key(Printer; PrinterRowNo)
        {
        }
    }

    trigger OnInsert()
    var
        PIPrintPrinter: Record PIPrintPrinter;
    begin
        if PIPrintPrinter.Get(PrinterRowNo) then
            if PIPrintPrinter.NewJobsOnHold then
                Rec.Status := Rec.Status::Hold;
    end;


    procedure AutoCleanUpJobs()
    var
        PIPrintPrinter: Record PIPrintPrinter;
    begin
        if PIPrintPrinter.FindSet() then
            repeat
                CleanUpJobs(PIPrintPrinter.RowNo, Enum::PIPrintJobState::Hold, PIPrintPrinter.AutoDeleteJobsOnHold);
                CleanUpJobs(PIPrintPrinter.RowNo, Enum::PIPrintJobState::Queued, PIPrintPrinter.AutoDeleteJobsQueued);
                CleanUpJobs(PIPrintPrinter.RowNo, Enum::PIPrintJobState::Error, PIPrintPrinter.AutoDeleteJobsInError);
                CleanUpJobs(PIPrintPrinter.RowNo, Enum::PIPrintJobState::Cancelled, PIPrintPrinter.AutoDeleteJobsCancelled);
                CleanUpJobs(PIPrintPrinter.RowNo, Enum::PIPrintJobState::Printing, PIPrintPrinter.AutoDeleteJobsPrinting);
                CleanUpJobs(PIPrintPrinter.RowNo, Enum::PIPrintJobState::Printed, PIPrintPrinter.AutoDeleteJobsPrinted);
            until PIPrintPrinter.Next() = 0;
    end;

    local procedure CleanUpJobs(PrinterRowNo: Integer; PIPrintJobState: Enum PIPrintJobState; DateFormula_: DateFormula)
    var
        PIPrintQueue: Record PIPrintQueue;
        EmptyDateFormula: DateFormula;
    begin
        if DateFormula_ = EmptyDateFormula then
            exit;

        if CalcDate(DateFormula_) >= Today() then
            exit;

        PIPrintQueue.SetRange(PrinterRowNo, PrinterRowNo);
        PIPrintQueue.SetRange(Status, PIPrintJobState);
        PIPrintQueue.SetFilter(SystemCreatedAt, '<=%1', CreateDateTime(CalcDate(DateFormula_), Time()));
        PIPrintQueue.DeleteAll(true);
    end;
}
