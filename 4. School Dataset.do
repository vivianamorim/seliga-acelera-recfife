
	**
	*DATASET AT SCHOOL LEVEL
	* _____________________________________________________________________________________________________________________________________________________________ *

	
	
		* _________________________________________________________________________________________________________________________________________________________ *
		**
		**
		**Flow Indicators for municipal schools in Recife
		**
		* _________________________________________________________________________________________________________________________________________________________ *
			use approval3grade 		approval4grade 		approval5grade 		approvalEF1		///
				repetition3grade 	repetition4grade 	repetition5grade	repetitionEF1	///
				dropout3grade 		dropout4grade 		dropout5grade		dropoutEF1		///
				network codmunic codschool year using "$rendimento/Flow Indicators at school level.dta" if network == 3 & codmunic == 2611606, clear
				destring , replace
			
				**
				*To have the indicator in the current year and in previous year
				expand 		2, gen (REP)
				replace 	year = year + 1 	if REP == 1
				gen 		t    = "t" 			if REP == 0
				replace 	t    = "t_menos1" 	if REP == 1
				drop 		REP
				
				**
				*
				foreach 	var of varlist *grade {
					local 	name = substr("`var'", 1, length("`var'")-5)	//taking grade out of var's name
					rename `var' `name'
				}
				
				**
				*
				reshape 	wide approval* repetition* dropout*, i(codschool codmunic year network) j(t) string
				
				**
				*
				tempfile 	 1
				save 		`1'
		
		* _________________________________________________________________________________________________________________________________________________________ *
		**
		**
		**Age Distortion for municipal schools in Recife
		**
		* _________________________________________________________________________________________________________________________________________________________ *
			use agedistortion3grade agedistortion4grade agedistortion5grade agedistortionEF1  		///
				network codmunic codschool year using "$distorcao/Age Distortion at school level.dta" if network == 3 & codmunic == 2611606, clear
				destring , replace
				
				**
				*To have the indicator in the current year and in previous year
				expand 		2, gen (REP)
				replace 	year = year + 1 	if REP == 1
				gen 		t    = "t" 			if REP == 0
				replace 	t    = "t_menos1" 	if REP == 1
				drop 		REP
				
				**
				*
				foreach 	var of varlist *grade {
					local 	name = substr("`var'", 1, length("`var'")-5)	//taking grade out of var's name
					rename `var' `name'
				}
				
				**
				*
				reshape 	wide agedistortion*, i(codschool codmunic year network) j(t) string
				
				**
				*
				tempfile 	 2
				save 		`2'
			
			
		* _________________________________________________________________________________________________________________________________________________________ *
		**
		**
		** School Infrastructure for municipal schools in Recife
		**
		* _________________________________________________________________________________________________________________________________________________________ *
			use 		"$censoescolar/School Infrastructure at school level.dta" 	if network == 3 & codmunic == 2611606, clear
				keep 	codschool year ComputerLab ScienceLab ClosedSportCourt OpenedSportCourt Library ReadingRoom InternetAccess SportCourt OwnBuilding BroadBandInternet MealsForStudents SchoolEmployees TotalClasses PrincipalRoom TeacherRoom Kitchen WaterAccess EnergyAccess SewerAccess
				tempfile 	 3
				save 		`3'

				
		* _________________________________________________________________________________________________________________________________________________________ *
		**
		**
		**Proficiency
		**
		* _________________________________________________________________________________________________________________________________________________________ *
			use 		"$dtinter/Proficiência.dta"									if grade < 6, clear
				collapse 	(mean)  prof_MT  prof_LP prof_MT_stand prof_LP_stand insuf_mat insuf_port, by(year grade codschool) 
				reshape 	wide    prof_MT  prof_LP prof_MT_stand prof_LP_stand insuf_mat insuf_port, i(codschool year) j(grade)
				
				**
				*To have the indicator in the current year and in previous year
				expand 		2, gen (REP)
				replace 	year = year + 1 	if REP == 1
				gen 		t    = "t" 			if REP == 0
				replace 	t    = "t_menos1" 	if REP == 1
				drop 		REP
				
				**
				*
				reshape 	wide prof_MT2-insuf_port5, i(codschool year) j(t) string
				
				**
				*
				tempfile 	 4
				save 		`4'
			
			
		* _________________________________________________________________________________________________________________________________________________________ *
		**
		**
		**Classrooms being used
		**
		* _________________________________________________________________________________________________________________________________________________________ *
			use 		"$dtfinal/SE LIGA & Acelera_Recife.dta" 					if grade != . & period !=., clear
				egen 			 n_turmas = tag(cd_turma)
				collapse    (sum)n_turmas, by(year codschool period)
				reshape 	wide n_turmas, i(year codschool) j(period)		
				tempfile 	 5
				save 		`5'
				
		* _________________________________________________________________________________________________________________________________________________________ *
		**
		**
		**Type of school
		**
		* _________________________________________________________________________________________________________________________________________________________ *
			use "$dtfinal/SE LIGA & Acelera_Recife.dta", clear
					
					duplicates drop codschool year, force
					keep 		    codschool year acelera_school 
					
					tempfile 6
					save 	`6'
				
		* _________________________________________________________________________________________________________________________________________________________ *
		**
		**
		**Number of students with age grade distortion
		**
		* _________________________________________________________________________________________________________________________________________________________ *
			use 		"$dtfinal/SE LIGA & Acelera_Recife.dta" 					if grade != . & grade >= 1 & grade <=5 , clear

				gen  		mat   = 1												//enrollments
				bys 		codschool year: egen tem_seliga  = max(t_seliga)		//school offers Se Liga
				bys 		codschool year: egen tem_acelera = max(t_acelera)		//school offers Acelera
				
				clonevar 	alunos_1mais = dist_1mais							
				clonevar 	alunos_2mais = dist_2mais
				
				gen 		proporca_acelera = 1 if el1_nesse_ano == 1 & t_acelera 	== 1
				replace		proporca_acelera = 0 if el1_nesse_ano == 1 & type_program  == 1
				
				preserve
				collapse 	(sum) mat alunos_1mais alunos_2mais (mean)proporca_acelera dist_1mais dist_2mais *migra* (max)tem_seliga tem_acelera, by(codschool year)
				tempfile 7		// total number of students with age distortion  - aggregated for 1st to 5th grade
				save 	`7'
				restore
				
				collapse 	(sum) mat  (mean)dist_1mais dist_2mais (max)tem_seliga tem_acelera, by(codschool year grade)
				reshape		 wide mat   	 dist_1mais dist_2mais, 							 i(codschool year       tem_seliga tem_acelera) j(grade)
									// total number of students with age distortion  - disaggregated by grade
				merge 		1:1 year codschool using `7', nogen 
			
		* _________________________________________________________________________________________________________________________________________________________ *
		**
		**
		**Merging Datasets
		**
		* _________________________________________________________________________________________________________________________________________________________ *
			merge 		1:1 year codschool using `1', nogen keep(1 3)
			merge 		1:1 year codschool using `2', nogen keep(1 3)
			merge 		1:1 year codschool using `3', nogen keep(1 3)
			merge 		1:1 year codschool using `4', nogen keep(1 3)
			merge 		1:1 year codschool using `5', nogen keep(1 3)
			merge 		1:1 year codschool using `6', nogen keep(1 3)	
		
			**
			*
			foreach 		var of varlist dist* insu* Library  BroadBandInternet ComputerLab ScienceLab SportCourt {
				replace    `var' = `var'*100
			}
			
			**
			*
			label	 	define 	tem_seliga  			0 "Other schools" 1 "Se Liga" 
			label 		define 	tem_acelera 			0 "Other schools" 1 "Acelera"
			label 		val 	tem_seliga  tem_seliga
			label 		val 	tem_acelera tem_acelera
			
			**
			*
			egen 		n_turmass_manhat = rsum(n_turmas1 n_turmas2)
			egen 		n_turmass_tardet = rsum(n_turmas1 n_turmas3)
			
			gen 		espaco_manhat = TotalClasses - n_turmass_manhat
			gen 		espaco_tardet = TotalClasses - n_turmass_tardet
			
			replace 	espaco_manhat = . if espaco_manhat < 0
			replace 	espaco_tardet = . if espaco_tardet < 0
			
			sort 		codschool year
			
			gen 		espaco_manhat_menos1 = espaco_manhat[_n-1] if codschool[_n] == codschool[_n-1]
			gen 		espaco_tardet_menos1 = espaco_tardet[_n-1] if codschool[_n] == codschool[_n-1]
			
			**
			*
			label 		var espaco_manhat_menos1		"Number of classrooms available in yeat t-1"
			label		var alunos_1mais  				"Students with at least one year of age-grade distortion"
			label 		var alunos_2mais				"Students with at least two years of age-grade distortion"
			label 		var dist_1mais 					"At least one year of age-grade distortion - %"
			label 		var dist_2mais 					"At least two years of age-grade distortion - %"
			label 		var Library		 				"Library - %"
			label 		var BroadBandInternet 			"Broad band internet - %"
			label 		var ComputerLab 				"Computer Lab - %"
			label 		var ScienceLab					"Science Lab - %"
			label 		var insuf_mat3t  				"Insufficient performance in Math, third graders  - %"
			label 		var insuf_port3t   				"Insufficient performance in Portuguese, third graders - %"
			label 		var insuf_mat5t  				"Insufficient performance in Math, fifth graders - %"
			label 		var insuf_port5t				"Insufficient performance in Portuguese, fifth graders - %"
			label 		var approvalEF1t				"Approval in t, first to fifth graders - %"
			label 		var repetitionEF1t				"Repetition in t, first to fifth graders - %"
			label 		var dropoutEF1t					"Dropout  in t, first to fifth graders - %"
			label 		var mat							"Enrollments, first to fifth graders"
			label 		var TotalClasses				"Number of classrooms in the school"
			label 		var n_turmas1					"Classrooms being used for full-day classes"
			label 		var n_turmas2 					"Classrooms being used in the morning"
			label 		var n_turmas3 					"Classrooms being used in the afternoon"
			*label 		var nmigrou_participar_seliga 	"Se liga students were enrolled in the same school in t-1"
			*label 		var nmigrou_participar_acelera	"Acelera students were enrolled in the same school in t-1"
			
			**
			*
			save "$dtinter/School Level Data.dta" 	, replace



			
