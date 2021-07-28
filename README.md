# redcap
Stata commands to import data from REDCap and export data to REDCap using the REDCap API. Will only work in Windows, and requires curl.

There are three ways to install this package:
  1. Install within Stata using -net install
  
    net install redcap, from("https://raw.githubusercontent.com/james-hedley/redcap/main/")
  
  2. Download the .ado and .sthlp files, and save them in your personal ADO folder. You can find where your personal ADO folder is located by typing -sysdir- in Stata
 
  3. Manually install within Stata (if -net install- fails). To install the command and then view the help file type:
    
    do "https://raw.githubusercontent.com/james-hedley/redcap/main/redcap.do"
    
    type "https://raw.githubusercontent.com/james-hedley/redcap/main/redcap.sthlp"
