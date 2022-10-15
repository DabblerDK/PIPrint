### Python ###

# RASPBERRY OS:
# - Install Raspberry OS on your Raspberry (Raspberry PI Image Writer)
#   Note: Cups is already installed and root+pi have lpadmin group membership
#
# - Connect it to your network (wifi can be done as Advanced settings in Raspberry PI Image Writer), otherwise dhcp is fine as it will only perform outgoing calls
#   If you have a RPI2 with a USB WIFI dongle, see this: https://www.electronicshub.org/setup-wifi-raspberry-pi-2-using-usb-dongle/
#
# - Make sure your installation is up-to-date
#     sudo apt-get update
#     sudo apt-get upgrade
#     sudo apt dist-upgrade
#     # and maybe sudo rpi-update or sudo rpi-eeprom-update (if you have a RPI 4 or later)
#     sudo shutdown -r now
#   ...and maybe also (if requested by the upgrade)
#     sudo apt autoremove
#
# - Update trusted CA certificates (might be needed to connect to your BC)
#     sudo dpkg-reconfigure ca-certificates
#
# - Update python and modules
#     pip install --upgrade requests
#     pip install --upgrade certifi
#
# - Install lpr and grant permission to cups
#     sudo apt-get install cups-bsd
#
# - Configure CUPS (http://raspberrypiprint.local:631)
#
#
# FREEBSD:
# - Install cups, cups-filters, py-pycups from ports
#
# - Configure CUPS (can be re-done later if you add/remove printers)
#   Allow remote config
#     cupsctl --remote-admin --remote-any
#   ...and add this line below DefaultAuthType Basic in the /etc/cups/cupsd.conf
#     DefaultEncryption IfRequested
#   Go to http://<ip of your pi>:631
#   Follow the guides on how to add/maintain printers (note: you only have to add printers - you don't have to configure anything else unless you need it for something else).
#     Hint: For brother printers you can download the BRprint (postscript) driver for windows and get the PPD-file from that one...
#
#   You can test-print a pdf-file with the lp command. lpstat -a shows the installed printers.
#     lp basic-invoice.pdf -d Brother_DCP-9055CDN
#
# - Install, configure and run this PIPrintProcessor python script
#
#
# Note: This will probably work on everything running Python and CUPS!
#

import requests, json, base64, urllib3, datetime, cups, os
from urllib.parse import quote
from socket import gethostname
from warnings import resetwarnings
from time import sleep
from threading import Thread
from tempfile import mkstemp

### Configuration ###
# Authentication:
AUTHENTICATION = {
  "Company":                     "CRONUS Danmark A/S", # Note: Must exist or be left empty if a Default Company is setup in the Service Tier. Only used for authentication as printers and jobs are PerCompany=false

  # Basic Auth (comment out the OAuth2 lines below to use BasicAuth)
  #"BasicAuthLogin":              "Your login",
  #"BasicAuthPassword":           "Your password",

  # OAuth2
  "BasicAuthLogin":              "",
  "BasicAuthPassword":           "",
  "OAuth2CustomerAADIDOrDomain": "Your AADID or Domain",
  "OAuth2ClientID":              "Your OAuth2 Client ID",
  "OAuth2ClientSecret":          "Your OAuth2 Secret",

  "IgnoreCertificateErrors":     True
}
#

# URLs for webservices:
#BASEURL                 = "https://<hostname>/<Instance>/ODataV4/" # OnPrem example
BASEURL                 = "https://api.businesscentral.dynamics.com/v2.0/<Your AADID or Domain>/<"Production" or Your Sandbox name>/ODataV4/" # SaaS example
PRINTERSWS              = "PIPrintPrinterWS"
QUEUESWS                = "PIPrintQueueWS"

# Misc.:
IGNOREPRINTERS = [] #["My First Printer to Ignore","My Second Printer to Ignore"] # Don't offer these printers to Business Central
LP             = "/usr/bin/lpr" # "/usr/local/bin/lpr-cups"
DELAY          = 5 # Delay between checking for print jobs in seconds
UPDATEDELAY    = 300 # Delay between updating printers in seconds

