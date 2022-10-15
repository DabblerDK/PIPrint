table 90000 PIPrintPrinter
{
    Caption = 'PIPrint Printer';
    DataClassification = SystemMetadata;
    LookupPageId = PIPrintPrinter;
    DrillDownPageId = PIPrintPrinter;
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
        field(2; HostID; Text[250])
        {
            Caption = 'Host ID';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(3; PrinterID; Text[250])
        {
            Caption = 'Printer ID';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(4; PrinterName; Text[250])
        {
            Caption = 'Printer Name';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(5; PrinterJsonPayload; Text[2048])
        {
            Caption = 'Printer Json Payload';
            DataClassification = SystemMetadata;
            NotBlank = true;

            trigger OnValidate()
            var
                JsonObject_: JsonObject;
                JsonParseErr: Label 'The provided PrinterJsonPayload could not be parsed';
            begin
                if PrinterJsonPayload = '' then
                    exit;
                if not JsonObject_.ReadFrom(PrinterJsonPayload) then
                    Error(JsonParseErr);
            end;
        }
        field(6; Enabled; Boolean)
        {
            Caption = 'Printer Enabled';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(7; NoOnHold; Integer)
        {
            Caption = 'No. of jobs on Hold';
            FieldClass = FlowField;
            CalcFormula = count(PIPrintQueue where(PrinterRowNo = field(RowNo), Status = const(Hold)));
            Editable = false;
        }
        field(8; NoQueued; Integer)
        {
            Caption = 'No. of jobs Queued';
            FieldClass = FlowField;
            CalcFormula = count(PIPrintQueue where(PrinterRowNo = field(RowNo), Status = const(Queued)));
            Editable = false;
        }
        field(9; NoInError; Integer)
        {
            Caption = 'No. of jobs in Error';
            FieldClass = FlowField;
            CalcFormula = count(PIPrintQueue where(PrinterRowNo = field(RowNo), Status = const(Error)));
            Editable = false;
        }
        field(10; NoCancelled; Integer)
        {
            Caption = 'No. of jobs Cancelled';
            FieldClass = FlowField;
            CalcFormula = count(PIPrintQueue where(PrinterRowNo = field(RowNo), Status = const(Cancelled)));
            Editable = false;
        }
        field(11; NoPrinted; Integer)
        {
            Caption = 'No. of jobs Printed';
            FieldClass = FlowField;
            CalcFormula = count(PIPrintQueue where(PrinterRowNo = field(RowNo), Status = const(Printed)));
            Editable = false;
        }
        field(12; NewJobsOnHold; Boolean)
        {
            Caption = 'New jobs on Hold';
            DataClassification = SystemMetadata;
        }
        field(13; LatestUpdate; DateTime)
        {
            Caption = 'Updated';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(14; AutoDeleteJobsOnHold; DateFormula)
        {
            Caption = 'Auto deleted jobs on Hold';
            DataClassification = SystemMetadata;
            InitValue = '<-1W>';

            trigger OnValidate()
            begin
                ValidateDateFormula(AutoDeleteJobsOnHold);
            end;
        }
        field(15; AutoDeleteJobsQueued; DateFormula)
        {
            Caption = 'Auto deleted jobs Queued';
            DataClassification = SystemMetadata;
            InitValue = '<-1M>';

            trigger OnValidate()
            begin
                ValidateDateFormula(AutoDeleteJobsQueued);
            end;
        }
        field(16; AutoDeleteJobsInError; DateFormula)
        {
            Caption = 'Auto deleted jobs in Error';
            DataClassification = SystemMetadata;
            InitValue = '<-1W>';

            trigger OnValidate()
            begin
                ValidateDateFormula(AutoDeleteJobsInError);
            end;
        }
        field(17; AutoDeleteJobsCancelled; DateFormula)
        {
            Caption = 'Auto deleted jobs Cancelled';
            DataClassification = SystemMetadata;
            InitValue = '<-1D>';

            trigger OnValidate()
            begin
                ValidateDateFormula(AutoDeleteJobsCancelled);
            end;
        }
        field(18; AutoDeleteJobsPrinted; DateFormula)
        {
            Caption = 'Auto deleted jobs Printed';
            DataClassification = SystemMetadata;
            InitValue = '<-1D>';

            trigger OnValidate()
            begin
                ValidateDateFormula(AutoDeleteJobsPrinted);
            end;
        }
        field(19; NoPrinting; Integer)
        {
            Caption = 'No. of jobs Printing';
            FieldClass = FlowField;
            CalcFormula = count(PIPrintQueue where(PrinterRowNo = field(RowNo), Status = const(Printing)));
            Editable = false;
        }
        field(20; AutoDeleteJobsPrinting; DateFormula)
        {
            Caption = 'Auto deleted jobs Printing';
            DataClassification = SystemMetadata;
            InitValue = '<-1D>';

            trigger OnValidate()
            begin
                ValidateDateFormula(AutoDeleteJobsPrinting);
            end;
        }

    }
    keys
    {
        key(PK; RowNo)
        {
            Clustered = true;
        }
        key(SortOrder; HostID, PrinterID)
        {
            Unique = true;
        }
    }

    local procedure ValidateDateFormula(DateFormula_: DateFormula)
    var
        MustBeInThePastErr: Label 'The DateFormula must calculate a date in the past, not in the future!';
    begin
        if CalcDate(DateFormula_) >= Today() then
            Error(MustBeInThePastErr);
    end;

    local procedure ValidatePrinterJsonPayload()
    var
        PrinterJsonPayloadLbl: Label '{"version":1,"description":"%1","duplex":false,"color":true,"defaultcopies":1,"papertrays":[{"papersourcekind":"AutomaticFeed","paperkind":"A4","units":"mm","height":297,"width":210,"landscape":false}]}',
                               Locked = true, Comment = '%1 is the PIPrint Printer Name or ID';
    begin
        if Rec.PrinterJsonPayload <> '' then
            exit;

        if (Rec.PrinterName = '') and (Rec.PrinterID = '') then
            exit;

        if Rec.PrinterName <> '' then
            Rec.Validate(PrinterJsonPayload, StrSubstNo(PrinterJsonPayloadLbl, Rec.PrinterName))
        else
            Rec.Validate(PrinterJsonPayload, StrSubstNo(PrinterJsonPayloadLbl, Rec.PrinterID))
    end;

    local procedure ValidatePrinterName()
    var
        Counter: Integer;
        PrinterNameLbl: Label '%1@%2', Locked = true,
                        Comment = '%1 is the PIPrint Printer Name or ID, %2 is the PIPrint Host ID';
        PrinterName2Lbl: Label '%1@%2-%3', Locked = true,
                         Comment = '%1 is the PIPrint Printer Name or ID, %2 is the PIPrint Host ID, %3 is a number';
    begin
        if PrinterName <> '' then
            exit;

        if (PrinterID = '') or (HostID = '') then
            exit;

        PrinterName := StrSubstNo(PrinterNameLbl, PrinterID, HostID);
        if not PrinterNameExists(PrinterName) then
            exit;

        repeat
            Counter += 1;
            PrinterName := StrSubstNo(PrinterName2Lbl, PrinterID, HostID, Counter);
        until not PrinterNameExists(PrinterName);
    end;

    local procedure PrinterNameExists(CheckPrinterName: Text): Boolean
    var
        PIPrintPrinter: Record PIPrintPrinter;
    begin
        PIPrintPrinter.SetRange(PrinterName, CheckPrinterName);
        exit(not PIPrintPrinter.IsEmpty());
    end;

    trigger OnInsert()
    begin
        ValidatePrinterName();
        ValidatePrinterJsonPayload();
        Rec.LatestUpdate := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        ValidatePrinterName();
        ValidatePrinterJsonPayload();
        Rec.LatestUpdate := CurrentDateTime();
    end;

    trigger OnDelete()
    var
        PIPrintQueue: Record PIPrintQueue;
    begin
        PIPrintQueue.SetRange(PrinterRowNo, RowNo);
        PIPrintQueue.DeleteAll(true);
    end;
}
