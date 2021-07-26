// Project: Extract data from REDCap
// Created by: Luke Stevens
// Date created: 20th June 2017
// Adapted by: James Hedley
// Date adapted: 23rd July 2020
// Last updated: 25th September 2020


* Program to extract REDCap API token from a given text file
capture program drop redcap_get_token
program define redcap_get_token, rclass
	preserve
		import delimited "`1'", clear delimiter("") varnames(nonames)
		return local token=v1
	restore
end


* Program to format numeric variables (with specified format)
capture program drop redcap_numberformat
program define redcap_numberformat, rclass
	syntax anything(name=var), Format(string)
	if "`format'"=="date_dmy" {
		capture confirm numeric variable `var'
		if _rc {
			clonevar _str=`var'
			destring `var', replace force
			replace `var'=date(_str,"YMD")
			drop _str
		}
		format `var' %td
	}

	if "`format'"=="date_ymd" {
		capture confirm numeric variable `var'
		if _rc {
			clonevar _str=`var'
			destring `var', replace force
			replace `var'=date(_str,"YMD")
			drop _str
		}
		format `var' %td
	}
	
	if inlist("`format'","datetime_dmy","datetime_ymd") {
		capture confirm numeric variable `var'
		if _rc {
			clonevar _str=`var'
			destring `var', replace force
			recast double `var'
			replace `var'=clock(_str,"YMDhm")
			drop _str
		}
		format `var' %tc
	}
	
	if inlist("`format'","datetime_seconds_dmy","datetime_seconds_ymd") {
		capture confirm numeric variable `var'
		if _rc {
			clonevar _str=`var'
			destring `var', replace force
			recast double `var'
			replace `var'=clock(_str,"YMDhms")
			drop _str
		}
		format `var' %tc
	}			
	
	if inlist("`format'","time") {
		capture confirm numeric variable `var'
		if _rc {
			clonevar _str=`var'
			destring `var', replace force
			recast double `var'
			replace `var'=clock(_str,"hm")
			drop _str
		}
		format `var' %tcHH:MM
	}	
	
	if ///
		inlist("`format'","integer","number") | ///
		inlist("`format'","number_1dp","number_2dp","number_3dp","number_4dp", ///
			"number_0-1dp","number_0-2dp","number_0-3dp","number_0-4dp") {
		
		capture confirm numeric variable `var'
		if _rc {
			clonevar _str=`var'
			destring `var', replace force
			replace `var'=real(_str)
			drop _str
		}
	}
	
	if "`format'"=="text" {
		capture confirm numeric variable `var'
		if _rc {			
			count
			local rowcount=`r(N)'
			
			count if !missing(`var')
			local nonmissing_count=`r(N)' // don't format variables with no data as numeric
			
			local nonnumeric_chars=0
			
			local i=0
			if `nonmissing_count'!=0 {
				while `nonnumeric_chars'==0 & `i'<`rowcount' {
					local i=`i'+1
					local chars=`var'[`i']
					local chars=subinstr(`"`chars'"',".","",.) // decimal points
					local chars=subinstr(`"`chars'"',",","",.) // commas as thousands separator
					forvalues j=0/9 {
						local chars=subinstr(`"`chars'"',"`j'","",.)
					}
					if strlen(`"`chars'"')!=0 local nonnmeric_chars=1
				}
			}
			
			if `nonmissing_count'!=0 & `nonnumeric_chars'==0 capture destring `var', replace

		}		
	}

end