### End of Configuration ###

#########################################################################################################
### YOU ARE NOT SUPPOSED TO CHANGE ANYTHING BEYOND THIS POINT UNLESS YOU WANT TO MODIFY FUNCTIONALITY ###
#########################################################################################################

def GetBasicAuthentication(Login, Password):
  value = Login + ":" + Password
  return base64.b64encode(value.encode('ascii')).decode('ascii')


def GetOAuth2AccessToken(ClientID, ClientSecret, CustomerAAD_ID_Or_Domain):
  Body = "client_id=" + quote(ClientID) + "&client_secret=" + quote(ClientSecret) + \
         "&scope=https://api.businesscentral.dynamics.com/.default&grant_type=client_credentials"
  try:
    Json = requests.post(url = "https://login.microsoftonline.com/" + CustomerAAD_ID_Or_Domain + "/oauth2/v2.0/token", headers = {"Content-Type":"application/x-www-form-urlencoded"}, data = Body).json()
  except requests.exceptions.RequestException as err:
    print ("Connect request OAuth2 Access Token:",err)
  else:
    return Json.get('access_token')


def CallBCWebService(Method, BaseURL, WebServiceName, Authentication, DirectLookup = "", Filter = "", ETag = "", Body = "", GetParametersOnly = False, IgnoreCertificateErrors = False):
  URL = BaseURL.rstrip("/")
  Headers = { "Accept":"application/json"}

  if Authentication["BasicAuthLogin"] and Authentication["BasicAuthPassword"]:
    Headers.update({"Authorization":"Basic "+GetBasicAuthentication(Authentication["BasicAuthLogin"], Authentication["BasicAuthPassword"])})
  else:
    Headers.update({"Authorization":"Bearer "+GetOAuth2AccessToken(Authentication["OAuth2ClientID"], Authentication["OAuth2ClientSecret"], Authentication["OAuth2CustomerAADIDOrDomain"])})

  if Method.casefold() == "get":
    Headers.update({"Data-Access-Intent":"ReadOnly"})

  if Body:
    Headers.update({"Content-Type":"application/json"})

  if ETag:
    Headers.update({"If-Match":ETag})

  if Authentication["Company"]:
    URL = URL + "/Company('" + Authentication["Company"] + "')"

  URL = URL + "/" + WebServiceName

  if DirectLookup:
    URL = URL + "(" + DirectLookup + ")"

  if Filter:
    URL = URL + "?$filter=" + Filter

  Parameters = {
    "url":URL,
    "headers":Headers
  }

  if Authentication["IgnoreCertificateErrors"]:
    Parameters.update({"verify":False})
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
  else:
    resetwarnings()

  if Body:
    Parameters.update({"data":Body})

  if GetParametersOnly:
    return Parameters
  else:
    try:
      if Method.casefold() == "get":
        Response = requests.get(**Parameters)
        Response.raise_for_status()
      elif Method.casefold() == "post":
        Response = requests.post(**Parameters)
        Response.raise_for_status()
      elif Method.casefold() == "patch":
        Response = requests.patch(**Parameters)
        Response.raise_for_status()
    except requests.exceptions.HTTPError as errh:
      print("Error calling BC web service: HTTP error",errh)
      print(Response.content)
      pass
    except requests.exceptions.RequestException as err:
      print("Error calling BC web service:",err)
      print(Response.content)
      pass
    else:
      return Response


