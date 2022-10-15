enum 90000 PIPrintJobState
{
    value(0; Hold)
    {
        Caption = 'OnHold';
    }
    value(10; Queued)
    {
        Caption = 'Queued';
    }
    value(20; Error)
    {
        Caption = 'Error';
    }
    value(30; Cancelled)
    {
        Caption = 'Cancelled';
    }
    value(40; Printing)
    {
        Caption = 'Printing';
    }
    value(50; Printed)
    {
        Caption = 'Printed';
    }
}
