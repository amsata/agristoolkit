
cap program drop consistencyCheck
program define consistencyCheck
		
	syntax [varlist(default=none)] , PARAMeter(string) VARiable(string asis) ///
	[hiergeovars(string asis) MARGINLABels(string asis) conditionals(string asis) svySE(string) ///
	subpop(string asis) setcluster(int 0)]
	
	* TO DO
		* take into account subpo
		* take into account vctype is svy
		*take into account conditionals
		*order the different check 
		
		
	local n_geovar: list sizeof hiergeovars
	local n_varlist: list sizeof varlist
	local n_geovarmarginlab: list sizeof geovarmarginlab
	
	*verifier que les dimensions sont des variables labéliser
	*TO DO list
	
	
		qui svyset 
		if("`r(wvar)'"=="" & "`weight1'"!="") {
		di as smcl as err "To use the command genmdt, the survey design has to be declared"
		exit 498
		}
		local pweight `r(wvar)'


	if(`n_geovarmarginlab'!=0 & `n_geovarmarginlab'>1) {
		display as error "The options geovarmarginlab should have on element!"
		exit 498
	}
	
	if (`n_geovar'==1) {
		display as error "geovar should contain at least 2 hierarchical geographic variable!"
		exit 498
	}

	foreach v of local hiergeovars {
		local pos: list posof "`v'" in varlist
		if (`n_geovar'!=0 & `pos'>0) {
			display as error "The variable `v' should be excluded from varlist"
			exit 498
		}
	}
	
	*Control existence of duplicated variable
	local dup_var: list dups variable
	local size_dup_var: list sizeof dup_var
	if (`size_dup_var'>0) {
		display as error "The variable {cmd: `dup_var'} are duplicated in {cmd: `variable'}"
		exit 498 // or any error code you want to return
	}

	* control if a variable exist
	if "`parameter'"!="ratio" {
		foreach v of local variable {
			cap confirm variable `v', exact
				if _rc {
					display as error "variable `v' not found in the data"
					exit 498
					}
		}
	}
	*control if dimension variables are labelled
	if "`varlist'"!="" {
		foreach v of local varlist {
			local lbl: value label `v'
			if "`lbl'" == "" {
				display as error "The dimension variable `v' should be labbelled."
				exit 498
			} 
		}
	}

	if "`hiergeovars'"!="" {
		foreach v of local hiergeovars {
			local lbl: value label `v'
			if "`lbl'" == "" {
				display as error "The dimension variable `v' should be labbelled."
				exit 498
			} 
		}
	}

	****************************************************************************
	********************* Checking dependancies*********************************
	****************************************************************************
	cap which elabel
	if _rc {
		di as error "Error: The elabel package is required. Please install it by running: ssc install elabel"
		exit 1
	}

	cap which tuples
	if _rc {
		di as error "Error: The tuples package is required. Please install it by running: ssc install tuples"
		exit 1
	}
	
	cap which parallel
	if _rc {
		di as error "Error:The parallel package is required. Please install it by running: net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace"
		exit 1
	}
		
	********************************************************
	*** Control that there is no duplication of variable ***
	********************************************************
	local dup_var: list dups variable
	local size_dup_var: list sizeof dup_var
	if (`size_dup_var'>0) {
		display as error "Error: There are duplicated variables in the option variable(`variable')"
		exit 498 // or any error code you want to return
	}
	***************************************************
	*** Check consistency in the number of elements ***
	***************************************************
	local n_varlist: list sizeof varlist
	local n_marginlabels: list sizeof marginlabels
	local n_variable: list sizeof variable
	local n_geovar: list sizeof hiergeovars

*Checking in margin labels are correctly specified
		if (`n_marginlabels'!=0) {
			foreach ind of local marginlabels {
				local pos=strpos("`ind'", "@")
				if `pos'>0 {
					local varname=substr("`ind'", 1, strpos("`ind'", "@") - 1)
					*verifier si la variable est dans la list des dimensions
					local pos_var=strpos("`varlist'","`varname'")
					if `pos'==1 {
						display as error "error in '{cmd:`ind'}': Please put the dimension variable name before {cmd:@}" _newline 
						display as error "The margin labels  should be specified as followed: {cmd: 'dimensionVariable@margin label'} "
						exit 480
					}
					else if `pos_var'==0 {
						display as error "Eerror in '{cmd:`ind'}': {cmd: `varname'} is not a valid dimension variable name in {cmd: `varlist'}" _newline 
						display as error "The margin labels  should be specified as followed: {cmd: 'DimensionVariable@margin label'} "
						exit 480
					}
				}
				else {		
					display as error "Eerror in '{cmd:`ind'}': '{cmd: @}' is missing in the margin label  specification" _newline 
						display as error "The margin labels  should be specified as followed: {cmd: 'DimensionVariable@margin label'} "
					exit 480
				}
			}			
		}
		
		
	**********************************************************			
	*** Checking if there are missing values in dimensions ***
	**********************************************************
	foreach v of local varlist {
		count if missing(`v')
		return list
		if (`r(N)'>0) {
			display as error "Error: The dimension `v' should not contain missing values"
			exit 498 // or any error code you want to return
		}
	}
	
	local n_par: list sizeof parameter
	local par "total mean ratio median"
	local input_in_par: list posof `"`parameter'"' in par
	
	if (`n_par'!=1 | `input_in_par'==0) {
		display as error "Error: argument 'parameter(`parameter')' must be either 'parameter(total)', 'parameter(mean)' or 'parameter(ratio)'"
		exit 498 // or any error code you want to return
	}

	*******************************************************
	*** if ratio, check if the specification if correct ***
	*******************************************************
	if ("`parameter'"=="ratio") {
	
		foreach v of local variable {
		local var_2=substr("`v'", strpos("`v'", ":") + 1, .)
		local pos = strpos("`var_2'", "/")
		*control if pos==0: invalid specification
		if (`pos'==0) {
			display as error "Error: Invalid specification in `v' for ratio estimation. '/' missing"
			exit 498
			}
		*check if numerator or denominator are in the variable lsit
		local denominator = substr("`var_2'", `pos'+1, .)
		local numerator = substr("`var_2'", 1, `pos'-1)
		cap confirm variable `numerator', exact
		if _rc {
			display as error "Error: variable `numerator' (in `v') not found"
			exit 498
			}
		cap confirm variable `denominator', exact
		if _rc {
			display as error "Error: variable `denominator' (in `v') not found"
			exit 498
			}
		}
	}
		*set cluster if specified
		if(`setcluster'>0) {
		quietly parallel initialize `setcluster'
	} 
	else if (`setcluster'<0) {
		di as error "The number of cluser should not be negative"
		exit 498
	}
		

end

*include controle in case of hierarchical geographic variable, indication=> to many zero/missing value in sample frequencies
