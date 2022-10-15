codeunit 90000 PIPrintManagement
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSetupPrinters', '', true, true)]
    local procedure ReportManagement_OnAfterSetupPrinters(var Printers: Dictionary of [Text[250], JsonObject])
    var
        PIPrintPrinter: Record PIPrintPrinter;
        PIPrintQueue: Record PIPrintQueue;
        JsonObject_: JsonObject;
    begin
        PIPrintPrinter.SetRange(Enabled, true);
        PIPrintPrinter.SetFilter(PrinterName, '<>%1', '');
        PIPrintPrinter.SetFilter(PrinterJsonPayload, '<>%1', '');
        if PIPrintPrinter.FindSet() then
            repeat
                Clear(JsonObject_);
                if JsonObject_.ReadFrom(PIPrintPrinter.PrinterJsonPayload) then
                    Printers.Add(PIPrintPrinter.PrinterName, JsonObject_);
            until PIPrintPrinter.Next() = 0;

        PIPrintQueue.AutoCleanUpJobs();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterDocumentPrintReady', '', true, true)]
    local procedure ReportManagement_OnAfterDocumentPrintReady(ObjectType: Option "Report","Page"; ObjectID: Integer;
                                                               ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    var
        PIPrintQueue: Record PIPrintQueue;
        OutStream_: OutStream;
    begin
        if Success then
            exit;

        if ObjectType <> ObjectType::Report then
            exit;

        PIPrintQueue.AutoCleanUpJobs();

        PIPrintQueue.Init();
        PIPrintQueue.Validate(PrinterRowNo, PrinterName2PrinterRowNo(JsonToken2Txt(ObjectPayload, 'printername')));
        PIPrintQueue.Validate(PrinterJobJsonPayload, JsonObject2Txt(ObjectPayload));
        PIPrintQueue.PDFPrintJob.CreateOutStream(OutStream_);
        if CopyStream(OutStream_, DocumentStream) then
            if (PIPrintQueue.PrinterRowNo <> 0) and (PIPrintQueue.PrinterJobJsonPayload <> '') then begin
                PIPrintQueue.Validate(Status, PIPrintQueue.Status::Queued);
                PIPrintQueue.Insert(true);
                Success := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Printer Setup", 'OnOpenPrinterSettings', '', false, false)]
    local procedure PrinterSetup_OnOpenPrinterSettings(PrinterID: Text; var IsHandled: Boolean)
    var
        PIPrintPrinter: Record PIPrintPrinter;
    begin
        PIPrintPrinter.SetRange(Enabled, true);
        PIPrintPrinter.SetRange(PrinterName, PrinterID);
        if PIPrintPrinter.FindFirst() then begin
            Page.Run(0, PIPrintPrinter);
            IsHandled := true;
        end;
    end;

    local procedure JsonObject2Txt(JsonObject_: JsonObject) ObjectPayloadAsText: Text
    begin
        JsonObject_.WriteTo(ObjectPayloadAsText);
    end;

    local procedure JsonToken2Txt(JsonObject_: JsonObject; Key_: Text): Text
    var
        JsonToken_: JsonToken;
    begin
        if Key_ = '' then
            exit('');
        if not JsonObject_.Get(Key_, JsonToken_) then
            exit('');
        exit(JsonToken_.AsValue().AsText());
    end;

    local procedure PrinterName2PrinterRowNo(PrinterName: Text): Integer
    var
        PIPrintPrinter: Record PIPrintPrinter;
    begin
        if PrinterName = '' then
            exit(0);
        PIPrintPrinter.SetRange(Enabled, true);
        PIPrintPrinter.SetRange(PrinterName, PrinterName);
        if PIPrintPrinter.FindFirst() then
            exit(PIPrintPrinter.RowNo);
        exit(0);
    end;
}
