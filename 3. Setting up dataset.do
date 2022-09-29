	**
	**
	*SAEPE + EMPREL + CENSUS DATA + IDEB DATA/*	
	* _____________________________________________________________________________________________________________________________________________________________ *

	
	
	* _____________________________________________________________________________________________________________________________________________________________ *
	**
	**
	*Finding students of EMPREL dataset in SAEPE data.
	**
	* _____________________________________________________________________________________________________________________________________________________________ *

	/*	
	*Strategies to find the proficiency data of the students listed in EMPREL datasets.
	Since the datasets shared do not have a student's code of identification, we will merge EMPREL and SAEPE data based on:
			- name, grade, birthday and codschool.
	*/

		*
		*1st merge -> trying name of the student + codschool + grade
		* ------------------------------------------------------------------------------------------------------------- *
		{
			**
			*Who are the students in our emprel dataset that we need to find in the proficiency dataset? 
			**
			use	  	   			 year name_student codschool grade id_emprel  using "$dtinter/Emprel.dta" 					if 											 (year < 2016 & (grade == 3 | grade == 5 | grade == 9)) | (year > 2015 & (grade == 2 | grade == 5 | grade == 9)), clear
			duplicates 		tag  year name_student codschool grade, gen(tag)
			drop 		if  tag > 0
			clonevar 				  name_student_emprel = name_student
			
			tempfile 		emprel
			save 		   `emprel'
			
			**
			*Students that did proficiency test
			**
			use   	    		year name_student codschool grade id_prof   using "$dtinter/Proficiência.dta"			   if grade < 12, clear
			duplicates  	tag year name_student codschool grade, gen(tag)
			drop 		 if tag > 0
			clonevar 	 name_student_saepe = name_student
			
			**
			merge 		1:1 	year name_student codschool grade using `emprel', keep (3) nogen							//1a tentativa de merge 
			
			**
			keep 		id_emprel id_prof	name_student_saepe  name_student_emprel	//student's id in emprel dataset and student's id in proficiency dataset
			
			gen 		base = 1
			
			**
			save   		"$dtinter/Merged.dta", replace			//137150
		}
		
		use "$dtinter\Proficiência.dta", clear
		
		tab year grade
		
		merge 1:1 id_prof using "$dtinter/Merged.dta"
		
		tab year grade if _merge == 3

		
		**
		*2nd merge -> trying first name + codschool + grade + birthday
		* ------------------------------------------------------------------------------------------------------------- *
		{	
			**
			**Emprel
			**
			use	  	   		year first_name1 codschool grade dt_nasc sizename1 id_emprel name_student  using "$dtinter/Emprel.dta"  		if dt_nasc != . & sizename1 > 2 & ((year < 2016 & (grade == 3 | grade == 5 | grade == 9)) | (year > 2015 & (grade == 2 | grade == 5 | grade == 9))), clear
			clonevar 		name_student_emprel = name_student

			**
			merge 		1:1 id_emprel using "$dtinter/Merged.dta", keep(1) nogen keepusing(id_emprel) 								//keeping students that we did not find in the 1st merge
			
			**
			duplicates 	tag  year first_name1 codschool grade dt_nasc, gen(tag)
			drop 	if  tag > 0
			
			**
			tempfile emprel
			save 	`emprel'
			
			**
			**Proficiëncia
			**
			use   	    	year first_name1 codschool grade dt_nasc sizename1 id_prof  name_student   using "$dtinter/Proficiência.dta"  	if dt_nasc != . & sizename1 > 2 & grade < 12, clear
			clonevar 	 name_student_saepe = name_student

			**
			merge 		1:1 id_prof   using "$dtinter/Merged.dta", keep (1) nogen keepusing(id_prof) 								//students that we did not find in the 1st merge
			
			**
			duplicates  tag year first_name1 codschool grade dt_nasc, gen(tag)
			drop 	 if tag > 0

			**		
			merge 	1:1 	year first_name1 codschool grade dt_nasc using `emprel', keep (3) nogen
			keep 	id_emprel id_prof  name_student_saepe  name_student_emprel
			gen 		base = 2
			
			
			**
			append using "$dtinter/Merged.dta"		
			save 		 "$dtinter/Merged.dta", replace
		}
		
				
		use "$dtinter\Proficiência.dta", clear
		
		tab year grade
		
		merge 1:1 id_prof using "$dtinter/Merged.dta"
		
		tab year grade if _merge == 3
		
		
		**
		*3rd merge -> using matchit command (looking for names that are typed differently in both datasets)
		* ------------------------------------------------------------------------------------------------------------- *
		{
		
			foreach grade in 3 5 				{
				
				forvalues year = 2010(1)2018 	{
					
					if (`grade' == 3 & `year' < 2016) | `grade' == 5 {
			
						use	  	   	year name_student codschool grade id_emprel  size* using "$dtinter/Emprel.dta"  			if  sizename1 > 5 & sizename2 > 5 & sizename3 > 5 & year == `year' & grade == `grade', clear
							merge 		1:1 id_emprel using "$dtinter/Merged.dta", keep (1) nogen keepusing(id_emprel)  //students that we did not find in the previous two merges
							duplicates 	   tag name_student codschool grade, gen(tag)
							drop 		if tag > 0
							rename 		name_student name_emprel
							
							**
							tempfile 	emprel
							save 	   `emprel'
							
						**
						use   	    year name_student codschool grade  id_prof   size* using "$dtinter/Proficiência.dta"    	if sizename1 > 5 & sizename2 > 5 & sizename3 > 5 & year == `year' & grade == `grade', clear
							merge 		1:1 id_prof   using "$dtinter/Merged.dta", keep (1) nogen keepusing(id_prof)			//students that we did not find in the previous two merges
							duplicates     tag name_student codschool grade, gen(tag)
							drop 	 	if tag > 0
							rename 		name_student name_prof
							drop 		if strpos(name_prof, "III") > 1
							
							**
							matchit id_prof name_prof using `emprel', idusing(id_emprel) txtu(name_emprel)  override 		//this command creates a score of similarity
							**

							**
							sort 	id_prof 
							bys  	id_prof: egen max_score = max(similscore)
							gen  	max_score_string    =  string(round(max_score,  .002))
							gen  	similscore_string   =  string(round(similscore, .002))
							keep 	if max_score_string == similscore_string
							sort 	max_score id_prof 
							keep 	if max_score > 0.80
							
							**
							duplicates tag id_prof, gen(tag)
							br if      tag > 0
							drop 	if tag > 0

							**
							drop	max_score max_score_string similscore_string tag
							bys  	id_emprel: egen max_score = max(similscore)
							gen  	max_score_string    =  string(round(max_score,  .002))
							gen  	similscore_string   =  string(round(similscore, .002))
							keep 	if max_score_string == similscore_string
							
							**
							duplicates tag id_emprel, gen(tag)
							drop 	if tag > 0

							**
							keep 	id_emprel id_prof name_prof  name_emprel similscore_string similscore
							save    "$dtinter\matching `year'`grade'", replace
					}
				}
			}
			
		
			clear 
			forvalues year = 2010(1)2018{
				append using "$dtinter\matching `year'5", 
				*erase   	 "$dtinter\matching `year'5"
			}
			forvalues year = 2010(1)2015{
				append using "$dtinter\matching `year'3", 
				*erase 		 "$dtinter\matching `year'3"
			}		
			
			merge 	1:1 id_emprel using "$dtinter/Emprel.dta"		, keep(3) keepusing(codschool) nogen
			rename 	codschool codschool_emprel
			
			merge 	1:1 id_prof using "$dtinter/Proficiência.dta" , keep(3) keepusing(codschool) nogen
			rename 	codschool codschool_prof
			
			sort 	similscore
			br 		name_prof  name_emprel  codschool_emprel codschool_prof similscore if codschool_emprel != codschool_prof
			drop 	if codschool_emprel != codschool_prof & similscore <.90
			
			save "$dtinter/Merged by name.dta", replace
		}
		
		
		
		* ------------------------------------------------------------------------------------------------------------- *
		{
			use 	"$dtinter/Merged by name.dta", clear
			keep 	id_emprel id_prof
			gen 	base = 3
			append 	using "$dtinter/Merged.dta"
			save 		  "$dtinter/Merged_final.dta", replace
		}
		
		
		use  "$dtinter/Proficiência.dta", clear
		keep if inlist(grade, 3, 4, 5)
		
		merge 1:1 id_prof using  "$dtinter/Merged_final.dta", keep(1 3)
		

	* _____________________________________________________________________________________________________________________________________________________________ *
	**
	**
	*SE liga & Acelera Dataset
	**
	* _____________________________________________________________________________________________________________________________________________________________ *
		
		use "$dtinter/Emprel.dta", clear  //2008 a 2014
		
			**
			merge 1:1 id_emprel 	using "$dtinter/Merged_final.dta"	, keep (1 3) nogen
			
			**
			merge m:1 id_prof  		using "$dtinter/Proficiência.dta"	, keep (1 3) nogen
			
			/*		
			**
			**Proficiency in 3o grade
			* ------------------------------------------------------------------------------------------------------------- *
			gen 	A = prof_MT_stand if (grade == 3 & year < 2016) 	//standardized proficiency of the student in the 3rd grade. Before 2016, 3rd grade students were tested
			gen 	B = prof_LP_stand if (grade == 3 & year < 2016) 
			bys 	cd_mat: egen prof_MT_3ano = max(A)
			bys 	cd_mat: egen prof_LP_3ano = max(B)					//for that student in the dataset, what was his/her proficiency in 3rd grade
			gen 	prof_3ano = ((prof_MT_3ano + prof_LP_3ano)/2)*10 if !missing(prof_MT_3ano) & !missing(prof_LP_3ano)
			drop 	A B cd_aluno nu_sequencial first_name1-first_name3 sizename1-sizename3  network ano_nasc
			*/	
				
			**
			**Number of students with age distortion at school level
			* ------------------------------------------------------------------------------------------------------------- *
			**
			**
			preserve
			
				//num de alunos com distorcao por escola
				collapse (sum)dist_1mais dist_2mais t_acelera, by(year codschool) 			//vemos que ha escolas com mais de 8 alunos elegiveis que nao participam do programa

				gen 	acelera_school 		= t_acelera > 0 & t_acelera != .

				gen 	mais_16_alunos_dist = dist_1mais >= 16								//if there are more than 16 students with age distortion
				
				rename (dist_1mais dist_2mais) (nalunos_dist_1mais nalunos_dist_2mais) 
				
				tempfile 1 
				save	`1'
		
			restore 
			
			**
			**Merge with school infrastructure and age distortion at school level
			* ------------------------------------------------------------------------------------------------------------- *
			merge m:1 codschool year using `1', nogen keepusing(acelera_school mais_16_alunos_dist nalunos_dist_2mais nalunos_dist_1mais)
			
			merge m:1 codschool year using "$censoescolar/School Infrastructure at school level.dta", keep(1 3) nogen force
			
			merge m:1 codschool year using  "$distorcao/Age Distortion at school level.dta"			, keep(1 3)  keepusing(agedistortion3grade agedistortion4grade agedistortion5grade agedistortionEF1) nogen 
			
			egen 	total_migraram_sla  = rsum(n_alunos_migraram_acelera  n_alunos_migraram_seliga)
			
			egen 	total_vaomigrar_sla = rsum(n_alunosvaomigrar_acelera  n_alunosvaomigrar_seliga)
			
			foreach var of varlist approved repeated dropped {
				replace `var' = `var'*100
			}
			
			
			**
			foreach sub in LP MT { 
				
			bys 		cd_mat: egen 	ultima_vez_3ano   = max(year) if grade == 3  & prof_`sub'_stand != .				//ultima   vez desse ano no 3o ano
			gen 		Aprof_`sub'3ano = prof_`sub' if year == ultima_vez_3ano
			bys 		cd_mat: egen prof_`sub'3ano = max(Aprof_`sub'3ano)	
			drop		ultima_vez_3ano Aprof_`sub'3ano
			}
			
			compress
			**
			save "$dtfinal/SE LIGA & Acelera_Recife.dta", replace
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			/*
			
			tab year grade if inlist(grade, 2,3, 5, 9)
			
			
			
			tab year grade if inlist(grade, 2, 3, 5, 9) & prof_MT != .
			
			keep cd_mat year prof* grade 
			
			
			reshape wide prof_*, i(cd_mat year) j(grade)
			
			
			
			
			alunos incluidos no 4o ano, comparar a prof no 3 e no 5. 
			
			
			para aqueles alunos no 4o ano, qual a ultima prof possivel quando ele estava no 3 ano e a prox prof possivel no 5 ano. 
			
			para os alunos elegeiveis no 4o ano buscar a prof deles no 3o ano e no 5o ano. 
			
			
			
			
			
			
			
			
			
			
			
			
			
			/*
			
			
			
			use "$dtfinal/SE LIGA & Acelera_Recife.dta", clear
			
			
			keep if grade == 3 | grade == 5
			keep if prof_MT != . & prof_LP != .
			
			
			bys cd_mat: egen min = min(grade)
			bys cd_mat: egen max = max(grade)
			
			keep if min == 3 & max == 5
			
			br cd_mat year type_program grade 
			
			
			bys cd_mat: gen total = _N
			keep if total > 1
			
			
			
			
			
			
			/*
						{		
				
			**
			*Matchit
			**
			forvalues year = 2010(1)2010 {
			
				**
				use	  	   	year name_student codschool grade id_emprel  size* using "$dtinter/Emprel.dta"  			if  sizename1 > 5 & sizename2 > 5 & sizename3 > 5 & ((year < 2016 & (grade == 3 | grade == 5 | grade == 9)) | (year > 2015 & (grade == 2 | grade == 5 | grade == 9))), clear
				merge 		1:1 id_emprel using "$dtinter/Merged.dta", keep (1) nogen keepusing(id_emprel)  //students that we did not find in the previous two merges
				keep 		if year == `year'
				duplicates 	   tag name_student codschool grade, gen(tag)
				drop 		if tag > 0
				rename 		name_student name_emprel
				
				**
				tempfile 	emprel
				save 	   `emprel'

				**
				use   	    year name_student codschool grade  id_prof   size* using "$dtinter/Proficiência.dta"    	if sizename1 > 5 & sizename2 > 5 & sizename3 > 5 & grade < 12, clear
				merge 		1:1 id_prof   using "$dtinter/Merged.dta", keep (1) nogen keepusing(id_prof)			//students that we did not find in the previous two merges
				keep 		if year == `year'
				duplicates     tag name_student codschool grade, gen(tag)
				drop 	 	if tag > 0
				rename 		name_student name_prof
				drop 		if strpos(name_prof, "III") > 1
				
				**
				matchit id_prof name_prof using `emprel', idusing(id_emprel) txtu(name_emprel)  override 		//this command creates a score of similarity
				**
			}
				**
				sort 	id_prof 
				bys  	id_prof: egen max_score = max(similscore)
				gen  	max_score_string    =  string(round(max_score,  .002))
				gen  	similscore_string   =  string(round(similscore, .002))
				keep 	if max_score_string == similscore_string
				sort 	max_score id_prof 
				br if max_score > 0.69
				keep 	if max_score > 0.69
				
				**
				duplicates tag id_prof, gen(tag)
				br if tag > 0
				drop 	if tag > 0

				**
				drop	max_score max_score_string similscore_string tag
				bys  	id_emprel: egen max_score = max(similscore)
				gen  	max_score_string    =  string(round(max_score,  .002))
				gen  	similscore_string   =  string(round(similscore, .002))
				keep 	if max_score_string == similscore_string
				
				**
				duplicates tag id_emprel, gen(tag)
				drop 	if tag > 0

				**
				keep 	id_emprel id_prof name_prof  name_emprel
				gen 	year =  `year'
				tempfile 		`year'
				save           ``year''
			}
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			/*
					
					
								
			**
			**Proficiency in 2o grade
			* ------------------------------------------------------------------------------------------------------------- *
			/*
			gen 	A = prof_MT_stand if (grade == 2 & year > 2015)		//standardized proficiency of the student in the 2nd grade. After 2015, 2nd grade students were tested
			gen 	B = prof_LP_stand if (grade == 2 & year > 2015)
			bys 	cd_mat: egen prof_MT_2ano = max(A)					//for that student in the dataset, what was his/her proficiency in 2nd grade
			bys 	cd_mat: egen prof_LP_2ano = max(B)
			drop 	A B
			gen 	prof_2ano = ((prof_MT_2ano + prof_LP_2ano)/2)*10 if !missing(prof_MT_2ano) & !missing(prof_LP_2ano)
			*/
			**
			
			**
			*Checking students with insufficient performance
			**
			gen 	A = prof_MT if (grade == 2 & year > 2015)		
			gen 	B = prof_LP if (grade == 2 & year > 2015)
			
			**
			bys 	cd_mat: egen prof_MT_2 = max(A)
			bys 	cd_mat: egen prof_LP_2 = max(B)
			drop 	A B
			
			**
			gen 	A = prof_MT if (grade == 3 & year < 2016) 
			gen 	B = prof_LP if (grade == 3 & year < 2016) 
			
			**
			bys 	cd_mat: egen prof_MT_3 = max(A)
			bys 	cd_mat: egen prof_LP_3 = max(B)

			**
			gen 	insuf_mat_2ano  = 0 if !missing(prof_MT_2)			//insufficient performance in the 2nd grade
			gen 	insuf_port_2ano = 0 if !missing(prof_LP_2)
			
			replace insuf_port_2ano = 1 if prof_LP_2 < 450 
			replace insuf_mat_2ano  = 1 if prof_MT_2 < 500 
			
			**
			gen 	insuf_mat_3ano 	= 0 if !missing(prof_MT_3)			//insufficient performance in the 3rd grade
			gen 	insuf_port_3ano = 0 if !missing(prof_LP_3)
			
			replace insuf_port_3ano = 1 if prof_LP_3 < 500 
			replace insuf_mat_3ano  = 1 if prof_MT_3 < 550 
			
			
			**
			drop 	A B prof_MT_2 prof_LP_2 prof_MT_3 prof_LP_3
			
			**
			format 	prof* defas* %4.2fc

