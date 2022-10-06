	**
	**
	*TABLES
	*
	* _____________________________________________________________________________________________________________________________________________________________ *
		
	
	**
	**
	*Table 1. SAMPLE
	*
	*Regular schools and Acelera schools
	* _____________________________________________________________________________________________________________________________________________________________ *
	{			
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	if year >= 2010, clear
				
			duplicates drop year codschool, force
			
			gen 		  escola_regular = 1 if acelera_school == 0
			collapse (sum)escola_regular acelera_school, by(year)
			
			tempfile escolas
				
			save 	`escolas'
			
			
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	if year >= 2010  & inlist(type_program, 1,3) & inrange(grade, 1,5) , clear		//elegible students  
			
			gen 		id = 1 if el1_nesse_ano == 1 & type_program == 1
			
			replace 	id = 1 if type_program == 3
			
			gen 		id_dis	= 1 if type_program == 3 & el1_nesse_ano == 1

			collapse 	(sum) id id_dis	,  by(year acelera_school   type_program )

			reshape 	wide  id*,   i(year type_program)  j(acelera_school) 
			
			reshape 	wide  id*,  i(year) j(type_program) 
						
			drop 		id03 id_dis01 id_dis11 id_dis03 //nao tem mat no acelera em escolas so com educacao regular

			merge 		1:1 year using   `escolas', nogen 
			
			tempfile escolas
				
			save 	`escolas'
			
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	if year >= 2010 & inlist(type_program, 3) & inrange(grade, 1,5), clear		//elegible students  
				
			collapse (sum) t_acelera , by (grade year)
			
			reshape wide t_acelera, i(year) j(grade)
			
			merge 1:1 year using `escolas', nogen

			expand 3, gen (REP)
			
			sort 	year REP
			
			gen 	col1= .
			
			gen 	col2 = . 
			
			gen 	col3 = .
			
			order year escola_regular  id01 col1 acelera_school id11 id13 col2 id_dis13 col3 t_acelera*

			foreach var of varlist escola_regular- t_acelera5 {
				replace `var' = . if REP == 1
			}
	}	
			
			
		
		
	**
	**
	*Table A1
	*
	*Educational Indicators of elementary education students in locally-managed schools, 2007-2019
	* __________________________________________________________________________________________________________________________________________________________ *
	{
		**
		**Flow Indicators
		**-------------------->>
		use 		"$rendimento/Flow Indicators at municipal level.dta" 	if network == 3 & location == 3 , clear
		
			**
			gen	 		total 	= "Brasil"
			expand 		2 					if uf 		== "PE"		, gen (REP1)
			replace 	total 	= "PE" 		if 						       REP1 == 1
			expand 		2 					if codmunic == 2611606 	    &  REP1 != 1, gen(REP2)
			replace 	total 	= "Recife" 	if 							   REP1 != 1 &    REP2 == 1 
			
			**
			collapse (mean) repetitionEF1 approvalEF1 dropoutEF1, by(year total)
			
			**
			tempfile 	 		 rendimento
			save 				`rendimento'
		
		**
		**Age-grade distortion
		**-------------------->>
		use 		"$distorcao/Age Distortion at municipal level.dta"		if network == 3 & location == 3 , clear

			**
			gen	 		total 	= "Brasil"
			expand 		2 					if uf 		== "PE"		, gen (REP1)
			replace 	total 	= "PE" 		if 						       REP1 == 1
			expand 		2 					if codmunic == 2611606 	    &  REP1 != 1, gen(REP2)
			replace 	total 	= "Recife" 	if 							   REP1 != 1 &    REP2 == 1 
		
			**
			collapse	(mean) agedistortionEF1, by(year total)

			
		**
		**Age-grade distortion + Flow
		**-------------------->>
			**
			merge 		1:1 year total using  `rendimento', nogen 
			
			
			rename 		(agedistortionEF1 repetitionEF1 approvalEF1 dropoutEF1) ///
						(agedistortion	  repetition    approval	dropout  )
			**
			reshape 	wide agedistortion		 repetition		  approval		 dropout, i(year) j(total) string
			
			gen col1 = .
			gen col2 = .
			gen col3=  .
			
			
		**
		*Table
		**-------------------->>
			order 		year age* agedistortion* col1 repetition*  col2 approval* col3 dropout*
	}	
	
	
	
	**
	**
	*Table A2
	*
	* _____________________________________________________________________________________________________________________________________________________________ *
	{
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	if ((inlist(grade,3,5) & year < 2016) | (inlist(grade, 2,5) & year> 2015)) & inrange(year, 2010, 2018), clear		//elegible students  
				
				expand 2, gen(REP)
				
				replace year =  4000 if REP == 1
				drop REP
				
				expand 2, gen (REP)
				
				replace acelera_school = 2 if REP == 1
				

				gen 	  student_saepe = prof_LP != .
				
				collapse (mean)student_saepe, by(grade year acelera_school)
				
				replace 	student_saepe = student_saepe*100
				
				reshape 	wide student_saepe, i(year grade) j(acelera_school)
			
				reshape 	wide student_saepe*, i(year) j(grade)
			
				order 		year student_saepe22 student_saepe23 student_saepe25 student_saepe02 student_saepe03 student_saepe05 student_saepe12 student_saepe13 student_saepe15
		}	
				
	
	**
	**
	*Table A3
	*
	* _____________________________________________________________________________________________________________________________________________________________ *
	{
	
			use  "$dtinter/School Level Data.dta" if year >= 2010 & year <= 2018 	, clear


			global covariadas_programa   mat agedistortion3t_menos1 agedistortion4t_menos1 agedistortion5t_menos1 TotalClasses 	///
										prof_MT3t_menos1 prof_LP3t_menos1 prof_MT5t_menos1 prof_LP5t_menos1  insuf_mat3t_menos1 insuf_port3t_menos1 insuf_mat5t_menos1  insuf_port5t_menos1  approvalEF1t_menos1 repetitionEF1t_menos1  dropoutEF1t_menos1  ///
										 Library  BroadBandInternet ComputerLab ScienceLab  espaco_manhat_menos1 espaco_tardet_menos1
			
			
			**
			*Regular versus Acelera
			**---------------------------->
			gen 	educacao = 1 if acelera_school == 0 
			replace educacao = 2 if acelera_school == 1

			label var prof_MT3t_menos1 				"Average proficiency Math year before, third grade"
			label var prof_LP3t_menos1				"Average proficiency Portuguese year before, third grade"
			label var prof_MT5t_menos1			 	"Average proficiency Math year before, fifth grade"
			label var prof_LP5t_menos1				"Average proficiency Portuguese year before, fifth grade"
			label var approvalEF1t_menos1 			"Approval rate year before, first to fifth grade - %"
			label var repetitionEF1t_menos1			"Repetition rate year before, first to fifth grade - %"
			label var dropoutEF1t_menos1			"Dropout rate year before, first to fifth grade - %"
			label var agedistortion3t_menos1		"Age grade distortion year before, third grade - %"
			label var agedistortion4t_menos1		"Age grade distortion year before, fourh grade - %"
			label var agedistortion5t_menos1		"Age grade distortion year before, fifth grade - %"
			label var insuf_mat3t_menos1			"Insufficient score Portuguese year before, third grade - %"
			label var insuf_port3t_menos1			"Insufficient score  Math year before, fifth grade - %"
			label var insuf_mat5t_menos1			"Insufficient score Portuguese year before, fifth grade - %"
			label var insuf_port5t_menos1			"Insufficient score Math year before, fifth grade - %"
			label var espaco_manhat_menos1 			"Number of classrooms available morning year before"
			label var espaco_tardet_menos1			"Number of classrooms available afternoon year before"
		
			
			iebaltab $covariadas_programa, format(%12.2fc) grpvar(educacao) savetex("$tables/TableB3.tex")  fixedeffect(year) rowvarlabels replace 
	}
			
			
			
	
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			/*
			
			
			
			
			
			
			
			
			
			
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	if year >= 2010 & inlist(type_program, 3) & inlist(grade, 1,5), clear		//elegible students  
				
			collapse (sum) t_acelera , by (year)
			
			reshape wide t_acelera, i(year) j(grade)
			
			merge 1:1 year using `escolas', nogen

			expand 3, gen (REP)
			
			sort year REP
			order year escola_regular id01 acelera_school id11 id13 t_acelera*

			foreach var of varlist escola_regular- t_acelera5 {
				replace `var' = . if REP == 1
			}
				
			
			
						

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
		
		
	**
	**
	*Table A3
	*
	*Inside the same school how are the students selected to participate of the intervention? 
	* _____________________________________________________________________________________________________________________________________________________________ *
	{	
		//dentro de uma mesma escola, qual eh a proporcao de alunos elegiveis que foram incluidos na intervencao. 
		
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" 	if year >= 2010 & grade >= 3 & grade <= 5 & acelera_school == 1, clear
			
			expand 2, 		gen (REP)
			replace grade = 0 if REP == 1		//total
			rename 		el1_nesse_ano elegivel_nesse_ano
			
			collapse	 (sum)elegivel_nesse_ano entrou_nesse_ano_acelera, by(year grade    type_program)
			
			drop 								 entrou*
			
			
			
			reshape		 wide elegivel_nesse_ano, 					i(year grade) j(type_program)
			
			rename 		(elegivel_nesse_ano1 elegivel_nesse_ano2 elegivel_nesse_ano3)	///
						(elegivel_regular    elegivel_seliga     elegivel_acelera	)  
			
			//podemos ver que para alguns casos entrou_nessa_ano > elegivel_nesse_ano porque a crianca embora nao tivesse distorcao > 1 foi incluida na intervencao
			//para que possamos comparar apenas as criancas com pelo menos um ano de distorcao, vamos trabalhar apenas com os "elegiveis" que de fato participaram do programa. 
		
			**
			reshape wide elegivel*, i(year) j(grade)
			
			foreach grade in 0 3 4 5 {
				egen elegivel_total`grade' = rsum(elegivel_regular`grade' elegivel_seliga`grade' elegivel_acelera`grade')
			}
			
			*
			expand 	4, gen (REP)
			sort 	year

			**
			foreach grade in 0 3 4 5 {
				replace elegivel_regular`grade' = (elegivel_regular`grade'	/elegivel_total`grade')*100 if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
				replace elegivel_seliga`grade' =  (elegivel_seliga`grade'	/elegivel_total`grade')*100 if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
				replace elegivel_acelera`grade' = (elegivel_acelera`grade'	/elegivel_total`grade')*100 if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
			}

			**
			drop 		*total* REP
			
			**
			tostring 	*, replace force
			
			**
			foreach 	 var of varlist elegivel* {
			replace 	`var' = ""					if year[_n] == year[_n-1] & year[_n] == year[_n-2] & year[_n] == year[_n-3] 
			}
			replace 	year = "" 	  				if year[_n] == year[_n-1] & year[_n] == year[_n-2] & year[_n] == year[_n-3] 
			
			
			**
			foreach 	 var of varlist elegivel* {
				replace `var' = "" 	  				if year[_n] == year[_n+1] & year[_n] == year[_n+2] 
			}
			replace 	year = "" 	  				if year[_n] == year[_n-1] & year[_n] == year[_n+2] 
			
			**
			replace 	year = "as %" 				if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
			
			**
			replace 	year = "Total" 				if year[_n+1] == "as %"
			
			**
			foreach var of varlist elegivel* {
				replace `var' = substr(`var',1,4)  if year == "as %"
				replace `var' = `var' + "%"		   if year == "as %"
			}
			*replace year = "" 					   if year == "as %"
			
			**
			gen col0 = .
			gen col3 = .
			gen col4 = .
			
			**
			order year *0* *3* *4* 		
			drop *seliga*
	}	
		
		
	
	**
	**
	*Table A4
	*
	*Enrollments of third to fifth graders with at least one year of age-grade distortion, 2010-201
	* _____________________________________________________________________________________________________________________________________________________________ *
	{			
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	if year >= 2010, clear
				
			duplicates drop year codschool, force
			
			gen 		  escola_regular = 1 if acelera_school == 0
			collapse (sum)escola_regular acelera_school, by(year)
			
			tempfile escolas
				
			save 	`escolas'
			
			
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	if year >= 2010 & grade >= 3 & grade <= 5 & el1_nesse_ano == 1, clear
			
			expand 		2, gen(REP)
			
			replace 	grade = 0 if REP == 1

			collapse 	(sum)t_seliga t_acelera, by(year	grade )
				
			reshape 	wide  t_seliga t_acelera, i(year) j(grade) 
			
			merge 		1:1 year using   `escolas', nogen 
				
			order 		year escola_regular acelera_school t_seliga* t_acelera*
				
			expand 		3, gen (REP)
			
			sort 		year
			
			foreach program in acelera seliga {
				
				foreach grade in 3 4 5  {
					
					replace t_`program'`grade' 	=  (t_`program'`grade'/t_`program'0)*100 	if year[_n] == year[_n-1] 
				}
			}
			
					replace acelera_school	= (acelera_school/escola_regular)*100 			if year[_n] == year[_n-1] 
					
			drop *0 REP
					
			tostring 	*, replace force
					
			replace 	year = "as %" 														if year[_n] == year[_n-1] & year[_n] == year[_n+1] 
			
			
			foreach var of varlist acelera_school escola_regular t_* {
				replace `var' = ""															if year[_n-1] == "as %"
			}
					
			replace escola_regular	  = "" 													if year[_n] == "as %"

			replace year  	  = "" 															if year[_n-1]  =="as %"

			foreach var of varlist acelera_school t_* {
				replace `var' = substr(`var', 1,4) + "%" if year == "as %"
			
			}
			
			gen col1 = .
			gen col2 = .
			
			order year escola_regular acelera_school col1 t_seliga* col2 t_acelera*
	}	

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	**
	**
	*Table A
	*
	*Minimum number of students with age-grade distortion
	* _____________________________________________________________________________________________________________________________________________________________ *
		
		clear matrix
		
		**
		*Program to store the results
		**-------------------->>
		cap program drop   save_tabstat
			program define save_tabstat
			syntax, year(integer)   //year of implementation and code = 2 for Se Liga and code = 3 for Acelera
							matrix A`year' = r(Stat1)			//statistics for Regular Education
							matrix B`year' = r(Stat2)  			//statistics for Acelera
			
		end
		
		
		**
		*Thresholds for program's implemetation
		**-------------------->>
		use "$dtfinal/SE LIGA & Acelera_Recife.dta"  	if year >= 2010 & grade >= 1 & grade <= 5 & inlist(type_program,1,3), clear 
			collapse (sum) dist_1mais, by(codschool year acelera_school)	
					
				forvalues   year = 2010(1)2018 {
					tabstat  	dist_1mais  if year == `year', by(acelera_school) statistics(mean sd max min) nototal columns(variables) save    
					save_tabstat, year(`year') 
				}
					
				matrix		cod_var = (1 \ 2 \ 3 \ 4) 		//1= mean, 2 = sd, 3 = max 4 = min

				matrix 		results = (	cod_var, A2010, A2011, A2012, A2013, A2014, A2015, A2016, A2017, A2018  \ 		///			//regular
										cod_var, B2010, B2011, B2012, B2013, B2014, B2015, B2016, B2017, B2018  )  		
				**
				*
				clear
				svmat 		results
				

				**
				label  		define results1 1 "Mean" 2 "Sd" 3 "Max" 4 "Min"
				label  		val    results1  results1
				
				decode 		results1, gen(var) 
				drop   		results1
				
				order  		var* 
				tostring 	*, replace force
			
				
				local 		year = 2010
				foreach 	 var of varlist results* {
					replace `var' = substr(`var', 1,4)
					rename 	`var'  ano_`year'
					local 		year = `year' + 1
				}
				
				
				**
				set obs 10
				replace 	var 	 = "Regular" in 9
				replace 	var 	 = "Acelera" in 10
					
				**	
				gen 		order 	 = _n
				replace 	order	 = 0.5 in 9
				replace 	order 	 = 4.5 in 10
				sort 		order
				drop 		order
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	/*	
	
		**
	**
	*Table A6
	*
	*Repetition status in t−1and age-grade distortion by type of enrollment, in %, 2010-2018
	* _____________________________________________________________________________________________________________________________________________________________ *
		
			*********************************************************
			**
			**Olhar matricula 318809

			*********************************************************
	{	
		
		//apenas dentro das escolas que implementaram a intervencao. 
		
		use 			"$dtfinal/SE LIGA & Acelera_Recife.dta" if year >= 2010 & grade >= 3 & grade <= 5 & inlist(tipo_escola, 2, 3,4), clear
			
			//
			*Manter apenas quem eh elegivel de acordo com a distorcao idade-serie
			
			**
			*
			keep if elegivel_nesse_ano == 1

			**
			*
			collapse 	(mean)		reprovou_anterior  dist_2mais, by(year type_program		grade )
			
			**
			*
			reshape		 wide 		reprovou_anterior  dist_2mais, i( year type_program	) j(grade) 
			
			**
			*
			foreach var of varlist 	reprovou_anterior* dist_2mais* {
				replace `var' = `var'*100
				format  `var' %4.1fc
			}
			
			**
			*
			tostring year, replace force
			
			**
			*
			replace  year = "" if year[_n] == year[_n-2]
			replace  year = "" if year[_n] == year[_n-1]
		
			**
			gen col3 = .
			gen col4 = .
			
			**
			order year type_program *3* *4* 		
	}


			
	**
	*
	*Table A4
	*
	* _____________________________________________________________________________________________________________________________________________________________ *
	{	
		**
		use "$dtfinal/SE LIGA & Acelera_Recife.dta" 	if grade > 2 & grade < 6 & year >= 2010 & distorcao >= 1 & distorcao != ., clear

			**
			*Número de alunos
			gen aluno_total     = 1						
			gen aluno_regular 	= 1 					if type_program == 1
			gen aluno_seliga 	= 1						if type_program == 2
			gen aluno_acelera 	= 1 					if type_program == 3
			
			*
			expand 2, 		gen (REP)
			replace grade = 0 if REP == 1		//total
		
			**
			collapse (sum)aluno_total-aluno_acelera, by(year grade)

			**
			reshape wide aluno*, i(year) j(grade)
			
			*
			expand 	4, gen (REP)
			sort 	year

			**
			foreach grade in 0 3 4 5 {
				replace aluno_regular`grade' = (aluno_regular`grade'/aluno_total`grade')*100 if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
				replace  aluno_seliga`grade' = ( aluno_seliga`grade'/aluno_total`grade')*100 if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
				replace aluno_acelera`grade' = (aluno_acelera`grade'/aluno_total`grade')*100 if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
			}

			**
			drop 		*total* REP
			
			**
			tostring 	*, replace force
			
			**
			foreach 	 var of varlist aluno* {
			replace 	`var' = ""					if year[_n] == year[_n-1] & year[_n] == year[_n-2] & year[_n] == year[_n-3] 
			}
			replace 	year = "" 	  				if year[_n] == year[_n-1] & year[_n] == year[_n-2] & year[_n] == year[_n-3] 
			
			
			**
			foreach var of varlist aluno* {
				replace `var' = "" 	  				if year[_n] == year[_n+1] & year[_n] == year[_n+2] 
			}
			replace 	year = "" 	  				if year[_n] == year[_n-1] & year[_n] == year[_n+2] 
			
			**
			replace 	year = "as %" 				if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
			
			**
			replace 	year = "Total" 				if year[_n+1] == "as %"
			
			**
			foreach var of varlist aluno* {
				replace `var' = substr(`var',1,4)  if year == "as %"
				replace `var' = `var' + "%"		   if year == "as %"
			}
			replace year = "" 					   if year == "as %"
			
			**
			gen col0 = .
			gen col3 = .
			gen col4 = .
			
			**
			order year *0* *3* *4* 
	}		
		
		

			
	**
	**
	*Table A16
	*
	*Repetition status in𝑡−1and age-grade distortion by type of enrollment, in %, 2010-2018
	* _____________________________________________________________________________________________________________________________________________________________ *
		
		

		**
		*Program to store the results
		**-------------------->>
		cap program drop   save_tabstat
			program define save_tabstat
			syntax, year(integer) grade(integer) code(integer)  //year of implementation and code = 2 for Se Liga and code = 3 for Acelera
							matrix A`grade'`year' = r(Stat1)			//statistics for Regular Education
			if `code' == 2  matrix B`grade'`year' = r(Stat2) 			//statistics for Se liga
			if `code' == 3  matrix C`grade'`year' = r(Stat2)  			//statistics for Acelera
			
		end
		
		
		**
		*Thresholds for program's implemetation
		**-------------------->>
			
		foreach indicador in dist_1mais {  //

		if "`indicador'" == "distorcao" local table = 16
		if "`indicador'" == "dist_2mais" local table = 17
		
		clear matrix
		 
			**
			*Defining datasets, number of tables and period of analysis
			**-------------------->>
				use "$dtfinal/SE LIGA & Acelera_Recife.dta"  	if year >= 2010 & grade >= 3 & grade <= 5 & inlist(tipo_escola, 2, 3, 4) & el1_nesse_ano == 1, clear 
				//vamos comparar apenas criancas elegiveis em escolas que oferecem o programa, comparar educacao regular versus se liga e educacao regular versus acelera

			**
			*Tabstat
			**-------------------->>
			foreach type_program in 2 3 { 		//Regular Education versus Se Liga and Regular Education versus Acelera

				**
				*
				if `type_program' == 2  local code = 2
				if `type_program' == 3  local code = 3
					
					preserve
					*.........................*
					
					**
					*
					gen 	educacao = 1 	if type_program == 1 
					replace educacao = 2 	if type_program == `type_program' 
									
					**
					*	
					foreach grade in 3 4 5 {
						forvalues   year = 2010(1)2018 {
							tabstat  	  `indicador'  if year == `year' & grade == `grade', by(educacao) statistics(mean sd max min) nototal columns(variables) save    
							save_tabstat, 		          year(`year')     grade(`grade') code(`code') 
						}
					}
					
					*.........................*
					restore

			}	

			**
			*Setting up Table 
			**-------------------->>
				**
				*
				matrix		cod_var = (1 \ 2 \ 3 \ 4) 		//1= mean, 2 = sd, 3 = max 4 = min

				matrix 		results = (	cod_var, A32010, A32011, A32012, A32013, A32014, A32015, A32016, A32017, A32018  \ 		///			//regular
										cod_var, B32010, B32011, B32012, B32013, B32014, B32015, B32016, B32017, B32018  \ 		///			//se liga
										cod_var, C32010, C32011, C32012, C32013, C32014, C32015, C32016, C32017, C42018  \ 		///		
										cod_var, A42010, A42011, A42012, A42013, A42014, A42015, A42016, A42017, A42018  \ 		///			//regular
										cod_var, B42010, B42011, B42012, B42013, B42014, B42015, B42016, B42017, B42018  \ 		///			//se liga
										cod_var, C42010, C42011, C42012, C42013, C42014, C42015, C42016, C42017, C42018  \ 		///		
										cod_var, A52010, A52011, A52012, A52013, A52014, A52015, A52016, A52017, A52018  \ 		///			//regular
										cod_var, B52010, B52011, B52012, B52013, B52014, B52015, B52016, B52017, B52018  \ 		///			//se liga
										cod_var, C52010, C52011, C52012, C52013, C52014, C52015, C52016, C52017, C52018  )					//acelera
				
				**
				*
				clear
				svmat 		results
				

				**
				label  		define results1 1 "Mean" 2 "Sd" 3 "Max" 4 "Min"
				label  		val    results1  results1
				
				decode 		results1, gen(var) 
				drop   		results1
				
				order  		var* 
				tostring 	*, replace force
				set 		obs 15
				
				local 		year = 2010
				foreach 	 var of varlist results* {
					replace `var' = substr(`var', 1,4)
					rename 	`var'  ano_`year'
					local 		year = `year' + 1
				}
				
				
				**
				replace 	var 	 = "Regular" in 13
				replace 	var 	 = "Se Liga" in 14
				replace 	var 	 = "Acelera" in 15		
					
				**	
				gen 		order 	 = _n
				replace 	order	 = 0.5 in 13
				replace 	order 	 = 4.5 in 14
				replace 	order 	 = 8.5 in 15
				sort 		order
				drop 		order
				export excel "$tables/TableA`table'.xlsx", replace 
		
		}
		

		use "$dtfinal/SE LIGA & Acelera_Recife.dta"  	if year >= 2010 & grade >= 3 & grade <= 5 & inlist(tipo_escola, 2, 3, 4) & elegivel_nesse_ano == 1, clear 
		
		keep if grade == 3 & reprovou_anterior == 1
		
			gen 	educacao = 1 	if type_program == 1 
			replace educacao = 2 	if type_program == 2
		
			tabstat  prof_MTt_menos1 if year == 2010, by(educacao) statistics(mean sd max min) nototal columns(variables) save    
			tabstat  prof_LPt_menos1 if year == 2010, by(educacao) statistics(mean sd max min) nototal columns(variables) save    
		
			
			tabstat  prof_MTt_menos1 if year == 2015, by(educacao) statistics(mean sd max min) nototal columns(variables) save    
			tabstat  prof_LPt_menos1 if year == 2015, by(educacao) statistics(mean sd max min) nototal columns(variables) save    
			
			
			
		use "$dtfinal/SE LIGA & Acelera_Recife.dta"  	if year >= 2010 & grade >= 3 & grade <= 5 & inlist(tipo_escola, 2, 3, 4) & elegivel_nesse_ano == 1, clear 
		
		keep if grade == 5
		
				gen 	educacao = 1 	if type_program == 1 
			replace educacao = 2 	if type_program == 2
		
		tabstat  prof_MT_3ano prof_LP_3ano if year == 2015, by(educacao) statistics(mean sd max min) nototal columns(variables) save    
		
			
			
			
			
			
			
		use "$dtfinal/SE LIGA & Acelera_Recife.dta"  	if year >= 2010, clear 

			gen base_prof_MT = 1 if prof_MT != .
			gen base_prof_LP = 1 if prof_LP != .
			
			gen mat = 1
			
			collapse (sum) mat base_prof*, by(grade year) 
		
			
			
			
		
	/*	
		
			
	**
	**
	*Table A5
	*
	*
	* _____________________________________________________________________________________________________________________________________________________________ *
			
			**
			*What happened 	with the students during the years
			*
			use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" if grade > 2 & grade < 6 & year > 2009 & year < 2018, clear
				
				sort 	cd_mat
			
				gen 	id = 1
				
				
				
				
				collapse (sum)	id			aprovou_1 aprovou_semdepois_1 pulou1_program1 pulou2_program1 reprovou_1 abandonou_1 ///
								t_seliga    aprovou_2 aprovou_semdepois_2 pulou1_program2 pulou2_program2 reprovou_2 abandonou_2 ///
								t_acelera   aprovou_3 aprovou_semdepois_3 pulou1_program3 pulou2_program3 reprovou_3 abandonou_3 ///
								,   by(grade year)
			
				drop id-abandonou_1
				
				foreach var of varlist aprovou_2 aprovou_semdepois_2 pulou1_program2 pulou2_program2 reprovou_2 abandonou_2 {
					replace `var' = (`var'/t_seliga)*100
					format  `var' %4.2fc
				}
				
			count
			
			
			
		
		
				
	**
	**
	*Table A3
	*  Minimum number of students with age grade distortion for program implementation
	* _____________________________________________________________________________________________________________________________________________________________ *

	//Then we can compare schools that almost reached the threshold with the mininum number of students and the ones that implemented the intervention

		**
		*Program to store the results
		**-------------------->>
		cap program drop   save_tabstat
			program define save_tabstat
			syntax, year(integer) code(integer) 			//year of implementation and code = 2 for Se Liga and code = 3 for Acelera
							matrix A`year' = r(Stat1)		//statistics for Regular Education
			if `code' == 2  matrix B`year' = r(Stat2) 		//statistics for Se liga
			if `code' == 3  matrix C`year' = r(Stat2)  		//statistics for Acelera
			
		end
		
		
		**
		*Thresholds for program's implemetation
		**-------------------->>
			
		foreach indicador in dist_1mais  {  //
		//dist_1mais em t 		- > vai determinar a seleção das escolas em t
		//insuf_mat3t_menos1 	- > vai determinar a seleção das escolas em t, assim como as demais variáveis. 
		//insuf_mat3t_menos1 	- > disponível de 2012 a 2016
		//insuf_port3t_menos1   - > disponível de 2011 a 2016
		//insuf_mat5t_menos1 	- > disponível de 2011 a 2018
		//insuf_port5t_menos1   - > disponível de 2011 a 2018	
		//espaco_manhat_menos1 espaco_tardet_menos1- > disponíveis de 2010 a 2017
		
		clear matrix
		 
			**
			*Defining datasets, number of tables and period of analysis
			**-------------------->>
			if "`indicador'" == "dist_1mais" {
				use "$dtfinal/SE LIGA & Acelera_Recife.dta"  		if year > 2009 &  				grade < 6, clear
																															local table 	= 3
																															local ano_final = 2018
			}
			else {
				use  "$dtinter/School Level Data.dta" 		 		if year > 2009 & year <= 2018			 , clear
					if  "`indicador'" == "insuf_mat3t_menos1"   															local table 	= 4
					if  "`indicador'" == "insuf_port3t_menos1"  															local table 	= 5
					if  "`indicador'" == "insuf_mat5t_menos1"   															local table 	= 6
					if  "`indicador'" == "insuf_port5t_menos1" 																local table 	= 7
					if  "`indicador'" == "espaco_manhat_menos1"																local table 	= 8
					if  "`indicador'" == "espaco_tardet_menos1"																local table 	= 9
					
					if  "`indicador'" == "insuf_mat3t_menos1"   |  "`indicador'" == "insuf_port3t_menos1"					local ano_final = 2016			//I am doing this because not all variables are available for all the years
					if  "`indicador'" == "espaco_manhat_menos1" |  "`indicador'" == "espaco_tardet_menos1" 					local ano_final = 2017
					if  "`indicador'" == "insuf_mat5t_menos1"   |  "`indicador'" == "insuf_port5t_menos1" 					local ano_final = 2018
			}
				
			**
			*Tabstat
			**-------------------->>
			foreach tipo_programa in 2 3 { 		//Regular Education versus Se Liga and Regular Education versus Acelera

				**
				*
				if `tipo_programa' == 2  local code = 2
				if `tipo_programa' == 3  local code = 3
					
					preserve
					*.........................*
					
					**
					*
					keep 					if inlist(tipo_escola, 1, `code', 4)									//tipo_escola = 1 for regular education, 2 for only se liga, 3 for only acelera and 4 for se liga and acelera. 
					gen 	educacao = 1 	if tipo_escola 		== 1
					replace educacao = 2 	if inlist(tipo_escola, 	  `code', 4)

					**
					*
					if  "`indicador'" == "dist_1mais" collapse (sum) "`indicador'", by(codschool year educacao)		//educacao = 1 for regular and 2 for Se liga/Acelera	
														//a base de dados para os outros indicadores ja esta organizada por escola
					**
					*	
					forvalues   year = 2010(1)`ano_final' {
						di as red "tipo programa..." `tipo_programa' "...." `year' "...."  `ano_final' "....."  "`indicador'"
						tabstat  	  `indicador'  if year == `year', by(educacao) statistics(mean sd max min) nototal columns(variables) save    
						save_tabstat, 		            year(`year') code(`code') 
					}
					
					*.........................*
					restore

			}	
			
			**
			*Setting up Table 
			**-------------------->>
				**
				*
				matrix		cod_var = (1 \ 2 \ 3 \ 4) 		//1= mean, 2 = sd, 3 = max 4 = min

				**
				*
				if "`indicador'" == "insuf_mat5t_menos1" | "`indicador'" == "insuf_port5t_menos1"  | "`indicador'" == "dist_1mais"  {
				matrix 		results = (	cod_var, A2010, A2011, A2012, A2013, A2014, A2015, A2016, A2017, A2018  \ 		///			//regular
										cod_var, B2010, B2011, B2012, B2013, B2014, B2015, B2016, B2017, B2018  \ 		///			//se liga
										cod_var, C2010, C2011, C2012, C2013, C2014, C2015, C2016, C2017, C2018  )					//acelera
				}
				
				if "`indicador'" == "insuf_mat3t_menos1" | "`indicador'" == "insuf_port3t_menos1"    								{
				matrix 		results = (	cod_var, A2010, A2011, A2012, A2013, A2014, A2015, A2016 				\ 		 ///		//regular
										cod_var, B2010, B2011, B2012, B2013, B2014, B2015, A2016				\ 		 ///		//se liga
										cod_var, C2010, C2011, C2012, C2013, C2014, C2015, A2016  				)					//acelera
				} 
				if "`indicador'" == "espaco_manhat_menos1" | "`indicador'" == "espaco_tardet_menos1" 								{
				matrix 		results = (	cod_var, A2010, A2011, A2012, A2013, A2014, A2015, A2016, A2017  		\ 		 ///		//regular
										cod_var, B2010, B2011, B2012, B2013, B2014, B2015, B2016, A2017  		\ 	     ///		//se liga
										cod_var, C2010, C2011, C2012, C2013, C2014, C2015, C2016, A2017  		)					//acelera
				} 	
				
			
				**
				*
				clear
				svmat 		results
				
				**
				label  		define results1 1 "Mean" 2 "Sd" 3 "Max" 4 "Min"
				label  		val    results1  results1
				
				decode 		results1, gen(var) 
				drop   		results1
				
				order  		var* 
				tostring 	*, replace force
				set 		obs 15
				
				local 		year = 2010
				foreach 	 var of varlist results* {
					replace `var' = substr(`var', 1,4)
					rename 	`var'  ano_`year'
					local 		year = `year' + 1
				}
				
				
				**
				replace 	var 	 = "Regular" in 13
				replace 	var 	 = "Se Liga" in 14
				replace 	var 	 = "Acelera" in 15		
					
				**	
				gen 		order 	 = _n
				replace 	order	 = 0.5 in 13
				replace 	order 	 = 4.5 in 14
				replace 	order 	 = 8.5 in 15
				sort 		order
				drop 		order
				export excel "$tables/TableA`table'.xlsx", replace 
		
		}

				
	**
	**
	*Table A14
	*
	*Inside the same school how are the students selected to participate of the intervention? 
	* _____________________________________________________________________________________________________________________________________________________________ *
		
		//dentro de uma mesma escola, qual eh a proporcao de alunos elegiveis que foram incluidos na intervencao. 
		
		use 	"$dtfinal/SE LIGA & Acelera_Recife.dta" 	if year >= 2010 & grade >= 3 & grade <= 5 & inlist(tipo_escola, 3,4), clear
			
			expand 2, 		gen (REP)
			replace grade = 0 if REP == 1		//total
			
			collapse	 (sum)elegivel_nesse_ano entrou_nesse_ano_acelera, by(year grade    type_program)
			
			drop 								 entrou*
			
			reshape		 wide elegivel_nesse_ano, 					i(year grade) j(type_program)
			
			rename 		(elegivel_nesse_ano1 elegivel_nesse_ano2 elegivel_nesse_ano3)	///
						(elegivel_regular    elegivel_seliga     elegivel_acelera	)  
			
			//podemos ver que para alguns casos entrou_nessa_ano > elegivel_nesse_ano porque a crianca embora nao tivesse distorcao > 1 foi incluida na intervencao
			//para que possamos comparar apenas as criancas com pelo menos um ano de distorcao, vamos trabalhar apenas com os "elegiveis" que de fato participaram do programa. 
		
			**
			reshape wide elegivel*, i(year) j(grade)
			
			foreach grade in 0 3 4 5 {
				egen elegivel_total`grade' = rsum(elegivel_regular`grade' elegivel_seliga`grade' elegivel_acelera`grade')
			}
			
			*
			expand 	4, gen (REP)
			sort 	year

			**
			foreach grade in 0 3 4 5 {
				replace elegivel_regular`grade' = (elegivel_regular`grade'	/elegivel_total`grade')*100 if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
				replace elegivel_seliga`grade' =  (elegivel_seliga`grade'	/elegivel_total`grade')*100 if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
				replace elegivel_acelera`grade' = (elegivel_acelera`grade'	/elegivel_total`grade')*100 if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
			}

			**
			drop 		*total* REP
			
			**
			tostring 	*, replace force
			
			**
			foreach 	 var of varlist elegivel* {
			replace 	`var' = ""					if year[_n] == year[_n-1] & year[_n] == year[_n-2] & year[_n] == year[_n-3] 
			}
			replace 	year = "" 	  				if year[_n] == year[_n-1] & year[_n] == year[_n-2] & year[_n] == year[_n-3] 
			
			
			**
			foreach 	 var of varlist elegivel* {
				replace `var' = "" 	  				if year[_n] == year[_n+1] & year[_n] == year[_n+2] 
			}
			replace 	year = "" 	  				if year[_n] == year[_n-1] & year[_n] == year[_n+2] 
			
			**
			replace 	year = "as %" 				if year[_n] == year[_n-1] & year[_n] == year[_n-2] 
			
			**
			replace 	year = "Total" 				if year[_n+1] == "as %"
			
			**
			foreach var of varlist elegivel* {
				replace `var' = substr(`var',1,4)  if year == "as %"
				replace `var' = `var' + "%"		   if year == "as %"
			}
			replace year = "" 					   if year == "as %"
			
			**
			gen col0 = .
			gen col3 = .
			gen col4 = .
			
			**
			order year *0* *3* *4* 		

		
	**
	**
	*Table A2
	*Number of schools in Se Liga and Acelera
	* ___________________________________________________________________________________________________________________________________________________________ *
	{
	
		use 		"$dtfinal/SE LIGA & Acelera_Recife.dta" if year > 2009 & grade < 6, clear
			**
			duplicates drop codschool year, force
			
			
			**
			gen 		id = 1
			collapse 	(sum)id, by(acelera_school year)

		**
		*Table
		**-------------------->>
			reshape 	wide id, i(acelera_school) j(year) 
	}
	
