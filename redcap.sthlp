{smcl}
{cmd:help redcap}
{hline}

{title:Title}

{p2col :{hi:redcap} {hline 2}}Commands to export and import datasets directly from REDCap (using cURL){p_end}


{title:Syntax}

{phang}{cmd:redcap_get_token} {it:token_filename}

{phang}{cmd:redcap_numberformat} {it:varname}, {opt f:ormat(redcap_format)}

{phang}{cmd:redcap_export}, {opt t:oken(string)} [{opt d:ictionary} {opt cl:ear} {opt s:ave(string)} {opt c:url(string)} {opt url(string)} {opt r:eports(string)} {opt f:orms(string)} {opt fi:elds(string)}]
  
{phang}{cmd:redcap_import}, {opt t:oken(string)} [{opt d:ictionary} {opt c:hecked} {opt c:url(string)} {opt url(string)}]


{title:Description}

{phang}{cmd:redcap_get_token} extracts a REDCap API token from a text file. The text file should contain only the API token, with no heading

{phang}{cmd:redcap_numberformat} formats a variable based on a specified REDCap format. See Options below for more details

{phang}{cmd:redcap_export} extracts data from REDCapusing cURL. The data will then be formatted for Stata, based on information taken from the REDCap data dictionary

{phang}{cmd:redcap_import} uploads the current dataset to REDCap. NOTE: Please make sure you have confirmed your data is correct before uploading


{title:Options}

{phang}{it:token_filename} is the filename of a text file ".txt" containing your REDCap API token only, with no headings, formatting, or any other data. Note that your REDCap API token is unique to you, do not share this with anyone. As a security measure, this command allows you to read in your API token from a text file (ideally saved on your local desktop), so you can share you Stata do-file without sharing your REDCap API token. 

{phang}{it:redcap_format} is a string containg a REDCap variable format (as it appears in the data dictionary). You can use:
	date_dmy, date_ymd, datetime_dmy, datetime_ymd, datetime_seconds_dmy, datetime_seconds_ymd, time, integer, number, 
	number_1dp, number_2dp, number_3dp, number_4dp, number_0-1dp, number_0-2dp, number_0-3dp, number_0-4dp

{phang}{opt token(string)} is your REDCap API token, either as the filename of the textfile where it is saved e.g. token("token_filename.txt"), or typed in directly e.g. token("ABCD123")

{phang}{opt dictionary} if you want to export/import the data dictionary rather than data

{phang}{opt clear} if you want to clear the currently loaded dataset

{phang}{opt save(string)} is the filename where you want to save the extracted REDCap dataset

{phang}{opt curl(string)} is the location of the cURL application on your machine. The default is where it is pre-installed by default on Windows 10 "C:\Windows\System32\curl.exe". cURL can be downloaded here: https://curl.haxx.se/download.html

{phang}{opt url(string)} is the URL for your institutions REDCap. The default is for MCRI "https://redcap.mcri.edu.au/api/"

{phang}{opt reports(string)} the name of the report from your REDCap project that you want to download. If no reports/forms/fields are specified, then all data will be exported

{phang}{opt forms(string)} the name of the froms from your REDCap project that you want to download. If no reports/forms/fields are specified, then all data will be exported

{phang}{opt fields(string)} the name of the fields from your REDCap project that you want to download. If no reports/forms/fields are specified, then all data will be exported

{phang}{opt checked} is to confirm that you have checked your data, and are sure that you want to upload it to REDCap. If you don't specify this option, you will be prompted to confrim you have checked your data before proceeding


{title:Examples}
Imagine your REDCap API token is saved in a text file called "redcap_api_token.txt"

If you want to look at the data dictionary:
	redcap_export, token("redcap_api_token.txt") dictionary
	
You can then export the data from your REDCap project:
	redcap_export, token("redcap_api_token.txt")
	
You might then make a small change to the data, e.g. changing a study participant's date of birth
	
You could then upload the dataset in memory to REDCap
	redcap_import, token("redcap_api_token.txt")
	type "yes" and press enter to confirm you have checked your data before uploading
	

{title:Author}

{pstd}James Hedley{p_end}
{pstd}Murdoch Children's Research Institute{p_end}
{pstd}Melbourne, VIC, Australia{p_end}
{pstd}{browse "mailto:james.hedley@mcri.edu.au":james.hedley@mcri.edu.au}

{pstd}Adapted from REDCap-API-and-Stata by Luke Stevens{p_end}
{pstd}Murdoch Children's Research Institute{p_end}
{pstd}Melbourne, VIC, Australia{p_end}