* Program to export data from a REDCap project
capture program drop redcap_export
program define redcap_export, rclass
	syntax , Token(string) [Dictionary CLear Save(string) Curl(string) URL(string) ///
		Reports(string) Forms(string) FIelds(string)]
		
	quietly {

		* Warn about overwriting existing dataset
		count
		local obs=`r(N)'
		
		ds
		local vars: word count `r(varlist)'
		
		if !(`obs'==0 & `vars'==0) & "`clear'"=="" {
			noisily display "This will overwrite existing data"
			noisily display "Specify the option 'clear' to confirm this is ok"
		}
		
		if !(!(`obs'==0 & `vars'==0) & "`clear'"=="") {
			
			
			* Extract token from file if required
			if strpos("`token'",".")!=0 {
				preserve
					import delimited "`token'", clear delimiter("") varnames(nonames)
					local token=v1
				restore
			}
			
			* Set default options
			if "`curl'"=="" local curl "C:\Windows\System32\curl.exe"
			if "`url'"=="" local url "https://redcap.mcri.edu.au/api/"
			tempfile datafile
			tempfile dictionaryfile
			
			
			* Progress update
			noisily display "Extracting data from REDCap..."
			
		
			* Extract all specified data (if data is required)
			** Prepare options for adding forms
			local formoptions ""
			foreach form in `forms' {
				local formoptions=`"`formoptions' --form forms[]="`form'""'
			}

			** Prepare options for adding fields
			local fieldoptions ""
			foreach field in `fields' {
				local fieldoptions=`"`fieldoptions' --form fields[]="`field'""'
			}
		
			** Prepare options for adding reports
			local reportoptions ""
			foreach report in `reports' {
				local reportoptions=`"`reportoptions' --form report_id="`report'""'
			}
					
					
			** Extract data
			if "`dictionary'"=="" {
				*** Extract data
				if "`reports'"=="" {
					shell "`curl'" ///
						--output "`datafile'" ///
						--form token="`token'" ///
						--form content=record ///
						--form format=csv ///
						--form type=flat ///
						`formoptions' ///
						`fieldoptions' ///
						"`url'"
				}
					
				if "`reports'"!="" {
					shell "`curl'" ///
						--output "`datafile'" ///
						--form token="`token'" ///
						--form content=report ///
						--form format=csv ///
						--form type=flat ///
						`reportoptions' ///
						"`url'"
				}	
				
			
				*** Extract data dictionary
				shell "`curl'" ///
					--output "`dictionaryfile'" ///
					--form token="`token'" ///
					--form content=metadata ///
					--form format=csv ///
					`formoptions' ///
					`fieldoptions' ///
					`reportoptions' ///
					"`url'"
			}
			
		
			** Extract dictionary only (if only the dictionary is required)
			if "`dictionary'"!="" {
				shell "`curl'" ///
					--output "`dictionaryfile'" ///
					--form token="`token'" ///
					--form content=metadata ///
					--form format=csv ///
					`formoptions' ///
					`fieldoptions' ///
					"`url'"
			}
			
	
			if "`dictionary'"=="" {
				* Extract value labels from data dictionary (if required)
				** Progress update
				noisily display "Preparing Stata formatting based on the data dictionary..."
				
				** Open data dictionary
				import delimited "`dictionaryfile'", clear delimiter(",") varnames(1) bindquotes(strict) maxquotedrows(unlimited) stringcols(_all)
				

				** Split value labels into separate variables
				split select_choices_or_calculations, gen(valuelabel) parse(" | ") trim
				local valuecount=`r(nvars)'
				forvalues i=1/`valuecount' {
					gen splitpos`i'=strpos(valuelabel`i',",")
					gen value_`i'=real(substr(valuelabel`i',1,splitpos`i'-1))
					gen label_`i'=substr(valuelabel`i',splitpos`i'+2,.)
				}
				drop splitpos* valuelabel*
				
				egen labelcount=rownonmiss(value_*)
			
				count
				local fieldcount=`r(N)'
				
				
				** Create the variable name that appears in Stata
				gen varname=field_name, after(field_name)
				
				expand labelcount if field_type=="checkbox"
				egen seq=seq(), by(field_name)
				
				gen value=.
				gen vallabel=""
				count
				forvalues i=1/`r(N)' {
					local seq=seq[`i']
					replace value=value_`seq' in `i'
					replace vallabel=label_`seq' in `i'
				}
				
				replace varname=field_name+"___"+string(value) if field_type=="checkbox"
				
				
				** Warning if there are more fields requested than Stata will allow
				count
				local varcount=`r(N)'
				local maxvarcount=`c(maxvar)'-2
				
				if `varcount'>`maxvarcount' {
					noisily display ""
					noisily display "ERROR:"
					noisily display "There are too many variables for this version of Stata"
					noisily display "Try specifying which forms, fields, or reports to extract"
					if `fieldcount' <=`maxvarcount' noisily display "Note: A single checkbox field in REDCap will appear as multiple variables in Stata"
					if `varcount'<=`c(maxvar)' noisily display "Note: In order to apply Stata formatting, you need space for 2 temporary variables to be created"
				}
				
				if `varcount'<=`maxvarcount' {				
					** Update Stata variable names to ensure they meet criteria (<=32 characters, no duplicates, etc.)
					preserve
						keep varname
						gen id=1
						gen seq=_n
						reshape wide varname, i(id) j(seq)
						
						set obs 2
						replace id=2 if id==.
						
						ds id, not
						foreach var in `r(varlist)' {
							local varname=`var'[1]
							local newname: permname `varname'
							rename `var' `newname'
							replace `newname'="`newname'" if id==2
						}
						
						local i=0
						ds id, not
						foreach var in `r(varlist)' {
							local i=`i'+1
							rename `var' var`i'
						}
						
						reshape long var@, i(id) j(seq)
						gsort +seq +id
						gen varname=var if id==1
						replace varname=varname[_n-1] if seq==seq[_n-1]
						gsort +seq -id
						gen newvarname=var if id==2
						replace newvarname=newvarname[_n-1] if seq==seq[_n-1]
						drop id seq var
						duplicates drop
						
						tempfile newvarnames
						save "`newvarnames'", replace
					restore
					merge 1:1 varname using "`newvarnames'", nogen
					replace varname=newvarname
					drop newvarname
				
					** Create a list of all variables in the data dictionary
					local dictionary_variables ""
					count
					forvalues i=1/`r(N)' {
						local varname=varname[`i']
						local dictionary_variables="`dictionary_variables' `varname'"
					}

					** Update values and labels for checkbox variables
					summ labelcount
					if `r(N)'!=0 {
						forvalues i=1/`r(max)' {
							if `i'==1 replace value_`i'=0 if field_type=="checkbox"
							if `i'==1 replace label_`i'="Unchecked" if field_type=="checkbox"
							
							if `i'==2 replace value_`i'=1 if field_type=="checkbox"
							if `i'==2 replace label_`i'="Checked" if field_type=="checkbox"
							
							if !inlist(`i',1,2) replace value_`i'=. if field_type=="checkbox"
							if !inlist(`i',1,2) replace label_`i'="" if field_type=="checkbox"
						}
					}

					
					** Update values and labels for yesno variables
					summ labelcount
					if `r(N)'!=0 {
						forvalues i=1/`r(max)' {
							if `i'==1 replace value_`i'=0 if field_type=="yesno"
							if `i'==1 replace label_`i'="No" if field_type=="yesno"
							
							if `i'==2 replace value_`i'=1 if field_type=="yesno"
							if `i'==2 replace label_`i'="Yes" if field_type=="yesno"
							
							if !inlist(`i',1,2) replace value_`i'=. if field_type=="yesno"
							if !inlist(`i',1,2) replace label_`i'="" if field_type=="yesno"
						}
					}
							
					** Keep only the variables that are in the extracted dataset (for reports only)
					if "`report'"!="" {
						preserve
							import delimited "`datafile'", clear delimiter(",") varnames(1) bindquotes(strict) maxquotedrows(unlimited) stringcols(_all)
							d, replace clear
							keep name
							rename name varname
							tempfile varlist
							save "`varlist'", replace
						restore
						merge 1:1 varname using "`varlist'", nogen keep(match)
					}
				
				
					** Create the commands to label variables
					gen variablelabel=field_label
					replace variablelabel=subinstr(variablelabel,`"""',"'",.)
					replace variablelabel=ustrregexra(variablelabel,"<.*?>","",.)
					replace variablelabel=variablelabel+" = "+vallabel if field_type=="checkbox"
							
					gen variablelabelcommand= ///
						"label variable " + ///
						varname + ///
						`" ""' + ///
						variablelabel + ///
						`"""'
						
					gen notescommand= ///
						"notes " + ///
						varname + ///
						`": ""' + ///
						variablelabel + ///
						`"""'
							
							
					** Create the commands to format numeric variables		
					gen redcap_numberformat=""
					replace redcap_numberformat=text_validation_type_or_show_sli if ///
						inlist(text_validation_type_or_show_sli, ///
							"date_dmy","date_ymd","datetime_dmy","datetime_ymd", ///
							"datetime_seconds_dmy","datetime_seconds_ymd","time")
					replace redcap_numberformat=text_validation_type_or_show_sli if ///	
							inlist(text_validation_type_or_show_sli, ///
							"integer","number")
					replace redcap_numberformat=text_validation_type_or_show_sli if ///	
							inlist(text_validation_type_or_show_sli, ///	
							"number_1dp","number_2dp","number_3dp","number_4dp", ///
							"number_0-1dp","number_0-2dp","number_0-3dp","number_0-4dp")
					replace redcap_numberformat="text" if redcap_numberformat=="" & !inlist(field_type,"notes","descriptive")

					gen formatcommand=""
					replace formatcommand="redcap_numberformat "+varname+", format("+redcap_numberformat+")" if ///
						redcap_numberformat!=""
						
					
					** Create the commands to add value labels
					gen valuelabelname=field_name
					replace valuelabelname="checkbox" if field_type=="checkbox"
					
					gen valuelabelcommands=""
					
					summ labelcount
					if `r(N)'!=0 {
						forvalues i=1/`r(max)' {
							replace valuelabelcommands= ///
								valuelabelcommands + ///
								" | " + ///
								"label define " + ///
								valuelabelname + ///
								" " + ///
								string(value_`i') + ///
								" " + ///
								`"""' + ///
								label_`i' + ///
								`"""' + ///
								", modify" ///
								if !missing(value_`i') | !missing(label_`i')
								
						}
					}
					replace valuelabelcommands= ///
						valuelabelcommands + ///
						" | label values " + ///
						varname + ///
						" " + ///
						valuelabelname
					replace valuelabelcommands=subinstr(valuelabelcommands," | ","",1)	
					replace valuelabelcommands="" if !inlist(field_type,"checkbox","dropdown","radio","yesno")

						
					** Create a dataset with all the formatting commands to be run
						*** Split formatting commands into individual variables
						keep variablelabelcommand notescommand valuelabelcommands formatcommand
						count
						if `r(N)'!=0 split valuelabelcommands, parse(" | ") gen(valuelabelcommand)
						drop valuelabelcommands
						
					
						*** Rename variables based on their order
						local i=0
						ds
						foreach var in `r(varlist)' {
							local i=`i'+1
							rename `var' var`i'
						}
						

						*** Expand the dataset to one row per command
						gen commandcount=.
						local i=0
						ds commandcount, not
						foreach var in `r(varlist)' {
							local i=`i'+1
							replace commandcount=`i' if !missing(`var')
						}
						gen rowid=_n
						expand commandcount
						egen seq=seq(), by(rowid)
						
						*** Create a variable for each unique command
						gen command=""
						count
						forvalues i=1/`r(N)' {
							local seq=seq[`i']
							replace command=var`seq' in `i'
						}
						
						*** Remove invisible characters from commands
						replace command=subinstr(command,char(9)," ",.)
						replace command=subinstr(command,char(10)," ",.)
						replace command=subinstr(command,"'Other'","Other",.)
						replace command=stritrim(command)
						
						*** Create separate lists of commands to run
						keep command
						drop if command==""
						count
						if `r(N)'!=0 duplicates drop
						
						
							**** Variable label commands
							preserve
								keep if strpos(command,"label variable")==1
								count 
								local varlabelcommandcount=`r(N)'
								forvalues i=1/`r(N)' {
									local varlabelcommand`i'=command[`i']
								}
							restore
							
							**** Notes commands
							preserve
								keep if strpos(command,"notes")==1
								count 
								local notescommandcount=`r(N)'
								forvalues i=1/`r(N)' {
									local notescommand`i'=command[`i']
								}
							restore
							
							**** Label definition commands
							preserve
								keep if strpos(command,"label define")==1
								count 
								local labeldefinecommandcount=`r(N)'
								forvalues i=1/`r(N)' {
									local labeldefinecommand`i'=command[`i']
								}
							restore
							
							**** Value label commands
							preserve
								keep if strpos(command,"label values")==1
								count 
								local valuelabelcommandcount=`r(N)'
								forvalues i=1/`r(N)' {
									local valuelabelcommand`i'=command[`i']
								}
							restore
							
							**** Number format commands
							preserve
								keep if strpos(command,"redcap_numberformat")==1
								count 
								local numberformatcommandcount=`r(N)'
								forvalues i=1/`r(N)' {
									local numberformatcommand`i'=command[`i']
								}
							restore


						
					* Progress update
					noisily display "Formatting data..."
				
					* Open the exported dataset
					import delimited "`datafile'", clear delimiter(",") varnames(1) bindquotes(strict) maxquotedrows(unlimited) stringcols(_all)
					

					* Apply formatting commands
					forvalues i=1/`varlabelcommandcount' {
						capture `varlabelcommand`i''
					}	
					forvalues i=1/`notescommandcount' {
						capture `notescommand`i''
					}	
					forvalues i=1/`numberformatcommandcount' {
						capture `numberformatcommand`i''
					}
					forvalues i=1/`labeldefinecommandcount' {
						capture `labeldefinecommand`i''
					}	
					forvalues i=1/`valuelabelcommandcount' {
						capture `valuelabelcommand`i''
					}	
					
					* Format any variables not included in the data dictionary
					ds
					foreach var in `r(varlist)' {
						local in_dictionary=0
						foreach dictvar in `dictionary_variables' {
							novarabbrev {
								if "`var'"=="`dictvar'" local in_dictionary=1
							}
						}
						
						if `in_dictionary'==0 {
							capture confirm numeric variable `var'
							if _rc {
								capture destring `var', replace
								if !_rc {
									label define `var' ///
										0 "Incomplete" ///
										1 "Unverified" ///
										2 "Complete" ///
										, replace
									if "`var'"!="id" label values `var' `var' // Ensure ID variable remains unlabelled
								}
							}
						}
					}
				}			
			} // end of check whether only dictionary is required
				
				
			* Open data dictionary if that is all that is needed
			if "`dictionary'"!="" {
				import delimited "`dictionaryfile'", clear delimiter(",") varnames(1) bindquotes(strict) maxquotedrows(unlimited) stringcols(_all)
			}
				
				
			* Save dataset
			compress		
			if "`save'"!="" {
				noisily display "Saving data..."	
				save "`save'", replace
			}
				
			
			* Progress update
			noisily display "Finished!"
		
		} // end of warning about existing data
	} // end of quietly statement