def PrintJob(Job,Name):
  #Write the PDF to a TempFile
  TempFileDescriptor, TempFileName = mkstemp(suffix=".pipp.pdf")
  TempFile = os.fdopen(TempFileDescriptor, "xb")
  TempFile.write(base64.b64decode(Job["PDFPrintJobBASE64"]))
  TempFile.flush()
  TempFile.close()

  #Print the file
  PrintProcess = os.system(LP + ' -T "' + Name + '" -P "' + Job["PrinterID"] + '" -r ' + TempFileName)
  if PrintProcess == 0:
    CallBCWebService(Method = "Patch", BaseURL = BASEURL, WebServiceName = QUEUESWS, DirectLookup = str(Job["RowNo"]), ETag = Job["@odata.etag"], Authentication = AUTHENTICATION, \
                     Body = "{\"Status\":\"Printed\",\"PrinterMessage\":\"" + LP + " called successfully for printing\"}")
  else:
    CallBCWebService(Method = "Patch", BaseURL = BASEURL, WebServiceName = QUEUESWS, DirectLookup = str(Job["RowNo"]), ETag = Job["@odata.etag"], Authentication = AUTHENTICATION, \
                     Body = "{\"Status\":\"Error\",\"PrinterMessage\":\"" + LP + " called for printing, but returned error code " + str(PrintProcess) + "\"}")

###


#House keeping
LastPrinterUpdate = datetime.datetime.now() - datetime.timedelta(seconds=UPDATEDELAY)

while True:
  #Connect to CUPS
  CupsConnection = cups.Connection()

  #Fetch printers on this host from BC
  BCPrinters = CallBCWebService(Method = "Get", BaseURL = BASEURL, WebServiceName = PRINTERSWS, Filter = "HostID eq '" + gethostname() + "'", Authentication = AUTHENTICATION).json().get("value")

  #Register new printers in BC
  for Printer in CupsConnection.getPrinters():
    if not Printer in IGNOREPRINTERS:
      if (not BCPrinters) or not [x for x in BCPrinters if x["PrinterID"] == Printer][0]:
        print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "Adding new printer in BC:", Printer)
        CallBCWebService(Method = "Post", BaseURL = BASEURL, WebServiceName = PRINTERSWS, Authentication = AUTHENTICATION, \
                         Body = "{\"HostID\":\"" + gethostname() + "\",\"PrinterID\":\"" + Printer + "\"}")

  #Update existing printers in BC
  if (datetime.datetime.now() - LastPrinterUpdate).total_seconds() > UPDATEDELAY:
    if BCPrinters:
      for Printer in CupsConnection.getPrinters():
        if not Printer in IGNOREPRINTERS:
          BCPrinter = [x for x in BCPrinters if x["PrinterID"] == Printer][0]
          if BCPrinter:
            print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "Updating printer in BC (RowNo: " + str(BCPrinter["RowNo"]) + "):", Printer)
            CallBCWebService(Method = "Patch", BaseURL = BASEURL, WebServiceName = PRINTERSWS, DirectLookup = str(BCPrinter["RowNo"]), ETag = BCPrinter["@odata.etag"], Authentication = AUTHENTICATION, \
                           Body = "{\"HostID\":\"" + gethostname() + "\",\"PrinterID\":\"" + Printer + "\"}")
      LastPrinterUpdate = datetime.datetime.now()
    print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "Looking for print jobs every", DELAY, "seconds, updating printers every", UPDATEDELAY, "seconds...")

  #Print the queued jobs for the printers on this host
  if sum(d['NoQueued'] for d in BCPrinters if d) > 0:
    for Job in CallBCWebService(Method = "Get", BaseURL = BASEURL, WebServiceName = QUEUESWS, Filter = "HostID eq '" + gethostname() + "' and Status eq 'Queued'", Authentication = AUTHENTICATION).json().get("value"):
      Job = CallBCWebService(Method = "Patch", BaseURL = BASEURL, WebServiceName = QUEUESWS, DirectLookup = str(Job["RowNo"]), ETag = Job["@odata.etag"], Authentication = AUTHENTICATION, \
                             Body = "{\"Status\":\"Printing\"}").json()
      print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "Printing job (RowNo: " + str(Job["RowNo"]) + ") on printer " + Job["PrinterID"] + "...")
      Name = os.path.basename(__file__) + " printing job (RowNo: " + str(Job["RowNo"]) + ") on printer " + Job["PrinterID"]
      Thread(target = PrintJob, name = Name, args=(Job,Name)).start()
    print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "Looking for print jobs every", DELAY, "seconds, updating printers every", UPDATEDELAY, "seconds...")

  sleep(DELAY)
