# PIPrint - A Free Direct Printing Solution for your Microsoft Dynamics 365 Business Central

Hi, this is the first release of the implementation of an idea I've had for a while.
We need a fully free and expandable direct printing solution for Microsoft Dynamics 365 Business Central.

Unfortunately I don't have much time to develop this further, so consider it a working prototype for now. It is still a bit rough, but it will get you started. Feel free to improve and use it in both commercial and private installations. But please submit improvements back to this repository.
Due to limited time, I don't have much time to support this, but please follow my. blog post about it (https://www.dabbler.dk/?p=632) or write me an e-mail on gert@dabbler.dk

Solution is split into two part:
- App for Microsoft Dynamics 365 Business Central that allow the "Print processors" to register printers and fetch print jobs via ODataV4 webservices
- Print Processor for Windows/PowerShell - utilizing PDF-XChange Viewer which I've bundled (https://www.tracker-software.com/product/pdf-xchange-viewer)
- Print Processor for Linux/Python. Should be able to run more or less modified on everything supporting Python and CUPS (http://www.cups.org/). I've tested on Raspberry OS (https://www.raspberrypi.com/software/) and FreeBSD (https://www.freebsd.org/)

Features include:
- Yes, both Microsoft Dynamics 365 Business Central OnPrem and SaaS is supported
- Yes, both Basic Authentication and OAuth2 is supported
- Yes, this fully integrates with the Dynamics 365 Business Central printing subsystem - just like e-mail printing and/or (https://learn.microsoft.com/en-us/dynamics365/business-central/ui-specify-printer-selection-reports)
- Yes, you can setup a Raspberry PI and connect it to your Microsoft Dynamics 365 Business Central SaaS installation to handle Direct Printing  (https://www.raspberrypi.org/)
- Yes, this is really free

Ideas for further development:
- We don't have to request a new OAuth2 access key every time. We should cache it and only request a new one when it is about to expire
- Start/run PowerShell as a Windows Service
- Start/run Python as a Linux service
- More intuitive configuration of Print Processors
- Better installation instructions
- Install instructions for more platforms
- Improved printer capabilities reporting to Microsoft Dynamics 365 Business Central
- Maybe Print Processors using other scripting languages?