end



* Program to import data into a REDCap project
capture program drop redcap_import
program define redcap_import, rclass
	syntax , Token(string) [Dictionary Checked Curl(string) URL(string)]
		
	quietly {

		* Warn if data hasn't been checked
		if "`checked'"=="" {
			noisily display ""
			noisily display "**********************************************************************"
			noisily display "WARNING:"
			noisily display "Have you checked this data is correct before you upload it to REDCap?"
			noisily display "**********************************************************************"			
			noisily display ""
			noisily display as input "Type 'yes' to confirm, or anything else to cancel", _request(_response)
		}
		
		if "`checked'"=="" & "${_response}"!="yes" {
			noisily display ""
			noisily display "Cancelled. Please confirm data is correct and try again"
			noisily display "To avoid this step, specify the 'checked' option to confirm you have already checked your data"
			noisily display ""
		}
		
		if "`checked'"!="" | "${_response}"=="yes" {
			
			* Extract token from file if required
			if strpos("`token'",".")!=0 {
				preserve
					import delimited "`token'", clear delimiter("") varnames(nonames)
					local token=v1
				restore
			}
			
			* Set default options
			if "`curl'"=="" local curl "C:\Windows\System32\curl.exe"
			if "`url'"=="" local url "https://redcap.mcri.edu.au/api/"
			tempfile data

			
			* Save dataset as a CSV file
			noisily display "Converting dataset to CSV format..."
			
				** Convert date and date-time variables to YYYY-MM-DD format
				preserve
					d, replace clear
					keep if inlist(format,"%td")
					local datevars ""
					count
					forvalues i=1/`r(N)' {
						local var=name[`i']
						local datevars "`datevars' `var'"
					}
				restore
				
				preserve
					d, replace clear
					keep if inlist(format,"%tc")
					local datetimevars ""
					count
					forvalues i=1/`r(N)' {
						local var=name[`i']
						local datevars "`datevars' `var'"
					}
				restore
								
				** Temporarily export dataset with correctly formatted dates
				preserve
					novarabbrev {
						foreach var in `datevars' {
							format `var' %tdCCYY!-NN!-DD
						}
						foreach var in `datetimevars' {
							format `var' %tcCCYY!-NN!-DD_HH:MM:SS
						}		
					}
				
					export delimited "`data'.csv", delimiter(",") nolabel quote datafmt replace
				restore
			
			* Upload data to REDcap
			noisily display "Uploading data to REDCap..."
			
			if "`dictionary'"=="" {
				local command= ///
					"`curl'" + ///
					" --form token=`token'" + ///
					" --form content=record" + ///
					" --form format=csv" + ///
					" --form type=flat" + ///
					" --form data="+char(34)+"<`data'.csv"+char(34) + ///
					" `url'"
				
				shell `command'
			}
			
			if "`dictionary'"!="" {
				local command= ///
					"`curl'" + ///
					" --form token=`token'" + ///
					" --form content=metadata" + ///
					" --form format=csv" + ///
					" --form data="+char(34)+"<`data'.csv"+char(34) + ///
					" `url'"
				
				shell `command'
			}
			
			* Progress update
			noisily display "Finished!"
		}
	}
end













